import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';

class AIResultsScreen extends StatefulWidget {
  final String userName;
  final String analysisResult;
  final File? palmImage;

  const AIResultsScreen({
    Key? key,
    required this.userName,
    required this.analysisResult,
    this.palmImage,
  }) : super(key: key);

  @override
  State<AIResultsScreen> createState() => _AIResultsScreenState();
}

class _AIResultsScreenState extends State<AIResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _particleController;
  late AnimationController _textController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _textAnimation;

  final ScrollController _scrollController = ScrollController();
  bool _showFloatingButton = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _setupScrollListener();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _textController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_particleController);

    _textAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutBack),
    );

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _textController.forward();
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final isScrolled = _scrollController.offset > 100;
      if (isScrolled != _showFloatingButton) {
        setState(() {
          _showFloatingButton = isScrolled;
        });
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _particleController.dispose();
    _textController.dispose();
    _scrollController.dispose();
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
            colors: [Color(0xFF1A0B3D), Color(0xFF2D1B5E), Color(0xFF1A0B3D)],
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
              child: Column(
                children: [
                  // Header z przyciskiem powrotu
                  _buildHeader(),

                  // Scrollowalna treść analizy
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _fadeAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeAnimation.value,
                          child: _buildAnalysisContent(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Floating action button - nowa analiza
            if (_showFloatingButton)
              Positioned(
                bottom: 30,
                right: 20,
                child: _buildFloatingNewAnalysisButton(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Przycisk powrotu
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.amber.withOpacity(0.3),
                width: 1,
              ),
              color: Colors.deepPurple.shade900.withOpacity(0.3),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.amber, size: 24),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          const Spacer(),

          // Tytuł
          Column(
            children: [
              Text(
                "Twoja Analiza",
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                widget.userName,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.amber.shade300,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Przycisk udostępniania
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.amber.withOpacity(0.3),
                width: 1,
              ),
              color: Colors.deepPurple.shade900.withOpacity(0.3),
            ),
            child: IconButton(
              icon: const Icon(Icons.share, color: Colors.amber, size: 24),
              onPressed: _shareAnalysis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisContent() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Obrazek dłoni (jeśli dostępny)
          if (widget.palmImage != null) _buildPalmImageCard(),

          const SizedBox(height: 20),

          // Karta z analizą
          AnimatedBuilder(
            animation: _textAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * _textAnimation.value),
                child: _buildAnalysisCard(),
              );
            },
          ),

          const SizedBox(height: 20),

          // Przycisk nowej analizy
          _buildNewAnalysisButton(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPalmImageCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepPurple.shade900.withOpacity(0.4),
            Colors.indigo.shade900.withOpacity(0.3),
          ],
        ),
        border: Border.all(color: Colors.amber.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "🖐️ Twoja Dłoń",
            style: GoogleFonts.cinzelDecorative(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.amber,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.amber.withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.2),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(widget.palmImage!, fit: BoxFit.cover),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepPurple.shade900.withOpacity(0.6),
            Colors.indigo.shade900.withOpacity(0.4),
            Colors.purple.shade900.withOpacity(0.5),
          ],
        ),
        border: Border.all(color: Colors.amber.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.15),
            blurRadius: 30,
            spreadRadius: 3,
          ),
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header karty
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.amber.withOpacity(0.8),
                      Colors.amber.withOpacity(0.2),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Mistyczna Analiza",
                      style: GoogleFonts.cinzelDecorative(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "Wygenerowano ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Divider z ornamentem
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.amber.withOpacity(0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "✨",
                  style: TextStyle(fontSize: 16, color: Colors.amber.shade300),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.amber.withOpacity(0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Treść analizy
          SelectableText(
            widget.analysisResult,
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Colors.grey.shade100,
              letterSpacing: 0.3,
            ),
          ),

          const SizedBox(height: 24),

          // Footer z ornamentem
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "🔮 ✨ 🌟 ✨ 🔮",
                style: TextStyle(fontSize: 18, color: Colors.amber.shade300),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNewAnalysisButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber.shade600,
            Colors.orange.shade600,
            Colors.deepOrange.shade600,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _startNewAnalysis,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.refresh, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  "Nowa Analiza",
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingNewAnalysisButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: FloatingActionButton.extended(
        onPressed: _startNewAnalysis,
        backgroundColor: Colors.amber.shade600,
        foregroundColor: Colors.white,
        elevation: 8,
        label: Text(
          "Nowa Analiza",
          style: GoogleFonts.cinzelDecorative(fontWeight: FontWeight.w600),
        ),
        icon: const Icon(Icons.refresh),
      ),
    );
  }

  void _shareAnalysis() {
    // Implementacja udostępniania analizy
    final textToShare =
        '''
🔮 Mistyczna Analiza Dłoni dla ${widget.userName} 🔮

${widget.analysisResult}

---
Wygenerowano przez AI Wróżka
''';

    // Tu można dodać package share_plus lub systemowe udostępnianie
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.deepPurple.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Udostępnij Analizę",
          style: GoogleFonts.cinzelDecorative(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        content: const Text(
          "Skopiowano analizę do schowka! Możesz ją teraz wkleić gdzie chcesz.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK", style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  void _startNewAnalysis() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.deepPurple.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Nowa Analiza",
          style: GoogleFonts.cinzelDecorative(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        content: const Text(
          "Czy chcesz rozpocząć nową analizę dłoni? Obecne wyniki zostaną utracone.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Anuluj", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Zamknij dialog
              // Wróć do głównego ekranu aplikacji
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text(
              "Rozpocznij",
              style: TextStyle(color: Colors.amber),
            ),
          ),
        ],
      ),
    );
  }
}

// Painter dla mistycznych cząsteczek (kopiowany z poprzednich ekranów)
class MysticParticlesPainter extends CustomPainter {
  final double animationValue;

  MysticParticlesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.amber.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 20; i++) {
      final x =
          (size.width * 0.1) +
          (size.width * 0.8 * ((i * 0.1 + animationValue) % 1.0));
      final y =
          (size.height * 0.1) +
          (size.height * 0.8 * ((i * 0.07 + animationValue * 0.3) % 1.0));

      final radius = 1.5 + (2.5 * ((animationValue + i * 0.1) % 1.0));

      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint
          ..color = Colors.amber.withOpacity(
            0.2 + 0.3 * ((animationValue + i * 0.1) % 1.0),
          ),
      );
    }

    // Dodatkowe większe cząsteczki
    for (int i = 0; i < 8; i++) {
      final x =
          size.width * 0.2 +
          (size.width * 0.6 * ((i * 0.15 + animationValue * 0.5) % 1.0));
      final y =
          size.height * 0.2 +
          (size.height * 0.6 * ((i * 0.11 + animationValue * 0.4) % 1.0));

      final radius = 2.0 + (4.0 * ((animationValue * 0.7 + i * 0.1) % 1.0));

      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint
          ..color = Colors.purple.withOpacity(
            0.1 + 0.2 * ((animationValue * 0.8 + i * 0.1) % 1.0),
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
