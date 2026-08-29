import {
  callGooglePlaces,
  getPlacesApiKey,
  PlacesError,
} from "../_shared/google_places.ts";
import type {
  DetectedSource,
  GeneratedRestaurantListing,
  SocialSourceContent,
} from "./types.ts";
import { GenerationError } from "./types.ts";
import { resolvePublicSocialPostUrl } from "./social_source.ts";

const MAPS_FIELD_MASK = [
  "id",
  "displayName",
  "primaryType",
  "formattedAddress",
  "location",
  "priceLevel",
  "addressComponents.longText",
  "addressComponents.types",
].join(",");

const MAPS_SEARCH_FIELD_MASK = MAPS_FIELD_MASK.split(",")
  .map((field) => `places.${field}`).join(",");

export async function fetchGoogleMapsSource(
  detection: DetectedSource,
  configuration: { apiKey?: string },
  fetcher: typeof fetch = fetch,
): Promise<SocialSourceContent> {
  let resolved: URL;
  try {
    resolved = await resolveGoogleMapsUrl(detection.normalizedUrl, fetcher);
    const apiKey = configuration.apiKey?.trim() || getPlacesApiKey();
    let raw: Record<string, unknown> | null = null;
    const placeId = extractPlaceId(resolved);
    if (placeId) {
      raw = await callGooglePlaces(
        `https://places.googleapis.com/v1/places/${
          encodeURIComponent(placeId)
        }?languageCode=en&regionCode=MY`,
        { apiKey, fieldMask: MAPS_FIELD_MASK, method: "GET", fetcher },
      );
    } else {
      const query = extractMapsQuery(resolved);
      if (!query) {
        throw new GenerationError(
          "MAPS_PLACE_NOT_FOUND",
          "Google Maps place could not be identified",
          404,
        );
      }
      const locationBias = extractCoordinates(resolved);
      const body: Record<string, unknown> = {
        textQuery: query,
        pageSize: 1,
        languageCode: "en",
        regionCode: "MY",
        locationRestriction: {
          rectangle: {
            low: { latitude: 0.8, longitude: 99.5 },
            high: { latitude: 7.5, longitude: 119.5 },
          },
        },
      };
      if (locationBias) {
        delete body.locationRestriction;
        body.locationBias = {
          circle: { center: locationBias, radius: 5000 },
        };
      }
      const result = await callGooglePlaces(
        "https://places.googleapis.com/v1/places:searchText",
        { apiKey, fieldMask: MAPS_SEARCH_FIELD_MASK, body, fetcher },
      );
      raw = Array.isArray(result.places) && result.places[0] &&
          typeof result.places[0] === "object"
        ? result.places[0] as Record<string, unknown>
        : null;
    }
    if (!raw) {
      throw new GenerationError(
        "MAPS_PLACE_NOT_FOUND",
        "Google Maps place could not be identified",
        404,
      );
    }
    const candidate = candidateFromGooglePlace(raw, detection.normalizedUrl);
    return {
      detection,
      posts: [{
        sourcePlatform: "google_maps",
        sourcePostUrl: detection.normalizedUrl,
        influencerUsername: null,
        sourceCaption: JSON.stringify(raw).slice(0, 5000),
      }],
      authoritativeCandidate: candidate,
      fallbackCandidate: candidate,
    };
  } catch (error) {
    if (error instanceof GenerationError) throw error;
    if (error instanceof PlacesError) {
      throw new GenerationError(error.code, error.message, error.status);
    }
    throw new GenerationError(
      "MAPS_PLACE_NOT_FOUND",
      "Google Maps place could not be identified",
      404,
    );
  }
}

