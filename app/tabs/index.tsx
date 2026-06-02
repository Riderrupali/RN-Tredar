import React, { useEffect, useState } from "react";
import { StyleSheet, Text, View, TouchableOpacity, Image, Alert, ScrollView } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import * as ImagePicker from "expo-image-picker";
import AsyncStorage from "@react-native-async-storage/async-storage";
import * as Haptics from "expo-haptics";
import { Feather } from "@expo/vector-icons";
import { useColors } from "@/hooks/useColors";

type AnalysisResult = {
  action: "BUY" | "SELL" | "WAIT";
  confidence: number;
  explanation: string;
};

type Stats = {
  total: number;
  right: number;
  wrong: number;
};

export default function TredarBiginScreen() {
  const colors = useColors();
  const insets = useSafeAreaInsets();

  const [imageUri, setImageUri] = useState<string | null>(null);
  const [result, setResult] = useState<AnalysisResult | null>(null);
  const [stats, setStats] = useState<Stats>({ total: 0, right: 0, wrong: 0 });

  useEffect(() => {
    (async () => {
      try {
        const stored = await AsyncStorage.getItem("tredar_stats");
        if (stored) {
          setStats(JSON.parse(stored));
        }
      } catch (e) {
        console.log("Stats load error", e);
      }
    })();
  }, []);

  const saveStats = async (s: Stats) => {
    try {
      setStats(s);
      await AsyncStorage.setItem("tredar_stats", JSON.stringify(s));
    } catch (e) {
      console.log("Stats save error", e);
    }
  };

  const pickImage = async () => {
    const permission = await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (!permission.granted) {
      Alert.alert("Permission", "Gallery access permission लागेल.");
      return;
    }

    const res = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ImagePicker.MediaTypeOptions.Images,
      quality: 1,
    });

    if (res.canceled) return;

    const uri = res.assets[0].uri;
    setImageUri(uri);
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    analyzeImage();
  };

  // आत्तासाठी image वर calculation न करता demo logic.
  // नंतर तू trading rules दिल्यास इथे खऱ्या rules लावू.
  const analyzeImage = () => {
    const actions: AnalysisResult["action"][] = ["BUY", "SELL", "WAIT"];
    const idx = Math.floor(Math.random() * actions.length);
    const action = actions[idx];
    const confidence = Math.floor(60 + Math.random() * 20); // 60–79 %

    let explanation = "";
    if (action === "BUY") {
      explanation =
        "Trend अंदाजे वरच्या बाजूला दिसत आहे. Buyers side strong असू शकतो. हा फक्त probability आहे, खात्री नाही. Real trading स्वतःच्या risk वर करा.";
    } else if (action === "SELL") {
      explanation =
        "Trend अंदाजे खालीच्या बाजूला दिसत आहे. Sellers side active असू शकतो. हा फक्त अंदाज आहे. नेहमी stop loss वापरा.";
    } else {
      explanation =
        "Chart मध्ये clear direction दिसत नाही. Sideways / unclear zone असू शकते. अशा वेळी थांबणं किंवा छोट्या position विचारात घ्या.";
    }

    const newResult: AnalysisResult = {
      action,
      confidence,
      explanation,
    };
    setResult(newResult);
  };

  const markFeedback = async (isRight: boolean) => {
    if (!result) return;
    Haptics.selectionAsync();
    const newStats: Stats = {
      total: stats.total + 1,
      right: stats.right + (isRight ? 1 : 0),
      wrong: stats.wrong + (!isRight ? 1 : 0),
    };
    await saveStats(newStats);
  };

  return (
    <View
      style={[
        styles.container,
        {
          backgroundColor: colors.background,
          paddingTop: insets.top + 12,
          paddingBottom: insets.bottom + 12,
        },
      ]}
    >
      <View style={styles.header}>
        <Text style={[styles.title, { color: colors.foreground }]}>Tredar Bigin</Text>
        <Text style={[styles.subtitle, { color: colors.mutedForeground }]}>
          Chart screenshot → BUY / SELL / WAIT suggestion
        </Text>
      </View>

      <ScrollView contentContainerStyle={{ paddingHorizontal: 20, paddingBottom: 20 }}>
        <TouchableOpacity
          style={[styles.pickButton, { backgroundColor: colors.primary }]}
          onPress={pickImage}
          activeOpacity={0.9}
        >
          <Feather name="image" size={18} color={colors.primaryForeground} />
          <Text
            style={[
              styles.pickButtonText,
              { color: colors.primaryForeground },
            ]}
          >
            Gallery मधून Chart निवडा
          </Text>
        </TouchableOpacity>

        {imageUri && (
          <View style={styles.imageBox}>
            <Image
              source={{ uri: imageUri }}
              style={styles.image}
              resizeMode="contain"
            />
          </View>
        )}

        {result && (
          <View
            style={[
              styles.resultBox,
              {
                backgroundColor: colors.card,
                borderColor:
                  result.action === "BUY"
                    ? "#22c55e"
                    : result.action === "SELL"
                    ? "#ef4444"
                    : colors.border,
              },
            ]}
          >
            <Text style={[styles.resultTitle, { color: colors.foreground }]}>
              Analysis Result
            </Text>
            <Text style={[styles.resultLine, { color: colors.foreground }]}>
              Action:{" "}
              <Text
                style={{
                  fontWeight: "700",
                  color:
                    result.action === "BUY"
                      ? "#22c55e"
                      : result.action === "SELL"
                      ? "#ef4444"
                      : colors.foreground,
                }}
              >
                {result.action}
              </Text>
            </Text>
            <Text style={[styles.resultLine, { color: colors.foreground }]}>
              Confidence:{" "}
              <Text style={{ fontWeight: "600" }}>{result.confidence}%</Text>
            </Text>
            <Text style={[styles.resultExplain, { color: colors.mutedForeground }]}>
              {result.explanation}
            </Text>
            <Text style={[styles.disclaimer, { color: colors.mutedForeground }]}>
              हे फक्त demo educational अंदाज आहे. हा कोणताही guaranteed सल्ला नाही.
              Real trading नेहमी स्वतःच्या risk वर करा.
            </Text>
          </View>
        )}

        {result && (
          <View style={styles.feedbackRow}>
            <TouchableOpacity
              style={[styles.feedbackBtn, { backgroundColor: "#22c55e" }]}
              onPress={() => markFeedback(true)}
            >
              <Feather name="thumbs-up" size={16} color="#020617" />
              <Text style={styles.feedbackText}>Answer Right</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.feedbackBtn, { backgroundColor: "#ef4444" }]}
              onPress={() => markFeedback(false)}
            >
              <Feather name="thumbs-down" size={16} color="#020617" />
              <Text style={styles.feedbackText}>Answer Wrong</Text>
            </TouchableOpacity>
          </View>
        )}

        <View
          style={[
            styles.statsBox,
            { backgroundColor: colors.card, borderColor: colors.border },
          ]}
        >
          <Text style={[styles.statsTitle, { color: colors.foreground }]}>
            History
          </Text>
          <Text style={[styles.statsText, { color: colors.mutedForeground }]}>
            Total: {stats.total} | Right: {stats.right} | Wrong: {stats.wrong}
          </Text>
        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  header: { paddingHorizontal: 20, marginBottom: 12 },
  title: { fontSize: 24, fontWeight: "700" as const },
  subtitle: { fontSize: 13, marginTop: 4 },
  pickButton: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: 8,
    paddingVertical: 12,
    borderRadius: 999,
    marginTop: 8,
    marginBottom: 12,
  },
  pickButtonText: { fontSize: 15, fontWeight: "600" as const },
  imageBox: {
    width: "100%",
    height: 230,
    borderRadius: 16,
    overflow: "hidden",
    marginTop: 4,
    marginBottom: 12,
  },
  image: { width: "100%", height: "100%" },
  resultBox: {
    borderRadius: 16,
    padding: 14,
    borderWidth: 1.5,
    marginTop: 4,
  },
  resultTitle: { fontSize: 16, fontWeight: "700" as const, marginBottom: 8 },
  resultLine: { fontSize: 14, marginBottom: 4 },
  resultExplain: { fontSize: 13, marginTop: 6 },
  disclaimer: { fontSize: 11, marginTop: 8 },
  feedbackRow: {
    flexDirection: "row",
    gap: 10,
    marginTop: 14,
  },
  feedbackBtn: {
    flex: 1,
    paddingVertical: 10,
    borderRadius: 999,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: 6,
  },
  feedbackText: {
    color: "#020617",
    fontWeight: "600" as const,
    fontSize: 13,
  },
  statsBox: {
    marginTop: 16,
    padding: 12,
    borderRadius: 14,
    borderWidth: 1,
  },
  statsTitle: { fontSize: 15, fontWeight: "700" as const, marginBottom: 4 },
  statsText: { fontSize: 13 },
});
