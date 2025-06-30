// ==========================================
// lib/widgets/monthly_usage_indicator.dart
// 📊 WSKAŹNIK MIESIĘCZNEGO UŻYCIA
// ==========================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';

class MonthlyUsageIndicator extends StatelessWidget {
  final bool hasUsedFree;
  final int candlesCount;
  final bool isSubscriber;

  const MonthlyUsageIndicator({
    super.key,
    required this.hasUsedFree,
    required this.candlesCount,
    required this.isSubscriber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getStatusColor().withOpacity(0.1),
            _getStatusColor().withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor().withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(),
            color: _getStatusColor(),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusTitle(),
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getStatusDescription(),
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (isSubscriber) return AppColors.green;
    if (!hasUsedFree) return AppColors.blue;
    if (candlesCount >= 10) return AppColors.orange;
    return AppColors.red;
  }

  IconData _getStatusIcon() {
    if (isSubscriber) return Icons.workspace_premium;
    if (!hasUsedFree) return Icons.card_giftcard;
    if (candlesCount >= 10) return Icons.local_fire_department;
    return Icons.lock;
  }

  String _getStatusTitle() {
    if (isSubscriber) return 'Premium Active';
    if (!hasUsedFree) return 'Darmowy dostęp';
    if (candlesCount >= 10) return 'Dostęp za świece';
    return 'Brak dostępu';
  }

  String _getStatusDescription() {
    if (isSubscriber) return 'Nieograniczony dostęp do wszystkich funkcji';
    if (!hasUsedFree) return 'Pierwszy horoskop rozbudowany w tym miesiącu';
    if (candlesCount >= 10) return 'Możesz użyć 10 świec dla dostępu';
    return 'Potrzebujesz więcej świec lub subskrypcję';
  }
}
