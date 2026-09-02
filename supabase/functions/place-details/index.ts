import {
  callGooglePlaces,
  DETAILS_FIELD_MASK,
  getPlacesApiKey,
  jsonReply,
  mapPlace,
  normalizedPlaceId,
  PlacesError,
  resolvePlacePhotoUri,
  sanitizedPlacesError,
} from "../_shared/google_places.ts";

export async function handlePlaceDetails(
  request: Request,
  deps?: { fetcher?: typeof fetch; env?: Record<string, string> },
): Promise<Response> {
  if (request.method === "OPTIONS") return jsonReply({});
  if (request.method !== "POST") {
    return jsonReply({ error: { code: "METHOD_NOT_ALLOWED" } }, 405);
  }
  try {
    const payload = await request.json().catch(() => ({}));
    const apiKey = getPlacesApiKey(deps?.env);
    if (Array.isArray(payload.placeIds)) {
      if (payload.placeIds.length === 0 || payload.placeIds.length > 20) {
        throw new PlacesError(
          "INVALID_PLACE_ID",
          "Provide between 1 and 20 place IDs",
        );
      }
      const placeIds: string[] = [
        ...new Set<string>(
          payload.placeIds.map((value: unknown) => normalizedPlaceId(value)),
        ),
      ];
      const places = await Promise.all(
        placeIds.map((placeId) => fetchPlace(placeId, apiKey, deps?.fetcher)),
      );
      return jsonReply({ places });
    }
    const placeId = normalizedPlaceId(payload.placeId);
    const place = await fetchPlace(placeId, apiKey, deps?.fetcher);
    return jsonReply({ place });
  } catch (error) {
    return sanitizedPlacesError(error);
  }
}

async function fetchPlace(
  placeId: string,
  apiKey: string,
  fetcher?: typeof fetch,
): Promise<Record<string, unknown>> {
  const data = await callGooglePlaces(
    `https://places.googleapis.com/v1/places/${
      encodeURIComponent(placeId)
    }?languageCode=en&regionCode=MY`,
    {
      apiKey,
      fieldMask: DETAILS_FIELD_MASK,
      method: "GET",
      fetcher,
    },
  );
  const imageUrl = await resolvePlacePhotoUri(data, apiKey, fetcher);
  const place = mapPlace(data, { imageUrl });
  if (!place) {
    throw new PlacesError("PLACE_NOT_FOUND", "Place not found", 404);
  }
  return place;
}

if (import.meta.main) Deno.serve((request) => handlePlaceDetails(request));
