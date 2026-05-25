import { Pressable, View } from "react-native";
import { AppText } from "@/components/shared/AppText";
import { Card } from "@/components/shared/Card";
import type { SaleItem, ShoppingListItem, Store } from "@/lib/types/models";

export function ShoppingListItemCard({ item, stores, sales, onToggle }: { item: ShoppingListItem; stores: Store[]; sales: SaleItem[]; onToggle: () => void }) {
  const store = stores.find((storeItem) => storeItem.id === item.recommended_store_id);
  const sale = sales.find((saleItem) => saleItem.id === item.matched_sale_item_id);
  return (
    <Pressable onPress={onToggle}>
      <Card className={`mb-3 ${item.checked ? "opacity-50" : ""}`}>
        <View className="flex-row items-center justify-between gap-3">
          <View className="flex-1">
            <AppText className={`text-lg ${item.checked ? "line-through" : ""}`} weight="bold">{item.name}</AppText>
            <AppText tone="muted">{item.quantity_needed} {item.unit} - {item.category}</AppText>
            {store ? <AppText className="mt-2 text-sm" tone="basil">Recommended: {store.name}{sale ? ` (${sale.sale_description})` : ""}</AppText> : null}
          </View>
          <View className={`h-7 w-7 rounded-full border-2 ${item.checked ? "border-basil bg-basil" : "border-sage"}`} />
        </View>
      </Card>
    </Pressable>
  );
}
