import type { PropsWithChildren } from "react";
import { ScrollView, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";

interface ScreenProps {
  scroll?: boolean;
  className?: string;
}

export function Screen({ children, scroll = true, className = "" }: PropsWithChildren<ScreenProps>) {
  const content = <View className={`px-5 pb-8 ${className}`}>{children}</View>;
  return (
    <SafeAreaView className="flex-1 bg-cream" edges={["top"]}>
      {scroll ? <ScrollView showsVerticalScrollIndicator={false}>{content}</ScrollView> : content}
    </SafeAreaView>
  );
}
