# 🔮 System Cachowania Horoskopów Rozbudowanych

## 📋 Przegląd

System cachowania zapobiega podwójnym płatnościom za ten sam horoskop dzienny. Użytkownik, który zakupi horoskop rozbudowany w danym dniu, może do niego wracać bez dodatkowych opłat do godziny 6:00 następnego dnia.

## 🏗️ Architektura

### Komponenty:
1. **`CachedHoroscope`** - Model danych dla cachowanego horoskopu
2. **`HoroscopeCacheService`** - Serwis zarządzający cache w Firestore
3. **`ExtendedHoroscopeScreen`** - Zmodyfikowany ekran z integracją cache

## 🕐 Logika Ważności

```
Zakup: 2025-01-15 14:30
Ważny do: 2025-01-16 06:00
```

Horoskop zakupiony o dowolnej porze jest ważny do 6:00 rano następnego dnia.

## 🔄 Flow Użytkownika

### Pierwszy Dostęp (Brak Cache)
1. Użytkownik wchodzi na ekran horoskopu
2. System sprawdza cache → **Brak horoskopu**
3. Wyświetla dialog płatności
4. Po płatności → generuje horoskop
5. **Zapisuje do cache**
6. Wyświetla horoskop

### Kolejny Dostęp (Istnieje Cache)
1. Użytkownik wchodzi na ekran horoskopu
2. System sprawdza cache → **Znajdzie horoskop**
3. Sprawdza ważność → **Ważny**
4. **Bezpośrednio wyświetla horoskop**
5. Pokazuje informację o czasie ważności

### Dostęp Po Wygaśnięciu
1. Użytkownik wchodzi na ekran horoskopu
2. System sprawdza cache → **Znajdzie horoskop**
3. Sprawdza ważność → **Wygasły**
4. **Usuwa z cache**
5. Wyświetla dialog płatności (jak przy pierwszym dostępie)

## 📊 Struktura Danych

### CachedHoroscope
```dart
{
  userId: String,
  purchaseDate: DateTime,    // Dzień zakupu (bez godziny)
  validUntil: DateTime,      // Ważny do (następny dzień 06:00)
  horoscopeData: Map<String, String>,
  userName: String,
  userGender: String,
  birthDate: DateTime?,
  dominantHand: String?,
  relationshipStatus: String?,
  primaryConcern: String?
}
```

### Firestore Collection: `cached_horoscopes`
Document ID Format: `{userId}_{YYYY-MM-DD}`

Przykład: `user123_2025-01-15`

## 🛠️ API Serwisu

### HoroscopeCacheService

```dart
// Sprawdź czy user ma ważny horoskop na dziś
Future<CachedHoroscope?> getTodaysHoroscope()

// Sprawdź czy user zakupił już dziś (bool)
Future<bool> hasTodaysHoroscope()

// Zapisz nowy horoskop po zakupie
Future<bool> saveHoroscope(CachedHoroscope horoscope)

// Utwórz horoskop dla aktualnego usera
Future<CachedHoroscope> createHoroscopeForUser({...})

// Historia horoskopów
Future<List<CachedHoroscope>> getHoroscopeHistory({int limit = 30})

// Wyczyść wygasłe (maintenance)
Future<void> cleanupExpiredHoroscopes()

// Statystyki
Future<HoroscopeCacheStats> getStats()
```

## 🎨 UI/UX

### Wskaźnik Ważności
W nagłówku horoskopu wyświetla się informacja:
- ⏰ "Ważny jeszcze 3h 45min"
- ⏰ "Ważny jeszcze 25min"
- ⏰ "Horoskop wygasł"

### Zachowanie Ekranu
- **Z cache**: Natychmiastowe wyświetlenie horoskopu
- **Bez cache**: Loading → Dialog płatności → Horoskop
- **Wygasły cache**: Usunięcie + dialog płatności

## 🧹 Maintenance

### Auto-cleanup
System automatycznie usuwa wygasłe horokorty przy:
- Inicjalizacji `HoroscopeCacheService`
- Wejściu na ekran horoskopu
- Wywołaniu `cleanupExpiredHoroscopes()`

### Optymalizacja Storage
- Jeden dokument na użytkownika na dzień
- Automatyczne usuwanie po wygaśnięciu
- Kompaktowa struktura danych

## 🔐 Bezpieczeństwo

### Walidacja
- Sprawdzenie `userId` przed każdą operacją
- Walidacja ważności po odczycie z cache
- Automatyczne usuwanie nieprawidłowych danych

### Firestore Rules (Propozycja)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /cached_horoscopes/{document} {
      allow read, write: if request.auth != null 
        && document.split('_')[0] == resource.data.userId;
    }
  }
}
```

## 📈 Metryki

### Monitorowanie
- Liczba cachowanych horoskopów
- Wskaźnik hit/miss cache
- Średni czas ważności
- Częstotliwość powrotów użytkowników

### Przykładowe Statystyki
```dart
HoroscopeCacheStats {
  totalCached: 156,
  validCached: 23,
  hasTodaysHoroscope: true,
  todaysExpiryInfo: "Wygasa za 4h 15min"
}
```

## 🚀 Wdrożenie

### Etapy
1. ✅ Utworzenie modeli i serwisów
2. ✅ Integracja z `ExtendedHoroscopeScreen`
3. ✅ Testy jednostkowe
4. 🔄 Testy integracyjne
5. 🔄 Monitoring i optymalizacja

### Kompatybilność
- System jest w pełni kompatybilny wstecznie
- Nie wpływa na istniejące płatności
- Może być rozszerzony na inne typy horoskopów

## 🔮 Przyszłe Rozszerzenia

### Możliwe Usprawnienia
1. **Cache dla horoskopów tygodniowych** (ważny cały tydzień)
2. **Cache dla analizy dłoni** (ważny przez miesiąc)
3. **Synchronizacja offline** z local storage
4. **Preemptywne generowanie** horoskopów o północy
5. **Personalizacja czasu ważności** na podstawie strefy czasowej

### Przykład Rozszerzenia
```dart
// Dla horoskopów tygodniowych
CachedWeeklyHoroscope.forThisWeek(...)
// Ważny przez cały tydzień (poniedziałek-niedziela)

// Dla analizy dłoni  
CachedPalmReading.forThisMonth(...)
// Ważny przez cały miesiąc
```
