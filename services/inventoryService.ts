import type { PantryItem } from "@/lib/types/models";
import { inferCategory, normalizeIngredientName } from "@/services/normalizationService";

export function buildPantryItem(input: Omit<PantryItem, "id" | "household_id" | "normalized_name" | "category" | "created_at" | "updated_at"> & { category?: string }, householdId: string): PantryItem {
  const timestamp = new Date().toISOString();
  const normalized_name = normalizeIngredientName(input.name);
  return {
    ...input,
    id: `pantry-${Date.now()}`,
    household_id: householdId,
    normalized_name,
    category: input.category || inferCategory(normalized_name),
    created_at: timestamp,
    updated_at: timestamp
  };
}

export function getInventorySummary(items: PantryItem[]) {
  const expiringSoon = items.filter((item) => item.expiration_date && new Date(item.expiration_date).getTime() - Date.now() <= 5 * 86400000).length;
  const lowStock = items.filter((item) => item.low_stock_threshold !== null && item.low_stock_threshold !== undefined && item.quantity <= item.low_stock_threshold).length;
  const byLocation = items.reduce<Record<string, number>>((acc, item) => {
    acc[item.location] = (acc[item.location] ?? 0) + 1;
    return acc;
  }, {});
  return { total: items.length, expiringSoon, lowStock, byLocation };
}
