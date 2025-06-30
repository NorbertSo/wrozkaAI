// ==========================================
// lib/services/subscription_service.dart
// 💳 SERWIS SUBSKRYPCJI
// ==========================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subscription_status.dart';
import '../services/secure_user_service.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  FirebaseFirestore? _firestore;
  bool _initialized = false;

  /// 🏗️ Inicjalizacja serwisu
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _firestore = FirebaseFirestore.instance;
      _initialized = true;
      print('SubscriptionService zainicjalizowany');
    } catch (e) {
      print('Błąd inicjalizacji SubscriptionService: $e');
    }
  }

  /// 📋 Pobierz status subskrypcji
  Future<SubscriptionStatus> getSubscriptionStatus() async {
    await initialize();

    try {
      final userData = await SecureUserService.getUserData();
      if (userData == null) {
        return const SubscriptionStatus();
      }

      final userId = userData.name;
      if (_firestore == null) {
        print('Firestore nie jest zainicjalizowany');
        return const SubscriptionStatus();
      }
      final doc = await _firestore!.collection('user_subscriptions').doc(userId).get();

      if (doc.exists && doc.data() != null) {
        final subscription = SubscriptionStatus.fromFirestore(doc.data()!);
        // Sprawdź czy subskrypcja nie wygasła
        if (subscription.endDate != null && subscription.endDate!.isBefore(DateTime.now())) {
          await _expireSubscription(userId);
          return const SubscriptionStatus();
        }
        return subscription;
      }

      return const SubscriptionStatus();
    } catch (e) {
      print('Błąd pobierania statusu subskrypcji: $e');
      return const SubscriptionStatus();
    }
  }

  /// ⏰ Wygaś subskrypcję
  Future<void> _expireSubscription(String userId) async {
    try {
      if (_firestore == null) {
        print('Firestore nie jest zainicjalizowany');
        return;
      }
      await _firestore!.collection('user_subscriptions').doc(userId).update({
        'isActive': false,
        'endDate': DateTime.now(),
      });

      print('Subskrypcja wygasła dla użytkownika: $userId');
    } catch (e) {
      print('Błąd wygaszania subskrypcji: $e');
    }
  }

  /// ✅ Sprawdź czy użytkownik ma aktywną subskrypcję
  Future<bool> hasActiveSubscription() async {
    final status = await getSubscriptionStatus();
    return status.isActive;
  }

  /// 🎯 Sprawdź czy użytkownik ma dostęp do funkcji
  Future<bool> hasFeatureAccess(String feature) async {
    final status = await getSubscriptionStatus();
    return status.hasFeature(feature) || status.isActive;
  }
}
