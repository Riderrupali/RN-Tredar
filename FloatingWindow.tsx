import { Feather } from "@expo/vector-icons";
import React, { useRef, useState } from "react";
import {
  Animated,
  PanResponder,
  Platform,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";
import { useApp } from "@/context/AppContext";

export default function FloatingWindow() {
  const { tradingActive, screenShareActive, setScreenShareActive, micActive, setMicActive, setTradingActive } =
    useApp();
  const pan = useRef(new Animated.ValueXY({ x: 20, y: 100 })).current;
  const [collapsed, setCollapsed] = useState(false);

  const panResponder = useRef(
    PanResponder.create({
      onStartShouldSetPanResponder: () => true,
      onPanResponderGrant: () => {
        pan.setOffset({ x: (pan.x as any)._value, y: (pan.y as any)._value });
      },
      onPanResponderMove: Animated.event([null, { dx: pan.x, dy: pan.y }], {
        useNativeDriver: false,
      }),
      onPanResponderRelease: () => {
        pan.flattenOffset();
      },
    })
  ).current;

  if (!tradingActive) return null;

  return (
    <Animated.View
      style={[styles.container, { transform: pan.getTranslateTransform() }]}
      {...panResponder.panHandlers}
    >
      <View style={styles.handle}>
        <View style={styles.dot} />
        <View style={styles.dot} />
        <View style={styles.dot} />
      </View>

      {!collapsed && (
        <>
          <TouchableOpacity
            style={[styles.btn, screenShareActive && styles.btnActive]}
            onPress={() => setScreenShareActive(!screenShareActive)}
          >
            <Feather
              name="cast"
              size={16}
              color={screenShareActive ? "#0A0E1A" : "#00D09C"}
            />
            <Text
              style={[styles.btnText, screenShareActive && styles.btnTextActive]}
            >
              {screenShareActive ? "Share ON" : "Share OFF"}
            </Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.btn, micActive && styles.btnMicActive]}
            onPress={() => setMicActive(!micActive)}
          >
            <Feather
              name={micActive ? "mic" : "mic-off"}
              size={16}
              color={micActive ? "#0A0E1A" : "#F0B90B"}
            />
            <Text
              style={[styles.btnText, micActive && styles.btnTextMicActive]}
            >
              {micActive ? "Mic ON" : "Mic OFF"}
            </Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.stopBtn}
            onPress={() => {
              setTradingActive(false);
              setScreenShareActive(false);
              setMicActive(false);
            }}
          >
            <Feather name="x" size={14} color="#E74C3C" />
            <Text style={styles.stopText}>Stop</Text>
          </TouchableOpacity>
        </>
      )}

      <TouchableOpacity
        style={styles.collapseBtn}
        onPress={() => setCollapsed(!collapsed)}
      >
        <Feather
          name={collapsed ? "chevron-down" : "chevron-up"}
          size={12}
          color="#6B7A8E"
        />
      </TouchableOpacity>
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  container: {
    position: "absolute",
    right: 16,
    top: Platform.OS === "web" ? 100 : 120,
    backgroundColor: "#FFFFFF",
    borderRadius: 16,
    padding: 12,
    gap: 8,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 10,
    zIndex: 9999,
    minWidth: 110,
    alignItems: "center",
  },
  handle: {
    flexDirection: "row",
    gap: 3,
    marginBottom: 4,
  },
  dot: {
    width: 4,
    height: 4,
    borderRadius: 2,
    backgroundColor: "#C8C8C8",
  },
  btn: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    paddingHorizontal: 10,
    paddingVertical: 7,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: "#00D09C",
    width: "100%",
  },
  btnActive: {
    backgroundColor: "#00D09C",
  },
  btnText: {
    fontSize: 11,
    fontWeight: "600" as const,
    color: "#00D09C",
  },
  btnTextActive: {
    color: "#0A0E1A",
  },
  btnMicActive: {
    backgroundColor: "#F0B90B",
    borderColor: "#F0B90B",
  },
  btnTextMicActive: {
    color: "#0A0E1A",
  },
  stopBtn: {
    flexDirection: "row",
    alignItems: "center",
    gap: 4,
    paddingHorizontal: 10,
    paddingVertical: 6,
    width: "100%",
  },
  stopText: {
    fontSize: 11,
    color: "#E74C3C",
    fontWeight: "600" as const,
  },
  collapseBtn: {
    paddingTop: 2,
  },
});
