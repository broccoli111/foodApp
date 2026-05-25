import { useEffect } from "react";
import { AppProviders } from "@/lib/providers/AppProviders";
import { useAuthStore } from "@/lib/store/authStore";

export default function RootLayout() {
  const initialize = useAuthStore((state) => state.initialize);

  useEffect(() => {
    void initialize();
  }, [initialize]);

  return <AppProviders />;
}
