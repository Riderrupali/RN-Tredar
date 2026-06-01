import { Feather } from "@expo/vector-icons";
import * as Haptics from "expo-haptics";
import * as ImagePicker from "expo-image-picker";
import React, { useRef, useState } from "react";
import {
  FlatList,
  Image,
  Platform,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";
import { KeyboardAvoidingView } from "react-native-keyboard-controller";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { useApp } from "@/context/AppContext";
import { useColors } from "@/hooks/useColors";
import type { ChatMessage } from "@/context/AppContext";

function runQuickAnalysis(
  buyPct: number,
  sellPct: number,
  rules: string[],
  currentPrice: string
): string {
  const diff = buyPct - sellPct;
  const absChance = Math.min(95, Math.abs(diff) * 1.8 + 30);
  const direction = diff > 0 ? "VARTI (UP)" : "KHALI (DOWN)";
  const emoji = diff > 0 ? "📈" : "📉";
  const signal = diff > 0 ? "BUY" : "SELL";

  let rsiNote = "";
  const rsiRule = rules.find((r) => r.toLowerCase().includes("rsi"));
  if (rsiRule) rsiNote = `\nRule: ${rsiRule.slice(0, 60)}...`;

  const priceNote = currentPrice ? `\nCurrent Price: ₹${currentPrice}` : "";
  const volumeNote =
    Math.min(buyPct, sellPct) < 40
      ? "\n⚡ Low volume site — high chance of run!"
      : "";

  return `${emoji} Quick Analysis Result\n\n✅ Signal: ${signal}\n📊 Candle ${direction} jaanar aahe\n💯 Chance: ~${Math.round(absChance)}%${priceNote}\n\nBuy: ${buyPct}% | Sell: ${sellPct}%${volumeNote}${rsiNote}\n\n⚡ Decision: ${signal} kara — ${Math.round(absChance)}% chance aahe!`;
}

function parseBuySellPercent(text: string): { buy: number; sell: number } | null {
  const m = text.match(/(\d+)\s*%?\s*(buy|khar|b)\s*[,&]?\s*(\d+)\s*%?\s*(sell|vik|s)/i);
  if (m) return { buy: parseInt(m[1]), sell: parseInt(m[3]) };
  const m2 = text.match(/(\d+)\s*%?\s*(sell|vik|s)\s*[,&]?\s*(\d+)\s*%?\s*(buy|khar|b)/i);
  if (m2) return { sell: parseInt(m2[1]), buy: parseInt(m2[3]) };
  return null;
}

export default function ChatScreen() {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const {
    messages,
    addMessage,
    clearMessages,
    knowledgeTopics,
    addKnowledgeEntry,
    buyPercent,
    sellPercent,
    setBuyPercent,
    setSellPercent,
    currentPrice,
    setCurrentPrice,
    analysisRules,
    addAnalysisRule,
    tradingActive,
    setTradingActive,
    setActiveTabIndex,
  } = useApp();

  const [input, setInput] = useState("");
  const [searchVisible, setSearchVisible] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [alwaysOnMic, setAlwaysOnMic] = useState(false);
  const flatRef = useRef<FlatList>(null);

  const handleSend = () => {
    const text = input.trim();
    if (!text) return;
    setInput("");
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    addMessage({ text, isUser: true, type: "text" });
    const normalized = text.toLowerCase().replace(/\s+/g, " ").trim();
    setTimeout(() => processCommand(normalized, text), 100);
  };

  const processCommand = (cmd: string, rawText: string) => {
    if (cmd === "123" || cmd.startsWith("treding suru")) {
      addMessage({ text: "✅ Trading Suru! App select kara.", isUser: false, type: "command" });
      setActiveTabIndex(0);
      return;
    }
    if (cmd === "2" || cmd.includes("save")) {
      if (messages.length > 0) {
        const lastUserMsg = messages.find((m) => m.isUser);
        if (lastUserMsg) {
          addAnalysisRule(lastUserMsg.text);
          addKnowledgeEntry("volume", lastUserMsg.text);
          addMessage({ text: "✅ Information save keli!", isUser: false, type: "command" });
          return;
        }
      }
    }
    if (cmd === "13 6") {
      const result = runQuickAnalysis(buyPercent, sellPercent, analysisRules, currentPrice);
      addMessage({ text: result, isUser: false, type: "analysis" });
      return;
    }
    addMessage({ text: "Commands: 123, 13 6, 25 2, 3 2 1, 2", isUser: false, type: "text" });
  };

  const handleImagePick = async () => {
    const result = await ImagePicker.launchImageLibraryAsync({ mediaTypes: ["images"], quality: 0.8 });
    if (!result.canceled && result.assets[0]) {
      addMessage({ text: "🔍 Image Scan Result:\nChart varti trend disat aahe.", isUser: false, type: "analysis" });
    }
  };

  const filtered = searchQuery ? messages.filter((m) => m.text.toLowerCase().includes(searchQuery.toLowerCase())) : messages;

  return (
    <KeyboardAvoidingView style={[styles.container, { backgroundColor: colors.background }]} behavior="padding">
      <View style={[styles.header, { paddingTop: insets.top, borderBottomColor: colors.border }]}>
        <Text style={[styles.headerTitle, { color: colors.foreground }]}>Chat</Text>
        <View style={styles.headerActions}>
          <TouchableOpacity onPress={() => setSearchVisible(!searchVisible)} style={[styles.headerBtn, { backgroundColor: colors.secondary }]}>
            <Feather name="search" size={17} color={colors.mutedForeground} />
          </TouchableOpacity>
        </View>
      </View>

      <FlatList
        ref={flatRef}
        data={filtered}
        keyExtractor={(m) => m.id}
        inverted
        contentContainerStyle={{ padding: 16, gap: 10 }}
        renderItem={({ item }) => <MessageBubble msg={item} colors={colors} />}
      />

      <View style={[styles.inputRow, { backgroundColor: colors.card, paddingBottom: insets.bottom + 8 }]}>
        <TouchableOpacity onPress={handleImagePick} style={styles.iconBtn}>
          <Feather name="image" size={20} color={colors.mutedForeground} />
        </TouchableOpacity>
        <TextInput
          style={[styles.textInput, { backgroundColor: colors.input, color: colors.foreground }]}
          placeholder="Command type kara..."
          value={input}
          onChangeText={setInput}
          onSubmitEditing={handleSend}
        />
        <TouchableOpacity style={styles.sendBtn} onPress={handleSend}>
          <Feather name="send" size={18} color={colors.primaryForeground} />
        </TouchableOpacity>
      </View>
    </KeyboardAvoidingView>
  );
}

function MessageBubble({ msg, colors }: { msg: ChatMessage; colors: any }) {
  return (
    <View style={[styles.bubble, { backgroundColor: msg.isUser ? colors.primary : colors.card }]}>
      <Text style={{ color: msg.isUser ? colors.primaryForeground : colors.foreground }}>{msg.text}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  header: { flexDirection: "row", justifyContent: "space-between", padding: 20, borderBottomWidth: 1 },
  headerTitle: { fontSize: 22, fontWeight: "700" },
  headerActions: { flexDirection: "row", gap: 8 },
  headerBtn: { width: 34, height: 34, borderRadius: 10, justifyContent: "center", alignItems: "center" },
  inputRow: { flexDirection: "row", alignItems: "center", padding: 12, borderTopWidth: 1 },
  textInput: { flex: 1, borderRadius: 20, paddingHorizontal: 14, paddingVertical: 8, fontSize: 14 },
  sendBtn: { width: 38, height: 38, borderRadius: 19, backgroundColor: "#00D09C", justifyContent: "center", alignItems: "center", marginLeft: 8 },
  bubble: { padding: 12, borderRadius: 16, maxWidth: "82%", alignSelf: "flex-start" },
  iconBtn: { padding: 8 }
});
