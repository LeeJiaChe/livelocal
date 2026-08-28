import {
  createClient,
  type SupabaseClient,
} from "npm:@supabase/supabase-js@2.112.0";
import type { EdgeDatabase } from "../_shared/database_types.ts";
import { generateStructuredRestaurantCandidates } from "./ai_extractor.ts";
import {
  canonicalizeSourceUrlForQuota,
  detectPlatformAndSourceType,
  fetchInstagramSource,
  fetchTikTokSource,
} from "./social_source.ts";
import {
  fetchGoogleMapsSource,
  fetchSocialMetadataFallback,
  fetchWebsiteSource,
} from "./source_import.ts";
import type { SocialSourceContent } from "./types.ts";
import { GenerationError } from "./types.ts";

const corsHeaders = {
  "access-control-allow-origin": "*",
  "access-control-allow-headers": "authorization, apikey, content-type",
  "content-type": "application/json; charset=utf-8",
};

export function reply(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: corsHeaders });
}

export async function computeSha256(text: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(text.trim());
  const hashBuffer = await crypto.subtle.digest("SHA-256", data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");
}

export async function handleGenerateRequest(
  request: Request,
  deps?: {
    authClient?: SupabaseClient<EdgeDatabase>;
    adminClient?: SupabaseClient<EdgeDatabase>;
    fetcher?: typeof fetch;
    env?: Record<string, string>;
  },
): Promise<Response> {
  if (request.method === "OPTIONS") return reply({}, 200);
  if (request.method !== "POST") {
    return reply({ error: { code: "METHOD_NOT_ALLOWED" } }, 405);
  }

  const getEnv = (key: string): string | undefined => {
    if (deps?.env && key in deps.env) return deps.env[key];
    try {
      return Deno.env.get(key);
    } catch {
      return undefined;
    }
  };

  let usageId: string | null = null;
  let adminClient: SupabaseClient<EdgeDatabase> | null = null;

  try {
    const projectUrl = getEnv("SUPABASE_URL");
    const publishableKey = getEnv("SUPABASE_ANON_KEY") ??
      getEnv("SUPABASE_PUBLISHABLE_KEY");
    const serviceRoleKey = getEnv("SUPABASE_SERVICE_ROLE_KEY");
    if (
      (!deps?.authClient && (!projectUrl || !publishableKey)) ||
      (!deps?.adminClient && (!projectUrl || !serviceRoleKey))
    ) {
      throw new GenerationError(
        "AUTHORIZATION_CHECK_FAILED",
        "Creator access could not be checked",
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
    // Keep caller authentication and privileged database access in separate
    // clients. The auth client has no service-role capability; the admin
    // client is used only after the caller JWT has been verified.
    const auth = deps?.authClient ??
      createClient<EdgeDatabase>(projectUrl!, publishableKey!, {
        auth: { persistSession: false, autoRefreshToken: false },
      });
    const admin = deps?.adminClient ??
      createClient<EdgeDatabase>(projectUrl!, serviceRoleKey!, {
        auth: { persistSession: false, autoRefreshToken: false },
      });
    adminClient = admin;

    const { data: userData, error: userError } = await auth.auth.getUser(jwt);
    if (userError || !userData.user) {
      throw new GenerationError("SESSION_EXPIRED", "Session expired", 401);
    }

    const [roleResult, accessResult] = await Promise.all([
      admin.from("user_roles").select("role, revoked_at")
        .eq("user_id", userData.user.id).is("revoked_at", null).maybeSingle(),
      admin.from("account_access").select("status, ends_at")
        .eq("user_id", userData.user.id).maybeSingle(),
    ]);
    if (roleResult.error || accessResult.error) {
      throw new GenerationError(
        "AUTHORIZATION_CHECK_FAILED",
        "Creator access could not be checked",
        503,
      );
    }
    const role = roleResult.data;
    const access = accessResult.data;
    if (!role || !access) {
      throw new GenerationError(
        "AUTHORIZATION_CHECK_FAILED",
        "Creator access could not be checked",
        503,
      );
    }
    const accessExpired = access?.ends_at &&
      new Date(access.ends_at).getTime() <= Date.now();
    if (
      role?.role !== "influencer" || access?.status !== "active" ||
      accessExpired || !userData.user.email_confirmed_at
    ) {
      throw new GenerationError(
        "INFLUENCER_REQUIRED",
        "Approved Creator required",
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

    // Social profiles require account-level API access and are intentionally
    // excluded from the paste-one-link workflow. Public posts, Maps places and
    // public websites remain supported.
    if (detection.sourceType === "profile") {
      throw new GenerationError(
        "PROFILE_IMPORT_NOT_SUPPORTED",
        "Profile import is not available",
        400,
      );
    }

    const canonicalSourceUrl = canonicalizeSourceUrlForQuota(sourceUrl);
    const sourceHash = await computeSha256(canonicalSourceUrl);

    // Enforce quota and duplicate request protection before executing AI call (FAIL CLOSED)
    const { data: quotaData, error: quotaError } = await admin.rpc(
      "check_and_record_ai_generation_quota" as never,
      {
        p_user_id: userData.user.id,
        p_source_hash: sourceHash,
        p_platform: detection.platform,
        p_hourly_limit: 10,
        p_daily_limit: 50,
        p_cooldown_seconds: 30,
      } as never,
    );

    if (quotaError || !quotaData || typeof quotaData !== "object") {
      throw new GenerationError(
        "AI_QUOTA_UNAVAILABLE",
        "AI quota check is unavailable",
        503,
      );
    }

    const quota = quotaData as Record<string, unknown>;
    if (quota.allowed === false) {
      const isCooldown = quota.error_code === "COOLDOWN";
      throw new GenerationError(
        "AI_RATE_LIMITED",
        isCooldown
          ? "Please wait before requesting AI generation for this link again."
          : "AI generation quota exceeded. Please try again later.",
        429,
      );
    }
    if (typeof quota.usage_id === "string") {
      usageId = quota.usage_id;
    }

    // Public source fetching without a creator-account OAuth dependency.
    const fetcher = deps?.fetcher ?? fetch;
    let source: SocialSourceContent;
    if (detection.platform === "google_maps") {
      source = await fetchGoogleMapsSource(detection, {
        apiKey: getEnv("GOOGLE_PLACES_API_KEY"),
      }, fetcher);
    } else if (detection.platform === "website") {
      source = await fetchWebsiteSource(detection, fetcher);
    } else {
      try {
        source = detection.platform === "tiktok"
          ? await fetchTikTokSource(detection, null, fetcher)
          : await fetchInstagramSource(detection, null, {
            graphApiVersion: getEnv("META_GRAPH_API_VERSION"),
            oEmbedAccessToken: getEnv("INSTAGRAM_OEMBED_ACCESS_TOKEN"),
          }, fetcher);
      } catch {
        // A valid public-post URL remains useful provenance even when the
        // platform API, oEmbed endpoint, or page fetch is unavailable. Keep
        // the Creator in the form with a partial editable draft.
        source = await fetchSocialMetadataFallback(detection, fetcher, {
          apiKey: getEnv("GOOGLE_PLACES_API_KEY"),
        });
      }
    }

    const provider = getEnv("AI_PROVIDER")?.trim();
    const apiKey = getEnv("AI_API_KEY")?.trim() ||
      (provider === "openai_compatible"
        ? getEnv("OPENAI_API_KEY")?.trim()
        : undefined) ||
      (provider === "gemini_openai_compatible"
        ? getEnv("GEMINI_API_KEY")?.trim()
        : undefined);
    const model = getEnv("AI_MODEL")?.trim();
    const baseUrl = getEnv("AI_API_BASE_URL")?.trim();

    let candidates = source.authoritativeCandidate
      ? [source.authoritativeCandidate]
      : [];
    if (candidates.length === 0) {
      try {
        candidates = await generateStructuredRestaurantCandidates(source, {
          provider,
          apiKey,
          model,
          baseUrl,
        }, fetcher);
      } catch (error) {
        if (source.fallbackCandidate) {
          candidates = [source.fallbackCandidate];
        } else {
          throw error;
        }
      }
    }

    if (candidates.length !== 1) {
      throw new GenerationError(
        "MALFORMED_AI_RESPONSE",
        "Source extraction did not return one candidate",
        502,
      );
    }

    if (usageId) {
      try {
        await admin.rpc("record_ai_generation_outcome" as never, {
          p_usage_id: usageId,
          p_outcome: "succeeded",
        } as never);
      } catch (_) {
        // ignore telemetry error
      }
    }

    return reply({
      sourceType: detection.sourceType,
      platform: detection.platform,
      candidates,
    });
  } catch (error) {
    if (usageId && adminClient) {
      try {
        await adminClient.rpc("record_ai_generation_outcome" as never, {
          p_usage_id: usageId,
          p_outcome: "failed",
        } as never);
      } catch (_) {
        // ignore telemetry error
      }
    }

    const typed = error instanceof GenerationError
      ? error
      : new GenerationError(
        "SOURCE_UNAVAILABLE",
        "Source analysis failed",
        503,
      );
    return reply(
      { error: { code: typed.code, message: typed.message } },
      typed.status,
    );
  }
}

if (import.meta.main) {
  Deno.serve((req) => handleGenerateRequest(req));
}
