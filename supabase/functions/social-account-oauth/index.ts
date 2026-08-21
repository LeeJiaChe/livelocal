import {
  createClient,
  type SupabaseClient,
} from "npm:@supabase/supabase-js@2.112.0";
import type { EdgeDatabase } from "../_shared/database_types.ts";
import {
  encryptSocialToken,
  randomBase64Url,
  sha256Base64Url,
} from "../_shared/social_tokens.ts";

type Platform = "tiktok" | "instagram";

class OAuthError extends Error {
  constructor(
    public readonly code: string,
    public readonly status = 503,
  ) {
    super(code);
  }
}

const headers = {
  "access-control-allow-origin": "*",
  "access-control-allow-headers": "authorization, apikey, content-type",
  "content-type": "application/json; charset=utf-8",
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers });
}

function redirect(location: string): Response {
  return new Response(null, { status: 302, headers: { location } });
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return json({}, 200);
  const projectUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const encryptionSecret = Deno.env.get("SOCIAL_TOKEN_ENCRYPTION_KEY");
  const callbackUrl = Deno.env.get("SOCIAL_OAUTH_CALLBACK_URL");
  if (!projectUrl || !serviceRoleKey || !encryptionSecret || !callbackUrl) {
    return json({ error: { code: "SOCIAL_API_NOT_CONFIGURED" } }, 503);
  }
  const admin = createClient<EdgeDatabase>(projectUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  if (request.method === "GET") {
    return await handleCallback(
      request,
      admin,
      encryptionSecret,
      callbackUrl,
    );
  }
  if (request.method !== "POST") {
    return json({ error: { code: "METHOD_NOT_ALLOWED" } }, 405);
  }

  const authorization = request.headers.get("authorization");
  const token = authorization?.match(/^Bearer\s+(.+)$/i)?.[1];
  if (!token) return json({ error: { code: "AUTHENTICATION_REQUIRED" } }, 401);
  const { data: userData, error: userError } = await admin.auth.getUser(token);
  if (userError || !userData.user) {
    return json({ error: { code: "SESSION_EXPIRED" } }, 401);
  }
  const [{ data: role }, { data: access }] = await Promise.all([
    admin.from("user_roles").select("role").eq("user_id", userData.user.id)
      .is("revoked_at", null).maybeSingle(),
    admin.from("account_access").select("status, ends_at")
      .eq("user_id", userData.user.id).maybeSingle(),
  ]);
  if (
    role?.role !== "influencer" || access?.status !== "active" ||
    (access?.ends_at && new Date(access.ends_at).getTime() <= Date.now()) ||
    !userData.user.email_confirmed_at
  ) {
    return json({ error: { code: "INFLUENCER_REQUIRED" } }, 403);
  }

  const body = await request.json().catch(() => ({}));
  const platform = body.platform as Platform;
  if (platform !== "tiktok" && platform !== "instagram") {
    return json({ error: { code: "INVALID_PLATFORM" } }, 400);
  }
  const configuredRedirect = Deno.env.get("SOCIAL_OAUTH_APP_REDIRECT_URI") ??
    "io.livelocal.app://social-connected";
  if (
    !configuredRedirect.startsWith("io.livelocal.app://") &&
    !configuredRedirect.startsWith("https://")
  ) {
    return json({ error: { code: "SOCIAL_API_NOT_CONFIGURED" } }, 503);
  }
  try {
    await admin.from("social_oauth_states").delete()
      .lt("expires_at", new Date().toISOString());
    const state = randomBase64Url();
    const stateHash = await sha256Base64Url(state);
    const { error } = await admin.from("social_oauth_states").insert({
      state_hash: stateHash,
      user_id: userData.user.id,
      platform,
      app_redirect_uri: configuredRedirect,
      expires_at: new Date(Date.now() + 10 * 60_000).toISOString(),
    });
    if (error) throw error;
    return json({
      authorizationUrl: authorizationUrl(platform, callbackUrl, state),
    });
  } catch (error) {
    const typed = error instanceof OAuthError
      ? error
      : new OAuthError("SOCIAL_API_UNAVAILABLE");
    return json({ error: { code: typed.code } }, typed.status);
  }
});

