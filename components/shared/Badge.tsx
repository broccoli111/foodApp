import { View } from "react-native";
import { AppText } from "@/components/shared/AppText";

export function Badge({ label, tone = "sage" }: { label: string; tone?: "sage" | "clay" | "oat" }) {
  const classes = tone === "clay" ? "bg-clay/15" : tone === "oat" ? "bg-oat" : "bg-sage/20";
  return (
    <View className={`rounded-full px-3 py-1 ${classes}`}>
      <AppText className="text-xs" tone={tone === "clay" ? "clay" : "basil"} weight="semibold">{label}</AppText>
    </View>
  );
}
