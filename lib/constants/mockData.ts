import type {
  Household,
  MealPlan,
  PantryItem,
  RecipeIngredient,
  RecipeWithIngredients,
  SaleItem,
  ShoppingListItem,
  Store
} from "@/lib/types/models";
import { daysFromNow, toISODate } from "@/lib/utils/date";

const householdId = "household-demo";
const now = new Date().toISOString();

export const demoHousehold: Household = {
  id: householdId,
  name: "Kitchen Compass Home",
  created_at: now,
  updated_at: now
};

export const mockPantryItems: PantryItem[] = [
  {
    id: "pantry-spinach",
    household_id: householdId,
    name: "Baby spinach bag",
    normalized_name: "spinach",
    category: "produce",
    quantity: 1,
    unit: "bag",
    expiration_date: daysFromNow(2),
    location: "fridge",
    notes: "Opened",
    low_stock_threshold: 1,
    created_at: now,
    updated_at: now
  },
  {
    id: "pantry-eggs",
    household_id: householdId,
    name: "Eggs",
    normalized_name: "eggs",
    category: "eggs",
    quantity: 8,
    unit: "ct",
    expiration_date: daysFromNow(10),
    location: "fridge",
    notes: null,
    low_stock_threshold: 6,
    created_at: now,
    updated_at: now
  },
  {
    id: "pantry-chicken",
    household_id: householdId,
    name: "Chicken breasts",
    normalized_name: "chicken breast",
    category: "meat",
    quantity: 1.5,
    unit: "lb",
    expiration_date: daysFromNow(4),
    location: "freezer",
    notes: null,
    low_stock_threshold: 1,
    created_at: now,
    updated_at: now
  },
  {
    id: "pantry-penne",
    household_id: householdId,
    name: "Barilla penne",
    normalized_name: "penne pasta",
    category: "pasta",
    quantity: 1,
    unit: "box",
    expiration_date: null,
    location: "pantry",
    notes: null,
    low_stock_threshold: 1,
    created_at: now,
    updated_at: now
  },
  {
    id: "pantry-rice",
    household_id: householdId,
    name: "Jasmine rice",
    normalized_name: "rice",
    category: "grains",
    quantity: 2,
    unit: "lb",
    expiration_date: null,
    location: "pantry",
    notes: null,
    low_stock_threshold: 1,
    created_at: now,
    updated_at: now
  },
  {
    id: "pantry-beans",
    household_id: householdId,
    name: "Black beans",
    normalized_name: "black beans",
    category: "canned",
    quantity: 2,
    unit: "can",
    expiration_date: null,
    location: "pantry",
    notes: null,
    low_stock_threshold: 1,
    created_at: now,
    updated_at: now
  }
];

const ingredient = (id: string, recipe_id: string, raw_text: string, name: string, quantity: number, unit: string, category: string, optional = false): RecipeIngredient => ({
  id,
  recipe_id,
  raw_text,
  name,
  normalized_name: name,
  quantity,
  unit,
  category,
  optional
});

export const mockRecipes: RecipeWithIngredients[] = [
  {
    id: "recipe-chicken-spinach-pasta",
    household_id: householdId,
    title: "Creamy Chicken Spinach Penne",
    description: "A cozy one-pan dinner that uses spinach before it wilts.",
    image_url: null,
    source_type: "manual",
    source_url: null,
    servings: 4,
    prep_time_minutes: 10,
    cook_time_minutes: 25,
    instructions: [
      "Boil pasta until al dente.",
      "Cook sliced chicken with garlic and olive oil.",
      "Fold in spinach, milk, and cheese until creamy.",
      "Toss pasta with sauce and season to taste."
    ],
    tags: ["dinner", "family", "minimal shopping"],
    favorite: true,
    created_at: now,
    updated_at: now,
    ingredients: [
      ingredient("ri-1", "recipe-chicken-spinach-pasta", "1 box penne pasta", "penne pasta", 1, "box", "pasta"),
      ingredient("ri-2", "recipe-chicken-spinach-pasta", "1 lb chicken breast", "chicken breast", 1, "lb", "meat"),
      ingredient("ri-3", "recipe-chicken-spinach-pasta", "1 bag spinach", "spinach", 1, "bag", "produce"),
      ingredient("ri-4", "recipe-chicken-spinach-pasta", "1 cup milk", "milk", 1, "cup", "dairy"),
      ingredient("ri-5", "recipe-chicken-spinach-pasta", "1/2 cup parmesan", "parmesan", 0.5, "cup", "dairy", true)
    ]
  },
  {
    id: "recipe-breakfast-eggs",
    household_id: householdId,
    title: "Spinach Egg Scramble",
    description: "Fast breakfast-for-dinner that clears out greens.",
    image_url: null,
    source_type: "manual",
    source_url: null,
    servings: 3,
    prep_time_minutes: 5,
    cook_time_minutes: 8,
    instructions: ["Whisk eggs with salt and pepper.", "Saute spinach until just wilted.", "Scramble eggs gently and serve with toast."],
    tags: ["breakfast", "quick", "uses expiring"],
    favorite: false,
    created_at: now,
    updated_at: now,
    ingredients: [
      ingredient("ri-6", "recipe-breakfast-eggs", "6 eggs", "eggs", 6, "ct", "eggs"),
      ingredient("ri-7", "recipe-breakfast-eggs", "2 cups spinach", "spinach", 2, "cup", "produce"),
      ingredient("ri-8", "recipe-breakfast-eggs", "4 slices bread", "bread", 4, "ct", "bakery", true)
    ]
  },
  {
    id: "recipe-rice-bean-bowls",
    household_id: householdId,
    title: "Black Bean Rice Bowls",
    description: "A flexible pantry meal with bright toppings.",
    image_url: null,
    source_type: "manual",
    source_url: null,
    servings: 4,
    prep_time_minutes: 10,
    cook_time_minutes: 20,
    instructions: ["Cook rice.", "Warm beans with cumin and garlic.", "Top bowls with salsa, spinach, and cheese if available."],
    tags: ["vegetarian", "pantry", "budget"],
    favorite: true,
    created_at: now,
    updated_at: now,
    ingredients: [
      ingredient("ri-9", "recipe-rice-bean-bowls", "1 cup rice", "rice", 1, "cup", "grains"),
      ingredient("ri-10", "recipe-rice-bean-bowls", "2 cans black beans", "black beans", 2, "can", "canned"),
      ingredient("ri-11", "recipe-rice-bean-bowls", "1 cup salsa", "salsa", 1, "cup", "condiments"),
      ingredient("ri-12", "recipe-rice-bean-bowls", "1 avocado", "avocado", 1, "ct", "produce", true)
    ]
  },
  {
    id: "recipe-taco-night",
    household_id: householdId,
    title: "Easy Chicken Taco Night",
    description: "A low-stress family dinner with sale-friendly ingredients.",
    image_url: null,
    source_type: "manual",
    source_url: null,
    servings: 4,
    prep_time_minutes: 10,
    cook_time_minutes: 15,
    instructions: ["Season and saute chicken.", "Warm taco shells.", "Set out toppings family-style."],
    tags: ["dinner", "kids", "sale opportunity"],
    favorite: false,
    created_at: now,
    updated_at: now,
    ingredients: [
      ingredient("ri-13", "recipe-taco-night", "1 lb chicken breast", "chicken breast", 1, "lb", "meat"),
      ingredient("ri-14", "recipe-taco-night", "1 box taco shells", "taco shells", 1, "box", "grains"),
      ingredient("ri-15", "recipe-taco-night", "1 cup shredded cheese", "cheese", 1, "cup", "dairy"),
      ingredient("ri-16", "recipe-taco-night", "1 cup lettuce", "lettuce", 1, "cup", "produce")
    ]
  }
];

