import { View } from "react-native";
import { AppText } from "@/components/shared/AppText";

export function EmptyState({ title, body }: { title: string; body: string }) {
  return (
    <View className="items-center rounded-comfort bg-white p-6">
      <AppText className="text-lg text-center" weight="bold">{title}</AppText>
      <AppText className="mt-2 text-center" tone="muted">{body}</AppText>
    </View>
  );
}
