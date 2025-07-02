// lib/widgets/candle_balance_display.dart
// 🕯️ WIDGET WYŚWIETLANIA SALDA ŚWIEC
// Zgodny z wytycznymi projektu AI Wróżka

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/candle_manager_service.dart';
import '../services/haptic_service.dart';
import '../utils/responsive_utils.dart';
import '../utils/logger.dart';

class CandleBalanceDisplay extends StatefulWidget {
  final bool showDetails;
  final VoidCallback? onTap;
  final bool showTodayEarned;

  const CandleBalanceDisplay({
    Key? key,
    this.showDetails = false,
    this.onTap,
    this.showTodayEarned = true,
  }) : super(key: key);

  @override
  State<CandleBalanceDisplay> createState() => _CandleBalanceDisplayState();
}

class _CandleBalanceDisplayState extends State<CandleBalanceDisplay>
    with TickerProviderStateMixin {
  final CandleManagerService _candleService = CandleManagerService();

  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _counterController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  late Animation<int> _counterAnimation;

  CandleStats? _stats;
  bool _isLoading = true;
  int _currentBalance = 0;
  int _previousBalance = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCandleData();
  }

  void _initializeAnimations() {
    // Animacja pulsowania świecy
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Animacja świecenia
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Animacja licznika
    _counterController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _counterAnimation = IntTween(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _counterController, curve: Curves.easeOut),
    );

    // Uruchom animacje w pętli
    _pulseController.repeat(reverse: true);
    _glowController.repeat(reverse: true);
  }

  Future<void> _loadCandleData() async {
    try {
      setState(() => _isLoading = true);

      final stats = await _candleService.getStats();

      setState(() {
        _stats = stats;
        _previousBalance = _currentBalance;
        _currentBalance = stats.currentBalance;
        _isLoading = false;
      });

      // Animuj zmianę licznika jeśli saldo się zmieniło
      if (_previousBalance != _currentBalance) {
        _animateCounter(_previousBalance, _currentBalance);
      }
    } catch (e) {
      Logger.error('Błąd ładowania danych świec: $e');
      setState(() => _isLoading = false);
    }
  }

  void _animateCounter(int from, int to) {
    _counterAnimation = IntTween(begin: from, end: to).animate(
      CurvedAnimation(parent: _counterController, curve: Curves.easeOut),
    );
    _counterController.reset();
    _counterController.forward();
  }

  Future<void> _handleTap() async {
    await HapticService.triggerLight();
    widget.onTap?.call();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    _counterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap != null ? _handleTap : null,
      child: ResponsiveContainer(
        child: _isLoading ? _buildLoadingWidget() : _buildCandleDisplay(),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withOpacity(0.3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Ładowanie...',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCandleDisplay() {
    if (_stats == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber.withOpacity(0.2),
            Colors.orange.withOpacity(0.1),
          ],
        ),
        border: Border.all(
          color: Colors.amber.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animowana ikona świecy
          _buildAnimatedCandleIcon(),

          const SizedBox(width: 12),

          // Saldo świec
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animowany licznik świec
                  AnimatedBuilder(
                    animation: _counterAnimation,
                    builder: (context, child) {
                      return Text(
                        _counterAnimation.value.toString(),
                        style: GoogleFonts.cinzelDecorative(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '🕯️',
                    style: GoogleFonts.cinzelDecorative(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),

              // Szczegóły (opcjonalnie)
              if (widget.showDetails) ...[
                const SizedBox(height: 4),
                _buildDetailsRow(),
              ],
            ],
          ),

          // Wskaźnik możliwości tapnięcia
          if (widget.onTap != null) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.touch_app,
              size: 16,
              color: Colors.white.withOpacity(0.5),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnimatedCandleIcon() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _glowAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.amber.withOpacity(_glowAnimation.value),
                  Colors.orange.withOpacity(_glowAnimation.value * 0.7),
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(_glowAnimation.value * 0.5),
                  blurRadius: 10 * _glowAnimation.value,
                  spreadRadius: 2 * _glowAnimation.value,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.local_fire_department,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailsRow() {
    if (_stats == null) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showTodayEarned && _stats!.todayEarned > 0) ...[
          Icon(
            Icons.trending_up,
            size: 12,
            color: Colors.green,
          ),
          const SizedBox(width: 2),
          Text(
            '+${_stats!.todayEarned}',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 12,
              color: Colors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
        ],
        if (_stats!.dailyStreak > 1) ...[
          Icon(
            Icons.local_fire_department,
            size: 12,
            color: Colors.orange,
          ),
          const SizedBox(width: 2),
          Text(
            '${_stats!.dailyStreak}',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 12,
              color: Colors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  /// Publiczne metody do odświeżania
  Future<void> refresh() async {
    await _loadCandleData();
  }

  /// Animuj zmianę salda (do użycia gdy saldo się zmieni)
  void animateBalanceChange(int newBalance) {
    final oldBalance = _currentBalance;
    setState(() {
      _currentBalance = newBalance;
    });

    // Animuj licznik
    _animateCounter(oldBalance, newBalance);

    // Krótka animacja "błysku" przy zmianie
    _glowController.reset();
    _glowController.forward();
  }
}

/// 🎯 Wariant kompaktowy dla małych przestrzeni
class CompactCandleDisplay extends StatelessWidget {
  final int candleCount;
  final VoidCallback? onTap;

  const CompactCandleDisplay({
    Key? key,
    required this.candleCount,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.amber.withOpacity(0.2),
          border: Border.all(
            color: Colors.amber.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department,
              size: 16,
              color: Colors.amber,
            ),
            const SizedBox(width: 4),
            Text(
              '$candleCount',
              style: GoogleFonts.cinzelDecorative(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
