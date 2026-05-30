import { Feather } from "@expo/vector-icons";
import * as ImagePicker from "expo-image-picker";
import React from "react";
import {
  Alert,
  Image,
  ImageBackground,
  Platform,
  ScrollView,
  StyleSheet,
  Switch,
  Text,
  TouchableOpacity,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { useApp } from "@/context/AppContext";
import { useColors } from "@/hooks/useColors";

export default function SettingsScreen() {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const { customThemeBg, setCustomThemeBg, alwaysOnMicActive, setAlwaysOnMicActive, clearMessages } = useApp();

  const handlePickTheme = async () => {
    const perm = await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (!perm.granted) return;
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ["images"],
      quality: 0.9,
    });
    if (!result.canceled) setCustomThemeBg(result.assets[0].uri);
  };

  return (
    <ScrollView
      style={[styles.container, { backgroundColor: colors.background }]}
      contentContainerStyle={{
        paddingTop: insets.top + (Platform.OS === "web" ? 67 : 0),
        paddingBottom: insets.bottom + (Platform.OS === "web" ? 34 : 40),
      }}
      showsVerticalScrollIndicator={false}
    >
      <View style={styles.header}>
        <Text style={[styles.headerTitle, { color: colors.foreground }]}>Settings</Text>
      </View>

      <View style={styles.section}>
        <Text style={[styles.sectionTitle, { color: colors.mutedForeground }]}>THEME</Text>

        <View style={[styles.themePreview, { borderColor: colors.border }]}>
          {customThemeBg ? (
            <Image source={{ uri: customThemeBg }} style={styles.themeImg} />
          ) : (
            <Image
              source={require("@/assets/images/trading_bg.png")}
              style={styles.themeImg}
            />
          )}
          <View style={[styles.themeOverlay, { backgroundColor: "rgba(10,14,26,0.55)" }]}>
            <Text style={styles.themeLabel}>
              {customThemeBg ? "Custom Theme" : "Default Trading Theme"}
            </Text>
          </View>
        </View>

        <View style={styles.themeActions}>
          <TouchableOpacity
            style={[styles.themeBtn, { backgroundColor: colors.card, borderColor: colors.border }]}
            onPress={handlePickTheme}
          >
            <Feather name="image" size={16} color={colors.primary} />
            <Text style={[styles.themeBtnText, { color: colors.foreground }]}>
              Gallery se photo add karo
            </Text>
          </TouchableOpacity>

          {customThemeBg && (
            <TouchableOpacity
              style={[styles.themeResetBtn, { borderColor: colors.border }]}
              onPress={() => setCustomThemeBg(null)}
            >
              <Feather name="rotate-ccw" size={14} color={colors.mutedForeground} />
              <Text style={[styles.themeResetText, { color: colors.mutedForeground }]}>
                Default Reset
              </Text>
            </TouchableOpacity>
          )}
        </View>
      </View>

      <View style={styles.section}>
        <Text style={[styles.sectionTitle, { color: colors.mutedForeground }]}>MIC SETTINGS</Text>

        <View style={[styles.settingRow, { backgroundColor: colors.card, borderColor: colors.border }]}>
          <View style={styles.settingLeft}>
            <Feather name="mic" size={18} color={colors.primary} />
            <View>
              <Text style={[styles.settingLabel, { color: colors.foreground }]}>
                Always-On Mic
              </Text>
              <Text style={[styles.settingDesc, { color: colors.mutedForeground }]}>
                Sagla aayknar — Google mic sarakh
              </Text>
            </View>
          </View>
          <Switch
            value={alwaysOnMicActive}
            onValueChange={setAlwaysOnMicActive}
            trackColor={{ false: colors.border, true: colors.primary }}
            thumbColor="#FFFFFF"
          />
        </View>
      </View>

      <View style={styles.section}>
        <Text style={[styles.sectionTitle, { color: colors.mutedForeground }]}>COMMANDS</Text>
        <View style={[styles.commandsCard, { backgroundColor: colors.card, borderColor: colors.border }]}>
          {[
            { code: "123", desc: "Trading suru kar — Screen Monitor ughado" },
            { code: "2", desc: "Information save kara (He lakshyat thev)" },
            { code: "25 2", desc: "Buy kiti % / Sell kiti % — analysis" },
            { code: "13 6", desc: "Quick Buy/Sell decision — 1 second madhe" },
            { code: "3 2 1", desc: "Trading band kara, app madhe parat" },
            { code: "000", desc: "Chat clear kara (reset)" },
          ].map((c) => (
            <View key={c.code} style={[styles.cmdItem, { borderBottomColor: colors.border }]}>
              <View style={[styles.cmdCode, { backgroundColor: colors.secondary }]}>
                <Text style={[styles.cmdCodeText, { color: colors.accent }]}>{c.code}</Text>
              </View>
              <Text style={[styles.cmdDesc, { color: colors.mutedForeground }]}>{c.desc}</Text>
            </View>
          ))}
        </View>
      </View>

      <View style={styles.section}>
        <Text style={[styles.sectionTitle, { color: colors.mutedForeground }]}>DATA</Text>
        <TouchableOpacity
          style={[styles.dangerBtn, { backgroundColor: colors.card, borderColor: colors.destructive + "40" }]}
          onPress={() => {
            Alert.alert("Chat Clear?", "Sagla chat history delete heil.", [
              { text: "Cancel", style: "cancel" },
              { text: "Clear", style: "destructive", onPress: clearMessages },
            ]);
          }}
        >
          <Feather name="trash-2" size={16} color={colors.destructive} />
          <Text style={[styles.dangerText, { color: colors.destructive }]}>
            Chat History Clear Kara
          </Text>
        </TouchableOpacity>
      </View>

      <View style={styles.aboutSection}>
        <Text style={[styles.aboutApp, { color: colors.mutedForeground }]}>
          Code Magic Trading App
        </Text>
        <Text style={[styles.aboutVersion, { color: colors.border }]}>v1.0.0</Text>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  header: { paddingHorizontal: 20, paddingVertical: 16 },
  headerTitle: { fontSize: 22, fontWeight: "700" as const },
  section: { paddingHorizontal: 16, marginBottom: 24 },
  sectionTitle: {
    fontSize: 11,
    fontWeight: "700" as const,
    letterSpacing: 1.2,
    marginBottom: 10,
    marginLeft: 4,
  },
  themePreview: {
    borderRadius: 16,
    overflow: "hidden",
    height: 160,
    borderWidth: 1,
    marginBottom: 12,
  },
  themeImg: { width: "100%", height: "100%", resizeMode: "cover" },
  themeOverlay: {
    ...StyleSheet.absoluteFillObject,
    justifyContent: "flex-end",
    padding: 14,
  },
  themeLabel: {
    color: "#FFFFFF",
    fontWeight: "600" as const,
    fontSize: 14,
  },
  themeActions: { gap: 8 },
  themeBtn: {
    flexDirection: "row",
    alignItems: "center",
    gap: 10,
    padding: 14,
    borderRadius: 12,
    borderWidth: 1,
  },
  themeBtnText: { fontSize: 14, fontWeight: "500" as const },
  themeResetBtn: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
    padding: 10,
    borderRadius: 10,
    borderWidth: 1,
    justifyContent: "center",
  },
  themeResetText: { fontSize: 13 },
  settingRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    padding: 14,
    borderRadius: 14,
    borderWidth: 1,
  },
  settingLeft: { flexDirection: "row", alignItems: "center", gap: 12 },
  settingLabel: { fontSize: 14, fontWeight: "600" as const },
  settingDesc: { fontSize: 12, marginTop: 1 },
  commandsCard: { borderRadius: 14, borderWidth: 1, overflow: "hidden" },
  cmdItem: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
    padding: 12,
    borderBottomWidth: 1,
  },
  cmdCode: { paddingHorizontal: 10, paddingVertical: 4, borderRadius: 8 },
  cmdCodeText: { fontSize: 13, fontWeight: "700" as const },
  cmdDesc: { fontSize: 13, flex: 1 },
  dangerBtn: {
    flexDirection: "row",
    alignItems: "center",
    gap: 10,
    padding: 14,
    borderRadius: 12,
    borderWidth: 1,
  },
  dangerText: { fontSize: 14, fontWeight: "500" as const },
  aboutSection: { alignItems: "center", paddingBottom: 20, gap: 4 },
  aboutApp: { fontSize: 13 },
  aboutVersion: { fontSize: 11 },
});
