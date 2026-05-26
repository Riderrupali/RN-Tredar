import 'database_service.dart';
import 'screen_monitor_service.dart';
import '../models/knowledge_model.dart';

class AiService {
  static final AiService instance = AiService._internal();
  AiService._internal();

  String _unknownTopic = '';

  Future<String> respondToScreenText(String screenText, String language) async {
    return ScreenMonitorService.instance.analyzeScreenText(screenText, language);
  }

  // ---------------------------------------------------------------
  // Main response — chat input
  // ---------------------------------------------------------------
  Future<String> getResponse(String userInput, String language) async {
    final input = userInput.trim();
    final inputLower = input.toLowerCase();

    if (_isMuteCommand(inputLower)) return '__MUTE__';
    if (_isUnmuteCommand(inputLower)) return '__UNMUTE__';
    if (_isTeachOnCommand(inputLower)) return '__TEACH_ON__';
    if (_isTeachOffCommand(inputLower)) return '__TEACH_OFF__';
    if (_isGreeting(inputLower)) return _getGreeting(language);
    if (_isHelpCommand(inputLower)) return _getHelp(language);

    // Search saved knowledge — Unicode-safe (Marathi/Hindi/English)
    final results = await DatabaseService.instance.searchKnowledge(input);
    if (results.isNotEmpty) return _buildKnowledgeResponse(results.first, language);

    if (input != inputLower) {
      final r2 = await DatabaseService.instance.searchKnowledge(inputLower);
      if (r2.isNotEmpty) return _buildKnowledgeResponse(r2.first, language);
    }

    // Word-by-word search
    final words = input.split(RegExp(r'\s+')).where((w) => w.length > 2);
    for (final word in words.take(6)) {
      final wr = await DatabaseService.instance.searchKnowledge(word);
      if (wr.isNotEmpty) return _buildKnowledgeResponse(wr.first, language);
    }

    _unknownTopic = input;
    return _getUnknownResponse(input, language);
  }

  // ---------------------------------------------------------------
  // TEACH MODE — auto-save anything user types as trading knowledge
  // ---------------------------------------------------------------
  Future<String> teachAndSave(String userInput, String language) async {
    final text = userInput.trim();
    if (text.isEmpty) {
      return language == 'marathi'
          ? 'काहीतरी लिहा — मी save करतो!'
          : 'Type something — I\'ll save it!';
    }

    final topic = _extractTradingTopic(text);
    await DatabaseService.instance.saveKnowledge(KnowledgeItem(
      topic: topic,
      content: text,
      appName: null,
      createdAt: DateTime.now(),
    ));

    switch (language) {
      case 'marathi':
        return '✅ Trading माहिती save झाली!\n\n'
            '📌 विषय: $topic\n'
            '📝 माहिती: ${text.length > 100 ? '${text.substring(0, 100)}...' : text}\n\n'
            'Screen analysis मध्ये मी ही माहिती वापरेन!\n'
            'आणखी माहिती टाका किंवा "शिकवा बंद" म्हणा.';
      case 'hindi':
        return '✅ Trading जानकारी save हो गई!\n\n'
            '📌 विषय: $topic\n'
            '📝 जानकारी: ${text.length > 100 ? '${text.substring(0, 100)}...' : text}\n\n'
            'Screen analysis में उपयोग करूंगा! और जानकारी दें।';
      default:
        return '✅ Trading info saved!\n\n'
            '📌 Topic: $topic\n'
            '📝 Info: ${text.length > 100 ? '${text.substring(0, 100)}...' : text}\n\n'
            'I\'ll use this in trading screen analysis! Add more or say "teach off".';
    }
  }

  // ---------------------------------------------------------------
  // SMART FILE UPLOAD — splits file into multiple trading entries
  // Each paragraph = one knowledge entry
  // ---------------------------------------------------------------
  Future<String> saveFileAsKnowledge(String fileName, String content, String language) async {
    // Split file into paragraphs/sections
    final sections = content
        .split(RegExp(r'\n{2,}'))
        .map((s) => s.trim())
        .where((s) => s.length > 20)
        .toList();

    if (sections.isEmpty) {
      // Save as single entry if no paragraphs
      await DatabaseService.instance.saveKnowledge(KnowledgeItem(
        topic: fileName,
        content: content.trim(),
        appName: null,
        createdAt: DateTime.now(),
      ));
      return _fileSavedResponse(fileName, 1, language);
    }

    int saved = 0;
    for (final section in sections) {
      final topic = _extractTradingTopic(section);
      await DatabaseService.instance.saveKnowledge(KnowledgeItem(
        topic: topic.isEmpty ? '$fileName - Part ${saved + 1}' : topic,
        content: section,
        appName: fileName,
        createdAt: DateTime.now().add(Duration(milliseconds: saved * 10)),
      ));
      saved++;
      if (saved >= 30) break; // Max 30 entries per file
    }

    return _fileSavedResponse(fileName, saved, language);
  }

