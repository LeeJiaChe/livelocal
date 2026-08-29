export const SEARCH_FIELD_MASK = [
  "places.id",
  "places.displayName",
  "places.primaryType",
  "places.types",
  "places.formattedAddress",
  "places.location",
  "places.rating",
  "places.userRatingCount",
  "places.priceLevel",
  "places.currentOpeningHours.openNow",
  "nextPageToken",
].join(",");

export const NEARBY_FIELD_MASK = [
  "places.id",
  "places.displayName",
  "places.primaryType",
  "places.types",
  "places.formattedAddress",
  "places.location",
  "places.rating",
  "places.userRatingCount",
  "places.priceLevel",
  "places.currentOpeningHours.openNow",
].join(",");

export const DETAILS_FIELD_MASK = [
  "id",
  "displayName",
  "primaryType",
  "types",
  "formattedAddress",
  "location",
  "rating",
  "userRatingCount",
  "priceLevel",
  "currentOpeningHours.openNow",
  "regularOpeningHours.weekdayDescriptions",
  "nationalPhoneNumber",
  "websiteUri",
  "googleMapsUri",
  "photos.name",
].join(",");

export const corsJsonHeaders = {
  "access-control-allow-origin": "*",
  "access-control-allow-headers": "authorization, apikey, content-type",
  "content-type": "application/json; charset=utf-8",
};

export type GooglePlaceResponse = Record<string, unknown>;

export class PlacesError extends Error {
  constructor(
    public readonly code: string,
    message: string,
    public readonly status = 400,
  ) {
    super(message);
  }
}

const CATEGORY_TYPES: Record<string, string> = {
  restaurant: "restaurant",
  cafe: "cafe",
  attraction: "tourist_attraction",
  museum: "museum",
  park: "park",
  beach: "beach",
  shopping: "shopping_mall",
};

const MALAYSIA_BOUNDS = {
  minimumLatitude: 0.8,
  maximumLatitude: 7.5,
  minimumLongitude: 99.5,
  maximumLongitude: 119.5,
};

export function placeTypeForCategory(value: unknown): string | undefined {
  if (value === undefined || value === null || value === "") return undefined;
  if (typeof value !== "string") {
    throw new PlacesError("INVALID_CATEGORY", "Invalid place category");
  }
  const normalized = value.trim().toLowerCase();
  const type = CATEGORY_TYPES[normalized];
  if (!type) {
    throw new PlacesError("INVALID_CATEGORY", "Invalid place category");
  }
  return type;
}

export function numberInRange(
  value: unknown,
  field: string,
  minimum: number,
  maximum: number,
): number {
  if (typeof value !== "number" || !Number.isFinite(value)) {
    throw new PlacesError("INVALID_LOCATION", `Invalid ${field}`);
  }
  if (value < minimum || value > maximum) {
    throw new PlacesError("INVALID_LOCATION", `Invalid ${field}`);
  }
  return value;
}

export function assertMalaysiaLocation(
  latitude: number,
  longitude: number,
): void {
  if (
    latitude < MALAYSIA_BOUNDS.minimumLatitude ||
    latitude > MALAYSIA_BOUNDS.maximumLatitude ||
    longitude < MALAYSIA_BOUNDS.minimumLongitude ||
    longitude > MALAYSIA_BOUNDS.maximumLongitude
  ) {
    throw new PlacesError(
      "INVALID_LOCATION",
      "Nearby discovery is available within Malaysia",
    );
  }
}

export function normalizedPlaceId(value: unknown): string {
  if (typeof value !== "string") {
    throw new PlacesError("INVALID_PLACE_ID", "Invalid place ID");
  }
  const id = value.trim();
  if (!/^[A-Za-z0-9_-]{8,256}$/.test(id)) {
    throw new PlacesError("INVALID_PLACE_ID", "Invalid place ID");
  }
  return id;
}

export function jsonReply(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: corsJsonHeaders,
  });
}

export function getPlacesApiKey(env?: Record<string, string>): string {
  const key = env?.GOOGLE_PLACES_API_KEY ??
    Deno.env.get("GOOGLE_PLACES_API_KEY");
  if (!key?.trim()) {
    throw new PlacesError(
      "PLACES_NOT_CONFIGURED",
      "Place discovery is not configured",
      503,
    );
  }
  return key.trim();
}

