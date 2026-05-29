import 'dart:io';
  import 'database_service.dart';
  import 'screen_monitor_service.dart';
  import 'ocr_service.dart';
  import '../models/knowledge_model.dart';

  class AiService {
    static final AiService instance = AiService._internal();
    AiService._internal();

    Future<String> analyzeImageFile(String imagePath, String language) async {
      try {
        final text = await OcrService.instance.extractTextFromPath(imagePath);
        if (text.trim().isEmpty) {
          return language == 'marathi'
              ? '📷 Image मध्ये text सापडला नाही.\nClear screenshot द्या.'
              : 'No text found. Provide a clearer screenshot.';
        }
        final response = await ScreenMonitorService.instance.analyzeScreenText(text, language);
        return '📷 Image Analysis:\n\n$response';
      } catch (e) {
        return language == 'marathi' ? '⚠️ Image scan error. Clear image द्या.' : 'Image scan failed.';
      }
    }

    Future<String> getResponse(String userInput, String language) async {
      final input = userInput.trim();
      final lower = input.toLowerCase();

      if (_isMute(lower)) return '__MUTE__';
      if (_isUnmute(lower)) return '__UNMUTE__';
      if (_isGreeting(lower)) return _greeting(language);
      if (_isHelp(lower)) return _help(language);

      final results = await DatabaseService.instance.searchKnowledge(input);
      if (results.isNotEmpty) return _knowledgeResp(results.first, language);

      final lower2 = input != lower ? await DatabaseService.instance.searchKnowledge(lower) : <KnowledgeItem>[];
      if (lower2.isNotEmpty) return _knowledgeResp(lower2.first, language);

      for (final word in input.split(RegExp(r'\s+')).where((w) => w.length > 2).take(6)) {
        final wr = await DatabaseService.instance.searchKnowledge(word);
        if (wr.isNotEmpty) return _knowledgeResp(wr.first, language);
      }
      return _unknown(input, language);
    }

    Future<String> teachAndSave(String text, String language) async {
      if (text.trim().isEmpty) return language == 'marathi' ? 'काहीतरी लिहा!' : 'Type something!';
      final topic = _extractTopic(text);
      await DatabaseService.instance.saveKnowledge(KnowledgeItem(
          topic: topic, content: text, appName: null, createdAt: DateTime.now()));
      return language == 'marathi'
          ? '✅ Save झालं!\n📌 Topic: $topic'
          : '✅ Saved! Topic: $topic';
    }

    Future<String> saveFileAsKnowledge(String fileName, String content, String language) async {
      final sections = content.split(RegExp(r'\n{2,}')).map((s) => s.trim()).where((s) => s.length > 20).toList();
      final list = sections.isEmpty ? [content.trim()] : sections;
      int saved = 0;
      for (final s in list) {
        await DatabaseService.instance.saveKnowledge(KnowledgeItem(
            topic: _extractTopic(s).isEmpty ? '$fileName - Part ${saved + 1}' : _extractTopic(s),
            content: s, appName: fileName,
            createdAt: DateTime.now().add(Duration(milliseconds: saved * 10))));
        if (++saved >= 30) break;
      }
      switch (language) {
        case 'marathi': return '📄 "$fileName" save झाली!\n✅ $saved entries save केल्या.\nChat मध्ये विचारा!';
        case 'hindi': return '📄 "$fileName" save हुई! ✅ $saved entries।';
        default: return '📄 "$fileName" saved! ✅ $saved entries.';
      }
    }

    Future<String> saveNewKnowledge(String topic, String content, String? appName) async {
      await DatabaseService.instance.saveKnowledge(KnowledgeItem(
          topic: topic, content: content, appName: appName, createdAt: DateTime.now()));
      return topic;
    }

    String _knowledgeResp(KnowledgeItem item, String lang) {
      switch (lang) {
        case 'marathi': return '🧠 माझ्याकडे माहिती आहे:\n\n📌 ${item.topic}\n\n${item.content}';
        case 'hindi': return '🧠 जानकारी:\n\n📌 ${item.topic}\n\n${item.content}';
        default: return '🧠 Found:\n\n📌 ${item.topic}\n\n${item.content}';
      }
    }

    String _extractTopic(String text) {
      const map = <String, List<String>>{
        'Types of Candlesticks': ['candle', 'कँडल', 'doji', 'hammer', 'engulfing'],
        'RSI (Relative Strength Index)': ['rsi', 'relative strength', 'overbought', 'oversold'],
        'MACD': ['macd', 'signal line', 'histogram'],
        'Support & Resistance': ['support', 'सपोर्ट', 'resistance', 'रेजिस्टन्स'],
        'Trend Analysis': ['trend', 'ट्रेंड', 'uptrend', 'downtrend'],
        'Volume': ['volume', 'व्हॉल्यूम'],
        'Use of Indicators': ['indicator', 'moving average', 'ema', 'bollinger'],
        'Stop Loss & Target': ['stop loss', 'stoploss', 'target', 'tp'],
        'Buy Sell Effect on Candle': ['buy sell', 'buyer', 'seller', 'demand', 'supply'],
      };
      final lower = text.toLowerCase();
      for (final e in map.entries) {
        if (e.value.any((k) => lower.contains(k.toLowerCase()))) return e.key;
      }
      final words = text.split(RegExp(r'[\s,।\n]+')).where((w) => w.length > 1).take(5).join(' ');
      return words.length > 45 ? '${words.substring(0, 45)}...' : words;
    }

    bool _isMute(String i) => i.contains('mute') || i.contains('शांत') || i.contains('गप्प');
    bool _isUnmute(String i) => i.contains('unmute') || i.contains('चालू कर') || i.contains('आवाज');
    bool _isGreeting(String i) => i == 'hi' || i == 'hello' || i.contains('नमस्कार') || i.contains('namaste');
    bool _isHelp(String i) => i.contains('help') || i.contains('मदत') || i.contains('काय करू');

    String _greeting(String lang) {
      switch (lang) {
        case 'marathi':
          return 'नमस्कार! मी Code Magic — Trading AI! 📈\n\n'
              '⚡ Commands:\n'
              '123 → Trading सुरू | 13 6 → Buy/Sell?\n'
              '25 2 → % | 2 → Save | 3 2 1 → Stop\n\n'
              'सांगा, कसली मदत हवी?';
        case 'hindi': return 'नमस्ते! Code Magic — Trading AI! 📈\n123=Start | 13 6=Decision | 3 2 1=Stop';
        default: return 'Hey! Code Magic — Trading AI! 📈\n123=Start | 13 6=Decision | 3 2 1=Stop';
      }
    }

    String _help(String lang) {
      switch (lang) {
        case 'marathi':
          return '📈 Commands:\n\n'
              '123 → Screen Monitor (Trading सुरू)\n'
              '2 → माहिती save करा\n'
              '25 2 → Buy/Sell %\n'
              '13 6 → Quick Buy/Sell (1 sec)\n'
              '3 2 1 → Trading बंद\n\n'
              '🧠 Chat वर → Topic search\n📎 File upload → माहिती save';
        default: return '📈 123=Start | 2=Save | 25 2=% | 13 6=Decision | 3 2 1=Stop';
      }
    }

    String _unknown(String topic, String lang) {
      final d = topic.length > 50 ? '${topic.substring(0, 50)}...' : topic;
      switch (lang) {
        case 'marathi': return '"$d" बद्दल माहिती नाही अजून.\n📝 सांगा — मी save करतो!\n(खाली माहिती टाका)';
        case 'hindi': return '"$d" की जानकारी नहीं।\nबताएं — save करूंगा।';
        default: return 'No info about "$d" yet.\nTell me — I\'ll save it!';
      }
    }
  }
  