  String _fileSavedResponse(String fileName, int count, String language) {
    switch (language) {
      case 'marathi':
        return '📄 "$fileName" file save झाली!\n\n'
            '✅ $count trading entries save केल्या.\n\n'
            'आता Screen Analysis किंवा Chat मध्ये विचारा —\n'
            'मी या file मधील माहिती वापरेन!';
      case 'hindi':
        return '📄 "$fileName" file save हो गई!\n\n'
            '✅ $count trading entries save हुईं।\n\n'
            'अब Screen Analysis या Chat में पूछें।';
      default:
        return '📄 "$fileName" saved!\n\n'
            '✅ $count trading entries saved.\n\n'
            'Now ask anything — I\'ll use this file for trading analysis!';
    }
  }

  Future<String> saveNewKnowledge(
      String topic, String content, String? appName) async {
    await DatabaseService.instance.saveKnowledge(KnowledgeItem(
      topic: topic,
      content: content,
      appName: appName,
      createdAt: DateTime.now(),
    ));
    return topic;
  }

  // ---------------------------------------------------------------
  // Smart topic extractor — trading focused
  // ---------------------------------------------------------------
  String _extractTradingTopic(String text) {
    final tradingTopics = <String, List<String>>{
      'Bullish Pattern':     ['bullish', 'बुलिश', 'bull', 'green candle', 'हिरवी कँडल', 'hammer', 'morning star', 'ऊपर'],
      'Bearish Pattern':     ['bearish', 'बेअरिश', 'bear', 'red candle', 'लाल कँडल', 'shooting star', 'नीचे'],
      'Candlestick Pattern': ['candle', 'कँडल', 'doji', 'engulfing', 'marubozu', 'pinbar'],
      'RSI Indicator':       ['rsi', 'relative strength', 'overbought', 'oversold'],
      'MACD Indicator':      ['macd', 'signal line', 'histogram'],
      'Support Level':       ['support', 'सपोर्ट', 'floor', 'base', 'तळ'],
      'Resistance Level':    ['resistance', 'रेजिस्टन्स', 'ceiling', 'top'],
      'Trend Analysis':      ['trend', 'ट्रेंड', 'uptrend', 'downtrend', 'sideways', 'कल'],
      'Volume Analysis':     ['volume', 'व्हॉल्यूम', 'volume spike', 'high volume'],
      'Breakout Pattern':    ['breakout', 'ब्रेकआउट', 'breakdown', 'consolidation'],
      'Moving Average':      ['ema', 'sma', 'moving average', 'ma20', 'ma50', 'ma200'],
      'Stop Loss':           ['stop loss', 'stoploss', 'sl', 'risk management'],
      'Target / Profit':     ['target', 'profit', 'नफा', 'tp', 'take profit', 'reward'],
      'Entry / Exit':        ['entry', 'exit', 'buy', 'sell', 'खरेदी', 'विक्री'],
      'Option Trading':      ['option', 'call', 'put', 'strike', 'expiry', 'premium'],
      'Nifty / BankNifty':   ['nifty', 'banknifty', 'sensex', 'index', 'futures'],
      'Fibonacci':           ['fibonacci', 'fib', 'retracement', '61.8', '38.2'],
      'Price Action':        ['price action', 'pa', 'higher high', 'lower low', 'swing'],
    };

    final lower = text.toLowerCase();
    for (final entry in tradingTopics.entries) {
      for (final kw in entry.value) {
        if (lower.contains(kw.toLowerCase())) return entry.key;
      }
    }

    // Use first meaningful phrase as topic
    final words = text.split(RegExp(r'[\s,।\n]+')).where((w) => w.length > 1);
    final topicPhrase = words.take(5).join(' ');
    if (topicPhrase.length > 45) return '${topicPhrase.substring(0, 45)}...';
    return topicPhrase.isNotEmpty
        ? topicPhrase
        : text.substring(0, text.length.clamp(0, 45));
  }

  // ---- Commands ----

  bool _isMuteCommand(String i) =>
      i.contains('mute') || i.contains('शांत') || i.contains('बंद कर') ||
      i.contains('chup') || i.contains('गप्प') || i.contains('band kar');

  bool _isUnmuteCommand(String i) =>
      i.contains('unmute') || i.contains('speak') ||
      i.contains('bol') || i.contains('चालू कर') || i.contains('आवाज चालू');

  bool _isTeachOnCommand(String i) =>
      i.contains('शिकवा') || i.contains('shikva') || i.contains('teach on') ||
      i.contains('teach mode') || i.contains('shikvaycha') ||
      i.contains('माहिती save') || i.contains('mahiti save') ||
      i.contains('learn mode') || i.contains('शिका');

  bool _isTeachOffCommand(String i) =>
      i.contains('teach off') || i.contains('शिकवा बंद') ||
      i.contains('shikva band') || i.contains('normal chat') ||
      i.contains('stop teach') || i.contains('band teach');

