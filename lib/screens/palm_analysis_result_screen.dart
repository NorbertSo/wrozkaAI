// lib/screens/palm_analysis_screen.dart
// NOWY PIĘKNY EKRAN WYNIKÓW ANALIZY DŁONI

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:math' as math;
import '../utils/constants.dart';
import '../models/palm_analysis.dart';
import '../services/logging_service.dart';
import '../services/ai_palm_analysis_service.dart';
import '../services/fortune_history_service.dart';
import 'main_menu_screen.dart';

class PalmAnalysisScreen extends StatefulWidget {
  final String userName;
  final String userGender;
  final PalmAnalysis? palmData;
  final PalmAnalysisResult? analysisResult;

  const PalmAnalysisScreen({
    super.key,
    required this.userName,
    required this.userGender,
    this.palmData,
    this.analysisResult,
  });

  @override
  State<PalmAnalysisScreen> createState() => _PalmAnalysisScreenState();
}

class _PalmAnalysisScreenState extends State<PalmAnalysisScreen>
    with TickerProviderStateMixin {
  final LoggingService _loggingService = LoggingService();
  final FortuneHistoryService _historyService = FortuneHistoryService();
  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();

  // ===== ANIMACJE =====
  late AnimationController _fadeController;
  late AnimationController _mysticalController;
  late AnimationController _sectionController;
  late AnimationController _glowController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _mysticalAnimation;
  late Animation<double> _glowAnimation;

  // ===== STAN =====
  int _currentSection = 0;
  bool _showScrollIndicator = true;
  List<FortuneSection> _fortuneSections = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _parseFortuneText();
    _startAnimations();
    _saveFortuneToHistory();
    _loggingService.logToConsole('Wyświetlenie wyników analizy',
        tag: 'RESULTS');
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _mysticalController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _sectionController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _mysticalAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mysticalController, curve: Curves.linear),
    );

    _glowAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() {
    _fadeController.forward();

    // Auto-hide scroll indicator
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showScrollIndicator = false);
      }
    });
  }

  void _parseFortuneText() {
    String fortuneText = '';

    if (widget.analysisResult?.analysisText != null) {
      fortuneText = widget.analysisResult!.analysisText;
    } else if (widget.palmData != null) {
      fortuneText =
          'Analiza dłoni na podstawie starożytnych metod chiromancji.';
    } else {
      fortuneText = 'Brak danych do analizy.';
      return;
    }

    // Parse sections with emojis and structure
    _fortuneSections = _extractSections(fortuneText);
  }

  List<FortuneSection> _extractSections(String text) {
    final sections = <FortuneSection>[];

    // Default sections if parsing fails
    if (!text.contains('🌟') && !text.contains('💖')) {
      sections.add(FortuneSection(
        title: 'Twoja Wróżba',
        icon: '🔮',
        content: text,
        color: AppColors.cyan,
      ));
      return sections;
    }

    // Parse structured fortune text
    final sectionPatterns = [
      {
        'pattern': r'🌟.*?OSOBOWOŚĆ',
        'title': 'Natura i Osobowość',
        'icon': '🌟',
        'color': AppColors.cyan
      },
      {
        'pattern': r'💖.*?ZWIĄZKI',
        'title': 'Miłość i Związki',
        'icon': '💖',
        'color': Colors.pink
      },
      {
        'pattern': r'🚀.*?SUKCES',
        'title': 'Kariera i Sukces',
        'icon': '🚀',
        'color': Colors.orange
      },
      {
        'pattern': r'💰.*?ASPEKTY',
        'title': 'Finanse',
        'icon': '💰',
        'color': Colors.green
      },
      {
        'pattern': r'🌿.*?ŻYCIOWA',
        'title': 'Zdrowie',
        'icon': '🌿',
        'color': Colors.lightGreen
      },
      {
        'pattern': r'🔮.*?MIESIĄCE',
        'title': 'Najbliższe Miesiące',
        'icon': '🔮',
        'color': Colors.purple
      },
      {
        'pattern': r'✨.*?PRZESŁANIE',
        'title': 'Specjalne Przesłanie',
        'icon': '✨',
        'color': Colors.amber
      },
    ];

    final lines = text.split('\n');
    String currentTitle = '';
    String currentIcon = '🔮';
    Color currentColor = AppColors.cyan;
    List<String> currentContent = [];

    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // Check if line starts a new section
      bool isNewSection = false;
      for (var pattern in sectionPatterns) {
        if (RegExp(pattern['pattern'] as String, caseSensitive: false)
            .hasMatch(line.toUpperCase())) {
          // Save previous section
          if (currentTitle.isNotEmpty && currentContent.isNotEmpty) {
            sections.add(FortuneSection(
              title: currentTitle,
              icon: currentIcon,
              content: currentContent.join('\n\n'),
              color: currentColor,
            ));
          }

          // Start new section
          currentTitle = pattern['title'] as String;
          currentIcon = pattern['icon'] as String;
          currentColor = pattern['color'] as Color;
          currentContent = [];
          isNewSection = true;
          break;
        }
      }

      if (!isNewSection &&
          !line.startsWith('🌟') &&
          !line.startsWith('💖') &&
          !line.startsWith('🚀') &&
          !line.startsWith('💰') &&
          !line.startsWith('🌿') &&
          !line.startsWith('🔮') &&
          !line.startsWith('✨')) {
        currentContent.add(line);
      }
    }

    // Add last section
    if (currentTitle.isNotEmpty && currentContent.isNotEmpty) {
      sections.add(FortuneSection(
        title: currentTitle,
        icon: currentIcon,
        content: currentContent.join('\n\n'),
        color: currentColor,
      ));
    }

    // Fallback if no sections found
    if (sections.isEmpty) {
      sections.add(FortuneSection(
        title: 'Twoja Wróżba',
        icon: '🔮',
        content: text,
        color: AppColors.cyan,
      ));
    }

    return sections;
  }

  Future<void> _saveFortuneToHistory() async {
    try {
      if (widget.analysisResult != null && widget.analysisResult!.isSuccess) {
        await _historyService.saveFortuneFromAnalysis(
          widget.analysisResult!,
          widget.userName,
          widget.userGender,
        );
        print('✅ Wróżba zapisana do historii');
      }
    } catch (e) {
      print('❌ Błąd zapisywania do historii: $e');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _mysticalController.dispose();
    _sectionController.dispose();
    _glowController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_fortuneSections.isEmpty) {
      return _buildNoDataScreen();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildMysticalBackground(),
          _buildContent(),
          if (_showScrollIndicator) _buildScrollIndicator(),
        ],
      ),
    );
  }

  Widget _buildMysticalBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.5,
          colors: [
            Color(0xFF0D1B2A),
            Color(0xFF1B263B),
            Color(0xFF000000),
          ],
        ),
      ),
      child: AnimatedBuilder(
        animation: _mysticalAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: EnhancedMysticalPainter(_mysticalAnimation.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    return SafeArea(
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _buildSectionsView(),
                ),
                _buildActionButtons(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withOpacity(0.85),
            Colors.black.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.cyan.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withOpacity(0.15),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _mysticalAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _mysticalAnimation.value * 2 * math.pi,
                    child: Icon(
                      Icons.auto_awesome,
                      color: AppColors.cyan,
                      size: 24,
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Text(
                'TWOJA WRÓŻBA',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 24,
                  color: AppColors.cyan,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(width: 12),
              AnimatedBuilder(
                animation: _mysticalAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: -_mysticalAnimation.value * 2 * math.pi,
                    child: Icon(
                      Icons.auto_awesome,
                      color: AppColors.cyan,
                      size: 24,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Drogi${widget.userGender == 'female' ? 'a' : (widget.userGender == 'other' ? '/a' : '')} ${widget.userName}',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Oto mistyczne odkrycia z Twojej dłoni',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 14,
              color: AppColors.cyan.withOpacity(0.8),
              fontWeight: FontWeight.w300,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionsView() {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (_showScrollIndicator && scrollInfo.metrics.pixels > 100) {
          setState(() => _showScrollIndicator = false);
        }
        return true;
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _fortuneSections.length,
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 300 + (index * 100)),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 30 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: _buildSectionCard(_fortuneSections[index], index),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSectionCard(FortuneSection section, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: section.color.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black.withOpacity(0.8),
                Colors.black.withOpacity(0.6),
                section.color.withOpacity(0.1),
              ],
            ),
            border: Border.all(
              color: section.color.withOpacity(0.3),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header z ikoną i tytułem
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      section.color.withOpacity(0.2),
                      section.color.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _glowAnimation.value,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  section.color.withOpacity(0.3),
                                  section.color.withOpacity(0.1),
                                ],
                              ),
                              border: Border.all(
                                color: section.color.withOpacity(0.5),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                section.icon,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section.title,
                            style: GoogleFonts.cinzelDecorative(
                              fontSize: 20,
                              color: section.color,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 2,
                            width: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  section.color,
                                  section.color.withOpacity(0.3),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  section.content,
                  style: AppTextStyles.fortuneText.copyWith(
                    color: Colors.white,
                    height: 1.8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScrollIndicator() {
    return Positioned(
      bottom: 100,
      right: 20,
      child: AnimatedOpacity(
        opacity: _showScrollIndicator ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 500),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.cyan.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.cyan.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.cyan,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Przewiń',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 12,
                  color: AppColors.cyan,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              margin: const EdgeInsets.only(right: 8),
              child: OutlinedButton.icon(
                onPressed: _shareResults,
                icon: const Icon(Icons.share, size: 20),
                label: const Text('Udostępnij'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.cyan,
                  side: BorderSide(color: AppColors.cyan.withOpacity(0.7)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 48,
              margin: const EdgeInsets.only(left: 8),
              child: ElevatedButton.icon(
                onPressed: () => _navigateToMainMenu(),
                icon: const Icon(Icons.auto_awesome, size: 20),
                label: const Text('Świat Wróż'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildMysticalBackground(),
          SafeArea(
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.withOpacity(0.2),
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber_outlined,
                      color: Colors.orange,
                      size: 64,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Brak Danych Analizy',
                      style: GoogleFonts.cinzelDecorative(
                        fontSize: 24,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nie otrzymano żadnych danych z analizy dłoni.\nSpróbuj ponownie wykonać skanowanie.',
                      style: AppTextStyles.bodyText.copyWith(
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _navigateToMainMenu(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Wróć do Świata Wróż',
                          style: GoogleFonts.cinzelDecorative(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToMainMenu() {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => MainMenuScreen(
          userName: widget.userName,
          userGender: widget.userGender,
          dominantHand: null,
          birthDate: null,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-0.3, 0.0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
      (route) => false,
    );
  }

  void _shareResults() {
    final shareText = '''
🔮 Moja wróżba z dłoni - AI Wróżka

👤 ${widget.userName}

${_fortuneSections.isNotEmpty ? _fortuneSections.first.content.substring(0, math.min(200, _fortuneSections.first.content.length)) + '...' : ''}

Odkryj swoją przyszłość z AI Wróżka!
''';

    Share.share(shareText, subject: 'Moja wróżba z dłoni');
    _loggingService.logToConsole('Udostępniono wyniki wróżby', tag: 'SHARE');
  }
}

// Model sekcji wróżby
class FortuneSection {
  final String title;
  final String icon;
  final String content;
  final Color color;

  FortuneSection({
    required this.title,
    required this.icon,
    required this.content,
    required this.color,
  });
}

// Enhanced mystical painter
class EnhancedMysticalPainter extends CustomPainter {
  final double animationValue;

  EnhancedMysticalPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()..style = PaintingStyle.fill;

    try {
      // Floating mystical orbs
      for (int i = 0; i < 25; i++) {
        final angle = (animationValue * math.pi) + (i * 2 * math.pi / 25);
        final radius = 100.0 + (i % 4) * 50.0;
        final x = size.width * 0.5 + radius * math.cos(angle * 0.3);
        final y = size.height * 0.5 + radius * math.sin(angle * 0.4);

        if (x >= -20 &&
            x <= size.width + 20 &&
            y >= -20 &&
            y <= size.height + 20) {
          final orbSize =
              1.5 + math.sin(animationValue * 3 * math.pi + i) * 0.8;
          final opacity =
              0.05 + math.sin(animationValue * 2 * math.pi + i * 0.5) * 0.03;

          if (orbSize > 0) {
            paint.color = AppColors.cyan.withOpacity(opacity.clamp(0.01, 0.08));
            canvas.drawCircle(Offset(x, y), orbSize.abs(), paint);
          }
        }
      }

      // Energy streams
      for (int i = 0; i < 3; i++) {
        final streamPath = Path();
        final startY = size.height * (0.2 + i * 0.3);
        streamPath.moveTo(0, startY);

        for (double x = 0; x <= size.width; x += 20) {
          final waveY = startY +
              30 * math.sin((x / 100) + animationValue * 2 * math.pi + i);
          streamPath.lineTo(x, waveY);
        }

        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = AppColors.cyan.withOpacity(0.1);

        canvas.drawPath(streamPath, paint);
      }

      // Corner decorations
      _drawCornerDecorations(canvas, size);
    } catch (e) {
      print('❌ Błąd w EnhancedMysticalPainter: $e');
    }
  }

  void _drawCornerDecorations(Canvas canvas, Size size) {
    final cornerPaint = Paint()
      ..color = AppColors.cyan.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    if (size.width > 120 && size.height > 120) {
      // Animated corner arcs
      final animatedExtent =
          (math.pi / 2) * (0.5 + 0.5 * math.sin(animationValue * 2 * math.pi));

      canvas.drawArc(
        Rect.fromLTWH(20, 20, 40, 40),
        -math.pi,
        animatedExtent,
        false,
        cornerPaint,
      );

      canvas.drawArc(
        Rect.fromLTWH(size.width - 60, 20, 40, 40),
        -math.pi / 2,
        animatedExtent,
        false,
        cornerPaint,
      );

      canvas.drawArc(
        Rect.fromLTWH(20, size.height - 60, 40, 40),
        math.pi / 2,
        animatedExtent,
        false,
        cornerPaint,
      );

      canvas.drawArc(
        Rect.fromLTWH(size.width - 60, size.height - 60, 40, 40),
        0,
        animatedExtent,
        false,
        cornerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