export async function fetchWebsiteSource(
  detection: DetectedSource,
  fetcher: typeof fetch = fetch,
): Promise<SocialSourceContent> {
  const metadata = await fetchPublicPageMetadata(
    detection.normalizedUrl,
    fetcher,
    false,
  );
  const structured = findBusinessJsonLd(metadata.jsonLd);
  const candidate = candidateFromWebsite(
    detection.normalizedUrl,
    structured,
    metadata,
  );
  const sourceCaption = [
    metadata.title,
    metadata.description,
    metadata.visibleText,
    structured ? JSON.stringify(structured) : null,
  ].filter(Boolean).join("\n").slice(0, 5000);
  return {
    detection,
    posts: [{
      sourcePlatform: "website",
      sourcePostUrl: detection.normalizedUrl,
      influencerUsername: null,
      sourceCaption: sourceCaption || null,
    }],
    fallbackCandidate: candidate,
  };
}

export async function fetchSocialMetadataFallback(
  detection: DetectedSource,
  fetcher: typeof fetch = fetch,
  configuration?: { apiKey?: string; restaurantName?: string },
): Promise<SocialSourceContent> {
  let title: string | null = null;
  let description: string | null = null;
  try {
    const resolved = await resolvePublicSocialPostUrl(detection, fetcher);
    const metadata = await fetchPublicPageMetadata(
      resolved.toString(),
      fetcher,
      true,
    );
    title = metadata.title;
    description = metadata.description;
  } catch (_) {
    // The URL itself remains useful provenance for a manual partial draft.
  }
  const fallback = emptyCandidate(
    detection.platform,
    detection.normalizedUrl,
    normalizedRestaurantName(configuration?.restaurantName),
  );
  const source: SocialSourceContent = {
    detection,
    posts: [{
      sourcePlatform: detection.platform,
      sourcePostUrl: detection.normalizedUrl,
      influencerUsername: null,
      sourceCaption: [title, description].filter(Boolean).join("\n") || null,
    }],
    fallbackCandidate: fallback,
  };
  return await enrichSocialSourceWithGoogleMatch(source, {
    apiKey: configuration?.apiKey,
    restaurantName: configuration?.restaurantName,
  }, fetcher);
}

export async function enrichSocialSourceWithGoogleMatch(
  source: SocialSourceContent,
  configuration?: { apiKey?: string; restaurantName?: string },
  fetcher: typeof fetch = fetch,
): Promise<SocialSourceContent> {
  if (
    source.detection.platform !== "instagram" &&
    source.detection.platform !== "tiktok"
  ) return source;

  const enrichedSource = await appendPublicSocialMetadata(source, fetcher);

  const apiKey = configuration?.apiKey?.trim();
  const restaurantName = normalizedRestaurantName(
    configuration?.restaurantName,
  );
  const signal = enrichedSource.posts.flatMap((post) => [
    post.influencerUsername ? `@${post.influencerUsername}` : null,
    post.sourceCaption,
  ]).filter(Boolean).join("\n").slice(0, 6000);
  if (!apiKey) {
    return restaurantName
      ? {
        ...enrichedSource,
        fallbackCandidate: emptyCandidate(
          enrichedSource.detection.platform,
          enrichedSource.detection.normalizedUrl,
          restaurantName,
        ),
      }
      : enrichedSource;
  }

  const queries = socialPlaceQueries(restaurantName, signal);
  for (const query of queries) {
    try {
      const result = await callGooglePlaces(
        "https://places.googleapis.com/v1/places:searchText",
        {
          apiKey,
          fieldMask: MAPS_SEARCH_FIELD_MASK,
          body: {
            textQuery: query,
            pageSize: 3,
            languageCode: "en",
            regionCode: "MY",
            locationRestriction: {
              rectangle: {
                low: { latitude: 0.8, longitude: 99.5 },
                high: { latitude: 7.5, longitude: 119.5 },
              },
            },
          },
          fetcher,
        },
      );
      const matched = (Array.isArray(result.places) ? result.places : [])
        .filter((place): place is Record<string, unknown> =>
          Boolean(place) && typeof place === "object"
        )
        .find((place) =>
          confidentSocialPlaceMatch(
            place,
            restaurantName ? `${restaurantName}\n${signal}` : signal,
          )
        );
      if (!matched) continue;
      const fallback = candidateFromGooglePlace(
        matched,
        enrichedSource.detection.normalizedUrl,
      );
      fallback.sourcePlatform = enrichedSource.detection.platform;
      fallback.influencerUsername =
        enrichedSource.posts[0]?.influencerUsername ?? null;
      fallback.sourceCaption = signal || null;
      fallback.confidence = restaurantName ? 0.95 : 0.85;
      fallback.missingFields = missingFields(fallback);
      return { ...enrichedSource, fallbackCandidate: fallback };
    } catch (_) {
      // Matching is a best-effort enrichment. The preserved source and manual
      // form remain usable when Google is temporarily unavailable.
    }
  }

  if (restaurantName) {
    return {
      ...enrichedSource,
      fallbackCandidate: emptyCandidate(
        enrichedSource.detection.platform,
        enrichedSource.detection.normalizedUrl,
        restaurantName,
      ),
    };
  }
  return enrichedSource;
}

