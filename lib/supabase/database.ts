export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[];

type RowBase = Record<string, unknown>;
type Table<Row extends RowBase, Insert extends RowBase = Partial<Row>, Update extends RowBase = Partial<Row>> = {
  Row: Row;
  Insert: Insert;
  Update: Update;
  Relationships: [];
};

export type Database = {
  public: {
    Tables: {
      profiles: Table<{
        id: string;
        email: string;
        full_name: string | null;
        default_household_id: string | null;
        onboarding_completed: boolean;
        created_at: string;
        updated_at: string;
      }>;
      households: Table<{
        id: string;
        name: string;
        created_at: string;
        updated_at: string;
      }>;
      household_members: Table<{
        id: string;
        household_id: string;
        user_id: string;
        role: "owner" | "adult" | "viewer";
        created_at: string;
      }>;
      pantry_items: Table<{
        id: string;
        household_id: string;
        name: string;
        normalized_name: string;
        category: string;
        quantity: number;
        unit: string;
        expiration_date: string | null;
        location: "pantry" | "fridge" | "freezer" | "spice" | "other";
        notes: string | null;
        created_at: string;
        updated_at: string;
      }>;
      recipes: Table<{
        id: string;
        household_id: string;
        title: string;
        description: string;
        image_url: string | null;
        source_type: "manual" | "url" | "scan";
        source_url: string | null;
        servings: number;
        prep_time_minutes: number;
        cook_time_minutes: number;
        instructions: string[];
        tags: string[];
        favorite: boolean;
        created_at: string;
        updated_at: string;
      }>;
      recipe_ingredients: Table<{
        id: string;
        recipe_id: string;
        raw_text: string;
        name: string;
        normalized_name: string;
        quantity: number;
        unit: string;
        category: string;
        optional: boolean;
      }>;
      meal_plans: Table<{
        id: string;
        household_id: string;
        recipe_id: string;
        planned_date: string;
        meal_type: "breakfast" | "lunch" | "dinner" | "snack";
        servings: number;
        created_at: string;
      }>;
      shopping_list_items: Table<{
        id: string;
        household_id: string;
        name: string;
        normalized_name: string;
        quantity_needed: number;
        unit: string;
        category: string;
        recommended_store_id: string | null;
        matched_sale_item_id: string | null;
        checked: boolean;
        created_at: string;
      }>;
      stores: Table<{
        id: string;
        household_id: string;
        name: string;
        chain: string;
        preferred: boolean;
        zip_code: string | null;
        created_at: string;
      }>;
      sale_items: Table<{
        id: string;
        store_id: string;
        household_id: string;
        item_name: string;
        normalized_name: string;
        category: string;
        sale_price: number | null;
        sale_description: string;
        start_date: string | null;
        end_date: string | null;
        source: "manual" | "flipp" | "retailer_circular" | "import" | "mock";
        confidence: number;
        created_at: string;
      }>;
      scan_jobs: Table<{
        id: string;
        household_id: string;
        type: "recipe" | "receipt";
        status: "draft" | "processing" | "needs_review" | "approved" | "failed";
        source_uri: string | null;
        raw_text: string | null;
        result_json: Json | null;
        created_at: string;
        updated_at: string;
      }>;
    };
    Views: Record<string, never>;
    Functions: Record<string, never>;
    Enums: Record<string, never>;
    CompositeTypes: Record<string, never>;
  };
};
