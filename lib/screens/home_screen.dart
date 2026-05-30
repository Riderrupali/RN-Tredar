import 'package:flutter/material.dart';
  import 'package:flutter_animate/flutter_animate.dart';
  import '../services/tts_service.dart';
  import '../services/stt_service.dart';
  import 'chat_screen.dart';
  import 'settings_screen.dart';
  import 'screen_monitor_screen.dart';

  class HomeScreen extends StatefulWidget {
    const HomeScreen({super.key});
    @override
    State<HomeScreen> createState() => _HomeScreenState();
  }

  class _HomeScreenState extends State<HomeScreen> {
    final TtsService _tts = TtsService.instance;
    final SttService _stt = SttService.instance;
    bool _micOn = false;
    bool _cmdListening = false;

    @override
    void initState() { super.initState(); _initialize(); }

    Future<void> _initialize() async {
      await _stt.init();
      await Future.delayed(const Duration(milliseconds: 800));
      await _tts.speak(_tts.languageGreeting);
    }

    @override
    void dispose() { _stt.stopListening(); super.dispose(); }

    Future<void> _toggleAlwaysOnMic() async {
      if (_micOn) {
        await _stt.stopListening();
        setState(() => _micOn = false);
      } else {
        setState(() => _micOn = true);
        _startContinuousListen();
      }
    }

    void _startContinuousListen() {
      _stt.startListening(
        onResult: (text) {
          if (text.isNotEmpty && _micOn) {
            _handleVoiceCommand(text);
            Future.delayed(const Duration(milliseconds: 400), () {
              if (_micOn && mounted) _startContinuousListen();
            });
          }
        },
        localeId: _stt.localeFor(_tts.language == AppLanguage.marathi ? 'marathi' :
            _tts.language == AppLanguage.hindi ? 'hindi' : 'english'),
      );
    }

    Future<void> _tapOrbListen() async {
      if (_cmdListening) {
        await _stt.stopListening();
        setState(() => _cmdListening = false);
      } else {
        setState(() => _cmdListening = true);
        await _stt.startListening(
          onResult: (text) {
            setState(() => _cmdListening = false);
            if (text.isNotEmpty) _handleVoiceCommand(text);
          },
          localeId: _stt.localeFor(_tts.language == AppLanguage.marathi ? 'marathi' :
              _tts.language == AppLanguage.hindi ? 'hindi' : 'english'),
        );
      }
    }

    void _handleVoiceCommand(String text) {
      final t = text.trim().toLowerCase();
      if (_isCmd(t, ['123', 'trading suru', 'treding suru', '1 2 3'])) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ScreenMonitorScreen()));
        return;
      }
      if (_isCmd(t, ['3 2 1', '321', 'stop trading', 'band karo', 'band kar'])) {
        _tts.speak(_tts.language == AppLanguage.marathi ? 'Trading बंद केलं!' : 'Trading stopped!');
        return;
      }
      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(initialMessage: text)));
    }

    bool _isCmd(String t, List<String> kws) => kws.any((k) => t.contains(k.toLowerCase()));

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0D1A),
        body: SafeArea(
          child: Column(children: [
            _buildHeader(),
            const Spacer(),
            _buildMagicOrb(),
            const SizedBox(height: 16),
            _buildStatusText(),
            const SizedBox(height: 12),
            _buildTip(),
            const Spacer(),
            _buildBottomNav(),
          ]),
        ),
      );
    }

    Widget _buildHeader() => Padding(
      padding: const EdgeInsets.all(20),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Code Magic', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold,
            foreground: Paint()..shader = const LinearGradient(
              colors: [Color(0xFF9B59F5), Color(0xFF3CE1C3)],
            ).createShader(const Rect.fromLTWH(0, 0, 200, 50)))),
          const Text('📈 Trading AI Friend • Marathi',
            style: TextStyle(color: Colors.white54, fontSize: 13)),
        ]),
        Row(children: [
          GestureDetector(
            onTap: _toggleAlwaysOnMic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _micOn ? const Color(0xFF9B59F5).withOpacity(0.25) : Colors.transparent,
                border: Border.all(
                  color: _micOn ? const Color(0xFF9B59F5) : Colors.transparent, width: 1.5),
              ),
              child: Icon(Icons.mic, color: _micOn ? const Color(0xFF9B59F5) : Colors.white38, size: 22),
            ),
          ),
          StatefulBuilder(builder: (ctx, s) => IconButton(
            onPressed: () { _tts.toggleMute(); s(() {}); },
            icon: Icon(_tts.isMuted ? Icons.volume_off : Icons.volume_up,
              color: _tts.isMuted ? Colors.redAccent : const Color(0xFF9B59F5)),
          )),
          IconButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
            icon: const Icon(Icons.settings, color: Colors.white54),
          ),
        ]),
      ]),
    );

    Widget _buildMagicOrb() {
      final listening = _cmdListening || _micOn;
      return GestureDetector(
        onTap: _tapOrbListen,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: listening ? 160 : 140, height: listening ? 160 : 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: listening
                ? [const Color(0xFF3CE1C3), const Color(0xFF6C3CE1)]
                : [const Color(0xFF9B59F5), const Color(0xFF3B1FA8)]),
            boxShadow: [BoxShadow(
              color: (listening ? const Color(0xFF3CE1C3) : const Color(0xFF9B59F5)).withOpacity(0.6),
              blurRadius: listening ? 60 : 40, spreadRadius: 10)],
          ),
          child: Icon(listening ? Icons.mic : Icons.mic_none, size: 60, color: Colors.white),
        ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds, color: Colors.white24),
      );
    }

    Widget _buildStatusText() => Text(
      _cmdListening ? (_tts.language == AppLanguage.marathi ? 'ऐकतोय... बोला' : 'Listening...')
          : _micOn ? (_tts.language == AppLanguage.marathi ? '🎤 Mic चालू' : '🎤 Mic ON')
          : (_tts.language == AppLanguage.marathi ? 'दाबा आणि बोला' : 'Tap to speak'),
      style: TextStyle(
        color: (_cmdListening || _micOn) ? const Color(0xFF3CE1C3) : Colors.white38,
        fontSize: 16, letterSpacing: 1.2),
    );

    Widget _buildTip() => Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF9B59F5).withOpacity(0.2))),
      child: const Text(
        '⚡ Commands:\n123 → Trading | 13 6 → Buy/Sell? | 25 2 → % | 3 2 1 → Stop',
        style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.6),
        textAlign: TextAlign.center),
    );

    Widget _buildBottomNav() => Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFF9B59F5).withOpacity(0.3))),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _navItem(Icons.chat_bubble_outline, 'Chat', const Color(0xFF9B59F5),
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()))),
        _navItem(Icons.phone_android, 'Screen\nMonitor', const Color(0xFF3CE1C3),
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScreenMonitorScreen()))),
        _navItem(Icons.settings_outlined, 'Settings', Colors.white38,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
      ]),
    );

    Widget _navItem(IconData icon, String label, Color color, VoidCallback onTap) =>
      GestureDetector(onTap: onTap,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 10),
              textAlign: TextAlign.center),
        ]));
  }
  
