import { router, Stack } from "expo-router";
import { useState } from "react";
import { TextInput, View } from "react-native";
import { Button } from "@/components/shared/Button";
import { Screen } from "@/components/shared/Screen";
import { AppText } from "@/components/shared/AppText";
import { useKitchenStore } from "@/lib/store/kitchenStore";
import { parseIngredientLine } from "@/services/normalizationService";

export default function AddRecipeScreen() {
  const addRecipe = useKitchenStore((state) => state.addRecipe);
  const [title, setTitle] = useState("");
  const [ingredients, setIngredients] = useState("1 lb chicken breast\n1 bag spinach");
  const [instructions, setInstructions] = useState("Cook everything until done.");

  function save() {
    if (!title.trim()) return;
    const recipe = addRecipe({
      title: title.trim(),
      description: "Manually added household recipe.",
      image_url: null,
      source_type: "manual",
      source_url: null,
      servings: 4,
      prep_time_minutes: 10,
      cook_time_minutes: 20,
      instructions: instructions.split(/\n+/).filter(Boolean),
      tags: ["manual"],
      favorite: false,
      ingredients: ingredients.split(/\n+/).filter(Boolean).map(parseIngredientLine)
    });
    router.replace(`/recipe/${recipe.id}`);
  }

  return (
    <Screen>
      <Stack.Screen options={{ headerShown: true, title: "Add Recipe" }} />
      <AppText className="pt-3 text-3xl" weight="bold">Create recipe</AppText>
      <View className="mt-5 gap-3">
        <TextInput className="min-h-12 rounded-2xl bg-white px-4 text-base" placeholder="Recipe title" value={title} onChangeText={setTitle} />
        <TextInput className="min-h-32 rounded-2xl bg-white px-4 py-3 text-base" multiline placeholder="Ingredients, one per line" value={ingredients} onChangeText={setIngredients} />
        <TextInput className="min-h-32 rounded-2xl bg-white px-4 py-3 text-base" multiline placeholder="Instructions" value={instructions} onChangeText={setInstructions} />
        <Button onPress={save}>Save recipe</Button>
      </View>
    </Screen>
  );
}
