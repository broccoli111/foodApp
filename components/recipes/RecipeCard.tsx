import { Pressable, View } from "react-native";
import { Badge } from "@/components/shared/Badge";
import { Card } from "@/components/shared/Card";
import { AppText } from "@/components/shared/AppText";
import type { PantryItem, RecipeWithIngredients } from "@/lib/types/models";
import { getRecipeMatch } from "@/services/recipeService";

export function RecipeCard({ recipe, pantryItems, onPress }: { recipe: RecipeWithIngredients; pantryItems: PantryItem[]; onPress: () => void }) {
  const match = getRecipeMatch(recipe, pantryItems);
  return (
    <Pressable onPress={onPress}>
      <Card className="mb-3">
        <View className="flex-row items-start justify-between gap-3">
          <View className="flex-1">
            <AppText className="text-lg" weight="bold">{recipe.title}</AppText>
            <AppText className="mt-1" tone="muted">{recipe.description}</AppText>
          </View>
          <Badge label={`${match.matchPercent}% match`} tone={match.matchPercent > 70 ? "sage" : "oat"} />
        </View>
        <View className="mt-3 flex-row flex-wrap gap-2">
          {recipe.favorite ? <Badge label="favorite" /> : null}
          {recipe.tags.slice(0, 3).map((tag) => <Badge key={tag} label={tag} tone="oat" />)}
        </View>
        <AppText className="mt-3 text-sm" tone="muted">{recipe.prep_time_minutes + recipe.cook_time_minutes} min total - {match.missing.length} missing</AppText>
      </Card>
    </Pressable>
  );
}
