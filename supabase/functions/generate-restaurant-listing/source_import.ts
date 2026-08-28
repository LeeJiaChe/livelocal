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
  configuration?: { apiKey?: string },
): Promise<SocialSourceContent> {
  let title: string | null = null;
  let description: string | null = null;
  try {
    const metadata = await fetchPublicPageMetadata(
      detection.normalizedUrl,
      fetcher,
      true,
    );
    title = metadata.title;
    description = metadata.description;
  } catch (_) {
    // The URL itself remains useful provenance for a manual partial draft.
  }
  let fallback = emptyCandidate(
    detection.platform,
    detection.normalizedUrl,
    title,
  );
  const apiKey = configuration?.apiKey?.trim();
  const query = [title, description].filter(Boolean).join(" ").trim()
    .slice(0, 160);
  if (apiKey && query.length >= 2) {
    try {
      const result = await callGooglePlaces(
        "https://places.googleapis.com/v1/places:searchText",
        {
          apiKey,
          fieldMask: MAPS_SEARCH_FIELD_MASK,
          body: {
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
          },
          fetcher,
        },
      );
      const matched = Array.isArray(result.places) && result.places[0] &&
          typeof result.places[0] === "object"
        ? result.places[0] as Record<string, unknown>
        : null;
      if (matched) {
        fallback = candidateFromGooglePlace(
          matched,
          detection.normalizedUrl,
        );
        fallback.sourcePlatform = detection.platform;
        fallback.sourceCaption =
          [title, description].filter(Boolean).join("\n") ||
          null;
      }
    } catch (_) {
      // Google matching enriches the partial draft when available, but a
      // provider/configuration failure must not turn social fallback into a
      // dead end.
    }
  }
  return {
    detection,
    posts: [{
      sourcePlatform: detection.platform,
      sourcePostUrl: detection.normalizedUrl,
      influencerUsername: null,
      sourceCaption: [title, description].filter(Boolean).join("\n") || null,
    }],
    fallbackCandidate: fallback,
  };
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
    const html = await readLimitedText(response, 512 * 1024);
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
): Promise<string> {
  if (!response.body) return "";
  const reader = response.body.getReader();
  const chunks: Uint8Array[] = [];
  let size = 0;
  while (true) {
    const { value, done } = await reader.read();
    if (done) break;
    if (!value) continue;
    size += value.length;
    if (size > limit) {
      await reader.cancel();
      throw new GenerationError(
        "WEBSITE_TOO_LARGE",
        "Website content is too large",
        400,
      );
    }
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
    .replace(/\s+/g, " ").trim();
  return cleaned ? cleaned.slice(0, limit) : null;
}

function titleCase(value: string): string {
  return value.replace(/\b\w/g, (letter) => letter.toUpperCase());
}