async function appendPublicSocialMetadata(
  source: SocialSourceContent,
  fetcher: typeof fetch,
): Promise<SocialSourceContent> {
  try {
    const resolved = await resolvePublicSocialPostUrl(
      source.detection,
      fetcher,
    );
    const metadata = await fetchPublicPageMetadata(
      resolved.toString(),
      fetcher,
      true,
    );
    const publicSignal = [metadata.title, metadata.description]
      .filter(Boolean)
      .join("\n");
    if (!publicSignal) return source;
    const first = source.posts[0] ?? {
      sourcePlatform: source.detection.platform,
      sourcePostUrl: source.detection.normalizedUrl,
      influencerUsername: null,
      sourceCaption: null,
    };
    const combined = [first.sourceCaption, publicSignal]
      .filter(Boolean)
      .join("\n")
      .slice(0, 5000);
    return {
      ...source,
      posts: [
        { ...first, sourceCaption: combined || null },
        ...source.posts.slice(1),
      ],
    };
  } catch (_) {
    return source;
  }
}

export function mergeGeneratedWithFallback(
  generated: GeneratedRestaurantListing,
  fallback: GeneratedRestaurantListing | undefined,
): GeneratedRestaurantListing {
  const generatedName = meaningfulGeneratedRestaurantName(generated);
  const result: GeneratedRestaurantListing = {
    restaurantName: generatedName ?? fallback?.restaurantName ?? null,
    address: generated.address ?? fallback?.address ?? null,
    state: generated.state ?? fallback?.state ?? null,
    city: generated.city ?? fallback?.city ?? null,
    cuisineType: generated.cuisineType ?? fallback?.cuisineType ?? null,
    priceRange: generated.priceRange ?? fallback?.priceRange ?? null,
    reviewedDishes: generated.reviewedDishes.length > 0
      ? generated.reviewedDishes
      : fallback?.reviewedDishes ?? [],
    sourcePlatform: generated.sourcePlatform,
    sourcePostUrl: generated.sourcePostUrl,
    influencerUsername: generated.influencerUsername ??
      fallback?.influencerUsername ?? null,
    sourceCaption: generated.sourceCaption ?? fallback?.sourceCaption ?? null,
    confidence: Math.max(generated.confidence, fallback?.confidence ?? 0),
    missingFields: [],
  };
  result.missingFields = missingFields(result);
  return result;
}

function meaningfulGeneratedRestaurantName(
  generated: GeneratedRestaurantListing,
): string | null {
  const name = generated.restaurantName?.trim();
  if (!name) return null;
  if (
    generated.sourcePlatform === "instagram" ||
    generated.sourcePlatform === "tiktok"
  ) {
    const generic = new Set([
      "instagram",
      "tiktok",
      "restaurant",
      "cafe",
      "unknown",
      "unknown restaurant",
    ]);
    if (generic.has(name.toLowerCase())) return null;
  }
  return name;
}

