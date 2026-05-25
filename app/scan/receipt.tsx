import * as ImagePicker from "expo-image-picker";
import { Stack } from "expo-router";
import { useState } from "react";
import { TextInput, View } from "react-native";
import { Button } from "@/components/shared/Button";
import { Screen } from "@/components/shared/Screen";
import { SectionHeader } from "@/components/shared/SectionHeader";
import { AppText } from "@/components/shared/AppText";
import { ExtractedItemReviewList } from "@/components/scan/ExtractedItemReviewList";
import { useKitchenStore } from "@/lib/store/kitchenStore";
import type { ParsedReceiptItem } from "@/lib/types/models";
import { scanService } from "@/services/scanService";

export default function ScanReceiptScreen() {
  const addPantryItem = useKitchenStore((state) => state.addPantryItem);
  const [text, setText] = useState("");
  const [items, setItems] = useState<ParsedReceiptItem[]>([]);
  const [loading, setLoading] = useState(false);

  async function runScan(uri?: string) {
    setLoading(true);
    try {
      setItems(await scanService.scanReceipt({ uri, pastedText: text }));
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

  function addApproved() {
    items.filter((item) => item.approved).forEach((item) => addPantryItem({
      name: item.name,
      category: item.category,
      quantity: item.quantity,
      unit: item.unit,
      expiration_date: null,
      location: item.category === "dairy" || item.category === "eggs" || item.category === "produce" ? "fridge" : "pantry",
      notes: `From receipt: ${item.raw_text}`,
      low_stock_threshold: 1
    }));
    setItems([]);
  }

  return (
    <Screen>
      <Stack.Screen options={{ headerShown: true, title: "Scan Receipt" }} />
      <AppText className="pt-3 text-3xl" weight="bold">Scan receipt</AppText>
      <AppText className="mt-2" tone="muted">Approve only the items you want added to inventory.</AppText>
      <View className="mt-5 flex-row gap-3">
        <Button className="flex-1" onPress={() => pickImage(true)}>Take photo</Button>
        <Button className="flex-1" variant="secondary" onPress={() => pickImage(false)}>Upload</Button>
      </View>
      <SectionHeader title="Or paste receipt text" />
      <TextInput className="min-h-36 rounded-2xl bg-white px-4 py-3 text-base" multiline value={text} onChangeText={setText} placeholder="Paste receipt lines" />
      <Button className="mt-3" variant="secondary" onPress={() => runScan()}>{loading ? "Scanning..." : "Extract items"}</Button>
      {items.length > 0 ? (
        <>
          <SectionHeader title="Review items" />
          <ExtractedItemReviewList items={items} onToggle={(id) => setItems((current) => current.map((item) => item.id === id ? { ...item, approved: !item.approved } : item))} />
          <Button className="mt-4" onPress={addApproved}>Add approved to pantry</Button>
        </>
      ) : null}
    </Screen>
  );
}
