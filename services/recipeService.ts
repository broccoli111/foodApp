import type { PantryItem, RecipeIngredient, RecipeWithIngredients } from "@/lib/types/models";

export function getRecipeMatch(recipe: RecipeWithIngredients, pantryItems: PantryItem[]) {
  const pantryNames = new Set(pantryItems.filter((item) => item.quantity > 0).map((item) => item.normalized_name));
  const required = recipe.ingredients.filter((ingredient) => !ingredient.optional);
  const available = required.filter((ingredient) => pantryNames.has(ingredient.normalized_name));
  const missing = required.filter((ingredient) => !pantryNames.has(ingredient.normalized_name));
  return {
    matchPercent: required.length === 0 ? 100 : Math.round((available.length / required.length) * 100),
    available: available as RecipeIngredient[],
    missing: missing as RecipeIngredient[]
  };
}

export function searchRecipes(recipes: RecipeWithIngredients[], query: string, tag?: string) {
  const normalized = query.trim().toLowerCase();
  return recipes.filter((recipe) => {
    const matchesQuery = !normalized || recipe.title.toLowerCase().includes(normalized) || recipe.tags.some((item) => item.toLowerCase().includes(normalized));
    const matchesTag = !tag || recipe.tags.includes(tag);
    return matchesQuery && matchesTag;
  });
}
