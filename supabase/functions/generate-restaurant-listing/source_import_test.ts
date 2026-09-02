import {
  enrichSocialSourceWithGoogleMatch,
  fetchGoogleMapsSource,
  fetchSocialMetadataFallback,
  fetchWebsiteSource,
  mergeGeneratedWithFallback,
} from "./source_import.ts";

Deno.test("Google Maps short URL resolves to authoritative editable fields", async () => {
  const calls: string[] = [];
  const source = await fetchGoogleMapsSource(
    {
      platform: "google_maps",
      sourceType: "place",
      normalizedUrl: "https://maps.app.goo.gl/AbCdEf123456",
    },
    { apiKey: "server-key" },
    (input) => {
      const url = input.toString();
      calls.push(url);
      if (url.includes("maps.app.goo.gl")) {
        return Promise.resolve(
          new Response(null, {
            status: 302,
            headers: {
              location:
                "https://www.google.com/maps/search/?api=1&query=Line+Clear&query_place_id=ChIJPlace123456",
            },
          }),
        );
      }
      return Promise.resolve(
        Response.json({
          id: "ChIJPlace123456",
          displayName: { text: "Line Clear Nasi Kandar" },
          formattedAddress: "177 Jalan Penang, George Town, Pulau Pinang",
          primaryType: "restaurant",
          priceLevel: "PRICE_LEVEL_MODERATE",
          location: { latitude: 5.42, longitude: 100.33 },
          addressComponents: [
            { longText: "George Town", types: ["locality"] },
            {
              longText: "Pulau Pinang",
              types: ["administrative_area_level_1"],
            },
          ],
        }),
      );
    },
  );
  equal(calls.length, 2);
  equal(
    source.authoritativeCandidate?.restaurantName,
    "Line Clear Nasi Kandar",
  );
  equal(source.authoritativeCandidate?.state, "Pulau Pinang");
  equal(source.authoritativeCandidate?.city, "George Town");
  equal(source.authoritativeCandidate?.priceRange, "$$");
  equal(source.authoritativeCandidate?.sourcePlatform, "google_maps");
});

Deno.test("public website JSON-LD yields a structured AI fallback without raw HTML", async () => {
  const html = `<!doctype html><html><head>
    <title>Example Cafe</title>
    <meta name="description" content="A neighbourhood cafe in Ipoh">
    <script type="application/ld+json">{
      "@type":"Restaurant",
      "name":"Example Cafe",
      "servesCuisine":"Malaysian",
      "priceRange":"$$",
      "address":{
        "streetAddress":"12 Jalan Example",
        "addressLocality":"Ipoh",
        "addressRegion":"Perak"
      }
    }</script></head><body>Welcome to Example Cafe</body></html>`;
  const source = await fetchWebsiteSource(
    {
      platform: "website",
      sourceType: "website",
      normalizedUrl: "https://example-cafe.test/about",
    },
    () =>
      Promise.resolve(
        new Response(html, {
          headers: { "content-type": "text/html; charset=utf-8" },
        }),
      ),
  );
  equal(source.authoritativeCandidate, undefined);
  equal(source.fallbackCandidate?.restaurantName, "Example Cafe");
  equal(source.fallbackCandidate?.city, "Ipoh");
  equal(source.fallbackCandidate?.state, "Perak");
  equal(source.fallbackCandidate?.cuisineType, "Malaysian");
  equal(source.posts[0].sourceCaption?.includes("<!doctype"), false);
});

Deno.test("website import rejects literal private network targets before fetch", async () => {
  let called = false;
  try {
    await fetchWebsiteSource(
      {
        platform: "website",
        sourceType: "website",
        normalizedUrl: "https://127.0.0.1/menu",
      },
      () => {
        called = true;
        return Promise.resolve(new Response("unreachable"));
      },
    );
    throw new Error("Expected private target rejection");
  } catch (error) {
    equal(
      error instanceof Error ? error.message : null,
      "Invalid public website URL",
    );
  }
  equal(called, false);
});

