import * as Haptics from "expo-haptics";
import type { PropsWithChildren } from "react";
import { Pressable, type PressableProps } from "react-native";
import { AppText } from "@/components/shared/AppText";

type ButtonVariant = "primary" | "secondary" | "ghost" | "danger";

interface ButtonProps extends PressableProps {
  variant?: ButtonVariant;
  className?: string;
}

const variants: Record<ButtonVariant, string> = {
  primary: "bg-basil",
  secondary: "bg-oat",
  ghost: "bg-transparent",
  danger: "bg-clay"
};

const textVariants: Record<ButtonVariant, "default" | "muted" | "basil" | "clay"> = {
  primary: "default",
  secondary: "basil",
  ghost: "basil",
  danger: "default"
};

export function Button({ children, variant = "primary", className = "", onPress, ...props }: PropsWithChildren<ButtonProps>) {
  return (
    <Pressable
      className={`min-h-12 items-center justify-center rounded-2xl px-5 ${variants[variant]} ${className}`}
      onPress={(event) => {
        void Haptics.selectionAsync();
        onPress?.(event);
      }}
      {...props}
    >
      <AppText weight="semibold" tone={textVariants[variant]} className={variant === "primary" || variant === "danger" ? "text-white" : ""}>{children}</AppText>
    </Pressable>
  );
}
