import { Feather, MaterialCommunityIcons } from "@expo/vector-icons";
import * as Haptics from "expo-haptics";
import { router } from "expo-router";
import React, { useState } from "react";
import {
  Alert,
  FlatList,
  Modal,
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import CandleLoader from "@/components/CandleLoader";
import { useApp } from "@/context/AppContext";
import { useColors } from "@/hooks/useColors";

export default function ScreenMonitorScreen() {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const {
    installedApps,
    addApp,
    removeApp,
    selectedApp,
    setSelectedApp,
    tradingActive,
    setTradingActive,
    setScreenShareActive,
    isLoadingTrading,
    setIsLoadingTrading,
    setActiveTabIndex,
  } = useApp();

  const [selectorVisible, setSelectorVisible] = useState(false);
  const [editMode, setEditMode] = useState(false);
  const [addVisible, setAddVisible] = useState(false);
  const [newAppName, setNewAppName] = useState("");

  const handleStartTrading = () => {
    if (!selectedApp) {
      Alert.alert("App Select Kara", "Konti trading app use karaychi te select kara.");
      return;
    }
    setSelectorVisible(false);
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Heavy);
    setIsLoadingTrading(true);
  };

  const handleLoadingComplete = () => {
    setIsLoadingTrading(false);
    setTradingActive(true);
    setScreenShareActive(true);
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
  };

  const handleCommand123 = () => {
    setSelectorVisible(true);
  };

  if (isLoadingTrading) {
    return (
      <CandleLoader
        appName={selectedApp?.name ?? "Trading App"}
        onComplete={handleLoadingComplete}
      />
    );
  }

  return (
    <View
      style={[
        styles.container,
        {
          backgroundColor: colors.background,
          paddingTop: insets.top + (Platform.OS === "web" ? 67 : 0),
          paddingBottom: insets.bottom + (Platform.OS === "web" ? 34 : 0),
        },
      ]}
    >
      <View style={styles.header}>
        <Text style={[styles.headerTitle, { color: colors.foreground }]}>
          Screen Monitoring
        </Text>
        {tradingActive && (
          <View style={[styles.activeBadge, { backgroundColor: colors.primary }]}>
            <View style={styles.activeDot} />
            <Text style={styles.activeText}>LIVE</Text>
          </View>
        )}
      </View>

      <View style={styles.body}>
        <TouchableOpacity
          style={[styles.monitorCard, { backgroundColor: colors.card, borderColor: tradingActive ? colors.primary : colors.border }]}
          onPress={() => {
            Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
            setSelectorVisible(true);
          }}
          activeOpacity={0.8}
        >
          <View style={[styles.iconCircle, { backgroundColor: tradingActive ? colors.primary + "20" : colors.secondary }]}>
            <Feather
              name="smartphone"
              size={52}
              color={tradingActive ? colors.primary : colors.mutedForeground}
            />
          </View>
          <Text style={[styles.monitorTitle, { color: colors.foreground }]}>
            {tradingActive ? "Trading Active" : "Screen Monitoring"}
          </Text>
          <Text style={[styles.monitorSub, { color: colors.mutedForeground }]}>
            {tradingActive
              ? `Monitoring: ${selectedApp?.name}`
              : "Tap to select app & start trading"}
          </Text>
        </TouchableOpacity>

        <View style={[styles.commandCard, { backgroundColor: colors.card, borderColor: colors.border }]}>
          <Text style={[styles.commandTitle, { color: colors.foreground }]}>
            Quick Commands
          </Text>
          <View style={styles.commandList}>
            {[
              { cmd: "123", label: "Trading Suru Kar", color: colors.primary },
              { cmd: "13 6", label: "Buy / Sell Decision", color: colors.accent },
              { cmd: "25 2", label: "Buy/Sell Percent", color: "#A78BFA" },
              { cmd: "3 2 1", label: "Trading Band Kar", color: colors.destructive },
            ].map((item) => (
              <View key={item.cmd} style={styles.cmdRow}>
                <View style={[styles.cmdBadge, { backgroundColor: item.color + "20", borderColor: item.color }]}>
                  <Text style={[styles.cmdCode, { color: item.color }]}>{item.cmd}</Text>
                </View>
                <Text style={[styles.cmdLabel, { color: colors.mutedForeground }]}>{item.label}</Text>
              </View>
            ))}
          </View>
        </View>
      </View>

      <Modal visible={selectorVisible} transparent animationType="slide">
        <View style={styles.modalOverlay}>
          <View style={[styles.sheet, { backgroundColor: colors.card }]}>
            <View style={styles.sheetHeader}>
              <Text style={[styles.sheetTitle, { color: colors.foreground }]}>
                Trading App Select Kara
              </Text>
              <View style={styles.sheetActions}>
                <TouchableOpacity
                  onPress={() => setEditMode(!editMode)}
                  style={[styles.sheetBtn, { borderColor: colors.border }]}
                >
                  <Feather
                    name={editMode ? "check" : "edit-2"}
                    size={16}
                    color={editMode ? colors.primary : colors.mutedForeground}
                  />
                </TouchableOpacity>
                <TouchableOpacity
                  onPress={() => setAddVisible(true)}
                  style={[styles.sheetBtn, { borderColor: colors.border }]}
                >
                  <Feather name="plus" size={16} color={colors.primary} />
                </TouchableOpacity>
                <TouchableOpacity
                  onPress={() => setSelectorVisible(false)}
                  style={[styles.sheetBtn, { borderColor: colors.border }]}
                >
                  <Feather name="x" size={16} color={colors.mutedForeground} />
                </TouchableOpacity>
              </View>
            </View>

            <FlatList
              data={installedApps}
              keyExtractor={(a) => a.id}
              style={{ maxHeight: 280 }}
              contentContainerStyle={{ gap: 8, paddingVertical: 8 }}
              renderItem={({ item }) => (
                <TouchableOpacity
                  style={[
                    styles.appRow,
                    {
                      backgroundColor:
                        selectedApp?.id === item.id
                          ? colors.primary + "15"
                          : colors.secondary,
                      borderColor:
                        selectedApp?.id === item.id
                          ? colors.primary
                          : "transparent",
                    },
                  ]}
                  onPress={() => {
                    setSelectedApp(item);
                    Haptics.selectionAsync();
                  }}
                >
                  <View style={[styles.appIcon, { backgroundColor: colors.muted }]}>
                    <Feather
                      name={(item.icon as any) || "trending-up"}
                      size={18}
                      color={colors.primary}
                    />
                  </View>
                  <Text style={[styles.appName, { color: colors.foreground }]}>
                    {item.name}
                  </Text>
                  {selectedApp?.id === item.id && (
                    <Feather name="check-circle" size={18} color={colors.primary} />
                  )}
                  {editMode && (
                    <TouchableOpacity
                      onPress={() => {
                        removeApp(item.id);
                        if (selectedApp?.id === item.id) setSelectedApp(null);
                      }}
                    >
                      <Feather name="trash-2" size={16} color={colors.destructive} />
                    </TouchableOpacity>
                  )}
                </TouchableOpacity>
              )}
            />

            <TouchableOpacity
              style={[
                styles.startBtn,
                {
                  backgroundColor: selectedApp ? colors.primary : colors.muted,
                },
              ]}
              onPress={handleStartTrading}
              activeOpacity={0.85}
            >
              <Feather name="play" size={18} color={selectedApp ? colors.primaryForeground : colors.mutedForeground} />
              <Text
                style={[
                  styles.startBtnText,
                  { color: selectedApp ? colors.primaryForeground : colors.mutedForeground },
                ]}
              >
                Start Trading
              </Text>
            </TouchableOpacity>
          </View>
        </View>
      </Modal>

      <Modal visible={addVisible} transparent animationType="fade">
        <View style={styles.modalOverlay}>
          <View style={[styles.addSheet, { backgroundColor: colors.card }]}>
            <Text style={[styles.sheetTitle, { color: colors.foreground, marginBottom: 16 }]}>
              App Name Taka
            </Text>
            <TextInput
              style={[styles.input, { backgroundColor: colors.input, borderColor: colors.border, color: colors.foreground }]}
              placeholder="E.g. Zerodha Kite"
              placeholderTextColor={colors.mutedForeground}
              value={newAppName}
              onChangeText={setNewAppName}
            />
            <View style={styles.addActions}>
              <TouchableOpacity
                style={[styles.addCancelBtn, { borderColor: colors.border }]}
                onPress={() => { setAddVisible(false); setNewAppName(""); }}
              >
                <Text style={{ color: colors.mutedForeground }}>Cancel</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.addConfirmBtn, { backgroundColor: colors.primary }]}
                onPress={() => {
                  if (newAppName.trim()) {
                    addApp(newAppName.trim());
                    setNewAppName("");
                    setAddVisible(false);
                  }
                }}
              >
                <Text style={{ color: colors.primaryForeground, fontWeight: "600" as const }}>Add</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  header: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    paddingHorizontal: 20,
    paddingVertical: 16,
  },
  headerTitle: { fontSize: 22, fontWeight: "700" as const },
  activeBadge: {
    flexDirection: "row",
    alignItems: "center",
    gap: 5,
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 20,
  },
  activeDot: { width: 6, height: 6, borderRadius: 3, backgroundColor: "#0A0E1A" },
  activeText: { fontSize: 11, fontWeight: "700" as const, color: "#0A0E1A" },
  body: { flex: 1, paddingHorizontal: 20, gap: 16 },
  monitorCard: {
    borderRadius: 20,
    padding: 28,
    alignItems: "center",
    gap: 12,
    borderWidth: 1.5,
  },
  iconCircle: {
    width: 100,
    height: 100,
    borderRadius: 50,
    justifyContent: "center",
    alignItems: "center",
    marginBottom: 4,
  },
  monitorTitle: { fontSize: 20, fontWeight: "700" as const },
  monitorSub: { fontSize: 13, textAlign: "center" },
  commandCard: { borderRadius: 16, padding: 16, borderWidth: 1 },
  commandTitle: { fontSize: 14, fontWeight: "700" as const, marginBottom: 12 },
  commandList: { gap: 10 },
  cmdRow: { flexDirection: "row", alignItems: "center", gap: 10 },
  cmdBadge: { paddingHorizontal: 10, paddingVertical: 4, borderRadius: 8, borderWidth: 1 },
  cmdCode: { fontSize: 13, fontWeight: "700" as const },
  cmdLabel: { fontSize: 13 },
  modalOverlay: {
    flex: 1,
    backgroundColor: "rgba(0,0,0,0.7)",
    justifyContent: "flex-end",
  },
  sheet: {
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    padding: 20,
    gap: 12,
    paddingBottom: 36,
  },
  sheetHeader: { flexDirection: "row", justifyContent: "space-between", alignItems: "center" },
  sheetTitle: { fontSize: 17, fontWeight: "700" as const },
  sheetActions: { flexDirection: "row", gap: 8 },
  sheetBtn: {
    width: 34,
    height: 34,
    borderRadius: 10,
    borderWidth: 1,
    justifyContent: "center",
    alignItems: "center",
  },
  appRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
    padding: 12,
    borderRadius: 12,
    borderWidth: 1.5,
  },
  appIcon: {
    width: 36,
    height: 36,
    borderRadius: 10,
    justifyContent: "center",
    alignItems: "center",
  },
  appName: { flex: 1, fontSize: 15, fontWeight: "500" as const },
  startBtn: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: 8,
    paddingVertical: 14,
    borderRadius: 14,
    marginTop: 4,
  },
  startBtnText: { fontSize: 16, fontWeight: "700" as const },
  addSheet: {
    margin: 24,
    borderRadius: 20,
    padding: 24,
  },
  input: {
    borderRadius: 12,
    borderWidth: 1,
    padding: 14,
    fontSize: 15,
    marginBottom: 16,
  },
  addActions: { flexDirection: "row", gap: 12 },
  addCancelBtn: {
    flex: 1,
    padding: 12,
    borderRadius: 12,
    borderWidth: 1,
    alignItems: "center",
  },
  addConfirmBtn: {
    flex: 1,
    padding: 12,
    borderRadius: 12,
    alignItems: "center",
  },
});
