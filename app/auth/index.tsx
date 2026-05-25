import { router, Stack } from "expo-router";
import { useState } from "react";
import { TextInput, View } from "react-native";
import { Button } from "@/components/shared/Button";
import { Screen } from "@/components/shared/Screen";
import { AppText } from "@/components/shared/AppText";
import { isSupabaseConfigured } from "@/lib/supabase/client";
import { useAuthStore } from "@/lib/store/authStore";

export default function AuthScreen() {
  const { signInWithEmail, signUpWithEmail } = useAuthStore();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [message, setMessage] = useState<string | null>(null);

  async function submit(mode: "sign-in" | "sign-up") {
    try {
      if (mode === "sign-in") await signInWithEmail(email, password);
      else await signUpWithEmail(email, password);
      router.replace("/(tabs)");
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "Authentication failed");
    }
  }

  return (
    <Screen>
      <Stack.Screen options={{ headerShown: true, title: "Sign in" }} />
      <AppText className="pt-3 text-3xl" weight="bold">Welcome home</AppText>
      <AppText className="mt-2" tone="muted">Use Supabase email auth for persistent household access.</AppText>
      {!isSupabaseConfigured ? <AppText className="mt-4 rounded-2xl bg-oat p-3" tone="basil">Set EXPO_PUBLIC_SUPABASE_URL and EXPO_PUBLIC_SUPABASE_ANON_KEY to enable real auth.</AppText> : null}
      <View className="mt-5 gap-3">
        <TextInput className="min-h-12 rounded-2xl bg-white px-4 text-base" autoCapitalize="none" keyboardType="email-address" placeholder="Email" value={email} onChangeText={setEmail} />
        <TextInput className="min-h-12 rounded-2xl bg-white px-4 text-base" secureTextEntry placeholder="Password" value={password} onChangeText={setPassword} />
        {message ? <AppText tone="clay">{message}</AppText> : null}
        <Button onPress={() => submit("sign-in")}>Sign in</Button>
        <Button variant="secondary" onPress={() => submit("sign-up")}>Create account</Button>
        <Button variant="ghost" onPress={() => router.push("/auth/onboarding")}>Continue to onboarding</Button>
      </View>
    </Screen>
  );
}
