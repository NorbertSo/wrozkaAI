// lib/services/ai_palm_analysis_service.dart
// POPRAWIONA WERSJA - Gemini Pro Vision zamiast ChatGPT

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import '../models/user_data.dart';

class SimpleAIPalmService {
  // 🔥 NAJNOWSZY: Gemini 2.0 Flash - najlepszy model dla obrazów!
  static const String _geminiApiKey =
      'AIzaSyD7hKeRoP0PJmZwQ95ZibZ9ZJOI4ogop5Ar'; // Wklej klucz z AI Studio
  static const String _geminiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent';

  final math.Random _random = math.Random();

  /// 🔮 GŁÓWNA METODA - teraz używa Gemini Pro Vision
  Future<PalmAnalysisResult> analyzePalm({
    required UserData userData,
    required String handType,
    XFile? palmPhoto,
  }) async {
    try {
      print('🔮 Rozpoczynam PRAWDZIWĄ analizę AI dla: ${userData.name}');

      // Sprawdź czy mamy zdjęcie dłoni
      if (palmPhoto == null) {
        print('❌ Brak zdjęcia dłoni');
        return PalmAnalysisResult.failure('Brak zdjęcia dłoni do analizy');
      }

      // ✅ ZMIANA: Wywołaj Gemini Vision API zamiast ChatGPT
      String analysisText;
      if (_geminiApiKey.isNotEmpty && _geminiApiKey != 'TWÓJ_GEMINI_API_KEY') {
        print('🤖 Wysyłam zdjęcie do Gemini Pro Vision API...');
        analysisText =
            await _analyzeImageWithGemini(palmPhoto, userData, handType);
      } else {
        print('🎭 Używam fallback analizy (brak klucza API)');
        analysisText = _generateFallbackAnalysis(userData, handType);
      }

      print('✅ Analiza zakończona pomyślnie');
      return PalmAnalysisResult.success(
        analysisText: analysisText,
        userName: userData.name,
        handType: handType,
        userGender: userData.genderForMessages,
      );
    } catch (e) {
      print('❌ Błąd analizy: $e');
      // Fallback do lokalnej analizy
      final fallbackText = _generateFallbackAnalysis(userData, handType);
      return PalmAnalysisResult.success(
        analysisText: fallbackText,
        userName: userData.name,
        handType: handType,
        userGender: userData.genderForMessages,
      );
    }
  }

