import { BlurView } from "expo-blur";
import { Tabs } from "expo-router";
import { Feather, MaterialCommunityIcons } from "@expo/vector-icons";
import React from "react";
import { Platform, StyleSheet, View, useColorScheme } from "react-native";
import { useColors } from "@/hooks/useColors";
import { useApp } from "@/context/AppContext";

let SymbolView: any = null;
try {
  SymbolView = require("expo-symbols").SymbolView;
} catch {}

export default function TabLayout() {
  const colors = useColors();
  const colorScheme = useColorScheme();
  const isDark = colorScheme === "dark";
  const isIOS = Platform.OS === "ios";
  const isWeb = Platform.OS === "web";
  const { activeTabIndex, setActiveTabIndex } = useApp();

  return (
    <Tabs
      screenOptions={{
        tabBarActiveTintColor: colors.primary,
        tabBarInactiveTintColor: colors.mutedForeground,
        headerShown: false,
        tabBarStyle: {
          position: "absolute",
          backgroundColor: isIOS ? "transparent" : colors.card,
          borderTopWidth: 1,
          borderTopColor: colors.border,
          elevation: 0,
          height: isWeb ? 84 : 60,
        },
        tabBarBackground: () =>
          isIOS ? (
            <BlurView
              intensity={100}
              tint="dark"
              style={StyleSheet.absoluteFill}
            />
          ) : isWeb ? (
            <View
              style={[StyleSheet.absoluteFill, { backgroundColor: colors.card }]}
            />
          ) : null,
        tabBarLabelStyle: { fontSize: 10, fontWeight: "600" as const },
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: "Monitor",
          tabBarIcon: ({ color }) =>
            isIOS && SymbolView ? (
              <SymbolView name="iphone" tintColor={color} size={22} />
            ) : (
              <Feather name="smartphone" size={21} color={color} />
            ),
        }}
      />
      <Tabs.Screen
        name="chat"
        options={{
          title: "Chat",
          tabBarIcon: ({ color }) =>
            isIOS && SymbolView ? (
              <SymbolView name="message" tintColor={color} size={22} />
            ) : (
              <Feather name="message-circle" size={21} color={color} />
            ),
        }}
      />
      <Tabs.Screen
        name="knowledge"
        options={{
          title: "Knowledge",
          tabBarIcon: ({ color }) =>
            isIOS && SymbolView ? (
              <SymbolView name="brain" tintColor={color} size={22} />
            ) : (
              <MaterialCommunityIcons name="brain" size={22} color={color} />
            ),
        }}
      />
      <Tabs.Screen
        name="settings"
        options={{
          title: "Settings",
          tabBarIcon: ({ color }) =>
            isIOS && SymbolView ? (
              <SymbolView name="gearshape" tintColor={color} size={22} />
            ) : (
              <Feather name="settings" size={21} color={color} />
            ),
        }}
      />
    </Tabs>
  );
}
