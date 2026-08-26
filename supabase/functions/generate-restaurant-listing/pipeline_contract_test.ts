import type { SupabaseClient } from "npm:@supabase/supabase-js@2.112.0";
import type { EdgeDatabase } from "../_shared/database_types.ts";
import { handleGenerateRequest } from "./index.ts";

function createMockAdminClient(options?: {
  userId?: string;
  role?: string;
  accessStatus?: string;
  quotaAllowed?: boolean;
  quotaErrorCode?: string;
  quotaUsageId?: string;
  onQuotaRpc?: () => void;
  onOutcomeRpc?: () => void;
  onConnectionQuery?: () => void;
  roleLookupFails?: boolean;
  accessLookupFails?: boolean;
}): SupabaseClient<EdgeDatabase> {
  const userId = options?.userId ?? "00000000-0000-0000-0000-000000000001";
  const role = options?.role ?? "influencer";
  const accessStatus = options?.accessStatus ?? "active";

  return {
    auth: {
      getUser: (_jwt: string) =>
        Promise.resolve({
          data: {
            user: {
              id: userId,
              email_confirmed_at: new Date().toISOString(),
            },
          },
          error: null,
        }),
    },
    from: (table: string) => {
      if (table === "user_roles") {
        return {
          select: () => ({
            eq: () => ({
              is: () => ({
                maybeSingle: () =>
                  Promise.resolve({
                    data: { role, revoked_at: null },
                    error: options?.roleLookupFails
                      ? { message: "role lookup failed" }
                      : null,
                  }),
              }),
            }),
          }),
        };
      }
      if (table === "account_access") {
        return {
          select: () => ({
            eq: () => ({
              maybeSingle: () =>
                Promise.resolve({
                  data: { status: accessStatus, ends_at: null },
                  error: options?.accessLookupFails
                    ? { message: "access lookup failed" }
                    : null,
                }),
            }),
          }),
        };
      }
      if (table === "social_account_connections") {
        options?.onConnectionQuery?.();
        return {
          select: () => ({
            eq: () => ({
              eq: () => ({
                maybeSingle: () =>
                  Promise.resolve({
                    data: null,
                    error: null,
                  }),
              }),
            }),
          }),
        };
      }
      throw new Error(`Unexpected table: ${table}`);
    },
    rpc: (fn: string, _args: unknown) => {
      if (fn === "check_and_record_ai_generation_quota") {
        options?.onQuotaRpc?.();
        return Promise.resolve({
          data: {
            allowed: options?.quotaAllowed ?? true,
            error_code: options?.quotaErrorCode,
            usage_id: options?.quotaUsageId ?? "usage-123",
          },
          error: null,
        });
      }
      if (fn === "record_ai_generation_outcome") {
        options?.onOutcomeRpc?.();
        return Promise.resolve({ data: null, error: null });
      }
      throw new Error(`Unexpected RPC: ${fn}`);
    },
  } as unknown as SupabaseClient<EdgeDatabase>;
}

function createMockAuthClient(options?: {
  authenticated?: boolean;
}): SupabaseClient<EdgeDatabase> {
  return {
    auth: {
      getUser: (_jwt: string) =>
        Promise.resolve(
          options?.authenticated == false
            ? { data: { user: null }, error: { message: "invalid JWT" } }
            : {
              data: {
                user: {
                  id: "00000000-0000-0000-0000-000000000001",
                  email_confirmed_at: new Date().toISOString(),
                },
              },
              error: null,
            },
        ),
    },
  } as unknown as SupabaseClient<EdgeDatabase>;
}

Deno.test("TikTok profile URL is rejected with PROFILE_IMPORT_NOT_SUPPORTED before quota, OAuth, or AI", async () => {
  let quotaCalled = false;
  let connectionQueried = false;
  let fetcherCalled = false;

  const mockAdmin = createMockAdminClient({
    onQuotaRpc: () => {
      quotaCalled = true;
    },
    onConnectionQuery: () => {
      connectionQueried = true;
    },
  });

  const request = new Request("https://localhost/generate-restaurant-listing", {
    method: "POST",
    headers: {
      authorization: "Bearer valid-creator-jwt",
      "content-type": "application/json",
    },
    body: JSON.stringify({
      sourceUrl: "https://www.tiktok.com/@foodie_creator/",
    }),
  });

  const response = await handleGenerateRequest(request, {
    authClient: createMockAuthClient(),
    adminClient: mockAdmin,
    fetcher: () => {
      fetcherCalled = true;
      return Promise.resolve(new Response("{}", { status: 200 }));
    },
  });

  equal(response.status, 400);
  const data = await response.json();
  equal(data.error?.code, "PROFILE_IMPORT_NOT_SUPPORTED");
  equal(data.error?.message, "Profile import is not available");
  equal(quotaCalled, false);
  equal(connectionQueried, false);
  equal(fetcherCalled, false);
});

