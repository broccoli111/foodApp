import { router } from "expo-router";
import { Screen } from "@/components/shared/Screen";
import { AppText } from "@/components/shared/AppText";
import { SectionHeader } from "@/components/shared/SectionHeader";
import { ScanOptionCard } from "@/components/scan/ScanOptionCard";

export default function ScanScreen() {
  return (
    <Screen>
      <AppText className="pt-3 text-3xl" weight="bold">Scan</AppText>
      <AppText className="mt-2" tone="muted">Mocked extraction flows keep parsing replaceable while the app remains usable.</AppText>
      <SectionHeader title="What are you adding?" />
      <ScanOptionCard title="Scan recipe" body="Take a photo, upload an image, or paste recipe text. Review before saving." onPress={() => router.push("/scan/recipe")} />
      <ScanOptionCard title="Scan receipt" body="Extract grocery items, approve what matters, and batch-add to pantry." onPress={() => router.push("/scan/receipt")} />
    </Screen>
  );
}
