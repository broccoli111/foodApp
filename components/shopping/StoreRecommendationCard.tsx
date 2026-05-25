import { View } from "react-native";
import { AppText } from "@/components/shared/AppText";
import { Badge } from "@/components/shared/Badge";
import { Card } from "@/components/shared/Card";
import type { StoreRecommendation } from "@/lib/types/models";

export function StoreRecommendationCard({ title, recommendation }: { title: string; recommendation: StoreRecommendation | null }) {
  if (!recommendation) return null;
  return (
    <Card className="mb-3">
      <View className="flex-row items-start justify-between">
        <View className="flex-1">
          <AppText className="text-sm uppercase tracking-wide" tone="muted" weight="bold">{title}</AppText>
          <AppText className="mt-1 text-xl" weight="bold">{recommendation.store.name}</AppText>
          <AppText className="mt-2" tone="muted">{recommendation.summary}</AppText>
        </View>
        {recommendation.store.preferred ? <Badge label="preferred" /> : null}
      </View>
    </Card>
  );
}
