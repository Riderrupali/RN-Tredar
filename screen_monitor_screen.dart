import 'dart:async';
  import 'package:flutter/material.dart';
  import 'package:flutter_overlay_window/flutter_overlay_window.dart';
  import '../services/tts_service.dart';
  import '../services/database_service.dart';

  class ScreenMonitorScreen extends StatefulWidget {
    const ScreenMonitorScreen({super.key});
    @override
    State<ScreenMonitorScreen> createState() => _ScreenMonitorScreenState();
  }

  class _ScreenMonitorScreenState extends State<ScreenMonitorScreen>
      with TickerProviderStateMixin {
    final TtsService _tts = TtsService.instance;

    // ── App selection ────────────────────────────────────
    final List<String> _tradingApps = [
      'Zerodha Kite', 'Upstox', 'Groww', 'Angel One', 'Kotak Neo',
      'HDFC Sky', 'Sharekhan', '5paisa', 'Paytm Money', 'Fyers',
    ];
    String? _selectedApp;
    final TextEditingController _customAppCtrl = TextEditingController();

    // ── Loading state ────────────────────────────────────
    bool _loading = false;
    int _loadProgress = 0; // 0-100
    Timer? _loadTimer;
    late AnimationController _candleAnim;

    @override
    void initState() {
      super.initState();
      _candleAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
        ..repeat(reverse: true);
      _requestOverlayPermission();
    }

    @override
    void dispose() {
      _loadTimer?.cancel();
      _candleAnim.dispose();
      _customAppCtrl.dispose();
      super.dispose();
    }

    Future<void> _requestOverlayPermission() async {
      if (!await FlutterOverlayWindow.isPermissionGranted()) {
        await FlutterOverlayWindow.requestPermission();
      }
    }

    void _addCustomApp() {
      final name = _customAppCtrl.text.trim();
      if (name.isEmpty) return;
      setState(() {
        _tradingApps.insert(0, name);
        _selectedApp = name;
        _customAppCtrl.clear();
      });
    }

    Future<void> _startTrading() async {
      if (_selectedApp == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('पहिले app select करा!'),
          backgroundColor: Color(0xFF9B59F5),
        ));
        return;
      }
      setState(() { _loading = true; _loadProgress = 0; });

      // Start screen share automatically
      _showOverlay();

      // 20-second loading
      _loadTimer = Timer.periodic(const Duration(milliseconds: 200), (t) {
        setState(() => _loadProgress += 1);
        if (_loadProgress >= 100) {
          t.cancel();
          _onLoadingComplete();
        }
      });
    }

    Future<void> _showOverlay() async {
      if (await FlutterOverlayWindow.isPermissionGranted()) {
        await FlutterOverlayWindow.showOverlay(
          enableDrag: true,
          height: 200,
          width: 80,
          alignment: OverlayAlignment.centerRight,
          flag: OverlayFlag.defaultFlag,
          overlayTitle: 'Trading',
          overlayContent: 'Code Magic Trading Active',
        );
      }
    }

    Future<void> _onLoadingComplete() async {
      await _tts.speak(_tts.language == AppLanguage.marathi
          ? '$_selectedApp मध्ये Trading सुरू! Screen Share चालू आहे.'
          : 'Trading started in $_selectedApp! Screen share is ON.');
      if (mounted) setState(() => _loading = false);
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0D1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A2E),
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Row(
            children: [
              Icon(Icons.phone_android, color: Color(0xFF3CE1C3), size: 22),
              SizedBox(width: 10),
              Text('Screen Monitor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.white38),
              onPressed: () => _showInfo(),
            ),
          ],
        ),
        body: _loading ? _buildLoadingScreen() : _buildSetupScreen(),
      );
    }

    // ── SETUP SCREEN ─────────────────────────────────────
    Widget _buildSetupScreen() {
      return Column(
        children: [
          // ── Top: Edit area ──────────────────────────────
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF9B59F5).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('✏️ App Add करा',
                  style: TextStyle(color: Color(0xFF9B59F5), fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customAppCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'App चे नाव टाका (उदा: Zerodha)',
                          hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                          filled: true,
                          fillColor: const Color(0xFF0D0D1A),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addCustomApp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C3CE1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── App list ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Trading App Select करा:',
                style: TextStyle(color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _tradingApps.length,
              itemBuilder: (ctx, i) {
                final app = _tradingApps[i];
                final selected = app == _selectedApp;
                return GestureDetector(
                  onTap: () => setState(() => _selectedApp = app),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF3CE1C3).withOpacity(0.12)
                          : const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? const Color(0xFF3CE1C3) : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.phone_android,
                            color: selected ? const Color(0xFF3CE1C3) : Colors.white38,
                            size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(app,
                            style: TextStyle(
                              color: selected ? const Color(0xFF3CE1C3) : Colors.white70,
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 15,
                            )),
                        ),
                        if (selected) const Icon(Icons.check_circle, color: Color(0xFF3CE1C3), size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Bottom: Start Trading button ─────────────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _startTrading,
                icon: const Icon(Icons.play_arrow_rounded, size: 28),
                label: const Text('Start Trading',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3CE1C3),
                  foregroundColor: const Color(0xFF0D0D1A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 8,
                  shadowColor: const Color(0xFF3CE1C3).withOpacity(0.5),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // ── LOADING SCREEN (20 seconds, candlestick animation) ─
    Widget _buildLoadingScreen() {
      return Stack(
        children: [
          // Background candlestick animation
          ..._buildCandleBackground(),
          // Overlay
          Container(
            color: const Color(0xFF0D0D1A).withOpacity(0.85),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated candlestick chart
                  _buildAnimatedCandles(),
                  const SizedBox(height: 32),
                  Text(
                    _selectedApp != null ? '$_selectedApp' : 'Trading',
                    style: const TextStyle(
                      color: Color(0xFF3CE1C3),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Trading data तयार होतेय...',
                    style: TextStyle(color: Colors.white70, fontSize: 15)),
                  const SizedBox(height: 24),
                  // Progress bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _loadProgress / 100,
                            minHeight: 8,
                            backgroundColor: const Color(0xFF1A1A2E),
                            valueColor: const AlwaysStoppedAnimation(Color(0xFF3CE1C3)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('$_loadProgress%',
                          style: const TextStyle(color: Color(0xFF3CE1C3), fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('📊 Knowledge base ready होतेय\n📈 Screen monitoring चालू\n🎤 Mic ready',
                    style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.8),
                    textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ],
      );
    }

    List<Widget> _buildCandleBackground() {
      return List.generate(8, (i) {
        return Positioned(
          left: 20.0 + (i * 42),
          bottom: 80,
          child: AnimatedBuilder(
            animation: _candleAnim,
            builder: (ctx, _) {
              final h = 60.0 + (i % 3) * 40 + _candleAnim.value * 30;
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 2,
                    height: h * 0.3,
                    color: i % 2 == 0
                        ? const Color(0xFF3CE1C3).withOpacity(0.3)
                        : const Color(0xFFE74C3C).withOpacity(0.3),
                  ),
                  Container(
                    width: 16,
                    height: h,
                    decoration: BoxDecoration(
                      color: i % 2 == 0
                          ? const Color(0xFF3CE1C3).withOpacity(0.4)
                          : const Color(0xFFE74C3C).withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      });
    }

    Widget _buildAnimatedCandles() {
      return AnimatedBuilder(
        animation: _candleAnim,
        builder: (ctx, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _candle(80, true, 0.8 + _candleAnim.value * 0.2),
              _candle(120, false, 1.0 - _candleAnim.value * 0.3),
              _candle(60, true, 0.6 + _candleAnim.value * 0.4),
              _candle(100, true, 0.9 + _candleAnim.value * 0.1),
              _candle(140, false, 1.0 - _candleAnim.value * 0.2),
            ],
          );
        },
      );
    }

    Widget _candle(double h, bool isBull, double scale) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.bottomCenter,
          child: Container(
            width: 18,
            height: h,
            decoration: BoxDecoration(
              color: isBull ? const Color(0xFF3CE1C3) : const Color(0xFFE74C3C),
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: (isBull ? const Color(0xFF3CE1C3) : const Color(0xFFE74C3C)).withOpacity(0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
      );
    }

    void _showInfo() {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text('Screen Monitor कसं वापरायचं?',
            style: TextStyle(color: Colors.white, fontSize: 16)),
          content: const Text(
            '1️⃣ Trading app select करा\n'
            '2️⃣ "Start Trading" दाबा\n'
            '3️⃣ 20 sec loading → data ready होतो\n'
            '4️⃣ Floating window येतो:\n'
            '   📱 Screen Share On/Off\n'
            '   🎤 Mic On/Off\n\n'
            '💡 "123" voice command → हे screen थेट उघडते!',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.7),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: Color(0xFF3CE1C3))),
            ),
          ],
        ),
      );
    }
  }
  