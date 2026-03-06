import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login/view/login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<_PageData> _pages = const [
    _PageData(
      title: "Welcome to TSL",
      description:
      "TSL is your trusted partner in securities brokerage, fund management and investment advisory. We provide comprehensive investment solutions tailored to your needs.",
      icon: Icons.trending_up_rounded,
    ),
    _PageData(
      title: "Secure & Licensed",
      description:
      "Licensed by the Capital Markets and Securities Authority (CMSA), Dar es salaam Stock Exchange (DSE) and Bank of Tanzania.",
      icon: Icons.verified_user_rounded,
    ),
    _PageData(
      title: "Start Your Journey",
      description:
      "Join thousands of satisfied clients who trust TSL for their financial future.",
      icon: Icons.rocket_launch_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _fadeController.reset();
    _slideController.reset();
    _fadeController.forward();
    _slideController.forward();
  }

  /// Marks onboarding as seen, then navigates to Login.
  Future<void> _navigateToLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);

    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToLogin();
    }
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
            // Decorative background circles
            Positioned(
              top: -60,
              left: -60,
              child: _GlassCircle(size: 200),
            ),
            Positioned(
              top: size.height * 0.25,
              right: -80,
              child: _GlassCircle(size: 160),
            ),
            Positioned(
              bottom: -40,
              left: -30,
              child: _GlassCircle(size: 140),
            ),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Skip button row
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedOpacity(
                          opacity: _currentPage < 2 ? 1 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: GestureDetector(
                            onTap: _currentPage < 2 ? _navigateToLogin : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.35),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.6),
                                    width: 1),
                              ),
                              child: const Text(
                                'Skip',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Logo card
                  const SizedBox(height: 20),
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.8), width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withOpacity(0.2),
                          blurRadius: 24,
                          spreadRadius: 4,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Image.asset("assets/logo.png"),
                  ),

                  // Page view
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      itemCount: _pages.length,
                      itemBuilder: (context, index) {
                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: _buildPageContent(_pages[index]),
                          ),
                        );
                      },
                    ),
                  ),

                  // Bottom section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                    child: Column(
                      children: [
                        // Dot indicators
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (index) {
                            final isActive = _currentPage == index;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeInOut,
                              margin:
                              const EdgeInsets.symmetric(horizontal: 4),
                              height: 8,
                              width: isActive ? 28 : 8,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.blue
                                    : Colors.white.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: isActive
                                    ? [
                                  BoxShadow(
                                    color:
                                    Colors.blue.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                                    : [],
                              ),
                            );
                          }),
                        ),

                        const SizedBox(height: 28),

                        // CTA Button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _nextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              elevation: 6,
                              shadowColor: Colors.blue.withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: Row(
                                key: ValueKey(_currentPage),
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _currentPage == 2
                                        ? 'Get Started'
                                        : 'Continue',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    _currentPage == 2
                                        ? Icons.check_circle_outline_rounded
                                        : Icons.arrow_forward_rounded,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
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

  Widget _buildPageContent(_PageData page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon badge
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.45),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withOpacity(0.7), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withOpacity(0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(page.icon, size: 34, color: Colors.blue.shade700),
          ),

          const SizedBox(height: 28),

          // Title
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              height: 1.2,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Divider accent
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 20),

          // Description
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15.5,
              color: Colors.black.withOpacity(0.65),
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageData {
  final String title;
  final String description;
  final IconData icon;

  const _PageData({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class _GlassCircle extends StatelessWidget {
  final double size;

  const _GlassCircle({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
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
}