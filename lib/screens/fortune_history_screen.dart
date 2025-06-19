// lib/screens/fortune_history_screen.dart
// Ekran historii wróżb

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:math' as math;
import '../utils/constants.dart';
import '../models/fortune_history.dart'; // ✅ POPRAWIONY IMPORT
import '../services/fortune_history_service.dart'; // ✅ POPRAWIONY IMPORT
import 'fortune_detail_screen.dart'; // ✅ POPRAWIONY IMPORT

class FortuneHistoryScreen extends StatefulWidget {
  final String userName;
  final String userGender;

  const FortuneHistoryScreen({
    super.key,
    required this.userName,
    required this.userGender,
  });

  @override
  State<FortuneHistoryScreen> createState() => _FortuneHistoryScreenState();
}

class _FortuneHistoryScreenState extends State<FortuneHistoryScreen>
    with TickerProviderStateMixin {
  // ===== SERWISY =====
  final FortuneHistoryService _historyService = FortuneHistoryService();

  // ===== STAN =====
  List<FortuneHistory> _history = [];
  bool _isLoading = true;
  bool _hasError = false;

  // ===== ANIMACJE =====
  late AnimationController _fadeController;
  late AnimationController _mysticalController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _mysticalAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadHistory();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _mysticalController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _mysticalAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mysticalController, curve: Curves.linear),
    );
  }

  Future<void> _loadHistory() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final history = await _historyService.getFortuneHistory();
      
      setState(() {
        _history = history;
        _isLoading = false;
      });

      _fadeController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      print('❌ Błąd ładowania historii: $e');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _mysticalController.dispose();
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
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.8,
          colors: [
            Color(0xFF0D1B2A),
            Color(0xFF1B263B),
            Color(0xFF000000),
          ],
        ),
      ),
      child: AnimatedBuilder(
        animation: _mysticalAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: HistoryBackgroundPainter(_mysticalAnimation.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildHistoryContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withOpacity(0.8),
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
            color: AppColors.cyan.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.cyan.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              iconSize: 20,
            ),
          ),

          // Title
          Expanded(
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
                            Icons.history,
                            color: AppColors.cyan,
                            size: 24,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'MOJE WRÓŻBY',
                      style: GoogleFonts.cinzelDecorative(
                        fontSize: 20,
                        color: AppColors.cyan,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Historia Twoich mistycznych odkryć',
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),

          // Action button
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.cyan.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              onPressed: _showOptionsMenu,
              icon: const Icon(Icons.more_vert, color: Colors.white),
              iconSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_history.isEmpty) {
      return _buildEmptyState();
    }

    return _buildHistoryList();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _mysticalAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _mysticalAnimation.value * 2 * math.pi,
                child: Icon(
                  Icons.auto_awesome,
                  size: 48,
                  color: AppColors.cyan,
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            'Przywołuję Twoje wróżby...',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.red.withOpacity(0.2),
              Colors.black.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.red.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Błąd ładowania historii',
              style: GoogleFonts.cinzelDecorative(
                fontSize: 18,
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadHistory,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Spróbuj ponownie',
                style: GoogleFonts.cinzelDecorative(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.cyan.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.cyan.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      size: 40,
                      color: AppColors.cyan,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Jeszcze nie masz wróżb',
                    style: GoogleFonts.cinzelDecorative(
                      fontSize: 20,
                      color: AppColors.cyan,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Wykonaj pierwszą analizę dłoni,\naby odkryć swoją przyszłość',
                    style: GoogleFonts.cinzelDecorative(
                      fontSize: 16,
                      color: Colors.white70,
                      fontWeight: FontWeight.w300,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cyan,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      'Skanuj dłoń',
                      style: GoogleFonts.cinzelDecorative(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryList() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _history.length,
            itemBuilder: (context, index) {
              final fortune = _history[index];
              return _buildFortuneCard(fortune, index);
            },
          ),
        );
      },
    );
  }

  Widget _buildFortuneCard(FortuneHistory fortune, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openFortuneDetail(fortune),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    // Hand icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.cyan.withOpacity(0.2),
                        border: Border.all(
                          color: AppColors.cyan.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          fortune.handIcon,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fortune.handTypeName,
                            style: GoogleFonts.cinzelDecorative(
                              fontSize: 16,
                              color: AppColors.cyan,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fortune.formattedDate,
                            style: GoogleFonts.cinzelDecorative(
                              fontSize: 14,
                              color: Colors.white60,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // More button
                    IconButton(
                      onPressed: () => _showFortuneOptions(fortune),
                      icon: const Icon(
                        Icons.more_horiz,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Summary
                Text(
                  fortune.shortSummary,
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w300,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // Footer
                Row(
                  children: [
                    Icon(
                      Icons.visibility,
                      size: 16,
                      color: AppColors.cyan.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Dotknij aby przeczytać',
                      style: GoogleFonts.cinzelDecorative(
                        fontSize: 12,
                        color: AppColors.cyan.withOpacity(0.7),
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openFortuneDetail(FortuneHistory fortune) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            FortuneDetailScreen(fortune: fortune),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.3, 0.0),
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
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _showFortuneOptions(FortuneHistory fortune) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A2332),
              Color(0xFF0B1426),
            ],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          border: Border.all(
            color: AppColors.cyan.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Opcje wróżby',
              style: GoogleFonts.cinzelDecorative(
                fontSize: 18,
                color: AppColors.cyan,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            // Options
            _buildOptionTile(
              icon: Icons.share,
              title: 'Udostępnij',
              onTap: () {
                Navigator.of(context).pop();
                _shareFortune(fortune);
              },
            ),
            _buildOptionTile(
              icon: Icons.visibility,
              title: 'Zobacz szczegóły',
              onTap: () {
                Navigator.of(context).pop();
                _openFortuneDetail(fortune);
              },
            ),
            _buildOptionTile(
              icon: Icons.delete_outline,
              title: 'Usuń',
              color: Colors.red,
              onTap: () {
                Navigator.of(context).pop();
                _deleteFortune(fortune);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final tileColor = color ?? Colors.white;
    
    return ListTile(
      leading: Icon(icon, color: tileColor),
      title: Text(
        title,
        style: GoogleFonts.cinzelDecorative(
          color: tileColor,
          fontWeight: FontWeight.w400,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A2332),
              Color(0xFF0B1426),
            ],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          border: Border.all(
            color: AppColors.cyan.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Opcje historii',
              style: GoogleFonts.cinzelDecorative(
                fontSize: 18,
                color: AppColors.cyan,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            // Options
            _buildOptionTile(
              icon: Icons.refresh,
              title: 'Odśwież',
              onTap: () {
                Navigator.of(context).pop();
                _loadHistory();
              },
            ),
            if (_history.isNotEmpty)
              _buildOptionTile(
                icon: Icons.delete_sweep,
                title: 'Wyczyść całą historię',
                color: Colors.red,
                onTap: () {
                  Navigator.of(context).pop();
                  _clearAllHistory();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _shareFortune(FortuneHistory fortune) {
    final shareText = '''
🔮 Moja wróżba z dłoni - AI Wróżka

${fortune.handIcon} ${fortune.handTypeName}
📅 ${fortune.formattedDate}

${fortune.shortSummary}

Odkryj swoją przyszłość z AI Wróżka!
''';

    Share.share(shareText, subject: 'Moja wróżba z dłoni');
  }

  void _deleteFortune(FortuneHistory fortune) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A2332),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.red.withOpacity(0.5),
            width: 1,
          ),
        ),
        title: Text(
          'Usuń wróżbę',
          style: GoogleFonts.cinzelDecorative(
            color: Colors.red,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Czy na pewno chcesz usunąć tę wróżbę z ${fortune.formattedDate}?',
          style: GoogleFonts.cinzelDecorative(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Anuluj',
              style: GoogleFonts.cinzelDecorative(
                color: Colors.white60,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _historyService.deleteFortune(fortune.id);
              _loadHistory();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Wróżba została usunięta',
                      style: GoogleFonts.cinzelDecorative(),
                    ),
                    backgroundColor: Colors.green.withOpacity(0.8),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Usuń',
              style: GoogleFonts.cinzelDecorative(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _clearAllHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A2332),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.red.withOpacity(0.5),
            width: 1,
          ),
        ),
        title: Text(
          'Wyczyść historię',
          style: GoogleFonts.cinzelDecorative(
            color: Colors.red,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Czy na pewno chcesz usunąć wszystkie wróżby z historii? Tej operacji nie można cofnąć.',
          style: GoogleFonts.cinzelDecorative(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Anuluj',
              style: GoogleFonts.cinzelDecorative(
                color: Colors.white60,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _historyService.clearHistory();
              _loadHistory();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Historia została wyczyszczona',
                      style: GoogleFonts.cinzelDecorative(),
                    ),
                    backgroundColor: Colors.green.withOpacity(0.8),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Wyczyść',
              style: GoogleFonts.cinzelDecorative(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter dla tła historii
class HistoryBackgroundPainter extends CustomPainter {
  final double animationValue;

  HistoryBackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()..style = PaintingStyle.fill;

    try {
      // Floating mystical particles
      for (int i = 0; i < 20; i++) {
        final angle = (animationValue * math.pi) + (i * 2 * math.pi / 20);
        final radius = 40.0 + (i % 3) * 20.0;
        final centerX = size.width * (0.1 + (i % 5) * 0.2);
        final centerY = size.height * (0.1 + (i % 4) * 0.25);
        
        final x = centerX + radius * math.cos(angle * 0.3);
        final y = centerY + radius * math.sin(angle * 0.2);

        if (x >= -10 && x <= size.width + 10 && 
            y >= -10 && y <= size.height + 10) {
          final particleSize = 0.8 + math.sin(animationValue * 3 * math.pi + i) * 0.4;
          final opacity = 0.05 + math.sin(animationValue * 2 * math.pi + i * 0.5) * 0.03;
          
          if (particleSize > 0) {
            paint.color = AppColors.cyan.withOpacity(opacity.clamp(0.01, 0.08));
            canvas.drawCircle(Offset(x, y), particleSize.abs(), paint);
          }
        }
      }

      // Subtle corner decorations
      final cornerPaint = Paint()
        ..color = AppColors.cyan.withOpacity(0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      if (size.width > 100 && size.height > 100) {
        // Decorative corners
        canvas.drawArc(
          Rect.fromLTWH(20, 20, 25, 25),
          -math.pi,
          math.pi / 2,
          false,
          cornerPaint,
        );

        canvas.drawArc(
          Rect.fromLTWH(size.width - 45, size.height - 45, 25, 25),
          0,
          math.pi / 2,
          false,
          cornerPaint,
        );
      }
    } catch (e) {
      print('❌ Błąd w HistoryBackgroundPainter: $e');
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}