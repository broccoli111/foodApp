import { useMemo } from "react";
import { Button } from "@/components/shared/Button";
import { EmptyState } from "@/components/shared/EmptyState";
import { Screen } from "@/components/shared/Screen";
import { SectionHeader } from "@/components/shared/SectionHeader";
import { AppText } from "@/components/shared/AppText";
import { ShoppingListItemCard } from "@/components/shopping/ShoppingListItemCard";
import { StoreRecommendationCard } from "@/components/shopping/StoreRecommendationCard";
import { useKitchenStore } from "@/lib/store/kitchenStore";
import { groupShoppingListByCategory, generateShoppingListFromMealPlan } from "@/services/shoppingListService";
import { recommendStores } from "@/services/saleMatchingService";

export default function ShoppingScreen() {
  const { householdId, mealPlans, recipes, pantryItems, saleItems, stores, shoppingListItems, setShoppingList, toggleShoppingItem } = useKitchenStore();
  const generated = useMemo(() => generateShoppingListFromMealPlan(householdId, mealPlans, recipes, pantryItems, saleItems, stores), [householdId, mealPlans, recipes, pantryItems, saleItems, stores]);
  const items = shoppingListItems.length > 0 ? shoppingListItems : generated;
  const grouped = groupShoppingListByCategory(items);
  const guidance = recommendStores(items, saleItems, stores);

  return (
    <Screen>
      <AppText className="pt-3 text-3xl" weight="bold">Shopping</AppText>
      <AppText className="mt-2" tone="muted">Generated from planned meals, minus what is already in the pantry.</AppText>
      <Button className="mt-5" onPress={() => setShoppingList(generated)}>Regenerate from meal plan</Button>
      <SectionHeader title="Store guidance" />
      <StoreRecommendationCard title="Best single-store option" recommendation={guidance.bestSingleStore} />
      <StoreRecommendationCard title="Best savings option" recommendation={guidance.bestSavingsOption} />
      <SectionHeader title="List" />
      {grouped.length === 0 ? <EmptyState title="Nothing to buy" body="Your current meal plan is covered by what you have at home." /> : grouped.map((group) => (
        <Section key={group.category} title={group.category}>
          {group.items.map((item) => <ShoppingListItemCard key={item.id} item={item} stores={stores} sales={saleItems} onToggle={() => toggleShoppingItem(item.id)} />)}
        </Section>
      ))}
    </Screen>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <>
      <AppText className="mb-2 mt-2 capitalize" weight="bold" tone="muted">{title}</AppText>
      {children}
    </>
  );
}
