import { Stack } from "expo-router";
import { Card } from "@/components/shared/Card";
import { Screen } from "@/components/shared/Screen";
import { SectionHeader } from "@/components/shared/SectionHeader";
import { AppText } from "@/components/shared/AppText";
import { Badge } from "@/components/shared/Badge";
import { useKitchenStore } from "@/lib/store/kitchenStore";

export default function StoresScreen() {
  const { stores, saleItems } = useKitchenStore();
  return (
    <Screen>
      <Stack.Screen options={{ headerShown: true, title: "Stores & Sales" }} />
      <AppText className="pt-3 text-3xl" weight="bold">Stores and sales</AppText>
      <AppText className="mt-2" tone="muted">Mock sale ingestion is modular. Instacart data is intentionally not treated as authoritative pricing.</AppText>
      <SectionHeader title="Stores" />
      {stores.map((store) => (
        <Card key={store.id} className="mb-3">
          <AppText className="text-lg" weight="bold">{store.name}</AppText>
          <AppText className="mt-1" tone="muted">{store.chain} • {store.zip_code ?? "no zip"}</AppText>
          {store.preferred ? <Badge label="preferred" /> : null}
        </Card>
      ))}
      <SectionHeader title="Current sale items" />
      {saleItems.map((sale) => (
        <Card key={sale.id} className="mb-3">
          <AppText weight="bold">{sale.item_name}</AppText>
          <AppText className="mt-1" tone="muted">{sale.sale_description}</AppText>
        </Card>
      ))}
    </Screen>
  );
}
