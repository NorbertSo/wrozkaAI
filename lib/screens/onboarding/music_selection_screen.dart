// lib/screens/music_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import '../../widgets/haptic_button.dart';
import '../../services/background_music_service.dart';
import '../../services/logging_service.dart';
import '../../services/haptic_service.dart';
import '../../services/user_preferences_service.dart';
import '../../utils/constants.dart';
import '../../utils/responsive_utils.dart';

class MusicSelectionScreen extends StatefulWidget {
  final String userName;
  final String userGender;

  const MusicSelectionScreen({
    super.key,
    required this.userName,
    required this.userGender,
  });

  @override
  State<MusicSelectionScreen> createState() => _MusicSelectionScreenState();
}

class _MusicSelectionScreenState extends State<MusicSelectionScreen>
    with TickerProviderStateMixin {
  final HapticService _hapticService = HapticService();
  final BackgroundMusicService _musicService = BackgroundMusicService();

  late AnimationController _fadeController;
  late AnimationController _starController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _starAnimation;

  String? _currentlyPlayingId;
  String? _selectedTrackId;
  bool _isLoading = false;

  // Lista dostępnych utworów
  final List<Map<String, dynamic>> _musicTracks = [
    {
      'id': 'mystic_ambient',
      'title': 'Mistyczna Atmosfera',
      'subtitle': 'Spokojne dźwięki kosmosu',
      'description':
          'Delikatne, otoczeniowe dźwięki idealne do wróżenia i medytacji.',
      'filename': 'musicbg.mp3', // Obecny utwór
      'duration': '5:30',
      'mood': 'Relaksujący',
      'color': AppColors.cyan,
      'icon': Icons.nightlight_round,
    },
    {
      'id': 'crystal_meditation',
      'title': 'Kryształowa Medytacja',
      'subtitle': 'Harmonijne wibracje',
      'description': 'Subtelne dźwięki mis tybetańskich i delikatnych melodii.',
      'filename': 'crystal_meditation.mp3',
      'duration': '7:45',
      'mood': 'Medytacyjny',
      'color': AppColors.purple,
      'icon': Icons.auto_awesome,
    },
    {
      'id': 'forest_whispers',
      'title': 'Szept Lasu',
      'subtitle': 'Natura w harmonii',
      'description': 'Naturalne dźwięki lasu połączone z subtelną muzyką.',
      'filename': 'forest_whispers.mp3',
      'duration': '6:15',
      'mood': 'Naturalny',
      'color': Colors.green,
      'icon': Icons.nature,
    },
    {
      'id': 'cosmic_energy',
      'title': 'Energia Kosmosu',
      'subtitle': 'Mistyczne wibracje',
      'description': 'Kosmiczne dźwięki pełne magicznej energii i mocy.',
      'filename': 'cosmic_energy.mp3',
      'duration': '8:20',
      'mood': 'Energetyczny',
      'color': Colors.amber,
      'icon': Icons.star,
    },
    {
      'id': 'moonlight_serenade',
      'title': 'Księżycowa Serenada',
      'subtitle': 'Nocna magia',
      'description': 'Romantyczne dźwięki nocnej magii i mistycznych obrzędów.',
      'filename': 'moonlight_serenade.mp3',
      'duration': '9:10',
      'mood': 'Romantyczny',
      'color': Colors.indigo,
      'icon': Icons.brightness_2,
    },
    {
      'id': 'silent_mode',
      'title': 'Cisza',
      'subtitle': 'Brak muzyki w tle',
      'description': 'Wyłącz muzykę w tle i ciesz się ciszą podczas wróżenia.',
      'filename': null,
      'duration': '∞',
      'mood': 'Cisza',
      'color': Colors.grey,
      'icon': Icons.volume_off,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCurrentSelection();
    _startAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _starController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _starAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _starController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _fadeController.forward();
  }

  Future<void> _loadCurrentSelection() async {
    try {
      final selectedTrack =
          await UserPreferencesService.getSelectedBackgroundMusic();
      setState(() {
        _selectedTrackId = selectedTrack ?? 'mystic_ambient';
      });
      LoggingService().logToConsole(
          '🎵 Załadowano wybór muzyki: $_selectedTrackId',
          tag: 'MUSIC');
    } catch (e) {
      LoggingService()
          .logToConsole('❌ Błąd ładowania wyboru muzyki: $e', tag: 'ERROR');
    }
  }

  Future<void> _playPreview(String trackId) async {
    await _hapticService.trigger(HapticType.light);

    // Zatrzymaj obecną muzykę
    if (_currentlyPlayingId != null) {
      await _musicService.stopBackgroundMusic();
    }

    setState(() {
      _currentlyPlayingId = trackId;
    });

    try {
      if (trackId == 'silent_mode') {
        // Dla trybu ciszy - po prostu zatrzymaj muzykę
        LoggingService().logToConsole('🔇 Preview: Tryb ciszy', tag: 'MUSIC');
        return;
      }

      final track = _musicTracks.firstWhere((t) => t['id'] == trackId);
      await _musicService.previewTrack(track['filename']);

      LoggingService()
          .logToConsole('🎵 Preview: ${track['title']}', tag: 'MUSIC');

      // Auto-stop preview po 30 sekundach
      Future.delayed(const Duration(seconds: 30), () {
        if (_currentlyPlayingId == trackId && mounted) {
          _stopPreview();
        }
      });
    } catch (e) {
      LoggingService().logToConsole('❌ Błąd preview: $e', tag: 'ERROR');
      setState(() {
        _currentlyPlayingId = null;
      });
    }
  }

  Future<void> _stopPreview() async {
    await _hapticService.trigger(HapticType.light);

    setState(() {
      _currentlyPlayingId = null;
    });

    await _musicService.stopPreview();
    LoggingService().logToConsole('⏹️ Preview zatrzymany', tag: 'MUSIC');
  }

  Future<void> _selectTrack(String trackId) async {
    await _hapticService.trigger(HapticType.medium);

    setState(() {
      _isLoading = true;
      _selectedTrackId = trackId;
    });

    try {
      // Zapisz wybór użytkownika
      await UserPreferencesService.setSelectedBackgroundMusic(trackId);

      // Zastosuj nową muzykę w tle
      if (trackId == 'silent_mode') {
        await _musicService.setBackgroundMusicEnabled(false);
        LoggingService()
            .logToConsole('🔇 Wyłączono muzykę w tle', tag: 'MUSIC');
      } else {
        final track = _musicTracks.firstWhere((t) => t['id'] == trackId);
        await _musicService.changeBackgroundMusic(track['filename']);
        await _musicService.setBackgroundMusicEnabled(true);
        LoggingService().logToConsole(
            '🎵 Zmieniono muzykę na: ${track['title']}',
            tag: 'MUSIC');
      }

      // Pokaż komunikat sukcesu
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  trackId == 'silent_mode'
                      ? 'Muzyka wyłączona'
                      : 'Muzyka zmieniona pomyślnie',
                  style: GoogleFonts.openSans(color: Colors.white),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      LoggingService().logToConsole('❌ Błąd zmiany muzyki: $e', tag: 'ERROR');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Błąd zmiany muzyki',
                  style: GoogleFonts.openSans(color: Colors.white),
                ),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _starController.dispose();
    _stopPreview(); // Zatrzymaj preview przy wyjściu
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
        child: Stack(
          children: [
            // Animated Stars Background
            AnimatedBuilder(
              animation: _starAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: StarFieldPainter(_starAnimation.value),
                  size: Size.infinite,
                );
              },
            ),

            // Main Content
            SafeArea(
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Column(
                      children: [
                        // Header
                        _buildHeader(),

                        // Scrollable Content
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  context.isTabletOrLarger ? 24.0 : 16.0,
                              vertical: 16.0,
                            ),
                            child: Column(
                              children: [
                                // Welcome Message
                                _buildWelcomeCard(),

                                const SizedBox(height: 20),

                                // Music Tracks
                                Column(
                                  children: _musicTracks.map((track) {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      child: _buildMusicCard(track),
                                    );
                                  }).toList(),
                                ),

                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Back Button
          HapticButton(
            onPressed: () {
              _stopPreview();
              Navigator.of(context).pop();
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: AppColors.cyan,
                size: 20,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Title
          Expanded(
            child: Text(
              'Wybierz muzykę w tle',
              style: GoogleFonts.cinzelDecorative(
                fontSize: context.isTabletOrLarger ? 20 : 18,
                color: AppColors.cyan,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(width: 12),

          // Music Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.music_note,
              color: AppColors.cyan,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
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
          color: AppColors.cyan.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.music_note,
            color: AppColors.cyan,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            'Personalizuj swoją atmosferę',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 18,
              color: AppColors.cyan,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Wybierz muzykę, która najlepiej wspiera Twoją duchową podróż. Możesz w każdej chwili odsłuchać podgląd.',
            style: GoogleFonts.openSans(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMusicCard(Map<String, dynamic> track) {
    final isSelected = _selectedTrackId == track['id'];
    final isPlaying = _currentlyPlayingId == track['id'];
    final isSilentMode = track['id'] == 'silent_mode';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isSelected
              ? [
                  track['color'].withOpacity(0.2),
                  track['color'].withOpacity(0.1),
                ]
              : [
                  Colors.black.withOpacity(0.8),
                  Colors.black.withOpacity(0.6),
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? track['color'].withOpacity(0.6)
              : track['color'].withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Top Row - Icon, Title, and Play Button
            Row(
              children: [
                // Icon Circle
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        track['color'].withOpacity(0.3),
                        track['color'].withOpacity(0.1),
                      ],
                    ),
                    border: Border.all(
                      color: track['color'].withOpacity(0.6),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    track['icon'],
                    size: 24,
                    color: track['color'],
                  ),
                ),

                const SizedBox(width: 16),

                // Title and Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track['title'],
                        style: GoogleFonts.cinzelDecorative(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        track['subtitle'],
                        style: GoogleFonts.openSans(
                          fontSize: 12,
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),

                // Play/Stop Button
                if (!isSilentMode) ...[
                  HapticButton(
                    onPressed: isPlaying
                        ? _stopPreview
                        : () => _playPreview(track['id']),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: track['color'].withOpacity(0.2),
                        border: Border.all(
                          color: track['color'].withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        isPlaying ? Icons.stop : Icons.play_arrow,
                        color: track['color'],
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              track['description'],
              style: GoogleFonts.openSans(
                fontSize: 13,
                color: Colors.white.withOpacity(0.8),
                height: 1.4,
              ),
            ),

            const SizedBox(height: 12),

            // Meta Info Row
            Row(
              children: [
                _buildMetaChip(
                    Icons.access_time, track['duration'], track['color']),
                const SizedBox(width: 8),
                _buildMetaChip(Icons.mood, track['mood'], track['color']),

                const Spacer(),

                // Select Button
                HapticButton(
                  onPressed:
                      _isLoading ? null : () => _selectTrack(track['id']),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: isSelected
                          ? track['color'].withOpacity(0.8)
                          : track['color'].withOpacity(0.2),
                      border: Border.all(
                        color: track['color'].withOpacity(0.6),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isLoading && isSelected) ...[
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        ] else ...[
                          Icon(
                            isSelected
                                ? Icons.check
                                : Icons.radio_button_unchecked,
                            color: isSelected ? Colors.white : track['color'],
                            size: 16,
                          ),
                        ],
                        const SizedBox(width: 8),
                        Text(
                          isSelected ? 'Wybrano' : 'Wybierz',
                          style: GoogleFonts.openSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : track['color'],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.15),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.openSans(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for Star Field Background
class StarFieldPainter extends CustomPainter {
  final double animationValue;

  StarFieldPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1;

    final random = Random(42);

    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;

      final opacity = (0.3 + 0.7 * ((animationValue + i * 0.1) % 1.0));
      paint.color = Colors.white.withOpacity(opacity * 0.3);

      canvas.drawCircle(Offset(x, y), 1, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
