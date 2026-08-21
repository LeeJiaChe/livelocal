type Table<Row, Insert = Row, Update = Partial<Insert>> = {
  Row: Row;
  Insert: Insert;
  Update: Update;
  Relationships: [];
};

type SocialConnectionRow = {
  id: string;
  user_id: string;
  platform: string;
  external_account_id: string;
  profile_url: string;
  access_token_ciphertext: string;
  access_token_iv: string;
  refresh_token_ciphertext: string | null;
  refresh_token_iv: string | null;
  scopes: string[];
  token_expires_at: string | null;
  refresh_expires_at: string | null;
  created_at: string;
  updated_at: string;
};

type SocialConnectionInsert =
  & Omit<
    SocialConnectionRow,
    "id" | "created_at" | "updated_at"
  >
  & {
    id?: string;
    created_at?: string;
    updated_at?: string;
  };

type OAuthStateRow = {
  state_hash: string;
  user_id: string;
  platform: string;
  app_redirect_uri: string;
  expires_at: string;
  used_at: string | null;
  created_at: string;
};

type OAuthStateInsert = Omit<OAuthStateRow, "used_at" | "created_at"> & {
  used_at?: string | null;
  created_at?: string;
};

export type EdgeDatabase = {
  public: {
    Tables: {
      user_roles: Table<{
        user_id: string;
        role: string;
        revoked_at: string | null;
      }>;
      account_access: Table<{
        user_id: string;
        status: string;
        ends_at: string | null;
      }>;
      social_account_connections: Table<
        SocialConnectionRow,
        SocialConnectionInsert
      >;
      social_oauth_states: Table<OAuthStateRow, OAuthStateInsert>;
    };
    Views: Record<string, never>;
    Functions: Record<string, never>;
    Enums: Record<string, never>;
    CompositeTypes: Record<string, never>;
  };
};
