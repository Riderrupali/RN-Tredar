import 'package:flutter/material.dart';
  import 'package:image_picker/image_picker.dart';
  import 'dart:io';
  import '../services/database_service.dart';
  import '../services/tts_service.dart';
  import '../models/knowledge_model.dart';

  class KnowledgeScreen extends StatefulWidget {
    const KnowledgeScreen({super.key});
    @override
    State<KnowledgeScreen> createState() => _KnowledgeScreenState();
  }

  class _KnowledgeScreenState extends State<KnowledgeScreen> {
    final TtsService _tts = TtsService.instance;
    final _searchCtrl = TextEditingController();

    // Predefined trading topics
    static const List<String> _predefinedTopics = [
      'Support & Resistance',
      'Trend Analysis',
      'Use of Indicators',
      'Volume',
      'Types of Candlesticks',
      'RSI (Relative Strength Index)',
      'MACD',
      'Price Action',
      'Stop Loss & Target',
      'Option Trading',
    ];

    String? _selectedTopic;
    List<KnowledgeItem> _items = [];
    List<KnowledgeItem> _topicItems = [];

    @override
    void initState() {
      super.initState();
      _load();
    }

    @override
    void dispose() {
      _searchCtrl.dispose();
      super.dispose();
    }

    Future<void> _load([String query = '']) async {
      final items = query.isEmpty
          ? await DatabaseService.instance.getAllKnowledge()
          : await DatabaseService.instance.searchKnowledge(query);
      setState(() => _items = items);
    }

    Future<void> _loadTopic(String topic) async {
      final items = await DatabaseService.instance.searchKnowledge(topic);
      setState(() {
        _selectedTopic = topic;
        _topicItems = items;
      });
    }

    void _showAddDialog([String? prefillTopic]) {
      final topicCtrl = TextEditingController(text: prefillTopic ?? _selectedTopic ?? '');
      final contentCtrl = TextEditingController();
      String? imagePath;

      showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setS) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            title: const Text('माहिती Add करा 📚',
                style: TextStyle(color: Colors.white, fontSize: 16)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Topic निवडा:',
                      style: TextStyle(color: Color(0xFF3CE1C3), fontSize: 12)),
                  const SizedBox(height: 6),
                  // Topic dropdown
                  DropdownButtonFormField<String>(
                    value: _predefinedTopics.contains(topicCtrl.text) ? topicCtrl.text : null,
                    dropdownColor: const Color(0xFF0D0D1A),
                    style: const TextStyle(color: Colors.white),
                    hint: const Text('Topic select करा', style: TextStyle(color: Colors.white38)),
                    decoration: InputDecoration(
                      filled: true, fillColor: const Color(0xFF0D0D1A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _predefinedTopics.map((t) => DropdownMenuItem(value: t,
                        child: Text(t, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (v) { if (v != null) topicCtrl.text = v; },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: topicCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: _inputDeco('किंवा custom topic लिहा...'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: contentCtrl,
                    maxLines: 5,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: _inputDeco(
                      'माहिती लिहा...\nउदा: Support म्हणजे जो price खाली येतो तो एका level वर थांबतो'),
                  ),
                  const SizedBox(height: 10),
                  // Image attach
                  GestureDetector(
                    onTap: () async {
                      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                      if (picked != null) setS(() => imagePath = picked.path);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D0D1A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: imagePath != null ? const Color(0xFF3CE1C3) : Colors.white24),
                      ),
                      child: Row(children: [
                        Icon(Icons.image_outlined,
                            color: imagePath != null ? const Color(0xFF3CE1C3) : Colors.white38,
                            size: 18),
                        const SizedBox(width: 8),
                        Text(imagePath != null ? '✅ Image attached' : '📷 Image add करा (optional)',
                            style: TextStyle(
                                color: imagePath != null ? const Color(0xFF3CE1C3) : Colors.white38,
                                fontSize: 12)),
                      ]),
                    ),
                  ),
                  if (imagePath != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(imagePath!), height: 100, fit: BoxFit.cover,
                          width: double.infinity),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C3CE1)),
                onPressed: () async {
                  if (topicCtrl.text.isEmpty || contentCtrl.text.isEmpty) return;
                  await DatabaseService.instance.saveKnowledge(KnowledgeItem(
                    topic: topicCtrl.text,
                    content: contentCtrl.text,
                    appName: imagePath,
                    createdAt: DateTime.now(),
                  ));
                  Navigator.pop(ctx);
                  _load();
                  if (_selectedTopic != null) _loadTopic(_selectedTopic!);
                },
                child: const Text('Save', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    InputDecoration _inputDeco(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
      filled: true, fillColor: const Color(0xFF0D0D1A),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0D1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A2E),
          iconTheme: const IconThemeData(color: Colors.white),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🧠 Knowledge Base', style: TextStyle(color: Colors.white, fontSize: 17)),
              if (_selectedTopic != null)
                Text(_selectedTopic!, style: const TextStyle(color: Color(0xFF3CE1C3), fontSize: 11)),
            ],
          ),
          actions: [
            if (_selectedTopic != null)
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white54, size: 18),
                onPressed: () => setState(() { _selectedTopic = null; _topicItems = []; }),
              ),
            IconButton(
              icon: const Icon(Icons.add, color: Color(0xFF3CE1C3)),
              onPressed: () => _showAddDialog(),
            ),
          ],
        ),
        body: _selectedTopic == null ? _buildTopicList() : _buildTopicDetail(),
      );
    }

    // ── Topic overview ───────────────────────────────────
    Widget _buildTopicList() {
      return Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              onChanged: _load,
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
                        onPressed: () { _searchCtrl.clear(); _load(); })
                    : null,
                filled: true, fillColor: const Color(0xFF1A1A2E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ),
          // Predefined topics grid
          if (_searchCtrl.text.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(alignment: Alignment.centerLeft,
                child: Text('Trading Topics:', style: TextStyle(
                    color: Colors.white.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w600))),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _predefinedTopics.length,
                itemBuilder: (ctx, i) {
                  final topic = _predefinedTopics[i];
                  return GestureDetector(
                    onTap: () => _loadTopic(topic),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFF9B59F5).withOpacity(0.4)),
                      ),
                      child: Text(topic, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
          // All items
          Expanded(
            child: _items.isEmpty
                ? Center(child: Text(
                    _searchCtrl.text.isEmpty
                        ? 'माहिती नाही. + बटण दाबून add करा!'
                        : 'काही मिळालं नाही.',
                    style: const TextStyle(color: Colors.white38)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _items.length,
                    itemBuilder: (ctx, i) => _knowledgeCard(_items[i], i + 1),
                  ),
          ),
        ],
      );
    }

    // ── Topic detail with numbered info ─────────────────
    Widget _buildTopicDetail() {
      return Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF9B59F5).withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_stories, color: Color(0xFF9B59F5), size: 22),
                const SizedBox(width: 12),
                Expanded(child: Text(_selectedTopic!,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
                Text('${_topicItems.length} entries',
                    style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: _topicItems.isEmpty
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.add_circle_outline, color: Colors.white24, size: 48),
                    const SizedBox(height: 12),
                    Text('"${_selectedTopic!}" बद्दल माहिती नाही\n+ बटण दाबून add करा!',
                        style: const TextStyle(color: Colors.white38, fontSize: 13),
                        textAlign: TextAlign.center),
                  ]))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _topicItems.length,
                    itemBuilder: (ctx, i) => _numberedCard(_topicItems[i], i + 1),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showAddDialog(_selectedTopic),
                icon: const Icon(Icons.add, size: 18),
                label: Text('"${_selectedTopic!}" मध्ये माहिती add करा'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C3CE1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ],
      );
    }

    Widget _knowledgeCard(KnowledgeItem item, int num) {
      return GestureDetector(
        onTap: () => _loadTopic(item.topic),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF9B59F5).withOpacity(0.15)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28, height: 28,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF6C3CE1)),
                child: Center(child: Text('$num',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.topic, style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    item.content.length > 80 ? '${item.content.substring(0, 80)}...' : item.content,
                    style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
                  ),
                ],
              )),
              const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
            ],
          ),
        ),
      );
    }

    Widget _numberedCard(KnowledgeItem item, int num) {
      final hasImage = item.appName != null &&
          item.appName!.isNotEmpty &&
          File(item.appName!).existsSync();
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF3CE1C3).withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF3CE1C3), width: 1.5),
                ),
                child: Center(child: Text('$num',
                    style: const TextStyle(color: Color(0xFF3CE1C3), fontSize: 11, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(item.topic,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13))),
              IconButton(
                icon: const Icon(Icons.volume_up_outlined, color: Colors.white38, size: 18),
                padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                onPressed: () => _tts.speak(item.content),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white24, size: 18),
                padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                onPressed: () async {
                  if (item.id != null) {
                    await DatabaseService.instance.deleteKnowledge(item.id!);
                    if (_selectedTopic != null) _loadTopic(_selectedTopic!);
                    _load();
                  }
                },
              ),
            ]),
            const SizedBox(height: 8),
            Text(item.content,
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.6)),
            if (hasImage) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(item.appName!),
                    height: 150, width: double.infinity, fit: BoxFit.cover),
              ),
            ],
          ],
        ),
      );
    }
  }
  
