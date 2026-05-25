import type { PropsWithChildren } from "react";
import Animated, { FadeInUp } from "react-native-reanimated";

interface CardProps {
  className?: string;
}

export function Card({ children, className = "" }: PropsWithChildren<CardProps>) {
  return (
    <Animated.View entering={FadeInUp.duration(260)} className={`rounded-comfort bg-card p-4 shadow-sm shadow-black/5 ${className}`}>
      {children}
    </Animated.View>
  );
}
