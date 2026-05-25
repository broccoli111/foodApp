import { router } from "expo-router";
import { View } from "react-native";
import { MetricCard } from "@/components/shared/MetricCard";
import { Screen } from "@/components/shared/Screen";
import { SectionHeader } from "@/components/shared/SectionHeader";
import { AppText } from "@/components/shared/AppText";
import { Button } from "@/components/shared/Button";
import { RecommendationCard } from "@/components/recommendations/RecommendationCard";
import { PantrySummary } from "@/components/pantry/PantrySummary";
import { StoreRecommendationCard } from "@/components/shopping/StoreRecommendationCard";
import { useKitchenStore } from "@/lib/store/kitchenStore";
import { isExpiringSoon, daysFromNow } from "@/lib/utils/date";
import { scoreRecipeRecommendations } from "@/services/recommendationService";
import { generateShoppingListFromMealPlan } from "@/services/shoppingListService";
import { recommendStores } from "@/services/saleMatchingService";

export default function HomeScreen() {
  const { householdId, pantryItems, recipes, mealPlans, saleItems, stores, addMealPlan, setShoppingList, shoppingListItems } = useKitchenStore();
  const recommendations = scoreRecipeRecommendations(pantryItems, recipes, saleItems, stores).slice(0, 3);
  const expiring = pantryItems.filter((item) => isExpiringSoon(item.expiration_date)).slice(0, 3);
  const generatedShopping = shoppingListItems.length > 0 ? shoppingListItems : generateShoppingListFromMealPlan(householdId, mealPlans, recipes, pantryItems, saleItems, stores);
  const storeGuidance = recommendStores(generatedShopping, saleItems, stores);

  return (
    <Screen>
      <View className="pt-3">
        <AppText className="text-sm uppercase tracking-wide" tone="muted" weight="bold">Kitchen Compass</AppText>
        <AppText className="mt-2 text-4xl leading-tight" weight="bold">Cook from what you have.</AppText>
        <AppText className="mt-2 text-base" tone="muted">Buy what is missing where it makes sense.</AppText>
      </View>

      <View className="mt-6 flex-row gap-3">
        <MetricCard label="planned meals" value={mealPlans.length} />
        <MetricCard label="shopping items" value={generatedShopping.length} />
      </View>

      <SectionHeader title="Pantry pulse" />
      <PantrySummary items={pantryItems} />

      <SectionHeader title="Recommended this week" action="Explainable picks" />
      {recommendations.map((recommendation) => {
        const recipe = recipes.find((item) => item.id === recommendation.recipe_id);
        if (!recipe) return null;
        return (
          <RecommendationCard
            key={recommendation.recipe_id}
            recipe={recipe}
            recommendation={recommendation}
            onAddToPlan={() => addMealPlan({ recipe_id: recipe.id, planned_date: daysFromNow(2), meal_type: "dinner", servings: recipe.servings })}
          />
        );
      })}

      <SectionHeader title="Use soon" />
      {expiring.map((item) => <AppText key={item.id} className="mb-2" tone="muted">{item.name} expires on {item.expiration_date}</AppText>)}
      {expiring.length === 0 ? <AppText tone="muted">Nothing urgent this week.</AppText> : null}

      <SectionHeader title="Shopping guidance" />
      <StoreRecommendationCard title="Best single-store option" recommendation={storeGuidance.bestSingleStore} />
      <StoreRecommendationCard title="Best savings option" recommendation={storeGuidance.bestSavingsOption} />
      {shoppingListItems.length === 0 ? <Button variant="secondary" onPress={() => setShoppingList(generatedShopping)}>Create current shopping list</Button> : null}
      <Button className="mt-3" variant="ghost" onPress={() => router.push("/settings/stores")}>Manage stores and sales</Button>
    </Screen>
  );
}
