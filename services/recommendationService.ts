import type { PantryItem, RecipeRecommendation, RecipeWithIngredients, SaleItem, Store } from "@/lib/types/models";
import { isExpiringSoon } from "@/lib/utils/date";
import { findSaleMatches } from "@/services/saleMatchingService";

function inventoryMap(pantryItems: PantryItem[]) {
  return new Map(pantryItems.filter((item) => item.quantity > 0).map((item) => [item.normalized_name, item]));
}

export function scoreRecipeRecommendations(
  pantryItems: PantryItem[],
  recipes: RecipeWithIngredients[],
  saleItems: SaleItem[],
  stores: Store[]
): RecipeRecommendation[] {
  const pantryByName = inventoryMap(pantryItems);
  const expiringNames = new Set(pantryItems.filter((item) => isExpiringSoon(item.expiration_date)).map((item) => item.normalized_name));
  const ingredientFrequency = new Map<string, number>();
  recipes.forEach((recipe) => recipe.ingredients.forEach((ingredient) => {
    ingredientFrequency.set(ingredient.normalized_name, (ingredientFrequency.get(ingredient.normalized_name) ?? 0) + 1);
  }));

  return recipes.map((recipe) => {
    const required = recipe.ingredients.filter((ingredient) => !ingredient.optional);
    const pantry_items_used = required
      .map((ingredient) => pantryByName.get(ingredient.normalized_name))
      .filter((item): item is PantryItem => Boolean(item));
    const missing_items = required.filter((ingredient) => !pantryByName.has(ingredient.normalized_name));
    const sale_matches = missing_items.flatMap((ingredient) => findSaleMatches(ingredient.normalized_name, saleItems, stores).slice(0, 1));
    const expiringUsed = pantry_items_used.filter((item) => expiringNames.has(item.normalized_name));
    const sharedIngredientBonus = required.reduce((total, ingredient) => total + Math.max(0, (ingredientFrequency.get(ingredient.normalized_name) ?? 1) - 1), 0);

    const inventory_match_score = required.length === 0 ? 0 : (pantry_items_used.length / required.length) * 55;
    const expiring_item_bonus = expiringUsed.length * 12;
    const sale_match_bonus = sale_matches.length * 7;
    const shared_ingredient_bonus = sharedIngredientBonus * 2;
    const missing_item_penalty = missing_items.length * 9;
    const estimated_cost_penalty = missing_items.reduce((total, item) => total + (item.category === "meat" || item.category === "seafood" ? 6 : 2), 0);
    const uniqueStores = new Set(sale_matches.map((match) => match.store.id)).size;
    const store_trip_penalty = uniqueStores > 1 ? (uniqueStores - 1) * 4 : 0;
    const score = Math.round(
      inventory_match_score +
      expiring_item_bonus +
      sale_match_bonus +
      shared_ingredient_bonus -
      missing_item_penalty -
      estimated_cost_penalty -
      store_trip_penalty
    );
    const match_percent = required.length === 0 ? 100 : Math.round((pantry_items_used.length / required.length) * 100);
    const reason_summary = [
      pantry_items_used.length > 0 ? `Uses ${pantry_items_used.length} ingredient${pantry_items_used.length === 1 ? "" : "s"} already at home` : "Starts from a clean shopping list",
      missing_items.length === 0 ? "No missing required ingredients" : `Only ${missing_items.length} missing item${missing_items.length === 1 ? "" : "s"}`,
      expiringUsed.length > 0 ? `Uses ${expiringUsed.map((item) => item.normalized_name).join(", ")} before expiration` : null,
      sale_matches.length > 0 ? `${sale_matches[0]?.sale_item.normalized_name} is on sale at ${sale_matches[0]?.store.name}` : null
    ].filter((reason): reason is string => Boolean(reason));

    return {
      recipe_id: recipe.id,
      score,
      match_percent,
      pantry_items_used,
      missing_items,
      sale_matches,
      reason_summary,
      badges: [
        missing_items.length <= 2 ? "minimal_shopping" : null,
        expiringUsed.length > 0 ? "uses_expiring" : null,
        sale_matches.length > 0 ? "sale_opportunity" : null
      ].filter((badge): badge is RecipeRecommendation["badges"][number] => Boolean(badge))
    };
  }).sort((a, b) => b.score - a.score);
}

export function getRecommendationCopy(recommendation: RecipeRecommendation): string {
  return recommendation.reason_summary[0] ?? "A practical option for this week.";
}
