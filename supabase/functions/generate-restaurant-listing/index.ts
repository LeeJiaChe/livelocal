import {
  createClient,
  type SupabaseClient,
} from "npm:@supabase/supabase-js@2.112.0";
import type { EdgeDatabase } from "../_shared/database_types.ts";
import { decryptSocialToken } from "../_shared/social_tokens.ts";
import { generateStructuredRestaurantCandidates } from "./ai_extractor.ts";
import {
  detectPlatformAndSourceType,
  fetchInstagramSource,
  fetchTikTokSource,
} from "./social_source.ts";
import type { SocialConnection, SocialPlatform } from "./types.ts";
import { GenerationError } from "./types.ts";

const corsHeaders = {
  "access-control-allow-origin": "*",
  "access-control-allow-headers": "authorization, apikey, content-type",
  "content-type": "application/json; charset=utf-8",
};

function reply(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: corsHeaders });
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return reply({}, 200);
  if (request.method !== "POST") {
    return reply({ error: { code: "METHOD_NOT_ALLOWED" } }, 405);
  }
  try {
    const projectUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const encryptionSecret = Deno.env.get("SOCIAL_TOKEN_ENCRYPTION_KEY");
    if (!projectUrl || !serviceRoleKey) {
      throw new GenerationError(
        "SOCIAL_API_NOT_CONFIGURED",
        "Server configuration missing",
        503,
      );
    }

    const authorization = request.headers.get("authorization");
    if (!authorization?.toLowerCase().startsWith("bearer ")) {
      throw new GenerationError(
        "AUTHENTICATION_REQUIRED",
        "Authentication required",
        401,
      );
    }
    const jwt = authorization.slice(7).trim();
    const admin = createClient<EdgeDatabase>(projectUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data: userData, error: userError } = await admin.auth.getUser(jwt);
    if (userError || !userData.user) {
      throw new GenerationError("SESSION_EXPIRED", "Session expired", 401);
    }

    const [{ data: role }, { data: access }] = await Promise.all([
      admin.from("user_roles").select("role, revoked_at")
        .eq("user_id", userData.user.id).is("revoked_at", null).maybeSingle(),
      admin.from("account_access").select("status, ends_at")
        .eq("user_id", userData.user.id).maybeSingle(),
    ]);
    const accessExpired = access?.ends_at &&
      new Date(access.ends_at).getTime() <= Date.now();
    if (
      role?.role !== "influencer" || access?.status !== "active" ||
      accessExpired || !userData.user.email_confirmed_at
    ) {
      throw new GenerationError(
        "INFLUENCER_REQUIRED",
        "Approved influencer required",
        403,
      );
    }

    const payload = await request.json().catch(() => ({}));
    const sourceUrl = typeof payload.sourceUrl === "string"
      ? payload.sourceUrl.trim()
      : "";
    if (!sourceUrl || sourceUrl.length > 2048) {
      throw new GenerationError("INVALID_SOURCE_URL", "Invalid source URL");
    }
    const detection = detectPlatformAndSourceType(sourceUrl);
    const connection = await loadConnection(
      admin,
      userData.user.id,
      detection.platform,
      encryptionSecret,
    );
    const source = detection.platform === "tiktok"
      ? await fetchTikTokSource(detection, connection)
      : await fetchInstagramSource(detection, connection, {
        graphApiVersion: Deno.env.get("META_GRAPH_API_VERSION"),
        oEmbedAccessToken: Deno.env.get("INSTAGRAM_OEMBED_ACCESS_TOKEN"),
      });
    if (detection.sourceType === "profile" && source.posts.length === 0) {
      throw new GenerationError(
        "NO_RESTAURANT_REVIEWS",
        "No recent posts available",
        404,
      );
    }
    const candidates = await generateStructuredRestaurantCandidates(source, {
      apiKey: Deno.env.get("AI_API_KEY"),
      model: Deno.env.get("AI_MODEL"),
      baseUrl: Deno.env.get("AI_API_BASE_URL"),
    });
    if (detection.sourceType === "post" && candidates.length !== 1) {
      throw new GenerationError(
        "MALFORMED_AI_RESPONSE",
        "Single-post extraction did not return one candidate",
        502,
      );
    }
    if (detection.sourceType === "profile" && candidates.length === 0) {
      throw new GenerationError(
        "NO_RESTAURANT_REVIEWS",
        "No restaurant reviews found",
        404,
      );
    }
    return reply({
      sourceType: detection.sourceType,
      platform: detection.platform,
      candidates,
    });
  } catch (error) {
    const typed = error instanceof GenerationError
      ? error
      : new GenerationError(
        "SOCIAL_API_UNAVAILABLE",
        "Source analysis failed",
        503,
      );
    return reply(
      { error: { code: typed.code, message: typed.message } },
      typed.status,
    );
  }
});

async function loadConnection(
  admin: SupabaseClient<EdgeDatabase>,
  userId: string,
  platform: SocialPlatform,
  encryptionSecret: string | undefined,
): Promise<SocialConnection | null> {
  const { data, error } = await admin.from("social_account_connections")
    .select(
      "profile_url, access_token_ciphertext, access_token_iv, token_expires_at",
    )
    .eq("user_id", userId).eq("platform", platform).maybeSingle();
  if (error) {
    throw new GenerationError(
      "SOCIAL_API_UNAVAILABLE",
      "Social connection lookup failed",
      503,
    );
  }
  if (!data) return null;
  if (
    data.token_expires_at &&
    new Date(data.token_expires_at).getTime() <= Date.now()
  ) return null;
  if (!encryptionSecret) {
    throw new GenerationError(
      "SOCIAL_API_NOT_CONFIGURED",
      "Social token encryption is not configured",
      503,
    );
  }
  return {
    platform,
    profileUrl: data.profile_url,
    accessToken: await decryptSocialToken(
      data.access_token_ciphertext,
      data.access_token_iv,
      encryptionSecret,
    ),
  };
}
