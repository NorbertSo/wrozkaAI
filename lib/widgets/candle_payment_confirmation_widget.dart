// lib/widgets/candle_payment_confirmation_widget.dart
// 🕯️ UNIWERSALNY WIDGET POTWIERDZANIA PŁATNOŚCI ŚWIECAMI
// Zgodny z wytycznymi projektu AI Wróżka

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../services/haptic_service.dart';
import '../utils/responsive_utils.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';

class CandlePaymentConfirmationWidget extends StatefulWidget {
  final String featureName; // Nazwa funkcji np. "Skan dłoni"
  final String featureIcon; // Ikona funkcji np. "�️"
  final int candleCost; // Koszt w świecach
  final String featureDescription; // Dodatkowy opis funkcji
  final int currentBalance; // Aktualne saldo świec użytkownika
  final VoidCallback onConfirm; // Callback po potwierdzeniu
  final VoidCallback? onCancel; // Callback po anulowaniu
  final Color? accentColor; // Kolor akcentu (domyślnie pomarańczowy)

  const CandlePaymentConfirmationWidget({
    Key? key,
    required this.featureName,
    required this.featureIcon,
    required this.candleCost,
    required this.featureDescription,
    required this.currentBalance,
    required this.onConfirm,
    this.onCancel,
    this.accentColor,
  }) : super(key: key);

  @override
  State<CandlePaymentConfirmationWidget> createState() =>
      _CandlePaymentConfirmationWidgetState();
}

