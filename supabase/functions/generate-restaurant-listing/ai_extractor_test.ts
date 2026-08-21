import {
  generateStructuredRestaurantCandidates,
  normalizeCandidates,
} from "./ai_extractor.ts";

Deno.test("normalization preserves verified source and reports missing fields", () => {
  const post = {
    sourcePlatform: "instagram" as const,
    sourcePostUrl: "https://instagram.com/reel/ABC/",
    influencerUsername: "creator",
    sourceCaption: "Village Park nasi lemak",
  };
  const candidates = normalizeCandidates([{
    restaurantName: "Village Park Restaurant",
    address: null,
    state: "Selangor",
    city: "Petaling Jaya",
    cuisineType: "Malay",
    priceRange: null,
    reviewedDishes: ["Nasi Lemak Ayam Goreng"],
    sourcePostUrl: post.sourcePostUrl,
    confidence: 0.9,
    missingFields: [],
  }], [post]);

  const candidate = candidates[0];
  equal(candidate.sourcePostUrl, post.sourcePostUrl);
  equal(candidate.influencerUsername, "creator");
  equal(candidate.restaurantName, "Village Park Restaurant");
  equal(candidate.address, null);
  equal(candidate.city, null);
  includes(candidate.missingFields, "address");
  includes(candidate.missingFields, "priceRange");
});

Deno.test("normalization rejects AI-supplied unverified post URLs", () => {
  const candidates = normalizeCandidates([{
    sourcePostUrl: "https://evil.test/fake",
    confidence: 1,
  }], [{
    sourcePlatform: "tiktok",
    sourcePostUrl: "https://tiktok.com/@creator/video/123",
    influencerUsername: null,
    sourceCaption: null,
  }]);
  equal(candidates.length, 0);
});

Deno.test("structured AI fetching is mockable and caps profile results at five", async () => {
  const posts = Array.from({ length: 6 }, (_, index) => ({
    sourcePlatform: "instagram" as const,
    sourcePostUrl: `https://instagram.com/reel/${index + 1}/`,
    influencerUsername: "creator",
    sourceCaption: `Cafe ${index + 1} nasi lemak`,
  }));
  const output = {
    candidates: posts.map((post, index) => ({
      restaurantName: `Cafe ${index + 1}`,
      address: null,
      state: null,
      city: null,
      cuisineType: null,
      priceRange: null,
      reviewedDishes: ["nasi lemak"],
      sourcePostUrl: post.sourcePostUrl,
      confidence: 0.8,
      missingFields: [],
    })),
  };
  const candidates = await generateStructuredRestaurantCandidates(
    {
      detection: {
        platform: "instagram",
        sourceType: "profile",
        normalizedUrl: "https://instagram.com/creator/",
      },
      posts,
    },
    { apiKey: "test-key", model: "structured-test-model" },
    (_url, init) => {
      const request = JSON.parse(String(init?.body));
      equal(request.model, "structured-test-model");
      equal(request.response_format.type, "json_schema");
      return Promise.resolve(
        new Response(
          JSON.stringify({
            choices: [{ message: { content: JSON.stringify(output) } }],
          }),
          { status: 200 },
        ),
      );
    },
  );
  equal(candidates.length, 5);
  equal(candidates[0].sourcePlatform, "instagram");
  equal(candidates[0].sourcePostUrl, posts[0].sourcePostUrl);
});

function equal(actual: unknown, expected: unknown) {
  if (actual !== expected) throw new Error("Values are not equal");
}

function includes(values: string[], expected: string) {
  if (!values.includes(expected)) throw new Error(`Missing ${expected}`);
}
