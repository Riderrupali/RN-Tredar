import 'package:flutter/material.dart';
  import 'package:file_picker/file_picker.dart';
  import 'package:image_picker/image_picker.dart';
  import 'dart:io';
  import '../services/ai_service.dart';
  import '../services/tts_service.dart';
  import '../services/stt_service.dart';
  import '../services/database_service.dart';
  import '../services/trading_commands_service.dart';
  import '../models/knowledge_model.dart';
  import '../widgets/chat_bubble.dart';
  import 'screen_monitor_screen.dart';

  class ChatScreen extends StatefulWidget {
    final String? initialMessage;
    const ChatScreen({super.key, this.initialMessage});
    @override
    State<ChatScreen> createState() => _ChatScreenState();
  }

  class _ChatScreenState extends State<ChatScreen> {
    final TextEditingController _ctrl = TextEditingController();
    final ScrollController _scroll = ScrollController();
    final AiService _ai = AiService.instance;
    final TtsService _tts = TtsService.instance;
    final SttService _stt = SttService.instance;
    final TradingCommandsService _cmd = TradingCommandsService.instance;

    List<ChatMessage> _messages = [];
    bool _isProcessing = false;
    bool _awaitingSave = false;
    String _pendingSaveTopic = '';

    // Knowledge topic search
    bool _showTopicSearch = false;
    List<KnowledgeItem> _topicResults = [];
    final TextEditingController _topicSearchCtrl = TextEditingController();

    String get _lang {
      switch (_tts.language) {
        case AppLanguage.hindi: return 'hindi';
        case AppLanguage.marathi: return 'marathi';
        default: return 'english';
      }
    }

    @override
    void initState() {
      super.initState();
      _loadHistory();
      if (widget.initialMessage != null) {
        Future.delayed(const Duration(milliseconds: 300),
            () => _processInput(widget.initialMessage!));
      }
    }

    @override
    void dispose() {
      _ctrl.dispose();
      _scroll.dispose();
      _topicSearchCtrl.dispose();
      super.dispose();
    }

    Future<void> _loadHistory() async {
      final msgs = await DatabaseService.instance.getRecentChats();
      setState(() => _messages = msgs);
      _scrollToBottom();
    }

    // ── Topic search ────────────────────────────────────
    Future<void> _searchTopic(String query) async {
      if (query.trim().isEmpty) {
        setState(() => _topicResults = []);
        return;
      }
      final results = await DatabaseService.instance.searchKnowledge(query);
      setState(() => _topicResults = results);
    }

    void _insertTopicResult(KnowledgeItem item) {
      final text = '🧠 ${item.topic}\n\n${item.content}';
      setState(() {
        _messages.add(ChatMessage(text: text, isUser: false, createdAt: DateTime.now()));
        _showTopicSearch = false;
        _topicResults = [];
        _topicSearchCtrl.clear();
      });
      _scrollToBottom();
      _tts.speak(item.content.length > 200 ? item.content.substring(0, 200) : item.content);
    }

    // ── Core message processor ──────────────────────────
    Future<void> _processInput(String text) async {
      if (text.trim().isEmpty) return;
      _ctrl.clear();
      setState(() => _isProcessing = true);

      final userMsg = ChatMessage(text: text, isUser: true, createdAt: DateTime.now());
      await DatabaseService.instance.saveChatMessage(userMsg);
      setState(() { _messages.add(userMsg); });
      _scrollToBottom();

      String response;

      // ── Number commands ─────────────────────────────
      final cmdResult = await _cmd.handleCommand(text, _lang);
      if (cmdResult != null) {
        if (cmdResult == '__SCREEN_MONITOR__') {
          setState(() => _isProcessing = false);
          if (mounted) Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ScreenMonitorScreen()));
          return;
        }
        response = cmdResult;
      }

      // ── Awaiting save content ────────────────────────
      else if (_awaitingSave) {
        await _ai.saveNewKnowledge(_pendingSaveTopic, text, null);
        response = _lang == 'marathi'
            ? '✅ "$_pendingSaveTopic" बद्दलची माहिती save केली! 😊'
            : '✅ Saved "$_pendingSaveTopic" info!';
        _awaitingSave = false;
        _pendingSaveTopic = '';
      }

      // ── Normal AI response ───────────────────────────
      else {
        response = await _ai.getResponse(text, _lang);
        if (response == '__MUTE__') {
          _tts.toggleMute();
          response = _lang == 'marathi' ? 'Mute केलं.' : 'Muted.';
        } else if (response == '__UNMUTE__') {
          if (_tts.isMuted) _tts.toggleMute();
          response = _lang == 'marathi' ? 'Unmute केलं.' : 'Unmuted.';
        } else if (response.contains('माहित नाही') || response.contains("don't know")) {
          _awaitingSave = true;
          _pendingSaveTopic = text;
        }
      }

      final aiMsg = ChatMessage(text: response, isUser: false, createdAt: DateTime.now());
      await DatabaseService.instance.saveChatMessage(aiMsg);
      setState(() { _messages.add(aiMsg); _isProcessing = false; });
      _scrollToBottom();
      await _tts.speak(response);
    }

    // ── File upload ─────────────────────────────────────
    Future<void> _uploadFile() async {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'md'],
      );
      if (result == null) return;
      _addAiMsg(_lang == 'marathi' ? '📄 File save होतेय...' : '📄 Processing file...');
      try {
        final content = await File(result.files.single.path!).readAsString();
        final name = result.files.single.name.replaceAll(RegExp(r'\.[^.]+$'), '');
        final response = await _ai.saveFileAsKnowledge(name, content, _lang);
        _replaceLastAiMsg(response);
        _tts.speak(response);
      } catch (e) {
        _replaceLastAiMsg(_lang == 'marathi'
            ? '⚠️ File read error. .txt file वापरा.' : 'File error. Use .txt file.');
      }
    }

    // ── Image: scan for trading position ────────────────
    Future<void> _scanImage() async {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      _addAiMsg(_lang == 'marathi' ? '📷 Image scan होतेय...' : '📷 Scanning image...');
      try {
        // OCR + analysis via AiService
        final response = await _ai.analyzeImageFile(picked.path, _lang);
        _replaceLastAiMsg(response);
        _tts.speak(response);
      } catch (e) {
        _replaceLastAiMsg('Image scan error: $e');
      }
    }

    void _addAiMsg(String text) {
      setState(() => _messages.add(
          ChatMessage(text: text, isUser: false, createdAt: DateTime.now())));
      _scrollToBottom();
    }

    void _replaceLastAiMsg(String text) {
      setState(() {
        if (_messages.isNotEmpty && !_messages.last.isUser) _messages.removeLast();
        _messages.add(ChatMessage(text: text, isUser: false, createdAt: DateTime.now()));
      });
      _scrollToBottom();
    }

    void _scrollToBottom() {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (_scroll.hasClients) _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0D1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A2E),
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text('Chat', style: TextStyle(color: Colors.white, fontSize: 17)),
          actions: [
            // 🧠 Knowledge topic search
            IconButton(
              icon: Icon(Icons.psychology,
                  color: _showTopicSearch ? const Color(0xFF3CE1C3) : Colors.white54),
              tooltip: 'Topic Search',
              onPressed: () => setState(() {
                _showTopicSearch = !_showTopicSearch;
                if (!_showTopicSearch) { _topicResults = []; _topicSearchCtrl.clear(); }
              }),
            ),
          ],
        ),
        body: Column(
          children: [
            // ── Topic search bar ──────────────────────────
            if (_showTopicSearch) _buildTopicSearch(),

            // ── Messages ─────────────────────────────────
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _messages.length + (_isProcessing ? 1 : 0),
                itemBuilder: (ctx, i) {
                  if (i == _messages.length) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(children: [
                        SizedBox(width: 12),
                        SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2,
                                color: Color(0xFF9B59F5))),
                        SizedBox(width: 10),
                        Text('विचार करतोय...', style: TextStyle(color: Colors.white38)),
                      ]),
                    );
                  }
                  return ChatBubble(message: _messages[i]);
                },
              ),
            ),

            // ── Shortcut chips ───────────────────────────
            _buildShortcuts(),

            // ── Input bar ────────────────────────────────
            _buildInputBar(),
          ],
        ),
      );
    }

    Widget _buildTopicSearch() {
      return Container(
        color: const Color(0xFF1A1A2E),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _topicSearchCtrl,
              style: const TextStyle(color: Colors.white),
              onChanged: _searchTopic,
              decoration: InputDecoration(
                hintText: '🧠 Topic search करा... (Support, RSI, Candle...)',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF3CE1C3), size: 20),
                filled: true,
                fillColor: const Color(0xFF0D0D1A),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none,
                ),
              ),
            ),
            if (_topicResults.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 160,
                child: ListView.builder(
                  itemCount: _topicResults.length,
                  itemBuilder: (ctx, i) {
                    final item = _topicResults[i];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.auto_stories, color: Color(0xFF9B59F5), size: 18),
                      title: Text(item.topic,
                          style: const TextStyle(color: Colors.white, fontSize: 13)),
                      subtitle: Text(
                        item.content.length > 50
                            ? '${item.content.substring(0, 50)}...' : item.content,
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                      onTap: () => _insertTopicResult(item),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      );
    }

    Widget _buildShortcuts() {
      final chips = [
        ('123 🚀', '123'),
        ('13 6 📊', '13 6'),
        ('25 2 📉', '25 2'),
        ('3 2 1 ⛔', '3 2 1'),
        ('2 💾', '2'),
      ];
      return SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: chips.map((c) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(c.$1, style: const TextStyle(fontSize: 11, color: Colors.white70)),
              backgroundColor: const Color(0xFF1A1A2E),
              side: const BorderSide(color: Color(0xFF9B59F5), width: 0.8),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              onPressed: () => _processInput(c.$2),
            ),
          )).toList(),
        ),
      );
    }

    Widget _buildInputBar() {
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        color: const Color(0xFF1A1A2E),
        child: Row(
          children: [
            // File upload
            IconButton(
              icon: const Icon(Icons.attach_file, color: Colors.white38),
              tooltip: 'Text file upload',
              onPressed: _uploadFile,
            ),
            // Image scan (gallery only, no camera)
            IconButton(
              icon: const Icon(Icons.image_search, color: Colors.white38),
              tooltip: 'Image scan (trading)',
              onPressed: _scanImage,
            ),
            // Text field
            Expanded(
              child: TextField(
                controller: _ctrl,
                style: const TextStyle(color: Colors.white),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: _processInput,
                decoration: InputDecoration(
                  hintText: _lang == 'marathi'
                      ? 'लिहा... किंवा command द्या (13 6, 123...)'
                      : 'Type or enter command (13 6, 123...)',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF0D0D1A),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Send
            GestureDetector(
              onTap: () => _processInput(_ctrl.text),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF6C3CE1),
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      );
    }
  }
  
