import type { PropsWithChildren } from "react";
import { Text, type TextProps } from "react-native";

interface AppTextProps extends TextProps {
  tone?: "default" | "muted" | "basil" | "clay";
  weight?: "regular" | "medium" | "semibold" | "bold";
}

const toneClass = {
  default: "text-ink",
  muted: "text-muted",
  basil: "text-basil",
  clay: "text-clay"
};

const weightClass = {
  regular: "font-normal",
  medium: "font-medium",
  semibold: "font-semibold",
  bold: "font-bold"
};

export function AppText({ children, className = "", tone = "default", weight = "regular", ...props }: PropsWithChildren<AppTextProps>) {
  return <Text className={`${toneClass[tone]} ${weightClass[weight]} ${className}`} {...props}>{children}</Text>;
}
