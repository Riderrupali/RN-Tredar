# Code Magic App — v14 Fix
  ## PROBLEM FIXED
  ❌ settings_screen.dart — shared_preferences काढला (pubspec.yaml ची गरज नाही)
  ❌ chat_bubble.dart — आता lib/widgets/ मध्ये आहे
  ✅ सगळे 17 files included

  ## HOW TO USE — Step by Step
  1. GitHub repo मध्ये जा
  2. lib/ folder delete करा (सगळं clear करा)
  3. या ZIP मधून lib/ folder upload करा
  4. pubspec.yaml मध्ये shared_preferences नको (आधीच remove केलं)
  5. Push + Build!

  ## Files Structure
  lib/
  ├── main.dart
  ├── screens/
  │   ├── home_screen.dart          ← Always-on mic, Home
  │   ├── chat_screen.dart          ← Commands: 123, 2, 25 2, 13 6, 3 2 1
  │   ├── screen_monitor_screen.dart ← NEW: Screen Monitor + Candle Loading
  │   ├── knowledge_screen.dart     ← Topics: Support, RSI, MACD...
  │   └── settings_screen.dart     ← Language + Voice + Theme (NO shared_prefs)
  ├── widgets/
  │   └── chat_bubble.dart          ← Chat UI
  ├── models/
  │   └── knowledge_model.dart      ← Data models
  └── services/
      ├── ai_service.dart            ← AI response + knowledge save
      ├── trading_commands_service.dart ← Commands handler
      ├── tts_service.dart           ← Marathi/Hindi/English TTS
      ├── stt_service.dart           ← Speech recognition
      ├── database_service.dart      ← SQLite storage
      ├── ocr_service.dart           ← Image text extraction
      ├── screen_monitor_service.dart ← Screen analysis
      ├── market_analysis_service.dart ← Market data
      └── continuous_talk_service.dart ← Continuous mic

  ## Commands
  123    → Trading सुरू (Screen Monitor)
  2      → Save info
  25 2   → Buy/Sell %
  13 6   → Quick Buy/Sell decision
  3 2 1  → Trading बंद
  