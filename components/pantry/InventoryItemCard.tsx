import { Pressable, View } from "react-native";
import { Badge } from "@/components/shared/Badge";
import { Button } from "@/components/shared/Button";
import { Card } from "@/components/shared/Card";
import { AppText } from "@/components/shared/AppText";
import type { PantryItem } from "@/lib/types/models";
import { daysUntil, isExpiringSoon } from "@/lib/utils/date";

export function InventoryItemCard({ item, onConsume, onDelete, onEdit }: { item: PantryItem; onConsume: () => void; onDelete: () => void; onEdit: () => void }) {
  const expiring = isExpiringSoon(item.expiration_date);
  const lowStock = item.low_stock_threshold !== null && item.low_stock_threshold !== undefined && item.quantity <= item.low_stock_threshold;
  const days = daysUntil(item.expiration_date);
  return (
    <Card className="mb-3">
      <Pressable onPress={onEdit} className="gap-3">
        <View className="flex-row items-start justify-between gap-3">
          <View className="flex-1">
            <AppText className="text-lg" weight="bold">{item.name}</AppText>
            <AppText className="mt-1 text-sm capitalize" tone="muted">{item.category} in {item.location}</AppText>
          </View>
          <AppText className="text-lg" weight="bold">{item.quantity} {item.unit}</AppText>
        </View>
        <View className="flex-row flex-wrap gap-2">
          {expiring ? <Badge label={days === 0 ? "expires today" : `expires in ${days}d`} tone="clay" /> : null}
          {lowStock ? <Badge label="low stock" tone="oat" /> : null}
        </View>
        <View className="flex-row gap-2">
          <Button className="flex-1" variant="secondary" onPress={onConsume}>Mark used</Button>
          <Button className="flex-1" variant="ghost" onPress={onDelete}>Delete</Button>
        </View>
      </Pressable>
    </Card>
  );
}