  /// 🔥 NOWA METODA - analiza zdjęcia przez Gemini Pro Vision
  Future<String> _analyzeImageWithGemini(
      XFile palmPhoto, UserData userData, String handType) async {
    try {
      // Konwertuj zdjęcie na base64
      final imageBytes = await palmPhoto.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      print('📸 Zdjęcie zakodowane do base64: ${base64Image.length} znaków');

      // Stwórz prompt dla Gemini Vision
      final prompt = _createGeminiPrompt(userData, handType);

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

      // Wywołaj Gemini API
      final response = await http.post(
        Uri.parse('$_geminiUrl?key=$_geminiApiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // ✅ ZMIANA: Gemini response format
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
      throw e;
    }
  }

  /// 📝 Prompt zoptymalizowany dla Gemini Vision
  String _createGeminiPrompt(UserData userData, String handType) {
    final currentDate = DateTime.now();
    final age = userData.age;
    final zodiacSign = userData.zodiacSign;
    final gender = userData.gender;
    final handName = handType == 'left' ? 'lewej' : 'prawej';
    final genderSuffix = gender == 'female' ? 'a' : '';

    return '''
Jesteś doświadczonym mistrzem chiromancji. Przeanalizuj to zdjęcie dłoni i stwórz szczegółową wróżbę.

👤 INFORMACJE O OSOBIE:
Imię: ${userData.name}
Wiek: $age lat  
Płeć: $gender
Znak zodiaku: $zodiacSign
Analizowana dłoń: $handName
Data: ${_formatPolishDate(currentDate)}

🔍 INSTRUKCJE ANALIZY:
1. Przeanalizuj zdjęcie dłoni pod kątem:
   - Główne linie (życia, serca, głowy, losu)
   - Kształt i proporcje dłoni
   - Wzgórki planetarne
   - Długość i kształt palców
   - Dodatkowe linie i znaki

2. Jeśli obraz jest niewyraźny lub źle oświetlony:
   - Poinformuj o problemach z jakością
   - Wykonaj analizę na podstawie widocznych elementów
   - Stwórz wróżbę uwzględniającą dane osobowe

3. ZAWSZE stwórz kompletną wróżbę - nie odmawiaj analizy!

🎯 STRUKTURA ODPOWIEDZI (800-1000 słów w języku polskim):

🌟 TWOJA NATURA I OSOBOWOŚĆ
[Na podstawie kształtu dłoni i głównych linii - opisz charakter, mocne strony, talenty]

💖 MIŁOŚĆ I ZWIĄZKI  
[Analiza linii serca - prognozy uczuciowe, rady dotyczące relacji]

🚀 KARIERA I SUKCES
[Na podstawie linii losu i wzgórka Merkurego - możliwości zawodowe, przyszłe sukcesy]

💰 FINANSE I MATERIALNE ASPEKTY
[Wzgórki i dodatkowe linie - perspektywy finansowe, rady o pieniądzach]

🌿 ZDROWIE I ENERGIA ŻYCIOWA
[Analiza linii życia - stan zdrowia, rady o dbaniu o siebie]

🔮 NAJBLIŻSZE MIESIĄCE
[Konkretne prognozy na następne 3-6 miesięcy]

✨ SPECJALNE PRZESŁANIE
[Motywująca wiadomość, rada na przyszłość]

WAŻNE ZASADY:
- Zacznij: "Drogi$genderSuffix ${userData.name}, analizując Twoją $handName dłoń widzę..."
- Odwołuj się do konkretnych cech widocznych na zdjęciu
- Uwzględnij wiek ($age lat) i znak zodiaku ($zodiacSign)
- Bądź pozytywny ale wiarygodny
- Jeśli nie widzisz wyraźnie dłoni, wspomnij o jakości zdjęcia
- Używaj ciepłego, mistycznego tonu
- Pisz płynnym tekstem bez formatowania markdown
''';
  }

  /// ✅ USUNIĘTE: _analyzeImageWithChatGPT - zastąpione przez Gemini
  /// ✅ USUNIĘTE: _createVisionPrompt - zastąpione przez _createGeminiPrompt

  /// Reszta metod pozostaje bez zmian...
  String _createSimplePalmPrompt(UserData userData, String handType) {
    final currentDate = DateTime.now();
    final age = userData.age;
    final zodiacSign = userData.zodiacSign;
    final gender = userData.gender;
    final handName = handType == 'left' ? 'lewej' : 'prawej';
    final genderSuffix = gender == 'female' ? 'a' : '';

    return '''
Jesteś doświadczonym chiromantą. Przeanalizuj $handName dłoń dla:

👤 DANE OSOBY:
Imię: ${userData.name}
Wiek: $age lat  
Płeć: $gender
Znak zodiaku: $zodiacSign
Data: ${_formatPolishDate(currentDate)}

🎯 ZADANIE:
Napisz mistyczną, personalną analizę dłoni w języku polskim. Tekst ma być:
- Bezpośrednio skierowany do ${userData.name}
- Podzielony na sekcje z emotikonami
- Pozytywny ale wiarygodny
- Uwzględniający wiek, płeć i znak zodiaku
- Długość: około 800-1000 słów

📝 STRUKTURA ODPOWIEDZI:

🌟 TWOJA NATURA I OSOBOWOŚĆ
[2-3 akapity o charakterze, mocnych stronach, talentach]

💖 MIŁOŚĆ I ZWIĄZKI  
[prognozy uczuciowe, rady dotyczące relacji]

🚀 KARIERA I SUKCES
[możliwości zawodowe, talenty, przyszłe sukcesy]

💰 FINANSE I MATERIALNE ASPEKTY
[perspektywy finansowe, rady dotyczące pieniędzy]

🌿 ZDROWIE I ENERGIA ŻYCIOWA
[stan zdrowia, rady dotyczące dbania o siebie]

🔮 NAJBLIŻSZE MIESIĄCE (${_getMonthName(currentDate.month)} - ${_getMonthName(_getMonthIn3Months(currentDate))})
[konkretne prognozy na najbliższy czas]

✨ SPECJALNE PRZESŁANIE
[motywująca wiadomość, rada na przyszłość]

WAŻNE ZASADY:
- Używaj zwrotów: "Drogi$genderSuffix ${userData.name}", "Twoja $handName dłoń mówi"
- Dostosuj prognozy do wieku (np. nie mów o emeryturze 20-latkowi)  
- Uwzględnij cechy znaku $zodiacSign
- Bądź konkretny w prognozach (podaj okresy, sytuacje)
- Unikaj negatywnych przepowiedni
- Tekst ma brzmieć jak prawdziwa wróżba, nie jak poradnik
''';
  }

  /// ✅ USUNIĘTE: _callOpenAI - zastąpione przez Gemini (jeśli potrzebne)

  /// Czyści odpowiedź AI z niepotrzebnych elementów
  String _cleanAIResponse(String response) {
    return response
        .replaceAll('```', '')
        .replaceAll('**', '')
        .replaceAll('*', '')
        .trim();
  }

  /// Generuje fallback analizę gdy AI nie działa
  String _generateFallbackAnalysis(UserData userData, String handType) {
    final currentDate = DateTime.now();
    final age = userData.age;
    final zodiacSign = userData.zodiacSign;
    final gender = userData.gender;
    final handName = handType == 'left' ? 'lewej' : 'prawej';
    final genderSuffix = gender == 'female' ? 'a' : '';

    final personality = _getPersonalityForZodiac(zodiacSign);
    final element = _getElementForZodiac(zodiacSign);
    final currentMonth = _getMonthName(currentDate.month);
    final nextMonth = _getMonthName(_getNextMonth(currentDate));

    return '''
🌟 TWOJA NATURA I OSOBOWOŚĆ

Drogi$genderSuffix ${userData.name}, Twoja $handName dłoń ujawnia fascynującą osobowość! Jako ${zodiacSign.toLowerCase()}, reprezentujesz element $element, co oznacza ${personality['element_desc']}. 

W Twoich liniach życia widzę silną determinację i naturalną mądrość, która rozwijała się przez Twoje $age lat życia. ${personality['main_trait']} To właśnie te cechy sprawiają, że ludzie naturalne Cię lubią i szukają u Ciebie rady.

Twoja dłoń wskazuje na ${_getPersonalityDetails(age, gender)}, co czyni Cię wyjątkową osobą w swoim otoczeniu.

💖 MIŁOŚĆ I ZWIĄZKI

Linia serca w Twojej dłoni jest ${_getHeartLineDescription(age)}. ${_getLovePredicition(age, gender, zodiacSign)}

W najbliższych miesiącach energia miłosna będzie szczególnie silna. Jeśli jesteś w związku, czeka Was pogłębienie więzi. Jeśli jesteś singlem, ${currentMonth} i ${nextMonth} przyniosą interesujące znajomości.

🚀 KARIERA I SUKCES

Twoja linia losu wskazuje na ${_getCareerPrediction(age)}. ${_getCareerDetails(zodiacSign)} 

Widzę, że Twoje największe sukcesy zawodowe czekają Cię ${_getCareerTimeline(age)}. Nie bój się podejmować nowych wyzwań - Twoja $handName dłoń mówi, że masz w sobie siłę do osiągnięcia wielkich rzeczy.

💰 FINANSE I MATERIALNE ASPEKTY

${_getFinanceReading(age, zodiacSign)} Wzgórek Merkurego w Twojej dłoni jest dobrze rozwinięty, co oznacza naturalne umiejętności w zarządzaniu pieniędzmi.

${_getFinanceAdvice(age)} Pamiętaj, że prawdziwe bogactwo to nie tylko pieniądze, ale także relacje i doświadczenia.

🌿 ZDROWIE I ENERGIA ŻYCIOWA

Linia życia w Twojej dłoni jest ${_getHealthReading(age)}. ${_getHealthAdvice(age, gender)}

Twoja energia życiowa jest silna, ale pamiętaj o regularnym odpoczynku. ${_getSeasonalHealthAdvice(currentDate.month)}

🔮 NAJBLIŻSZE MIESIĄCE ($currentMonth - ${_getMonthName(_getMonthIn3Months(currentDate))})

${_getMonthlyPrediction(currentDate, zodiacSign, age)}

${nextMonth} będzie szczególnie ważny dla Twoich planów długoterminowych. Gwiazdy sprzyjają podejmowaniu ważnych decyzji.

✨ SPECJALNE PRZESŁANIE

Drogi$genderSuffix ${userData.name}, Twoja $handName dłoń nosi w sobie niezwykły potencjał. ${_getSpecialMessage(zodiacSign, age)} 

Pamiętaj: każdy dzień to nowa szansa na realizację marzeń. Twoja dłoń pokazuje, że masz w sobie moc do tworzenia pozytywnych zmian nie tylko w swoim życiu, ale także w życiu innych.

Niech te słowa będą dla Ciebie źródłem siły i inspiracji! 🌟
''';
  }

  // ===== WSZYSTKIE POZOSTAŁE METODY BEZ ZMIAN =====

  Map<String, String> _getPersonalityForZodiac(String zodiac) {
    final personalities = {
      'Baran': {
        'element_desc': 'siłę, energię i naturalną charyzmę przywódczą',
        'main_trait':
            'Jesteś osobą pełną pasji i determinacji, która nie boi się nowych wyzwań.',
      },
      'Byk': {
        'element_desc':
            'stabilność, praktyczność i umiejętność cieszenia się życiem',
        'main_trait':
            'Twoja wytrwałość i lojalność to cechy, które najbardziej cenią w Tobie inni.',
      },
      'Bliźnięta': {
        'element_desc': 'komunikatywność, szybkość myślenia i adaptacyjność',
        'main_trait':
            'Masz niezwykłą umiejętność nawiązywania kontaktów i inspirowania innych.',
      },
      'Rak': {
        'element_desc':
            'empatię, intuicję i głęboką wrażliwość na potrzeby innych',
        'main_trait':
            'Twoja naturalna opiekuńczość sprawia, że ludzie czują się przy Tobie bezpiecznie.',
      },
      'Lew': {
        'element_desc': 'kreatywność, pewność siebie i naturalny magnetyzm',
        'main_trait':
            'Rodzisz się do bycia w centrum uwagi i inspirowania innych swoją energią.',
      },
      'Panna': {
        'element_desc':
            'perfekcjonizm, praktyczność i analityczne podejście do życia',
        'main_trait':
            'Twoja skrupulatność i pomocność są niezastąpione w każdym zespole.',
      },
      'Waga': {
        'element_desc': 'harmonię, sprawiedliwość i estetyczne wyczucie',
        'main_trait':
            'Masz naturalny talent do tworzenia piękna i rozwiązywania konfliktów.',
      },
      'Skorpion': {
        'element_desc': 'intensywność, głębię i umiejętność transformacji',
        'main_trait':
            'Twoja magnetyczna osobowość i intuicja pomagają Ci rozumieć innych lepiej niż oni sami siebie.',
      },
      'Strzelec': {
        'element_desc': 'optymizm, poszukiwanie prawdy i miłość do przygód',
        'main_trait':
            'Twój entuzjazm i otwartość na świat inspirują innych do przekraczania granic.',
      },
      'Koziorożec': {
        'element_desc': 'ambicję, wytrwałość i naturalną mądrość życiową',
        'main_trait':
            'Twoja cierpliwość i systematyczność prowadzą Cię do trwałych sukcesów.',
      },
      'Wodnik': {
        'element_desc': 'oryginalność, humanitaryzm i wizjonerskie myślenie',
        'main_trait':
            'Masz unikalną perspektywę na świat i naturalną potrzebę pomagania innym.',
      },
      'Ryby': {
        'element_desc': 'intuicję, empatię i głęboką duchowość',
        'main_trait':
            'Twoja wrażliwość i kreatywność pozwalają Ci widzieć piękno tam, gdzie inni go nie dostrzegają.',
      },
    };

    return personalities[zodiac] ?? personalities['Baran']!;
  }

  String _getElementForZodiac(String zodiac) {
    switch (zodiac) {
      case 'Baran':
      case 'Lew':
      case 'Strzelec':
        return 'ognia';
      case 'Byk':
      case 'Panna':
      case 'Koziorożec':
        return 'ziemi';
      case 'Bliźnięta':
      case 'Waga':
      case 'Wodnik':
        return 'powietrza';
      default:
        return 'wody';
    }
  }

  String _getPersonalityDetails(int age, String gender) {
    if (age < 25) {
      return gender == 'female'
          ? 'młodą kobietę pełną marzeń i potencjału, która dopiero odkrywa swoje możliwości'
          : 'młodego człowieka o wielkich ambicjach, który ma przed sobą niezliczone możliwości';
    } else if (age < 40) {
      return gender == 'female'
          ? 'dojrzałą kobietę, która wie czego chce od życia i potrafi to osiągnąć'
          : 'osobę w pełni sił, która ma jasną wizję swojej przyszłości';
    } else {
      return gender == 'female'
          ? 'mądrą kobietę, której doświadczenie życiowe jest cennym skarbem'
          : 'osobę o bogatym doświadczeniu, która może być mentorem dla innych';
    }
  }

  String _getHeartLineDescription(int age) {
    final descriptions = [
      'wyraźna i głęboka, co wskazuje na silną potrzebę miłości i bliskości',
      'delikatnie zakrzywiona, co oznacza romantyczną naturę',
      'długa i stabilna, wskazująca na lojalność w związkach',
    ];
    return descriptions[_random.nextInt(descriptions.length)];
  }

  String _getLovePredicition(int age, String gender, String zodiac) {
    if (age < 30) {
      return 'Przed Tobą okres odkrywania prawdziwej miłości. Nie spiesz się - los przygotowuje dla Ciebie kogoś wyjątkowego.';
    } else if (age < 50) {
      return 'Twoje doświadczenia uczuciowe prowadzą Cię do głębszego zrozumienia miłości. Jeśli jesteś w związku, czeka Was nowy etap bliskości.';
    } else {
      return 'Dojrzałość emocjonalna pozwala Ci na budowanie trwałych, harmonijnych relacji opartych na wzajemnym szacunku.';
    }
  }

  String _getCareerPrediction(int age) {
    if (age < 30) return 'period dynamicznego rozwoju zawodowego';
    if (age < 50) return 'stabilizację i umocnienie Twojej pozycji zawodowej';
    return 'czas dzielenia się wiedzą i doświadczeniem z młodszym pokoleniem';
  }

  String _getCareerDetails(String zodiac) {
    final careerTraits = {
      'Baran':
          'Twoja naturalna charyzmą przywódcza otwiera przed Tobą drogi do kierowniczych stanowisk.',
      'Byk':
          'Twoja wytrwałość i praktyczność są bardzo cenione w każdej branży.',
      'Bliźnięta':
          'Twoje umiejętności komunikacyjne otwierają przed Tobą drzwi w mediach, edukacji i handlu.',
      'Rak':
          'Twoja empatia sprawia, że świetnie radzisz sobie w pracy z ludźmi.',
      'Lew':
          'Twoja kreatywność i charyzma predysponują Cię do pracy w branżach kreatywnych.',
      'Panna':
          'Twoja skrupulatność i analityczne myślenie są bezcenne w każdej dziedzinie.',
      'Waga':
          'Twoje poczucie sprawiedliwości i estetyki otwierają przed Tobą wiele możliwości.',
      'Skorpion':
          'Twoja intuicja i determinacja pomagają Ci osiągać cele, które wydają się niemożliwe.',
      'Strzelec':
          'Twój optymizm i otwartość na nowe doświadczenia prowadzą Cię do międzynarodowych sukcesów.',
      'Koziorożec':
          'Twoja systematyczność i ambicja prowadzą Cię prosto na szczyt.',
      'Wodnik':
          'Twoja oryginalność pozwala Ci wprowadzać innowacyjne rozwiązania.',
      'Ryby':
          'Twoja kreatywność i intuicja są bezcenne w dziedzinach artystycznych.',
    };
    return careerTraits[zodiac] ?? careerTraits['Baran']!;
  }

  String _getCareerTimeline(int age) {
    if (age < 25) return 'w ciągu najbliższych 5 lat';
    if (age < 35) return 'przed 40. rokiem życia';
    if (age < 50) return 'w najbliższej dekadzie';
    return 'w formie uznania za dotychczasowe osiągnięcia';
  }

  String _getFinanceReading(int age, String zodiac) {
    final readings = [
      'Twoja dłoń wskazuje na stabilną sytuację finansową.',
      'Widzę pozytywne zmiany w Twoich finansach.',
      'Linie bogactwa w Twojej dłoni są obiecujące.',
    ];
    return readings[_random.nextInt(readings.length)];
  }

  String _getFinanceAdvice(int age) {
    if (age < 30) {
      return 'To dobry czas na naukę zarządzania pieniędzmi i budowanie nawyków oszczędzania.';
    } else if (age < 50) {
      return 'Rozważ długoterminowe inwestycje - Twoja intuicja finansowa jest teraz szczególnie silna.';
    } else {
      return 'Twoje doświadczenie w zarządzaniu finansami może być cenną radą dla innych.';
    }
  }

  String _getHealthReading(int age) {
    if (age < 30) return 'silna i pełna energii';
    if (age < 50) return 'stabilna, ale wymaga więcej uwagi na kondycję';
    return 'mądra - Twoje ciało wie, czego potrzebuje';
  }

  String _getHealthAdvice(int age, String gender) {
    if (age < 30) {
      return 'Buduj teraz zdrowe nawyki, które będą służyć Ci przez całe życie.';
    } else if (age < 50) {
      return gender == 'female'
          ? 'Zwróć szczególną uwagę na równowagę hormonalną i regularne badania.'
          : 'Regularny sport i zdrowa dieta to klucz do utrzymania energii.';
    } else {
      return 'Słuchaj swojego ciała i nie lekceważ żadnych sygnałów ostrzegawczych.';
    }
  }

  String _getSeasonalHealthAdvice(int month) {
    if (month >= 3 && month <= 5) {
      return 'Wiosna to idealny czas na detoks i zwiększenie aktywności fizycznej.';
    } else if (month >= 6 && month <= 8) {
      return 'Latem pamiętaj o nawodnieniu i ochronie przed słońcem.';
    } else if (month >= 9 && month <= 11) {
      return 'Jesień to czas wzmocnienia odporności przed nadchodzącą zimą.';
    } else {
      return 'Zimą szczególnie dbaj o ciepło i suplementację witaminą D.';
    }
  }

  String _getMonthlyPrediction(DateTime date, String zodiac, int age) {
    final currentMonth = _getMonthName(date.month);
    final predictions = [
      '$currentMonth przyniesie Ci nowe możliwości rozwoju osobistego.',
      'W tym miesiącu energia planet szczególnie Ci sprzyja.',
      'Najbliższe tygodnie będą pełne pozytywnych zmian.',
    ];
    return predictions[_random.nextInt(predictions.length)];
  }

  String _getSpecialMessage(String zodiac, int age) {
    final messages = [
      'Jesteś osobą wyjątkową, która ma w sobie moc do zmiany świata na lepsze.',
      'Twoja intuicja i mądrość są Twoimi największymi skarbami.',
      'Pamiętaj, że każde wyzwanie to szansa na rozwój i poznanie siebie.',
    ];
    return messages[_random.nextInt(messages.length)];
  }

  // Date formatting methods
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

/// Klasa rezultatu analizy - BEZ ZMIAN
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
🤚 Nie wykryto dłoni

Przepraszam, ale nie udało mi się wykryć wewnętrznej strony dłoni na obrazie. 

Aby uzyskać dokładną analizę, upewnij się, że:
• Pokazujesz WNĘTRZE dłoni (nie wierzch)
• Dłoń jest dobrze oświetlona
• Wszystkie palce są widoczne
• Dłoń wypełnia większość ramki

Spróbuj ponownie w lepszym oświetleniu! 🌟''',
    );
  }
}
