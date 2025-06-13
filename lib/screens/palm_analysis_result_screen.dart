// lib/screens/palm_analysis_result_screen.dart
// Ekran wyników analizy dłoni

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:math' as math;
import '../utils/constants.dart';
import '../models/palm_analysis.dart';
import '../services/logging_service.dart';

class PalmAnalysisResultScreen extends StatefulWidget {
  final String userName;
  final String userGender;
  final PalmAnalysis palmData;

  const PalmAnalysisResultScreen({
    super.key,
    required this.userName,
    required this.userGender,
    required this.palmData,
  });

  @override
  State<PalmAnalysisResultScreen> createState() =>
      _PalmAnalysisResultScreenState();
}

class _PalmAnalysisResultScreenState extends State<PalmAnalysisResultScreen>
    with TickerProviderStateMixin {
  final LoggingService _loggingService = LoggingService();
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // ===== ANIMACJE =====
  late AnimationController _fadeController;
  late AnimationController _mysticalController;
  late AnimationController _cardController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _mysticalAnimation;
  late Animation<double> _cardAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    _loggingService.logToConsole('Wyświetlenie wyników analizy',
        tag: 'RESULTS');
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _mysticalController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _mysticalAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mysticalController, curve: Curves.linear),
    );

    _cardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.elasticOut),
    );
  }

  void _startAnimations() {
    _fadeController.forward();
    _mysticalController.repeat();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _cardController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _mysticalController.dispose();
    _cardController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildMysticalBackground(),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildMysticalBackground() {
    return AnimatedBuilder(
      animation: _mysticalAnimation,
      builder: (context, child) {
        return Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.5,
              colors: [
                Color(0xFF0D1B2A),
                Color(0xFF1B263B),
                Color(0xFF000000),
              ],
            ),
          ),
          child: CustomPaint(
            painter: MysticalResultsPainter(_mysticalAnimation.value),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    return SafeArea(
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    children: [
                      _buildOverviewPage(),
                      _buildDetailedAnalysisPage(),
                      _buildPredictionsPage(),
                    ],
                  ),
                ),
                _buildPageIndicator(),
                _buildActionButtons(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.85),
            Colors.black.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.cyan.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withOpacity(0.15),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _mysticalAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _mysticalAnimation.value * 2 * math.pi,
                    child: Icon(
                      Icons.auto_awesome,
                      color: AppColors.cyan,
                      size: 24,
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Text(
                'TWOJA WRÓŻBA',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 24,
                  color: AppColors.cyan,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(width: 12),
              AnimatedBuilder(
                animation: _mysticalAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: -_mysticalAnimation.value * 2 * math.pi,
                    child: Icon(
                      Icons.auto_awesome,
                      color: AppColors.cyan,
                      size: 24,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Drogi${widget.userGender == 'female' ? 'a' : (widget.userGender == 'other' || widget.userGender == 'inna' || widget.userGender == 'neutral') ? '/a' : ''} ${widget.userName}',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Oto co odkryły starożytne znaki w Twojej ${widget.palmData.handType == 'left' ? 'lewej' : 'prawej'} dłoni',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 14,
              color: AppColors.cyan.withOpacity(0.8),
              fontWeight: FontWeight.w300,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildSectionCard(
            title: 'Natura Twojej Duszy',
            icon: Icons.psychology,
            content: _buildSoulNatureContent(),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Energia Życiowa',
            icon: Icons.favorite,
            content: _buildLifeEnergyContent(),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Droga Przeznaczenia',
            icon: Icons.timeline,
            content: _buildDestinyContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedAnalysisPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildSectionCard(
            title: 'Analiza Linii Dłoni',
            icon: Icons.linear_scale,
            content: _buildLinesAnalysis(),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Wzgórki i Energie',
            icon: Icons.landscape,
            content: _buildMountsAnalysis(),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Kształt i Palce',
            icon: Icons.pan_tool,
            content: _buildHandShapeAnalysis(),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildSectionCard(
            title: 'Miłość i Związki',
            icon: Icons.favorite_border,
            content: _buildLoveAnalysis(),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Kariera i Sukces',
            icon: Icons.work_outline,
            content: _buildCareerAnalysis(),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Zdrowie i Długowieczność',
            icon: Icons.health_and_safety,
            content: _buildHealthAnalysis(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _cardAnimation.value,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.black.withOpacity(0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.cyan.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cyan.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.cyan.withOpacity(0.1),
                        border: Border.all(
                          color: AppColors.cyan.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: AppColors.cyan,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.cinzelDecorative(
                          fontSize: 18,
                          color: AppColors.cyan,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                content,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSoulNatureContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAnalysisPoint(
          'Element duszy',
          widget.palmData.handShape.elementType,
          _getElementDescription(widget.palmData.handShape.elementType),
        ),
        const SizedBox(height: 12),
        _buildAnalysisPoint(
          'Typ osobowości',
          widget.palmData.handShape.form,
          _getPersonalityDescription(widget.palmData.handShape.form),
        ),
        const SizedBox(height: 12),
        _buildAnalysisPoint(
          'Energia kciuka',
          widget.palmData.fingers.kciuk.typ,
          _getThumbDescription(widget.palmData.fingers.kciuk.typ),
        ),
      ],
    );
  }

  Widget _buildLifeEnergyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAnalysisPoint(
          'Linia życia',
          '${widget.palmData.lines.lifeLine.dlugosc} - ${widget.palmData.lines.lifeLine.ksztalt}',
          _getLifeLineDescription(widget.palmData.lines.lifeLine),
        ),
        const SizedBox(height: 12),
        _buildAnalysisPoint(
          'Wzgórek Wenus',
          widget.palmData.mounts.mountOfVenus,
          _getVenusDescription(widget.palmData.mounts.mountOfVenus),
        ),
        const SizedBox(height: 12),
        _buildAnalysisPoint(
          'Siła woli',
          widget.palmData.fingers.flexibility,
          _getWillpowerDescription(widget.palmData.fingers.flexibility),
        ),
      ],
    );
  }

  Widget _buildDestinyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAnalysisPoint(
          'Linia losu',
          widget.palmData.lines.fateLine.obecnosc,
          _getFateLineDescription(widget.palmData.lines.fateLine),
        ),
        const SizedBox(height: 12),
        _buildAnalysisPoint(
          'Linia słońca',
          widget.palmData.lines.sunLine.obecnosc,
          _getSunLineDescription(widget.palmData.lines.sunLine),
        ),
        const SizedBox(height: 12),
        _buildAnalysisPoint(
          'Wzgórek Jowisza',
          widget.palmData.mounts.mountOfJupiter,
          _getJupiterDescription(widget.palmData.mounts.mountOfJupiter),
        ),
      ],
    );
  }

  Widget _buildLinesAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailedLineInfo('Linia głowy', widget.palmData.lines.headLine),
        const Divider(color: Colors.white24),
        _buildDetailedLineInfo('Linia serca', widget.palmData.lines.heartLine),
        const Divider(color: Colors.white24),
        _buildDetailedLineInfo('Linia życia', widget.palmData.lines.lifeLine),
      ],
    );
  }

  Widget _buildMountsAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMountInfo(
            'Jowisz (przywództwo)', widget.palmData.mounts.mountOfJupiter),
        _buildMountInfo(
            'Saturn (mądrość)', widget.palmData.mounts.mountOfSaturne),
        _buildMountInfo(
            'Apollo (kreatywność)', widget.palmData.mounts.mountOfApollo),
        _buildMountInfo(
            'Merkury (komunikacja)', widget.palmData.mounts.mountOfMercury),
      ],
    );
  }

  Widget _buildHandShapeAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAnalysisPoint(
          'Rozmiar dłoni',
          widget.palmData.handShape.size,
          _getHandSizeDescription(widget.palmData.handShape.size),
        ),
        const SizedBox(height: 12),
        _buildAnalysisPoint(
          'Długość palców',
          widget.palmData.fingers.length,
          _getFingersDescription(widget.palmData.fingers.length),
        ),
        const SizedBox(height: 12),
        _buildAnalysisPoint(
          'Tekstura skóry',
          widget.palmData.skin.tekstura,
          _getSkinDescription(widget.palmData.skin.tekstura),
        ),
      ],
    );
  }

  Widget _buildLoveAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAnalysisPoint(
          'Linia serca',
          '${widget.palmData.lines.heartLine.dlugosc} - ${widget.palmData.lines.heartLine.ksztalt}',
          _getHeartLineDescription(widget.palmData.lines.heartLine),
        ),
        const SizedBox(height: 12),
        _buildAnalysisPoint(
          'Linie małżeństwa',
          widget.palmData.lines.marriageLines.ilosc,
          _getMarriageDescription(widget.palmData.lines.marriageLines),
        ),
        const SizedBox(height: 12),
        _buildAnalysisPoint(
          'Wzgórek Wenus',
          widget.palmData.mounts.mountOfVenus,
          _getLoveVenusDescription(widget.palmData.mounts.mountOfVenus),
        ),
      ],
    );
  }

  Widget _buildCareerAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAnalysisPoint(
          'Linia losu',
          widget.palmData.lines.fateLine.obecnosc,
          _getCareerFateDescription(widget.palmData.lines.fateLine),
        ),
        const SizedBox(height: 12),
        _buildAnalysisPoint(
          'Wzgórek Merkurego',
          widget.palmData.mounts.mountOfMercury,
          _getMercuryCareerDescription(widget.palmData.mounts.mountOfMercury),
        ),
        const SizedBox(height: 12),
        _buildAnalysisPoint(
          'Palec wskazujący',
          widget.palmData.fingers.palecWskazujacy,
          _getIndexFingerDescription(widget.palmData.fingers.palecWskazujacy),
        ),
      ],
    );
  }

  Widget _buildHealthAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAnalysisPoint(
          'Linia zdrowia',
          widget.palmData.lines.healthLine.obecnosc,
          _getHealthLineDescription(widget.palmData.lines.healthLine),
        ),
        const SizedBox(height: 12),
        _buildAnalysisPoint(
          'Wzgórek Księżyca',
          widget.palmData.mounts.mountOfMoon,
          _getMoonHealthDescription(widget.palmData.mounts.mountOfMoon),
        ),
        const SizedBox(height: 12),
        _buildAnalysisPoint(
          'Paznokcie',
          '${widget.palmData.paznokcie.ksztalt} - ${widget.palmData.paznokcie.kolor}',
          _getNailsHealthDescription(widget.palmData.paznokcie),
        ),
      ],
    );
  }

  Widget _buildAnalysisPoint(String title, String value, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cyan,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.cinzelDecorative(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 14,
                  color: AppColors.cyan.withOpacity(0.9),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 14,
                  color: Colors.white70,
                  fontWeight: FontWeight.w300,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedLineInfo(String lineName, dynamic lineData) {
    String details = '';
    String interpretation = '';

    if (lineData is LifeLine) {
      details = 'Długość: ${lineData.dlugosc}, Kształt: ${lineData.ksztalt}';
      interpretation =
          'Rozpoczyna się ${lineData.rozpoczecie} i ${lineData.przebieg}';
    } else if (lineData is HeadLine) {
      details = 'Długość: ${lineData.dlugosc}, Kształt: ${lineData.ksztalt}';
      interpretation =
          'Rozpoczyna się ${lineData.rozpoczecie}, kończy ${lineData.koniec}';
    } else if (lineData is HeartLine) {
      details = 'Długość: ${lineData.dlugosc}, Kształt: ${lineData.ksztalt}';
      interpretation =
          'Rozpoczyna się ${lineData.rozpoczecie}, znaki: ${lineData.znaki}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lineName,
            style: GoogleFonts.cinzelDecorative(
              fontSize: 16,
              color: AppColors.cyan,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            details,
            style: GoogleFonts.cinzelDecorative(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            interpretation,
            style: GoogleFonts.cinzelDecorative(
              fontSize: 13,
              color: Colors.white70,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMountInfo(String mountName, String strength) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            mountName,
            style: GoogleFonts.cinzelDecorative(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w400,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.cyan.withOpacity(0.1),
              border: Border.all(
                color: AppColors.cyan.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              strength,
              style: GoogleFonts.cinzelDecorative(
                fontSize: 12,
                color: AppColors.cyan,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _currentPage == index ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: _currentPage == index
                  ? AppColors.cyan
                  : AppColors.cyan.withOpacity(0.3),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              margin: const EdgeInsets.only(right: 8),
              child: OutlinedButton.icon(
                onPressed: _shareResults,
                icon: const Icon(Icons.share, size: 20),
                label: const Text('Udostępnij'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.cyan,
                  side: BorderSide(color: AppColors.cyan.withOpacity(0.7)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 48,
              margin: const EdgeInsets.only(left: 8),
              child: ElevatedButton.icon(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                icon: const Icon(Icons.home, size: 20),
                label: const Text('Powrót'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareResults() {
    final shareText = '''
🔮 Moja wróżba z dłoni - AI Wróżka

👤 ${widget.userName}
🤚 Analiza ${widget.palmData.handType == 'left' ? 'lewej' : 'prawej'} dłoni

✨ Element duszy: ${widget.palmData.handShape.elementType}
💫 Typ osobowości: ${widget.palmData.handShape.form}
❤️ Linia serca: ${widget.palmData.lines.heartLine.dlugosc}
🧠 Linia głowy: ${widget.palmData.lines.headLine.dlugosc}
🌟 Linia życia: ${widget.palmData.lines.lifeLine.dlugosc}

Odkryj swoją przyszłość z AI Wróżka!
''';

    Share.share(shareText, subject: 'Moja wróżba z dłoni');
    _loggingService.logToConsole('Udostępniono wyniki wróżby', tag: 'SHARE');
  }

  // ===== DESCRIPTION METHODS =====
  String _getElementDescription(String element) {
    switch (element.toLowerCase()) {
      case 'ziemia':
        return 'Jesteś osobą praktyczną i stabilną. Cenisz bezpieczeństwo i systematyczne działanie.';
      case 'woda':
        return 'Twoja natura jest emocjonalna i intuicyjna. Masz silną wrażliwość na energie innych.';
      case 'ogień':
        return 'Pełen energii i pasji. Jesteś przywódcą z naturalną charyzmą i siłą działania.';
      case 'powietrze':
        return 'Umysł jest Twoją największą siłą. Jesteś komunikatywny i pełen kreatywnych pomysłów.';
      default:
        return 'Twoja energia jest unikalna i łączy w sobie różne elementy natury.';
    }
  }

  String _getPersonalityDescription(String form) {
    switch (form.toLowerCase()) {
      case 'prostokątna':
        return 'Osobowość praktyczna i zorganizowana. Lubisz mieć kontrolę nad sytuacją.';
      case 'kwadratowa':
        return 'Stabilność i solidność to Twoje mocne strony. Jesteś godny zaufania.';
      case 'okrągła':
        return 'Masz łagodną naturę i dar do budowania harmonijnych relacji.';
      default:
        return 'Twoja osobowość ma wyjątkowe cechy, które wyróżniają Cię w tłumie.';
    }
  }

  String _getThumbDescription(String typ) {
    switch (typ.toLowerCase()) {
      case 'mocny':
        return 'Masz silną wolę i determinację. Potrafisz osiągać swoje cele.';
      case 'średni':
        return 'Wyważona siła woli. Potrafisz być elastyczny w różnych sytuacjach.';
      case 'delikatny':
        return 'Twoja siła leży w dyplomacji i subtelności. Unikasz konfliktów.';
      default:
        return 'Twoja wola ma unikalne cechy, które pomagają Ci w życiu.';
    }
  }

  String _getLifeLineDescription(LifeLine lifeLine) {
    String base = 'Twoja energia życiowa jest ';
    switch (lifeLine.dlugosc.toLowerCase()) {
      case 'długa':
        base += 'silna i trwała. ';
        break;
      case 'średnia':
        base += 'zrównoważona. ';
        break;
      case 'krótka':
        base += 'intensywna, ale zmienia się w cyklach. ';
        break;
      default:
        base += 'wyjątkowa. ';
    }

    switch (lifeLine.ksztalt.toLowerCase()) {
      case 'głęboka':
        base += 'Masz mocne podstawy życiowe.';
        break;
      case 'płytka':
        base += 'Jesteś wrażliwy na zmiany energetyczne.';
        break;
      default:
        base += 'Energia płynie w harmonii.';
    }

    return base;
  }

  String _getVenusDescription(String venus) {
    switch (venus.toLowerCase()) {
      case 'wysoki':
        return 'Jesteś pełen miłości i pasji. Twoje serce jest otwarte na świat.';
      case 'średni':
        return 'Masz zrównoważone podejście do miłości i przyjemności.';
      case 'niski':
        return 'Cenisz głębokie, przemyślane relacje nad powierzchowne uczucia.';
      default:
        return 'Twoje podejście do miłości jest unikalne i autentyczne.';
    }
  }

  String _getWillpowerDescription(String flexibility) {
    switch (flexibility.toLowerCase()) {
      case 'giętkie':
        return 'Jesteś elastyczny i potrafisz dostosować się do zmian.';
      case 'sztywne':
        return 'Masz mocne przekonania i trzymasz się swoich zasad.';
      case 'średnie':
        return 'Wyważasz elastyczność z wytrwałością w osiąganiu celów.';
      default:
        return 'Twoja siła woli ma unikalne cechy.';
    }
  }

  String _getFateLineDescription(FateLine fateLine) {
    if (fateLine.obecnosc.toLowerCase() == 'jest') {
      return 'Masz wyraźne przeznaczenie i kierunek życiowy. Los prowadzi Cię określoną ścieżką.';
    } else {
      return 'Jesteś architektem własnego losu. Masz wolność tworzenia swojej przyszłości.';
    }
  }

  String _getSunLineDescription(SunLine sunLine) {
    if (sunLine.obecnosc.toLowerCase() == 'jest') {
      return 'Czeka Cię sukces i uznanie. Twoje talenty zostaną docenione.';
    } else {
      return 'Twój sukces będzie wynikiem ciężkiej pracy i własnych starań.';
    }
  }

  String _getJupiterDescription(String jupiter) {
    switch (jupiter.toLowerCase()) {
      case 'wysoki':
        return 'Masz naturalne predyspozycje przywódcze i ambitne cele.';
      case 'średni':
        return 'Potrafisz kierować sobą i innymi w sposób zrównoważony.';
      case 'niski':
        return 'Preferujesz współpracę nad dominacją, cenisz harmonię.';
      default:
        return 'Twoje podejście do przywództwa jest unikalne.';
    }
  }

  String _getHandSizeDescription(String size) {
    switch (size.toLowerCase()) {
      case 'duża':
        return 'Myślisz globalnie i masz szerokie perspektywy życiowe.';
      case 'średnia':
        return 'Masz zrównoważone podejście do szczegółów i ogólnej wizji.';
      case 'mała':
        return 'Zwracasz uwagę na detale i lubisz precyzyjne działanie.';
      default:
        return 'Twoje podejście do życia jest przemyślane i unikalne.';
    }
  }

  String _getFingersDescription(String length) {
    switch (length.toLowerCase()) {
      case 'długie':
        return 'Jesteś osobą analityczną, która lubi zagłębiać się w szczegóły.';
      case 'krótkie':
        return 'Działasz szybko i instynktownie, ufasz swojej intuicji.';
      case 'proporcjonalne':
        return 'Masz zrównoważone podejście do analizy i działania.';
      default:
        return 'Twój sposób myślenia jest oryginalny i efektywny.';
    }
  }

  String _getSkinDescription(String texture) {
    switch (texture.toLowerCase()) {
      case 'gładka':
        return 'Masz delikatną naturę i wrażliwość na piękno.';
      case 'szorstka':
        return 'Jesteś osobą praktyczną, która nie boi się ciężkiej pracy.';
      case 'średnia':
        return 'Łączysz w sobie wrażliwość z praktycznym podejściem do życia.';
      default:
        return 'Twoja natura ma unikalne cechy, które Cię wyróżniają.';
    }
  }

  String _getHeartLineDescription(HeartLine heartLine) {
    String base = 'W miłości jesteś ';
    switch (heartLine.dlugosc.toLowerCase()) {
      case 'długa':
        base += 'oddany i lojalny. ';
        break;
      case 'krótka':
        base += 'intensywny i namiętny. ';
        break;
      default:
        base += 'zrównoważony. ';
    }

    switch (heartLine.ksztalt.toLowerCase()) {
      case 'prosta':
        base += 'Masz realistyczne podejście do związków.';
        break;
      case 'zakrzywiona':
        base += 'Jesteś romantyczny i emocjonalny.';
        break;
      default:
        base += 'Twoje podejście do miłości jest autentyczne.';
    }

    return base;
  }

  String _getMarriageDescription(MarriageLines marriageLines) {
    switch (marriageLines.ilosc) {
      case '1':
        return 'Jeden wielki związek będzie kształtował Twoje życie uczuciowe.';
      case '2':
        return 'Dwa ważne związki wpłyną na Twoją drogę miłosną.';
      case '3':
        return 'Życie obdarzy Cię różnorodnymi doświadczeniami miłosnymi.';
      default:
        return 'Twoja droga miłosna będzie bogata w doświadczenia.';
    }
  }

  String _getLoveVenusDescription(String venus) {
    switch (venus.toLowerCase()) {
      case 'wysoki':
        return 'Miłość i namiętność są centralną częścią Twojego życia.';
      case 'średni':
        return 'Potrafisz zrównoważyć miłość z innymi aspektami życia.';
      case 'niski':
        return 'Cenisz głęboką więź emocjonalną nad powierzchowną atrakcję.';
      default:
        return 'Twoje podejście do miłości jest przemyślane i autentyczne.';
    }
  }

  String _getCareerFateDescription(FateLine fateLine) {
    if (fateLine.obecnosc.toLowerCase() == 'jest') {
      return 'Masz wyraźną ścieżkę zawodową. Powodzenie przyjdzie naturalnie.';
    } else {
      return 'Będziesz budować karierę własnymi siłami i determinacją.';
    }
  }

  String _getMercuryCareerDescription(String mercury) {
    switch (mercury.toLowerCase()) {
      case 'wysoki':
        return 'Komunikacja i handel będą kluczowe w Twojej karierze.';
      case 'średni':
        return 'Masz dobre predyspozycje do pracy z ludźmi i negocjacji.';
      case 'niski':
        return 'Preferujesz pracę wymagającą skupienia i precyzji.';
      default:
        return 'Twoje umiejętności zawodowe są unikalne i cenne.';
    }
  }

  String _getIndexFingerDescription(String indexFinger) {
    switch (indexFinger.toLowerCase()) {
      case 'długi':
        return 'Masz naturalne predyspozycje przywódcze w karierze.';
      case 'normalny':
        return 'Potrafisz dobrze współpracować w zespole i kierować projektami.';
      case 'krótki':
        return 'Preferujesz wspierającą rolę i pracę za kulisami.';
      default:
        return 'Twój styl pracy jest efektywny i dostosowany do Twoich mocnych stron.';
    }
  }

  String _getHealthLineDescription(HealthLine healthLine) {
    if (healthLine.obecnosc.toLowerCase() == 'jest') {
      return 'Zwracaj uwagę na sygnały swojego ciała. Profilaktyka jest kluczowa.';
    } else {
      return 'Masz naturalnie dobry stan zdrowia i silną odporność.';
    }
  }

  String _getMoonHealthDescription(String moon) {
    switch (moon.toLowerCase()) {
      case 'wysoki':
        return 'Jesteś wrażliwy na cykle natury. Słuchaj swojej intuicji zdrowotnej.';
      case 'średni':
        return 'Masz dobrą równowagę między aktywnością a odpoczynkiem.';
      case 'niski':
        return 'Potrzebujesz regularnego rytmu życia dla zachowania zdrowia.';
      default:
        return 'Twoje potrzeby zdrowotne są unikalne i wymagają indywidualnego podejścia.';
    }
  }

  String _getNailsHealthDescription(Nails nails) {
    String base = 'Twoje paznokcie wskazują na ';

    switch (nails.kolor.toLowerCase()) {
      case 'jasne':
        base += 'dobry przepływ energii życiowej. ';
        break;
      case 'różowe':
        base += 'zdrową cyrkulację i vitalność. ';
        break;
      case 'blade':
        base += 'potrzebę wzmocnienia energii. ';
        break;
      default:
        base += 'stabilną kondycję. ';
    }

    switch (nails.ksztalt.toLowerCase()) {
      case 'owalne':
        base += 'Masz harmonijną naturę i dobre zdrowie emocjonalne.';
        break;
      case 'kwadratowe':
        base += 'Jesteś osobą stabilną, ale pamiętaj o elastyczności.';
        break;
      case 'szpiczaste':
        base += 'Masz intensywną energię - dbaj o równowagę.';
        break;
      default:
        base += 'Twoja energia ma unikalne właściwości.';
    }

    return base;
  }
}

class MysticalResultsPainter extends CustomPainter {
  final double animationValue;

  MysticalResultsPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()..style = PaintingStyle.fill;

    try {
      // Mystical aura around the screen
      for (int i = 0; i < 5; i++) {
        final centerX = size.width * 0.5;
        final centerY = size.height * 0.5;
        final baseRadius = 100.0 + (i * 60.0);
        final animatedRadius = baseRadius *
            (1 + 0.05 * math.sin(animationValue * 2 * math.pi + i));

        if (animatedRadius > 0 && animatedRadius < size.width * 1.5) {
          paint.color = AppColors.cyan.withOpacity(0.02 - i * 0.003);
          canvas.drawCircle(Offset(centerX, centerY), animatedRadius, paint);
        }
      }

      // Floating mystical particles
      for (int i = 0; i < 30; i++) {
        final angle = (animationValue * math.pi) + (i * 2 * math.pi / 30);
        final radius = 120.0 + (i % 4) * 40.0;
        final x = size.width * 0.5 +
            radius * math.cos(angle + animationValue * math.pi);
        final y = size.height * 0.5 +
            radius * math.sin(angle * 0.7 + animationValue * math.pi);

        if (x >= -20 &&
            x <= size.width + 20 &&
            y >= -20 &&
            y <= size.height + 20) {
          final particleSize =
              0.8 + math.sin(animationValue * 4 * math.pi + i) * 0.4;
          final opacity =
              0.1 + math.sin(animationValue * 3 * math.pi + i * 0.5) * 0.05;

          if (particleSize > 0) {
            paint.color = AppColors.cyan.withOpacity(opacity.clamp(0.02, 0.15));
            canvas.drawCircle(Offset(x, y), particleSize, paint);
          }
        }
      }

      // Subtle corner decorations
      final cornerPaint = Paint()
        ..color = AppColors.cyan.withOpacity(0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      // Top corners
      canvas.drawArc(
        Rect.fromLTWH(20, 20, 40, 40),
        -math.pi,
        math.pi / 2,
        false,
        cornerPaint,
      );

      canvas.drawArc(
        Rect.fromLTWH(size.width - 60, 20, 40, 40),
        -math.pi / 2,
        math.pi / 2,
        false,
        cornerPaint,
      );

      // Bottom corners
      canvas.drawArc(
        Rect.fromLTWH(20, size.height - 60, 40, 40),
        math.pi / 2,
        math.pi / 2,
        false,
        cornerPaint,
      );

      canvas.drawArc(
        Rect.fromLTWH(size.width - 60, size.height - 60, 40, 40),
        0,
        math.pi / 2,
        false,
        cornerPaint,
      );
    } catch (e) {
      print('Błąd w MysticalResultsPainter: $e');
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
