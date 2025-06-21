# 🔊 Implementacja Wibracji w AI Wróżka

## 📋 Kroki implementacji

### 1. Dodaj zależności do pubspec.yaml
```bash
flutter pub add vibration
flutter pub get
```

### 2. Skopiuj pliki
- `lib/services/haptic_service.dart`
- `lib/widgets/haptic_button.dart`

### 3. Zaktualizuj main.dart
```dart
// Dodaj import
import 'services/haptic_service.dart';

// W _AppInitializerState dodaj inicjalizację
final HapticService _hapticService = HapticService();

// W _initializeApp() dodaj:
await _hapticService.initialize();
await _hapticService.printCapabilities();
```

### 4. Zaktualizuj AndroidManifest.xml
```xml
<uses-permission android:name="android.permission.VIBRATE" />
```

### 5. Zastąp przyciski HapticButton-ami

## 🎯 Rodzaje wibracji

| Typ | Użycie | Czas | Siła |
|-----|--------|------|------|
| `HapticType.light` | Przyciski, hover | 50ms | Lekka |
| `HapticType.medium` | Nawigacja, przełączanie | 80ms | Średnia |
| `HapticType.heavy` | Ważne akcje | 120ms | Mocna |
| `HapticType.selection` | Checkbox, radio, toggle | - | Selekcja |
| `HapticType.impact` | Potwierdzenia | 60ms | Kliknięcie |
| `HapticType.success` | Sukces | 2x100ms | Podwójna |
| `HapticType.warning` | Ostrzeżenia | 200ms | Długa |
| `HapticType.error` | Błędy | 3x80ms | Potrójna |

## 🔧 Przykłady użycia

### Podstawowy przycisk
```dart
HapticButton(
  text: 'Kliknij mnie',
  onPressed: () => print('Kliknięto!'),
  hapticType: HapticType.light,
)
```

### Przycisk główny (CTA)
```dart
HapticPrimaryButton(
  text: 'Rozpocznij',
  onPressed: () => navigateToNext(),
  icon: Icons.arrow_forward,
)
```

### Przycisk ikony
```dart
HapticIconButton(
  icon: Icons.settings