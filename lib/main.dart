import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'services/database_service.dart';
import 'services/tts_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Crash-safe initialization — try/catch so app never crashes on open
  try {
    await DatabaseService.instance.init();
  } catch (e) {
    debugPrint('DB init error (non-fatal): $e');
  }

  try {
    await TtsService.instance.init();
  } catch (e) {
    debugPrint('TTS init error (non-fatal): $e');
  }

  try {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  } catch (_) {}

  runApp(const CodeMagicApp());
}

class CodeMagicApp extends StatelessWidget {
  const CodeMagicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Code Magic',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C3CE1),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
      builder: (context, child) {
        // Global error boundary — catches render errors
        ErrorWidget.builder = (details) => Scaffold(
          backgroundColor: const Color(0xFF0D0D1A),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.redAccent, size: 48),
                  const SizedBox(height: 16),
                  const Text('काहीतरी चुकलं. App restart करा.',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(details.exception.toString(),
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        );
        return child!;
      },
    );
  }
}
