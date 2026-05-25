import type { IngredientNeed, MealPlan, PantryItem, RecipeWithIngredients, SaleItem, ShoppingListItem, Store } from "@/lib/types/models";
import { CATEGORY_ORDER } from "@/lib/constants/categories";
import { findSaleMatches } from "@/services/saleMatchingService";

const id = (prefix: string) => `${prefix}-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;

export function generateShoppingListFromMealPlan(
  householdId: string,
  mealPlans: MealPlan[],
  recipes: RecipeWithIngredients[],
  pantryItems: PantryItem[],
  saleItems: SaleItem[],
  stores: Store[]
): ShoppingListItem[] {
  const pantryByName = new Map(pantryItems.map((item) => [item.normalized_name, item]));
  const needs = new Map<string, IngredientNeed>();

  mealPlans.forEach((plan) => {
    const recipe = recipes.find((item) => item.id === plan.recipe_id);
    if (!recipe) return;
    recipe.ingredients.filter((ingredient) => !ingredient.optional).forEach((ingredient) => {
      const existing = needs.get(ingredient.normalized_name);
      if (existing && existing.unit === ingredient.unit) {
        existing.quantity += ingredient.quantity;
        existing.recipe_ids.push(recipe.id);
      } else if (!existing) {
        needs.set(ingredient.normalized_name, {
          normalized_name: ingredient.normalized_name,
          name: ingredient.name,
          quantity: ingredient.quantity,
          unit: ingredient.unit,
          category: ingredient.category,
          recipe_ids: [recipe.id]
        });
      }
    });
  });

  return [...needs.values()].flatMap((need) => {
    const pantry = pantryByName.get(need.normalized_name);
    const remainingQuantity = Math.max(0, need.quantity - (pantry?.quantity ?? 0));
    if (remainingQuantity <= 0) return [];
    const bestSale = findSaleMatches(need.normalized_name, saleItems, stores)[0];
    return [{
      id: id("shop"),
      household_id: householdId,
      name: need.name,
      normalized_name: need.normalized_name,
      quantity_needed: Number(remainingQuantity.toFixed(2)),
      unit: need.unit,
      category: need.category,
      recommended_store_id: bestSale?.store.id ?? null,
      matched_sale_item_id: bestSale?.sale_item.id ?? null,
      checked: false,
      created_at: new Date().toISOString()
    } satisfies ShoppingListItem];
  }).sort((a, b) => (CATEGORY_ORDER[a.category] ?? 99) - (CATEGORY_ORDER[b.category] ?? 99));
}

export function groupShoppingListByCategory(items: ShoppingListItem[]): Array<{ category: string; items: ShoppingListItem[] }> {
  const grouped = new Map<string, ShoppingListItem[]>();
  items.forEach((item) => grouped.set(item.category, [...(grouped.get(item.category) ?? []), item]));
  return [...grouped.entries()]
    .map(([category, categoryItems]) => ({ category, items: categoryItems }))
    .sort((a, b) => (CATEGORY_ORDER[a.category] ?? 99) - (CATEGORY_ORDER[b.category] ?? 99));
}
