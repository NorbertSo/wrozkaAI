// lib/screens/ai_upload_screen.dart
// Naprawiony ekran upload z unified API calls

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import '../services/ai_vision_service.dart';
import '../services/logging_service.dart';
import '../utils/constants.dart';
import 'ai_results_screen.dart';

class AIUploadScreen extends StatefulWidget {
  // UNIFIED CONSTRUCTOR - wszystkie parametry opcjonalne z sensownymi defaults
  final String userName;
  final String? userGender;
  final DateTime? birthDate;
  final String? dominantHand;
  final File palmImage;

  const AIUploadScreen({
    super.key,
    required this.userName,
    required this.palmImage,
    this.userGender,
    this.birthDate,
    this.dominantHand,
  });

  @override
  State<AIUploadScreen> createState() => _AIUploadScreenState();
}

class _AIUploadScreenState extends State<AIUploadScreen>
    with TickerProviderStateMixin {
  
  final LoggingService _loggingService = LoggingService();
  final AIVisionService _aiVisionService = AIVisionService();

  // Animation controllers
  late AnimationController _loadingController;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  late Animation<double> _loadingAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _particleAnimation;

  // State variables
  bool _isAnalyzing = false;
  String _statusText = "Przygotowuję mistyczną analizę...";
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _logScreenAccess();
    _startUploadProcess();
  }

  void _initializeAnimations() {
    // Loading spinner - 300ms zgodnie z wytycznymi
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );

    // Pulse effect - 200ms dla responsywności
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Particle animation - 250ms
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.easeOut),
    );

    // Start animations
    _loadingController.forward();
    _pulseController.repeat(reverse: true);
    _particleController.repeat();
  }

  void _logScreenAccess() {
    _loggingService.logToConsole(
      'Upload screen accessed by: ${widget.userName}',
      tag: 'UPLOAD',
    );
    
    _loggingService.logToConsole(
      'Palm image: ${widget.palmImage.path}',
      tag: 'UPLOAD',
    );
  }

  Future<void> _startUploadProcess() async {
    // Simulate preparation steps with progress updates
    await _updateProgress(0.1, "Sprawdzam jakość obrazu...");
    await Future.delayed(const Duration(milliseconds: 800));
    
    await _updateProgress(0.3, "Analizuję linie dłoni...");
    await Future.delayed(const Duration(milliseconds: 1000));
    
    await _updateProgress(0.5, "Rozpoznaję wzorce energetyczne...");
    await Future.delayed(const Duration(milliseconds: 900));
    
    await _updateProgress(0.7, "Łączę z kosmiczną bazą wiedzy...");
    await Future.delayed(const Duration(milliseconds: 1200));
    
    await _updateProgress(0.9, "Przygotowuję wyniki...");
    await Future.delayed(const Duration(milliseconds: 700));

    // Start real AI analysis
    await _sendToAI();
  }

  Future<void> _updateProgress(double progress, String status) async {
    if (!mounted) return;
    
    setState(() {
      _progress = progress;
      _statusText = status;
    });
    
    _loggingService.logToConsole(
      'Progress: ${(progress * 100).toInt()}% - $status',
      tag: 'PROGRESS',
    );
  }

  Future<void> _sendToAI() async {
    try {
      setState(() {
        _isAnalyzing = true;
        _statusText = "Analizuję wzorce energetyczne...";
        _progress = 0.95;
      });

      _loggingService.logToConsole(
        'Rozpoczynam analizę AI dla: ${widget.userName}',
        tag: 'AI_ANALYSIS',
      );

      // Use unified AI service with proper error handling
      final analysisResult = await _aiVisionService.analyzePalmWithAI(
        palmImageFile: widget.palmImage,
        userName: widget.userName,
        userGender: widget.userGender ?? 'unknown',
        dominantHand: widget.dominantHand,
        birthDate: widget.birthDate,
      );

      setState(() {
        _isAnalyzing = false;
        _progress = 1.0;
        _statusText = "Analiza zakończona pomyślnie!";
      });

      _loggingService.logToConsole(
        'Analiza AI zakończona pomyślnie',
        tag: 'AI_SUCCESS',
      );

      // Brief success animation
      await Future.delayed(const Duration(milliseconds: 800));

      // Navigate to results with unified constructor
      if (mounted) {
        await _navigateToResults(analysisResult);
      }

    } catch (e) {
      _loggingService.logToConsole(
        'Błąd analizy AI: $e',
        tag: 'AI_ERROR',
      );

      setState(() {
        _isAnalyzing = false;
        _progress = 0.0;
        _statusText = "Błąd podczas analizy";
      });

      _showErrorDialog(e.toString());
    }
  }

  Future<void> _navigateToResults(String analysisResult) async {
    if (!mounted) return;

    _loggingService.logToConsole('Nawigacja do wyników', tag: 'NAVIGATE');

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => AIResultsScreen(
          userName: widget.userName,
          userGender: widget.userGender,
          birthDate: widget.birthDate,
          dominantHand: widget.dominantHand,
          analysisResult: analysisResult,
          palmImage: widget.palmImage,
        ),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
            child: child,
          );
        },
      ),
    );
  }

  void _showErrorDialog(String error) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.deepPurple.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          "Błąd analizy",
          style: GoogleFonts.cinzelDecorative(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              "Nie udało się przeanalizować Twojej dłoni. Spróbuj ponownie.",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            if (error.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                "Błąd: ${error.length > 50 ? error.substring(0, 50) + '...' : error}",
                style: const TextStyle(
                  color: Colors.red.shade300,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Back to previous screen
            },
            child: const Text(
              "Anuluj",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _retryAnalysis();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Spróbuj ponownie"),
          ),
        ],
      ),
    );
  }

  void _retryAnalysis() {
    setState(() {
      _isAnalyzing = false;
      _progress = 0.0;
      _statusText = "Przygotowuję mistyczną analizę...";
    });
    
    _startUploadProcess();
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: _buildGradientBackground(),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _loadingAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _loadingAnimation.value,
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(child: _buildMainContent()),
                    _buildProgressSection(),
                    _buildActionButtons(),
                  ],
                ),
              );
            },
          ),
        ),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            constraints: const BoxConstraints(
              minWidth: 44, // Minimum 44x44 px zgodnie z wytycznymi
              minHeight: 44,
            ),
            child: IconButton(
              onPressed: _isAnalyzing ? null : () => Navigator.of(context).pop(),
              icon: Icon(
                Icons.arrow_back_ios,
                color: _isAnalyzing ? Colors.grey : Colors.white,
              ),
              iconSize: 24,
            ),
          ),
          Expanded(
            child: Text(
              'Analiza Mistyczna',
              style: GoogleFonts.cinzelDecorative(
                fontSize: 24, // 24-32pt dla nagłówków
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 44), // Balance for back button
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // User greeting
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          margin: const EdgeInsets.symmetric(horizontal: 24),
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
              const SizedBox(height: 8),
              Text(
                'Analizuję Twoją dłoń...',
                style: TextStyle(
                  fontSize: 16, // 16-18pt dla tekstu głównego
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Palm image preview
        _buildPalmImagePreview(),

        const SizedBox(height: 32),

        // Loading animation
        _buildLoadingAnimation(),
      ],
    );
  }

  Widget _buildPalmImagePreview() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple.withOpacity(0.5), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                widget.palmImage,
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingAnimation() {
    return Column(
      children: [
        // Main loading indicator
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer ring
            AnimatedBuilder(
              animation: _particleAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _particleAnimation.value * 2 * 3.14159,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.amber.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                  ),
                );
              },
            ),
            
            // Inner loading
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: _progress,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _isAnalyzing ? Colors.green : Colors.amber,
                ),
                strokeWidth: 4,
              ),
            ),
            
            // Percentage text
            Text(
              '${(_progress * 100).toInt()}%',
              style: GoogleFonts.cinzelDecorative(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Mystical icons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildMysticalIcon(Icons.auto_awesome, Colors.amber),
            _buildMysticalIcon(Icons.psychology, Colors.purple),
            _buildMysticalIcon(Icons.visibility, Colors.blue),
            _buildMysticalIcon(Icons.favorite, Colors.pink),
          ],
        ),
      ],
    );
  }

  Widget _buildMysticalIcon(IconData icon, Color color) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * _pulseAnimation.value),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // Status text
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Text(
              _statusText,
              style: GoogleFonts.cinzelDecorative(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 16),

          // Progress bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _isAnalyzing ? Colors.green : Colors.amber,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        height: 48, // Optimal button height zgodnie z wytycznymi
        child: ElevatedButton(
          onPressed: _isAnalyzing ? null : () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isAnalyzing ? Colors.grey : Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            disabledBackgroundColor: Colors.grey.withOpacity(0.3),
          ),
          child: Text(
            _isAnalyzing ? 'Analizuję...' : 'Anuluj',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}