function normalizedRestaurantName(value: string | undefined): string | null {
  const name = value?.replace(/\s+/g, " ").trim();
  return name && name.length >= 2 && name.length <= 120 ? name : null;
}

function socialPlaceQueries(
  restaurantName: string | null,
  signal: string,
): string[] {
  const queries: string[] = [];
  if (restaurantName) queries.push(`${restaurantName} Malaysia`);

  for (const match of signal.matchAll(/@([a-z0-9._]{3,60})/gi)) {
    const handle = match[1].replace(/[._]+/g, " ").trim();
    if (handle) queries.push(`${handle} Malaysia restaurant`);
  }

  const caption = signal
    .replace(/^.*?\bon (?:instagram|tiktok)\s*:\s*/i, "")
    .replace(/^\d[\d,]*\s+(?:likes?|comments?).*?:\s*/i, "")
    .replace(/#[a-z0-9_]+/gi, " ")
    .replace(/\s+/g, " ")
    .replace(/^["“]|["”]$/g, "")
    .trim();
  if (caption.length >= 3) queries.push(caption.slice(0, 180));

  return [...new Set(queries.map((value) => value.trim()))].slice(0, 4);
}

function confidentSocialPlaceMatch(
  place: Record<string, unknown>,
  signal: string,
): boolean {
  const primaryType = typeof place.primaryType === "string"
    ? place.primaryType
    : "";
  if (
    primaryType &&
    !primaryType.endsWith("_restaurant") &&
    ![
      "restaurant",
      "cafe",
      "coffee_shop",
      "bakery",
      "cake_shop",
      "dessert_shop",
      "food_court",
      "ice_cream_shop",
      "juice_shop",
      "meal_takeaway",
      "sandwich_shop",
      "tea_house",
      "bar",
    ].includes(primaryType)
  ) return false;

  const display = place.displayName as Record<string, unknown> | undefined;
  const name = typeof display?.text === "string" ? display.text : "";
  const compactSignal = compactComparable(signal);
  const compactName = compactComparable(name);
  if (compactName.length >= 5 && compactSignal.includes(compactName)) {
    return true;
  }
  const tokens = comparableTokens(name);
  if (tokens.length === 0) return false;
  const matched = tokens.filter((token) => compactSignal.includes(token));
  return matched.length >= Math.min(2, tokens.length) &&
    matched.length / tokens.length >= 0.5;
}

function compactComparable(value: string): string {
  return value.toLowerCase().normalize("NFKD")
    .replace(/[^a-z0-9]+/g, "");
}

function comparableTokens(value: string): string[] {
  const ignored = new Set([
    "cafe",
    "restaurant",
    "restoran",
    "kopitiam",
    "bakery",
    "kitchen",
    "the",
    "and",
  ]);
  return value.toLowerCase().normalize("NFKD").split(/[^a-z0-9]+/)
    .filter((token) => token.length >= 3 && !ignored.has(token));
}

async function resolveGoogleMapsUrl(
  value: string,
  fetcher: typeof fetch,
): Promise<URL> {
  let current = new URL(value);
  for (let redirects = 0; redirects < 5; redirects += 1) {
    assertGoogleMapsHost(current);
    if (current.hostname !== "maps.app.goo.gl") return current;
    const response = await fetcher(current, {
      method: "GET",
      redirect: "manual",
      signal: AbortSignal.timeout(10_000),
      headers: { "user-agent": "LiveLocal/1.0 place-import" },
    });
    await response.body?.cancel();
    const location = response.headers.get("location");
    if (!location) {
      if (response.url) {
        const finalUrl = new URL(response.url);
        assertGoogleMapsHost(finalUrl);
        return finalUrl;
      }
      throw new GenerationError(
        "MAPS_PLACE_NOT_FOUND",
        "Maps link did not resolve",
        404,
      );
    }
    current = new URL(location, current);
  }
  throw new GenerationError(
    "MAPS_PLACE_NOT_FOUND",
    "Maps link redirected too many times",
    400,
  );
}

function assertGoogleMapsHost(url: URL): void {
  const host = url.hostname.toLowerCase();
  const valid = host === "maps.app.goo.gl" || host === "maps.google.com" ||
    host === "google.com" || host === "www.google.com";
  if (url.protocol !== "https:" || !valid) {
    throw new GenerationError("INVALID_SOURCE_URL", "Invalid Google Maps URL");
  }
}

function extractPlaceId(url: URL): string | null {
  const queryId = url.searchParams.get("query_place_id") ??
    url.searchParams.get("place_id");
  if (queryId && /^[A-Za-z0-9_-]{8,256}$/.test(queryId)) return queryId;
  const decoded = decodeURIComponent(url.toString());
  const dataId = decoded.match(/!1s([A-Za-z0-9_-]{8,256})(?:!|$)/)?.[1];
  return dataId ?? null;
}

function extractMapsQuery(url: URL): string | null {
  const query = url.searchParams.get("query") ?? url.searchParams.get("q");
  if (query?.trim()) return query.trim().slice(0, 160);
  const match = url.pathname.match(/\/maps\/place\/([^/]+)/i);
  if (!match) return null;
  const value = decodeURIComponent(match[1]).replace(/\+/g, " ").trim();
  return value ? value.slice(0, 160) : null;
}

function extractCoordinates(
  url: URL,
): { latitude: number; longitude: number } | null {
  const match = decodeURIComponent(url.toString()).match(
    /@(-?\d{1,2}(?:\.\d+)?),(-?\d{1,3}(?:\.\d+)?)/,
  );
  if (!match) return null;
  const latitude = Number(match[1]);
  const longitude = Number(match[2]);
  return Number.isFinite(latitude) && Number.isFinite(longitude)
    ? { latitude, longitude }
    : null;
}

function candidateFromGooglePlace(
  raw: Record<string, unknown>,
  sourceUrl: string,
): GeneratedRestaurantListing {
  const display = raw.displayName as Record<string, unknown> | undefined;
  const components = Array.isArray(raw.addressComponents)
    ? raw.addressComponents as Record<string, unknown>[]
    : [];
  const component = (...types: string[]): string | null => {
    const found = components.find((item) => {
      const itemTypes = Array.isArray(item.types) ? item.types : [];
      return types.some((type) => itemTypes.includes(type));
    });
    return typeof found?.longText === "string" ? found.longText : null;
  };
  const primaryType = typeof raw.primaryType === "string"
    ? raw.primaryType
    : null;
  const result: GeneratedRestaurantListing = {
    restaurantName: typeof display?.text === "string" ? display.text : null,
    address: typeof raw.formattedAddress === "string"
      ? raw.formattedAddress
      : null,
    state: component("administrative_area_level_1"),
    city: component("locality", "postal_town", "administrative_area_level_2"),
    cuisineType: primaryType
      ? titleCase(primaryType.replaceAll("_", " "))
      : null,
    priceRange: googlePrice(raw.priceLevel),
    reviewedDishes: [],
    sourcePlatform: "google_maps",
    sourcePostUrl: sourceUrl,
    influencerUsername: null,
    sourceCaption: null,
    confidence: 1,
    missingFields: [],
  };
  result.missingFields = missingFields(result);
  return result;
}

type PageMetadata = {
  title: string | null;
  description: string | null;
  visibleText: string | null;
  jsonLd: unknown[];
};

async function fetchPublicPageMetadata(
  value: string,
  fetcher: typeof fetch,
  allowSocialHosts: boolean,
): Promise<PageMetadata> {
  let current = new URL(value);
  for (let redirects = 0; redirects < 4; redirects += 1) {
    await assertFetchableHost(
      current,
      allowSocialHosts,
      fetcher === fetch,
    );
    let response: Response;
    try {
      response = await fetcher(current, {
        method: "GET",
        redirect: "manual",
        signal: AbortSignal.timeout(12_000),
        headers: {
          accept: "text/html,application/xhtml+xml",
          "user-agent": "LiveLocal/1.0 public-metadata-import",
        },
      });
    } catch (_) {
      throw new GenerationError(
        "WEBSITE_UNAVAILABLE",
        "Website could not be read",
        503,
      );
    }
    if (response.status >= 300 && response.status < 400) {
      const location = response.headers.get("location");
      await response.body?.cancel();
      if (!location) {
        throw new GenerationError(
          "WEBSITE_UNAVAILABLE",
          "Website redirect failed",
          503,
        );
      }
      current = new URL(location, current);
      continue;
    }
    if (!response.ok) {
      await response.body?.cancel();
      throw new GenerationError(
        "WEBSITE_UNAVAILABLE",
        "Website could not be read",
        503,
      );
    }
    const contentType = response.headers.get("content-type")?.toLowerCase() ??
      "";
    if (
      !contentType.includes("text/html") &&
      !contentType.includes("application/xhtml+xml")
    ) {
      await response.body?.cancel();
      throw new GenerationError(
        "WEBSITE_UNAVAILABLE",
        "Website is not an HTML page",
        400,
      );
    }
    const html = await readLimitedText(
      response,
      512 * 1024,
      allowSocialHosts,
    );
    return extractMetadata(html);
  }
  throw new GenerationError(
    "WEBSITE_UNAVAILABLE",
    "Website redirected too many times",
    400,
  );
}

async function assertFetchableHost(
  url: URL,
  allowSocialHosts: boolean,
  resolveDns: boolean,
): Promise<void> {
  if (url.protocol !== "https:" || url.port || url.username || url.password) {
    throw new GenerationError(
      "INVALID_SOURCE_URL",
      "Invalid public website URL",
    );
  }
  const host = url.hostname.toLowerCase().replace(/^\[|\]$/g, "");
  if (
    allowSocialHosts && (
      host === "instagram.com" || host === "www.instagram.com" ||
      host === "tiktok.com" || host === "www.tiktok.com" ||
      host === "vm.tiktok.com" || host === "vt.tiktok.com"
    )
  ) return;
  if (
    !host.includes(".") || host === "localhost" || host.endsWith(".local") ||
    isPrivateIp(host)
  ) {
    throw new GenerationError(
      "INVALID_SOURCE_URL",
      "Invalid public website URL",
    );
  }
  if (!resolveDns) return;
  let addresses: string[];
  try {
    const [ipv4, ipv6] = await Promise.all([
      Deno.resolveDns(host, "A"),
      Deno.resolveDns(host, "AAAA").catch(() => []),
    ]);
    addresses = [...ipv4, ...ipv6];
  } catch (_) {
    throw new GenerationError(
      "WEBSITE_UNAVAILABLE",
      "Website host could not be resolved",
      503,
    );
  }
  if (addresses.length === 0 || addresses.some(isPrivateIp)) {
    throw new GenerationError(
      "INVALID_SOURCE_URL",
      "Invalid public website URL",
    );
  }
}

function isPrivateIp(host: string): boolean {
  const parts = host.split(".").map(Number);
  if (parts.length === 4 && parts.every(Number.isInteger)) {
    return parts.some((part) => part < 0 || part > 255) ||
      parts[0] === 0 || parts[0] === 10 || parts[0] === 127 ||
      (parts[0] === 169 && parts[1] === 254) ||
      (parts[0] === 172 && parts[1] >= 16 && parts[1] <= 31) ||
      (parts[0] === 192 && parts[1] === 168) || parts[0] >= 224;
  }
  const normalized = host.toLowerCase();
  return normalized === "::" || normalized === "::1" ||
    normalized.startsWith("fc") || normalized.startsWith("fd") ||
    /^fe[89ab]/.test(normalized);
}

async function readLimitedText(
  response: Response,
  limit: number,
  truncateAtLimit = false,
): Promise<string> {
  if (!response.body) return "";
  const reader = response.body.getReader();
  const chunks: Uint8Array[] = [];
  let size = 0;
  while (true) {
    const { value, done } = await reader.read();
    if (done) break;
    if (!value) continue;
    if (size + value.length > limit) {
      if (!truncateAtLimit) {
        await reader.cancel();
        throw new GenerationError(
          "WEBSITE_TOO_LARGE",
          "Website content is too large",
          400,
        );
      }
      const remaining = limit - size;
      if (remaining > 0) chunks.push(value.slice(0, remaining));
      size = limit;
      await reader.cancel();
      break;
    }
    size += value.length;
    chunks.push(value);
  }
  const joined = new Uint8Array(size);
  let offset = 0;
  for (const chunk of chunks) {
    joined.set(chunk, offset);
    offset += chunk.length;
  }
  return new TextDecoder().decode(joined);
}

function extractMetadata(html: string): PageMetadata {
  const meta = (property: string): string | null => {
    const escaped = property.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const patterns = [
      new RegExp(
        `<meta[^>]+(?:property|name)=["']${escaped}["'][^>]+content=["']([^"']*)["'][^>]*>`,
        "i",
      ),
      new RegExp(
        `<meta[^>]+content=["']([^"']*)["'][^>]+(?:property|name)=["']${escaped}["'][^>]*>`,
        "i",
      ),
    ];
    for (const pattern of patterns) {
      const match = html.match(pattern)?.[1];
      if (match) return cleanText(match, 1000);
    }
    return null;
  };
  const title = meta("og:title") ??
    cleanText(html.match(/<title[^>]*>([\s\S]*?)<\/title>/i)?.[1], 300);
  const description = meta("og:description") ?? meta("description");
  const jsonLd: unknown[] = [];
  for (
    const match of html.matchAll(
      /<script[^>]+type=["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi,
    )
  ) {
    if (jsonLd.length >= 10) break;
    try {
      jsonLd.push(JSON.parse(match[1]));
    } catch (_) {
      // Invalid third-party JSON-LD is ignored; metadata/text can still help.
    }
  }
  const visibleText = cleanText(
    html.replace(/<script\b[^>]*>[\s\S]*?<\/script>/gi, " ")
      .replace(/<style\b[^>]*>[\s\S]*?<\/style>/gi, " ")
      .replace(/<[^>]+>/g, " "),
    4000,
  );
  return { title, description, visibleText, jsonLd };
}

function findBusinessJsonLd(values: unknown[]): Record<string, unknown> | null {
  const queue = [...values];
  while (queue.length > 0) {
    const value = queue.shift();
    if (Array.isArray(value)) {
      queue.push(...value);
      continue;
    }
    if (!value || typeof value !== "object") continue;
    const object = value as Record<string, unknown>;
    if (Array.isArray(object["@graph"])) {
      queue.push(...object["@graph"] as unknown[]);
    }
    const rawType = object["@type"];
    const types = Array.isArray(rawType) ? rawType : [rawType];
    if (
      types.some((type) =>
        typeof type === "string" &&
        ["Restaurant", "LocalBusiness", "FoodEstablishment", "CafeOrCoffeeShop"]
          .includes(type)
      )
    ) return object;
  }
  return null;
}

function candidateFromWebsite(
  sourceUrl: string,
  structured: Record<string, unknown> | null,
  metadata: PageMetadata,
): GeneratedRestaurantListing {
  const addressValue = structured?.address;
  const address = addressValue && typeof addressValue === "object"
    ? addressValue as Record<string, unknown>
    : null;
  const cuisine = structured?.servesCuisine;
  const cuisineText = Array.isArray(cuisine)
    ? cuisine.filter((value): value is string => typeof value === "string")
      .join(", ")
    : typeof cuisine === "string"
    ? cuisine
    : null;
  const name = text(structured?.name) ?? metadata.title;
  const result: GeneratedRestaurantListing = {
    restaurantName: name,
    address: address
      ? [
        address.streetAddress,
        address.postalCode,
        address.addressLocality,
        address.addressRegion,
      ]
        .map(text).filter(Boolean).join(", ") || null
      : text(addressValue),
    state: text(address?.addressRegion),
    city: text(address?.addressLocality),
    cuisineType: cuisineText,
    priceRange: normalizedPrice(structured?.priceRange),
    reviewedDishes: [],
    sourcePlatform: "website",
    sourcePostUrl: sourceUrl,
    influencerUsername: null,
    sourceCaption: metadata.description,
    confidence: structured ? 0.95 : name ? 0.35 : 0,
    missingFields: [],
  };
  result.missingFields = missingFields(result);
  return result;
}

function emptyCandidate(
  platform: "tiktok" | "instagram" | "google_maps" | "website",
  sourceUrl: string,
  title: string | null,
): GeneratedRestaurantListing {
  const result: GeneratedRestaurantListing = {
    restaurantName: title,
    address: null,
    state: null,
    city: null,
    cuisineType: null,
    priceRange: null,
    reviewedDishes: [],
    sourcePlatform: platform,
    sourcePostUrl: sourceUrl,
    influencerUsername: null,
    sourceCaption: title,
    confidence: title ? 0.2 : 0,
    missingFields: [],
  };
  result.missingFields = missingFields(result);
  return result;
}

function missingFields(candidate: GeneratedRestaurantListing): string[] {
  return [
    "restaurantName",
    "address",
    "state",
    "city",
    "cuisineType",
    "priceRange",
    "reviewedDishes",
  ].filter((field) => {
    const value = candidate[field as keyof GeneratedRestaurantListing];
    return Array.isArray(value) ? value.length === 0 : !value;
  });
}

function googlePrice(value: unknown): string | null {
  switch (value) {
    case "PRICE_LEVEL_FREE":
    case "PRICE_LEVEL_INEXPENSIVE":
      return "$";
    case "PRICE_LEVEL_MODERATE":
      return "$$";
    case "PRICE_LEVEL_EXPENSIVE":
      return "$$$";
    case "PRICE_LEVEL_VERY_EXPENSIVE":
      return "$$$$";
    default:
      return null;
  }
}

function normalizedPrice(value: unknown): string | null {
  const parsed = text(value);
  if (!parsed) return null;
  const symbols = parsed.match(/\$/g)?.length ?? 0;
  return symbols >= 1 && symbols <= 4 ? "$".repeat(symbols) : null;
}

function text(value: unknown): string | null {
  return typeof value === "string" && value.trim()
    ? value.trim().slice(0, 1000)
    : null;
}

function cleanText(value: string | undefined, limit: number): string | null {
  if (!value) return null;
  const cleaned = value.replace(/&amp;/gi, "&").replace(/&quot;/gi, '"')
    .replace(/&#39;/gi, "'").replace(/&lt;/gi, "<").replace(/&gt;/gi, ">")
    .replace(
      /&#x([0-9a-f]+);/gi,
      (_, code: string) => safeCodePoint(Number.parseInt(code, 16)),
    )
    .replace(
      /&#(\d+);/g,
      (_, code: string) => safeCodePoint(Number.parseInt(code, 10)),
    )
    .replace(/\s+/g, " ").trim();
  return cleaned ? cleaned.slice(0, limit) : null;
}

function safeCodePoint(value: number): string {
  if (!Number.isInteger(value) || value < 0 || value > 0x10ffff) return "";
  try {
    return String.fromCodePoint(value);
  } catch (_) {
    return "";
  }
}

function titleCase(value: string): string {
  return value.replace(/\b\w/g, (letter) => letter.toUpperCase());
}
