import React, { useEffect, useRef } from "react";
import { Animated, StyleSheet, Text, View } from "react-native";

interface Props {
  onComplete: () => void;
  appName: string;
}

export default function CandleLoader({ onComplete, appName }: Props) {
  const progress = useRef(new Animated.Value(0)).current;
  const candles = Array.from({ length: 8 }, (_, i) => ({
    anim: useRef(new Animated.Value(0.3 + Math.random() * 0.7)).current,
    isGreen: Math.random() > 0.4,
    delay: i * 120,
  }));

  useEffect(() => {
    Animated.timing(progress, {
      toValue: 1,
      duration: 20000,
      useNativeDriver: false,
    }).start(() => onComplete());

    candles.forEach((c) => {
      const loop = () => {
        Animated.sequence([
          Animated.timing(c.anim, {
            toValue: 0.2 + Math.random() * 0.8,
            duration: 400 + Math.random() * 600,
            useNativeDriver: false,
          }),
          Animated.timing(c.anim, {
            toValue: 0.3 + Math.random() * 0.7,
            duration: 400 + Math.random() * 400,
            useNativeDriver: false,
          }),
        ]).start(() => loop());
      };
      setTimeout(() => loop(), c.delay);
    });
  }, []);

  const barWidth = progress.interpolate({
    inputRange: [0, 1],
    outputRange: ["0%", "100%"],
  });

  const seconds = useRef(new Animated.Value(20)).current;
  const secondsDisplay = useRef(20);
  useEffect(() => {
    const timer = setInterval(() => {
      secondsDisplay.current -= 1;
      if (secondsDisplay.current <= 0) clearInterval(timer);
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  return (
    <View style={styles.container}>
      <View style={styles.content}>
        <Text style={styles.title}>Trading System Initializing</Text>
        <Text style={styles.subtitle}>{appName}</Text>

        <View style={styles.candleChart}>
          {candles.map((c, i) => (
            <View key={i} style={styles.candleWrapper}>
              <Animated.View
                style={[
                  styles.wick,
                  { backgroundColor: c.isGreen ? "#00D09C" : "#E74C3C" },
                ]}
              />
              <Animated.View
                style={[
                  styles.candle,
                  {
                    backgroundColor: c.isGreen ? "#00D09C" : "#E74C3C",
                    height: c.anim.interpolate({
                      inputRange: [0, 1],
                      outputRange: [20, 90],
                    }),
                    opacity: 0.85,
                  },
                ]}
              />
              <Animated.View
                style={[
                  styles.wick,
                  { backgroundColor: c.isGreen ? "#00D09C" : "#E74C3C" },
                ]}
              />
            </View>
          ))}
        </View>

        <View style={styles.progressContainer}>
          <Animated.View style={[styles.progressBar, { width: barWidth }]} />
        </View>

        <View style={styles.statusList}>
          {[
            "Loading market data...",
            "Connecting to " + appName,
            "Analyzing chart patterns...",
            "Initializing RSI & MACD...",
            "Preparing quick analysis...",
          ].map((s, i) => (
            <View key={i} style={styles.statusRow}>
              <View style={styles.statusDot} />
              <Text style={styles.statusText}>{s}</Text>
            </View>
          ))}
        </View>

        <Text style={styles.hint}>Trading analysis ready in ~20 seconds</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#0A0E1A",
    justifyContent: "center",
    alignItems: "center",
  },
  content: {
    width: "88%",
    alignItems: "center",
    gap: 20,
  },
  title: {
    fontSize: 22,
    fontWeight: "700" as const,
    color: "#E8EAF0",
    textAlign: "center",
  },
  subtitle: {
    fontSize: 15,
    color: "#00D09C",
    fontWeight: "600" as const,
  },
  candleChart: {
    flexDirection: "row",
    alignItems: "flex-end",
    height: 120,
    gap: 8,
    padding: 16,
    backgroundColor: "#131926",
    borderRadius: 16,
    width: "100%",
    justifyContent: "center",
  },
  candleWrapper: {
    alignItems: "center",
    gap: 2,
    flex: 1,
  },
  candle: {
    width: 14,
    borderRadius: 3,
    minHeight: 20,
  },
  wick: {
    width: 2,
    height: 10,
    borderRadius: 1,
  },
  progressContainer: {
    width: "100%",
    height: 6,
    backgroundColor: "#1E2A3A",
    borderRadius: 3,
    overflow: "hidden",
  },
  progressBar: {
    height: "100%",
    backgroundColor: "#00D09C",
    borderRadius: 3,
  },
  statusList: {
    width: "100%",
    gap: 10,
  },
  statusRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 10,
  },
  statusDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
    backgroundColor: "#00D09C",
  },
  statusText: {
    fontSize: 13,
    color: "#6B7A8E",
  },
  hint: {
    fontSize: 12,
    color: "#6B7A8E",
    marginTop: 8,
  },
});
