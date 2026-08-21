import type {
  DetectedSource,
  SocialConnection,
  SocialPost,
  SocialSourceContent,
} from "./types.ts";
import { GenerationError } from "./types.ts";

const INSTAGRAM_RESERVED = new Set([
  "about",
  "accounts",
  "developer",
  "directory",
  "explore",
  "legal",
  "p",
  "privacy",
  "reel",
  "reels",
  "stories",
  "terms",
  "tv",
]);

export function detectPlatformAndSourceType(url: string): DetectedSource {
  let parsed: URL;
  try {
    parsed = new URL(url.trim());
  } catch {
    throw new GenerationError("INVALID_SOURCE_URL", "Invalid source URL");
  }
  if (
    parsed.protocol !== "https:" || parsed.port || parsed.username ||
    parsed.password
  ) {
    throw new GenerationError("INVALID_SOURCE_URL", "Invalid source URL");
  }
  const host = parsed.hostname.toLowerCase();
  const segments = parsed.pathname.split("/").filter(Boolean);
  if (host === "instagram.com" || host === "www.instagram.com") {
    if (
      segments.length === 2 &&
      ["p", "reel", "reels", "tv"].includes(segments[0])
    ) {
      return {
        platform: "instagram",
        sourceType: "post",
        normalizedUrl: parsed.toString(),
      };
    }
    if (
      segments.length === 1 &&
      !INSTAGRAM_RESERVED.has(segments[0].toLowerCase())
    ) {
      return {
        platform: "instagram",
        sourceType: "profile",
        normalizedUrl: parsed.toString(),
      };
    }
  }
  if (["tiktok.com", "www.tiktok.com"].includes(host)) {
    if (
      segments.length === 3 &&
      segments[0].startsWith("@") &&
      segments[1] === "video" &&
      segments[2]
    ) {
      return {
        platform: "tiktok",
        sourceType: "post",
        normalizedUrl: parsed.toString(),
      };
    }
    if (segments.length === 1 && segments[0].startsWith("@")) {
      return {
        platform: "tiktok",
        sourceType: "profile",
        normalizedUrl: parsed.toString(),
      };
    }
  }
  if (
    ["vm.tiktok.com", "vt.tiktok.com"].includes(host) &&
    segments.length === 1
  ) {
    return {
      platform: "tiktok",
      sourceType: "post",
      normalizedUrl: parsed.toString(),
    };
  }
  throw new GenerationError("INVALID_SOURCE_URL", "Unsupported source URL");
}

export function canonicalizeSourceUrlForQuota(url: string): string {
  const detected = detectPlatformAndSourceType(url);
  const parsed = new URL(url.trim());
  let host = parsed.hostname.toLowerCase();
  if (host.startsWith("www.")) {
    host = host.slice(4);
  }
  const rawSegments = parsed.pathname.split("/").filter(Boolean);

  let canonicalPath = "";
  if (detected.platform === "instagram") {
    if (detected.sourceType === "post" && rawSegments.length === 2) {
      const type = rawSegments[0].toLowerCase();
      const code = rawSegments[1];
      canonicalPath = `/${type}/${code}`;
    } else if (detected.sourceType === "profile" && rawSegments.length === 1) {
      canonicalPath = `/${rawSegments[0].toLowerCase()}`;
    }
  } else if (detected.platform === "tiktok") {
    if (
      detected.sourceType === "post" && rawSegments.length === 3 &&
      rawSegments[0].startsWith("@") && rawSegments[1].toLowerCase() === "video"
    ) {
      canonicalPath = `/${rawSegments[0].toLowerCase()}/video/${
        rawSegments[2]
      }`;
    } else if (
      detected.sourceType === "post" &&
      ["vm.tiktok.com", "vt.tiktok.com"].includes(host) &&
      rawSegments.length === 1
    ) {
      canonicalPath = `/${rawSegments[0]}`;
    } else if (detected.sourceType === "profile" && rawSegments.length === 1) {
      canonicalPath = `/${rawSegments[0].toLowerCase()}`;
    }
  }

  if (!canonicalPath) {
    canonicalPath = `/${rawSegments.join("/")}`;
  }

  return `https://${host}${canonicalPath}`;
}

