import React, { useEffect, useRef } from "react";
import { View, Text, StyleSheet, Animated } from "react-native";

type Props = {
  appName: string;
  onComplete: () => void;
};

export default function CandleLoader({ appName, onComplete }: Props) {
  const candles = [0.4, 0.7, 0.5, 0.9, 0.6, 0.8, 0.45, 0.75, 0.55, 0.85];
  const anims = useRef(candles.map(() => new Animated.Value(0))).current;
  const opacity = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    Animated.timing(opacity, {
      toValue: 1,
      duration: 400,
      useNativeDriver: true,
    }).start();

    const sequence = anims.map((anim, i) =>
      Animated.sequence([
        Animated.delay(i * 120),
        Animated.timing(anim, {
          toValue: 1,
          duration: 400,
          useNativeDriver: true,
        }),
      ])
    );

    Animated.stagger(80, sequence).start(() => {
      setTimeout(onComplete, 600);
    });
  }, []);

  return (
    <Animated.View style={[styles.container, { opacity }]}>
      <View style={styles.candlesRow}>
        {candles.map((height, i) => (
          <Animated.View
            key={i}
            style={[
              styles.candle,
              {
                height: height * 80,
                backgroundColor: i % 2 === 0 ? "#22C55E" : "#EF4444",
                opacity: anims[i],
                transform: [
                  {
                    scaleY: anims[i].interpolate({
                      inputRange: [0, 1],
                      outputRange: [0, 1],
                    }),
                  },
                ],
              },
            ]}
          />
        ))}
      </View>
      <Text style={styles.appName}>{appName}</Text>
      <Text style={styles.loadingText}>Trading suru hot aahe...</Text>
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#0A0E1A",
    justifyContent: "center",
    alignItems: "center",
    gap: 24,
  },
  candlesRow: {
    flexDirection: "row",
    alignItems: "flex-end",
    gap: 6,
    height: 100,
  },
  candle: {
    width: 18,
    borderRadius: 4,
  },
  appName: {
    color: "#F1F5F9",
    fontSize: 22,
    fontWeight: "700",
  },
  loadingText: {
    color: "#64748B",
    fontSize: 14,
  },
});
