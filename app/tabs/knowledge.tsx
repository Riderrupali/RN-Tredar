import { Feather } from "@expo/vector-icons";
import * as Haptics from "expo-haptics";
import * as ImagePicker from "expo-image-picker";
import React, { useState } from "react";
import {
  Alert,
  FlatList,
  Image,
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
import { useApp } from "@/context/AppContext";
import { useColors } from "@/hooks/useColors";
import type { KnowledgeTopic } from "@/context/AppContext";

const ICON_MAP: Record<string, string> = {
  "trending-up": "trending-up",
  activity: "activity",
  "bar-chart-2": "bar-chart-2",
  layers: "layers",
  "git-commit": "git-commit",
  percent: "percent",
  cpu: "cpu",
};

export default function KnowledgeScreen() {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const { knowledgeTopics, addKnowledgeEntry, deleteKnowledgeEntry } = useApp();

  const [search, setSearch] = useState("");
  const [selectedTopic, setSelectedTopic] = useState<KnowledgeTopic | null>(null);
  const [addVisible, setAddVisible] = useState(false);
  const [newText, setNewText] = useState("");
  const [newImage, setNewImage] = useState<string | null>(null);

  const filtered = search
    ? knowledgeTopics.filter(
        (t) =>
          t.name.toLowerCase().includes(search.toLowerCase()) ||
          t.entries.some((e) => e.text.toLowerCase().includes(search.toLowerCase()))
      )
    : knowledgeTopics;

  const handleAddEntry = () => {
    if (!newText.trim() || !selectedTopic) return;
    addKnowledgeEntry(selectedTopic.id, newText.trim(), newImage ?? undefined);
    setNewText("");
    setNewImage(null);
    setAddVisible(false);
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    const updated = knowledgeTopics.find((t) => t.id === selectedTopic.id);
    if (updated) setSelectedTopic(updated);
  };

  const handlePickImage = async () => {
    const perm = await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (!perm.granted) return;
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ["images"],
      quality: 0.7,
    });
    if (!result.canceled) setNewImage(result.assets[0].uri);
  };

  return (
    <View
      style={[
        styles.container,
        {
          backgroundColor: colors.background,
          paddingTop: insets.top + (Platform.OS === "web" ? 67 : 0),
        },
      ]}
    >
      <View style={styles.header}>
        <View style={styles.headerLeft}>
          <Feather name="book-open" size={22} color={colors.accent} />
          <Text style={[styles.headerTitle, { color: colors.foreground }]}>Knowledge</Text>
        </View>
      </View>

      <View style={[styles.searchRow, { backgroundColor: colors.card, borderColor: colors.border }]}>
        <Feather name="search" size={15} color={colors.mutedForeground} />
        <TextInput
          style={[styles.searchInput, { color: colors.foreground }]}
          placeholder="Topic search kara..."
          placeholderTextColor={colors.mutedForeground}
          value={search}
          onChangeText={setSearch}
        />
        {search.length > 0 && (
          <TouchableOpacity onPress={() => setSearch("")}>
            <Feather name="x" size={15} color={colors.mutedForeground} />
          </TouchableOpacity>
        )}
      </View>

      <FlatList
        data={filtered}
        keyExtractor={(t) => t.id}
        contentContainerStyle={{ padding: 16, gap: 10, paddingBottom: insets.bottom + 40 }}
        showsVerticalScrollIndicator={false}
        renderItem={({ item }) => (
          <TopicCard
            topic={item}
            colors={colors}
            onPress={() => setSelectedTopic(item)}
          />
        )}
        ListEmptyComponent={
          <View style={styles.empty}>
            <Feather name="book-open" size={32} color={colors.border} />
            <Text style={[styles.emptyText, { color: colors.mutedForeground }]}>
              Kahi milale nahi
            </Text>
          </View>
        }
      />

      <Modal visible={!!selectedTopic} animationType="slide" transparent>
        <View style={styles.modalOverlay}>
          <View style={[styles.detailSheet, { backgroundColor: colors.card }]}>
            <View style={styles.detailHeader}>
              <TouchableOpacity onPress={() => setSelectedTopic(null)}>
                <Feather name="arrow-left" size={20} color={colors.foreground} />
              </TouchableOpacity>
              <Text style={[styles.detailTitle, { color: colors.foreground }]}>
                {selectedTopic?.name}
              </Text>
              <TouchableOpacity
                onPress={() => setAddVisible(true)}
                style={[styles.addBtn, { backgroundColor: colors.primary }]}
              >
                <Feather name="plus" size={16} color={colors.primaryForeground} />
              </TouchableOpacity>
            </View>

            <FlatList
              data={selectedTopic?.entries ?? []}
              keyExtractor={(e) => e.id}
              contentContainerStyle={{ padding: 16, gap: 12 }}
              showsVerticalScrollIndicator={false}
              renderItem={({ item }) => (
                <View style={[styles.entryCard, { backgroundColor: colors.background, borderColor: colors.border }]}>
                  {item.imageUri && (
                    <Image source={{ uri: item.imageUri }} style={styles.entryImage} />
                  )}
                  <Text style={[styles.entryText, { color: colors.foreground }]}>
                    {item.text}
                  </Text>
                  <View style={styles.entryFooter}>
                    <Text style={[styles.entryTime, { color: colors.mutedForeground }]}>
                      {new Date(item.timestamp).toLocaleDateString()}
                    </Text>
                    <TouchableOpacity
                      onPress={() => {
                        Alert.alert("Delete?", "He entry delete karaychi ka?", [
                          { text: "Cancel", style: "cancel" },
                          {
                            text: "Delete",
                            style: "destructive",
                            onPress: () => {
                              if (selectedTopic) {
                                deleteKnowledgeEntry(selectedTopic.id, item.id);
                                setSelectedTopic((prev) =>
                                  prev
                                    ? { ...prev, entries: prev.entries.filter((e) => e.id !== item.id) }
                                    : null
                                );
                              }
                            },
                          },
                        ]);
                      }}
                    >
                      <Feather name="trash-2" size={14} color={colors.destructive} />
                    </TouchableOpacity>
                  </View>
                </View>
              )}
              ListEmptyComponent={
                <View style={styles.empty}>
                  <Text style={[styles.emptyText, { color: colors.mutedForeground }]}>
                    Abhi kahi nahi — + press kara add karayla
                  </Text>
                </View>
              }
            />
          </View>
        </View>
      </Modal>

      <Modal visible={addVisible} transparent animationType="fade">
        <View style={styles.modalOverlay}>
          <View style={[styles.addSheet, { backgroundColor: colors.card }]}>
            <Text style={[styles.addTitle, { color: colors.foreground }]}>
              {selectedTopic?.name} — Navin Entry
            </Text>
            <TextInput
              style={[styles.addInput, { backgroundColor: colors.input, borderColor: colors.border, color: colors.foreground }]}
              placeholder="Information taka (rules, analysis, notes...)"
              placeholderTextColor={colors.mutedForeground}
              value={newText}
              onChangeText={setNewText}
              multiline
              numberOfLines={4}
              textAlignVertical="top"
            />
            <TouchableOpacity
              style={[styles.imagePickBtn, { borderColor: colors.border }]}
              onPress={handlePickImage}
            >
              {newImage ? (
                <Image source={{ uri: newImage }} style={styles.pickedImage} />
              ) : (
                <>
                  <Feather name="image" size={16} color={colors.mutedForeground} />
                  <Text style={{ color: colors.mutedForeground, fontSize: 13 }}>
                    Image add kara (optional)
                  </Text>
                </>
              )}
            </TouchableOpacity>
            <View style={styles.addActions}>
              <TouchableOpacity
                style={[styles.cancelBtn, { borderColor: colors.border }]}
                onPress={() => { setAddVisible(false); setNewText(""); setNewImage(null); }}
              >
                <Text style={{ color: colors.mutedForeground }}>Cancel</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.saveBtn, { backgroundColor: colors.primary }]}
                onPress={handleAddEntry}
              >
                <Text style={{ color: colors.primaryForeground, fontWeight: "700" as const }}>Save</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>
    </View>
  );
}