function assertMatchingProfile(
  detected: DetectedSource,
  connection: SocialConnection | null,
): SocialConnection {
  if (!connection || connection.platform !== detected.platform) {
    throw new GenerationError(
      "SOCIAL_ACCOUNT_NOT_CONNECTED",
      "Creator account connection required",
      409,
    );
  }
  const requested = new URL(detected.normalizedUrl).pathname.replace(/\/$/, "")
    .toLowerCase();
  const connected = new URL(connection.profileUrl).pathname.replace(/\/$/, "")
    .toLowerCase();
  if (!requested || requested !== connected) {
    throw new GenerationError(
      "SOCIAL_ACCOUNT_NOT_CONNECTED",
      "The requested profile is not the connected creator account",
      409,
    );
  }
  return connection;
}

async function checkedJson(
  response: Response,
  authorizationRequired = false,
): Promise<Record<string, unknown>> {
  if (
    authorizationRequired &&
    (response.status === 400 || response.status === 401)
  ) {
    throw new GenerationError(
      "SOCIAL_ACCOUNT_NOT_CONNECTED",
      "The social account connection has expired",
      409,
    );
  }
  if (response.status === 404 || response.status === 400) {
    throw new GenerationError(
      "POST_UNAVAILABLE",
      "Social post unavailable",
      404,
    );
  }
  if (!response.ok) {
    throw new GenerationError(
      "SOCIAL_API_UNAVAILABLE",
      "Social API unavailable",
      503,
    );
  }
  const data = await response.json() as Record<string, unknown>;
  const apiError = data.error;
  if (apiError && typeof apiError === "object") {
    const code = stringValue((apiError as Record<string, unknown>).code);
    if (code && code !== "ok") {
      throw new GenerationError(
        authorizationRequired
          ? "SOCIAL_ACCOUNT_NOT_CONNECTED"
          : "SOCIAL_API_UNAVAILABLE",
        "Social API rejected the request",
        authorizationRequired ? 409 : 503,
      );
    }
  }
  return data;
}

export async function fetchTikTokSource(
  detected: DetectedSource,
  connection: SocialConnection | null,
  fetcher: typeof fetch = fetch,
): Promise<SocialSourceContent> {
  if (detected.sourceType === "post") {
    const endpoint = new URL("https://www.tiktok.com/oembed");
    endpoint.searchParams.set("url", detected.normalizedUrl);
    const data = await checkedJson(
      await fetcher(endpoint, { signal: AbortSignal.timeout(12_000) }),
    );
    return {
      detection: detected,
      posts: [{
        sourcePlatform: "tiktok",
        sourcePostUrl: detected.normalizedUrl,
        influencerUsername: stringValue(data.author_name),
        sourceCaption: stringValue(data.title),
      }],
    };
  }

  const authorized = assertMatchingProfile(detected, connection);
  const endpoint = new URL("https://open.tiktokapis.com/v2/video/list/");
  endpoint.searchParams.set(
    "fields",
    "id,title,video_description,create_time,share_url",
  );
  const data = await checkedJson(
    await fetcher(endpoint, {
      method: "POST",
      headers: {
        authorization: `Bearer ${authorized.accessToken}`,
        "content-type": "application/json",
      },
      body: JSON.stringify({ max_count: 10 }),
      signal: AbortSignal.timeout(12_000),
    }),
    true,
  );
  const videos = ((data.data as Record<string, unknown> | undefined)?.videos ??
    []) as Record<string, unknown>[];
  const username = new URL(authorized.profileUrl).pathname.replace(/^\/@/, "")
    .replace(/\/$/, "");
  const posts: SocialPost[] = videos.slice(0, 10).flatMap((video) => {
    const id = stringValue(video.id);
    const postUrl = verifiedPostUrl(
      stringValue(video.share_url) ??
        (id ? `https://www.tiktok.com/@${username}/video/${id}` : null),
      "tiktok",
    );
    if (!postUrl) return [];
    return [{
      sourcePlatform: "tiktok",
      sourcePostUrl: postUrl,
      influencerUsername: username || null,
      sourceCaption: stringValue(video.video_description) ??
        stringValue(video.title),
      createdAt: dateValue(video.create_time),
    }];
  });
  return { detection: detected, posts };
}

