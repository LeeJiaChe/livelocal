export type SocialPlatform = "tiktok" | "instagram";
export type SocialSourceType = "post" | "profile";

export type DetectedSource = {
  platform: SocialPlatform;
  sourceType: SocialSourceType;
  normalizedUrl: string;
};

export type SocialPost = {
  sourcePlatform: SocialPlatform;
  sourcePostUrl: string;
  influencerUsername: string | null;
  sourceCaption: string | null;
  createdAt?: string | null;
};

export type SocialSourceContent = {
  detection: DetectedSource;
  posts: SocialPost[];
};

export type SocialConnection = {
  platform: SocialPlatform;
  profileUrl: string;
  accessToken: string;
};

export type GeneratedRestaurantListing = {
  restaurantName: string | null;
  address: string | null;
  state: string | null;
  city: string | null;
  cuisineType: string | null;
  priceRange: string | null;
  reviewedDishes: string[];
  sourcePlatform: SocialPlatform;
  sourcePostUrl: string;
  influencerUsername: string | null;
  sourceCaption: string | null;
  confidence: number;
  missingFields: string[];
};

export class GenerationError extends Error {
  constructor(
    public readonly code: string,
    message: string,
    public readonly status = 400,
  ) {
    super(message);
  }
}
