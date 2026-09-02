import {
  assertMalaysiaLocation,
  callGooglePlaces,
  getPlacesApiKey,
  jsonReply,
  mapPlace,
  NEARBY_FIELD_MASK,
  numberInRange,
  placeTypeForCategory,
  sanitizedPlacesError,
} from "../_shared/google_places.ts";

export async function handleNearbyPlaces(
  request: Request,
  deps?: { fetcher?: typeof fetch; env?: Record<string, string> },
): Promise<Response> {
  if (request.method === "OPTIONS") return jsonReply({});
  if (request.method !== "POST") {
    return jsonReply({ error: { code: "METHOD_NOT_ALLOWED" } }, 405);
  }
  try {
    const payload = await request.json().catch(() => ({}));
    const latitude = numberInRange(payload.latitude, "latitude", -90, 90);
    const longitude = numberInRange(payload.longitude, "longitude", -180, 180);
    assertMalaysiaLocation(latitude, longitude);
    const radius = payload.radius === undefined
      ? 5000
      : numberInRange(payload.radius, "radius", 100, 50000);
    const category = placeTypeForCategory(payload.category);
    const ranking = payload.ranking === "distance" ? "DISTANCE" : "POPULARITY";
    const body: Record<string, unknown> = {
      maxResultCount: 20,
      rankPreference: ranking,
      languageCode: "en",
      regionCode: "MY",
      locationRestriction: {
        circle: {
          center: { latitude, longitude },
          radius,
        },
      },
    };
    if (category) body.includedTypes = [category];

    const data = await callGooglePlaces(
      "https://places.googleapis.com/v1/places:searchNearby",
      {
        apiKey: getPlacesApiKey(deps?.env),
        fieldMask: NEARBY_FIELD_MASK,
        body,
        fetcher: deps?.fetcher,
      },
    );
    const places = Array.isArray(data.places)
      ? data.places.map((raw) => mapPlace(raw)).filter((place) =>
        place !== null
      )
      : [];
    return jsonReply({ places });
  } catch (error) {
    return sanitizedPlacesError(error);
  }
}

if (import.meta.main) Deno.serve((request) => handleNearbyPlaces(request));
