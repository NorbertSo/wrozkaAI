// ==========================================
// lib/widgets/candle_counter_widget.dart
// 🕯️ LICZNIK ŚWIEC
// ==========================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/constants.dart';

class CandleCounterWidget extends StatelessWidget {
  final int candlesCount;
  final bool showLabel;
  final double? fontSize;

  const CandleCounterWidget({
    super.key,
    required this.candlesCount,
    this.showLabel = true,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.orange.withOpacity(0.2),
            AppColors.orange.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.orange.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🕯️', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            candlesCount.toString(),
            style: GoogleFonts.cinzelDecorative(
              fontSize: fontSize ?? 14,
              color: AppColors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              'świec',
              style: GoogleFonts.cinzelDecorative(
                fontSize: (fontSize ?? 14) - 2,
                color: AppColors.orange.withOpacity(0.8),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
