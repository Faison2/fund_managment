import 'dart:math';
import 'package:flutter/material.dart';

class ComingSoonPage extends StatefulWidget {
  const ComingSoonPage({super.key});

  @override
  State<ComingSoonPage> createState() => _ComingSoonPageState();
}

class _ComingSoonPageState extends State<ComingSoonPage>
    with TickerProviderStateMixin {
  late AnimationController _orbitController;
  late AnimationController _fadeController;
  late AnimationController _timerController;
  late AnimationController _textRevealController;
  late AnimationController _pulseController;

  late Animation<double> _fadeIn;
  late Animation<double> _textReveal;
  late Animation<double> _timerProgress;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    // Orbiting particles
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Pulse glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Fade in the entire screen
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();

    // Text reveal
    _textRevealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _textReveal = CurvedAnimation(
      parent: _textRevealController,
      curve: Curves.easeOutExpo,
    );
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _textRevealController.forward();
    });

    // 5-second countdown + auto-pop
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _timerProgress = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _timerController, curve: Curves.linear),
    );
    _timerController.forward();
    _timerController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _fadeController.dispose();
    _timerController.dispose();
    _textRevealController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050A12),
      body: FadeTransition(
        opacity: _fadeIn,
        child: Stack(
          children: [
            // Ambient background gradient blobs
            _buildBackgroundBlobs(),

            // Orbiting particles
            AnimatedBuilder(
              animation: _orbitController,
              builder: (_, __) => CustomPaint(
                painter: _OrbitPainter(_orbitController.value),
                child: const SizedBox.expand(),
              ),
            ),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Pulsing diamond icon
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (_, __) => Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4FC3F7)
                                .withOpacity(0.3 * _pulse.value),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Opacity(
                        opacity: _pulse.value,
                        child: const Icon(
                          Icons.diamond_outlined,
                          size: 52,
                          color: Color(0xFF4FC3F7),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // "COMING SOON" text reveal
                  AnimatedBuilder(
                    animation: _textReveal,
                    builder: (_, __) => ClipRect(
                      child: Align(
                        widthFactor: _textReveal.value,
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          'COMING SOON',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 10,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Subtitle
                  AnimatedBuilder(
                    animation: _textReveal,
                    builder: (_, __) => Opacity(
                      opacity: _textReveal.value,
                      child: const Text(
                        'Something extraordinary is on its way',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B8FAB),
                          letterSpacing: 2,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Countdown arc timer
                  AnimatedBuilder(
                    animation: _timerProgress,
                    builder: (_, __) {
                      final seconds =
                      (5 * _timerProgress.value).ceil().clamp(0, 5);
                      return Column(
                        children: [
                          SizedBox(
                            width: 90,
                            height: 90,
                            child: CustomPaint(
                              painter: _TimerArcPainter(_timerProgress.value),
                              child: Center(
                                child: Text(
                                  '$seconds',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Returning automatically...',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF3D5A70),
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // Top-left decorative line
            Positioned(
              top: 48,
              left: 28,
              child: _buildCornerDecor(),
            ),

            // Bottom-right decorative line
            Positioned(
              bottom: 48,
              right: 28,
              child: Transform.rotate(
                angle: pi,
                child: _buildCornerDecor(),
              ),
            ),

            // Back button
            Positioned(
              top: 44,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded,
                    color: Color(0xFF4FC3F7), size: 22),
                tooltip: 'Go back',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundBlobs() {
    return Stack(
      children: [
        Positioned(
          top: -80,
          left: -60,
          child: _GlowBlob(
            color: const Color(0xFF0D47A1).withOpacity(0.35),
            size: 280,
          ),
        ),
        Positioned(
          bottom: -60,
          right: -80,
          child: _GlowBlob(
            color: const Color(0xFF006064).withOpacity(0.3),
            size: 320,
          ),
        ),
        Positioned(
          top: 200,
          right: 40,
          child: _GlowBlob(
            color: const Color(0xFF1A237E).withOpacity(0.2),
            size: 180,
          ),
        ),
      ],
    );
  }

  Widget _buildCornerDecor() {
    return SizedBox(
      width: 36,
      height: 36,
      child: CustomPaint(painter: _CornerPainter()),
    );
  }
}

// ── Painters ────────────────────────────────────────────────────────────────

class _OrbitPainter extends CustomPainter {
  final double progress;
  _OrbitPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final paint = Paint()..style = PaintingStyle.fill;

    final orbits = [
      _OrbitConfig(160, 0.0, const Color(0xFF4FC3F7), 3.5),
      _OrbitConfig(210, pi * 0.4, const Color(0xFF80DEEA), 2.5),
      _OrbitConfig(250, pi * 0.9, const Color(0xFF29B6F6), 2.0),
      _OrbitConfig(130, pi * 1.5, const Color(0xFF00BCD4), 3.0),
      _OrbitConfig(290, pi * 1.2, const Color(0xFF4DD0E1), 2.0),
    ];

    for (final o in orbits) {
      final angle = progress * 2 * pi + o.phase;
      final dx = cx + o.radius * cos(angle);
      final dy = cy + o.radius * sin(angle) * 0.35; // elliptical feel
      paint.color = o.color.withOpacity(0.55);
      canvas.drawCircle(Offset(dx, dy), o.dotSize, paint);

      // Trailing dot
      final angle2 = angle - 0.3;
      final dx2 = cx + o.radius * cos(angle2);
      final dy2 = cy + o.radius * sin(angle2) * 0.35;
      paint.color = o.color.withOpacity(0.18);
      canvas.drawCircle(Offset(dx2, dy2), o.dotSize * 0.6, paint);
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => old.progress != progress;
}

class _OrbitConfig {
  final double radius;
  final double phase;
  final Color color;
  final double dotSize;
  const _OrbitConfig(this.radius, this.phase, this.color, this.dotSize);
}

class _TimerArcPainter extends CustomPainter {
  final double progress;
  _TimerArcPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    // Track
    final trackPaint = Paint()
      ..color = const Color(0xFF1A2940)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Arc
    final arcPaint = Paint()
      ..color = const Color(0xFF4FC3F7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      arcPaint,
    );

    // Glow arc
    final glowPaint = Paint()
      ..color = const Color(0xFF4FC3F7).withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(_TimerArcPainter old) => old.progress != progress;
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4FC3F7).withOpacity(0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Glow Blob ────────────────────────────────────────────────────────────────

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color, blurRadius: size * 0.8, spreadRadius: size * 0.1),
        ],
        color: color,
      ),
    );
  }
}