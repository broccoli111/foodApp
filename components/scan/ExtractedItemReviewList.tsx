import { Pressable, View } from "react-native";
import { AppText } from "@/components/shared/AppText";
import type { ParsedReceiptItem } from "@/lib/types/models";

export function ExtractedItemReviewList({ items, onToggle }: { items: ParsedReceiptItem[]; onToggle: (id: string) => void }) {
  return (
    <View className="gap-2">
      {items.map((item) => (
        <Pressable key={item.id} onPress={() => onToggle(item.id)} className="rounded-2xl bg-white p-4">
          <View className="flex-row items-center justify-between">
            <View className="flex-1">
              <AppText weight="bold">{item.name}</AppText>
              <AppText className="mt-1 text-sm" tone="muted">From {item.raw_text} - {Math.round(item.confidence * 100)}% confidence</AppText>
            </View>
            <View className={`h-6 w-6 rounded-full border-2 ${item.approved ? "border-basil bg-basil" : "border-muted"}`} />
          </View>
        </Pressable>
      ))}
    </View>
  );
}
