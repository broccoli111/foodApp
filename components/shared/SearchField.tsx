import { TextInput, View } from "react-native";

export function SearchField({ value, onChangeText, placeholder = "Search" }: { value: string; onChangeText: (value: string) => void; placeholder?: string }) {
  return (
    <View className="rounded-2xl bg-white px-4 py-1 shadow-sm shadow-black/5">
      <TextInput
        value={value}
        onChangeText={onChangeText}
        placeholder={placeholder}
        placeholderTextColor="#728079"
        className="min-h-12 text-base text-ink"
        returnKeyType="search"
      />
    </View>
  );
}
