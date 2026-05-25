import { View } from "react-native";
import { AppText } from "@/components/shared/AppText";

export function SectionHeader({ title, action }: { title: string; action?: string }) {
  return (
    <View className="mb-3 mt-6 flex-row items-center justify-between">
      <AppText className="text-xl" weight="bold">{title}</AppText>
      {action ? <AppText className="text-sm" tone="basil" weight="semibold">{action}</AppText> : null}
    </View>
  );
}
