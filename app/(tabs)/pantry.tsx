import { useMemo, useState } from "react";
import { Alert, TextInput, View } from "react-native";
import { Button } from "@/components/shared/Button";
import { Screen } from "@/components/shared/Screen";
import { SearchField } from "@/components/shared/SearchField";
import { SectionHeader } from "@/components/shared/SectionHeader";
import { AppText } from "@/components/shared/AppText";
import { InventoryItemCard } from "@/components/pantry/InventoryItemCard";
import { PantrySummary } from "@/components/pantry/PantrySummary";
import { QuickAddChips } from "@/components/pantry/QuickAddChips";
import { PANTRY_LOCATIONS } from "@/lib/constants/categories";
import { useKitchenStore } from "@/lib/store/kitchenStore";
import type { PantryLocation } from "@/lib/types/models";
import { inferCategory } from "@/services/normalizationService";

export default function PantryScreen() {
  const { pantryItems, addPantryItem, consumePantryItem, deletePantryItem } = useKitchenStore();
  const [query, setQuery] = useState("");
  const [location, setLocation] = useState<PantryLocation | "all">("all");
  const [name, setName] = useState("");
  const [quantity, setQuantity] = useState("1");
  const [unit, setUnit] = useState("ct");

  const filtered = useMemo(() => pantryItems.filter((item) => {
    const matchesQuery = !query || item.name.toLowerCase().includes(query.toLowerCase()) || item.normalized_name.includes(query.toLowerCase());
    const matchesLocation = location === "all" || item.location === location;
    return matchesQuery && matchesLocation;
  }), [pantryItems, query, location]);

  function addManualItem() {
    if (!name.trim()) return;
    addPantryItem({
      name: name.trim(),
      category: inferCategory(name),
      quantity: Number(quantity) || 1,
      unit,
      expiration_date: null,
      location: "pantry",
      notes: null,
      low_stock_threshold: 1
    });
    setName("");
    setQuantity("1");
  }

  return (
    <Screen>
      <AppText className="pt-3 text-3xl" weight="bold">Pantry</AppText>
      <AppText className="mt-2" tone="muted">Fast inventory for the foods your household already owns.</AppText>
      <SectionHeader title="Summary" />
      <PantrySummary items={pantryItems} />

      <SectionHeader title="Quick add" />
      <QuickAddChips onAdd={addPantryItem} />

      <SectionHeader title="Add item" />
      <View className="gap-3 rounded-comfort bg-white p-4">
        <TextInput className="min-h-12 rounded-2xl bg-cream px-4 text-base text-ink" placeholder="Item name" placeholderTextColor="#728079" value={name} onChangeText={setName} />
        <View className="flex-row gap-3">
          <TextInput className="min-h-12 flex-1 rounded-2xl bg-cream px-4 text-base text-ink" keyboardType="decimal-pad" placeholder="Qty" value={quantity} onChangeText={setQuantity} />
          <TextInput className="min-h-12 flex-1 rounded-2xl bg-cream px-4 text-base text-ink" placeholder="Unit" value={unit} onChangeText={setUnit} />
        </View>
        <Button onPress={addManualItem}>Add to pantry</Button>
      </View>

      <SectionHeader title="Inventory" />
      <SearchField value={query} onChangeText={setQuery} placeholder="Search pantry" />
      <View className="my-3 flex-row flex-wrap gap-2">
        <Button variant={location === "all" ? "primary" : "secondary"} onPress={() => setLocation("all")}>All</Button>
        {PANTRY_LOCATIONS.map((item) => <Button key={item} variant={location === item ? "primary" : "secondary"} onPress={() => setLocation(item)}>{item}</Button>)}
      </View>
      {filtered.map((item) => (
        <InventoryItemCard
          key={item.id}
          item={item}
          onConsume={() => consumePantryItem(item.id)}
          onDelete={() => deletePantryItem(item.id)}
          onEdit={() => Alert.alert("Edit item", "Quantity editing is available from the card actions in this MVP.")}
        />
      ))}
    </Screen>
  );
}
