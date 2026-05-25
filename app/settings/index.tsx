import { router, Stack } from "expo-router";
import { Button } from "@/components/shared/Button";
import { Screen } from "@/components/shared/Screen";
import { AppText } from "@/components/shared/AppText";
import { useAuthStore } from "@/lib/store/authStore";

export default function SettingsScreen() {
  const signOut = useAuthStore((state) => state.signOut);
  return (
    <Screen>
      <Stack.Screen options={{ headerShown: true, title: "Settings" }} />
      <AppText className="pt-3 text-3xl" weight="bold">Settings</AppText>
      <Button className="mt-5" onPress={() => router.push("/settings/stores")}>Stores and sales</Button>
      <Button className="mt-3" variant="secondary" onPress={() => router.push("/auth")}>Auth</Button>
      <Button className="mt-3" variant="ghost" onPress={() => void signOut()}>Sign out</Button>
    </Screen>
  );
}
