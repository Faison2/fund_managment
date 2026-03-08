import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../provider/locale_provider.dart';
import '../../provider/theme_provider.dart';

// ── Reuse the same colour tokens as SettingsPage ────────────────────────────
class TSLColors {
  static const darkBg        = Color(0xFF0B1A0C);
  static const darkCard      = Color(0xFF132013);
  static const darkCard2     = Color(0xFF1A2B1B);
  static const darkBorder    = Color(0xFF1E3320);
  static const darkTextPrim  = Color(0xFFE8F5E9);
  static const darkTextSec   = Color(0xFF81A884);
  static const darkTextHint  = Color(0xFF4A7A4D);
  static const darkDivider   = Color(0xFF1E3320);

  static const lightBg       = Color(0xFFB8E6D3);
  static const lightCard     = Color(0xFFFFFFFF);
  static const lightBorder   = Color(0xFFE2ECE2);
  static const lightTextPrim = Color(0xFF1A2E1A);
  static const lightTextSec  = Color(0xFF5A7A5C);
  static const lightTextHint = Color(0xFF9AAA9C);
  static const lightDivider  = Color(0xFFEEEEEE);

  static const green500 = Color(0xFF4ADE80);
  static const green700 = Color(0xFF15803D);
  static const teal     = Color(0xFF2E7D99);
}

// ── Localised strings for ProfileScreen ─────────────────────────────────────
class _PS {
  final String profile, accountInfo, actions,
      fullName, email, mobile, address,
      editProfile, refreshData,
      accountType, member, status,
      individual, active, accountStatus,
      editComingSoon, notProvided;
  const _PS({
    required this.profile,       required this.accountInfo,
    required this.actions,       required this.fullName,
    required this.email,         required this.mobile,
    required this.address,       required this.editProfile,
    required this.refreshData,   required this.accountType,
    required this.member,        required this.status,
    required this.individual,    required this.active,
    required this.accountStatus, required this.editComingSoon,
    required this.notProvided,
  });
}

const _psEn = _PS(
  profile:       'Profile',
  accountInfo:   'Account Information',
  actions:       'Actions',
  fullName:      'Full Name',
  email:         'Email Address',
  mobile:        'Mobile Number',
  address:       'Address',
  editProfile:   'Edit Profile',
  refreshData:   'Refresh Data',
  accountType:   'Account Type',
  member:        'Member',
  status:        'Status',
  individual:    'Individual',
  active:        'Active',
  accountStatus: 'Account Status',
  editComingSoon:'Edit profile coming soon!',
  notProvided:   'Not provided',
);

const _psSw = _PS(
  profile:       'Wasifu',
  accountInfo:   'Taarifa za Akaunti',
  actions:       'Vitendo',
  fullName:      'Jina Kamili',
  email:         'Barua Pepe',
  mobile:        'Nambari ya Simu',
  address:       'Anwani',
  editProfile:   'Hariri Wasifu',
  refreshData:   'Onyesha Upya',
  accountType:   'Aina ya Akaunti',
  member:        'Mwanachama',
  status:        'Hali',
  individual:    'Binafsi',
  active:        'Hai',
  accountStatus: 'Hali ya Akaunti',
  editComingSoon:'Kuhariri wasifu kunakuja hivi karibuni!',
  notProvided:   'Haijatolewa',
);