export const mockStores: Store[] = [
  { id: "store-costco", household_id: householdId, name: "Costco", chain: "Costco", preferred: true, zip_code: "07030", created_at: now },
  { id: "store-bjs", household_id: householdId, name: "BJ's", chain: "BJ's", preferred: false, zip_code: "07030", created_at: now },
  { id: "store-stop-shop", household_id: householdId, name: "Stop & Shop", chain: "Stop & Shop", preferred: true, zip_code: "07030", created_at: now },
  { id: "store-shoprite", household_id: householdId, name: "ShopRite", chain: "ShopRite", preferred: true, zip_code: "07030", created_at: now },
  { id: "store-whole-foods", household_id: householdId, name: "Whole Foods", chain: "Whole Foods", preferred: false, zip_code: "07030", created_at: now },
  { id: "store-trader-joes", household_id: householdId, name: "Trader Joe's", chain: "Trader Joe's", preferred: true, zip_code: "07030", created_at: now }
];

export const mockSaleItems: SaleItem[] = [
  { id: "sale-chicken-shoprite", store_id: "store-shoprite", household_id: householdId, item_name: "Boneless chicken breast", normalized_name: "chicken breast", category: "meat", sale_price: 2.99, sale_description: "$2.99/lb family pack", start_date: toISODate(new Date()), end_date: daysFromNow(7), source: "mock", confidence: 0.94, created_at: now },
  { id: "sale-eggs-stopshop", store_id: "store-stop-shop", household_id: householdId, item_name: "Large eggs", normalized_name: "eggs", category: "eggs", sale_price: 2.49, sale_description: "$2.49 dozen with card", start_date: toISODate(new Date()), end_date: daysFromNow(5), source: "mock", confidence: 0.91, created_at: now },
  { id: "sale-pasta-shoprite", store_id: "store-shoprite", household_id: householdId, item_name: "Barilla pasta", normalized_name: "penne pasta", category: "pasta", sale_price: 1.25, sale_description: "4 for $5 assorted pasta", start_date: toISODate(new Date()), end_date: daysFromNow(7), source: "mock", confidence: 0.88, created_at: now },
  { id: "sale-milk-costco", store_id: "store-costco", household_id: householdId, item_name: "Milk 2 pack", normalized_name: "milk", category: "dairy", sale_price: 5.99, sale_description: "Warehouse value on two gallons", start_date: toISODate(new Date()), end_date: daysFromNow(10), source: "mock", confidence: 0.74, created_at: now },
  { id: "sale-cheese-trader", store_id: "store-trader-joes", household_id: householdId, item_name: "Shredded cheese", normalized_name: "cheese", category: "dairy", sale_price: 3.49, sale_description: "Everyday low price", start_date: null, end_date: null, source: "mock", confidence: 0.7, created_at: now },
  { id: "sale-avocado-whole", store_id: "store-whole-foods", household_id: householdId, item_name: "Avocados", normalized_name: "avocado", category: "produce", sale_price: 1.5, sale_description: "Prime member produce special", start_date: toISODate(new Date()), end_date: daysFromNow(3), source: "mock", confidence: 0.67, created_at: now }
];

export const mockMealPlans: MealPlan[] = [
  { id: "plan-1", household_id: householdId, recipe_id: "recipe-chicken-spinach-pasta", planned_date: daysFromNow(1), meal_type: "dinner", servings: 4, created_at: now },
  { id: "plan-2", household_id: householdId, recipe_id: "recipe-rice-bean-bowls", planned_date: daysFromNow(3), meal_type: "dinner", servings: 4, created_at: now }
];

export const mockShoppingListItems: ShoppingListItem[] = [];
