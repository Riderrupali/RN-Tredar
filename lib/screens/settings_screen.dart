import 'package:flutter/material.dart';
  import 'package:image_picker/image_picker.dart';
  import 'dart:io';
  import '../services/tts_service.dart';

  class SettingsScreen extends StatefulWidget {
    const SettingsScreen({super.key});
    @override
    State<SettingsScreen> createState() => _SettingsScreenState();
  }

  class _SettingsScreenState extends State<SettingsScreen> {
    final TtsService _tts = TtsService.instance;

    // Theme — simple static (no shared_preferences needed)
    static String? _customThemeImagePath;
    static bool _useCustomTheme = false;

    Future<void> _pickThemeImage() async {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      setState(() {
        _customThemeImagePath = picked.path;
        _useCustomTheme = true;
      });
    }

    void _resetTheme() => setState(() {
      _useCustomTheme = false;
      _customThemeImagePath = null;
    });

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0D1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text('Settings', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _sectionTitle('🌐 Language / भाषा'),
            const SizedBox(height: 12),
            _languageSelector(),
            const SizedBox(height: 24),
            _sectionTitle('🎙️ Voice Type'),
            const SizedBox(height: 12),
            _voiceSelector(),
            const SizedBox(height: 24),
            _sectionTitle('🎨 Theme'),
            const SizedBox(height: 12),
            _themeSection(),
            const SizedBox(height: 24),
            _sectionTitle('🔇 Mute'),
            const SizedBox(height: 12),
            _muteRow(),
            const SizedBox(height: 24),
            _sectionTitle('ℹ️ Commands'),
            const SizedBox(height: 12),
            _commandsSection(),
          ],
        ),
      );
    }

    Widget _sectionTitle(String t) => Text(t,
        style: const TextStyle(color: Colors.white60, fontSize: 13,
            fontWeight: FontWeight.w600, letterSpacing: 0.5));

    Widget _languageSelector() {
      return StatefulBuilder(builder: (ctx, setS) {
        return Row(children: AppLanguage.values.map((lang) {
          final selected = _tts.language == lang;
          final label = lang == AppLanguage.marathi ? '🇮🇳 Marathi'
              : lang == AppLanguage.hindi ? '🇮🇳 Hindi' : '🇬🇧 English';
          return Expanded(
            child: GestureDetector(
              onTap: () async { await _tts.setLanguage(lang); setS(() {}); setState(() {}); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF6C3CE1) : const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: selected ? const Color(0xFF9B59F5) : Colors.transparent),
                ),
                child: Center(child: Text(label,
                    style: TextStyle(
                        color: selected ? Colors.white : Colors.white54, fontSize: 13))),
              ),
            ),
          );
        }).toList());
      });
    }

    Widget _voiceSelector() {
      return StatefulBuilder(builder: (ctx, setS) => Column(children: [
        _voiceRow('Female 🔊', 'female', setS),
        const SizedBox(height: 8),
        _voiceRow('Male 🔊', 'male', setS),
      ]));
    }

    Widget _voiceRow(String label, String type, StateSetter setS) {
      final selected = _tts.voiceType == type;
      return GestureDetector(
        onTap: () async { await _tts.setVoiceType(type); setS(() {}); },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF6C3CE1).withOpacity(0.2) : const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? const Color(0xFF9B59F5) : Colors.transparent),
          ),
          child: Row(children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: selected ? const Color(0xFF9B59F5) : Colors.white38, size: 20),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(
                color: selected ? Colors.white : Colors.white54, fontSize: 14)),
          ]),
        ),
      );
    }

    Widget _themeSection() {
      return Column(children: [
        // Default trading theme
        GestureDetector(
          onTap: _resetTheme,
          child: Container(
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFF0D0D1A), Color(0xFF1A1A2E), Color(0xFF2D1B69)],
              ),
              border: Border.all(
                color: !_useCustomTheme ? const Color(0xFF3CE1C3) : Colors.transparent, width: 2),
            ),
            child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.trending_up, color: Color(0xFF3CE1C3), size: 26),
              const SizedBox(height: 4),
              const Text('Default Trading Theme', style: TextStyle(color: Colors.white70, fontSize: 12)),
              if (!_useCustomTheme)
                const Text('✅ Active', style: TextStyle(color: Color(0xFF3CE1C3), fontSize: 11)),
            ])),
          ),
        ),
        const SizedBox(height: 12),
        // Custom image from gallery
        GestureDetector(
          onTap: _pickThemeImage,
          child: Container(
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFF1A1A2E),
              border: Border.all(
                color: _useCustomTheme ? const Color(0xFF9B59F5) : Colors.white24,
                width: _useCustomTheme ? 2 : 1),
              image: (_useCustomTheme && _customThemeImagePath != null &&
                  File(_customThemeImagePath!).existsSync())
                  ? DecorationImage(
                      image: FileImage(File(_customThemeImagePath!)),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.4), BlendMode.darken))
                  : null,
            ),
            child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.add_photo_alternate_outlined,
                  color: _useCustomTheme ? const Color(0xFF9B59F5) : Colors.white38, size: 26),
              const SizedBox(height: 4),
              Text(_useCustomTheme ? '✅ Custom Theme Active' : 'Gallery मधून Photo Add करा',
                  style: TextStyle(
                      color: _useCustomTheme ? const Color(0xFF9B59F5) : Colors.white38,
                      fontSize: 12)),
            ])),
          ),
        ),
      ]);
    }

    Widget _muteRow() {
      return StatefulBuilder(builder: (ctx, setS) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(_tts.isMuted ? Icons.volume_off : Icons.volume_up,
              color: _tts.isMuted ? Colors.redAccent : const Color(0xFF9B59F5)),
          const SizedBox(width: 12),
          Expanded(child: Text(_tts.isMuted ? 'Muted' : 'Voice Active',
              style: const TextStyle(color: Colors.white70, fontSize: 14))),
          Switch(
            value: !_tts.isMuted,
            activeColor: const Color(0xFF9B59F5),
            onChanged: (_) { _tts.toggleMute(); setS(() {}); },
          ),
        ]),
      ));
    }

    Widget _commandsSection() {
      const cmds = [
        ('123', 'Trading सुरू करा → Screen Monitor'),
        ('2', 'माहिती save करा'),
        ('25 2', 'Buy/Sell percentage पाहा'),
        ('13 6', 'Quick Buy/Sell decision (1 sec)'),
        ('3 2 1', 'Trading बंद करा'),
      ];
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: cmds.map((c) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C3CE1),
                  borderRadius: BorderRadius.circular(8)),
                child: Text(c.$1, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(c.$2, style: const TextStyle(color: Colors.white60, fontSize: 12))),
            ]),
          )).toList(),
        ),
      );
    }
  }
  
