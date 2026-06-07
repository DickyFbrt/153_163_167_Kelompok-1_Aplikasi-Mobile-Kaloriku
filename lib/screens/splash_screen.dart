import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/app_theme.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Controllers
  late AnimationController _bgController;
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _taglineController;
  late AnimationController _progressController;
  late AnimationController _particleController;

  // Animations
  late Animation<double> _bgScale;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoGlow;
  late Animation<Offset> _titleSlide;
  late Animation<double> _titleOpacity;
  late Animation<double> _taglineOpacity;
  late Animation<Offset> _taglineSlide;
  late Animation<double> _progressValue;
  late Animation<double> _particleOpacity;

  @override
  void initState() {
    super.initState();
    // Status bar transparan
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _initAnimations();
    _startSequence();
  }

  void _initAnimations() {
    // Background subtle scale
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _bgScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.easeOut),
    );

    // Logo scale + opacity
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _logoGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    // Title slide up
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic));
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    // Tagline fade + slide
    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeOut),
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _taglineController, curve: Curves.easeOut));

    // Progress bar
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _progressValue = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    // Particle dots fade
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _particleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.easeOut),
    );
  }

  Future<void> _startSequence() async {
    // 1. Background zoom mulai
    _bgController.forward();

    // 2. Logo muncul setelah 80ms
    await Future.delayed(const Duration(milliseconds: 80));
    _logoController.forward();

    // 3. Title slide up setelah logo
    await Future.delayed(const Duration(milliseconds: 150));
    _textController.forward();

    // 4. Tagline fade in
    await Future.delayed(const Duration(milliseconds: 100));
    _taglineController.forward();
    _particleController.forward();

    // 5. Progress bar mulai
    await Future.delayed(const Duration(milliseconds: 50));
    _progressController.forward();

    // 6. Tunggu loading selesai + animasi exit (sangat cepat)
    await Future.delayed(const Duration(milliseconds: 850));
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    if (!mounted) return;

    debugPrint('Splash: starting navigateNext');

    try {
      final auth = context.read<AuthProvider>();

      // Tunggu auth selesai load sesi jika belum.
      // Hindari kemungkinan hang sehingga layar tetap black.
      var waitedMs = 0;
      while (auth.isLoading && waitedMs < 5000) {
        await Future.delayed(const Duration(milliseconds: 50));
        waitedMs += 50;
      }

      // Jika masih loading (mis. error saat load session), lanjutkan saja.
      if (auth.isLoading) {
        debugPrint(
            'AuthProvider is still loading after ${waitedMs}ms, forcing navigation.');
      }

      if (!mounted) return;

      // Animasi exit — fade out layar
      await _bgController.reverse();

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          // Selalu ke halaman login — user harus login setiap membuka aplikasi
          pageBuilder: (_, a, __) => const LoginScreen(),
          transitionsBuilder: (_, a, __, child) => FadeTransition(
            opacity: CurvedAnimation(parent: a, curve: Curves.easeIn),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 200),
        ),
      );
    } catch (e, st) {
      debugPrint('Splash navigateNext failed: $e\n$st');

      // Jangan biarkan aplikasi blank kalau ada error.
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    _logoController.dispose();
    _textController.dispose();
    _taglineController.dispose();
    _progressController.dispose();
    _particleController.dispose();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.dark,
    ));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (_, __) {
          return Transform.scale(
            scale: _bgScale.value,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1E3C0D),
                    Color(0xFF2E5A14),
                    Color(0xFF3B6D11),
                    Color(0xFF4E8A1A),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  // Dekorasi lingkaran latar
                  _buildDecorativeCircles(),
                  // Konten utama
                  SafeArea(
                    child: Column(
                      children: [
                        const Spacer(flex: 2),
                        _buildLogo(),
                        const SizedBox(height: 28),
                        _buildTitle(),
                        const SizedBox(height: 12),
                        _buildTagline(),
                        const Spacer(flex: 3),
                        _buildProgressArea(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Logo ───────────────────────────────────────────
  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (_, __) {
        return FadeTransition(
          opacity: _logoOpacity,
          child: Transform.scale(
            scale: _logoScale.value,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glow ring
                AnimatedBuilder(
                  animation: _logoGlow,
                  builder: (_, __) => Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white
                              .withValues(alpha: _logoGlow.value * 0.2),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
                // Lingkaran luar
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                ),
                // Icon container
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    size: 40,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Nama Aplikasi ──────────────────────────────────
  Widget _buildTitle() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (_, __) {
        return FadeTransition(
          opacity: _titleOpacity,
          child: SlideTransition(
            position: _titleSlide,
            child: Column(
              children: [
                // Nama utama
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.white, Color(0xFFD4F0A0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    'KaloriKu+',
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 44,
                      color: Colors.white,
                      letterSpacing: 1.2,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Tagline ────────────────────────────────────────
  Widget _buildTagline() {
    return AnimatedBuilder(
      animation: _taglineController,
      builder: (_, __) {
        return FadeTransition(
          opacity: _taglineOpacity,
          child: SlideTransition(
            position: _taglineSlide,
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    '🥗  Hidup sehat dimulai dari sini',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.9),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Dot particles
                AnimatedBuilder(
                  animation: _particleController,
                  builder: (_, __) => Opacity(
                    opacity: _particleOpacity.value,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (i) {
                        return Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                Colors.white.withValues(alpha: 0.4 + i * 0.2),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Progress Area ──────────────────────────────────
  Widget _buildProgressArea() {
    return AnimatedBuilder(
      animation: _progressController,
      builder: (_, __) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Column(
            children: [
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progressValue.value,
                  minHeight: 3,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Memuat aplikasi...',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.5),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Dekorasi latar ─────────────────────────────────
  Widget _buildDecorativeCircles() {
    return Stack(
      children: [
        // Lingkaran pojok kanan atas
        Positioned(
          top: -80,
          right: -80,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
        ),
        // Lingkaran pojok kiri bawah
        Positioned(
          bottom: -100,
          left: -60,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.03),
            ),
          ),
        ),
        // Aksen kecil tengah atas
        Positioned(
          top: 80,
          left: 30,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ),
        // Aksen kecil kanan bawah
        Positioned(
          bottom: 120,
          right: 24,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
        ),
      ],
    );
  }
}
