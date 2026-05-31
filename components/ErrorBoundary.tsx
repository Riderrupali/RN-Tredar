import React from "react";
import { View, Text, StyleSheet, ScrollView, TouchableOpacity } from "react-native";

type Props = {
  children: React.ReactNode;
};

type State = {
  hasError: boolean;
  error: string;
};

export class ErrorBoundary extends React.Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false, error: "" };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error: error.message + "\n" + error.stack };
  }

  componentDidCatch(error: Error, info: React.ErrorInfo) {
    console.error("=== APP CRASH ===");
    console.error("Error:", error.message);
    console.error("Stack:", error.stack);
    console.error("Component Stack:", info.componentStack);
  }

  render() {
    if (this.state.hasError) {
      return (
        <View style={styles.container}>
          <Text style={styles.title}>App Error</Text>
          <Text style={styles.subtitle}>खालील error expo logs मध्ये बघा:</Text>
          <ScrollView style={styles.scroll}>
            <Text style={styles.errorText}>{this.state.error}</Text>
          </ScrollView>
          <TouchableOpacity
            style={styles.button}
            onPress={() => this.setState({ hasError: false, error: "" })}
          >
            <Text style={styles.buttonText}>Retry</Text>
          </TouchableOpacity>
        </View>
      );
    }
    return this.props.children;
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#0A0E1A",
    padding: 20,
    justifyContent: "center",
  },
  title: {
    color: "#FF4444",
    fontSize: 22,
    fontWeight: "bold",
    marginBottom: 8,
  },
  subtitle: {
    color: "#AAAAAA",
    fontSize: 14,
    marginBottom: 12,
  },
  scroll: {
    maxHeight: 400,
    backgroundColor: "#1A1E2E",
    borderRadius: 8,
    padding: 12,
    marginBottom: 16,
  },
  errorText: {
    color: "#FF8888",
    fontSize: 11,
    fontFamily: "monospace",
  },
  button: {
    backgroundColor: "#2A6EFF",
    padding: 14,
    borderRadius: 8,
    alignItems: "center",
  },
  buttonText: {
    color: "white",
    fontWeight: "bold",
    fontSize: 16,
  },
});
