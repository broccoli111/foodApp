import { useMemo } from "react";
import { View } from "react-native";
import { Button } from "@/components/shared/Button";
import { Card } from "@/components/shared/Card";
import { Screen } from "@/components/shared/Screen";
import { SectionHeader } from "@/components/shared/SectionHeader";
import { AppText } from "@/components/shared/AppText";
import { useKitchenStore } from "@/lib/store/kitchenStore";
import { shortWeekday, weekDates } from "@/lib/utils/date";
import { scoreRecipeRecommendations } from "@/services/recommendationService";

export default function PlanScreen() {
  const { pantryItems, recipes, mealPlans, saleItems, stores, addMealPlan, removeMealPlan } = useKitchenStore();
  const dates = weekDates();
  const recommendations = useMemo(() => scoreRecipeRecommendations(pantryItems, recipes, saleItems, stores), [pantryItems, recipes, saleItems, stores]);

  return (
    <Screen>
      <AppText className="pt-3 text-3xl" weight="bold">Weekly plan</AppText>
      <AppText className="mt-2" tone="muted">Tap meals into days now; drag and drop can replace this interaction as the planner matures.</AppText>
      <SectionHeader title="This week" />
      {dates.map((date) => {
        const plans = mealPlans.filter((plan) => plan.planned_date === date);
        return (
          <Card key={date} className="mb-3">
            <View className="flex-row items-center justify-between">
              <View>
                <AppText className="text-lg" weight="bold">{shortWeekday(date)}</AppText>
                <AppText tone="muted">{date}</AppText>
              </View>
              <Button variant="secondary" onPress={() => {
                const top = recommendations[0];
                const recipe = recipes.find((item) => item.id === top?.recipe_id);
                if (recipe) addMealPlan({ recipe_id: recipe.id, planned_date: date, meal_type: "dinner", servings: recipe.servings });
              }}>Add pick</Button>
            </View>
            {plans.map((plan) => {
              const recipe = recipes.find((item) => item.id === plan.recipe_id);
              return (
                <View key={plan.id} className="mt-3 flex-row items-center justify-between rounded-2xl bg-cream p-3">
                  <View className="flex-1">
                    <AppText weight="semibold">{recipe?.title ?? "Recipe"}</AppText>
                    <AppText className="capitalize" tone="muted">{plan.meal_type} • {plan.servings} servings</AppText>
                  </View>
                  <Button variant="ghost" onPress={() => removeMealPlan(plan.id)}>Remove</Button>
                </View>
              );
            })}
          </Card>
        );
      })}
    </Screen>
  );
}
