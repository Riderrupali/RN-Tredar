import 'package:flutter/material.dart';
  import 'package:flutter/services.dart';
  import 'package:flutter_overlay_window/flutter_overlay_window.dart';
  import 'screens/home_screen.dart';
  import 'services/database_service.dart';
  import 'services/tts_service.dart';

  @pragma("vm:entry-point")
  void overlayMain() {
    runApp(const TradingOverlayApp());
  }

  class TradingOverlayApp extends StatefulWidget {
    const TradingOverlayApp({super.key});
    @override
    State<TradingOverlayApp> createState() => _TradingOverlayAppState();
  }

  class _TradingOverlayAppState extends State<TradingOverlayApp> {
    bool _screenShareOn = true;
    bool _micOn = false;
    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: BoxDecoration(
              color: const Color(0xCC1A1A2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF9B59F5).withOpacity(0.6)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text('📈', style: TextStyle(fontSize: 14)),
              ),
              _btn(Icons.screen_share, _screenShareOn ? 'Share\nOn' : 'Share\nOff',
                _screenShareOn ? const Color(0xFF3CE1C3) : Colors.white38,
                () => setState(() => _screenShareOn = !_screenShareOn)),
              _btn(Icons.mic, _micOn ? 'Mic\nOn' : 'Mic\nOff',
                _micOn ? const Color(0xFF9B59F5) : Colors.white38,
                () => setState(() => _micOn = !_micOn)),
              GestureDetector(
                onTap: () => FlutterOverlayWindow.closeOverlay(),
                child: const Padding(padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, color: Colors.white38, size: 14))),
            ]),
          ),
        ),
      );
    }
    Widget _btn(IconData icon, String label, Color color, VoidCallback onTap) {
      return GestureDetector(onTap: onTap,
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 22),
            Text(label, style: TextStyle(color: color, fontSize: 9), textAlign: TextAlign.center),
          ])));
    }
  }

  Future<void> main() async {
    WidgetsFlutterBinding.ensureInitialized();
    try { await DatabaseService.instance.init(); } catch (e) { debugPrint('DB: $e'); }
    try { await TtsService.instance.init(); } catch (e) { debugPrint('TTS: $e'); }
    try { SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]); } catch (_) {}
    runApp(const CodeMagicApp());
  }

  class CodeMagicApp extends StatelessWidget {
    const CodeMagicApp({super.key});
    @override
    Widget build(BuildContext context) => MaterialApp(
      title: 'Code Magic',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C3CE1), brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
  