function authorizationUrl(
  platform: Platform,
  callbackUrl: string,
  state: string,
): string {
  if (platform === "tiktok") {
    const clientKey = requiredEnvironment("TIKTOK_CLIENT_KEY");
    const url = new URL("https://www.tiktok.com/v2/auth/authorize/");
    url.searchParams.set("client_key", clientKey);
    url.searchParams.set("scope", "user.info.basic,video.list");
    url.searchParams.set("response_type", "code");
    url.searchParams.set("redirect_uri", callbackUrl);
    url.searchParams.set("state", state);
    return url.toString();
  }
  const clientId = requiredEnvironment("INSTAGRAM_CLIENT_ID");
  const url = new URL("https://www.instagram.com/oauth/authorize");
  url.searchParams.set("client_id", clientId);
  url.searchParams.set("redirect_uri", callbackUrl);
  url.searchParams.set("response_type", "code");
  url.searchParams.set("scope", "instagram_business_basic");
  url.searchParams.set("state", state);
  url.searchParams.set("enable_fb_login", "0");
  url.searchParams.set("force_authentication", "1");
  return url.toString();
}

async function handleCallback(
  request: Request,
  admin: SupabaseClient<EdgeDatabase>,
  encryptionSecret: string,
  callbackUrl: string,
): Promise<Response> {
  const url = new URL(request.url);
  const state = url.searchParams.get("state");
  const code = url.searchParams.get("code");
  if (!state) return json({ error: "OAuth callback is incomplete" }, 400);
  const stateHash = await sha256Base64Url(state);
  const { data: pending } = await admin.from("social_oauth_states").delete()
    .eq("state_hash", stateHash).is("used_at", null)
    .gt("expires_at", new Date().toISOString()).select().maybeSingle();
  if (!pending) {
    return json({ error: "OAuth state is invalid or expired" }, 400);
  }

  if (!code) {
    const destination = new URL(pending.app_redirect_uri);
    destination.searchParams.set("platform", pending.platform);
    destination.searchParams.set("error", "SOCIAL_CONNECTION_CANCELLED");
    return redirect(destination.toString());
  }

  try {
    const connected = pending.platform === "tiktok"
      ? await connectTikTok(code, callbackUrl)
      : await connectInstagram(code, callbackUrl);
    const access = await encryptSocialToken(
      connected.accessToken,
      encryptionSecret,
    );
    const refresh = connected.refreshToken
      ? await encryptSocialToken(connected.refreshToken, encryptionSecret)
      : null;
    const { error } = await admin.from("social_account_connections").upsert({
      user_id: pending.user_id,
      platform: pending.platform,
      external_account_id: connected.externalAccountId,
      profile_url: connected.profileUrl,
      access_token_ciphertext: access.ciphertext,
      access_token_iv: access.iv,
      refresh_token_ciphertext: refresh?.ciphertext ?? null,
      refresh_token_iv: refresh?.iv ?? null,
      scopes: connected.scopes,
      token_expires_at: connected.expiresIn
        ? new Date(Date.now() + connected.expiresIn * 1000).toISOString()
        : null,
      refresh_expires_at: connected.refreshExpiresIn
        ? new Date(Date.now() + connected.refreshExpiresIn * 1000).toISOString()
        : null,
      updated_at: new Date().toISOString(),
    }, { onConflict: "user_id,platform" });
    if (error) throw error;
    const destination = new URL(pending.app_redirect_uri);
    destination.searchParams.set("platform", pending.platform);
    destination.searchParams.set("connected", "true");
    return redirect(destination.toString());
  } catch {
    const destination = new URL(pending.app_redirect_uri);
    destination.searchParams.set("platform", pending.platform);
    destination.searchParams.set("error", "SOCIAL_CONNECTION_FAILED");
    return redirect(destination.toString());
  }
}

