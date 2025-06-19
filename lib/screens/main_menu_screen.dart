// lib/screens/main_menu_screen.dart
// Główne menu aplikacji AI Wróżka

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'dart:math' as math;
import '../utils/constants.dart';
import '../models/user_data.dart';
import '../services/fortune_history_service.dart'; // ✅ DODANE
import 'palm_intro_screen.dart';
import 'fortune_history_screen.dart'; // ✅ DODANE

class MainMenuScreen extends StatefulWidget {
  final String userName;
  final String userGender;
  final String? dominantHand;
  final DateTime? birthDate;

  const MainMenuScreen({
    super.key,
    required this.userName,
    required this.userGender,
    this.dominantHand,
    this.birthDate,
  });

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with TickerProviderStateMixin {
  // ===== SERWISY =====
  final FortuneHistoryService _historyService =
      FortuneHistoryService(); // ✅ DODANE

  // ===== ANIMACJE =====
  late AnimationController _fadeController;
  late AnimationController _floatingController;
  late AnimationController _pulseController;
  late AnimationController _starController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _starAnimation;

  // ===== STAN MENU =====
  int _selectedIndex = -1;
  int _fortuneCount = 0; // ✅ DODANE - licznik wróżb

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    _loadFortuneCount(); // ✅ DODANE
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _starController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _floatingAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _starAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _starController, curve: Curves.linear),
    );
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _fadeController.forward();
      }
    });
  }

  // ✅ DODANA METODA - ładowanie liczby wróżb
  Future<void> _loadFortuneCount() async {
    try {
      final count = await _historyService.getFortuneCount();
      if (mounted) {
        setState(() {
          _fortuneCount = count;
        });
      }
    } catch (e) {
      print('❌ Błąd ładowania liczby wróżb: $e');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _floatingController.dispose();
    _pulseController.dispose();
    _starController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        // Gradient tło
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.8,
              colors: [
                Color(0xFF0D1B2A),
                Color(0xFF1B263B),
                Color(0xFF000000),
              ],
            ),
          ),
        ),

        // Animowane tło z gwiazdami
        SizedBox.expand(
          child: Lottie.asset(
            'assets/animations/star_bg.json',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),

        // Mystical particles
        AnimatedBuilder(
          animation: _starAnimation,
          builder: (context, child) {
            return CustomPaint(
              painter: MenuBackgroundPainter(_starAnimation.value),
              size: Size.infinite,
            );
          },
        ),
      ],
    );
  }

  Widget _buildContent() {
    return SafeArea(
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildWelcomeHeader(),
                  const SizedBox(height: 40),
                  _buildMenuOptions(),
                  const SizedBox(height: 40),
                  _buildMysticFooter(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatingAnimation.value),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black.withOpacity(0.8),
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
                  color: AppColors.cyan.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                // Mystical icon
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.cyan.withOpacity(0.3),
                              AppColors.cyan.withOpacity(0.1),
                              Colors.transparent,
                            ],
                          ),
                          border: Border.all(
                            color: AppColors.cyan.withOpacity(0.6),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.auto_awesome,
                          size: 40,
                          color: AppColors.cyan,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Welcome text
                Text(
                  'Witaj w Świecie Wróż',
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 24,
                    color: AppColors.cyan,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  'Drogi${widget.userGender == 'female' ? 'a' : (widget.userGender == 'other' ? '/a' : '')} ${widget.userName}',
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w300,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                Text(
                  'Co chcesz dziś odkryć?',
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 16,
                    color: AppColors.cyan.withOpacity(0.8),
                    fontWeight: FontWeight.w300,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuOptions() {
    final options = [
      MenuOption(
        title: 'Skan Dłoni',
        subtitle: 'Odkryj swoją przyszłość',
        icon: Icons.pan_tool_outlined,
        color: AppColors.cyan,
        isAvailable: true,
        onTap: () => _navigateToPalmScan(),
      ),
      MenuOption(
        title: 'Horoskop na Dzisiaj',
        subtitle: 'Twoje gwiazdy mówią...',
        icon: Icons.stars_outlined,
        color: Colors.purple,
        isAvailable: false,
        onTap: () => _showComingSoon('Horoskop'),
      ),
      MenuOption(
        title: 'Moje Dane',
        subtitle: 'Zarządzaj profilem',
        icon: Icons.person_outline,
        color: Colors.orange,
        isAvailable: false,
        onTap: () => _showComingSoon('Profil'),
      ),
      MenuOption(
        title: 'Moje Wróżby',
        subtitle: _fortuneCount > 0
            ? '$_fortuneCount zapisanych wróżb'
            : 'Historia Twoich wróżb',
        icon: Icons.history_outlined,
        color: Colors.green,
        isAvailable: true, // ✅ ZMIENIONE na true
        badge: _fortuneCount > 0 ? _fortuneCount.toString() : null, // ✅ DODANE
        onTap: () => _navigateToFortuneHistory(), // ✅ ZMIENIONE
      ),
    ];

    return Column(
      children: options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;

        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + (index * 100)),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(bottom: 16),
          child: _buildMenuCard(option, index),
        );
      }).toList(),
    );
  }

  Widget _buildMenuCard(MenuOption option, int index) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _selectedIndex = index);
        HapticFeedback.selectionClick();
      },
      onTapUp: (_) {
        setState(() => _selectedIndex = -1);
        option.onTap();
      },
      onTapCancel: () {
        setState(() => _selectedIndex = -1);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform:
            isSelected ? (Matrix4.identity()..scale(0.98)) : Matrix4.identity(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: option.isAvailable
                  ? [
                      Colors.black.withOpacity(0.8),
                      Colors.black.withOpacity(0.6),
                    ]
                  : [
                      Colors.grey.withOpacity(0.3),
                      Colors.grey.withOpacity(0.2),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: option.isAvailable
                  ? (isSelected ? option.color : option.color.withOpacity(0.4))
                  : Colors.grey.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: option.isAvailable
                ? [
                    BoxShadow(
                      color: option.color.withOpacity(isSelected ? 0.4 : 0.15),
                      blurRadius: isSelected ? 20 : 10,
                      spreadRadius: isSelected ? 2 : 1,
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: option.isAvailable
                      ? RadialGradient(
                          colors: [
                            option.color.withOpacity(0.3),
                            option.color.withOpacity(0.1),
                          ],
                        )
                      : null,
                  color:
                      option.isAvailable ? null : Colors.grey.withOpacity(0.2),
                  border: Border.all(
                    color: option.isAvailable
                        ? option.color.withOpacity(0.6)
                        : Colors.grey.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Icon(
                  option.icon,
                  size: 28,
                  color: option.isAvailable ? option.color : Colors.grey,
                ),
              ),

              const SizedBox(width: 16),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            option.title,
                            style: GoogleFonts.cinzelDecorative(
                              fontSize: 18,
                              color: option.isAvailable
                                  ? Colors.white
                                  : Colors.grey,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (!option.isAvailable)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Wkrótce',
                              style: GoogleFonts.cinzelDecorative(
                                fontSize: 10,
                                color: Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option.subtitle,
                      style: GoogleFonts.cinzelDecorative(
                        fontSize: 14,
                        color: option.isAvailable
                            ? Colors.white70
                            : Colors.grey.withOpacity(0.7),
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow icon
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: option.isAvailable
                    ? option.color.withOpacity(0.7)
                    : Colors.grey.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMysticFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.6),
            Colors.black.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cyan.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Decorative stars
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              return AnimatedBuilder(
                animation: _starAnimation,
                builder: (context, child) {
                  final delay = index * 0.2;
                  final rotation = (_starAnimation.value + delay) * 2 * math.pi;
                  return Transform.rotate(
                    angle: rotation,
                    child: Icon(
                      Icons.star_border,
                      size: 16,
                      color: AppColors.cyan.withOpacity(0.6),
                    ),
                  );
                },
              );
            }),
          ),

          const SizedBox(height: 16),

          Text(
            'Mistyczne moce zawsze z Tobą',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 16,
              color: AppColors.cyan,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.8,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            'Wersja 1.0.0 • AI Wróżka',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 12,
              color: Colors.white54,
              fontWeight: FontWeight.w300,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ✅ DODANA METODA - nawigacja do historii wróżb
  void _navigateToFortuneHistory() {
    HapticFeedback.mediumImpact();

    Navigator.of(context)
        .push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            FortuneHistoryScreen(
          userName: widget.userName,
          userGender: widget.userGender,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.3, 0.0),
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
    )
        .then((_) {
      // Odśwież licznik po powrocie
      _loadFortuneCount();
    });
  }

  void _navigateToPalmScan() {
    HapticFeedback.mediumImpact();

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            PalmIntroScreen(
          userName: widget.userName,
          userGender: widget.userGender,
          dominantHand: widget.dominantHand,
          birthDate: widget.birthDate,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.3),
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
    );
  }

  void _showComingSoon(String featureName) {
    HapticFeedback.lightImpact();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A2332),
                Color(0xFF0B1426),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.orange.withOpacity(0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome,
                color: Colors.orange,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                '$featureName - Wkrótce',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Ta funkcja jest w przygotowaniu.\nMistyczne moce nad nią pracują...',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  color: Colors.white70,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    'Rozumiem',
                    style: GoogleFonts.cinzelDecorative(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Model dla opcji menu
class MenuOption {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isAvailable;
  final String? badge; // ✅ DODANE
  final VoidCallback onTap;

  MenuOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isAvailable,
    this.badge, // ✅ DODANE
    required this.onTap,
  });
}

// Custom painter dla tła menu
class MenuBackgroundPainter extends CustomPainter {
  final double animationValue;

  MenuBackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()..style = PaintingStyle.fill;

    try {
      // Floating mystical orbs
      for (int i = 0; i < 15; i++) {
        final angle = (animationValue * math.pi) + (i * 2 * math.pi / 15);
        final radius = 60.0 + (i % 3) * 25.0;
        final centerX = size.width * (0.2 + (i % 4) * 0.2);
        final centerY = size.height * (0.2 + (i % 5) * 0.15);

        final x = centerX + radius * math.cos(angle * 0.5);
        final y = centerY + radius * math.sin(angle * 0.3);

        if (x >= -20 &&
            x <= size.width + 20 &&
            y >= -20 &&
            y <= size.height + 20) {
          final orbSize =
              1.5 + math.sin(animationValue * 2 * math.pi + i) * 0.8;
          final opacity =
              0.1 + math.sin(animationValue * 3 * math.pi + i * 0.5) * 0.05;

          if (orbSize > 0) {
            paint.color = AppColors.cyan.withOpacity(opacity.clamp(0.02, 0.15));
            canvas.drawCircle(Offset(x, y), orbSize.abs(), paint);
          }
        }
      }

      // Subtle corner decorations
      final cornerPaint = Paint()
        ..color = AppColors.cyan.withOpacity(0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      if (size.width > 100 && size.height > 100) {
        // Top left decoration
        canvas.drawArc(
          Rect.fromLTWH(20, 20, 30, 30),
          -math.pi,
          math.pi / 2,
          false,
          cornerPaint,
        );

        // Bottom right decoration
        canvas.drawArc(
          Rect.fromLTWH(size.width - 50, size.height - 50, 30, 30),
          0,
          math.pi / 2,
          false,
          cornerPaint,
        );
      }
    } catch (e) {
      print('❌ Błąd w MenuBackgroundPainter: $e');
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
