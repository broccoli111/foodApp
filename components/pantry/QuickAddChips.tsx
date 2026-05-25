import { ScrollView } from "react-native";
import { Button } from "@/components/shared/Button";
import { COMMON_QUICK_ADDS } from "@/lib/constants/categories";
import type { PantryItem } from "@/lib/types/models";

export function QuickAddChips({ onAdd }: { onAdd: (item: Omit<PantryItem, "id" | "household_id" | "normalized_name" | "created_at" | "updated_at">) => void }) {
  return (
    <ScrollView horizontal showsHorizontalScrollIndicator={false} className="-mx-5 px-5">
      {COMMON_QUICK_ADDS.map((item) => (
        <Button key={item.name} variant="secondary" className="mr-2" onPress={() => onAdd({ ...item, expiration_date: null, notes: null, low_stock_threshold: 1 })}>
          + {item.name}
        </Button>
      ))}
    </ScrollView>
  );
}
