// lib/services/ai_palm_analysis_service.dart
// POPRAWIONA WERSJA - Kompleksowa analiza z przewodnikiem duchowym

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import '../models/user_data.dart';
import 'firebase_remote_config_service.dart';

class SimpleAIPalmService {
  // 🔥 Gemini 2.0 Flash - najlepszy model dla obrazów

  static const String _geminiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent';

  final math.Random _random = math.Random();

  /// 🔮 GŁÓWNA METODA - analiza z obowiązkowym zdjęciem
  Future<PalmAnalysisResult> analyzePalm({
    required UserData userData,
    required String handType,
    XFile? palmPhoto,
  }) async {
    try {
      print('🔮 Rozpoczynam analizę dla: ${userData.name}');

      // ✅ WYMAGANE ZDJĘCIE - bez zdjęcia brak analizy
      if (palmPhoto == null) {
        print('❌ Brak wymaganego zdjęcia dłoni');
        return PalmAnalysisResult.failure(
            'Analiza wymaga zdjęcia dłoni. Dodaj zdjęcie aby otrzymać swoją wróżbę.');
      }

      String analysisText;
      final remoteConfig = FirebaseRemoteConfigService();
      if (remoteConfig.isConfigReady) {
        print('🤖 Wysyłam do przewodnika duchowego...');
        analysisText =
            await _analyzeImageWithGemini(palmPhoto, userData, handType);
      } else {
        print('🎭 Używam lokalnego przewodnika (brak klucza API)');
        analysisText = _generateSpiritualFallback(userData, handType);
      }

      print('✅ Analiza duchowa zakończona pomyślnie');
      return PalmAnalysisResult.success(
        analysisText: analysisText,
        userName: userData.name,
        handType: handType,
        userGender: userData.genderForMessages,
      );
    } catch (e) {
      print('❌ Błąd analizy: $e');
      // Fallback do duchowej analizy bez obrazu
      final fallbackText = _generateSpiritualFallback(userData, handType);
      return PalmAnalysisResult.success(
        analysisText: fallbackText,
        userName: userData.name,
        handType: handType,
        userGender: userData.genderForMessages,
      );
    }
  }