class _CandlePaymentConfirmationWidgetState
    extends State<CandlePaymentConfirmationWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Delikatne pulsowanie świec
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Subtelne świecenie
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
    _glowController.repeat(reverse: true);
  }

  bool get _hasEnoughCandles => widget.currentBalance >= widget.candleCost;
  int get _balanceAfter => widget.currentBalance - widget.candleCost;
  Color get _accentColor => widget.accentColor ?? Colors.orange;

  Future<void> _handleConfirm() async {
    await HapticService.triggerMedium();

    if (_hasEnoughCandles) {
      widget.onConfirm();
    } else {
      // Pokazuj dialog niewystarczających świec
      _showInsufficientCandlesDialog();
    }
  }

  Future<void> _handleCancel() async {
    await HapticService.triggerLight();
    widget.onCancel?.call();
  }

  void _showInsufficientCandlesDialog() {
    showDialog(
      context: context,
      builder: (context) => InsufficientCandlesDialog(
        currentBalance: widget.currentBalance,
        requiredAmount: widget.candleCost,
        featureName: widget.featureName,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.darkBlue,
              AppColors.deepBlue,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _accentColor.withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _accentColor.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🎯 Ikona funkcji
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    _accentColor.withOpacity(0.3),
                    _accentColor.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Text(
                widget.featureIcon,
                style: const TextStyle(fontSize: 48),
              ),
            ),

            const SizedBox(height: 16),

            // 🏷️ Nazwa funkcji
            Text(
              widget.featureName,
              style: GoogleFonts.cinzelDecorative(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // 📄 Opis funkcji
            Text(
              widget.featureDescription,
              style: GoogleFonts.cinzelDecorative(
                fontSize: 14,
                fontWeight: FontWeight.w300,
                color: Colors.white70,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // 🕯️ Animowane świece z kosztem
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _accentColor.withOpacity(0.2),
                          _accentColor.withOpacity(0.4),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: _accentColor.withOpacity(0.6),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _glowAnimation,
                          builder: (context, child) {
                            return Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(
                                      _glowAnimation.value,
                                    ),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Text('🕯️',
                                  style: TextStyle(fontSize: 24)),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.candleCost} świec zostanie wydane',
                          style: GoogleFonts.cinzelDecorative(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // 💰 Informacje o saldzie
            _buildBalanceInfo(),

            const SizedBox(height: 24),

            // 🎯 Przyciski akcji
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Aktualny balans
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Twój aktualny balans:',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              Row(
                children: [
                  const Text('🕯️', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.currentBalance}',
                    style: GoogleFonts.cinzelDecorative(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (_hasEnoughCandles) ...[
            const SizedBox(height: 8),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 8),

            // Balans po transakcji
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Balans po zakupie:',
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                Row(
                  children: [
                    const Text('🕯️', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text(
                      '$_balanceAfter',
                      style: GoogleFonts.cinzelDecorative(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _balanceAfter > 0 ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Przycisk główny
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _handleConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: _hasEnoughCandles
                  ? _accentColor
                  : Colors.grey.withOpacity(0.3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: _hasEnoughCandles ? 4 : 0,
            ),
            child: Text(
              _hasEnoughCandles ? 'Idę dalej' : 'Potrzebuję więcej świec',
              style: GoogleFonts.cinzelDecorative(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Przycisk anulowania
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _handleCancel,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              'Anuluj',
              style: GoogleFonts.cinzelDecorative(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// 📊 DIALOG NIEWYSTARCZAJĄCYCH ŚWIEC
class InsufficientCandlesDialog extends StatelessWidget {
  final int currentBalance;
  final int requiredAmount;
  final String featureName;

  const InsufficientCandlesDialog({
    Key? key,
    required this.currentBalance,
    required this.requiredAmount,
    required this.featureName,
  }) : super(key: key);

  int get _missingCandles => requiredAmount - currentBalance;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.darkBlue,
                AppColors.deepBlue,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.red.withOpacity(0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🚫 Ikona braku świec
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.red.withOpacity(0.3),
                      Colors.red.withOpacity(0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red,
                ),
              ),

              const SizedBox(height: 16),

              // 📋 Tytuł
              Text(
                'Niewystarczające saldo',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // 📄 Opis problemu
              Text(
                'Do zakupu funkcji "$featureName" potrzebujesz $_missingCandles więcej świec.',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // 💡 Sposoby zdobycia świec
              Text(
                'Sposoby zdobycia świec:',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Lista metod zarobku
              Column(
                children: [
                  _buildEarnMethod('🌅', 'Codzienne logowanie', '+1'),
                  _buildEarnMethod('📤', 'Udostępnienie wyniku', '+3'),
                  _buildEarnMethod('👥', 'Polecenie znajomemu', '+5'),
                  _buildEarnMethod('🔥', 'Seria aktywności', '+2'),
                ],
              ),

              const SizedBox(height: 24),

              // 🎯 Przyciski akcji
              Column(
                children: [
                  // Przycisk zakupu (placeholder)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showPurchaseComingSoon(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        '💎 Kup świece (wkrótce)',
                        style: GoogleFonts.cinzelDecorative(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Przycisk zamknięcia
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Rozumiem',
                        style: GoogleFonts.cinzelDecorative(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEarnMethod(String icon, String title, String reward) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.cinzelDecorative(
                fontSize: 13,
                color: Colors.white70,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            reward,
            style: GoogleFonts.cinzelDecorative(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  void _showPurchaseComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkBlue,
        title: Text(
          'Funkcja w przygotowaniu',
          style: GoogleFonts.cinzelDecorative(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'System zakupu świec będzie dostępny wkrótce. Obecnie możesz zdobywać świece przez codzienne aktywności w aplikacji.',
          style: GoogleFonts.cinzelDecorative(
            color: Colors.white70,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Zamknij dialog zakupu
              Navigator.of(context)
                  .pop(); // Zamknij dialog niewystarczających świec
            },
            child: Text(
              'OK',
              style: GoogleFonts.cinzelDecorative(
                color: Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 🎯 HELPER - Pokazanie dialogu płatności
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
    final completer = Completer<bool>();

    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: CandlePaymentConfirmationWidget(
          featureName: featureName,
          featureIcon: featureIcon,
          candleCost: candleCost,
          featureDescription: featureDescription,
          currentBalance: currentBalance,
          accentColor: accentColor,
          onConfirm: () {
            Navigator.of(context).pop();
            completer.complete(true);
          },
          onCancel: () {
            Navigator.of(context).pop();
            completer.complete(false);
          },
        ),
      ),
    );

    return completer.future;
  }

  /// 🎯 NOWA METODA - Dialog płatności z callback wykonania płatności
  static Future<bool> showPaymentConfirmationWithCallback({
    required BuildContext context,
    required String featureName,
    required String featureIcon,
    required int candleCost,
    required String featureDescription,
    required int currentBalance,
    required Future<void> Function() onPaymentSuccess,
    Color? accentColor,
  }) async {
    final completer = Completer<bool>();

    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: CandlePaymentConfirmationWidget(
          featureName: featureName,
          featureIcon: featureIcon,
          candleCost: candleCost,
          featureDescription: featureDescription,
          currentBalance: currentBalance,
          accentColor: accentColor,
          onConfirm: () async {
            Navigator.of(context).pop();
            try {
              // Wykonaj callback płatności
              await onPaymentSuccess();
              completer.complete(true);
            } catch (e) {
              Logger.error('Błąd wykonania płatności: $e');
              completer.complete(false);
            }
          },
          onCancel: () {
            Navigator.of(context).pop();
            completer.complete(false);
          },
        ),
      ),
    );

    return completer.future;
