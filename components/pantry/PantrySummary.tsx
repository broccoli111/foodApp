import { View } from "react-native";
import { MetricCard } from "@/components/shared/MetricCard";
import type { PantryItem } from "@/lib/types/models";
import { getInventorySummary } from "@/services/inventoryService";

export function PantrySummary({ items }: { items: PantryItem[] }) {
  const summary = getInventorySummary(items);
  return (
    <View className="flex-row gap-3">
      <MetricCard label="items at home" value={summary.total} />
      <MetricCard label="expiring soon" value={summary.expiringSoon} helper="Use first" />
      <MetricCard label="low stock" value={summary.lowStock} />
    </View>
  );
}
