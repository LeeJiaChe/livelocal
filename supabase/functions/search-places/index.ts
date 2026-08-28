import {
  callGooglePlaces,
  getPlacesApiKey,
  jsonReply,
  mapPlace,
  PlacesError,
  placeTypeForCategory,
  sanitizedPlacesError,
  SEARCH_FIELD_MASK,
} from "../_shared/google_places.ts";

export async function handleSearchPlaces(
  request: Request,
  deps?: { fetcher?: typeof fetch; env?: Record<string, string> },
): Promise<Response> {
  if (request.method === "OPTIONS") return jsonReply({});
  if (request.method !== "POST") {
    return jsonReply({ error: { code: "METHOD_NOT_ALLOWED" } }, 405);
  }
  try {
    const payload = await request.json().catch(() => ({}));
    const query = typeof payload.query === "string" ? payload.query.trim() : "";
    if (query.length < 2 || query.length > 160) {
      throw new PlacesError(
        "INVALID_QUERY",
        "Enter a search of 2 to 160 characters",
      );
    }
    const category = placeTypeForCategory(payload.category);
    const pageToken = typeof payload.pageToken === "string"
      ? payload.pageToken.trim()
      : "";
    if (pageToken.length > 2048) {
      throw new PlacesError("INVALID_PAGE_TOKEN", "Invalid page token");
    }
    const body: Record<string, unknown> = {
      textQuery: query,
      pageSize: 20,
      languageCode: "en",
      regionCode: "MY",
      locationRestriction: {
        rectangle: {
          low: { latitude: 0.8, longitude: 99.5 },
          high: { latitude: 7.5, longitude: 119.5 },
        },
      },
    };
    if (category) {
      body.includedType = category;
      body.strictTypeFiltering = false;
    }
    if (pageToken) body.pageToken = pageToken;

    const data = await callGooglePlaces(
      "https://places.googleapis.com/v1/places:searchText",
      {
        apiKey: getPlacesApiKey(deps?.env),
        fieldMask: SEARCH_FIELD_MASK,
        body,
        fetcher: deps?.fetcher,
      },
    );
    const places = Array.isArray(data.places)
      ? data.places.map(mapPlace).filter((place) => place !== null)
      : [];
    return jsonReply({
      places,
      nextPageToken: typeof data.nextPageToken === "string"
        ? data.nextPageToken
        : null,
    });
  } catch (error) {
    return sanitizedPlacesError(error);
  }
}

if (import.meta.main) Deno.serve((request) => handleSearchPlaces(request));
