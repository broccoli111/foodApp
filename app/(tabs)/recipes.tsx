import { router } from "expo-router";
import { useMemo, useState } from "react";
import { Button } from "@/components/shared/Button";
import { Screen } from "@/components/shared/Screen";
import { SearchField } from "@/components/shared/SearchField";
import { SectionHeader } from "@/components/shared/SectionHeader";
import { AppText } from "@/components/shared/AppText";
import { RecipeCard } from "@/components/recipes/RecipeCard";
import { useKitchenStore } from "@/lib/store/kitchenStore";
import { searchRecipes } from "@/services/recipeService";

export default function RecipesScreen() {
  const { recipes, pantryItems } = useKitchenStore();
  const [query, setQuery] = useState("");
  const filtered = useMemo(() => searchRecipes(recipes, query), [recipes, query]);

  return (
    <Screen>
      <AppText className="pt-3 text-3xl" weight="bold">Recipes</AppText>
      <AppText className="mt-2" tone="muted">Recipes stay connected to pantry reality and sale opportunities.</AppText>
      <Button className="mt-5" onPress={() => router.push("/recipe/add")}>Create recipe</Button>
      <Button className="mt-3" variant="secondary" onPress={() => router.push("/scan/recipe")}>Scan recipe</Button>
      <SectionHeader title="Library" />
      <SearchField value={query} onChangeText={setQuery} placeholder="Search recipes or tags" />
      {filtered.map((recipe) => <RecipeCard key={recipe.id} recipe={recipe} pantryItems={pantryItems} onPress={() => router.push(`/recipe/${recipe.id}`)} />)}
    </Screen>
  );
}
