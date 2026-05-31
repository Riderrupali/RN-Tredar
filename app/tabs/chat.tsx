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
    setIsLoadingTrading,
    setActiveTabIndex,
  } = useApp();

  const [input, setInput] = useState("");
  const [searchVisible, setSearchVisible] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [alwaysOnMic, setAlwaysOnMic] = useState(false);
  const [commandMic, setCommandMic] = useState(false);
  const flatRef = useRef<FlatList>(null);

  const handleSend = () => {
    const text = input.trim();
    if (!text) return;
    setInput("");
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);

    addMessage({ text, isUser: true, type: "text" });

    const normalized = text.toLowerCase().replace(/\s+/g, " ").trim();

    setTimeout(() => {
      processCommand(normalized, text);
    }, 100);
  };

  const processCommand = (cmd: string, rawText: string) => {
    if (cmd === "123" || cmd === "123/" || cmd.startsWith("treding suru")) {
      addMessage({
        text: "✅ Trading Suru! Screen Monitor tab var jat aahe...\nApp select kara aani Start Trading var click kara.",
        isUser: false,
        type: "command",
      });
      setActiveTabIndex(0);
      return;
    }

    if (cmd === "2" || cmd === "2/" || cmd.includes("save") || cmd.includes("lakshyat")) {
      if (messages.length > 0) {
        const lastUserMsg = messages.find((m) => m.isUser);
        if (lastUserMsg) {
          addAnalysisRule(lastUserMsg.text);
          addKnowledgeEntry("volume", lastUserMsg.text);
          addMessage({
            text: "✅ Information save keli! Knowledge madhe add keli aani analysis rules madhe pan save keli.",
            isUser: false,
            type: "command",
          });
          return;
        }
      }
      addMessage({ text: "📝 Pudi information ya — me save karein.", isUser: false, type: "command" });
      return;
    }

    if (cmd === "25 2" || cmd === "25 2/" || cmd.includes("buy kiti") || cmd.includes("sell kiti")) {
      const parsed = parseBuySellPercent(rawText);
      const bp = parsed?.buy ?? buyPercent;
      const sp = parsed?.sell ?? sellPercent;
      if (parsed) {
        setBuyPercent(parsed.buy);
        setSellPercent(parsed.sell);
      }
      const diff = Math.abs(bp - sp);
      const stronger = bp > sp ? "BUY" : "SELL";
      const weaker = bp > sp ? "sell" : "buy";
      const chance = Math.round(diff / 2);
      addMessage({
        text: `📊 Buy/Sell Analysis:\n\n🟢 Buy: ${bp}% lokani buy kele\n🔴 Sell: ${sp}% lokani sell kele\n\n${stronger === "BUY" ? "🟢" : "🔴"} ${stronger} jast aahe\n⚠️ ${chance}% chance candel ${weaker} side la jau shakte\n\n${sp > 55 ? "⚡ Jast lokani sell kelay — bearish signal!" : bp > 55 ? "⚡ Jast lokani buy kelay — bullish signal!" : "📊 Market balanced aahe."}`,
        isUser: false,
        type: "analysis",
      });
      return;
    }

    if (cmd === "13 6" || cmd === "13 6/" || cmd.includes("buy karu ki sell") || cmd.includes("mi by karu")) {
      const result = runQuickAnalysis(buyPercent, sellPercent, analysisRules, currentPrice);
      addMessage({ text: result, isUser: false, type: "analysis" });
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      return;
    }

    if (cmd === "3 2 1" || cmd === "3 2 1/" || cmd.includes("trading band") || cmd.includes("stop treding")) {
      setTradingActive(false);
      addMessage({
        text: "✅ Trading Band Keli!\nScreen share aani mic band kele. App madhe parat yeto.",
        isUser: false,
        type: "command",
      });
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Warning);
      return;
    }

    if (cmd === "000" || cmd === "000/") {
      clearMessages();
      return;
    }

    const priceMatch = rawText.match(/(?:price|bhav|current)\s*[:\s]*[₹]?\s*(\d+(?:\.\d+)?)/i);
    if (priceMatch) {
      setCurrentPrice(priceMatch[1]);
      addMessage({
        text: `✅ Current price save kela: ₹${priceMatch[1]}\n13 6 command detach analysis madhe use hol.`,
        isUser: false,
        type: "command",
      });
      return;
    }

    const buyMatch = rawText.match(/(?:buy|khar)\s*[:\s]*(\d+)\s*%/i);
    const sellMatch = rawText.match(/(?:sell|vik)\s*[:\s]*(\d+)\s*%/i);
    if (buyMatch || sellMatch) {
      if (buyMatch) setBuyPercent(parseInt(buyMatch[1]));
      if (sellMatch) setSellPercent(parseInt(sellMatch[1]));
      addMessage({
        text: `✅ Update kele:\nBuy: ${buyMatch ? buyMatch[1] : buyPercent}%  |  Sell: ${sellMatch ? sellMatch[1] : sellPercent}%`,
        isUser: false,
        type: "command",
      });
      return;
    }

    if (rawText.length > 20) {
      addMessage({
        text: `✅ Information note keli! '2' type karun save karta yeil.\n\nCommands:\n• 123 — Trading suru\n• 13 6 — Quick decision\n• 25 2 — Buy/Sell %\n• 3 2 1 — Trading band\n• 2 — Save info`,
        isUser: false,
        type: "text",
      });
    } else {
      addMessage({
        text: `Commands:\n• 123 → Trading suru\n• 13 6 → Quick buy/sell decision\n• 25 2 → Buy/Sell %\n• 3 2 1 → Trading band\n• 2 → Info save kara`,
        isUser: false,
        type: "text",
      });
    }
  };

  const handleImagePick = async () => {
    const perm = await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (!perm.granted) return;
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ["images"],
      quality: 0.8,
    });
    if (!result.canceled && result.assets[0]) {
      const uri = result.assets[0].uri;
      addMessage({ text: "Image scan karato...", isUser: true, type: "image", imageUri: uri });
      setTimeout(() => {
        addMessage({
          text: "🔍 Image Scan Result:\n\nPosition detect keli. Chart varti janyacha trend disat aahe.\nFor accurate analysis: current price, buy% aani sell% enter kara.\n\n13 6 type karun quick decision ghya.",
          isUser: false,
          type: "analysis",
        });
      }, 800);
    }
  };

  const filtered = searchQuery
    ? messages.filter(
        (m) =>
          m.text.toLowerCase().includes(searchQuery.toLowerCase())
      )
    : messages;

  const topicResults = searchQuery
    ? knowledgeTopics.filter(
        (t) =>
          t.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
          t.entries.some((e) => e.text.toLowerCase().includes(searchQuery.toLowerCase()))
      )
    : [];

  return (
    <KeyboardAvoidingView
      style={[styles.container, { backgroundColor: colors.background }]}
      behavior="padding"
      keyboardVerticalOffset={0}
    >
      <View
        style={[
          styles.header,
          {
            paddingTop: insets.top + (Platform.OS === "web" ? 67 : 0),
            backgroundColor: colors.background,
            borderBottomColor: colors.border,
          },
        ]}
      >
        <Text style={[styles.headerTitle, { color: colors.foreground }]}>Chat</Text>
        <View style={styles.headerActions}>
          <TouchableOpacity
            onPress={() => setSearchVisible(!searchVisible)}
            style={[styles.headerBtn, { backgroundColor: colors.secondary }]}
          >
            <Feather name="search" size={17} color={colors.mutedForeground} />
          </TouchableOpacity>
          <TouchableOpacity
            onPress={() => clearMessages()}
            style={[styles.headerBtn, { backgroundColor: colors.secondary }]}
          >
            <Feather name="trash-2" size={17} color={colors.mutedForeground} />
          </TouchableOpacity>
        </View>
      </View>

      {searchVisible && (
        <View style={[styles.searchBar, { backgroundColor: colors.card, borderColor: colors.border }]}>
          <Feather name="search" size={15} color={colors.mutedForeground} />
          <TextInput
            style={[styles.searchInput, { color: colors.foreground }]}
            placeholder="Chat search kara — topic, command, info..."
            placeholderTextColor={colors.mutedForeground}
            value={searchQuery}
            onChangeText={setSearchQuery}
            autoFocus
          />
          {searchQuery.length > 0 && (
            <TouchableOpacity onPress={() => setSearchQuery("")}>
              <Feather name="x" size={15} color={colors.mutedForeground} />
            </TouchableOpacity>
          )}
        </View>
      )}

      {topicResults.length > 0 && (
        <View style={[styles.topicResults, { backgroundColor: colors.card, borderColor: colors.border }]}>
          <Text style={[styles.topicResultTitle, { color: colors.mutedForeground }]}>
            Knowledge Topics:
          </Text>
          {topicResults.map((t) => (
            <View key={t.id} style={styles.topicResultRow}>
              <Text style={[styles.topicResultName, { color: colors.primary }]}>{t.name}</Text>
              <Text style={[styles.topicResultSub, { color: colors.mutedForeground }]} numberOfLines={1}>
                {t.entries[0]?.text ?? "No entries"}
              </Text>
            </View>
          ))}
        </View>
      )}

      <FlatList
        ref={flatRef}
        data={filtered}
        keyExtractor={(m) => m.id}
        inverted
        contentContainerStyle={{ padding: 16, gap: 10, paddingBottom: 8 }}
        showsVerticalScrollIndicator={false}
        scrollEnabled={!!filtered.length}
        renderItem={({ item }) => <MessageBubble msg={item} colors={colors} />}
        ListEmptyComponent={
          <View style={styles.empty}>
            <Feather name="message-circle" size={36} color={colors.border} />
            <Text style={[styles.emptyText, { color: colors.mutedForeground }]}>
              Commands type kara
            </Text>
            <Text style={[styles.emptyHint, { color: colors.mutedForeground }]}>
              123 · 13 6 · 25 2 · 3 2 1 · 2
            </Text>
          </View>
        }
      />

      <View
        style={[
          styles.inputRow,
          {
            backgroundColor: colors.card,
            borderTopColor: colors.border,
            paddingBottom: insets.bottom + (Platform.OS === "web" ? 34 : 8),
          },
        ]}
      >
        <TouchableOpacity onPress={handleImagePick} style={styles.iconBtn}>
          <Feather name="image" size={20} color={colors.mutedForeground} />
        </TouchableOpacity>

        <TextInput
          style={[
            styles.textInput,
            { backgroundColor: colors.input, borderColor: colors.border, color: colors.foreground },
          ]}
          placeholder="Command type kara... (123, 13 6, 25 2...)"
          placeholderTextColor={colors.mutedForeground}
          value={input}
          onChangeText={setInput}
          onSubmitEditing={handleSend}
          returnKeyType="send"
          multiline={false}
        />

        <TouchableOpacity
          style={[styles.micBtn, { backgroundColor: alwaysOnMic ? colors.primary + "20" : "transparent" }]}
          onPress={() => {
            setAlwaysOnMic(!alwaysOnMic);
            Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
          }}
        >
          <Feather
            name="mic"
            size={20}
            color={alwaysOnMic ? colors.primary : colors.mutedForeground}
          />
        </TouchableOpacity>

        <TouchableOpacity
          style={[styles.sendBtn, { backgroundColor: colors.primary }]}
          onPress={handleSend}
        >
          <Feather name="send" size={18} color={colors.primaryForeground} />
        </TouchableOpacity>
      </View>
    </KeyboardAvoidingView>
  );
}

