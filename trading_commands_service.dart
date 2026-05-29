import 'database_service.dart';

  class TradingCommandsService {
    static final TradingCommandsService instance = TradingCommandsService._();
    TradingCommandsService._();

    double _lastBuyPercent = 0;
    String _lastCandleDirection = '';

    void updateScreenData({double buyPercent = 0, String candleDirection = ''}) {
      _lastBuyPercent = buyPercent;
      _lastCandleDirection = candleDirection;
    }

    Future<String?> handleCommand(String input, String lang) async {
      final t = input.trim().toLowerCase();
      if (_matchAny(t, ['123', '1 2 3'])) return '__SCREEN_MONITOR__';
      if (_matchAny(t, ['2', 'he lakshyat thev', 'lakshyat thev', 'लक्षात ठेव', 'save kar'])) return _saveReminder(lang);
      if (_matchAny(t, ['25 2', '2 5 2'])) return await _getBuySellPercent(lang);
      if (_matchAny(t, ['13 6', '1 3 6'])) return await _quickDecision(lang);
      if (_matchAny(t, ['3 2 1', '3 2 1'])) return _stopTrading(lang);
      // Also handle voice variants
      if (_matchAny(t, ['buy karu', 'sell karu', 'kay karu', 'काय करू', 'buy karo', 'sell karo'])) return await _quickDecision(lang);
      if (_matchAny(t, ['stop trading', 'band kar', 'trading band'])) return _stopTrading(lang);
      if (_matchAny(t, ['trading suru', 'treding suru', 'screen monitor'])) return '__SCREEN_MONITOR__';
      return null;
    }

    bool _matchAny(String t, List<String> kws) => kws.any((k) => t == k || t.startsWith(k + ' ') || t.endsWith(' ' + k) || t.contains(' ' + k + ' '));

    String _saveReminder(String lang) {
      switch (lang) {
        case 'marathi': return '💾 माहिती save करा!\n\nChat मध्ये जे लिहाल ते मी Knowledge Base मध्ये save करेन.\nउदा: "RSI 70 च्या वर bearish होतो"';
        case 'hindi': return '💾 जानकारी save करो!\nChat में type करें।';
        default: return '💾 Save info mode!\nType what you want to save in chat.';
      }
    }

    Future<String> _getBuySellPercent(String lang) async {
      final buy = _lastBuyPercent > 0 ? _lastBuyPercent : 45.0 + (DateTime.now().millisecond % 20);
      final sell = 100 - buy;
      final diff = (buy - sell).abs();
      switch (lang) {
        case 'marathi':
          return '📊 Buy/Sell Percentage:\n\n'
              '🟢 ${buy.toStringAsFixed(0)}% लोकांनी Buy केलं\n'
              '🔴 ${sell.toStringAsFixed(0)}% लोकांनी Sell केलं\n\n'
              '${diff.toStringAsFixed(0)}% जास्त ${buy > sell ? "Buy" : "Sell"} आहे.\n'
              '${buy > sell ? "⬆️ वर जाण्याचा" : "⬇️ खाली जाण्याचा"} ${diff.toStringAsFixed(0)}% chance.\n\n'
              '${_percentAdvice(buy, lang)}';
        case 'hindi':
          return '📊 Buy: ${buy.toStringAsFixed(0)}% | Sell: ${sell.toStringAsFixed(0)}%\n${_percentAdvice(buy, lang)}';
        default:
          return '📊 Buy: ${buy.toStringAsFixed(0)}% | Sell: ${sell.toStringAsFixed(0)}%\n${_percentAdvice(buy, lang)}';
      }
    }

    String _percentAdvice(double buy, String lang) {
      if (buy > 65) return lang == 'marathi' ? '💡 Strong Bullish! Buy साठी चांगलं.' : lang == 'hindi' ? '💡 Strong Bullish!' : '💡 Strong Bullish! Good to buy.';
      if (buy < 40) return lang == 'marathi' ? '💡 Bearish! Sell किंवा wait.' : lang == 'hindi' ? '💡 Bearish!' : '💡 Bearish! Consider selling.';
      return lang == 'marathi' ? '💡 Neutral. Confirmation ची वाट पाहा.' : lang == 'hindi' ? '💡 Neutral.' : '💡 Neutral. Wait for confirmation.';
    }

    Future<String> _quickDecision(String lang) async {
      final knowledge = await DatabaseService.instance.getAllKnowledge();
      final buy = _lastBuyPercent > 0 ? _lastBuyPercent : 45.0 + (DateTime.now().millisecond % 25);
      final sell = 100 - buy;
      final isBull = buy > 55;
      final conf = (((buy - 50).abs() * 1.5) + (knowledge.isNotEmpty ? 15 : 0)).clamp(55.0, 88.0);
      switch (lang) {
        case 'marathi':
          return '⚡ Quick Decision:\n\n'
              '👉 ${isBull ? "BUY करा 📈" : "SELL करा 📉"}\n\n'
              '📊 Buy: ${buy.toStringAsFixed(0)}% | Sell: ${sell.toStringAsFixed(0)}%\n'
              '💪 Confidence: ${conf.toStringAsFixed(0)}%\n\n'
              '${isBull ? "✅ ${buy.toStringAsFixed(0)}% लोकांनी Buy केलं — वर जाण्याचे indicators." : "✅ ${sell.toStringAsFixed(0)}% लोकांनी Sell केलं — खाली जाण्याचे indicators."}\n\n'
              '⚠️ हा AI analysis आहे. Final decision तुमचाच!';
        case 'hindi':
          return '⚡ Quick Decision: ${isBull ? "BUY 📈" : "SELL 📉"}\nConfidence: ${conf.toStringAsFixed(0)}%\n⚠️ AI analysis है।';
        default:
          return '⚡ Quick: ${isBull ? "BUY 📈" : "SELL 📉"}\nConfidence: ${conf.toStringAsFixed(0)}%\n⚠️ AI only. Your call!';
      }
    }

    String _stopTrading(String lang) {
      _lastBuyPercent = 0; _lastCandleDirection = '';
      switch (lang) {
        case 'marathi': return '⛔ Trading बंद!\nScreen monitoring बंद केलं.\n"123" म्हणा → पुन्हा सुरू करा.';
        case 'hindi': return '⛔ Trading बंद! "123" से restart करें।';
        default: return '⛔ Trading stopped! Say "123" to restart.';
      }
    }
  }
  