export async function fetchInstagramSource(
  detected: DetectedSource,
  connection: SocialConnection | null,
  configuration: {
    graphApiVersion?: string;
    oEmbedAccessToken?: string;
  },
  fetcher: typeof fetch = fetch,
): Promise<SocialSourceContent> {
  if (detected.sourceType === "post") {
    if (connection) {
      try {
        const ownPosts = await fetchInstagramRecentPosts(
          connection,
          configuration.graphApiVersion,
          fetcher,
          25,
        );
        const matching = ownPosts.find(
          (post) =>
            normalizePermalink(post.sourcePostUrl) ===
              normalizePermalink(detected.normalizedUrl),
        );
        if (matching) return { detection: detected, posts: [matching] };
      } catch (error) {
        if (
          !(error instanceof GenerationError) ||
          error.code !== "SOCIAL_ACCOUNT_NOT_CONNECTED"
        ) throw error;
      }
    }
    if (!configuration.graphApiVersion || !configuration.oEmbedAccessToken) {
      throw new GenerationError(
        "SOCIAL_API_NOT_CONFIGURED",
        "Instagram oEmbed is not configured",
        503,
      );
    }
    const endpoint = new URL(
      `https://graph.facebook.com/${configuration.graphApiVersion}/instagram_oembed`,
    );
    endpoint.searchParams.set("url", detected.normalizedUrl);
    endpoint.searchParams.set(
      "access_token",
      configuration.oEmbedAccessToken,
    );
    const data = await checkedJson(
      await fetcher(endpoint, { signal: AbortSignal.timeout(12_000) }),
    );
    return {
      detection: detected,
      posts: [{
        sourcePlatform: "instagram",
        sourcePostUrl: detected.normalizedUrl,
        influencerUsername: stringValue(data.author_name),
        sourceCaption: stringValue(data.title),
      }],
    };
  }

  const authorized = assertMatchingProfile(detected, connection);
  return {
    detection: detected,
    posts: await fetchInstagramRecentPosts(
      authorized,
      configuration.graphApiVersion,
      fetcher,
      10,
    ),
  };
}

async function fetchInstagramRecentPosts(
  connection: SocialConnection,
  graphApiVersion: string | undefined,
  fetcher: typeof fetch,
  limit: number,
): Promise<SocialPost[]> {
  if (!graphApiVersion) {
    throw new GenerationError(
      "SOCIAL_API_NOT_CONFIGURED",
      "Instagram Graph API version is not configured",
      503,
    );
  }
  const endpoint = new URL(
    `https://graph.instagram.com/${graphApiVersion}/me/media`,
  );
  endpoint.searchParams.set(
    "fields",
    "id,caption,media_type,permalink,timestamp,username",
  );
  endpoint.searchParams.set("limit", String(limit));
  endpoint.searchParams.set("access_token", connection.accessToken);
  const data = await checkedJson(
    await fetcher(endpoint, { signal: AbortSignal.timeout(12_000) }),
    true,
  );
  return ((data.data ?? []) as Record<string, unknown>[]).slice(0, limit)
    .flatMap((media) => {
      const permalink = verifiedPostUrl(
        stringValue(media.permalink),
        "instagram",
      );
      if (!permalink) return [];
      return [{
        sourcePlatform: "instagram" as const,
        sourcePostUrl: permalink,
        influencerUsername: stringValue(media.username),
        sourceCaption: stringValue(media.caption),
        createdAt: stringValue(media.timestamp),
      }];
    });
}

function normalizePermalink(value: string): string {
  const url = new URL(value);
  return `${url.hostname.toLowerCase()}${url.pathname.replace(/\/$/, "")}`;
}

function verifiedPostUrl(
  value: string | null,
  platform: "tiktok" | "instagram",
): string | null {
  if (!value) return null;
  try {
    const detected = detectPlatformAndSourceType(value);
    return detected.platform === platform && detected.sourceType === "post"
      ? detected.normalizedUrl
      : null;
  } catch {
    return null;
  }
}

function stringValue(value: unknown): string | null {
  if (typeof value !== "string" || !value.trim()) return null;
  return value.trim().slice(0, 5000);
}

function dateValue(value: unknown): string | null {
  if (typeof value === "number" && Number.isFinite(value)) {
    return new Date(value * 1000).toISOString();
  }
  return stringValue(value);
}
