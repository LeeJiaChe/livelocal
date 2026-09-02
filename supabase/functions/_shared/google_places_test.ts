import {
  DETAILS_FIELD_MASK,
  NEARBY_FIELD_MASK,
  SEARCH_FIELD_MASK,
} from "./google_places.ts";
import { handleNearbyPlaces } from "../nearby-places/index.ts";
import { handlePlaceDetails } from "../place-details/index.ts";
import { handleSearchPlaces } from "../search-places/index.ts";

Deno.test("Google Places field masks remain narrow and never request broad wildcard data", () => {
  equal(SEARCH_FIELD_MASK.includes("*"), false);
  equal(NEARBY_FIELD_MASK.includes("*"), false);
  equal(DETAILS_FIELD_MASK.includes("*"), false);
  equal(SEARCH_FIELD_MASK.includes("places.id"), true);
  equal(SEARCH_FIELD_MASK.includes("places.location"), true);
  equal(DETAILS_FIELD_MASK.includes("googleMapsUri"), true);
  equal(DETAILS_FIELD_MASK.includes("photos.name"), true);
  equal(DETAILS_FIELD_MASK.includes("reviews"), false);
});

Deno.test("search validates query before provider access", async () => {
  let called = false;
  const response = await handleSearchPlaces(
    request({ query: "x" }),
    {
      env: { GOOGLE_PLACES_API_KEY: "server-secret" },
      fetcher: () => {
        called = true;
        return Promise.resolve(new Response("{}"));
      },
    },
  );
  equal(response.status, 400);
  equal(called, false);
  equal((await response.json()).error.code, "INVALID_QUERY");
});

Deno.test("Nearby validates coordinates and radius", async () => {
  const response = await handleNearbyPlaces(
    request({ latitude: 100, longitude: 101, radius: 5000 }),
    { env: { GOOGLE_PLACES_API_KEY: "server-secret" } },
  );
  equal(response.status, 400);
  equal((await response.json()).error.code, "INVALID_LOCATION");
});

Deno.test("Nearby cannot proxy discovery outside Malaysia", async () => {
  let called = false;
  const response = await handleNearbyPlaces(
    request({ latitude: 40.7128, longitude: -74.006, radius: 5000 }),
    {
      env: { GOOGLE_PLACES_API_KEY: "server-secret" },
      fetcher: () => {
        called = true;
        return Promise.resolve(new Response("{}"));
      },
    },
  );
  equal(response.status, 400);
  equal(called, false);
  equal((await response.json()).error.code, "INVALID_LOCATION");
});

Deno.test("provider errors are sanitized and never leak API key or payload", async () => {
  const response = await handleSearchPlaces(
    request({ query: "cafe in Penang" }),
    {
      env: { GOOGLE_PLACES_API_KEY: "super-secret-key" },
      fetcher: () =>
        Promise.resolve(
          new Response(
            JSON.stringify({
              error: { message: "super-secret-key request-id-sensitive" },
            }),
            { status: 403 },
          ),
        ),
    },
  );
  const body = await response.text();
  equal(response.status, 503);
  equal(body.includes("super-secret-key"), false);
  equal(body.includes("request-id-sensitive"), false);
  equal(body.includes("PLACES_UNAVAILABLE"), true);
});

Deno.test("Place Details accepts only normalized provider IDs", async () => {
  const response = await handlePlaceDetails(
    request({ placeId: "../../secret" }),
    { env: { GOOGLE_PLACES_API_KEY: "server-secret" } },
  );
  equal(response.status, 400);
  equal((await response.json()).error.code, "INVALID_PLACE_ID");
});

Deno.test("Place Details batches bounded cover previews and maps photo URIs", async () => {
  let detailCalls = 0;
  let photoCalls = 0;
  const response = await handlePlaceDetails(
    request({ placeIds: ["ChIJPlaceOne123", "ChIJPlaceTwo456"] }),
    {
      env: { GOOGLE_PLACES_API_KEY: "server-secret" },
      fetcher: (input) => {
        const url = input.toString();
        if (url.includes("/media")) {
          photoCalls += 1;
          return Promise.resolve(Response.json({
            photoUri: `https://lh3.googleusercontent.com/place-${photoCalls}`,
          }));
        }
        detailCalls += 1;
        const id = url.includes("PlaceOne")
          ? "ChIJPlaceOne123"
          : "ChIJPlaceTwo456";
        return Promise.resolve(Response.json({
          id,
          displayName: { text: `Place ${detailCalls}` },
          formattedAddress: "Malaysia",
          location: { latitude: 3.14, longitude: 101.69 },
          photos: [{ name: `places/${id}/photos/PhotoResource123` }],
        }));
      },
    },
  );
  equal(response.status, 200);
  const data = await response.json();
  equal(data.places.length, 2);
  equal(detailCalls, 2);
  equal(photoCalls, 2);
  equal(data.places[0].imageUrl.startsWith("https://"), true);
});

function request(body: unknown): Request {
  return new Request("https://example.test/functions/v1/test", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(body),
  });
}

function equal(actual: unknown, expected: unknown): void {
  if (actual !== expected) {
    throw new Error(`Expected ${String(expected)}, got ${String(actual)}`);
  }
}
