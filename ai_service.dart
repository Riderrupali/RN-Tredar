import 'dart:io';
  import 'database_service.dart';
  import 'screen_monitor_service.dart';
  import 'ocr_service.dart';
  import '../models/knowledge_model.dart';

  class AiService {
    static final AiService instance = AiService._internal();
    AiService._internal();

    String _unknownTopic = '';

    // ── Pre-load candle/trading knowledge into DB ────────
    Future<void> seedTradingKnowledge() async {
      final existing = await DatabaseService.instance.getAllKnowledge();
      if (existing.isNotEmpty) return; // Already seeded

      final knowledge = [
        // ── Candlesticks ──────────────────────────────────
        KnowledgeItem(topic: 'Types of Candlesticks',
          content: 'Candlestick म्हणजे एका time period (1min, 5min, 1hr) मधील price movement.\n'
            'Green/Bullish candle = किंमत वर गेली. Open पेक्षा Close जास्त.\n'
            'Red/Bearish candle = किंमत खाली आली. Open पेक्षा Close कमी.\n'
            'Body = Open आणि Close मधील अंतर.\n'
            'Wick/Shadow = High आणि Low चा भाग.',
          appName: null, createdAt: DateTime.now()),

        KnowledgeItem(topic: 'Types of Candlesticks',
          content: 'Doji candle = Open आणि Close जवळजवळ सारखे. Market undecided आहे.\n'
            'Hammer = खाली लांब wick, वर छोटी body. Bullish reversal signal.\n'
            'Shooting Star = वर लांब wick, खाली छोटी body. Bearish reversal.\n'
            'Marubozu = कोणतीही wick नाही. Strong bullish/bearish candle.\n'
            'Engulfing = मागची candle पूर्ण झाकते. Powerful reversal signal.',
          appName: null, createdAt: DateTime.now()),

        // ── Volume ───────────────────────────────────────
        KnowledgeItem(topic: 'Volume',
          content: 'Volume म्हणजे किती shares/contracts trade झाले.\n'
            'High Volume + Price Up = Strong bullish signal.\n'
            'High Volume + Price Down = Strong bearish signal.\n'
            'Low Volume = Weak move, trust करू नका.\n'
            'Volume Spike = मोठे players market मध्ये आले आहेत.',
          appName: null, createdAt: DateTime.now()),

        KnowledgeItem(topic: 'Volume',
          content: 'Buy/Sell percent: जेव्हा Buyers जास्त असतात (>60%) तेव्हा candle वर जाते.\n'
            'Sellers जास्त (>60%) तेव्हा candle खाली येते.\n'
            'Volume कमी असताना Sell/Buy percent वर विश्वास ठेवू नका.\n'
            'Volume जास्त + Buy% जास्त = Strong Entry Signal.',
          appName: null, createdAt: DateTime.now()),

        // ── Support & Resistance ─────────────────────────
        KnowledgeItem(topic: 'Support & Resistance',
          content: 'Support = जो price खाली जाताना एका level वर थांबतो तो support level.\n'
            'Support वर candle वर परतली तर BUY करायची संधी.\n'
            'Resistance = जो price वर जाताना एका level वर थांबतो.\n'
            'Resistance break झाला तर Strong Bullish signal.\n'
            'Support break झाला तर Strong Bearish signal.',
          appName: null, createdAt: DateTime.now()),

        // ── Trend Analysis ───────────────────────────────
        KnowledgeItem(topic: 'Trend Analysis',
          content: 'Uptrend = Price Higher Highs आणि Higher Lows बनवतो. BUY संधी.\n'
            'Downtrend = Price Lower Highs आणि Lower Lows बनवतो. SELL संधी.\n'
            'Sideways = Price range मध्ये आहे. Wait करा.\n'
            'Trend follow करणे = सर्वात safe strategy.\n'
            '"Trend is your friend" — Trend विरुद्ध जाऊ नका.',
          appName: null, createdAt: DateTime.now()),

        // ── RSI ──────────────────────────────────────────
        KnowledgeItem(topic: 'RSI (Relative Strength Index)',
          content: 'RSI = 0-100 च्या दरम्यान असतो.\n'
            'RSI > 70 = Overbought = Sell करायला विचारा (candle खाली येऊ शकते).\n'
            'RSI < 30 = Oversold = Buy करायला विचारा (candle वर येऊ शकते).\n'
            'RSI 40-60 = Neutral zone. Wait करा.\n'
            'RSI Divergence = Price वर जातो पण RSI खाली = Bearish warning.',
          appName: null, createdAt: DateTime.now()),

        // ── MACD ─────────────────────────────────────────
        KnowledgeItem(topic: 'MACD',
          content: 'MACD = Moving Average Convergence Divergence.\n'
            'MACD Line Signal Line cross करते वर = BUY signal.\n'
            'MACD Line Signal Line cross करते खाली = SELL signal.\n'
            'Histogram वाढत असेल = Momentum वाढतोय.\n'
            'MACD Zero line cross = Strong trend change signal.',
          appName: null, createdAt: DateTime.now()),

        // ── Use of Indicators ─────────────────────────────
        KnowledgeItem(topic: 'Use of Indicators',
          content: 'RSI + MACD एकत्र वापरा — दोन्ही BUY म्हणत असतील तर Strong signal.\n'
            'Moving Average (MA20, MA50) = Trend direction सांगतो.\n'
            'Price MA च्या वर = Bullish. MA च्या खाली = Bearish.\n'
            'Bollinger Bands = Price band बाहेर गेला तर reversal येऊ शकतो.\n'
            'एकटा indicator कधी वापरू नका — confirm करत राहा.',
          appName: null, createdAt: DateTime.now()),

        // ── Buy/Sell Effect ──────────────────────────────
        KnowledgeItem(topic: 'Buy Sell Effect on Candle',
          content: 'Buy करणारे जास्त = Demand जास्त = Price वर जातो.\n'
            'Sell करणारे जास्त = Supply जास्त = Price खाली येतो.\n'
            'Current Price = जेवढे buyer आणि seller agree करतात तो price.\n'
            '55% Buy, 45% Sell = 5% जास्त chance candle वर जाईल.\n'
            '80% Buy = Strong bullish = candle definitely वर जाईल.',
          appName: null, createdAt: DateTime.now()),
      ];

      for (final item in knowledge) {
        await DatabaseService.instance.saveKnowledge(item);
      }
    }

    Future<String> respondToScreenText(String screenText, String language) async {
      return ScreenMonitorService.instance.analyzeScreenText(screenText, language);
    }

    // ── Analyze image file for trading position ──────────
    Future<String> analyzeImageFile(String imagePath, String language) async {
      try {
        final ocr = OcrService.instance;
        final text = await ocr.extractTextFromPath(imagePath);

        if (text.trim().isEmpty) {
          // No text found — describe based on image name
          return _imageNoTextResponse(language);
        }

        // Check if it's a market screen
        final isMarket = _isTradingScreenText(text);
        if (isMarket) {
          final response = await ScreenMonitorService.instance.analyzeScreenText(text, language);
          return '📷 Image Analysis:\n\n$response';
        }

        // Search knowledge for relevant info
        final results = await DatabaseService.instance.searchKnowledge(text.split(' ').take(5).join(' '));
        if (results.isNotEmpty) {
          return '📷 Image मध्ये मिळालेलं:\n\n${text.substring(0, text.length.clamp(0, 200))}\n\n'
                 '🧠 Knowledge: ${results.first.content}';
        }

        return '📷 Image मधील text:\n\n${text.substring(0, text.length.clamp(0, 300))}\n\n'
               '${_getTradingContext(text, language)}';
      } catch (e) {
        return language == 'marathi'
            ? '⚠️ Image scan करता आली नाही. Clear image द्या.'
            : 'Image scan failed. Please provide a clearer image.';
      }
    }

    bool _isTradingScreenText(String text) {
      final t = text.toLowerCase();
      return t.contains('nifty') || t.contains('banknifty') || t.contains('sensex') ||
          t.contains('buy') || t.contains('sell') || t.contains('rsi') ||
          t.contains('macd') || t.contains('candle') || t.contains('price') ||
          t.contains('volume') || t.contains('support') || t.contains('resistance') ||
          t.contains('%') || RegExp(r'\d+\.\d+').hasMatch(t);
    }

    String _getTradingContext(String text, String lang) {
      if (lang == 'marathi') return '📈 Trading संदर्भ: "2" टाईप करा → save करायला';
      if (lang == 'hindi') return '📈 Trading context. "2" type करें → save के लिए';
      return '📈 Trading context detected. Type "2" to save this info.';
    }

    String _imageNoTextResponse(String lang) {
      switch (lang) {
        case 'marathi':
          return '📷 Image मध्ये text सापडला नाही.\n\n'
              'Trading screen असेल तर:\n'
              '• Screen screenshot स्पष्ट असावा\n'
              '• Zoom in करून try करा\n'
              '• किंवा text copy करून Chat मध्ये पाठवा';
        case 'hindi':
          return '📷 Image में text नहीं मिला।\n\nClear screenshot दें।';
        default:
          return '📷 No text found in image.\n\nTry a clearer screenshot or copy-paste the text.';
      }
    }

    // ---------------------------------------------------------------
    // Main response — chat input
    // ---------------------------------------------------------------
    Future<String> getResponse(String userInput, String language) async {
      final input = userInput.trim();
      final inputLower = input.toLowerCase();

      if (_isMuteCommand(inputLower)) return '__MUTE__';
      if (_isUnmuteCommand(inputLower)) return '__UNMUTE__';
      if (_isGreeting(inputLower)) return _getGreeting(language);
      if (_isHelpCommand(inputLower)) return _getHelp(language);

      // Search saved knowledge
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
    // TEACH MODE (from file upload)
    // ---------------------------------------------------------------
    Future<String> teachAndSave(String userInput, String language) async {
      final text = userInput.trim();
      if (text.isEmpty) {
        return language == 'marathi' ? 'काहीतरी लिहा!' : 'Type something to save!';
      }
      final topic = _extractTradingTopic(text);
      await DatabaseService.instance.saveKnowledge(KnowledgeItem(
        topic: topic, content: text, appName: null, createdAt: DateTime.now()));
      switch (language) {
        case 'marathi':
          return '✅ Save झालं!\n📌 Topic: $topic\n\n'
              'Screen analysis मध्ये मी ही माहिती वापरेन!';
        case 'hindi':
          return '✅ Save हो गया!\n📌 Topic: $topic';
        default:
          return '✅ Saved!\n📌 Topic: $topic';
      }
    }

    Future<String> saveFileAsKnowledge(String fileName, String content, String language) async {
      final sections = content.split(RegExp(r'\n{2,}'))
          .map((s) => s.trim()).where((s) => s.length > 20).toList();
      if (sections.isEmpty) {
        await DatabaseService.instance.saveKnowledge(KnowledgeItem(
          topic: fileName, content: content.trim(), appName: null, createdAt: DateTime.now()));
        return _fileSavedResponse(fileName, 1, language);
      }
      int saved = 0;
      for (final section in sections) {
        final topic = _extractTradingTopic(section);
        await DatabaseService.instance.saveKnowledge(KnowledgeItem(
          topic: topic.isEmpty ? '$fileName - Part ${saved + 1}' : topic,
          content: section, appName: fileName,
          createdAt: DateTime.now().add(Duration(milliseconds: saved * 10))));
        saved++;
        if (saved >= 30) break;
      }
      return _fileSavedResponse(fileName, saved, language);
    }

    String _fileSavedResponse(String fileName, int count, String language) {
      switch (language) {
        case 'marathi':
          return '📄 "$fileName" save झाली!\n✅ $count entries save केल्या.\n'
              'Chat मध्ये विचारा — मी ही माहिती वापरेन!';
        case 'hindi':
          return '📄 "$fileName" save हुई!\n✅ $count entries.';
        default:
          return '📄 "$fileName" saved!\n✅ $count trading entries.';
      }
    }

    Future<String> saveNewKnowledge(String topic, String content, String? appName) async {
      await DatabaseService.instance.saveKnowledge(KnowledgeItem(
        topic: topic, content: content, appName: appName, createdAt: DateTime.now()));
      return topic;
    }

    String _buildKnowledgeResponse(KnowledgeItem item, String language) {
      switch (language) {
        case 'marathi':
          return '🧠 माझ्याकडे माहिती आहे:\n\n'
              '📌 ${item.topic}\n\n${item.content}\n\n'
              '${item.appName != null ? "App: ${item.appName}" : ""}';
        case 'hindi':
          return '🧠 जानकारी:\n\n📌 ${item.topic}\n\n${item.content}';
        default:
          return '🧠 Found:\n\n📌 ${item.topic}\n\n${item.content}';
      }
    }

    String _extractTradingTopic(String text) {
      final tradingTopics = <String, List<String>>{
        'Types of Candlesticks': ['candle', 'कँडल', 'doji', 'hammer', 'engulfing', 'bullish candle', 'bearish candle'],
        'RSI (Relative Strength Index)': ['rsi', 'relative strength', 'overbought', 'oversold'],
        'MACD': ['macd', 'signal line', 'histogram', 'convergence'],
        'Support & Resistance': ['support', 'सपोर्ट', 'resistance', 'रेजिस्टन्स', 'level'],
        'Trend Analysis': ['trend', 'ट्रेंड', 'uptrend', 'downtrend', 'sideways'],
        'Volume': ['volume', 'व्हॉल्यूम', 'volume spike'],
        'Use of Indicators': ['indicator', 'moving average', 'ema', 'sma', 'bollinger'],
        'Stop Loss & Target': ['stop loss', 'stoploss', 'sl', 'target', 'tp'],
        'Price Action': ['price action', 'higher high', 'lower low', 'swing'],
        'Buy Sell Effect on Candle': ['buy sell', 'buyer', 'seller', 'demand', 'supply', '%'],
      };
      final lower = text.toLowerCase();
      for (final entry in tradingTopics.entries) {
        for (final kw in entry.value) {
          if (lower.contains(kw.toLowerCase())) return entry.key;
        }
      }
      final words = text.split(RegExp(r'[\s,।\n]+')).where((w) => w.length > 1);
      final phrase = words.take(5).join(' ');
      return phrase.length > 45 ? '${phrase.substring(0, 45)}...' : phrase;
    }

    bool _isMuteCommand(String i) =>
        i.contains('mute') || i.contains('शांत') || i.contains('बंद कर') || i.contains('गप्प');
    bool _isUnmuteCommand(String i) =>
        i.contains('unmute') || i.contains('bol') || i.contains('चालू कर') || i.contains('आवाज');
    bool _isGreeting(String i) =>
        i == 'hi' || i == 'hello' || i.contains('नमस्कार') || i.contains('namaste') || i.contains('नमस्ते');
    bool _isHelpCommand(String i) =>
        i.contains('help') || i.contains('मदत') || i.contains('काय करू') || i.contains('क्या कर');

    String _getGreeting(String language) {
      switch (language) {
        case 'marathi':
          return 'नमस्कार! मी Code Magic — तुमचा Trading AI! 📈\n\n'
              'Commands:\n'
              '⚡ 123 → Trading सुरू\n'
              '📊 25 2 → Buy/Sell %\n'
              '🎯 13 6 → Quick Buy/Sell?\n'
              '⛔ 3 2 1 → Trading बंद\n\n'
              'सांगा, कसली मदत हवी?';
        case 'hindi':
          return 'नमस्ते! मैं Code Magic — Trading AI! 📈\n\n'
              '123 → Trading start | 13 6 → Quick decision | 3 2 1 → Stop';
        default:
          return 'Hey! Code Magic — Trading AI! 📈\n\n'
              '123 → Start | 13 6 → Quick decision | 3 2 1 → Stop';
      }
    }

    String _getHelp(String language) {
      switch (language) {
        case 'marathi':
          return '📈 Commands:\n\n'
              '1️⃣ "123" → Screen Monitor उघडा\n'
              '2️⃣ "2" → माहिती save करा\n'
              '3️⃣ "25 2" → Buy/Sell %\n'
              '4️⃣ "13 6" → Quick Buy/Sell decision\n'
              '5️⃣ "3 2 1" → Trading बंद\n\n'
              '🧠 वर "🧠" button → Topic search\n'
              '📎 File upload → सगळी माहिती save';
        case 'hindi':
          return '📈 Commands: 123=Start | 2=Save | 25 2=% | 13 6=Decision | 3 2 1=Stop';
        default:
          return '📈 Commands: 123=Start | 2=Save | 25 2=% | 13 6=Decision | 3 2 1=Stop';
      }
    }

    String _getUnknownResponse(String topic, String language) {
      final d = topic.length > 50 ? '${topic.substring(0, 50)}...' : topic;
      switch (language) {
        case 'marathi':
          return '"$d" बद्दल माहिती नाही अजून.\n\n'
              '📝 सांगा — मी save करतो!\n(खाली माहिती टाका)';
        case 'hindi':
          return '"$d" के बारे में जानकारी नहीं।\nबताएं — save करूंगा।';
        default:
          return 'No info about "$d" yet.\nTell me — I\'ll save it!';
      }
    }
  }
  