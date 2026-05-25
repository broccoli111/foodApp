import type { SaleItem, SaleMatch, ShoppingListItem, Store, StoreRecommendation } from "@/lib/types/models";
import { fuzzyMatchIngredient } from "@/services/normalizationService";

export function findSaleMatches(normalizedName: string, saleItems: SaleItem[], stores: Store[]): SaleMatch[] {
  return saleItems
    .map((sale_item) => {
      const score = fuzzyMatchIngredient(normalizedName, sale_item.normalized_name);
      const store = stores.find((item) => item.id === sale_item.store_id);
      if (!store || score < 0.68) return null;
      return {
        sale_item,
        store,
        matched_name: sale_item.normalized_name,
        savings_score: score * sale_item.confidence * (sale_item.sale_price ? 1.1 : 0.8)
      } satisfies SaleMatch;
    })
    .filter((match): match is SaleMatch => Boolean(match))
    .sort((a, b) => b.savings_score - a.savings_score);
}

export function recommendStores(shoppingItems: ShoppingListItem[], saleItems: SaleItem[], stores: Store[]): {
  bestSingleStore: StoreRecommendation | null;
  bestSavingsOption: StoreRecommendation | null;
  options: StoreRecommendation[];
} {
  const options = stores.map((store) => {
    const storeSales = saleItems.filter((sale) => sale.store_id === store.id);
    const sale_matches = shoppingItems.flatMap((item) => findSaleMatches(item.normalized_name, storeSales, [store]));
    const covered_items = shoppingItems.filter((item) => sale_matches.some((match) => match.sale_item.normalized_name === item.normalized_name));
    const coverageScore = covered_items.length * 8;
    const savingsScore = sale_matches.reduce((total, match) => total + match.savings_score * 5, 0);
    const preferenceScore = store.preferred ? 6 : 0;
    const tinyTripPenalty = covered_items.length <= 1 && !store.preferred ? 7 : 0;
    const score = coverageScore + savingsScore + preferenceScore - tinyTripPenalty;
    return {
      store,
      covered_items,
      sale_matches,
      score,
      summary: covered_items.length > 0
        ? `${store.name} covers ${covered_items.length} of ${shoppingItems.length} items with ${sale_matches.length} sale match${sale_matches.length === 1 ? "" : "es"}.`
        : `${store.name} is available but has no strong sale matches right now.`
    } satisfies StoreRecommendation;
  }).sort((a, b) => b.score - a.score);

  const bestSingleStore = [...options].sort((a, b) => {
    const coverageDiff = b.covered_items.length - a.covered_items.length;
    return coverageDiff !== 0 ? coverageDiff : b.score - a.score;
  })[0] ?? null;

  const bestSavingsOption = options[0] ?? null;
  return { bestSingleStore, bestSavingsOption, options };
}
