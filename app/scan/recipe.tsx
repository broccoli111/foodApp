import * as ImagePicker from "expo-image-picker";
import { router, Stack } from "expo-router";
import { useState } from "react";
import { TextInput, View } from "react-native";
import { Button } from "@/components/shared/Button";
import { Card } from "@/components/shared/Card";
import { Screen } from "@/components/shared/Screen";
import { SectionHeader } from "@/components/shared/SectionHeader";
import { AppText } from "@/components/shared/AppText";
import { useKitchenStore } from "@/lib/store/kitchenStore";
import type { ParsedRecipeDraft } from "@/lib/types/models";
import { scanService } from "@/services/scanService";

export default function ScanRecipeScreen() {
  const addRecipe = useKitchenStore((state) => state.addRecipe);
  const [text, setText] = useState("");
  const [draft, setDraft] = useState<ParsedRecipeDraft | null>(null);
  const [loading, setLoading] = useState(false);

  async function runScan(uri?: string) {
    setLoading(true);
    try {
      setDraft(await scanService.scanRecipe({ uri, pastedText: text }));
    } finally {
      setLoading(false);
    }
  }

  async function pickImage(camera: boolean) {
    const result = camera
      ? await ImagePicker.launchCameraAsync({ allowsEditing: true, quality: 0.8 })
      : await ImagePicker.launchImageLibraryAsync({ allowsEditing: true, quality: 0.8 });
    if (!result.canceled) await runScan(result.assets[0]?.uri);
  }

  function saveDraft() {
    if (!draft) return;
    const recipe = addRecipe({ ...draft, image_url: null, source_type: "scan", source_url: null, favorite: false });
    router.replace(`/recipe/${recipe.id}`);
  }

  return (
    <Screen>
      <Stack.Screen options={{ headerShown: true, title: "Scan Recipe" }} />
      <AppText className="pt-3 text-3xl" weight="bold">Scan recipe</AppText>
      <AppText className="mt-2" tone="muted">OCR and LLM parsing are abstracted behind mocked providers for this MVP.</AppText>
      <View className="mt-5 flex-row gap-3">
        <Button className="flex-1" onPress={() => pickImage(true)}>Take photo</Button>
        <Button className="flex-1" variant="secondary" onPress={() => pickImage(false)}>Upload</Button>
      </View>
      <SectionHeader title="Or paste text" />
      <TextInput className="min-h-36 rounded-2xl bg-white px-4 py-3 text-base" multiline value={text} onChangeText={setText} placeholder="Paste recipe text" />
      <Button className="mt-3" variant="secondary" onPress={() => runScan()}>{loading ? "Scanning..." : "Extract recipe"}</Button>
      {draft ? (
        <>
          <SectionHeader title="Review before saving" />
          <Card>
            <AppText className="text-xl" weight="bold">{draft.title}</AppText>
            <AppText className="mt-2" tone="muted">Serves {draft.servings} • {draft.prep_time_minutes + draft.cook_time_minutes} min</AppText>
            <AppText className="mt-4" weight="bold">Ingredients</AppText>
            {draft.ingredients.map((ingredient) => <AppText key={ingredient.raw_text} className="mt-1" tone="muted">{ingredient.raw_text}</AppText>)}
          </Card>
          <Button className="mt-4" onPress={saveDraft}>Save recipe</Button>
        </>
      ) : null}
    </Screen>
  );
}