export async function callGooglePlaces(
  url: string,
  options: {
    apiKey: string;
    fieldMask: string;
    method?: "GET" | "POST";
    body?: Record<string, unknown>;
    fetcher?: typeof fetch;
  },
): Promise<GooglePlaceResponse> {
  const fetcher = options.fetcher ?? fetch;
  let response: Response;
  try {
    response = await fetcher(url, {
      method: options.method ?? "POST",
      headers: {
        "content-type": "application/json",
        "x-goog-api-key": options.apiKey,
        "x-goog-fieldmask": options.fieldMask,
      },
      body: options.body ? JSON.stringify(options.body) : undefined,
      signal: AbortSignal.timeout(12_000),
    });
  } catch (_) {
    throw new PlacesError(
      "PLACES_UNAVAILABLE",
      "Place discovery is temporarily unavailable",
      503,
    );
  }

  if (!response.ok) {
    // Provider payloads can contain request identifiers and configuration
    // details. They are intentionally never returned to the mobile client.
    throw new PlacesError(
      response.status === 429 ? "PLACES_RATE_LIMITED" : "PLACES_UNAVAILABLE",
      response.status === 429
        ? "Place discovery is busy. Please try again shortly"
        : "Place discovery is temporarily unavailable",
      response.status === 429 ? 429 : 503,
    );
  }

  try {
    return await response.json() as GooglePlaceResponse;
  } catch (_) {
    throw new PlacesError(
      "PLACES_UNAVAILABLE",
      "Place discovery is temporarily unavailable",
      503,
    );
  }
}

export function mapPlace(
  raw: unknown,
  options?: { imageUrl?: string | null },
): Record<string, unknown> | null {
  if (!raw || typeof raw !== "object") return null;
  const place = raw as Record<string, unknown>;
  const id = typeof place.id === "string" ? place.id : null;
  const displayName = place.displayName as Record<string, unknown> | undefined;
  const name = typeof displayName?.text === "string" ? displayName.text : null;
  const location = place.location as Record<string, unknown> | undefined;
  const latitude = typeof location?.latitude === "number"
    ? location.latitude
    : null;
  const longitude = typeof location?.longitude === "number"
    ? location.longitude
    : null;
  if (!id || !name || latitude === null || longitude === null) return null;

  const currentHours = place.currentOpeningHours as
    | Record<string, unknown>
    | undefined;
  const regularHours = place.regularOpeningHours as
    | Record<string, unknown>
    | undefined;
  return {
    provider: "google",
    placeId: id,
    name,
    primaryType: typeof place.primaryType === "string"
      ? place.primaryType
      : null,
    types: Array.isArray(place.types)
      ? place.types.filter((type): type is string => typeof type === "string")
        .slice(0, 8)
      : [],
    formattedAddress: typeof place.formattedAddress === "string"
      ? place.formattedAddress
      : null,
    latitude,
    longitude,
    rating: typeof place.rating === "number" ? place.rating : null,
    userRatingCount: typeof place.userRatingCount === "number"
      ? place.userRatingCount
      : null,
    priceLevel: mappedPriceLevel(place.priceLevel),
    openNow: typeof currentHours?.openNow === "boolean"
      ? currentHours.openNow
      : null,
    weekdayDescriptions: Array.isArray(regularHours?.weekdayDescriptions)
      ? regularHours.weekdayDescriptions.filter((line): line is string =>
        typeof line === "string"
      ).slice(0, 7)
      : [],
    phoneNumber: typeof place.nationalPhoneNumber === "string"
      ? place.nationalPhoneNumber
      : null,
    websiteUri: safeHttpsUrl(place.websiteUri),
    googleMapsUri: safeHttpsUrl(place.googleMapsUri),
    imageUrl: safeHttpsUrl(options?.imageUrl),
  };
}

export async function resolvePlacePhotoUri(
  raw: unknown,
  apiKey: string,
  fetcher: typeof fetch = fetch,
): Promise<string | null> {
  if (!raw || typeof raw !== "object") return null;
  const photos = (raw as Record<string, unknown>).photos;
  const first = Array.isArray(photos) && photos[0] &&
      typeof photos[0] === "object"
    ? photos[0] as Record<string, unknown>
    : null;
  const name = typeof first?.name === "string" ? first.name : "";
  if (
    !/^places\/[A-Za-z0-9_-]{8,256}\/photos\/[A-Za-z0-9_-]{8,512}$/.test(name)
  ) {
    return null;
  }
  try {
    const endpoint = new URL(
      `https://places.googleapis.com/v1/${name}/media`,
    );
    endpoint.searchParams.set("maxWidthPx", "600");
    endpoint.searchParams.set("maxHeightPx", "600");
    endpoint.searchParams.set("skipHttpRedirect", "true");
    const response = await fetcher(endpoint, {
      method: "GET",
      headers: { "x-goog-api-key": apiKey },
      signal: AbortSignal.timeout(12_000),
    });
    if (!response.ok) {
      await response.body?.cancel();
      return null;
    }
    const data = await response.json() as Record<string, unknown>;
    return safeHttpsUrl(data.photoUri);
  } catch (_) {
    return null;
  }
}

function mappedPriceLevel(value: unknown): string | null {
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

function safeHttpsUrl(value: unknown): string | null {
  if (typeof value !== "string") return null;
  try {
    const parsed = new URL(value);
    return parsed.protocol === "https:" ? parsed.toString() : null;
  } catch (_) {
    return null;
  }
}

export function sanitizedPlacesError(error: unknown): Response {
  const typed = error instanceof PlacesError ? error : new PlacesError(
    "PLACES_UNAVAILABLE",
    "Place discovery is temporarily unavailable",
    503,
  );
  return jsonReply(
    { error: { code: typed.code, message: typed.message } },
    typed.status,
  );
}
