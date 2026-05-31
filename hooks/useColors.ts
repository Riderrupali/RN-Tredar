import { useColorScheme } from "react-native";

const darkColors = {
  background: "#0A0E1A",
  foreground: "#F1F5F9",
  card: "#111827",
  cardForeground: "#F1F5F9",
  border: "#1E2A3A",
  input: "#1A2235",
  primary: "#2A6EFF",
  primaryForeground: "#FFFFFF",
  secondary: "#1A2235",
  secondaryForeground: "#94A3B8",
  muted: "#1E2A3A",
  mutedForeground: "#64748B",
  accent: "#0EA5E9",
  accentForeground: "#FFFFFF",
  destructive: "#EF4444",
  destructiveForeground: "#FFFFFF",
  success: "#22C55E",
  warning: "#F59E0B",
};

const lightColors = {
  background: "#F8FAFC",
  foreground: "#0F172A",
  card: "#FFFFFF",
  cardForeground: "#0F172A",
  border: "#E2E8F0",
  input: "#F1F5F9",
  primary: "#2A6EFF",
  primaryForeground: "#FFFFFF",
  secondary: "#F1F5F9",
  secondaryForeground: "#475569",
  muted: "#F1F5F9",
  mutedForeground: "#94A3B8",
  accent: "#0EA5E9",
  accentForeground: "#FFFFFF",
  destructive: "#EF4444",
  destructiveForeground: "#FFFFFF",
  success: "#22C55E",
  warning: "#F59E0B",
};

export type Colors = typeof darkColors;

export function useColors(): Colors {
  const scheme = useColorScheme();
  return scheme === "light" ? lightColors : darkColors;
}
