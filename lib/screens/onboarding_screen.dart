// lib/screens/onboarding_screen.dart
// Zaktualizowany - z miejscem i godziną urodzenia + persistencja + poprawki

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../utils/constants.dart';
import '../models/user_data.dart';
import '../services/user_preferences_service.dart';
import 'main_menu_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _birthPlaceController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _selectedGender = '';
  String _selectedHand = '';
  bool _rememberBirthTime = true; // Domyślnie chcemy pamiętać godzinę

  late AnimationController _fadeController;
  late AnimationController _formController;
  late AnimationController _glowController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _formController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeOutCubic),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _startAnimations();
    _showPrivacyDialog();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _formController.forward();
  }

  void _showPrivacyDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildPrivacyDialog(),
      );
    });
  }

  Widget _buildPrivacyDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A2332), Color(0xFF0B1426)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cyan.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.cyan.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.security, color: AppColors.cyan, size: 48),
            const SizedBox(height: 16),
            Text(
              'Prywatność Twoich Danych',
              style: GoogleFonts.cinzelDecorative(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Twoje dane są zbierane tylko do celów analizy dłoni i tworzenia spersonalizowanej wróżby. Miejsce i godzina urodzenia pomagają w dokładniejszej interpretacji.',
              style: GoogleFonts.cinzelDecorative(
                fontSize: 14,
                fontWeight: FontWeight.w300,
                color: Colors.white70,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan.withOpacity(0.2),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                    side: BorderSide(
                      color: AppColors.cyan.withOpacity(0.6),
                      width: 1,
                    ),
                  ),
                ),
                child: Text(
                  'Rozumiem',
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthPlaceController.dispose();
    _fadeController.dispose();
    _formController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.welcomeGradient,
          ),
        ),
        child: Stack(
          children: [
            // Animowane tło z gwiazdami
            SizedBox.expand(
              child: Lottie.asset(
                'assets/animations/star_bg.json',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),

            // Główna zawartość
            SafeArea(
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 40),

                              // Tytuł
                              Text(
                                'UZUPEŁNIJ\nDANE',
                                style: GoogleFonts.cinzelDecorative(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.cyan,
                                  letterSpacing: 2.0,
                                  height: 1.2,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 60),

                              // Pole imię
                              _buildInputField(
                                label: 'Imię',
                                controller: _nameController,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Podaj swoje imię';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 32),

                              // Pole data urodzenia
                              _buildDateField(),

                              const SizedBox(height: 32),

                              // Pole godzina urodzenia (opcjonalne)
                              _buildTimeField(),

                              const SizedBox(height: 32),

                              // Pole miejsce urodzenia (OPCJONALNE)
                              _buildInputField(
                                label: 'Miejsce urodzenia (opcjonalne)',
                                controller: _birthPlaceController,
                                hint: 'np. Warszawa, Kraków, Gdańsk...',
                                isOptional: true,
                              ),

                              const SizedBox(height: 32),

                              // Wybór płci
                              _buildGenderSelection(),

                              const SizedBox(height: 32),

                              // Wybór ręki głównej
                              _buildHandSelection(),

                              const SizedBox(height: 60),

                              // Przycisk kontynuuj
                              AnimatedBuilder(
                                animation: _glowAnimation,
                                builder: (context, child) {
                                  return Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.cyan.withOpacity(
                                            0.3 + (_glowAnimation.value * 0.5),
                                          ),
                                          blurRadius:
                                              20 + (_glowAnimation.value * 20),
                                          spreadRadius:
                                              2 + (_glowAnimation.value * 5),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _handleContinue,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 18,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                          side: BorderSide(
                                            color: AppColors.cyan.withOpacity(
                                              0.8 +
                                                  (_glowAnimation.value * 0.2),
                                            ),
                                            width: 2,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: Text(
                                        'Wejdź do Świata Wróż',
                                        style: GoogleFonts.cinzelDecorative(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String? hint,
    String? Function(String?)? validator,
    bool isOptional = false,
  }) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        final hasContent = controller.text.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.cinzelDecorative(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: hasContent
                      ? AppColors.cyan.withOpacity(0.6)
                      : Colors.grey.withOpacity(0.4),
                  width: hasContent ? 2 : 1.5,
                ),
                boxShadow: hasContent
                    ? [
                        BoxShadow(
                          color: AppColors.cyan.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: TextFormField(
                controller: controller,
                validator: validator,
                onChanged: (value) => setState(() {}), // Refresh border color
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w300,
                ),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.2),
                  hintText: hint,
                  hintStyle: GoogleFonts.cinzelDecorative(
                    color: Colors.white38,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateField() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        final hasDate = _selectedDate != null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data urodzenia',
              style: GoogleFonts.cinzelDecorative(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: hasDate
                      ? AppColors.cyan.withOpacity(0.6)
                      : Colors.grey.withOpacity(0.4),
                  width: hasDate ? 2 : 1.5,
                ),
                boxShadow: hasDate
                    ? [
                        BoxShadow(
                          color: AppColors.cyan.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.black.withOpacity(0.2),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          hasDate
                              ? '${_selectedDate!.day.toString().padLeft(2, '0')}.${_selectedDate!.month.toString().padLeft(2, '0')}.${_selectedDate!.year}'
                              : 'Wybierz datę urodzenia',
                          style: GoogleFonts.cinzelDecorative(
                            fontSize: 16,
                            color: hasDate ? Colors.white : Colors.white38,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.calendar_today,
                        color: hasDate
                            ? AppColors.cyan.withOpacity(0.8)
                            : Colors.grey.withOpacity(0.6),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimeField() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        final hasTime = _selectedTime != null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Godzina urodzenia',
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(opcjonalne)',
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Pole godziny
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: _rememberBirthTime
                      ? (hasTime
                          ? AppColors.cyan.withOpacity(0.6)
                          : Colors.grey.withOpacity(0.4))
                      : Colors.grey.withOpacity(0.3),
                  width: (_rememberBirthTime && hasTime) ? 2 : 1.5,
                ),
                boxShadow: (_rememberBirthTime && hasTime)
                    ? [
                        BoxShadow(
                          color: AppColors.cyan.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: InkWell(
                onTap: _rememberBirthTime ? _selectTime : null,
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: _rememberBirthTime
                        ? Colors.black.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.1),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          hasTime
                              ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                              : _rememberBirthTime
                                  ? 'Wybierz godzinę urodzenia'
                                  : 'Godzina nieznana',
                          style: GoogleFonts.cinzelDecorative(
                            fontSize: 16,
                            color: _rememberBirthTime
                                ? (hasTime ? Colors.white : Colors.white38)
                                : Colors.grey,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.access_time,
                        color: _rememberBirthTime
                            ? (hasTime
                                ? AppColors.cyan.withOpacity(0.8)
                                : Colors.grey.withOpacity(0.6))
                            : Colors.grey,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Checkbox "Nie pamiętam godziny" - PRZENIESIONY POD POLE GODZINY
            Row(
              children: [
                Transform.scale(
                  scale: 0.9,
                  child: Checkbox(
                    value: !_rememberBirthTime,
                    onChanged: (value) {
                      setState(() {
                        _rememberBirthTime = !(value ?? false);
                        if (!_rememberBirthTime) {
                          _selectedTime = null;
                        }
                      });
                    },
                    activeColor: AppColors.cyan,
                    checkColor: Colors.black,
                    side: BorderSide(
                      color: AppColors.cyan.withOpacity(0.6),
                      width: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Nie pamiętam godziny urodzenia',
                    style: GoogleFonts.cinzelDecorative(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildGenderSelection() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Płeć',
              style: GoogleFonts.cinzelDecorative(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 20),
            Column(
              children: [
                _buildGenderOption('Mężczyzna', 'male'),
                const SizedBox(height: 12),
                _buildGenderOption('Kobieta', 'female'),
                const SizedBox(height: 12),
                _buildGenderOption('Inna', 'other'),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildGenderOption(String title, String value) {
    final isSelected = _selectedGender == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color:
                isSelected ? AppColors.cyan : AppColors.cyan.withOpacity(0.3),
            width: isSelected ? 2 : 1.5,
          ),
          color: isSelected
              ? AppColors.cyan.withOpacity(0.1)
              : Colors.black.withOpacity(0.2),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.cyan.withOpacity(
                      0.3 + (_glowAnimation.value * 0.4),
                    ),
                    blurRadius: 15 + (_glowAnimation.value * 10),
                    spreadRadius: 2 + (_glowAnimation.value * 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.cyan : Colors.white38,
                  width: 2,
                ),
                color: isSelected ? AppColors.cyan : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: isSelected ? AppColors.cyan : Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandSelection() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ręka główna',
              style: GoogleFonts.cinzelDecorative(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildHandOption('Lewa', 'left')),
                const SizedBox(width: 16),
                Expanded(child: _buildHandOption('Prawa', 'right')),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildHandOption(String title, String value) {
    final isSelected = _selectedHand == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedHand = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color:
                isSelected ? AppColors.cyan : AppColors.cyan.withOpacity(0.3),
            width: isSelected ? 2 : 1.5,
          ),
          color: isSelected
              ? AppColors.cyan.withOpacity(0.1)
              : Colors.black.withOpacity(0.2),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.cyan.withOpacity(
                      0.3 + (_glowAnimation.value * 0.4),
                    ),
                    blurRadius: 15 + (_glowAnimation.value * 10),
                    spreadRadius: 2 + (_glowAnimation.value * 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.cyan : Colors.white38,
                  width: 2,
                ),
                color: isSelected ? AppColors.cyan : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: isSelected ? AppColors.cyan : Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.cyan,
              onPrimary: Colors.white,
              surface: const Color(0xFF1A2332),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: true, // ✅ WYMUSZA FORMAT 24H
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.dark(
                primary: AppColors.cyan,
                onPrimary: Colors.white,
                surface: const Color(0xFF1A2332),
                onSurface: Colors.white,
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _handleContinue() async {
    if (_formKey.currentState!.validate() &&
        _selectedDate != null &&
        _selectedGender.isNotEmpty &&
        _selectedHand.isNotEmpty) {
      // Uruchom mistyczny efekt świetlny
      _glowController.forward().then((_) {
        _glowController.reverse();
      });

      try {
        // Przygotuj dane godziny urodzenia
        String? birthTimeString;
        if (_rememberBirthTime && _selectedTime != null) {
          birthTimeString =
              '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';
        }

        // Przygotuj miejsce urodzenia (opcjonalne)
        String? birthPlace;
        if (_birthPlaceController.text.trim().isNotEmpty) {
          birthPlace = _birthPlaceController.text.trim();
        }

        // Stwórz obiekt UserData
        final userData = UserData(
          name: _nameController.text.trim(),
          birthDate: _selectedDate!,
          birthTime: birthTimeString,
          birthPlace: birthPlace,
          gender: _selectedGender,
          dominantHand: _selectedHand,
          registrationDate: DateTime.now(),
        );

        // Zapisz dane użytkownika
        await UserPreferencesService.saveUserData(userData);

        // Oznacz onboarding jako ukończony
        await UserPreferencesService.setOnboardingCompleted();

        // Debug
        print('✅ Dane użytkownika: $userData');
        print('🔍 DEBUG: Full birth info = ${userData.fullBirthInfo}');

        // Nawigacja do menu głównego
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    MainMenuScreen(
                  userName: userData.name,
                  userGender: userData.genderForMessages,
                  dominantHand: userData.dominantHand,
                  birthDate: userData.birthDate,
                ),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.3),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: child,
                    ),
                  );
                },
                transitionDuration: const Duration(milliseconds: 1200),
              ),
            );
          }
        });
      } catch (e) {
        print('❌ Błąd zapisywania danych: $e');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Błąd zapisywania danych: ${e.toString()}',
                style: GoogleFonts.cinzelDecorative(),
              ),
              backgroundColor: Colors.red.withOpacity(0.8),
            ),
          );
        }
      }
    } else {
      String message = '';
      if (_selectedDate == null) {
        message = 'Wybierz datę urodzenia';
      } else if (_selectedGender.isEmpty) {
        message = 'Wybierz swoją płeć';
      } else if (_selectedHand.isEmpty) {
        message = 'Wybierz swoją dominującą rękę';
      }

      if (message.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message, style: GoogleFonts.cinzelDecorative()),
            backgroundColor: Colors.red.withOpacity(0.8),
          ),
        );
      }
    }
  }
}
