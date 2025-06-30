// ==========================================
// lib/models/subscription_status.dart
// 💳 MODEL STATUSU SUBSKRYPCJI
// ==========================================

class SubscriptionStatus {
  final bool isActive;
  final String? planType; // 'basic', 'premium', 'vip'
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? nextBillingDate;
  final String? provider; // 'apple', 'google', 'stripe'
  final bool isTrialPeriod;
  final int daysRemaining;
  final List<String> features;

  const SubscriptionStatus({
    this.isActive = false,
    this.planType,
    this.startDate,
    this.endDate,
    this.nextBillingDate,
    this.provider,
    this.isTrialPeriod = false,
    this.daysRemaining = 0,
    this.features = const [],
  });

  factory SubscriptionStatus.fromFirestore(Map<String, dynamic> data) {
    return SubscriptionStatus(
      isActive: data['isActive'] ?? false,
      planType: data['planType'],
      startDate: data['startDate']?.toDate(),
      endDate: data['endDate']?.toDate(),
      nextBillingDate: data['nextBillingDate']?.toDate(),
      provider: data['provider'],
      isTrialPeriod: data['isTrialPeriod'] ?? false,
      daysRemaining: data['daysRemaining'] ?? 0,
      features: List<String>.from(data['features'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'isActive': isActive,
      'planType': planType,
      'startDate': startDate,
      'endDate': endDate,
      'nextBillingDate': nextBillingDate,
      'provider': provider,
      'isTrialPeriod': isTrialPeriod,
      'daysRemaining': daysRemaining,
      'features': features,
    };
  }

  bool hasFeature(String feature) {
    return features.contains(feature);
  }

  bool get isPremium => planType == 'premium' || planType == 'vip';
  bool get isVip => planType == 'vip';
}
