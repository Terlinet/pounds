import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

// --- Ponte JS Interop (Assumindo que o ambiente Web terá esses métodos) ---
@JS('initPoseDetector')
external JSPromise<JSBoolean> _initPoseDetector();

@JS('startCamera')
external JSPromise<JSBoolean> _startCamera(JSString facingMode);

@JS('stopCamera')
external void _stopCamera();

@JS('setPoseCallback')
external void _setPoseCallback(JSFunction callback);

@JS('captureFrame')
external JSString _captureFrame();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TerlineTPoundsApp());
}

class TerlineTPoundsApp extends StatelessWidget {
  const TerlineTPoundsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TerlineT Pounds',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF9B59B6), // Roxo para Libras/Acessibilidade
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late VideoPlayerController _videoController;
  List<dynamic> _landmarks = [];
  bool _isCameraReady = false;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
    _setupTracking();
  }

  void _initVideo() {
    _videoController = VideoPlayerController.asset("assets/videos/gesture.mp4")
      ..initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
        });
        _videoController.setLooping(true);
        _videoController.setVolume(0); // Silencioso para fundo
        _videoController.play();
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _stopCamera();
    super.dispose();
  }

  Future<void> _setupTracking() async {
    try {
      _setPoseCallback(_onPoseDetected.toJS);
      final initSuccess = await _initPoseDetector().toDart;
      if (initSuccess.toDart) {
        final started = await _startCamera("user".toJS).toDart;
        if (started.toDart) {
          setState(() => _isCameraReady = true);
        }
      }
    } catch (e) {
      debugPrint("Erro Tracking Home: $e");
    }
  }

  void _onPoseDetected(JSString landmarksJson) {
    if (!mounted) return;
    try {
      final List<dynamic> newLandmarks = jsonDecode(landmarksJson.toDart);
      setState(() {
        _landmarks = newLandmarks;
      });
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Vídeo de Fundo
          if (_isVideoInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            ),

          // Overlay de Gradiente para legibilidade
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  const Color(0xFF0F172A).withOpacity(0.9),
                ],
              ),
            ),
          ),

          SingleChildScrollView(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
                child: Column(
                  children: [
                    _buildCyberHandsIcon(),
                    const SizedBox(height: 20),
                    const Text("🫶🏽", style: TextStyle(fontSize: 50)),
                    const SizedBox(height: 10),
                    Text("TERLINET POUNDS",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.orbitron(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8,
                            color: const Color(0xFF9B59B6))),
                    const Text("TRADUTOR DE LIBRAS COM IA",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, letterSpacing: 4)),
                    const SizedBox(height: 60),

                    Wrap(
                      spacing: 25,
                      runSpacing: 25,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildFeatureCard(
                          icon: Icons.sign_language,
                          title: "LEITURA GESTUAL",
                          description: "Mapeamento neural de mãos e expressões faciais em tempo real.",
                        ),
                        _buildFeatureCard(
                          icon: Icons.translate,
                          title: "TRADUÇÃO LIBRAS",
                          description: "Conversão instantânea de sinais para texto e voz em Português.",
                        ),
                        _buildFeatureCard(
                          icon: Icons.record_voice_over,
                          title: "SÍNTESE VOCAL",
                          description: "IA que dita os sinais traduzidos para facilitar a comunicação.",
                        ),
                      ],
                    ),

                    const SizedBox(height: 60),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9B59B6),
                        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 25),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 15,
                        shadowColor: const Color(0xFF9B59B6).withOpacity(0.4),
                      ),
                      onPressed: () {
                        _stopCamera();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const InterpreterPage()),
                        ).then((_) => _setupTracking());
                      },
                      child: const Text("INICIAR TRADUÇÃO",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18, letterSpacing: 2)),
                    ),
                    const SizedBox(height: 40),
                    _buildSecurityInfo(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCyberHandsIcon() {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF9B59B6), width: 2),
        boxShadow: [
          BoxShadow(color: const Color(0xFF9B59B6).withOpacity(0.2), blurRadius: 20, spreadRadius: 5),
        ],
      ),
      child: const Icon(Icons.sign_language, size: 80, color: Color(0xFF9B59B6)),
    );
  }

  Widget _buildFeatureCard({required IconData icon, required String title, required String description}) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF9B59B6), size: 40),
          const SizedBox(height: 20),
          Text(title, style: GoogleFonts.orbitron(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Text(description, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildSecurityInfo() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(10)),
      child: const Text("PROCESSAMENTO LOCAL & PRIVADO: Sua imagem não sai do dispositivo.",
          style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 1)),
    );
  }
}

class InterpreterPage extends StatefulWidget {
  const InterpreterPage({super.key});

  @override
  State<InterpreterPage> createState() => _InterpreterPageState();
}

