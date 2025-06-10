import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../utils/constants.dart';
import '../models/user_data.dart';
import 'palm_intro_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dateController = TextEditingController();

  String _selectedGender = '';
  String _selectedHand = '';
  bool _showPrivacyMessage = true;

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
              'Twoje dane są zbierane tylko do celów analizy twojej dłoni, nie są one zapisywane. Po wykonaniu "wróżby" wszystkie informacje są usuwane.',
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
    _dateController.dispose();
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
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
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
                                        'Kontynuuj',
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
    String? Function(String?)? validator,
  }) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
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
                  color: AppColors.cyan.withOpacity(0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cyan.withOpacity(
                      0.1 + (_glowAnimation.value * 0.3),
                    ),
                    blurRadius: 10 + (_glowAnimation.value * 10),
                    spreadRadius: 1 + (_glowAnimation.value * 2),
                  ),
                ],
              ),
              child: TextFormField(
                controller: controller,
                validator: validator,
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
                  color: AppColors.cyan.withOpacity(0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cyan.withOpacity(
                      0.1 + (_glowAnimation.value * 0.3),
                    ),
                    blurRadius: 10 + (_glowAnimation.value * 10),
                    spreadRadius: 1 + (_glowAnimation.value * 2),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _dateController,
                readOnly: true,
                onTap: _selectDate,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Wybierz datę urodzenia';
                  }
                  return null;
                },
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
                  hintText: 'DD.MM.RRRR',
                  hintStyle: GoogleFonts.cinzelDecorative(
                    color: Colors.white38,
                    fontSize: 14,
                  ),
                  suffixIcon: Icon(
                    Icons.calendar_today,
                    color: AppColors.cyan.withOpacity(0.7),
                    size: 20,
                  ),
                ),
              ),
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
            color: isSelected
                ? AppColors.cyan
                : AppColors.cyan.withOpacity(0.3),
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
            color: isSelected
                ? AppColors.cyan
                : AppColors.cyan.withOpacity(0.3),
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

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _handleContinue,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(color: AppColors.cyan.withOpacity(0.8), width: 2),
          ),
          elevation: 0,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.cyan.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              'Kontynuuj',
              style: GoogleFonts.cinzelDecorative(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
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
        _dateController.text =
            '${picked.day.toString().padLeft(2, '0')}.${picked.month.toString().padLeft(2, '0')}.${picked.year}';
      });
    }
  }

  void _handleContinue() {
    if (_formKey.currentState!.validate() &&
        _selectedGender.isNotEmpty &&
        _selectedHand.isNotEmpty) {
      // Uruchom mistyczny efekt świetlny
      _glowController.forward().then((_) {
        _glowController.reverse();
      });

      // Stwórz obiekt UserData
      final userData = UserData(
        name: _nameController.text.trim(),
        birthDate: _parseDate(_dateController.text),
        gender: _selectedGender,
        dominantHand: _selectedHand,
        registrationDate: DateTime.now(),
      );

      // Debug - sprawdź dane
      print('Dane użytkownika: $userData');
      print(
        'DEBUG Onboarding: gender = ${userData.gender}, dominantHand = ${userData.dominantHand}',
      );

      // POPRAWIONE PRZEJŚCIE do następnego ekranu po animacji
      Future.delayed(const Duration(milliseconds: 1000), () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                PalmIntroScreen(
                  userName: userData.name,
                  userGender: userData.gender,
                  dominantHand: userData.dominantHand,
                ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position:
                          Tween<Offset>(
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
      });
    } else {
      String message = '';
      if (_selectedGender.isEmpty) {
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

  DateTime _parseDate(String dateString) {
    try {
      final parts = dateString.split('.');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      print('Błąd parsowania daty: $e');
    }
    return DateTime.now();
  }
}
