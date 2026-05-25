import AsyncStorage from "@react-native-async-storage/async-storage";
import { create } from "zustand";
import { createJSONStorage, persist } from "zustand/middleware";
import { demoHousehold, mockMealPlans, mockPantryItems, mockRecipes, mockSaleItems, mockShoppingListItems, mockStores } from "@/lib/constants/mockData";
import type { MealPlan, PantryItem, RecipeWithIngredients, SaleItem, ShoppingListItem, Store } from "@/lib/types/models";
import { normalizeIngredientName, inferCategory } from "@/services/normalizationService";

const now = () => new Date().toISOString();
const id = (prefix: string) => `${prefix}-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;

interface KitchenState {
  householdId: string;
  pantryItems: PantryItem[];
  recipes: RecipeWithIngredients[];
  mealPlans: MealPlan[];
  shoppingListItems: ShoppingListItem[];
  stores: Store[];
  saleItems: SaleItem[];
  addPantryItem: (item: Omit<PantryItem, "id" | "household_id" | "normalized_name" | "created_at" | "updated_at">) => PantryItem;
  updatePantryItem: (id: string, patch: Partial<PantryItem>) => void;
  consumePantryItem: (id: string) => void;
  deletePantryItem: (id: string) => void;
  addRecipe: (recipe: Omit<RecipeWithIngredients, "id" | "household_id" | "created_at" | "updated_at">) => RecipeWithIngredients;
  deleteRecipe: (id: string) => void;
  addMealPlan: (plan: Omit<MealPlan, "id" | "household_id" | "created_at">) => void;
  removeMealPlan: (id: string) => void;
  setShoppingList: (items: ShoppingListItem[]) => void;
  toggleShoppingItem: (id: string) => void;
  addShoppingItem: (item: Omit<ShoppingListItem, "id" | "household_id" | "normalized_name" | "created_at" | "checked" | "recommended_store_id" | "matched_sale_item_id">) => void;
  deleteShoppingItem: (id: string) => void;
}

export const useKitchenStore = create<KitchenState>()(
  persist(
    (set, get) => ({
      householdId: demoHousehold.id,
      pantryItems: mockPantryItems,
      recipes: mockRecipes,
      mealPlans: mockMealPlans,
      shoppingListItems: mockShoppingListItems,
      stores: mockStores,
      saleItems: mockSaleItems,
      addPantryItem: (item) => {
        const created: PantryItem = {
          ...item,
          id: id("pantry"),
          household_id: get().householdId,
          normalized_name: normalizeIngredientName(item.name),
          category: item.category || inferCategory(item.name),
          created_at: now(),
          updated_at: now()
        };
        set((state) => ({ pantryItems: [created, ...state.pantryItems] }));
        return created;
      },
      updatePantryItem: (itemId, patch) => set((state) => ({
        pantryItems: state.pantryItems.map((item) => item.id === itemId ? { ...item, ...patch, updated_at: now() } : item)
      })),
      consumePantryItem: (itemId) => set((state) => ({
        pantryItems: state.pantryItems.map((item) => item.id === itemId ? { ...item, quantity: Math.max(0, item.quantity - 1), updated_at: now() } : item)
      })),
      deletePantryItem: (itemId) => set((state) => ({ pantryItems: state.pantryItems.filter((item) => item.id !== itemId) })),
      addRecipe: (recipe) => {
        const recipeId = id("recipe");
        const created: RecipeWithIngredients = {
          ...recipe,
          id: recipeId,
          household_id: get().householdId,
          created_at: now(),
          updated_at: now(),
          ingredients: recipe.ingredients.map((ingredient, index) => ({ ...ingredient, id: id(`ingredient-${index}`), recipe_id: recipeId }))
        };
        set((state) => ({ recipes: [created, ...state.recipes] }));
        return created;
      },
      deleteRecipe: (recipeId) => set((state) => ({ recipes: state.recipes.filter((recipe) => recipe.id !== recipeId) })),
      addMealPlan: (plan) => set((state) => ({
        mealPlans: [{ ...plan, id: id("plan"), household_id: state.householdId, created_at: now() }, ...state.mealPlans]
      })),
      removeMealPlan: (planId) => set((state) => ({ mealPlans: state.mealPlans.filter((plan) => plan.id !== planId) })),
      setShoppingList: (items) => set({ shoppingListItems: items }),
      toggleShoppingItem: (itemId) => set((state) => ({
        shoppingListItems: state.shoppingListItems.map((item) => item.id === itemId ? { ...item, checked: !item.checked } : item)
      })),
      addShoppingItem: (item) => set((state) => ({
        shoppingListItems: [{
          ...item,
          id: id("shop"),
          household_id: state.householdId,
          normalized_name: normalizeIngredientName(item.name),
          checked: false,
          recommended_store_id: null,
          matched_sale_item_id: null,
          created_at: now()
        }, ...state.shoppingListItems]
      })),
      deleteShoppingItem: (itemId) => set((state) => ({ shoppingListItems: state.shoppingListItems.filter((item) => item.id !== itemId) }))
    }),
    {
      name: "kitchen-compass-store",
      storage: createJSONStorage(() => AsyncStorage),
      partialize: (state) => ({
        pantryItems: state.pantryItems,
        recipes: state.recipes,
        mealPlans: state.mealPlans,
        shoppingListItems: state.shoppingListItems,
        stores: state.stores,
        saleItems: state.saleItems
      })
    }
  )
);