  bool _isGreeting(String i) =>
      (i == 'hi' || i == 'hello' || i == 'hey' ||
      i.contains('नमस्कार') || i.contains('namaste') || i.contains('नमस्ते') ||
      i.contains('कसा आहेस') || i.contains('कसे आहात') || i.contains('कसं चाललंय'));

  bool _isHelpCommand(String i) =>
      i.contains('help') || i.contains('मदत') || i.contains('काय करू') ||
      i.contains('kay karu') || i.contains('कशी मदत') || i.contains('क्या कर');

  // ---- Responses ----

  String _getGreeting(String language) {
    switch (language) {
      case 'marathi':
        return 'नमस्कार! मी Code Magic आहे — तुमचा Trading AI मित्र! 📈\n\n'
            'मी हे करू शकतो:\n'
            '• Trading screen दाखवा → मी analysis देतो\n'
            '• "शिकवा" दाबा → Marathi मध्ये माहिती save करा\n'
            '• File upload करा → सगळी माहिती save होईल\n'
            '• "RSI काय आहे?" विचारा → सांगतो\n\n'
            'सांगा, कसली मदत हवी?';
      case 'hindi':
        return 'नमस्ते! मैं Code Magic हूँ — आपका Trading AI दोस्त! 📈\n\n'
            'क्या कर सकता हूँ:\n'
            '• Trading screen दें → analysis दूंगा\n'
            '• "Teach" दबाएं → Hindi में जानकारी save करें\n'
            '• File upload करें → सब save हो जाएगा\n\n'
            'बोलें, क्या काम है?';
      default:
        return 'Hey! I\'m Code Magic — your Trading AI! 📈\n\n'
            'What I can do:\n'
            '• Show trading screen → I\'ll analyze it\n'
            '• Tap "Teach" → Save trading info in Marathi\n'
            '• Upload a file → All info saved automatically\n\n'
            'How can I help?';
    }
  }

  String _getHelp(String language) {
    switch (language) {
      case 'marathi':
        return '📈 Trading मध्ये मी कसं मदत करतो:\n\n'
            '1️⃣ Chat मध्ये "शिकवा" button दाबा\n'
            '   → Marathi मध्ये trading माहिती लिहा\n'
            '   → मी ती save करतो आणि screen analysis मध्ये वापरतो\n\n'
            '2️⃣ File Upload करा (📎 button)\n'
            '   → ChatGPT/Google ने दिलेली trading info file\n'
            '   → App आपोआप सगळी माहिती save करतो\n\n'
            '3️⃣ "Trade 📈" tab → Screen चा screenshot द्या\n'
            '   → App OCR ने वाचतो आणि UP/DOWN सांगतो\n\n'
            '4️⃣ "Live 🔴" tab → नेहमी screen पाहत राहतो';
      case 'hindi':
        return '📈 Trading में मैं कैसे मदद करता हूँ:\n\n'
            '1️⃣ "Teach" button दबाएं → Hindi में जानकारी दें\n'
            '2️⃣ File Upload करें → सब auto-save होगा\n'
            '3️⃣ "Trade 📈" tab → Screen screenshot दें → UP/DOWN बताऊंगा\n'
            '4️⃣ "Live 🔴" tab → लगातार screen देखता रहूंगा';
      default:
        return '📈 How I help with trading:\n\n'
            '1️⃣ Tap "Teach" → Type trading info in any language\n'
            '2️⃣ Upload file → All info auto-saved\n'
            '3️⃣ "Trade 📈" tab → Screenshot → Get UP/DOWN signal\n'
            '4️⃣ "Live 🔴" tab → Continuous screen watching';
    }
  }

  String _getUnknownResponse(String topic, String language) {
    final display = topic.length > 50 ? '${topic.substring(0, 50)}...' : topic;
    switch (language) {
      case 'marathi':
        return '"$display" बद्दल माझ्याकडे अजून माहिती नाही.\n\n'
            '💡 "शिकवा" button दाबा आणि Marathi मध्ये सांगा —\n'
            'मी ते save करतो आणि पुढच्या वेळी सांगतो!';
      case 'hindi':
        return '"$display" के बारे में अभी जानकारी नहीं है।\n\n'
            '💡 "Teach" button दबाएं और Hindi में बताएं — याद रखूंगा!';
      default:
        return 'I don\'t have info about "$display" yet.\n\n'
            '💡 Tap "Teach" and tell me in Marathi/English — I\'ll save it!';
    }
  }

  String _buildKnowledgeResponse(KnowledgeItem item, String language) {
    final source = item.appName != null && item.appName!.isNotEmpty
        ? ' (${item.appName})'
        : '';
    switch (language) {
      case 'marathi':
        return '📚 ${item.topic}$source:\n\n${item.content}';
      case 'hindi':
        return '📚 ${item.topic}$source:\n\n${item.content}';
      default:
        return '📚 ${item.topic}$source:\n\n${item.content}';
    }
  }

  String get lastUnknownTopic => _unknownTopic;
}
