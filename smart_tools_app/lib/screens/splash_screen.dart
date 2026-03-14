import 'dart:math';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Phase 1: Logo scale + fade in
  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  // Phase 2: Text slide up + fade in
  late AnimationController _textController;
  late Animation<double> _textSlide;
  late Animation<double> _textOpacity;

  // Phase 3: Glow pulse
  late AnimationController _glowController;
  late Animation<double> _glowRadius;

  // Phase 4: Particles
  late AnimationController _particleController;

  // Phase 5: Exit transition
  late AnimationController _exitController;
  late Animation<double> _exitScale;
  late Animation<double> _exitOpacity;

  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();

    // Generate particles
    final rng = Random();
    for (int i = 0; i < 20; i++) {
      _particles.add(_Particle(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: rng.nextDouble() * 4 + 1,
        speed: rng.nextDouble() * 0.3 + 0.1,
        opacity: rng.nextDouble() * 0.5 + 0.1,
      ));
    }

    // Phase 1: Logo
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    // Phase 2: Text
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _textSlide = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    // Phase 3: Glow
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _glowRadius = Tween<double>(begin: 40, end: 80).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Phase 4: Particles
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Phase 5: Exit
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _exitScale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    // Phase 1: Show logo with elastic bounce
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 400));

    // Phase 2: Slide in text
    _textController.forward();
    await Future.delayed(const Duration(milliseconds: 200));

    // Phase 3: Start glow pulse
    _glowController.repeat(reverse: true);

    // Phase 4: Start particles
    _particleController.repeat();

    // Wait for the splash to be enjoyed
    await Future.delayed(const Duration(milliseconds: 2000));

    // Request permissions in background
    _requestPermissions();

    // Phase 5: Exit
    _exitController.forward();
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  Future<void> _requestPermissions() async {
    // Request storage permissions silently
    try {
      await Permission.storage.request();
      await Permission.manageExternalStorage.request();
      
      // Request media permissions for Android 13+
      await Permission.photos.request();
      await Permission.videos.request();
      await Permission.audio.request();
    } catch (e) {
      // Ignore errors, permissions will be requested when needed
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1A),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _logoController,
          _textController,
          _glowController,
          _particleController,
          _exitController,
        ]),
        builder: (context, child) {
          return FadeTransition(
            opacity: _exitOpacity,
            child: ScaleTransition(
              scale: _exitScale,
              child: Stack(
                children: [
                  // Floating particles
                  ..._buildParticles(),

                  // Central content
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Glow behind logo
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: _glowRadius.value * 2.5,
                              height: _glowRadius.value * 2.5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary.withValues(alpha: 0.3),
                                    blurRadius: _glowRadius.value,
                                    spreadRadius: _glowRadius.value * 0.3,
                                  ),
                                ],
                              ),
                            ),
                            // Logo
                            Opacity(
                              opacity: _logoOpacity.value,
                              child: Transform.scale(
                                scale: _logoScale.value,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [AppTheme.primary, AppTheme.primaryLight],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primary.withValues(alpha: 0.5),
                                        blurRadius: 30,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.auto_fix_high_rounded,
                                    size: 56,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 36),

                        // App name
                        Transform.translate(
                          offset: Offset(0, _textSlide.value),
                          child: Opacity(
                            opacity: _textOpacity.value,
                            child: ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Colors.white, AppTheme.primaryLight],
                              ).createShader(bounds),
                              child: const Text(
                                'أدواتي',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Subtitle
                        Transform.translate(
                          offset: Offset(0, _textSlide.value * 1.2),
                          child: Opacity(
                            opacity: _textOpacity.value * 0.7,
                            child: const Text(
                              'أدوات ذكية بين يديك',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white54,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom shimmer line
                  Positioned(
                    bottom: 60,
                    left: 0,
                    right: 0,
                    child: Opacity(
                      opacity: _textOpacity.value * 0.4,
                      child: Center(
                        child: Container(
                          width: 80,
                          height: 3,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: const LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppTheme.primary,
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
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

  List<Widget> _buildParticles() {
    final size = MediaQuery.of(context).size;
    return _particles.map((p) {
      final progress = _particleController.value;
      final y = (p.y - progress * p.speed) % 1.0;
      return Positioned(
        left: p.x * size.width,
        top: y * size.height,
        child: Opacity(
          opacity: p.opacity * _logoOpacity.value,
          child: Container(
            width: p.size,
            height: p.size,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  blurRadius: p.size * 2,
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}

class _Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}
