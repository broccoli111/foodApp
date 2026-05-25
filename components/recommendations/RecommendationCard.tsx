import { View } from "react-native";
import { Badge } from "@/components/shared/Badge";
import { Button } from "@/components/shared/Button";
import { Card } from "@/components/shared/Card";
import { AppText } from "@/components/shared/AppText";
import type { RecipeRecommendation, RecipeWithIngredients } from "@/lib/types/models";

const badgeLabel = {
  minimal_shopping: "minimal shopping",
  uses_expiring: "uses expiring items",
  sale_opportunity: "sale opportunity"
};

export function RecommendationCard({ recipe, recommendation, onAddToPlan }: { recipe: RecipeWithIngredients; recommendation: RecipeRecommendation; onAddToPlan: () => void }) {
  return (
    <Card className="mb-3 border border-sage/10">
      <View className="flex-row justify-between gap-3">
        <View className="flex-1">
          <AppText className="text-lg" weight="bold">{recipe.title}</AppText>
          <AppText className="mt-1" tone="muted">{recommendation.reason_summary.join(". ")}</AppText>
        </View>
        <View className="items-end">
          <AppText className="text-2xl" weight="bold" tone="basil">{recommendation.match_percent}%</AppText>
          <AppText className="text-xs" tone="muted">match</AppText>
        </View>
      </View>
      <View className="mt-3 flex-row flex-wrap gap-2">
        {recommendation.badges.map((badge) => <Badge key={badge} label={badgeLabel[badge]} tone={badge === "sale_opportunity" ? "clay" : "sage"} />)}
      </View>
      <Button className="mt-4" onPress={onAddToPlan}>Save to this week</Button>
    </Card>
  );
}