Deno.test("unreadable public social post keeps a partial manual fallback", async () => {
  const source = await fetchSocialMetadataFallback(
    {
      platform: "instagram",
      sourceType: "post",
      normalizedUrl: "https://instagram.com/reel/PUBLIC123/",
    },
    () => Promise.resolve(new Response("blocked", { status: 403 })),
  );
  equal(source.fallbackCandidate?.sourcePlatform, "instagram");
  equal(
    source.fallbackCandidate?.sourcePostUrl,
    "https://instagram.com/reel/PUBLIC123/",
  );
  equal(source.fallbackCandidate?.missingFields.length, 7);
});

Deno.test("social metadata fallback can enrich an editable draft with a Malaysia Google match", async () => {
  const source = await fetchSocialMetadataFallback(
    {
      platform: "instagram",
      sourceType: "post",
      normalizedUrl: "https://instagram.com/reel/PUBLIC123/",
    },
    (input) => {
      const url = input.toString();
      if (url.includes("instagram.com")) {
        return Promise.resolve(
          new Response(
            '<html><head><meta property="og:title" content="Example Cafe Ipoh"></head></html>',
            { headers: { "content-type": "text/html" } },
          ),
        );
      }
      return Promise.resolve(Response.json({
        places: [{
          id: "ChIJExampleCafe123",
          displayName: { text: "Example Cafe" },
          formattedAddress: "12 Jalan Example, Ipoh, Perak, Malaysia",
          primaryType: "restaurant",
          location: { latitude: 4.5975, longitude: 101.0901 },
          addressComponents: [
            { longText: "Ipoh", types: ["locality"] },
            { longText: "Perak", types: ["administrative_area_level_1"] },
          ],
        }],
      }));
    },
    { apiKey: "server-key" },
  );
  equal(source.fallbackCandidate?.restaurantName, "Example Cafe");
  equal(source.fallbackCandidate?.city, "Ipoh");
  equal(source.fallbackCandidate?.sourcePlatform, "instagram");
  equal(
    source.fallbackCandidate?.sourcePostUrl,
    "https://instagram.com/reel/PUBLIC123/",
  );
});

Deno.test("oversized public Instagram HTML keeps bounded OpenGraph metadata", async () => {
  const html =
    `<html><head><meta property="og:title" content="Pak Yuu Kopitiam, Petaling Jaya"></head><body>${
      "x".repeat(600 * 1024)
    }</body></html>`;
  const source = await fetchSocialMetadataFallback(
    {
      platform: "instagram",
      sourceType: "post",
      normalizedUrl: "https://instagram.com/reel/PUBLIC456/",
    },
    () =>
      Promise.resolve(
        new Response(html, {
          headers: { "content-type": "text/html" },
        }),
      ),
  );
  equal(source.fallbackCandidate?.restaurantName, null);
  if (!source.posts[0]?.sourceCaption?.includes("Pak Yuu Kopitiam")) {
    throw new Error("Expected bounded public metadata to remain available");
  }
});

Deno.test("social author and caption signals receive a conservative Google match", async () => {
  const source = await enrichSocialSourceWithGoogleMatch(
    {
      detection: {
        platform: "tiktok",
        sourceType: "post",
        normalizedUrl:
          "https://www.tiktok.com/@sundaydo.hq/video/7444170884375383304",
      },
      posts: [{
        sourcePlatform: "tiktok",
        sourcePostUrl:
          "https://www.tiktok.com/@sundaydo.hq/video/7444170884375383304",
        influencerUsername: "Sundaydo",
        sourceCaption: "A birthday surprise at our bakery in Kuala Lumpur",
      }],
    },
    { apiKey: "server-key" },
    () =>
      Promise.resolve(Response.json({
        places: [{
          id: "ChIJSundaydoBakery",
          displayName: { text: "Sundaydo Bakery" },
          formattedAddress: "Kuala Lumpur, Malaysia",
          primaryType: "dessert_shop",
          location: { latitude: 3.14, longitude: 101.69 },
          addressComponents: [
            { longText: "Kuala Lumpur", types: ["locality"] },
            {
              longText: "Wilayah Persekutuan Kuala Lumpur",
              types: ["administrative_area_level_1"],
            },
          ],
        }],
      })),
  );
  equal(source.fallbackCandidate?.restaurantName, "Sundaydo Bakery");
  equal(source.fallbackCandidate?.sourcePlatform, "tiktok");
});

