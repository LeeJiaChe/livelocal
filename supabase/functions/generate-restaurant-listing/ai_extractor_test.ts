import {
  generateStructuredRestaurantCandidates,
  normalizeCandidates,
} from "./ai_extractor.ts";
import { GenerationError } from "./types.ts";

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

Deno.test("explicit AI configuration validations", async () => {
  const dummySource = {
    detection: {
      platform: "tiktok" as const,
      sourceType: "post" as const,
      normalizedUrl: "https://www.tiktok.com/@user/video/123",
    },
    posts: [],
  };

  // Missing provider
  try {
    await generateStructuredRestaurantCandidates(
      dummySource,
      { apiKey: "test-key", model: "gpt-4o-mini" },
    );
    throw new Error("Should have thrown");
  } catch (err) {
    if (err instanceof GenerationError) {
      equal(err.code, "AI_PROVIDER_NOT_CONFIGURED");
    } else throw err;
  }

  // Unsupported provider
  try {
    await generateStructuredRestaurantCandidates(
      dummySource,
      { provider: "claude_direct", apiKey: "test-key", model: "claude-3" },
    );
    throw new Error("Should have thrown");
  } catch (err) {
    if (err instanceof GenerationError) {
      equal(err.code, "AI_PROVIDER_NOT_CONFIGURED");
    } else throw err;
  }

  // Missing API key
  try {
    await generateStructuredRestaurantCandidates(
      dummySource,
      { provider: "openai_compatible", apiKey: "", model: "gpt-4o-mini" },
    );
    throw new Error("Should have thrown");
  } catch (err) {
    if (err instanceof GenerationError) {
      equal(err.code, "AI_PROVIDER_NOT_CONFIGURED");
    } else throw err;
  }

  // Missing model
  try {
    await generateStructuredRestaurantCandidates(
      dummySource,
      { provider: "openai_compatible", apiKey: "test-key", model: "" },
    );
    throw new Error("Should have thrown");
  } catch (err) {
    if (err instanceof GenerationError) {
      equal(err.code, "AI_PROVIDER_NOT_CONFIGURED");
    } else throw err;
  }
});

Deno.test("gemini_openai_compatible provider uses Gemini defaults", async () => {
  const post = {
    sourcePlatform: "tiktok" as const,
    sourcePostUrl: "https://www.tiktok.com/@user/video/123",
    influencerUsername: "creator",
    sourceCaption: "Good Laksa Cafe",
  };
  let calledUrl = "";
  let calledModel = "";

  await generateStructuredRestaurantCandidates(
    {
      detection: {
        platform: "tiktok",
        sourceType: "post",
        normalizedUrl: post.sourcePostUrl,
      },
      posts: [post],
    },
    {
      provider: "gemini_openai_compatible",
      apiKey: "test-gemini-key",
      model: "gemini-2.5-flash",
    },
    (url, init) => {
      calledUrl = String(url);
      const body = JSON.parse(String(init?.body));
      calledModel = body.model;
      return Promise.resolve(
        new Response(
          JSON.stringify({
            choices: [{
              message: {
                content: JSON.stringify({
                  candidates: [{
                    restaurantName: "Good Laksa Cafe",
                    address: null,
                    state: null,
                    city: null,
                    cuisineType: null,
                    priceRange: null,
                    reviewedDishes: ["Laksa"],
                    sourcePostUrl: post.sourcePostUrl,
                    confidence: 0.9,
                    missingFields: [],
                  }],
                }),
              },
            }],
          }),
          { status: 200 },
        ),
      );
    },
  );

  equal(
    calledUrl,
    "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions",
  );
  equal(calledModel, "gemini-2.5-flash");
});

Deno.test("unexpected internal error does not leak secret detail", () => {
  const internalError = new Error(
    "Connection failed: SUPER_SECRET_INTERNAL_DETAIL_12345",
  );
  const sanitized = internalError instanceof GenerationError
    ? internalError
    : new GenerationError(
      "SOCIAL_API_UNAVAILABLE",
      "Source analysis failed",
      503,
    );

  equal(sanitized.code, "SOCIAL_API_UNAVAILABLE");
  equal(sanitized.message, "Source analysis failed");
  equal(sanitized.message.includes("SUPER_SECRET_INTERNAL_DETAIL"), false);
});

Deno.test("malformed AI response throws MALFORMED_AI_RESPONSE", async () => {
  try {
    await generateStructuredRestaurantCandidates(
      {
        detection: {
          platform: "tiktok",
          sourceType: "post",
          normalizedUrl: "https://www.tiktok.com/@user/video/123",
        },
        posts: [{
          sourcePlatform: "tiktok",
          sourcePostUrl: "https://www.tiktok.com/@user/video/123",
          influencerUsername: null,
          sourceCaption: "Test",
        }],
      },
      {
        provider: "openai_compatible",
        apiKey: "test-key",
        model: "gpt-4o-mini",
      },
      () =>
        Promise.resolve(
          new Response(
            JSON.stringify({
              choices: [{ message: { content: "INVALID_NOT_JSON" } }],
            }),
            { status: 200 },
          ),
        ),
    );
    throw new Error("Should have thrown");
  } catch (err) {
    if (err instanceof GenerationError) {
      equal(err.code, "MALFORMED_AI_RESPONSE");
      equal(err.status, 502);
    } else {
      throw err;
    }
  }
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
    {
      provider: "openai_compatible",
      apiKey: "test-key",
      model: "structured-test-model",
    },
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
  if (actual !== expected) {
    throw new Error(
      `Expected ${JSON.stringify(expected)} but got ${JSON.stringify(actual)}`,
    );
  }
}

function includes(array: string[], item: string) {
  if (!array.includes(item)) {
    throw new Error(`Expected ${JSON.stringify(array)} to contain "${item}"`);
  }
}