function TopicCard({ topic, colors, onPress }: { topic: KnowledgeTopic; colors: ReturnType<typeof useColors>; onPress: () => void }) {
  return (
    <TouchableOpacity
      style={[styles.topicCard, { backgroundColor: colors.card, borderColor: colors.border }]}
      onPress={onPress}
      activeOpacity={0.8}
    >
      <View style={[styles.topicIcon, { backgroundColor: colors.secondary }]}>
        <Feather
          name={(ICON_MAP[topic.icon] as any) ?? "book-open"}
          size={20}
          color={colors.accent}
        />
      </View>
      <View style={styles.topicInfo}>
        <Text style={[styles.topicName, { color: colors.foreground }]}>{topic.name}</Text>
        <Text style={[styles.topicCount, { color: colors.mutedForeground }]}>
          {topic.entries.length} {topic.entries.length === 1 ? "entry" : "entries"}
        </Text>
      </View>
      <Feather name="chevron-right" size={18} color={colors.mutedForeground} />
    </TouchableOpacity>
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
  headerLeft: { flexDirection: "row", alignItems: "center", gap: 10 },
  headerTitle: { fontSize: 22, fontWeight: "700" as const },
  searchRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 10,
    marginHorizontal: 16,
    paddingHorizontal: 14,
    paddingVertical: 10,
    borderRadius: 12,
    borderWidth: 1,
    marginBottom: 4,
  },
  searchInput: { flex: 1, fontSize: 14 },
  topicCard: {
    flexDirection: "row",
    alignItems: "center",
    gap: 14,
    padding: 14,
    borderRadius: 14,
    borderWidth: 1,
  },
  topicIcon: {
    width: 44,
    height: 44,
    borderRadius: 12,
    justifyContent: "center",
    alignItems: "center",
  },
  topicInfo: { flex: 1 },
  topicName: { fontSize: 15, fontWeight: "600" as const },
  topicCount: { fontSize: 12, marginTop: 2 },
  empty: { alignItems: "center", justifyContent: "center", paddingTop: 40, gap: 8 },
  emptyText: { fontSize: 14, textAlign: "center" },
  modalOverlay: { flex: 1, backgroundColor: "rgba(0,0,0,0.7)" },
  detailSheet: { flex: 1, marginTop: 60, borderTopLeftRadius: 24, borderTopRightRadius: 24 },
  detailHeader: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
    padding: 20,
  },
  detailTitle: { flex: 1, fontSize: 18, fontWeight: "700" as const },
  addBtn: {
    width: 34,
    height: 34,
    borderRadius: 10,
    justifyContent: "center",
    alignItems: "center",
  },
  entryCard: {
    padding: 14,
    borderRadius: 14,
    borderWidth: 1,
    gap: 8,
  },
  entryImage: { width: "100%", height: 140, borderRadius: 10 },
  entryText: { fontSize: 14, lineHeight: 22 },
  entryFooter: { flexDirection: "row", justifyContent: "space-between", alignItems: "center" },
  entryTime: { fontSize: 11 },
  addSheet: { margin: 20, marginTop: 100, borderRadius: 20, padding: 20, gap: 12 },
  addTitle: { fontSize: 16, fontWeight: "700" as const },
  addInput: { borderRadius: 12, borderWidth: 1, padding: 12, fontSize: 14, minHeight: 100 },
  imagePickBtn: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
    borderWidth: 1,
    borderStyle: "dashed",
    borderRadius: 12,
    padding: 12,
    justifyContent: "center",
  },
  pickedImage: { width: "100%", height: 120, borderRadius: 10 },
  addActions: { flexDirection: "row", gap: 10 },
  cancelBtn: {
    flex: 1,
    padding: 12,
    borderRadius: 12,
    borderWidth: 1,
    alignItems: "center",
  },
  saveBtn: {
    flex: 1,
    padding: 12,
    borderRadius: 12,
    alignItems: "center",
  },
});
