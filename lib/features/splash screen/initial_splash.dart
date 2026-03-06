import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsl/features/splash%20screen/splash.dart';
import '../auth/login/view/login.dart';

class InitialSplashScreen extends StatefulWidget {
  const InitialSplashScreen({super.key});

  @override
  State<InitialSplashScreen> createState() => _InitialSplashScreenState();
}

class _InitialSplashScreenState extends State<InitialSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _masterController;
  late AnimationController _chartController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _subtitleFade;
  late Animation<double> _lineWidth;
  late Animation<double> _statsFade;
  late Animation<double> _chartProgress;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;
  late Animation<double> _shimmerPosition;

  @override
  void initState() {
    super.initState();

    _masterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.0, 0.45, curve: Curves.elasticOut),
      ),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
    ));
    _lineWidth = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.5, 0.72, curve: Curves.easeOut),
      ),
    );
    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.6, 0.85, curve: Curves.easeOut),
      ),
    );
    _statsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.78, 1.0, curve: Curves.easeOut),
      ),
    );
    _chartProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _chartController, curve: Curves.easeInOut),
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.65).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.55, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _shimmerPosition = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _masterController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _chartController.forward();
    });
    Future.delayed(const Duration(milliseconds: 5000), _navigate);
  }

  Future<void> _navigate() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
        hasSeenOnboarding ? const LoginScreen() : const SplashScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _masterController.dispose();
    _chartController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF7FFFD4),
              Color(0xFF98FB98),
              Color(0xFFAFEEEE),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Subtle dot grid overlay
            CustomPaint(size: size, painter: _DotGridPainter()),

            // Original glass circles
            Positioned(top: -60, left: -60, child: _GlassCircle(size: 220)),
            Positioned(bottom: -60, right: -60, child: _GlassCircle(size: 200)),
            Positioned(
              top: size.height * 0.42,
              left: -80,
              child: _GlassCircle(size: 160),
            ),

            // Animated market chart
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: size.height * 0.38,
              child: AnimatedBuilder(
                animation: _chartProgress,
                builder: (context, _) => CustomPaint(
                  painter: _ChartPainter(progress: _chartProgress.value),
                ),
              ),
            ),

            // Soft radial glow behind logo
            Positioned(
              top: size.height * 0.20,
              left: size.width / 2 - 110,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Logo with pulse ring
                  AnimatedBuilder(
                    animation: Listenable.merge(
                        [_logoScale, _logoFade, _pulseScale, _pulseOpacity]),
                    builder: (context, _) => FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: SizedBox(
                          width: 150,
                          height: 150,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Pulse ring
                              Transform.scale(
                                scale: _pulseScale.value,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.teal.withOpacity(
                                          _pulseOpacity.value),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                              // Logo circle
                              Container(
                                width: 118,
                                height: 118,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.55),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.9),
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.teal.withOpacity(0.25),
                                      blurRadius: 32,
                                      spreadRadius: 5,
                                      offset: const Offset(0, 8),
                                    ),
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.6),
                                      blurRadius: 12,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(22),
                                child: AnimatedBuilder(
                                  animation: _shimmerPosition,
                                  builder: (context, child) => ShaderMask(
                                    shaderCallback: (rect) => LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.black87,
                                        Colors.black87,
                                        Colors.teal.shade700,
                                        Colors.black87,
                                        Colors.black87,
                                      ],
                                      stops: [
                                        0,
                                        (_shimmerPosition.value - 0.3)
                                            .clamp(0.0, 1.0),
                                        _shimmerPosition.value
                                            .clamp(0.0, 1.0),
                                        (_shimmerPosition.value + 0.3)
                                            .clamp(0.0, 1.0),
                                        1,
                                      ],
                                    ).createShader(rect),
                                    child: child!,
                                  ),
                                  child: Image.asset("assets/logo.png"),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // TSL wordmark
                  FadeTransition(
                    opacity: _titleFade,
                    child: SlideTransition(
                      position: _titleSlide,
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'T',
                              style: TextStyle(
                                fontSize: 46,
                                fontWeight: FontWeight.w900,
                                color: Colors.teal.shade700,
                                letterSpacing: 10,
                                height: 1,
                              ),
                            ),
                            const TextSpan(
                              text: 'SL',
                              style: TextStyle(
                                fontSize: 46,
                                fontWeight: FontWeight.w900,
                                color: Colors.blue,
                                letterSpacing: 10,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Animated teal divider
                  AnimatedBuilder(
                    animation: _lineWidth,
                    builder: (context, _) => Center(
                      child: Container(
                        width: 180 * _lineWidth.value,
                        height: 1.5,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.teal.withOpacity(0.7),
                              Colors.teal,
                              Colors.teal.withOpacity(0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Subtitle
                  FadeTransition(
                    opacity: _subtitleFade,
                    child: Text(
                      'SECURITIES  ·  BROKERAGE  ·  WEALTH',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.teal.shade800.withOpacity(0.7),
                        letterSpacing: 2.8,
                      ),
                    ),
                  ),

                  const Spacer(flex: 1),

                  // Market stats card
                  FadeTransition(
                    opacity: _statsFade,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.6),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.teal.withOpacity(0.1),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _StatChip(
                                label: 'DSE', value: '+1.24%', positive: true),
                            _VerticalDivider(),
                            _StatChip(
                                label: 'EQUITY',
                                value: '+0.87%',
                                positive: true),
                            _VerticalDivider(),
                            _StatChip(
                                label: 'BONDS',
                                value: '-0.32%',
                                positive: false),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Compliance + loading bar
                  FadeTransition(
                    opacity: _subtitleFade,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified_rounded,
                                size: 13, color: Colors.teal.shade700),
                            const SizedBox(width: 6),
                            Text(
                              'CMSA Licensed  ·  DSE Member  ·  BOT Regulated',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.black54,
                                letterSpacing: 1.1,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        _AnimatedLoadingBar(controller: _masterController),
                        const SizedBox(height: 36),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final bool positive;
  const _StatChip(
      {required this.label, required this.value, required this.positive});

  @override
  Widget build(BuildContext context) {
    final color = positive ? Colors.green.shade700 : Colors.red.shade600;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: Colors.teal.shade800,
                letterSpacing: 1.5)),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(positive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                size: 16, color: color),
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.4)),
          ],
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      width: 1, height: 28, color: Colors.teal.withOpacity(0.2));
}

class _AnimatedLoadingBar extends StatelessWidget {
  final AnimationController controller;
  const _AnimatedLoadingBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Container(
        width: 120,
        height: 2.5,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(2),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: controller.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                colors: [Colors.teal.shade400, Colors.teal.shade700],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withOpacity(0.4),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.teal.withOpacity(0.12)
      ..style = PaintingStyle.fill;
    const step = 32.0;
    for (double x = step; x < size.width; x += step) {
      for (double y = step; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _ChartPainter extends CustomPainter {
  final double progress;
  _ChartPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final points = _generatePoints(size);
    if (points.length < 2) return;

    final visible = points.sublist(
        0, (points.length * progress).round().clamp(2, points.length));

    // Fill
    final fillPath = Path()..moveTo(visible.first.dx, size.height);
    for (final p in visible) fillPath.lineTo(p.dx, p.dy);
    fillPath..lineTo(visible.last.dx, size.height)..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.teal.withOpacity(0.18),
            Colors.teal.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Line
    final linePath = Path()
      ..moveTo(visible.first.dx, visible.first.dy);
    for (int i = 1; i < visible.length; i++) {
      final p = visible[i - 1];
      final c = visible[i];
      linePath.cubicTo(
          (p.dx + c.dx) / 2, p.dy, (p.dx + c.dx) / 2, c.dy, c.dx, c.dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = Colors.teal.withOpacity(0.65)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Leading dot + glow
    if (visible.length > 1) {
      final last = visible.last;
      canvas.drawCircle(last, 9,
          Paint()..color = Colors.teal.withOpacity(0.2));
      canvas.drawCircle(last, 4,
          Paint()..color = Colors.teal.shade600);
    }
  }

  List<Offset> _generatePoints(Size size) {
    final rand = Random(42);
    final pts = <Offset>[];
    double y = size.height * 0.52;
    for (int i = 0; i < 60; i++) {
      final x = (i / 59) * size.width;
      y += (rand.nextDouble() - 0.44) * size.height * 0.07;
      y = y.clamp(size.height * 0.1, size.height * 0.85);
      pts.add(Offset(x, y));
    }
    return pts;
  }

  @override
  bool shouldRepaint(_ChartPainter old) => old.progress != progress;
}

class _GlassCircle extends StatelessWidget {
  final double size;
  const _GlassCircle({required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withOpacity(0.15),
      border:
      Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
    ),
  );
}