  /// 🔥 NOWA METODA - analiza przez duchowego przewodnika
  Future<String> _analyzeImageWithGemini(
      XFile palmPhoto, UserData userData, String handType) async {
    try {
      // 🔑 Pobierz klucz z Remote Config
      final remoteConfig = FirebaseRemoteConfigService();
      final apiKey = remoteConfig.geminiApiKey;
      final apiUrl = remoteConfig.geminiApiUrl;

      if (apiKey.isEmpty) {
        throw Exception('Brak klucza Gemini API w Remote Config');
      }

      // Konwertuj zdjęcie na base64
      final imageBytes = await palmPhoto.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      print('📸 Zdjęcie zakodowane do base64: ${base64Image.length} znaków');

      // Stwórz prompt dla Gemini Vision
      final prompt = _createSpiritualPrompt(userData, handType);

      // ✅ ZMIANA: Gemini API format
      final requestBody = {
        "contents": [
          {
            "parts": [
              {"text": prompt},
              {
                "inline_data": {"mime_type": "image/jpeg", "data": base64Image}
              }
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.8,
          "topK": 40,
          "topP": 0.95,
          "maxOutputTokens": 2048,
        }
      };

      // Wywołaj Gemini API z Remote Config URL i kluczem
      final response = await http.post(
        Uri.parse('$apiUrl?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          String content = data['candidates'][0]['content']['parts'][0]['text'];
          print('✅ Gemini przeanalizował zdjęcie dłoni');
          return _cleanAIResponse(content);
        } else {
          throw Exception('Brak odpowiedzi od Gemini');
        }
      } else {
        print('❌ Błąd API Gemini: ${response.statusCode}');
        print('Response: ${response.body}');
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Błąd analizy obrazu: $e');
      rethrow;
    }
  }

  /// 📝 NOWY PROMPT - przewodnik duchowy zamiast AI
  String _createSpiritualPrompt(UserData userData, String handType) {
    final currentDate = DateTime.now();
    final age = userData.age;
    final zodiacSign = userData.zodiacSign;
    final gender = userData.gender;
    final handName = handType == 'left' ? 'lewej' : 'prawej';

    // ✅ ROZSZERZONE DANE - wszystkie dostępne informacje
    String extendedUserInfo = _buildExtendedUserInfo(userData);

    return '''
Jesteś duchowym przewodnikiem i mistrzem CHIROMANCJI (Hast Rekha Shastra). Twoja główna specjalizacja to ANALIZA DŁONI. Inne metody (astrologia) używasz tylko jako wsparcie lub gdy nie można analizować dłoni.

$extendedUserInfo

Analizowana dłoń: $handName
Obecna data: ${_formatPolishDate(currentDate)}

🔍 INSTRUKCJE DUCHOWEJ ANALIZY:

1. **PRIORYTET #1 - ANALIZA ZDJĘCIA DŁONI:**
   - NAJPIERW sprawdź czy widzisz wyraźnie dłoń na zdjęciu
   - Jeśli dłoń jest WYRAŹNA: 80% analizy opieraj na chiromancji, 20% na astrologii
   - Jeśli dłoń jest NIEWYRAŹNA: napisz to wprost i przejdź do analizy astrologicznej
   - ZAWSZE wspominaj co widzisz lub nie widzisz na dłoni

2. **KOLEJNOŚĆ ANALIZY:**
   a) Najpierw sprawdź jakość zdjęcia dłoni
   b) Jeśli widzisz linie - opisz je szczegółowo
   c) Dopiero potem dodaj informacje astrologiczne jako uzupełnienie

3. **CHIROMANCJA - GŁÓWNE ELEMENTY (jeśli widoczne):**
   - **Linia życia** (wokół kciuka) - długość życia, energia, zdrowie
   - **Linia głowy** (pozioma przez środek) - inteligencja, sposób myślenia
   - **Linia serca** (górna pozioma) - uczucia, miłość, relacje
   - **Linia losu** (pionowa przez środek) - kariera, przeznaczenie
   - **Wzgórki** (wypukłości pod palcami) - różne aspekty osobowości
   - **Kształt dłoni i palców** - typ osobowości

4. **TON I CHARAKTER:**
   - Jesteś mistrzem chiromancji, nie AI
   - Odnosisz się przede wszystkim do tego co WIDZISZ na dłoni
   - Informacje astrologiczne traktujesz jako dodatek
   - Używaj imienia osoby naturalnie

5. **STRUKTURA ODPOWIEDZI (900-1200 słów):**

🌟 TWOJA NATURA I OSOBOWOŚĆ
[Analiza charakteru na podstawie dłoni (jeśli widoczna) + znak zodiaku + intuicja duchowa]

💖 MIŁOŚĆ I ZWIĄZKI  
[Linia serca (jeśli widoczna) + astrologiczne prognozy uczuciowe + prawdy o związkach]

🚀 KARIERA I SUKCES
[Linia losu (jeśli widoczna) + predyspozycje zawodowe + duchowe powołanie]

💰 FINANSE I MATERIALNE ASPEKTY
[Wzgórki i linie (jeśli widoczne) + stosunek do materialności + duchowe podejście do pieniędzy]

🌿 ZDROWIE I ENERGIA ŻYCIOWA
[Linia życia (jeśli widoczna) + energia astrologiczna + duchowe rady zdrowotne]

🔮 NAJBLIŻSZE MIESIĄCE
[Konkretne prognozy na 3-6 miesięcy + cykle astrologiczne + duchowa intuicja]

✨ SPECJALNE PRZESŁANIE
[Osobista wiadomość od przewodnika + duchowa rada + motywacja]

5. ZASADY WIARYGODNOŚCI:
   - Jeśli nie widzisz linii, NIE opisuj ich szczegółowo
   - Możesz wspomnieć wyzwania, ale zawsze z rozwiązaniem
   - Prawda jest ważniejsza niż pochlebstwa
   - Każda trudność ma duchowy sens i potencjał wzrostu
   - Nie rób fałszywych obietnic, ale dawaj nadzieję

6. PRZYKŁADY TRUDNYCH PRAWD (z nadzieją):
   - "Widzę, że Twoja skłonność do perfekcjonizmu czasem Cię ogranicza, ale to również Twoja największa siła..."
   - "Niektóre decyzje z przeszłości nadal oddziałują na Twoją teraźniejszość, ale nadszedł czas na ich przemiany..."
   - "Energia wokół Ciebie wskazuje na okres przejściowy, który może przynieść wyzwania, ale także nowe możliwości..."

Rozpocznij analizę, pamiętając że jesteś duchowym przewodnikiem, który widzi prawdę i dzieli się nią z miłością i mądrością.
''';
  }

  /// ✅ NOWA METODA - budowanie rozszerzonych informacji o użytkowniku
  String _buildExtendedUserInfo(UserData userData) {
    List<String> userDetails = [];

    userDetails.add('Imię: ${userData.name}');
    userDetails.add('Wiek: ${userData.age} lat');
    userDetails.add('Płeć: ${_getGenderDescription(userData.gender)}');
    userDetails.add('Znak zodiaku: ${userData.zodiacSign}');

    // ✅ DODATKOWE DANE - tylko jeśli dostępne
    if (userData.birthTime != null) {
      userDetails.add('Godzina urodzenia: ${userData.birthTime}');
    }

    if (userData.birthPlace != null && userData.birthPlace!.isNotEmpty) {
      userDetails.add('Miejsce urodzenia: ${userData.birthPlace}');
    }

    userDetails.add(
        'Dominująca ręka: ${userData.dominantHand == "left" ? "lewa" : "prawa"}');

    // Czas trwania znajomości z aplikacją
    final daysSinceRegistration =
        DateTime.now().difference(userData.registrationDate).inDays;
    if (daysSinceRegistration > 0) {
      userDetails.add('Czas w duchowej podróży: $daysSinceRegistration dni');
    }

    return '''
👤 INFORMACJE O DUSZY, KTÓRĄ PROWADZISZ:
${userDetails.map((detail) => '- $detail').join('\n')}
''';
  }

  String _getGenderDescription(String gender) {
    switch (gender) {
      case 'female':
        return 'kobieta';
      case 'male':
        return 'mężczyzna';
      default:
        return 'osoba niebinarna';
    }
  }

  /// Czyści odpowiedź z AI, aby miała bardziej duchowy charakter
  String _cleanAIResponse(String response) {
    return response
        .replaceAll('```', '')
        .replaceAll('**', '')
        .replaceAll('*', '')
        .replaceAll('AI', 'przewodnik duchowy')
        .replaceAll('sztuczna inteligencja', 'duchowa intuicja')
        .trim();
  }

  /// Czyści odpowiedź duchowego przewodnika
  String _cleanSpiritualResponse(String response) {
    return response
        .replaceAll('```', '')
        .replaceAll('**', '')
        .replaceAll('*', '')
        .replaceAll('AI', 'przewodnik')
        .replaceAll('sztuczna inteligencja', 'duchowa intuicja')
        .trim();
  }

  /// 🔮 DUCHOWA ANALIZA - Przewodnik przemawia

  /// ✅ NOWY FALLBACK - duchowy przewodnik bez obrazu
  String _generateSpiritualFallback(UserData userData, String handType) {
    final currentDate = DateTime.now();
    final age = userData.age;
    final zodiacSign = userData.zodiacSign;
    final gender = userData.gender;
    final handName = handType == 'left' ? 'lewej' : 'prawej';

    final spiritualProfile = _getSpiritualProfileForZodiac(zodiacSign);
    final currentMonth = _getMonthName(currentDate.month);
    final nextMonth = _getMonthName(_getNextMonth(currentDate));

    return '''
🔮 DUCHOWA ANALIZA - Przewodnik przemawia

Niestety, nie mogę wyraźnie dostrzec linii na Twojej dłoni z tego zdjęcia, ale Twoja energia duchowa przemawia do mnie w inny sposób. Pozwól, że poprowadzę Cię przez analizę astrologiczną i energetyczną.

🌟 TWOJA NATURA I OSOBOWOŚĆ

${userData.name}, jako $zodiacSign, nosisz w sobie ${spiritualProfile['spiritual_essence']}. Przez Twoje $age lat życia, ta energia kształtowała Twoją duchową ścieżkę.

${spiritualProfile['personality_insight']}

Twoja $handName dłoń, choć niewidoczna dla oczu, emanuje energią ${_getEnergeticQuality(age, gender)}. To czyni Cię osobą, która ${_getSpiritualPurpose(zodiacSign, age)}.

💖 MIŁOŚĆ I ZWIĄZKI

Energia serca wokół Ciebie ${_getSpiritualLoveReading(age, zodiacSign)}. ${_getSpiritualLoveGuidance(age, gender)}

W nadchodzących miesiącach, szczególnie w $currentMonth i $nextMonth, energia miłosna będzie intensywnie pracować nad Twoimi relacjami. ${_getLoveChallenge(age)}, ale pamiętaj - każde wyzwanie to lekcja duszy.

🚀 KARIERA I SUKCES

Twoja duchowa ścieżka zawodowa wskazuje na ${_getSpiritualCareerGuidance(age, zodiacSign)}. ${_getCareerSpiritualDetails(zodiacSign)}

Widzę, że Twoje największe sukcesy materialne przyjdą ${_getSpiritualCareerTimeline(age)}, ale prawdziwe spełnienie znajdziesz gdy połączysz pracę z duchowym powołaniem.

💰 FINANSE I MATERIALNE ASPEKTY

${_getSpiritualFinanceReading(zodiacSign)} Twój stosunek do pieniędzy odzwierciedla ${_getMoneyLessonForZodiac(zodiacSign)}.

${_getSpiritualFinanceAdvice(age)} Pamiętaj - obfitość przychodzi do tych, którzy są w harmonii ze swoją prawdziwą naturą, ale czasem droga do niej prowadzi przez chwile ograniczeń, które uczą nas wdzięczności.

🌿 ZDROWIE I ENERGIA ŻYCIOWA

Twoja energia życiowa jest ${_getSpiritualHealthReading(age, zodiacSign)}. ${_getSpiritualHealthAdvice(age, gender)}

Przede wszystkim słuchaj swojego ciała - to świątynia Twojej duszy. ${_getSeasonalSpiritualAdvice(currentDate.month)} Czasem ciało sygnalizuje potrzebę zwolnienia tempa, a to nie słabość, lecz mądrość.

🔮 NAJBLIŻSZE MIESIĄCE ($currentMonth - ${_getMonthName(_getMonthIn3Months(currentDate))})

${_getSpiritualMonthlyPrediction(currentDate, zodiacSign, age)}

$nextMonth będzie kluczowy dla Twojego duchowego rozwoju. Gwiazdy szykują test Twojej cierpliwości, ale również otwierają drzwi do nowych możliwości. Zaufaj procesowi, nawet gdy droga wydaje się niepewna.

✨ SPECJALNE PRZESŁANIE

${userData.name}, jako Twój duchowy przewodnik widzę w Tobie ${_getSpiritualSpecialMessage(zodiacSign, age)}

Czasem droga duchowa prowadzi przez momenty wątpliwości czy wyzwań - to normalne i potrzebne. Każda lekcja, nawet trudna, służy Twojemu wzrostowi. Nie bój się swojej mocy, ale używaj jej mądrze.

Twoja dusza wybrała tę ścieżkę nieprzypadkowo. Zaufaj sobie, a Wszechświat będzie Cię wspierać. ✨

~ Twój duchowy przewodnik
''';
  }

  // ===== NOWE METODY DUCHOWE =====

  Map<String, String> _getSpiritualProfileForZodiac(String zodiac) {
    final profiles = {
      'Baran': {
        'spiritual_essence':
            'płomień pionierskiego ducha i naturalnego przywództwa',
        'personality_insight':
            'Twoja dusza nosi w sobie energię wojownika światła - nie tego, który walczy z innymi, ale tego, który przebija się przez własne ograniczenia. Twoja bezpośredniość czasem rani innych, ale wynika z głębokiej potrzeby autentyczności.',
      },
      'Byk': {
        'spiritual_essence':
            'stabilną energię ziemi i głęboką potrzebę harmonii',
        'personality_insight':
            'Jesteś duchowym ogrodnikiem - wszystko, czego dotkniesz, ma szansę zakwitnąć, ale wymaga to czasu i cierpliwości. Twoja pozorna powolność to tak naprawdę mądrość, która wie, że prawdziwe wartości buduje się stopniowo.',
      },
      'Bliźnięta': {
        'spiritual_essence':
            'ruchliwą energię powietrza i dar komunikacji między światami',
        'personality_insight':
            'Twoja dusza jest mostem między różnymi rzeczywistościami. Ta pozorna powierzchowność to tak naprawdę głęboka potrzeba zrozumienia wszystkiego. Czasem czujesz się rozdarty między różnymi ścieżkami, ale to właśnie Twoja siła - widzisz możliwości tam, gdzie inni widzą tylko jedną drogę.',
      },
      'Rak': {
        'spiritual_essence':
            'głęboką energię księżyca i naturalną intuicję opiekuńczą',
        'personality_insight':
            'Jesteś duchową matką/ojcem dla wszystkich wokół, niezależnie od płci. Twoja wrażliwość to nie słabość, ale supermocy, która pozwala Ci odczytywać energie niedostępne innym. Czasem ta intensywność przytłacza, ale bez niej świat byłby dużo bardziej zimnym miejscem.',
      },
      'Lew': {
        'spiritual_essence':
            'słoneczną energię kreatywności i naturalną charyzmę duszy',
        'personality_insight':
            'Twoja dusza przyszła na świat, by świecić i inspirować innych. Ta potrzeba uwagi nie wynika z ego, ale z głębokiego pragnienia dzielenia się swoim światłem. Czasem Twoja duma może Cię ograniczać, ale pamiętaj - prawdziwe królewskość to służba innym.',
      },
      'Panna': {
        'spiritual_essence':
            'energię perfekcji i głęboką potrzebę służenia wyższemu celowi',
        'personality_insight':
            'Jesteś duchowym alchemikiem - potrafisz przekształcać chaos w porządek, ale czasem ten dar staje się przekleństwem, gdy kierujesz go przeciwko sobie. Twój perfekcjonizm to tak naprawdę tęsknota za doskonałością duchową.',
      },
      'Waga': {
        'spiritual_essence':
            'energię równowagi i naturalną potrzebę tworzenia piękna',
        'personality_insight':
            'Twoja dusza jest dyplomatą kosmicznych energii. Widzisz piękno i harmonię tam, gdzie inni dostrzegają tylko konflikt. Ta potrzeba zadowolenia wszystkich czasem prowadzi do wewnętrznych rozdarć, ale Twoja misja to pokazanie światu, że pokój jest możliwy.',
      },
      'Skorpion': {
        'spiritual_essence': 'transformacyjną energię śmierci i odrodzenia',
        'personality_insight':
            'Jesteś duchowym alchemikiem, który przekształca ciemność w światło. Twoja intensywność przeraża innych, ale to dlatego, że widzisz prawdy, które wolą ukrywać. Każda Twoja "śmierć" duchowa to przygotowanie do potężniejszego odrodzenia.',
      },
      'Strzelec': {
        'spiritual_essence': 'energię poszukiwacza prawdy i duchowego odkrywcy',
        'personality_insight':
            'Twoja dusza to wieczny pielgrzym, szukający sensu w każdym doświadczeniu. Ta pozorna niestałość to tak naprawdę głęboka mądrość, która wie, że prawda ma wiele twarzy. Czasem Twoja szczerość boli innych, ale to cena za autentyczność.',
      },
      'Koziorożec': {
        'spiritual_essence': 'energię duchowego mistrza i naturalnego lidera',
        'personality_insight':
            'Jesteś starą duszą, która przyszła na świat z misją budowania trwałych fundamentów. Ta pozorna surowość to tak naprawdę głęboka odpowiedzialność za innych. Czasem nosisz ciężar świata na swoich ramionach, ale pamiętaj - prawdziwa siła leży w delegowaniu.',
      },
      'Wodnik': {
        'spiritual_essence': 'energię wizjonera i duchowego rewolucjonisty',
        'personality_insight':
            'Twoja dusza przyszła z przyszłości, by pomóc ludzkości ewoluować. Ta pozorna obojętność to tak naprawdę ochrona przed zbyt intensywnymi emocjami, które mogłyby Cię przytłoczyć. Jesteś mostrem między tym, co jest, a tym, co mogłoby być.',
      },
      'Ryby': {
        'spiritual_essence':
            'energię mistyka i naturalną łączność z kosmiczną świadomością',
        'personality_insight':
            'Jesteś duchowym empatą, który odczuwa ból całego świata. Ta wrażliwość to dar i przekleństwo jednocześnie. Czasem uciekasz w marzenia, bo rzeczywistość jest zbyt intensywna, ale Twoja misja to pokazanie innym, że miłość bezwarunkowa jest możliwa.',
      },
    };

    return profiles[zodiac] ?? profiles['Baran']!;
  }

  String _getEnergeticQuality(int age, String gender) {
    if (age < 25) {
      return 'młodą, ale intensywną, pełną potencjału czekającego na ujawnienie';
    } else if (age < 40) {
      return 'dojrzałą i świadomą, która już poznała smak prawdziwej mocy';
    } else {
      return 'mądrą i zrównoważoną, która nosi w sobie skarby życiowych doświadczeń';
    }
  }

  String _getSpiritualPurpose(String zodiac, int age) {
    final purposes = {
      'Baran': 'inspiruje innych do działania i przełamywania barier',
      'Byk': 'tworzy stabilność i piękno w chaotycznym świecie',
      'Bliźnięta': 'łączy ludzi i idee w nieoczekiwane sposoby',
      'Rak': 'oferuje bezpieczną przystań dla zranionych dusz',
      'Lew': 'rozpala ogień kreatywności w sercach innych',
      'Panna': 'doskonali świat poprzez służbę i oddanie',
      'Waga': 'przywraca harmonię tam, gdzie panuje konflikt',
      'Skorpion': 'pomaga innym przejść przez duchowe transformacje',
      'Strzelec': 'prowadzi innych ku wyższej prawdzie i mądrości',
      'Koziorożec': 'buduje fundamenty dla przyszłych pokoleń',
      'Wodnik': 'przynosi wizje lepszej przyszłości dla ludzkości',
      'Ryby': 'oferuje bezwarunkową miłość i duchowe wsparcie',
    };
    return purposes[zodiac] ?? purposes['Baran']!;
  }

  // Dodatkowe metody duchowe...
  String _getSpiritualLoveReading(int age, String zodiac) {
    if (age < 30) {
      return 'jest w fazie odkrywania - uczysz się różnicy między miłością a potrzebą';
    } else if (age < 50) {
      return 'przechodzi przez głęboką transformację - stare wzorce ustępują miejsca autentycznej bliskości';
    } else {
      return 'osiągnęła mądrość - rozumiesz już, że prawdziwa miłość zaczyna się od siebie';
    }
  }

  String _getSpiritualLoveGuidance(int age, String gender) {
    if (age < 30) {
      return 'Nie spiesz się z ważnymi decyzjami sercowymi. Czasem samotność to nie kara, ale czas na poznanie siebie.';
    } else {
      return 'Twoje serce już wie, czego potrzebuje. Zaufaj swojej intuicji, nawet jeśli rozum protestuje.';
    }
  }

  String _getLoveChallenge(int age) {
    final challenges = [
      'Czeka Cię test cierpliwości w relacjach',
      'Będziesz musiał/a stawić czoła starym ranom serca',
      'Nadchodzi czas podejmowania trudnych decyzji o przyszłości związku',
      'Twoja potrzeba niezależności zderzy się z pragnieniem bliskości',
    ];
    return challenges[math.Random().nextInt(challenges.length)];
  }

  // ... pozostałe metody duchowe ...
  String _getSpiritualCareerGuidance(int age, String zodiac) {
    if (age < 30) {
      return 'okres eksperymentowania i odkrywania prawdziwego powołania';
    }
    if (age < 50) {
      return 'czas wykorzystania nabytej wiedzy dla służenia wyższemu celowi';
    }
    return 'fazę dzielenia się mądrością i wspierania młodszych na ich ścieżce';
  }

  String _getCareerSpiritualDetails(String zodiac) {
    final details = {
      'Baran':
          'Twoje powołanie to przewodzenie zmianom i inspirowanie innych do odwagi.',
      'Byk':
          'Znajdziesz spełnienie w pracy, która tworzy trwałe wartości i piękno.',
      'Bliźnięta':
          'Twoja misja to łączenie ludzi, idei i światów przez komunikację.',
      'Rak':
          'Prawdziwe powołanie znajdziesz w opiekowaniu się innymi i tworzeniu bezpiecznych przestrzeni.',
      'Lew':
          'Jesteś tu, by inspirować innych przez swoją kreatywność i autentyczność.',
      'Panna':
          'Twoja ścieżka to służba innym przez doskonalenie i uzdrawianie.',
      'Waga': 'Znajdziesz sens w tworzeniu piękna, sprawiedliwości i harmonii.',
      'Skorpion': 'Twoje powołanie to transformacja - własna i innych ludzi.',
      'Strzelec':
          'Jesteś tu, by szerzyć mądrość i inspirować innych do poszukiwania prawdy.',
      'Koziorożec':
          'Twoja misja to budowanie trwałych struktur dla dobra przyszłych pokoleń.',
      'Wodnik':
          'Znajdziesz spełnienie w pracy na rzecz ludzkości i przyszłości.',
      'Ryby':
          'Twoje powołanie to uzdrawianie świata przez miłość i współczucie.',
    };
    return details[zodiac] ?? details['Baran']!;
  }

  String _getSpiritualCareerTimeline(int age) {
    if (age < 25) {
      return 'gdy zaczniesz słuchać głosu swojego serca, a nie oczekiwań innych';
    }
    if (age < 35) return 'gdy połączysz swoją pasję z służbą innym';
    if (age < 50) {
      return 'gdy znajdziesz równowagę między sukcesem materialnym a duchowym spełnieniem';
    }
    return 'gdy zaczniesz przekazywać swoją mądrość młodszym pokoleniom';
  }

  String _getSpiritualFinanceReading(String zodiac) {
    final readings = [
      'Twój stosunek do pieniędzy odzwierciedla Twoją relację z własną wartością.',
      'Finanse są dla Ciebie narzędziem do realizacji wyższych celów, nie celem samym w sobie.',
      'Czeka Cię lekcja o prawdziwej obfitości - czasem trzeba stracić, by zrozumieć, co naprawdę jest wartościowe.',
    ];
    return readings[math.Random().nextInt(readings.length)];
  }

  String _getMoneyLessonForZodiac(String zodiac) {
    final lessons = {
      'Baran': 'potrzebę nauczenia się cierpliwości w gromadzeniu bogactwa',
      'Byk': 'naturalną umiejętność przyciągania obfitości przez wytrwałość',
      'Bliźnięta':
          'lekcję o tym, że prawdziwe bogactwo leży w różnorodności doświadczeń',
      'Rak':
          'głęboką potrzebę bezpieczeństwa finansowego dla siebie i bliskich',
      'Lew':
          'naukę o tym, że prawdziwe bogactwo to możliwość dzielenia się z innymi',
      'Panna': 'umiejętność praktycznego zarządzania zasobami',
      'Waga': 'potrzebę równowagi między wydawaniem a oszczędzaniem',
      'Skorpion':
          'transformacyjne podejście do pieniędzy - albo wszystko, albo nic',
      'Strzelec':
          'lekcję o tym, że pieniądze to wolność do podróżowania po życiu',
      'Koziorożec': 'naturalną zdolność do budowania długoterminowego bogactwa',
      'Wodnik': 'naukę o tym, że pieniądze powinny służyć wyższym celom',
      'Ryby':
          'duchowe podejście do materialności - czasem tracisz, by ktoś inny mógł zyskać',
    };
    return lessons[zodiac] ?? lessons['Baran']!;
  }

  String _getSpiritualFinanceAdvice(int age) {
    if (age < 30) {
      return 'Nie gon za pieniędzmi - gon za pasją, a pieniądze same Cię znajdą. Czasem wydaje się, że inni mają więcej, ale każdy ma swoją ścieżkę do obfitości.';
    } else if (age < 50) {
      return 'To dobry czas, by zastanowić się, czy Twoje finanse odzwierciedlają Twoje prawdziwe wartości. Czasem trzeba zrezygnować z czegoś dobrze płatnego, by znaleźć prawdziwe spełnienie.';
    } else {
      return 'Twoje doświadczenie z pieniędzmi to skarb. Podziel się tym, czego się nauczyłeś - ale pamiętaj, że dawanie nie oznacza wyczerpywania siebie.';
    }
  }

  String _getSpiritualHealthReading(int age, String zodiac) {
    if (age < 30) {
      return 'pełna potencjału, ale czasem nadwyrężana przez młodzieńczy brak umiaru';
    }
    if (age < 50) {
      return 'w fazie uczenia się równowagi między ambitnymi celami a potrzebami ciała';
    }
    return 'mądra i doświadczona, ale wymagająca większej uwagi i szacunku';
  }

  String _getSpiritualHealthAdvice(int age, String gender) {
    if (age < 30) {
      return 'Twoje ciało to nie maszyna - ma swoje granice i potrzeby. Naucz się je słuchać teraz, zanim zacznie krzyczeć.';
    } else if (age < 50) {
      return 'Stress to nie odznaka honoru. Czasem zwolnienie tempa to nie lenistwo, ale mądrość. Twoje ciało pamięta każdy nadmiar.';
    } else {
      return 'Teraz Twoje ciało potrzebuje więcej delikatności i cierpliwości. To nie słabość, ale naturalna ewolucja - szanuj ten proces.';
    }
  }

  String _getSeasonalSpiritualAdvice(int month) {
    if (month >= 3 && month <= 5) {
      return 'Wiosenna energia wspiera detoksykację - nie tylko fizyczną, ale i emocjonalną.';
    } else if (month >= 6 && month <= 8) {
      return 'Letnia energia jest intensywna - chroń się przed przepaleniem, zarówno słonecznym jak i życiowym.';
    } else if (month >= 9 && month <= 11) {
      return 'Jesienna energia uczy nas odpuszczania - tego, co już nie służy naszemu rozwojowi.';
    } else {
      return 'Zimowa energia zachęca do introspekcji i regeneracji - nie walcz z naturalnymi cyklami.';
    }
  }

  String _getSpiritualMonthlyPrediction(DateTime date, String zodiac, int age) {
    final currentMonth = _getMonthName(date.month);
    final predictions = [
      '$currentMonth przyniesie Ci duchowe wyzwanie, które na początku może wydawać się przeszkodą, ale okaże się bramą do nowych możliwości.',
      'W tym miesiącu Wszechświat testuje Twoją cierpliwość. Nie wszystko przyjdzie łatwo, ale każda trudność ma swoją duchową lekcję.',
      'Najbliższe tygodnie będą wymagały od Ciebie podjęcia trudnej decyzji. Zaufaj swojej intuicji, nawet jeśli inni będą protestować.',
      'Energia tego miesiąca może przynieść zakończenia - ale pamiętaj, że każde zakończenie to jednocześnie nowy początek.',
    ];
    return predictions[math.Random().nextInt(predictions.length)];
  }

  String _getSpiritualSpecialMessage(String zodiac, int age) {
    final messages = [
      'niespożytą moc, która czeka na właściwy moment, by się objawić. Nie forsuj tego procesu - prawdziwa transformacja potrzebuje czasu.',
      'starą duszę w młodym ciele (lub mądrą duszę w dojrzałym ciele), która przyszła tu z ważną misją. Czasem czujesz się samotny, bo niewielu rozumie Twoją głębię.',
      'naturalne uzdrowiciela, który leczy innych już samą swoją obecnością. To dar, ale też odpowiedzialność - nie zapomnij zadbać o siebie.',
      'duchowego wojownika, który walczy nie mieczem, ale prawdą i miłością. Twoje bitwy toczą się w sferze energii i świadomości.',
    ];
    return messages[math.Random().nextInt(messages.length)];
  }

  // ===== POZOSTAŁE METODY BEZ ZMIAN =====

  String _formatPolishDate(DateTime date) {
    return '${date.day} ${_getMonthNameGenitive(date.month)} ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'Styczeń',
      'Luty',
      'Marzec',
      'Kwiecień',
      'Maj',
      'Czerwiec',
      'Lipiec',
      'Sierpień',
      'Wrzesień',
      'Październik',
      'Listopad',
      'Grudzień'
    ];
    return months[month - 1];
  }

  String _getMonthNameGenitive(int month) {
    const months = [
      'stycznia',
      'lutego',
      'marca',
      'kwietnia',
      'maja',
      'czerwca',
      'lipca',
      'sierpnia',
      'września',
      'października',
      'listopada',
      'grudnia'
    ];
    return months[month - 1];
  }

  int _getNextMonth(DateTime date) {
    return date.month == 12 ? 1 : date.month + 1;
  }

  int _getMonthIn3Months(DateTime date) {
    int targetMonth = (date.month + 2) % 12;
    return targetMonth == 0 ? 12 : targetMonth;
  }
}

/// ✅ KLASA REZULTATU - BEZ ZMIAN
class PalmAnalysisResult {
  final bool isSuccess;
  final String analysisText;
  final String? errorMessage;
  final String? userName;
  final String? handType;
  final String? userGender;

  PalmAnalysisResult._({
    required this.isSuccess,
    required this.analysisText,
    this.errorMessage,
    this.userName,
    this.handType,
    this.userGender,
  });

  factory PalmAnalysisResult.success({
    required String analysisText,
    required String userName,
    required String handType,
    required String userGender,
  }) {
    return PalmAnalysisResult._(
      isSuccess: true,
      analysisText: analysisText,
      userName: userName,
      handType: handType,
      userGender: userGender,
    );
  }

  factory PalmAnalysisResult.failure(String errorMessage) {
    return PalmAnalysisResult._(
      isSuccess: false,
      analysisText: '',
      errorMessage: errorMessage,
    );
  }

  factory PalmAnalysisResult.noHandDetected() {
    return PalmAnalysisResult._(
      isSuccess: false,
      analysisText: '',
      errorMessage: '''
🤚 Przewodnik nie może dostrzec dłoni

Przepraszam, ale duchowe oko nie może wyraźnie dostrzec linii na Twojej dłoni z tego zdjęcia. 

Aby otrzymać pełną analizę chiromantyczną, upewnij się, że:
• Pokazujesz WNĘTRZE dłoni (nie wierzch)
• Dłoń jest dobrze oświetlona
• Wszystkie palce są widoczne i rozłożone
• Dłoń wypełnia większość kadru

Spróbuj ponownie w lepszym oświetleniu - przewodnik czeka na jaśniejszy obraz Twojej duchowej mapy! 🌟''',
    );
  }
}