Deno.test("manual social identification preserves source and fills from Google", async () => {
  const source = await fetchSocialMetadataFallback(
    {
      platform: "instagram",
      sourceType: "post",
      normalizedUrl: "https://instagram.com/p/PUBLIC789/",
    },
    (input) =>
      input.toString().includes("instagram.com")
        ? Promise.resolve(new Response("blocked", { status: 403 }))
        : Promise.resolve(Response.json({
          places: [{
            id: "ChIJPakYuu123",
            displayName: { text: "Pak Yuu Kopitiam" },
            formattedAddress: "39 Jalan 20/7, Petaling Jaya, Selangor",
            primaryType: "chinese_restaurant",
            location: { latitude: 3.11, longitude: 101.62 },
            addressComponents: [
              { longText: "Petaling Jaya", types: ["locality"] },
              { longText: "Selangor", types: ["administrative_area_level_1"] },
            ],
          }],
        })),
    { apiKey: "server-key", restaurantName: "Pak Yuu Kopitiam" },
  );
  equal(source.fallbackCandidate?.restaurantName, "Pak Yuu Kopitiam");
  equal(source.fallbackCandidate?.city, "Petaling Jaya");
  equal(
    source.fallbackCandidate?.sourcePostUrl,
    "https://instagram.com/p/PUBLIC789/",
  );
});

Deno.test("AI values merge with authoritative Google fallback fields", () => {
  const base = {
    restaurantName: "Example Cafe",
    address: "12 Jalan Example",
    state: "Perak",
    city: "Ipoh",
    cuisineType: "Cafe",
    priceRange: "$$",
    reviewedDishes: [] as string[],
    sourcePlatform: "instagram" as const,
    sourcePostUrl: "https://instagram.com/reel/PUBLIC123/",
    influencerUsername: null,
    sourceCaption: "Example Cafe Ipoh",
    confidence: 0.85,
    missingFields: ["reviewedDishes"],
  };
  const merged = mergeGeneratedWithFallback({
    ...base,
    restaurantName: null,
    address: null,
    state: null,
    city: null,
    cuisineType: null,
    priceRange: null,
    reviewedDishes: ["White coffee"],
    confidence: 0.6,
  }, base);
  equal(merged.restaurantName, "Example Cafe");
  equal(merged.reviewedDishes[0], "White coffee");
  equal(merged.missingFields.length, 0);
});

Deno.test("generic social platform identity remains an editable missing field", () => {
  const merged = mergeGeneratedWithFallback({
    restaurantName: "Instagram",
    address: null,
    state: null,
    city: null,
    cuisineType: null,
    priceRange: null,
    reviewedDishes: [],
    sourcePlatform: "instagram",
    sourcePostUrl: "https://instagram.com/reel/PUBLIC123/",
    influencerUsername: null,
    sourceCaption: null,
    confidence: 0.2,
    missingFields: [],
  }, undefined);
  equal(merged.restaurantName, null);
  if (!merged.missingFields.includes("restaurantName")) {
    throw new Error("Expected restaurantName to require Creator completion");
  }
});

function equal(actual: unknown, expected: unknown): void {
  if (actual !== expected) {
    throw new Error(`Expected ${String(expected)}, got ${String(actual)}`);
  }
}
