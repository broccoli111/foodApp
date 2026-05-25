import { Pressable } from "react-native";
import { Card } from "@/components/shared/Card";
import { AppText } from "@/components/shared/AppText";

export function ScanOptionCard({ title, body, onPress }: { title: string; body: string; onPress: () => void }) {
  return (
    <Pressable onPress={onPress}>
      <Card className="mb-3">
        <AppText className="text-lg" weight="bold">{title}</AppText>
        <AppText className="mt-2" tone="muted">{body}</AppText>
      </Card>
    </Pressable>
  );
}
