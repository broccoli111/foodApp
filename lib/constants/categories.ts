import type { PantryLocation } from "@/lib/types/models";

export const CATEGORIES = [
  "produce",
  "meat",
  "seafood",
  "dairy",
  "eggs",
  "bakery",
  "grains",
  "pasta",
  "canned",
  "frozen",
  "spices",
  "condiments",
  "snacks",
  "beverages",
  "household",
  "other"
] as const;

export const PANTRY_LOCATIONS: PantryLocation[] = ["pantry", "fridge", "freezer", "spice", "other"];

export const COMMON_QUICK_ADDS = [
  { name: "eggs", quantity: 12, unit: "ct", category: "eggs", location: "fridge" as PantryLocation },
  { name: "milk", quantity: 1, unit: "gal", category: "dairy", location: "fridge" as PantryLocation },
  { name: "chicken breast", quantity: 2, unit: "lb", category: "meat", location: "freezer" as PantryLocation },
  { name: "spinach", quantity: 1, unit: "bag", category: "produce", location: "fridge" as PantryLocation },
  { name: "penne pasta", quantity: 1, unit: "box", category: "pasta", location: "pantry" as PantryLocation },
  { name: "rice", quantity: 2, unit: "lb", category: "grains", location: "pantry" as PantryLocation }
];

export const CATEGORY_ORDER = CATEGORIES.reduce<Record<string, number>>((acc, category, index) => {
  acc[category] = index;
  return acc;
}, {});
