// ==========================================
// lib/models/user_premium_status.dart
// 💎 PROSTY MODEL STATUSU PREMIUM
// ==========================================

class UserPremiumStatus {
  final bool isPremium;
  final bool hasUsedMonthlyFree;
  final DateTime? premiumExpiryDate;
  final DateTime lastChecked;

  const UserPremiumStatus({
    this.isPremium = false,
    this.hasUsedMonthlyFree = false,
    this.premiumExpiryDate,
    required this.lastChecked,
  });

  factory UserPremiumStatus.fromMap(Map<String, dynamic> data) {
    return UserPremiumStatus(
      isPremium: data['isPremium'] ?? false,
      hasUsedMonthlyFree: data['hasUsedMonthlyFree'] ?? false,
      premiumExpiryDate: data['premiumExpiryDate']?.toDate(),
      lastChecked: data['lastChecked']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isPremium': isPremium,
      'hasUsedMonthlyFree': hasUsedMonthlyFree,
      'premiumExpiryDate': premiumExpiryDate,
      'lastChecked': lastChecked,
    };
  }

  bool get isActive {
    if (!isPremium) return false;
    if (premiumExpiryDate == null) return true;
    return premiumExpiryDate!.isAfter(DateTime.now());
  }

  bool get canUseExtendedHoroscope {
    return isActive || !hasUsedMonthlyFree;
  }
}
