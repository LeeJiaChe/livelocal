import {
  detectPlatformAndSourceType,
  fetchInstagramSource,
  fetchTikTokSource,
} from "./social_source.ts";
import { GenerationError } from "./types.ts";

Deno.test("detects supported post and profile URLs", () => {
  equal(
    detectPlatformAndSourceType("https://www.tiktok.com/@creator/video/123")
      .sourceType,
    "post",
  );
  equal(
    detectPlatformAndSourceType("https://www.tiktok.com/@creator/").sourceType,
    "profile",
  );
  equal(
    detectPlatformAndSourceType("https://instagram.com/reel/ABC/").sourceType,
    "post",
  );
  equal(
    detectPlatformAndSourceType("https://instagram.com/creator/").sourceType,
    "profile",
  );
});

Deno.test("rejects unsupported and deceptive source URLs", async () => {
  for (
    const value of [
      "not a URL",
      "http://instagram.com/reel/ABC",
      "https://instagram.com.evil.test/reel/ABC",
      "https://example.com/@creator/video/123",
      "https://instagram.com/reel/ABC/extra",
      "https://www.tiktok.com/@creator/video/123/extra",
    ]
  ) {
    await throwsCode(
      () => Promise.resolve(detectPlatformAndSourceType(value)),
      "INVALID_SOURCE_URL",
    );
  }
});

Deno.test("TikTok fetching is isolated and accepts a mocked official API", async () => {
  const detected = {
    platform: "tiktok" as const,
    sourceType: "post" as const,
    normalizedUrl: "https://www.tiktok.com/@creator/video/123",
  };
  const result = await fetchTikTokSource(
    detected,
    null,
    () =>
      Promise.resolve(
        new Response(
          JSON.stringify({
            author_name: "creator",
            title: "Nasi lemak at Village Park",
          }),
          { status: 200 },
        ),
      ),
  );
  equal(result.posts[0].sourceCaption, "Nasi lemak at Village Park");
});

Deno.test("TikTok profile fetching uses the connected account and limits posts", async () => {
  const result = await fetchTikTokSource(
    {
      platform: "tiktok",
      sourceType: "profile",
      normalizedUrl: "https://www.tiktok.com/@creator/",
    },
    {
      platform: "tiktok",
      profileUrl: "https://www.tiktok.com/@creator/",
      accessToken: "server-only-token",
    },
    (_url, init) => {
      equal(
        (init?.headers as Record<string, string>).authorization,
        "Bearer server-only-token",
      );
      return Promise.resolve(
        new Response(
          JSON.stringify({
            data: {
              videos: Array.from({ length: 12 }, (_, index) => ({
                id: String(index + 1),
                share_url: `https://www.tiktok.com/@creator/video/${index + 1}`,
                video_description: `Restaurant review ${index + 1}`,
              })),
            },
            error: { code: "ok" },
          }),
          { status: 200 },
        ),
      );
    },
  );
  equal(result.posts.length, 10);
  equal(
    result.posts[0].sourcePostUrl,
    "https://www.tiktok.com/@creator/video/1",
  );
});

Deno.test("Instagram profile fetching is isolated behind a mocked API", async () => {
  const result = await fetchInstagramSource(
    {
      platform: "instagram",
      sourceType: "profile",
      normalizedUrl: "https://www.instagram.com/creator/",
    },
    {
      platform: "instagram",
      profileUrl: "https://www.instagram.com/creator/",
      accessToken: "server-only-token",
    },
    { graphApiVersion: "v99.0" },
    () =>
      Promise.resolve(
        new Response(
          JSON.stringify({
            data: [{
              permalink: "https://www.instagram.com/reel/ABC/",
              username: "creator",
              caption: "Restaurant review",
            }],
          }),
          { status: 200 },
        ),
      ),
  );
  equal(result.posts.length, 1);
  equal(result.posts[0].influencerUsername, "creator");
});

function equal(actual: unknown, expected: unknown) {
  if (actual !== expected) {
    throw new Error(`Expected ${String(expected)}, got ${String(actual)}`);
  }
}

async function throwsCode(
  callback: () => Promise<unknown>,
  expected: string,
) {
  try {
    await callback();
  } catch (error) {
    if (error instanceof GenerationError && error.code === expected) return;
    throw error;
  }
  throw new Error(`Expected ${expected}`);
}
