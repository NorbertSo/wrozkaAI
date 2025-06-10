// lib/screens/ai_results_screen.dart
// Naprawiony ekran wyników - bez Transform.translateY

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class AIResultsScreen extends StatefulWidget {
  final String userName;
  final String? userGender;
  final DateTime? birthDate;
  final String? dominantHand;
  final Map<String, dynamic>? palmData;
  final File? palmImage;
  final String? analysisResult;

  const AIResultsScreen({
    super.key,
    required this.userName,
    this.userGender,
    this.birthDate,
    this.dominantHand,
    this.palmData,
    this.palmImage,
    this.analysisResult,
  });

  @override
  State<AIResultsScreen> createState() => _AIResultsScreenState();
}

class _AIResultsScreenState extends State<AIResultsScreen> 
    with TickerProviderStateMixin {
  
  // Kontrolery animacji
  late AnimationController _fadeController;
  late AnimationController _particleController;
  late AnimationController _textController;
  late AnimationController _buttonController;
  
  // Animacje
  late Animation<double> _fadeAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _textAnimation;
  late Animation<double> _buttonAnimation;

  final ScrollController _scrollController = ScrollController();
  bool _showFloatingButton = false;
  
  // Wynik analizy - unified getter
  String get _analysisResult {
    if (widget.analysisResult != null) {
      return widget.analysisResult!;
    }
    
    if (widget.palmData != null && widget.palmData!['analysisResult'] != null) {
      return widget.palmData!['analysisResult'] as String;
    }
    
    return _getDefaultAnalysis();
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupScrollListener();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _particleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.easeOut),
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _textAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeInOut),
    );

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _buttonAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.elasticOut),
    );
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final showButton = _scrollController.offset > 100;
      if (showButton != _showFloatingButton) {
        setState(() {
          _showFloatingButton = showButton;
        });
      }
    });
  }

  void _startAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _fadeController.forward();
    
    await Future.delayed(const Duration(milliseconds: 150));
    _particleController.forward();
    
    await Future.delayed(const Duration(milliseconds: 200));
    _textController.forward();
    
    await Future.delayed(const Duration(milliseconds: 250));
    _buttonController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _particleController.dispose();
    _textController.dispose();
    _buttonController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8.0),
        child: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          iconSize: 24,
          constraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 44,
          ),
        ),
      ),
      title: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Text(
              'Twoja Wróżba',
              style: GoogleFonts.cinzelDecorative(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8.0),
          child: IconButton(
            onPressed: _shareResults,
            icon: const Icon(Icons.share, color: Colors.amber),
            iconSize: 24,
            constraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Container(
      decoration: _buildGradientBackground(),
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 120, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildUserHeader(),
                      const SizedBox(height: 32),
                      _buildPalmImageSection(),
                      const SizedBox(height: 32),
                      _buildAnalysisSection(),
                      const SizedBox(height: 32),
                      _buildActionButtons(),
                      const SizedBox(height: 100),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  BoxDecoration _buildGradientBackground() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0A0A23),
          Color(0xFF1A1A40),
          Color(0xFF2D1B69),
          Color(0xFF000000),
        ],
        stops: [0.0, 0.3, 0.7, 1.0],
      ),
    );
  }

  Widget _buildUserHeader() {
    return AnimatedBuilder(
      animation: _textAnimation,
      builder: (context, child) {
        // Zastąpienie Transform.translateY zwykłym Transform.translate
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _textAnimation.value)),
          child: Opacity(
            opacity: _textAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    '✨ ${widget.userName} ✨',
                    style: GoogleFonts.cinzelDecorative(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.userGender != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Energia: ${_getEnergyType()}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                  if (widget.dominantHand != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Dłoń dominująca: ${widget.dominantHand}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        };
      },
    );
  }

  Widget _buildPalmImageSection() {
    if (widget.palmImage == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _particleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * _particleAnimation.value),
          child: Opacity(
            opacity: _particleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  widget.palmImage!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        };
      },
    );
  }

  Widget _buildAnalysisSection() {
    return AnimatedBuilder(
      animation: _textAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _textAnimation.value)),
          child: Opacity(
            opacity: _textAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🔮 Analiza Mistyczna',
                    style: GoogleFonts.cinzelDecorative(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurpleAccent,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _analysisResult,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          );
        };
      },
    );
  }

  Widget _buildActionButtons() {
    return AnimatedBuilder(
      animation: _buttonAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _buttonAnimation.value,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: 56,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: ElevatedButton(
                  onPressed: _shareResults,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 8,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.share, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Udostępnij Wróżbę',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      margin: const EdgeInsets.only(right: 8),
                      child: OutlinedButton(
                        onPressed: _copyToClipboard,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.amber,
                          side: const BorderSide(color: Colors.amber),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Kopiuj'),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 48,
                      margin: const EdgeInsets.only(left: 8),
                      child: OutlinedButton(
                        onPressed: _startNewAnalysis,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Nowa Analiza'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget? _buildFloatingActionButton() {
    if (!_showFloatingButton) return null;

    return FloatingActionButton(
      onPressed: () {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      backgroundColor: Colors.purple,
      child: const Icon(Icons.arrow_upward, color: Colors.white),
    );
  }

  String _getEnergyType() {
    if (widget.userGender == null) return 'Uniwersalna';
    return widget.userGender!.toLowerCase() == 'female' ? 'Księżycowa' : 'Słoneczna';
  }

  String _getDefaultAnalysis() {
    return '''
🔮 **Mistyczna Analiza Dłoni**

Twoja dłoń kryje w sobie tajemnice przyszłości. Linie życia wskazują na długowieczność i szczęście. 

✨ **Linia Serca**: Głęboka miłość czeka Cię w najbliższym czasie
💫 **Linia Umysłu**: Mądre decyzje przyniosą Ci sukces
🌟 **Linia Życia**: Długie i szczęśliwe życie przed Tobą

*Analiza wygenerowana ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}*
''';
  }

  void _shareResults() async {
    try {
      await Share.share(
        'Moja wróżba z dłoni od AI Wróżki:\n\n$_analysisResult',
        subject: 'Wróżba z dłoni - ${widget.userName}',
      );
    } catch (e) {
      print('Błąd udostępniania: $e');
    }
  }

  void _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _analysisResult));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Wróżba skopiowana do schowka!'),
          backgroundColor: Colors.green,
          duration: const Duration(milliseconds: 2000),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _startNewAnalysis() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF311B92), // Fixed deepPurple color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          'Nowa Analiza',
          style: GoogleFonts.cinzelDecorative(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        content: const Text(
          'Czy chcesz rozpocząć nową analizę dłoni? Obecne wyniki zostaną utracone.',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Anuluj',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Tak, zacznij nową'),
          ),
        ],
      ),
    );
  }
}