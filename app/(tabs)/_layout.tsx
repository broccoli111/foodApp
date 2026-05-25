import { Tabs } from "expo-router";
import { theme } from "@/lib/constants/theme";

export default function TabLayout() {
  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: theme.colors.basil,
        tabBarInactiveTintColor: theme.colors.muted,
        tabBarStyle: {
          backgroundColor: "#FFF8EE",
          borderTopColor: "#F5E9D7",
          height: 84,
          paddingBottom: 24,
          paddingTop: 8
        },
        tabBarLabelStyle: { fontSize: 12, fontWeight: "600" }
      }}
    >
      <Tabs.Screen name="index" options={{ title: "Home" }} />
      <Tabs.Screen name="pantry" options={{ title: "Pantry" }} />
      <Tabs.Screen name="recipes" options={{ title: "Recipes" }} />
      <Tabs.Screen name="plan" options={{ title: "Plan" }} />
      <Tabs.Screen name="shopping" options={{ title: "Shopping" }} />
      <Tabs.Screen name="scan" options={{ title: "Scan" }} />
    </Tabs>
  );
}
