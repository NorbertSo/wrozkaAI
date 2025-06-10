import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import '../services/ai_vision_service.dart';
import 'ai_results_screen.dart';

class AIUploadScreen extends StatefulWidget {
  final String userName;
  final String userGender;
  final DateTime birthDate;
  final String dominantHand;
  final File palmImage;

  const AIUploadScreen({
    Key? key,
    required this.userName,
    required this.userGender,
    required this.birthDate,
    required this.dominantHand,
    required this.palmImage,
  }) : super(key: key);

  @override
  State<AIUploadScreen> createState() => _AIUploadScreenState();
}

class _AIUploadScreenState extends State<AIUploadScreen>
    with TickerProviderStateMixin {
  late AnimationController _uploadController;
  late AnimationController _particleController;
  late AnimationController _glowController;
  late Animation<double> _uploadAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _glowAnimation;

  bool _isUploading = false;
  bool _isAnalyzing = false;
  double _uploadProgress = 0.0;
  String _statusText = "Przygotowuję dane...";

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnalysis();
  }

  void _initAnimations() {
    _uploadController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _uploadAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _uploadController, curve: Curves.easeInOut));
    
    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(_particleController);
    
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0)
        .animate(_glowController);
  }

  Future<void> _startAnalysis() async {
    setState(() {
      _isUploading = true;
      _statusText = "Łączę się z mistycznymi energiami...";
    });

    // Symulacja etapów analizy
    await _simulateUploadSteps();
  }

  Future<void> _simulateUploadSteps() async {
    final steps = [
      "Przygotowuję zdjęcie dłoni...",
      "Analizuję linie palmarne...",
      "Łączę się z astrologiczną bazą danych...",
      "Obliczam pozycje planet...",
      "Interpretuję energetyczne wzorce...",
      "Przygotowuję personalną analizę...",
      "Finalizuję mistyczną interpretację..."
    ];

    for (int i = 0; i < steps.length; i++) {
      setState(() {
        _statusText = steps[i];
        _uploadProgress = (i + 1) / steps.length;
      });
      
      await Future.delayed(Duration(milliseconds: 800 + (i * 200)));
    }

    setState(() {
      _isUploading = false;
      _isAnalyzing = true;
      _statusText = "Analiza kompletna! Przygotowuję wyniki...";
    });

    // Wywołanie prawdziwego AI
    await _sendToAI();
  }

  Future<void> _sendToAI() async {
    try {
      // Użycie prawdziwego AI Vision Service
      final analysisResult = await AIVisionService.analyzePalm(
        palmImage: widget.palmImage,
        userName: widget.userName,
        birthDate: widget.birthDate,
        gender: widget.userGender,
        dominantHand: widget.dominantHand,
      );
      
      // Nawigacja do ekranu wyników z prawdziwą analizą
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AIResultsScreen(
              userName: widget.userName,
              analysisResult: analysisResult, // Tekst z AI
              palmImage: widget.palmImage,   // Zdjęcie dłoni
            ),
          ),
        );
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.deepPurple.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          "Błąd analizy",
          style: GoogleFonts.cinzelDecorative(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        content: const Text(
          "Nie udało się przeanalizować Twojej dłoni. Spróbuj ponownie.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Wróć do poprzedniego ekranu
            },
            child: const Text("OK", style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _uploadController.dispose();
    _particleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A0B3D),
              Color(0xFF2D1B5E),
              Color(0xFF1A0B3D),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animowane tło z gwiazdkami
            SizedBox.expand(
              child: Lottie.asset(
                'assets/animations/star_bg.json',
                fit: BoxFit.cover,
                repeat: true,
              ),
            ),

            // Mistyczne cząsteczki
            AnimatedBuilder(
              animation: _particleAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: MysticParticlesPainter(_particleAnimation.value),
                  size: Size.infinite,
                );
              },
            ),

            // Główna zawartość
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 60),

                    // Mistyczna ikona AI
                    AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.amber.withOpacity(_glowAnimation.value),
                                Colors.deepPurple.withOpacity(0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.psychology,
                            size: 60,
                            color: Colors.amber,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 40),

                    // Tytuł
                    Text(
                      "Analiza Mistyczna",
                      style: GoogleFonts.cinzelDecorative(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    Text(
                      "Odkrywam sekrety Twojej dłoni...",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade300,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 60),

                    // Pasek postępu
                    Container(
                      width: double.infinity,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.deepPurple.shade800,
                      ),
                      child: AnimatedBuilder(
                        animation: _uploadAnimation,
                        builder: (context, child) {
                          return Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: const LinearGradient(
                                colors: [
                                  Colors.amber,
                                  Colors.orange,
                                  Colors.deepOrange,
                                ],
                              ),
                            ),
                            child: LinearProgressIndicator(
                              value: _uploadProgress,
                              backgroundColor: Colors.transparent,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.transparent,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Tekst statusu
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: Text(
                        _statusText,
                        key: ValueKey(_statusText),
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.amber,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Postęp w procentach
                    Text(
                      "${(_uploadProgress * 100).toInt()}%",
                      style: GoogleFonts.cinzelDecorative(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const Spacer(),

                    // Podgląd dłoni
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          widget.palmImage,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      "Twoja dłoń jest analizowana przez najlepsze AI",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade400,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Painter dla mistycznych cząsteczek
class MysticParticlesPainter extends CustomPainter {
  final double animationValue;

  MysticParticlesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.amber.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 15; i++) {
      final x = (size.width * 0.1) + 
          (size.width * 0.8 * ((i * 0.1 + animationValue) % 1.0));
      final y = (size.height * 0.1) + 
          (size.height * 0.8 * ((i * 0.07 + animationValue * 0.5) % 1.0));
      
      final radius = 2.0 + (3.0 * ((animationValue + i * 0.1) % 1.0));
      
      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint..color = Colors.amber.withOpacity(
          0.3 + 0.4 * ((animationValue + i * 0.1) % 1.0)
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}