class _InterpreterPageState extends State<InterpreterPage> with TickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  List<dynamic> _landmarks = [];
  String _currentTranslation = "Aguardando sinal...";
  String _detectedWord = "";
  bool _isSpeaking = false;
  bool _isProcessing = false;
  Timer? _translationTimer;

  // Animações
  late AnimationController _scannerController;

  @override
  void initState() {
    super.initState();
    _scannerController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _initTts().then((_) => _speakIntroduction());
    _setupPoseDetection();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("pt-BR");
    await _tts.setSpeechRate(0.9);
    await _tts.setPitch(1.0);
    _tts.setStartHandler(() => setState(() => _isSpeaking = true));
    _tts.setCompletionHandler(() => setState(() => _isSpeaking = false));
  }

  Future<void> _speakIntroduction() async {
    try {
      final response = await http.get(
        Uri.parse("https://tertulianoshow-terlinet-pounds.hf.space/explain_system")
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final text = jsonDecode(response.body)['message'];
        setState(() => _currentTranslation = text);
        await _tts.speak(text);
      }
    } catch (e) {
      debugPrint("Erro IA Intro: $e");
    }
  }

  Future<void> _setupPoseDetection() async {
    _setPoseCallback(_onPoseDetected.toJS);
    await _initPoseDetector().toDart;
    await _startCamera("user".toJS).toDart;
  }

  void _onPoseDetected(JSString landmarksJson) {
    if (!mounted) return;
    final List<dynamic> landmarks = jsonDecode(landmarksJson.toDart);
    setState(() => _landmarks = landmarks);

    // Lógica simplificada de interpretação
    _processLibras(landmarks);
  }

  void _processLibras(List<dynamic> landmarks) {
    if (_isProcessing || landmarks.isEmpty) return;

    String? newWord;

    // Landmark 0 (Nose), 15 (Left Wrist), 16 (Right Wrist) do MediaPipe Pose
    if (landmarks.length > 20) {
      final noseY = landmarks[0]['y'] as num;
      final lWristY = landmarks[15]['y'] as num;
      final rWristY = landmarks[16]['y'] as num;

      if (lWristY < noseY && rWristY < noseY) {
        newWord = "Olá";
      } else if (lWristY > 0.6 && rWristY > 0.6 && (lWristY - rWristY).abs() < 0.1) {
        newWord = "Tudo bem?";
      }
    }

    if (newWord != null && newWord != _detectedWord) {
      _detectedWord = newWord;
      _callBackendTranslation(newWord);
    }
  }

  Future<void> _callBackendTranslation(String gesture) async {
    setState(() {
      _isProcessing = true;
      _currentTranslation = "Traduzindo...";
    });

    try {
      final response = await http.post(
        Uri.parse("https://tertulianoshow-terlinet-pounds.hf.space/interpret_gesture"),
        body: jsonEncode({"area_name": "Camera Principal", "object_type": gesture}),
        headers: {"Content-Type": "application/json"},
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final msg = jsonDecode(response.body)['message'];
        setState(() => _currentTranslation = msg);
        await _tts.speak(msg);
      } else {
        await _speakTranslation(gesture);
      }
    } catch (e) {
      await _speakTranslation(gesture);
    } finally {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _isProcessing = false);
      });
    }
  }

  Future<void> _speakTranslation(String text) async {
    setState(() {
      _currentTranslation = text;
    });

    await _tts.speak(text);
  }

  @override
  void dispose() {
    _stopCamera();
    _scannerController.dispose();
    _translationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Visualizador de Câmera (CustomPaint desenhando landmarks)
          if (_landmarks.isNotEmpty)
            CustomPaint(painter: LibrasPainter(_landmarks), size: Size.infinite),

          // Efeito de Scanner
          AnimatedBuilder(
            animation: _scannerController,
            builder: (context, child) {
              return Positioned(
                top: _scannerController.value * MediaQuery.of(context).size.height,
                left: 0, right: 0,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF9B59B6).withOpacity(0.5), blurRadius: 10, spreadRadius: 2),
                    ],
                  ),
                ),
              );
            },
          ),

          // Interface HUD
          Positioned(
            top: 50, left: 20, right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF9B59B6)),
                  ),
                  child: const Text("IA MAPPING ACTIVE", style: TextStyle(color: Color(0xFF9B59B6), fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),

          // Área de Tradução (Legenda)
          Positioned(
            bottom: 60, left: 20, right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0xFF9B59B6).withOpacity(0.5)),
                    boxShadow: [BoxShadow(color: const Color(0xFF9B59B6).withOpacity(0.2), blurRadius: 15)],
                  ),
                  child: Column(
                    children: [
                      Text("TRADUÇÃO EM TEMPO REAL",
                        style: GoogleFonts.vt323(color: const Color(0xFF9B59B6), fontSize: 14, letterSpacing: 2)),
                      const SizedBox(height: 10),
                      Text(_currentTranslation,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.orbitron(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                if (_isSpeaking)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Icon(Icons.volume_up, color: Color(0xFF9B59B6), size: 30),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LibrasPainter extends CustomPainter {
  final List<dynamic> landmarks;
  LibrasPainter(this.landmarks);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF9B59B6)..style = PaintingStyle.fill;
    final linePaint = Paint()..color = const Color(0xFF9B59B6).withOpacity(0.3)..strokeWidth = 1;

    for (var i = 0; i < landmarks.length; i++) {
      final lm = landmarks[i];
      if (lm['visibility'] > 0.5) {
        // Assume câmera frontal invertida
        double x = (1.0 - (lm['x'] as num).toDouble()) * size.width;
        double y = (lm['y'] as num).toDouble() * size.height;

        canvas.drawCircle(Offset(x, y), 3, paint);
      }
    }

    // Desenha algumas conexões básicas (Skeleton)
    // Simplificado para este exemplo
  }

  @override
  bool shouldRepaint(LibrasPainter oldDelegate) => true;
}