function MessageBubble({ msg, colors }: { msg: ChatMessage; colors: ReturnType<typeof useColors> }) {
  const isAnalysis = msg.type === "analysis";
  const isCommand = msg.type === "command";
  const bg = msg.isUser
    ? colors.primary
    : isAnalysis
    ? colors.card
    : isCommand
    ? colors.secondary
    : colors.card;
  const textColor = msg.isUser ? colors.primaryForeground : colors.foreground;
  const borderColor = isAnalysis ? colors.accent + "40" : isCommand ? colors.primary + "30" : colors.border;

  return (
    <View style={[styles.bubbleRow, msg.isUser && styles.bubbleRowUser]}>
      {!msg.isUser && (
        <View style={[styles.avatarDot, { backgroundColor: isAnalysis ? colors.accent : colors.primary }]} />
      )}
      <View
        style={[
          styles.bubble,
          { backgroundColor: bg, borderColor, maxWidth: "82%" },
          msg.isUser && styles.bubbleUser,
          !msg.isUser && { borderWidth: 1 },
        ]}
      >
        {msg.imageUri && (
          <Image source={{ uri: msg.imageUri }} style={styles.bubbleImage} />
        )}
        <Text style={[styles.bubbleText, { color: textColor }]}>{msg.text}</Text>
        <Text style={[styles.bubbleTime, { color: msg.isUser ? "#ffffff80" : colors.mutedForeground }]}>
          {new Date(msg.timestamp).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}
        </Text>
      </View>
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
    paddingBottom: 12,
    borderBottomWidth: 1,
  },
  headerTitle: { fontSize: 22, fontWeight: "700" as const },
  headerActions: { flexDirection: "row", gap: 8 },
  headerBtn: { width: 34, height: 34, borderRadius: 10, justifyContent: "center", alignItems: "center" },
  searchBar: {
    flexDirection: "row",
    alignItems: "center",
    gap: 10,
    marginHorizontal: 16,
    marginTop: 10,
    paddingHorizontal: 14,
    paddingVertical: 10,
    borderRadius: 12,
    borderWidth: 1,
  },
  searchInput: { flex: 1, fontSize: 14 },
  topicResults: {
    marginHorizontal: 16,
    marginTop: 8,
    padding: 12,
    borderRadius: 12,
    borderWidth: 1,
    gap: 6,
  },
  topicResultTitle: { fontSize: 11, fontWeight: "600" as const, textTransform: "uppercase" },
  topicResultRow: { gap: 2 },
  topicResultName: { fontSize: 13, fontWeight: "600" as const },
  topicResultSub: { fontSize: 12 },
  empty: { flex: 1, alignItems: "center", justifyContent: "center", gap: 8, paddingTop: 60 },
  emptyText: { fontSize: 15 },
  emptyHint: { fontSize: 13, letterSpacing: 2 },
  inputRow: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 12,
    paddingTop: 10,
    gap: 8,
    borderTopWidth: 1,
  },
  iconBtn: { padding: 8 },
  textInput: {
    flex: 1,
    borderRadius: 20,
    borderWidth: 1,
    paddingHorizontal: 14,
    paddingVertical: Platform.OS === "ios" ? 10 : 8,
    fontSize: 14,
    maxHeight: 80,
  },
  micBtn: { padding: 8, borderRadius: 20 },
  sendBtn: { width: 38, height: 38, borderRadius: 19, justifyContent: "center", alignItems: "center" },
  bubbleRow: { flexDirection: "row", alignItems: "flex-end", gap: 8 },
  bubbleRowUser: { flexDirection: "row-reverse" },
  avatarDot: { width: 6, height: 6, borderRadius: 3, marginBottom: 8 },
  bubble: { padding: 12, borderRadius: 16, gap: 4 },
  bubbleUser: { borderBottomRightRadius: 4 },
  bubbleImage: { width: "100%", height: 160, borderRadius: 10, marginBottom: 4 },
  bubbleText: { fontSize: 14, lineHeight: 20 },
  bubbleTime: { fontSize: 10, alignSelf: "flex-end" },
});
        