// ── ProfileScreen ─────────────────────────────────────────────────────────────
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

  // ── Theme helpers (mirrors SettingsPage) ────────────────────────────────
  bool  get _dark  => context.watch<ThemeProvider>().isDark;
  _PS   get _s     => context.watch<LocaleProvider>().isSwahili ? _psSw : _psEn;
  Color get _bg    => _dark ? TSLColors.darkBg       : TSLColors.lightBg;
  Color get _card  => _dark ? TSLColors.darkCard      : TSLColors.lightCard;
  Color get _border=> _dark ? TSLColors.darkBorder    : TSLColors.lightBorder;
  Color get _txtP  => _dark ? TSLColors.darkTextPrim  : TSLColors.lightTextPrim;
  Color get _txtS  => _dark ? TSLColors.darkTextSec   : TSLColors.lightTextSec;
  Color get _txtH  => _dark ? TSLColors.darkTextHint  : TSLColors.lightTextHint;
  Color get _div   => _dark ? TSLColors.darkDivider   : TSLColors.lightDivider;
  Color get _accent=> _dark ? TSLColors.green500      : TSLColors.green700;
  Color get _teal  => TSLColors.teal;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _shimmerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);

    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _pulseAnimation =
        Tween<double>(begin: 0.92, end: 1.08).animate(
            CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

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
      setState(() { _isLoading = true; _errorMessage = ''; });
      _fadeController.reset();

      final prefs        = await SharedPreferences.getInstance();
      final cdsNumber    = prefs.getString('cdsNumber');
      final acctStatus   = prefs.getString('accountStatus');
      setState(() => _accountStatus = acctStatus ?? 'Unknown');

      if (cdsNumber == null || cdsNumber.isEmpty) {
        setState(() {
          _errorMessage = 'Account Number not found. Please login again.';
          _isLoading    = false;
        });
        return;
      }

      final url = Uri.parse(
          'https://portaluat.tsl.co.tz/FMSAPI/Home/UserBasicDetails');
      final response = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'CDSNumber': cdsNumber}));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          setState(() {
            _userData  = Map<String, dynamic>.from(data['data']);
            _isLoading = false;
          });
          _fadeController.forward();
        } else {
          setState(() {
            _errorMessage = data['statusDesc'] ?? 'Failed to load user data';
            _isLoading    = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Network error: ${response.statusCode}';
          _isLoading    = false;
        });
      }
    } catch (e) {
      setState(() { _errorMessage = 'Error: $e'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild whenever theme or locale changes
    context.watch<ThemeProvider>();
    context.watch<LocaleProvider>();

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(children: [
        _buildDecorativeBackground(),
        SafeArea(
          child: _isLoading
              ? _buildLoadingState()
              : _errorMessage.isNotEmpty
              ? _buildErrorState()
              : _buildContent(),
        ),
      ]),
    );
  }

  // ── Decorative blobs (colour-aware) ─────────────────────────────────────
  Widget _buildDecorativeBackground() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (_, __) => CustomPaint(
        painter: _BlobPainter(_pulseAnimation.value, _dark),
        child: const SizedBox.expand(),
      ),
    );
  }

  // ── Shimmer skeleton (theme-aware) ───────────────────────────────────────
  Widget _buildLoadingState() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (_, __) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
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
        ]),
      ),
    );
  }

  Widget _shimmerBox(double w, double h, {double radius = 12}) {
    final t = _shimmerController.value;
    final Color shimA = _dark ? const Color(0xFF1A2E1C) : const Color(0xFFA8D8C2);
    final Color shimB = _dark ? const Color(0xFF243828) : const Color(0xFFD4EFE4);
    return Container(
      width: w, height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment(-1.0 + t * 2, 0),
          end:   Alignment(t * 2, 0),
          colors: [shimA, shimB, shimA],
        ),
      ),
    );
  }

  // ── Error state (theme-aware) ────────────────────────────────────────────
  Widget _buildErrorState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _card.withOpacity(0.65),
            border: Border.all(color: Colors.red.withOpacity(0.3), width: 2),
            boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.1),
                blurRadius: 20, spreadRadius: 4)],
          ),
          child: const Icon(Icons.error_outline_rounded,
              size: 56, color: Colors.redAccent),
        ),
        const SizedBox(height: 24),
        Text('Something went wrong',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                color: _accent)),
        const SizedBox(height: 12),
        Text(_errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.red, height: 1.6)),
        const SizedBox(height: 32),
        _primaryButton('Try Again', _fetchUserProfile),
      ]),
    ),
  );

  // ── Main content ─────────────────────────────────────────────────────────
  Widget _buildContent() {
    final s = _s;
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(children: [
          _buildHeroHeader(s),
          const SizedBox(height: 12),
          _buildQuickStats(s),
          const SizedBox(height: 28),
          _sectionLabel(s.accountInfo),
          const SizedBox(height: 12),
          _buildInfoCard(s),
          const SizedBox(height: 28),
          _sectionLabel(s.actions),
          const SizedBox(height: 12),
          _buildActions(s),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  // ── Hero header ──────────────────────────────────────────────────────────
  Widget _buildHeroHeader(_PS s) {
    final name     = _userData?['Names'] ?? 'Account Holder';
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').take(2).map((w) => w[0]).join().toUpperCase()
        : '??';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: _dark
            ? const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0x4A2E7D99), Color(0x3A1A5F77)])
            : const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0x662E7D99), Color(0x661A5F77)]),
        border: Border.all(color: _teal.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: _teal.withOpacity(0.35),
            blurRadius: 30, offset: const Offset(0, 12))],
      ),
      child: Column(children: [
        // Avatar
        Stack(alignment: Alignment.bottomRight, children: [
          Container(
            width: 96, height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.15),
              border: Border.all(color: Colors.white.withOpacity(0.4), width: 3),
              boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.12),
                  blurRadius: 20, spreadRadius: 4)],
            ),
            child: Center(child: Text(initials,
                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold,
                    color: Colors.white, letterSpacing: 2))),
          ),
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(shape: BoxShape.circle,
                color: const Color(0xFF4CAF50),
                border: Border.all(color: _teal, width: 2.5)),
            child: const Icon(Icons.check, size: 12, color: Colors.white),
          ),
        ]),

        const SizedBox(height: 16),
        Text(name, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
                color: Colors.white, letterSpacing: 0.4)),
        const SizedBox(height: 4),
        Text('${s.individual} • ${s.member}',
            style: TextStyle(fontSize: 13,
                color: Colors.white.withOpacity(0.72), letterSpacing: 0.3)),
        const SizedBox(height: 16),

        // Status badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: const Color(0xFF4CAF50),
            boxShadow: [BoxShadow(color: const Color(0xFF4CAF50).withOpacity(0.45),
                blurRadius: 14, offset: const Offset(0, 5))],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 7, height: 7,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Colors.white)),
            const SizedBox(width: 7),
            Text('${s.accountStatus}: ${_accountStatus ?? s.active}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: Colors.white, letterSpacing: 0.4)),
          ]),
        ),
      ]),
    );
  }

  // ── Quick stats ──────────────────────────────────────────────────────────
  Widget _buildQuickStats(_PS s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: [
        _statChip(s.individual, s.accountType, Icons.account_balance_outlined),
        const SizedBox(width: 10),
        _statChip('TSL',        s.member,      Icons.shield_outlined),
        const SizedBox(width: 10),
        _statChip(s.active,     s.status,      Icons.verified_outlined),
      ]),
    );
  }

  Widget _statChip(String value, String label, IconData icon) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: _card.withOpacity(_dark ? 0.55 : 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _teal.withOpacity(0.15)),
        boxShadow: [BoxShadow(color: _teal.withOpacity(0.08),
            blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        Icon(icon, size: 20, color: _teal),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 12,
            fontWeight: FontWeight.bold, color: _txtP)),
        const SizedBox(height: 2),
        Text(label, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 9, color: _txtH, letterSpacing: 0.4)),
      ]),
    ),
  );

  // ── Section label ────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(children: [
      Container(width: 3, height: 14,
          decoration: BoxDecoration(color: _accent,
              borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(text.toUpperCase(),
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
              color: _txtH, letterSpacing: 2.0)),
    ]),
  );

  // ── Info card ────────────────────────────────────────────────────────────
  Widget _buildInfoCard(_PS s) {
    final fields = [
      _InfoField(Icons.person_outline_rounded, s.fullName,
          _userData?['Names']  ?? s.notProvided, _teal),
      _InfoField(Icons.mail_outline_rounded,   s.email,
          _userData?['Email']  ?? s.notProvided, _accent),
      _InfoField(Icons.phone_outlined,          s.mobile,
          _userData?['Mobile'] ?? s.notProvided, _teal),
      _InfoField(Icons.location_on_outlined,    s.address,
          _userData?['Add_1']  ?? s.notProvided, _accent),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _border),
          boxShadow: [BoxShadow(color: _teal.withOpacity(_dark ? 0.06 : 0.12),
              blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Column(
          children: List.generate(fields.length, (i) => Column(children: [
            _infoRow(fields[i], i),
            if (i < fields.length - 1)
              Divider(height: 1, indent: 72, color: _div),
          ])),
        ),
      ),
    );
  }

  Widget _infoRow(_InfoField f, int index) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Duration(milliseconds: 350 + index * 90),
    curve: Curves.easeOut,
    builder: (_, val, child) => Opacity(opacity: val,
        child: Transform.translate(offset: Offset(18 * (1 - val), 0),
            child: child)),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: f.color.withOpacity(_dark ? 0.12 : 0.10),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(f.icon, color: f.color, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(f.label,
                  style: TextStyle(fontSize: 11, color: _txtH,
                      letterSpacing: 0.4, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(f.value,
                  style: TextStyle(fontSize: 15, color: _txtP,
                      fontWeight: FontWeight.w600)),
            ])),
        Icon(Icons.chevron_right_rounded,
            size: 18, color: _txtS.withOpacity(0.4)),
      ]),
    ),
  );

  // ── Action buttons ───────────────────────────────────────────────────────
  Widget _buildActions(_PS s) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(children: [
      _primaryButton(s.editProfile, () =>
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(s.editComingSoon),
            backgroundColor: _teal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ))),
      const SizedBox(height: 12),
      _secondaryButton(s.refreshData, _fetchUserProfile),
    ]),
  );

  Widget _primaryButton(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity, height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
            colors: _dark
                ? [const Color(0xFF4ADE80), const Color(0xFF16A34A)]
                : [const Color(0xFF4CAF50), const Color(0xFF388E3C)]),
        boxShadow: [BoxShadow(color: _accent.withOpacity(0.38),
            blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Center(child: Text(label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
              color: Colors.white, letterSpacing: 0.6))),
    ),
  );

  Widget _secondaryButton(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity, height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: _card,
        border: Border.all(color: _teal.withOpacity(0.4), width: 1.5),
        boxShadow: [BoxShadow(color: _teal.withOpacity(0.08),
            blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.refresh_rounded, size: 18, color: _teal),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
            color: _teal, letterSpacing: 0.4)),
      ]),
    ),
  );
}

// ── Helpers ───────────────────────────────────────────────────────────────────
class _InfoField {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    color;
  const _InfoField(this.icon, this.label, this.value, this.color);
}

class _BlobPainter extends CustomPainter {
  final double pulse;
  final bool   dark;
  _BlobPainter(this.pulse, this.dark);

  @override
  void paint(Canvas canvas, Size size) {
    void blob(Offset c, double r, Color col) {
      final opacity = dark ? 0.12 : 0.20;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [col.withOpacity(opacity), Colors.transparent],
        ).createShader(Rect.fromCircle(center: c, radius: r));
      canvas.drawCircle(c, r * pulse, paint);
    }
    blob(Offset(size.width * 0.85, size.height * 0.08),
        size.width * 0.5, const Color(0xFF2E7D99));
    blob(Offset(size.width * 0.1, size.height * 0.5),
        size.width * 0.45, const Color(0xFF4CAF50));
    blob(Offset(size.width * 0.6, size.height * 0.9),
        size.width * 0.38, const Color(0xFF2E7D32));
  }

  @override
  bool shouldRepaint(_BlobPainter old) =>
      old.pulse != pulse || old.dark != dark;
}