Deno.test("Instagram profile URL is rejected with PROFILE_IMPORT_NOT_SUPPORTED before quota, OAuth, or AI", async () => {
  let quotaCalled = false;
  let connectionQueried = false;
  let fetcherCalled = false;

  const mockAdmin = createMockAdminClient({
    onQuotaRpc: () => {
      quotaCalled = true;
    },
    onConnectionQuery: () => {
      connectionQueried = true;
    },
  });

  const request = new Request("https://localhost/generate-restaurant-listing", {
    method: "POST",
    headers: {
      authorization: "Bearer valid-creator-jwt",
      "content-type": "application/json",
    },
    body: JSON.stringify({
      sourceUrl: "https://instagram.com/penang_eats/",
    }),
  });

  const response = await handleGenerateRequest(request, {
    authClient: createMockAuthClient(),
    adminClient: mockAdmin,
    fetcher: () => {
      fetcherCalled = true;
      return Promise.resolve(new Response("{}", { status: 200 }));
    },
  });

  equal(response.status, 400);
  const data = await response.json();
  equal(data.error?.code, "PROFILE_IMPORT_NOT_SUPPORTED");
  equal(data.error?.message, "Profile import is not available");
  equal(quotaCalled, false);
  equal(connectionQueried, false);
  equal(fetcherCalled, false);
});

Deno.test("valid TikTok post runs through pipeline without requiring OAuth or SOCIAL_TOKEN_ENCRYPTION_KEY", async () => {
  let quotaCalled = false;
  let connectionQueried = false;
  let outcomeRecorded = false;

  const mockAdmin = createMockAdminClient({
    onQuotaRpc: () => {
      quotaCalled = true;
    },
    onConnectionQuery: () => {
      connectionQueried = true;
    },
    onOutcomeRpc: () => {
      outcomeRecorded = true;
    },
  });

  const request = new Request("https://localhost/generate-restaurant-listing", {
    method: "POST",
    headers: {
      authorization: "Bearer valid-creator-jwt",
      "content-type": "application/json",
    },
    body: JSON.stringify({
      sourceUrl: "https://www.tiktok.com/@creator/video/7123456789012345678",
    }),
  });

  const response = await handleGenerateRequest(request, {
    authClient: createMockAuthClient(),
    adminClient: mockAdmin,
    env: {
      AI_PROVIDER: "openai_compatible",
      AI_API_KEY: "test-key",
      AI_MODEL: "gpt-4o-mini",
    },
    fetcher: (url, _init) => {
      const urlStr = String(url);
      if (urlStr.includes("tiktok.com/oembed")) {
        return Promise.resolve(
          new Response(
            JSON.stringify({
              author_name: "creator",
              title: "Siam Road Char Kway Teow in George Town Penang",
            }),
            { status: 200 },
          ),
        );
      }
      if (urlStr.includes("chat/completions")) {
        return Promise.resolve(
          new Response(
            JSON.stringify({
              choices: [{
                message: {
                  content: JSON.stringify({
                    candidates: [{
                      restaurantName: "Siam Road Char Kway Teow",
                      address: "Siam Road",
                      state: "Pulau Pinang",
                      city: "George Town",
                      cuisineType: null,
                      priceRange: null,
                      reviewedDishes: ["Char Kway Teow"],
                      sourcePostUrl:
                        "https://www.tiktok.com/@creator/video/7123456789012345678",
                      confidence: 0.95,
                      missingFields: [],
                    }],
                  }),
                },
              }],
            }),
            { status: 200 },
          ),
        );
      }
      throw new Error(`Unexpected fetch URL: ${urlStr}`);
    },
  });

  equal(response.status, 200);
  const data = await response.json();
  equal(data.sourceType, "post");
  equal(data.platform, "tiktok");
  equal(data.candidates.length, 1);
  equal(
    data.candidates[0].restaurantName,
    "Siam Road Char Kway Teow",
  );
  equal(quotaCalled, true);
  equal(connectionQueried, false);
  equal(outcomeRecorded, true);
});