async function connectTikTok(
  code: string,
  callbackUrl: string,
) {
  const body = new URLSearchParams({
    client_key: requiredEnvironment("TIKTOK_CLIENT_KEY"),
    client_secret: requiredEnvironment("TIKTOK_CLIENT_SECRET"),
    code,
    grant_type: "authorization_code",
    redirect_uri: callbackUrl,
  });
  const tokenResponse = await fetch(
    "https://open.tiktokapis.com/v2/oauth/token/",
    {
      method: "POST",
      headers: { "content-type": "application/x-www-form-urlencoded" },
      body,
      signal: AbortSignal.timeout(12_000),
    },
  );
  if (!tokenResponse.ok) throw new Error("TikTok token exchange failed");
  const token = await tokenResponse.json();
  const profileUrl = new URL(
    "https://open.tiktokapis.com/v2/user/info/",
  );
  profileUrl.searchParams.set(
    "fields",
    "open_id,display_name,profile_deep_link",
  );
  const profileResponse = await fetch(profileUrl, {
    headers: { authorization: `Bearer ${token.access_token}` },
    signal: AbortSignal.timeout(12_000),
  });
  if (!profileResponse.ok) throw new Error("TikTok profile lookup failed");
  const profile = (await profileResponse.json()).data?.user;
  if (!profile?.open_id || !profile?.profile_deep_link) {
    throw new Error("TikTok profile is incomplete");
  }
  return {
    accessToken: token.access_token as string,
    refreshToken: token.refresh_token as string | undefined,
    expiresIn: token.expires_in as number | undefined,
    refreshExpiresIn: token.refresh_expires_in as number | undefined,
    externalAccountId: profile.open_id as string,
    profileUrl: profile.profile_deep_link as string,
    scopes: String(token.scope ?? "").split(",").filter(Boolean),
  };
}

async function connectInstagram(code: string, callbackUrl: string) {
  const form = new FormData();
  form.set("client_id", requiredEnvironment("INSTAGRAM_CLIENT_ID"));
  form.set("client_secret", requiredEnvironment("INSTAGRAM_CLIENT_SECRET"));
  form.set("grant_type", "authorization_code");
  form.set("redirect_uri", callbackUrl);
  form.set("code", code);
  const shortResponse = await fetch(
    "https://api.instagram.com/oauth/access_token",
    { method: "POST", body: form, signal: AbortSignal.timeout(12_000) },
  );
  if (!shortResponse.ok) throw new Error("Instagram token exchange failed");
  const short = await shortResponse.json();
  const longUrl = new URL("https://graph.instagram.com/access_token");
  longUrl.searchParams.set("grant_type", "ig_exchange_token");
  longUrl.searchParams.set(
    "client_secret",
    requiredEnvironment("INSTAGRAM_CLIENT_SECRET"),
  );
  longUrl.searchParams.set("access_token", short.access_token);
  const longResponse = await fetch(longUrl, {
    signal: AbortSignal.timeout(12_000),
  });
  const long = longResponse.ok ? await longResponse.json() : short;
  const accessToken = long.access_token ?? short.access_token;
  const version = requiredEnvironment("META_GRAPH_API_VERSION");
  const profileUrl = new URL(`https://graph.instagram.com/${version}/me`);
  profileUrl.searchParams.set("fields", "user_id,username");
  profileUrl.searchParams.set("access_token", accessToken);
  const profileResponse = await fetch(profileUrl, {
    signal: AbortSignal.timeout(12_000),
  });
  if (!profileResponse.ok) throw new Error("Instagram profile lookup failed");
  const profile = await profileResponse.json();
  if (!profile.username) throw new Error("Instagram profile is incomplete");
  return {
    accessToken: accessToken as string,
    refreshToken: undefined,
    expiresIn: (long.expires_in ?? short.expires_in) as number | undefined,
    refreshExpiresIn: undefined,
    externalAccountId: String(profile.user_id ?? profile.id),
    profileUrl: `https://www.instagram.com/${profile.username}/`,
    scopes: ["instagram_business_basic"],
  };
}

function requiredEnvironment(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new OAuthError("SOCIAL_API_NOT_CONFIGURED");
  return value;
}
