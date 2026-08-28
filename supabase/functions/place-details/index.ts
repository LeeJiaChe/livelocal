import {
  callGooglePlaces,
  DETAILS_FIELD_MASK,
  getPlacesApiKey,
  jsonReply,
  mapPlace,
  normalizedPlaceId,
  PlacesError,
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
    const placeId = normalizedPlaceId(payload.placeId);
    const data = await callGooglePlaces(
      `https://places.googleapis.com/v1/places/${
        encodeURIComponent(placeId)
      }?languageCode=en&regionCode=MY`,
      {
        apiKey: getPlacesApiKey(deps?.env),
        fieldMask: DETAILS_FIELD_MASK,
        method: "GET",
        fetcher: deps?.fetcher,
      },
    );
    const place = mapPlace(data);
    if (!place) {
      throw new PlacesError("PLACE_NOT_FOUND", "Place not found", 404);
    }
    return jsonReply({ place });
  } catch (error) {
    return sanitizedPlacesError(error);
  }
}

if (import.meta.main) Deno.serve((request) => handlePlaceDetails(request));