Deno.test("valid Instagram post/reel runs through pipeline without requiring OAuth or connection data", async () => {
  let quotaCalled = false;
  let connectionQueried = false;

  const mockAdmin = createMockAdminClient({
    onQuotaRpc: () => {
      quotaCalled = true;
    },
    onConnectionQuery: () => {
      connectionQueried = true;
    },
  });

  const request = new Request("https://localhost/generate-restaurant-listing", {
    method: "POST",
    headers: {
      authorization: "Bearer valid-creator-jwt",
      "content-type": "application/json",
    },
    body: JSON.stringify({
      sourceUrl: "https://www.instagram.com/reel/C8xyz123AbC/",
    }),
  });

  const response = await handleGenerateRequest(request, {
    authClient: createMockAuthClient(),
    adminClient: mockAdmin,
    env: {
      AI_PROVIDER: "openai_compatible",
      AI_API_KEY: "test-key",
      AI_MODEL: "gpt-4o-mini",
      META_GRAPH_API_VERSION: "v20.0",
      INSTAGRAM_OEMBED_ACCESS_TOKEN: "mock-meta-token",
    },
    fetcher: (url, _init) => {
      const urlStr = String(url);
      if (urlStr.includes("instagram_oembed")) {
        return Promise.resolve(
          new Response(
            JSON.stringify({
              author_name: "penangeats",
              title:
                "Deen Maju Nasi Kandar in Jalan Gurdwara George Town Penang",
            }),
            { status: 200 },
          ),
        );
      }
      if (urlStr.includes("chat/completions")) {
        return Promise.resolve(
          new Response(
            JSON.stringify({
              choices: [{
                message: {
                  content: JSON.stringify({
                    candidates: [{
                      restaurantName: "Deen Maju Nasi Kandar",
                      address: "Jalan Gurdwara",
                      state: "Pulau Pinang",
                      city: "George Town",
                      cuisineType: null,
                      priceRange: null,
                      reviewedDishes: ["Nasi Kandar"],
                      sourcePostUrl:
                        "https://www.instagram.com/reel/C8xyz123AbC/",
                      confidence: 0.92,
                      missingFields: [],
                    }],
                  }),
                },
              }],
            }),
            { status: 200 },
          ),
        );
      }
      throw new Error(`Unexpected fetch URL: ${urlStr}`);
    },
  });

  equal(response.status, 200);
  const data = await response.json();
  equal(data.sourceType, "post");
  equal(data.platform, "instagram");
  equal(data.candidates.length, 1);
  equal(data.candidates[0].restaurantName, "Deen Maju Nasi Kandar");
  equal(quotaCalled, true);
  equal(connectionQueried, false);
});

Deno.test("tourist is denied Creator generation after successful authorization lookups", async () => {
  const request = new Request("https://localhost/generate-restaurant-listing", {
    method: "POST",
    headers: {
      authorization: "Bearer valid-tourist-jwt",
      "content-type": "application/json",
    },
    body: JSON.stringify({
      sourceUrl: "https://www.tiktok.com/@creator/video/7123456789012345678",
    }),
  });

  const response = await handleGenerateRequest(request, {
    authClient: createMockAuthClient(),
    adminClient: createMockAdminClient({ role: "tourist" }),
  });

  equal(response.status, 403);
  const data = await response.json();
  equal(data.error?.code, "INFLUENCER_REQUIRED");
});

Deno.test("account access lookup failure is a sanitized 503, not Creator-required", async () => {
  const request = new Request("https://localhost/generate-restaurant-listing", {
    method: "POST",
    headers: {
      authorization: "Bearer valid-creator-jwt",
      "content-type": "application/json",
    },
    body: JSON.stringify({
      sourceUrl: "https://www.tiktok.com/@creator/video/7123456789012345678",
    }),
  });

  const response = await handleGenerateRequest(request, {
    authClient: createMockAuthClient(),
    adminClient: createMockAdminClient({ accessLookupFails: true }),
  });

  equal(response.status, 503);
  const data = await response.json();
  equal(data.error?.code, "AUTHORIZATION_CHECK_FAILED");
  equal(data.error?.message, "Creator access could not be checked");
});

function equal(actual: unknown, expected: unknown) {
  if (actual !== expected) {
    throw new Error(
      `Expected ${JSON.stringify(expected)} but got ${JSON.stringify(actual)}`,
    );
  }
}
