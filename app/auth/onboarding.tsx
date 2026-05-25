import { router, Stack } from "expo-router";
import { Button } from "@/components/shared/Button";
import { Card } from "@/components/shared/Card";
import { Screen } from "@/components/shared/Screen";
import { AppText } from "@/components/shared/AppText";
import { useAuthStore } from "@/lib/store/authStore";

export default function OnboardingScreen() {
  const completeOnboarding = useAuthStore((state) => state.completeOnboarding);
  return (
    <Screen>
      <Stack.Screen options={{ headerShown: true, title: "Onboarding" }} />
      <AppText className="pt-3 text-3xl" weight="bold">Set your compass</AppText>
      <Card className="mt-5">
        <AppText weight="bold">1. Add what you already have</AppText>
        <AppText className="mt-2" tone="muted">Start with a quick pantry scan or manual staples.</AppText>
      </Card>
      <Card className="mt-3">
        <AppText weight="bold">2. Save family recipes</AppText>
        <AppText className="mt-2" tone="muted">Manual entry and scan review both feed recommendations.</AppText>
      </Card>
      <Card className="mt-3">
        <AppText weight="bold">3. Plan with less waste</AppText>
        <AppText className="mt-2" tone="muted">Kitchen Compass prioritizes expiring ingredients and short shopping lists.</AppText>
      </Card>
      <Button className="mt-5" onPress={() => { completeOnboarding(); router.replace("/(tabs)"); }}>Start planning</Button>
    </Screen>
  );
}
