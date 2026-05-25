export type ID = string;

export type PantryLocation = "pantry" | "fridge" | "freezer" | "spice" | "other";
export type RecipeSourceType = "manual" | "url" | "scan";
export type MealType = "breakfast" | "lunch" | "dinner" | "snack";
export type SaleSource = "manual" | "flipp" | "retailer_circular" | "import" | "mock";
export type ScanType = "recipe" | "receipt";
export type ScanStatus = "draft" | "processing" | "needs_review" | "approved" | "failed";

export interface Household {
  id: ID;
  name: string;
  created_at: string;
  updated_at: string;
}

export interface Profile {
  id: ID;
  email: string;
  full_name: string | null;
  default_household_id: ID | null;
  onboarding_completed: boolean;
  created_at: string;
  updated_at: string;
}

export interface HouseholdMember {
  id: ID;
  household_id: ID;
  user_id: ID;
  role: "owner" | "adult" | "viewer";
  created_at: string;
}

export interface PantryItem {
  id: ID;
  household_id: ID;
  name: string;
  normalized_name: string;
  category: string;
  quantity: number;
  unit: string;
  expiration_date: string | null;
  location: PantryLocation;
  notes: string | null;
  low_stock_threshold?: number | null;
  created_at: string;
  updated_at: string;
}

export interface Recipe {
  id: ID;
  household_id: ID;
  title: string;
  description: string;
  image_url: string | null;
  source_type: RecipeSourceType;
  source_url: string | null;
  servings: number;
  prep_time_minutes: number;
  cook_time_minutes: number;
  instructions: string[];
  tags: string[];
  favorite: boolean;
  created_at: string;
  updated_at: string;
}

export interface RecipeIngredient {
  id: ID;
  recipe_id: ID;
  raw_text: string;
  name: string;
  normalized_name: string;
  quantity: number;
  unit: string;
  category: string;
  optional: boolean;
}

export interface RecipeWithIngredients extends Recipe {
  ingredients: RecipeIngredient[];
}

export interface MealPlan {
  id: ID;
  household_id: ID;
  recipe_id: ID;
  planned_date: string;
  meal_type: MealType;
  servings: number;
  created_at: string;
}

export interface ShoppingListItem {
  id: ID;
  household_id: ID;
  name: string;
  normalized_name: string;
  quantity_needed: number;
  unit: string;
  category: string;
  recommended_store_id: ID | null;
  matched_sale_item_id: ID | null;
  checked: boolean;
  created_at: string;
}

export interface Store {
  id: ID;
  household_id: ID;
  name: string;
  chain: string;
  preferred: boolean;
  zip_code: string | null;
  created_at: string;
}

export interface SaleItem {
  id: ID;
  store_id: ID;
  household_id: ID;
  item_name: string;
  normalized_name: string;
  category: string;
  sale_price: number | null;
  sale_description: string;
  start_date: string | null;
  end_date: string | null;
  source: SaleSource;
  confidence: number;
  created_at: string;
}

export interface ScanJob {
  id: ID;
  household_id: ID;
  type: ScanType;
  status: ScanStatus;
  source_uri: string | null;
  raw_text: string | null;
  result_json: unknown;
  created_at: string;
  updated_at: string;
}

export interface IngredientNeed {
  normalized_name: string;
  name: string;
  quantity: number;
  unit: string;
  category: string;
  recipe_ids: ID[];
}

export interface SaleMatch {
  sale_item: SaleItem;
  store: Store;
  matched_name: string;
  savings_score: number;
}

export interface RecipeRecommendation {
  recipe_id: ID;
  score: number;
  match_percent: number;
  pantry_items_used: PantryItem[];
  missing_items: RecipeIngredient[];
  sale_matches: SaleMatch[];
  reason_summary: string[];
  badges: Array<"minimal_shopping" | "uses_expiring" | "sale_opportunity">;
}

export interface StoreRecommendation {
  store: Store;
  covered_items: ShoppingListItem[];
  sale_matches: SaleMatch[];
  score: number;
  summary: string;
}

export interface ParsedReceiptItem {
  id: ID;
  raw_text: string;
  normalized_name: string;
  name: string;
  quantity: number;
  unit: string;
  category: string;
  confidence: number;
  approved: boolean;
}

export interface ParsedRecipeDraft {
  title: string;
  servings: number;
  prep_time_minutes: number;
  cook_time_minutes: number;
  description: string;
  ingredients: Omit<RecipeIngredient, "id" | "recipe_id">[];
  instructions: string[];
  tags: string[];
}
