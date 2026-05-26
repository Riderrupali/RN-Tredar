import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ocr_service.dart';
import '../services/screen_monitor_service.dart';
import '../services/tts_service.dart';
import '../services/database_service.dart';
import '../models/knowledge_model.dart';

class ScreenReadScreen extends StatefulWidget {
  const ScreenReadScreen({super.key});

  @override
  State<ScreenReadScreen> createState() => _ScreenReadScreenState();
}

class _ScreenReadScreenState extends State<ScreenReadScreen> {
  final OcrService _ocr = OcrService.instance;
  final ScreenMonitorService _monitor = ScreenMonitorService.instance;
  final TtsService _tts = TtsService.instance;
  final TextEditingController _pasteCtrl = TextEditingController();

  String _ocrText = '';
  String _aiResponse = '';
  bool _isProcessing = false;
  int _savedCount = 0;

  String get _lang {
    switch (_tts.language) {
      case AppLanguage.hindi:   return 'hindi';
      case AppLanguage.marathi: return 'marathi';
      default:                  return 'english';
    }
  }

  @override
  void dispose() {
    _pasteCtrl.dispose();
    super.dispose();
  }

  Future<void> _analyzeImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked == null) return;

      setState(() { _isProcessing = true; _aiResponse = ''; });
      final text = await _ocr.extractTextFromPath(picked.path);
      await _runAnalysis(text);
    } catch (e) {
      setState(() => _isProcessing = false);
      _showSnack('Image read करताना error: $e');
    }
  }

  Future<void> _analyzeText(String text) async {
    if (text.trim().isEmpty) {
      _showSnack(_lang == 'marathi'
          ? 'काहीतरी paste करा'
          : 'Please paste some text first');
      return;
    }
    setState(() { _isProcessing = true; _aiResponse = ''; _ocrText = text; });
    await _runAnalysis(text);
  }

  Future<void> _runAnalysis(String text) async {
    setState(() => _ocrText = text);
    try {
      final response = await _monitor.analyzeScreenText(text, _lang);
      setState(() {
        _aiResponse = response;
        _isProcessing = false;
      });
      if (response.isNotEmpty) await _tts.speak(response);
    } catch (e) {
      setState(() {
        _aiResponse = 'Analysis error. Please try again.';
        _isProcessing = false;
      });
    }
  }

  // Save OCR text to knowledge for future use
  Future<void> _saveToKnowledge() async {
    if (_ocrText.isEmpty) return;
    final topic = 'Screen Capture ${DateTime.now().toString().substring(0, 16)}';
    await DatabaseService.instance.saveKnowledge(KnowledgeItem(
      topic: topic,
      content: _ocrText,
      appName: 'Trading Screen',
      createdAt: DateTime.now(),
    ));
    setState(() => _savedCount++);
    _showSnack(_lang == 'marathi'
        ? '✅ Screen माहिती save झाली!'
        : '✅ Screen info saved to knowledge!');
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Row(
          children: [
            Icon(Icons.trending_up, color: Color(0xFF3CE1C3), size: 20),
            SizedBox(width: 8),
            Text('Trading Analysis',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_ocrText.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.save_outlined, color: Color(0xFF3CE1C3)),
              tooltip: 'Knowledge मध्ये save करा',
              onPressed: _saveToKnowledge,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 16),
            _buildImageButtons(),
            const SizedBox(height: 16),
            _buildPasteSection(),
            if (_isProcessing) ...[
              const SizedBox(height: 30),
              _buildAnalyzingIndicator(),
            ],
            if (!_isProcessing && _aiResponse.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildResultCard(),
            ],
            if (!_isProcessing && _ocrText.isNotEmpty && _aiResponse.isEmpty)
              _buildOcrRaw(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3CE1C3).withOpacity(0.1),
            const Color(0xFF6C3CE1).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3CE1C3).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFF3CE1C3), size: 18),
              SizedBox(width: 8),
              Text('कसं वापरायचं:',
                  style: TextStyle(
                      color: Color(0xFF3CE1C3), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          _tip('📸', 'Trading app चा screenshot gallery मधून upload करा'),
          _tip('📷', 'Camera ने थेट trading screen चा photo काढा'),
          _tip('📋', 'Trading info paste करा → Analysis मिळवा'),
          _tip('💾', 'Analysis save करा → पुढच्या वेळी वापरता येईल'),
        ],
      ),
    );
  }

  Widget _tip(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style:
                    const TextStyle(color: Colors.white60, fontSize: 12, height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildImageButtons() {
    return Row(
      children: [
        Expanded(
          child: _imgBtn(
            icon: Icons.photo_library_outlined,
            label: '📁 Gallery\nमधून',
            color: const Color(0xFF6C3CE1),
            onTap: () => _analyzeImage(ImageSource.gallery),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _imgBtn(
            icon: Icons.camera_alt_outlined,
            label: '📷 Camera\nने',
            color: const Color(0xFF3CE1C3),
            onTap: () => _analyzeImage(ImageSource.camera),
          ),
        ),
      ],
    );
  }

  Widget _imgBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(color: color, fontSize: 13, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildPasteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('📋 Trading Data Paste करा:',
            style: TextStyle(
                color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF6C3CE1).withOpacity(0.3)),
          ),
          child: TextField(
            controller: _pasteCtrl,
            maxLines: 5,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: _lang == 'marathi'
                  ? 'RSI: 65, Price: 22450, Trend: Uptrend...\n'
                    'किंवा trading app मधील कोणताही text paste करा'
                  : 'RSI: 65, Price: 22450, Trend: Uptrend...\n'
                    'Or paste any trading data here',
              hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C3CE1),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _analyzeText(_pasteCtrl.text),
            icon: const Icon(Icons.analytics_outlined, color: Colors.white),
            label: Text(
              _lang == 'marathi' ? '📈 Analysis करा' : '📈 Analyze',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzingIndicator() {
    return Center(
      child: Column(
        children: [
          const CircularProgressIndicator(color: Color(0xFF3CE1C3)),
          const SizedBox(height: 12),
          Text(
            _lang == 'marathi'
                ? 'Trading analysis करतोय...'
                : 'Analyzing trading data...',
            style: const TextStyle(color: Color(0xFF3CE1C3), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final isUp = _aiResponse.contains('📈') || _aiResponse.contains('वर जाण्याची') || _aiResponse.contains('ऊपर');
    final isDown = _aiResponse.contains('📉') || _aiResponse.contains('खाली जाण्याची') || _aiResponse.contains('नीचे');

    final cardColor = isUp
        ? const Color(0xFF1A3A1A)
        : isDown
            ? const Color(0xFF3A1A1A)
            : const Color(0xFF1A1A2E);
    final borderColor = isUp
        ? const Color(0xFF3CE1C3)
        : isDown
            ? Colors.redAccent
            : const Color(0xFF9B59F5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🤖 Code Magic Analysis:',
            style: TextStyle(
                color: Color(0xFF3CE1C3), fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor.withOpacity(0.6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _aiResponse,
                style: const TextStyle(
                    color: Colors.white, fontSize: 15, height: 1.6),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _tts.speak(_aiResponse),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.volume_up, color: Color(0xFF3CE1C3), size: 18),
                            SizedBox(width: 6),
                            Text('पुन्हा ऐका',
                                style: TextStyle(color: Color(0xFF3CE1C3), fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: _saveToKnowledge,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save_outlined, color: Color(0xFF9B59F5), size: 18),
                            SizedBox(width: 6),
                            Text('Save करा',
                                style: TextStyle(color: Color(0xFF9B59F5), fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOcrRaw() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('📱 OCR ने वाचलेला text:',
            style: TextStyle(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(_ocrText,
              style: const TextStyle(
                  color: Colors.white60, fontSize: 12, height: 1.5)),
        ),
      ],
    );
  }
}
