import { View } from "react-native";
import { AppText } from "@/components/shared/AppText";

export function MetricCard({ label, value, helper }: { label: string; value: string | number; helper?: string }) {
  return (
    <View className="flex-1 rounded-3xl bg-white p-4 shadow-sm shadow-black/5">
      <AppText className="text-2xl" weight="bold">{value}</AppText>
      <AppText className="mt-1 text-sm" tone="muted">{label}</AppText>
      {helper ? <AppText className="mt-2 text-xs" tone="basil">{helper}</AppText> : null}
    </View>
  );
}
