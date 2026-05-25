import { Stack, useLocalSearchParams, router } from "expo-router";
import { Button } from "@/components/shared/Button";
import { Card } from "@/components/shared/Card";
import { Screen } from "@/components/shared/Screen";
import { SectionHeader } from "@/components/shared/SectionHeader";
import { AppText } from "@/components/shared/AppText";
import { IngredientMatchList } from "@/components/recipes/IngredientMatchList";
import { useKitchenStore } from "@/lib/store/kitchenStore";
import { daysFromNow } from "@/lib/utils/date";

export default function RecipeDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { recipes, pantryItems, addMealPlan, deleteRecipe } = useKitchenStore();
  const recipe = recipes.find((item) => item.id === id);

  if (!recipe) {
    return <Screen><AppText>Recipe not found.</AppText></Screen>;
  }

  return (
    <Screen>
      <Stack.Screen options={{ headerShown: true, title: recipe.title }} />
      <AppText className="pt-3 text-3xl" weight="bold">{recipe.title}</AppText>
      <AppText className="mt-2" tone="muted">{recipe.description}</AppText>
      <Button className="mt-5" onPress={() => addMealPlan({ recipe_id: recipe.id, planned_date: daysFromNow(1), meal_type: "dinner", servings: recipe.servings })}>Add to meal plan</Button>
      <Button className="mt-3" variant="ghost" onPress={() => { deleteRecipe(recipe.id); router.back(); }}>Delete recipe</Button>
      <SectionHeader title="Pantry match" />
      <Card><IngredientMatchList recipe={recipe} pantryItems={pantryItems} /></Card>
      <SectionHeader title="Instructions" />
      <Card>
        {recipe.instructions.map((instruction, index) => <AppText key={`${instruction}-${index}`} className="mb-3">{index + 1}. {instruction}</AppText>)}
      </Card>
    </Screen>
  );
}
