import { View } from "react-native";
import { AppText } from "@/components/shared/AppText";
import type { PantryItem, RecipeWithIngredients } from "@/lib/types/models";
import { getRecipeMatch } from "@/services/recipeService";

export function IngredientMatchList({ recipe, pantryItems }: { recipe: RecipeWithIngredients; pantryItems: PantryItem[] }) {
  const match = getRecipeMatch(recipe, pantryItems);
  return (
    <View className="gap-4">
      <View>
        <AppText weight="bold">Available at home</AppText>
        {match.available.map((ingredient) => <AppText key={ingredient.id} className="mt-1" tone="muted">{ingredient.quantity} {ingredient.unit} {ingredient.name}</AppText>)}
      </View>
      <View>
        <AppText weight="bold">Missing</AppText>
        {match.missing.length === 0 ? <AppText className="mt-1" tone="basil">Nothing required is missing.</AppText> : match.missing.map((ingredient) => <AppText key={ingredient.id} className="mt-1" tone="muted">{ingredient.quantity} {ingredient.unit} {ingredient.name}</AppText>)}
      </View>
    </View>
  );
}
