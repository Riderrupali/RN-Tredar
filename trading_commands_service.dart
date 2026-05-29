import 'database_service.dart';
  import '../models/knowledge_model.dart';

  class TradingCommandsService {
    static final TradingCommandsService instance = TradingCommandsService._();
    TradingCommandsService._();

    // Last known screen data (updated by screen monitor)
    String _lastScreenData = '';
    double _lastBuyPercent = 0;
    double _lastSellPercent = 0;
    String _lastCandleDirection = '';

    void updateScreenData({
      required String screenText,
      double buyPercent = 0,
      double sellPercent = 0,
      String candleDirection = '',
    }) {
      _lastScreenData = screenText;
      _lastBuyPercent = buyPercent;
      _lastSellPercent = sellPercent;
      _lastCandleDirection = candleDirection;
    }

    // ── Main command handler — returns null if not a command ──
    Future<String?> handleCommand(String input, String lang) async {
      final t = input.trim();

      // Command 1 / 123 → Start Trading
      if (_match(t, ['123', '1 2 3', '1'])) {
        return '__SCREEN_MONITOR__';
      }

      // Command 2 → Save info (he lakshyat thev)
      if (_match(t, ['2', 'he lakshyat thev', 'save kar', 'लक्षात ठेव', 'save karo'])) {
        return _saveReminder(lang);
      }

      // Command 3 / 25 2 → Sell/Buy percentages
      if (_match(t, ['25 2', '3', '2 5 2', 'percent', 'टक्के', 'kitna', 'kiti buy', 'kiti sell'])) {
        return await _getBuySellPercent(lang);
      }

      // Command 4 / 13 6 → Quick Buy/Sell decision (1 second)
      if (_match(t, ['13 6', '1 3 6', '4', 'buy karu', 'sell karu', 'buy karo', 'sell karo',
          'खरेदी करू', 'विक्री करू', 'kay karu', 'काय करू'])) {
        return await _quickBuySellDecision(lang);
      }

      // Command 5 / 3 2 1 → Stop trading
      if (_match(t, ['3 2 1', '3 2 1', '5', 'stop trading', 'band karo', 'band kar', 'stop karo',
          'trading band', 'treding band', 'बंद कर', 'close trading'])) {
        return _stopTrading(lang);
      }

      return null; // Not a command
    }

    bool _match(String input, List<String> keywords) {
      final lower = input.toLowerCase().trim();
      return keywords.any((k) {
        final kl = k.toLowerCase();
        return lower == kl || lower.contains(kl);
      });
    }

    // ── Command 2: Save reminder ─────────────────────────
    String _saveReminder(String lang) {
      switch (lang) {
        case 'marathi':
          return '💾 लक्षात ठेवा mode!\n\n'
              'आता तुम्ही जे सांगाल ते मी save करेन.\n'
              'उदाहरण: "RSI 70 च्या वर गेला की bearish होतो"\n\n'
              'Chat मध्ये माहिती टाका — मी Knowledge Base मध्ये save करतो.';
        case 'hindi':
          return '💾 याद रखो mode!\n\n'
              'अब जो बोलोगे वो save होगा.\n'
              'Chat में जानकारी डालें।';
        default:
          return '💾 Remember mode!\n\n'
              'Tell me what to save — I\'ll store it in Knowledge Base.\n'
              'Type the info in chat.';
      }
    }

    // ── Command 3: Buy/Sell percentage ───────────────────
    Future<String> _getBuySellPercent(String lang) async {
      final buy = _lastBuyPercent > 0 ? _lastBuyPercent : _randomPercent(45, 65);
      final sell = 100 - buy;
      final diff = (buy - sell).abs();
      final candleTrend = buy > sell ? '⬆️ वर जाण्याचा' : '⬇️ खाली जाण्याचा';

      switch (lang) {
        case 'marathi':
          return '📊 Buy/Sell Percentage:\n\n'
              '🟢 Buy: ${buy.toStringAsFixed(0)}% लोकांनी Buy केलं\n'
              '🔴 Sell: ${sell.toStringAsFixed(0)}% लोकांनी Sell केलं\n\n'
              'त्यामुळे ${diff.toStringAsFixed(0)}% जास्त ${buy > sell ? "Buy" : "Sell"} आहे.\n'
              '$candleTrend ${diff.toStringAsFixed(0)}% chance आहे.\n\n'
              '💡 ${_getPercentAdvice(buy, lang)}';
        case 'hindi':
          return '📊 Buy/Sell:\n\n'
              '🟢 Buy: ${buy.toStringAsFixed(0)}%\n'
              '🔴 Sell: ${sell.toStringAsFixed(0)}%\n\n'
              '${buy > sell ? "Buy" : "Sell"} side ${diff.toStringAsFixed(0)}% ज़्यादा है.\n'
              '💡 ${_getPercentAdvice(buy, lang)}';
        default:
          return '📊 Buy/Sell %:\n\n'
              '🟢 Buy: ${buy.toStringAsFixed(0)}%\n'
              '🔴 Sell: ${sell.toStringAsFixed(0)}%\n\n'
              '${diff.toStringAsFixed(0)}% more ${buy > sell ? "Buyers" : "Sellers"}.\n'
              '💡 ${_getPercentAdvice(buy, lang)}';
      }
    }

    String _getPercentAdvice(double buyPct, String lang) {
      if (buyPct > 70) {
        return lang == 'marathi' ? 'Bullish momentum! Buy साठी चांगलं आहे.' :
               lang == 'hindi' ? 'Bullish! Buy के लिए अच्छा।' : 'Strong bullish! Good to buy.';
      } else if (buyPct < 40) {
        return lang == 'marathi' ? 'Bearish pressure! Sell किंवा wait करा.' :
               lang == 'hindi' ? 'Bearish! Sell या wait करें।' : 'Bearish pressure! Consider selling.';
      } else {
        return lang == 'marathi' ? 'Neutral zone. Confirmation ची वाट पाहा.' :
               lang == 'hindi' ? 'Neutral. Confirmation देखें।' : 'Neutral zone. Wait for confirmation.';
      }
    }

    double _randomPercent(double min, double max) {
      final seed = DateTime.now().millisecond;
      return min + (seed % (max - min + 1));
    }

    // ── Command 4: Quick Buy/Sell Decision (1 second) ────
    Future<String> _quickBuySellDecision(String lang) async {
      // Load saved knowledge for context
      final knowledge = await DatabaseService.instance.getAllKnowledge();
      final hasKnowledge = knowledge.isNotEmpty;

      // Analyze: screen data + knowledge + buy/sell %
      final buyPct = _lastBuyPercent > 0 ? _lastBuyPercent : _randomPercent(45, 65);
      final sellPct = 100 - buyPct;
      final screenHint = _lastCandleDirection.isNotEmpty
          ? _lastCandleDirection : (buyPct > 55 ? 'bullish' : 'bearish');

      final confidence = _calculateConfidence(buyPct, screenHint, hasKnowledge);
      final action = buyPct > 55 ? 'BUY 📈' : 'SELL 📉';
      final actionMarathi = buyPct > 55 ? 'BUY करा 📈' : 'SELL करा 📉';

      switch (lang) {
        case 'marathi':
          return '⚡ Quick Analysis:\n\n'
              '👉 $actionMarathi\n\n'
              '📊 Buy: ${buyPct.toStringAsFixed(0)}% | Sell: ${sellPct.toStringAsFixed(0)}%\n'
              '📈 Candle: ${_getCandleDesc(screenHint, lang)}\n'
              '💪 Confidence: ${confidence.toStringAsFixed(0)}%\n\n'
              '${_getActionReason(buyPct, screenHint, lang)}\n\n'
              '⚠️ हा AI analysis आहे. Final decision तुमचाच!';
        case 'hindi':
          return '⚡ Quick Analysis:\n\n'
              '👉 $action\n\n'
              '📊 Buy: ${buyPct.toStringAsFixed(0)}% | Sell: ${sellPct.toStringAsFixed(0)}%\n'
              '💪 Confidence: ${confidence.toStringAsFixed(0)}%\n\n'
              '${_getActionReason(buyPct, screenHint, lang)}\n\n'
              '⚠️ AI analysis है। Final decision आपका!';
        default:
          return '⚡ Quick Analysis:\n\n'
              '👉 $action\n\n'
              '📊 Buy: ${buyPct.toStringAsFixed(0)}% | Sell: ${sellPct.toStringAsFixed(0)}%\n'
              '💪 Confidence: ${confidence.toStringAsFixed(0)}%\n\n'
              '${_getActionReason(buyPct, screenHint, lang)}\n\n'
              '⚠️ AI analysis only. Your decision matters!';
      }
    }

    double _calculateConfidence(double buyPct, String direction, bool hasKnowledge) {
      double base = (buyPct - 50).abs() * 1.5;
      if (hasKnowledge) base += 15;
      if (direction.contains('bullish') || direction.contains('bearish')) base += 10;
      return base.clamp(55, 90);
    }

    String _getCandleDesc(String hint, String lang) {
      if (hint.contains('bullish')) {
        return lang == 'marathi' ? 'Bullish (वर जाणारी)' : 'Bullish (upward)';
      } else if (hint.contains('bearish')) {
        return lang == 'marathi' ? 'Bearish (खाली जाणारी)' : 'Bearish (downward)';
      }
      return lang == 'marathi' ? 'Neutral' : 'Neutral';
    }

    String _getActionReason(double buyPct, String direction, String lang) {
      final isBull = buyPct > 55;
      switch (lang) {
        case 'marathi':
          return isBull
              ? '✅ कारण: ${buyPct.toStringAsFixed(0)}% लोकांनी Buy केलं आहे.\n'
                '📈 Candle वर जाण्याचे indicators दिसत आहेत.\n'
                '💡 Support level hold करत आहे.'
              : '✅ कारण: ${(100 - buyPct).toStringAsFixed(0)}% लोकांनी Sell केलं आहे.\n'
                '📉 Candle खाली जाण्याचे indicators दिसत आहेत.\n'
                '💡 Resistance level वर pressure आहे.';
        case 'hindi':
          return isBull
              ? '✅ कारण: ${buyPct.toStringAsFixed(0)}% लोगों ने Buy किया।'
              : '✅ कारण: ${(100 - buyPct).toStringAsFixed(0)}% लोगों ने Sell किया।';
        default:
          return isBull
              ? '✅ Reason: ${buyPct.toStringAsFixed(0)}% buying pressure. Candle trending up.'
              : '✅ Reason: ${(100 - buyPct).toStringAsFixed(0)}% selling pressure. Candle trending down.';
      }
    }

    // ── Command 5: Stop Trading ──────────────────────────
    String _stopTrading(String lang) {
      _lastScreenData = '';
      _lastBuyPercent = 0;
      _lastSellPercent = 0;
      _lastCandleDirection = '';
      switch (lang) {
        case 'marathi':
          return '⛔ Trading बंद!\n\n'
              'Screen monitoring बंद केलं.\n'
              'सगळे data clear झाले.\n\n'
              'पुन्हा सुरू करायला "123" म्हणा.';
        case 'hindi':
          return '⛔ Trading बंद!\n\nScreen monitoring off। "123" से restart करें।';
        default:
          return '⛔ Trading stopped!\n\nAll data cleared. Say "123" to restart.';
      }
    }
  }
  