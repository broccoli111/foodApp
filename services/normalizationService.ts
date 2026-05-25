import type { RecipeIngredient } from "@/lib/types/models";

const brandWords = new Set([
  "barilla",
  "trader",
  "joe",
  "joes",
  "kirkland",
  "costco",
  "stop",
  "shop",
  "shoprite",
  "whole",
  "foods",
  "bjs",
  "bj"
]);

const descriptors = new Set([
  "fresh",
  "frozen",
  "organic",
  "baby",
  "bag",
  "bags",
  "box",
  "boxes",
  "can",
  "cans",
  "jar",
  "jars",
  "pkg",
  "package",
  "boneless",
  "skinless",
  "large",
  "small",
  "medium",
  "ripe",
  "whole",
  "reduced",
  "low",
  "sodium",
  "percent",
  "2%"
]);

const singulars: Record<string, string> = {
  breasts: "breast",
  thighs: "thigh",
  tomatoes: "tomato",
  potatoes: "potato",
  onions: "onion",
  eggs: "eggs",
  noodles: "noodle",
  bags: "bag",
  cans: "can"
};

const aliases: Record<string, string> = {
  "chicken breasts": "chicken breast",
  "chicken breast": "chicken breast",
  "baby spinach": "spinach",
  spinach: "spinach",
  "barilla penne": "penne pasta",
  penne: "penne pasta",
  "penne pasta": "penne pasta",
  "2 dozen eggs": "eggs",
  "dozen eggs": "eggs",
  egg: "eggs",
  eggs: "eggs",
  "milk 2": "milk",
  "2 milk": "milk",
  "ground beef": "ground beef",
  beef: "beef",
  cilantro: "cilantro",
  "black beans": "black beans",
  "taco shells": "taco shells"
};

const categoryRules: Array<[string, string[]]> = [
  ["produce", ["spinach", "lettuce", "tomato", "onion", "potato", "pepper", "cilantro", "apple", "banana", "lemon", "lime", "avocado"]],
  ["meat", ["chicken", "beef", "pork", "turkey", "sausage", "bacon"]],
  ["seafood", ["salmon", "shrimp", "tuna", "cod"]],
  ["dairy", ["milk", "cheese", "yogurt", "cream", "butter"]],
  ["eggs", ["egg"]],
  ["pasta", ["pasta", "penne", "spaghetti", "noodle", "macaroni"]],
  ["grains", ["rice", "quinoa", "oat", "flour", "bread", "tortilla"]],
  ["canned", ["beans", "tomato sauce", "broth", "corn"]],
  ["spices", ["salt", "pepper", "cumin", "paprika", "oregano", "basil", "garlic powder"]],
  ["condiments", ["oil", "vinegar", "mustard", "ketchup", "mayo", "sauce"]]
];

const unitAliases: Record<string, string> = {
  tablespoon: "tbsp",
  tablespoons: "tbsp",
  tbsp: "tbsp",
  teaspoon: "tsp",
  teaspoons: "tsp",
  tsp: "tsp",
  pounds: "lb",
  pound: "lb",
  lbs: "lb",
  lb: "lb",
  ounces: "oz",
  ounce: "oz",
  oz: "oz",
  cups: "cup",
  cup: "cup",
  count: "ct",
  ct: "ct",
  dozen: "dozen",
  bag: "bag",
  box: "box",
  can: "can"
};

export function normalizeIngredientName(input: string): string {
  const lower = input
    .toLowerCase()
    .replace(/&/g, " and ")
    .replace(/[^a-z0-9%\s]/g, " ")
    .replace(/\s+/g, " ")
    .trim();

  if (aliases[lower]) return aliases[lower];

  const tokens = lower
    .split(" ")
    .filter((token) => token && !/^\d+(\.\d+)?$/.test(token))
    .filter((token) => !brandWords.has(token))
    .filter((token) => !descriptors.has(token))
    .map((token) => singulars[token] ?? token);

  const phrase = tokens.join(" ").trim();
  if (aliases[phrase]) return aliases[phrase];
  if (phrase.includes("penne")) return "penne pasta";
  if (phrase.includes("spinach")) return "spinach";
  if (phrase.includes("egg")) return "eggs";
  if (phrase.includes("milk")) return "milk";
  return phrase || lower;
}

export function inferCategory(input: string): string {
  const normalized = normalizeIngredientName(input);
  for (const [category, keywords] of categoryRules) {
    if (keywords.some((keyword) => normalized.includes(keyword))) return category;
  }
  return "other";
}

export function normalizeUnit(unit: string): string {
  return unitAliases[unit.toLowerCase().trim()] ?? unit.toLowerCase().trim();
}

export function fuzzyMatchIngredient(a: string, b: string): number {
  const left = normalizeIngredientName(a);
  const right = normalizeIngredientName(b);
  if (left === right) return 1;
  if (left.includes(right) || right.includes(left)) return 0.82;

  const leftTokens = new Set(left.split(" "));
  const rightTokens = new Set(right.split(" "));
  const intersection = [...leftTokens].filter((token) => rightTokens.has(token)).length;
  const union = new Set([...leftTokens, ...rightTokens]).size;
  return union === 0 ? 0 : intersection / union;
}

const conversionToBase: Record<string, { base: string; factor: number }> = {
  tsp: { base: "tsp", factor: 1 },
  tbsp: { base: "tsp", factor: 3 },
  cup: { base: "tsp", factor: 48 },
  oz: { base: "oz", factor: 1 },
  lb: { base: "oz", factor: 16 },
  ct: { base: "ct", factor: 1 },
  dozen: { base: "ct", factor: 12 }
};

export function convertUnits(quantity: number, fromUnit: string, toUnit: string): number | null {
  const from = conversionToBase[normalizeUnit(fromUnit)];
  const to = conversionToBase[normalizeUnit(toUnit)];
  if (!from || !to || from.base !== to.base) return null;
  return (quantity * from.factor) / to.factor;
}

export function parseIngredientLine(rawText: string): Omit<RecipeIngredient, "id" | "recipe_id"> {
  const trimmed = rawText.trim();
  const match = trimmed.match(/^(\d+(?:\.\d+)?|\d+\/\d+)?\s*([a-zA-Z]+)?\s*(.*)$/);
  const quantity = match?.[1]?.includes("/")
    ? match[1].split("/").map(Number).reduce((a, b) => a / b)
    : Number(match?.[1] ?? 1);
  const unit = normalizeUnit(match?.[2] ?? "ct");
  const name = match?.[3]?.trim() || trimmed;
  const normalized_name = normalizeIngredientName(name);
  return {
    raw_text: rawText,
    name: normalized_name,
    normalized_name,
    quantity: Number.isFinite(quantity) ? quantity : 1,
    unit,
    category: inferCategory(normalized_name),
    optional: /optional/i.test(rawText)
  };
}
