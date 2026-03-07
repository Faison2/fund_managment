import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic>? _userData;
  String? _accountStatus;

  late AnimationController _fadeController;
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  // ── Your original brand palette ────────────────────────────────────────────
  static const Color _teal      = Color(0xFF2E7D99);
  static const Color _green     = Color(0xFF4CAF50);
  static const Color _darkGreen = Color(0xFF2E7D32);
  static const Color _mintBg    = Color(0xFFB8E6D3);
  static const Color _white     = Color(0xFFFFFFFF);
  static const Color _textDark  = Color(0xFF333333);
  // ──────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fetchUserProfile();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      _fadeController.reset();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? cdsNumber     = prefs.getString('cdsNumber');
      String? accountStatus = prefs.getString('accountStatus');

      setState(() => _accountStatus = accountStatus ?? 'Unknown');

      if (cdsNumber == null || cdsNumber.isEmpty) {
        setState(() {
          _errorMessage = 'Account Number not found. Please login again.';
          _isLoading   = false;
        });
        return;
      }

      final url = Uri.parse(
          'https://portaluat.tsl.co.tz/FMSAPI/Home/UserBasicDetails');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'CDSNumber': cdsNumber}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success' &&
            responseData['data'] != null) {
          setState(() {
            _userData  = Map<String, dynamic>.from(responseData['data']);
            _isLoading = false;
          });
          _fadeController.forward();
        } else {
          setState(() {
            _errorMessage =
                responseData['statusDesc'] ?? 'Failed to load user data';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Network error: ${response.statusCode}';
          _isLoading   = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading   = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _mintBg,
      body: Stack(
        children: [
          _buildDecorativeBackground(),
          SafeArea(
            child: _isLoading
                ? _buildLoadingState()
                : _errorMessage.isNotEmpty
                ? _buildErrorState()
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  // ── Soft decorative blobs in your green/teal palette ──────────────────────
  Widget _buildDecorativeBackground() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, _) => CustomPaint(
        painter: _BlobPainter(_pulseAnimation.value),
        child: const SizedBox.expand(),
      ),
    );
  }

  // ── Shimmer loading skeleton ───────────────────────────────────────────────
  Widget _buildLoadingState() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Center(child: _shimmerBox(110, 110, radius: 55)),
              const SizedBox(height: 20),
              Center(child: _shimmerBox(200, 26)),
              const SizedBox(height: 10),
              Center(child: _shimmerBox(110, 16)),
              const SizedBox(height: 36),
              ...List.generate(4, (_) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _shimmerBox(double.infinity, 74, radius: 18),
              )),
            ],
          ),
        );
      },
    );
  }

  Widget _shimmerBox(double w, double h, {double radius = 12}) {
    final t = _shimmerController.value;
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment(-1.0 + t * 2, 0),
          end: Alignment(t * 2, 0),
          colors: const [
            Color(0xFFA8D8C2),
            Color(0xFFD4EFE4),
            Color(0xFFA8D8C2),
          ],
        ),
      ),
    );
  }

  // ── Error state ────────────────────────────────────────────────────────────
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _white.withOpacity(0.65),
                border: Border.all(color: Colors.red.withOpacity(0.3), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 56, color: Colors.redAccent),
            ),
            const SizedBox(height: 24),
            const Text('Something went wrong',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _darkGreen)),
            const SizedBox(height: 12),
            Text(_errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: Colors.red, height: 1.6)),
            const SizedBox(height: 32),
            _buildPrimaryButton('Try Again', _fetchUserProfile),
          ],
        ),
      ),
    );
  }

  // ── Main content ───────────────────────────────────────────────────────────
  Widget _buildContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildHeroHeader(),
            const SizedBox(height: 12),
            _buildQuickStats(),
            const SizedBox(height: 28),
            _buildSectionLabel('ACCOUNT INFORMATION'),
            const SizedBox(height: 12),
            _buildInfoCard(),
            const SizedBox(height: 28),
            _buildSectionLabel('ACTIONS'),
            const SizedBox(height: 12),
            _buildActions(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Hero header card ───────────────────────────────────────────────────────
  Widget _buildHeroHeader() {
    final name = _userData?['Names'] ?? 'Account Holder';
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').take(2).map((w) => w[0]).join().toUpperCase()
        : '??';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x662E7D99), Color(0x661A5F77)],
        ),
        boxShadow: [
          BoxShadow(
            color: _teal.withOpacity(0.35),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar with initials
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _white.withOpacity(0.15),
                  border: Border.all(color: _white.withOpacity(0.4), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: _white.withOpacity(0.12),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: _white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _green,
                  border: Border.all(color: _teal, width: 2.5),
                ),
                child: const Icon(Icons.check, size: 12, color: _white),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _white,
              letterSpacing: 0.4,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Individual Account',
            style: TextStyle(
              fontSize: 13,
              color: _white.withOpacity(0.72),
              letterSpacing: 0.3,
            ),
          ),

          const SizedBox(height: 16),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: _green,
              boxShadow: [
                BoxShadow(
                  color: _green.withOpacity(0.45),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _white,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  'Account Status: ${_accountStatus ?? "Active"}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _white,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick stats row ────────────────────────────────────────────────────────
  Widget _buildQuickStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildStatChip('Individual', 'Account Type',
              Icons.account_balance_outlined),
          const SizedBox(width: 10),
          _buildStatChip('TSL', 'Member', Icons.shield_outlined),
          const SizedBox(width: 10),
          _buildStatChip('Active', 'Status', Icons.verified_outlined),
        ],
      ),
    );
  }

  Widget _buildStatChip(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: _white.withOpacity(0.65),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _teal.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: _teal.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: _teal),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _textDark)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey[600],
                    letterSpacing: 0.4)),
          ],
        ),
      ),
    );
  }

  // ── Section label ──────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: _darkGreen,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(text,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _darkGreen.withOpacity(0.7),
                  letterSpacing: 2.0)),
        ],
      ),
    );
  }

  // ── Info card ──────────────────────────────────────────────────────────────
  Widget _buildInfoCard() {
    final fields = [
      _InfoField(Icons.person_outline_rounded, 'Full Name',
          _userData?['Names'] ?? 'Not provided', _teal),
      _InfoField(Icons.mail_outline_rounded, 'Email Address',
          _userData?['Email'] ?? 'Not provided', _darkGreen),
      _InfoField(Icons.phone_outlined, 'Mobile Number',
          _userData?['Mobile'] ?? 'Not provided', _teal),
      _InfoField(Icons.location_on_outlined, 'Address',
          _userData?['Add_1'] ?? 'Not provided', _darkGreen),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _teal.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: List.generate(fields.length, (i) {
            final f = fields[i];
            return Column(
              children: [
                _buildInfoRow(f, i),
                if (i < fields.length - 1)
                  Divider(
                    height: 1,
                    indent: 72,
                    color: Colors.grey.withOpacity(0.12),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildInfoRow(_InfoField f, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + index * 90),
      curve: Curves.easeOut,
      builder: (ctx, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(18 * (1 - value), 0),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: f.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(f.icon, color: f.color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f.label,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                          letterSpacing: 0.4,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(f.value,
                      style: const TextStyle(
                          fontSize: 15,
                          color: _textDark,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: Colors.grey.withOpacity(0.35)),
          ],
        ),
      ),
    );
  }

  // ── Action buttons ─────────────────────────────────────────────────────────
  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildPrimaryButton('Edit Profile', () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Edit profile coming soon!'),
                backgroundColor: _teal,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            );
          }),
          const SizedBox(height: 12),
          _buildSecondaryButton('Refresh Data', _fetchUserProfile),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
          ),
          boxShadow: [
            BoxShadow(
              color: _green.withOpacity(0.38),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _white,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: _white,
          border: Border.all(color: _teal.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _teal.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.refresh_rounded, size: 18, color: _teal),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _teal,
                    letterSpacing: 0.4)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────── Helpers ─────────────────────────────────────

class _InfoField {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _InfoField(this.icon, this.label, this.value, this.color);
}

class _BlobPainter extends CustomPainter {
  final double pulse;
  _BlobPainter(this.pulse);

  @override
  void paint(Canvas canvas, Size size) {
    void drawBlob(Offset center, double radius, Color color) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color.withOpacity(0.2), Colors.transparent],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius * pulse, paint);
    }

    drawBlob(Offset(size.width * 0.85, size.height * 0.08),
        size.width * 0.5, const Color(0xFF2E7D99));
    drawBlob(Offset(size.width * 0.1, size.height * 0.5),
        size.width * 0.45, const Color(0xFF4CAF50));
    drawBlob(Offset(size.width * 0.6, size.height * 0.9),
        size.width * 0.38, const Color(0xFF2E7D32));
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.pulse != pulse;
}