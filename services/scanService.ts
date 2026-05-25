import type { ParsedReceiptItem, ParsedRecipeDraft } from "@/lib/types/models";
import { inferCategory, normalizeIngredientName, parseIngredientLine } from "@/services/normalizationService";

const id = (prefix: string) => `${prefix}-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;

export interface OcrProvider {
  extractText(source: { uri?: string; pastedText?: string; type: "recipe" | "receipt" }): Promise<string>;
}

export interface RecipeParser {
  parseRecipe(rawText: string): Promise<ParsedRecipeDraft>;
}

export interface ReceiptParser {
  parseReceipt(rawText: string): Promise<ParsedReceiptItem[]>;
}

export class MockOcrProvider implements OcrProvider {
  async extractText(source: { uri?: string; pastedText?: string; type: "recipe" | "receipt" }) {
    if (source.pastedText?.trim()) return source.pastedText.trim();
    if (source.type === "recipe") {
      return "Sheet Pan Chicken and Spinach\nServes 4\nPrep 10 minutes\nCook 25 minutes\nIngredients\n1 lb chicken breasts\n1 bag baby spinach\n1 lb potatoes\n2 tbsp olive oil\nInstructions\nSlice potatoes. Roast chicken and potatoes. Add spinach at the end.";
    }
    return "STOP AND SHOP\n2 DOZEN EGGS\nBARILLA PENNE\nMILK 2%\nBABY SPINACH BAG";
  }
}

export class DeterministicRecipeParser implements RecipeParser {
  async parseRecipe(rawText: string): Promise<ParsedRecipeDraft> {
    const lines = rawText.split(/\n+/).map((line) => line.trim()).filter(Boolean);
    const title = lines[0] ?? "Scanned recipe";
    const servings = Number(rawText.match(/serves?\s+(\d+)/i)?.[1] ?? 4);
    const prep_time_minutes = Number(rawText.match(/prep\s+(\d+)/i)?.[1] ?? 10);
    const cook_time_minutes = Number(rawText.match(/cook\s+(\d+)/i)?.[1] ?? 20);
    const ingredientStart = lines.findIndex((line) => /^ingredients?/i.test(line));
    const instructionStart = lines.findIndex((line) => /^instructions?|directions?/i.test(line));
    const ingredientLines = ingredientStart >= 0
      ? lines.slice(ingredientStart + 1, instructionStart > ingredientStart ? instructionStart : undefined)
      : lines.filter((line) => /^\d/.test(line));
    const instructionLines = instructionStart >= 0 ? lines.slice(instructionStart + 1) : ["Review and add cooking steps."];

    return {
      title,
      servings,
      prep_time_minutes,
      cook_time_minutes,
      description: "Imported from scan. Please review before saving.",
      ingredients: ingredientLines.map(parseIngredientLine),
      instructions: instructionLines.length > 0 ? instructionLines : ["Review scanned instructions."],
      tags: ["scan"]
    };
  }
}

export class DeterministicReceiptParser implements ReceiptParser {
  async parseReceipt(rawText: string): Promise<ParsedReceiptItem[]> {
    return rawText.split(/\n+/)
      .map((line) => line.trim())
      .filter((line) => line && !/(total|visa|cash|stop and shop|shoprite|costco)/i.test(line))
      .map((raw_text) => {
        const dozenMatch = raw_text.match(/(\d+)\s+dozen\s+eggs/i);
        const normalized_name = normalizeIngredientName(raw_text);
        return {
          id: id("receipt"),
          raw_text,
          normalized_name,
          name: normalized_name,
          quantity: dozenMatch ? Number(dozenMatch[1]) * 12 : 1,
          unit: dozenMatch ? "ct" : "ct",
          category: inferCategory(normalized_name),
          confidence: normalized_name === raw_text.toLowerCase() ? 0.7 : 0.88,
          approved: true
        };
      });
  }
}

export const scanService = {
  ocr: new MockOcrProvider(),
  recipeParser: new DeterministicRecipeParser(),
  receiptParser: new DeterministicReceiptParser(),
  async scanRecipe(input: { uri?: string; pastedText?: string }) {
    const rawText = await this.ocr.extractText({ ...input, type: "recipe" });
    return this.recipeParser.parseRecipe(rawText);
  },
  async scanReceipt(input: { uri?: string; pastedText?: string }) {
    const rawText = await this.ocr.extractText({ ...input, type: "receipt" });
    return this.receiptParser.parseReceipt(rawText);
  }
};
