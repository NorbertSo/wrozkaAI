// lib/widgets/candle_payment_confirmation_widget.dart
// 🎨 UNIWERSALNY WIDGET PŁATNOŚCI - FINALNE ROZWIĄZANIE
// Jeden kod dla WSZYSTKICH płatności świecami

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../services/haptic_service.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';
import '../widgets/haptic_button.dart';

// 🎯 HELPER - Pokazanie JEDNEGO uniwersalnego widgetu
class CandlePaymentHelper {
  static Future<bool> showPaymentConfirmation({
    required BuildContext context,
    required String featureName,
    required String featureIcon,
    required int candleCost,
    required String featureDescription,
    required int currentBalance,
    Color? accentColor,
  }) async {
    final result = await Navigator.push<bool>(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            UniversalPaymentScreen(
          featureName: featureName,
          featureIcon: featureIcon,
          candleCost: candleCost,
          featureDescription: featureDescription,
          currentBalance: currentBalance,
          accentColor: accentColor ?? AppColors.cyan,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );

    return result ?? false;
  }
}

// 🎨 UNIWERSALNY EKRAN PŁATNOŚCI - ELEGANCKI STYL
class UniversalPaymentScreen extends StatefulWidget {
  final String featureName;
  final String featureIcon;
  final int candleCost;
  final String featureDescription;
  final int currentBalance;
  final Color accentColor;

  const UniversalPaymentScreen({
    super.key,
    required this.featureName,
    required this.featureIcon,
    required this.candleCost,
    required this.featureDescription,
    required this.currentBalance,
    required this.accentColor,
  });

  @override
  State<UniversalPaymentScreen> createState() => _UniversalPaymentScreenState();
}

class _UniversalPaymentScreenState extends State<UniversalPaymentScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _sparkleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _sparkleAnimation;

  bool get _hasEnoughCandles => widget.currentBalance >= widget.candleCost;
  int get _balanceAfter => widget.currentBalance - widget.candleCost;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _sparkleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() {
    _fadeController.forward();
    _sparkleController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBlue,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.welcomeGradient,
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Column(
                  children: [
                    _buildCustomAppBar(),
                    Expanded(
                      child: _buildPaymentContent(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          HapticButton(
            text: '',
            onPressed: () => Navigator.of(context).pop(false),
            hapticType: HapticType.light,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              widget.featureName.toUpperCase(),
              style: GoogleFonts.cinzelDecorative(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _buildCandleCounter(),
        ],
      ),
    );
  }

  Widget _buildCandleCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.2),
            Colors.orange.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.orange.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🕯️', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            widget.currentBalance.toString(),
            style: GoogleFonts.cinzelDecorative(
              fontSize: 14,
              color: Colors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animowana ikona z gradientem
            AnimatedBuilder(
              animation: _sparkleController,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        widget.accentColor
                            .withOpacity(0.3 + _sparkleAnimation.value * 0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Text(
                    widget.featureIcon,
                    style: TextStyle(
                      fontSize: 64,
                      color: widget.accentColor,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Nazwa funkcji
            Text(
              widget.featureName,
              style: GoogleFonts.cinzelDecorative(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Opis funkcji
            Text(
              widget.featureDescription,
              style: GoogleFonts.cinzelDecorative(
                fontSize: 14,
                color: Colors.white70,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Karta kosztów - ELEGANCKA WERSJA (jak w horoskopie)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.withOpacity(0.2),
                    Colors.orange.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _sparkleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 1.0 + (_sparkleAnimation.value * 0.1),
                            child: const Text('🕯️',
                                style: TextStyle(fontSize: 24)),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.candleCost} świec',
                        style: GoogleFonts.cinzelDecorative(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Twój balans: ${widget.currentBalance} świec',
                    style: GoogleFonts.cinzelDecorative(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // PRZYCISK PŁATNOŚCI - ELEGANCKI
            SizedBox(
              width: double.infinity,
              child: HapticButton(
                text: _hasEnoughCandles
                    ? '🔮 Odbierz ${widget.featureName}'
                    : '🚫 Brak wystarczających świec',
                onPressed: _hasEnoughCandles
                    ? _handleConfirm
                    : _handleInsufficientFunds,
                hapticType: HapticType.medium,
                backgroundColor: _hasEnoughCandles
                    ? widget.accentColor.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
                foregroundColor:
                    _hasEnoughCandles ? widget.accentColor : Colors.grey,
              ),
            ),

            const SizedBox(height: 12),

            // Przycisk anulowania
            SizedBox(
              width: double.infinity,
              child: HapticButton(
                text: 'Anuluj',
                onPressed: () => Navigator.of(context).pop(false),
                hapticType: HapticType.light,
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white70,
              ),
            ),

            // Informacje o saldzie po zakupie
            if (_hasEnoughCandles) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Balans po zakupie:',
                      style: GoogleFonts.cinzelDecorative(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      '🕯️ $_balanceAfter',
                      style: GoogleFonts.cinzelDecorative(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _balanceAfter > 0 ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Informacja o zdobywaniu świec
            if (!_hasEnoughCandles) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Zdobądź świece w codziennych aktywnościach',
                      style: GoogleFonts.cinzelDecorative(
                        fontSize: 14,
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '🌅 Codzienne logowanie: +1 świeca\n📤 Udostępnienie wyniku: +3 świece',
                      style: GoogleFonts.cinzelDecorative(
                        fontSize: 12,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Future<void> _handleConfirm() async {
    await HapticService.triggerSuccess();
    Navigator.of(context).pop(true);
  }

  Future<void> _handleInsufficientFunds() async {
    await HapticService.triggerError();
    // Można dodać dodatkowy dialog lub pozostawić obecny widget
  }
}
