import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/constants.dart';
import '../market_watch/market_watch.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TSL BRAND PALETTE
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  static const Color blue      = Color(0xFF329AD6);
  static const Color teal      = Color(0xFF00A79D);
  static const Color grey      = Color(0xFF939598);
  static const Color white     = Color(0xFFFFFFFF);
  static const Color black     = Color(0xFF231F20);
  static const Color lightGrey = Color(0xFFF5F6F7);
  static const Color errorRed  = Color(0xFFD32F2F);

  static const Color bg        = Color(0xFFF0F8FA);
  static const Color surface   = Color(0xFFFFFFFF);
  static const Color border    = Color(0xFFB8DDE8);

  static const Color green     = Color(0xFF34C759);
  static const Color greenLt   = Color(0xFFEBFBF2);
  static const Color red       = Color(0xFFFF6B8A);
  static const Color redLt     = Color(0xFFFFEEF2);
  static const Color gold      = Color(0xFFF5A623);
  static const Color goldLt    = Color(0xFFFFF8EC);

  static const Color tealLt    = Color(0xFFE0F5F4);
  static const Color blueLt    = Color(0xFFE6F3FB);

  static const Color txtPrim   = Color(0xFF0D2B2A);
  static const Color txtSec    = Color(0xFF4A8080);
  static const Color txtHint   = Color(0xFF93BFC0);

  static const List<Color> heroGrad = [Color(0xFF00A79D), Color(0xFF1A7BAF), Color(0xFF329AD6)];
  static const List<Color> fabGrad  = [Color(0xFF00A79D), Color(0xFF1A7BAF)];
  static const List<Color> buyGrad  = [Color(0xFF34C759), Color(0xFF1E8E3E)];
  static const List<Color> sellGrad = [Color(0xFFFF8AA8), Color(0xFFFF6B8A)];
}


// ─────────────────────────────────────────────────────────────────────────────
// USER MODEL
// ─────────────────────────────────────────────────────────────────────────────

class DrawerUserDetails {
  final String names;
  final String email;
  final String mobile;
  final String cdsNumber;

  const DrawerUserDetails({
    required this.names,
    required this.email,
    required this.mobile,
    required this.cdsNumber,
  });

  factory DrawerUserDetails.fromJson(Map<String, dynamic> json, String cds) {
    return DrawerUserDetails(
      names:     json['Names']  ?? '',
      email:     json['Email']  ?? '',
      mobile:    json['Mobile'] ?? '',
      cdsNumber: cds,
    );
  }

  String get displayName {
    if (names.trim().isEmpty) return 'TSL Investor';
    return names
        .toLowerCase()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  String get initials {
    final parts = displayName.trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();
    if (parts.isEmpty)     return 'TI';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TRADE DRAWER
// ─────────────────────────────────────────────────────────────────────────────

class TradeDrawer extends StatefulWidget {
  final VoidCallback onSwitchToFms;
  const TradeDrawer({Key? key, required this.onSwitchToFms}) : super(key: key);

  @override
  State<TradeDrawer> createState() => _TradeDrawerState();
}

class _TradeDrawerState extends State<TradeDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _headerAnim;
  late Animation<double>   _headerFade;
  late Animation<Offset>   _headerSlide;

  DrawerUserDetails? _user;
  bool   _loadingUser = true;
  bool   _shimmerTick = false;

  static final _apiUrl = '$cSharpApi/UserBasicDetails';

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _headerFade  = CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(
        begin: const Offset(0, -0.15), end: Offset.zero)
        .animate(CurvedAnimation(
        parent: _headerAnim, curve: Curves.easeOut));

    _fetchUser();
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    super.dispose();
  }

  Future<void> _fetchUser() async {
    if (!mounted) return;
    setState(() => _loadingUser = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final cds   = prefs.getString('cdsNumber') ?? '';
      if (cds.isEmpty) {
        if (mounted) setState(() => _loadingUser = false);
        return;
      }

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept':       'application/json',
        },
        body: jsonEncode({'CDSNumber': cds}),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['status'] == 'success' && body['data'] != null) {
          setState(() {
            _user        = DrawerUserDetails.fromJson(
                body['data'] as Map<String, dynamic>, cds);
            _loadingUser = false;
          });
          return;
        }
      }
      if (mounted) setState(() => _loadingUser = false);
    } catch (_) {
      if (mounted) setState(() => _loadingUser = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: _C.surface,
      width: MediaQuery.of(context).size.width * 0.80,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight:    Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildEnvToggle(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              physics: const BouncingScrollPhysics(),
              children: [
                _sectionLabel('TRADE NAVIGATION'),
                const SizedBox(height: 4),
                _item(
                  icon:  Icons.pie_chart_rounded,
                  label: 'Portfolio',
                  color: _C.teal,
                  delay: 0,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          _buildSwitchToFms(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return SlideTransition(
      position: _headerSlide,
      child: FadeTransition(
        opacity: _headerFade,
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end:   Alignment.bottomRight,
              colors: _C.heroGrad,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft:  Radius.circular(5),
              bottomRight: Radius.circular(5),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: _loadingUser
                  ? _buildHeaderSkeleton()
                  : _buildHeaderContent(),
            ),
          ),
        ),
      ),
    );
  }

  // ── Shimmer ────────────────────────────────────────────────────────────────
  Widget _shimmer() {
    return TweenAnimationBuilder<double>(
      key: ValueKey(_shimmerTick),
      tween: Tween(begin: -1.5, end: 1.5),
      duration: const Duration(milliseconds: 900),
      onEnd: () {
        if (mounted) setState(() => _shimmerTick = !_shimmerTick);
      },
      builder: (_, v, __) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end:   Alignment.centerRight,
            stops: [
              (v - 0.4).clamp(0.0, 1.0),
              v.clamp(0.0, 1.0),
              (v + 0.4).clamp(0.0, 1.0),
            ],
            colors: [
              Colors.white.withOpacity(0.04),
              Colors.white.withOpacity(0.14),
              Colors.white.withOpacity(0.04),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSkeleton() {
    Widget skelBox(double w, double h, {double r = 6, bool circle = false}) =>
        Container(
          width: w, height: h,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: circle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: circle ? null : BorderRadius.circular(r),
          ),
          clipBehavior: Clip.hardEdge,
          child: _shimmer(),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        skelBox(64, 64, circle: true),
        const SizedBox(height: 14),
        skelBox(150, 18),
        const SizedBox(height: 8),
        skelBox(110, 12),
        const SizedBox(height: 12),
        skelBox(130, 28, r: 20),
      ],
    );
  }

  Widget _buildHeaderContent() {
    final initials    = _user?.initials    ?? 'TI';
    final displayName = _user?.displayName ?? 'TSL Investor';
    final email       = _user?.email       ?? '';
    final cds         = _user?.cdsNumber   ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.28),
                    Colors.white.withOpacity(0.10),
                  ],
                  begin: Alignment.topLeft,
                  end:   Alignment.bottomRight,
                ),
                border: Border.all(
                    color: Colors.white.withOpacity(0.5), width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5),
                ),
              ),
            ),
            Positioned(
              bottom: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                  border: Border.all(color: _C.teal, width: 2),
                ),
                child: const Icon(Icons.check, size: 10, color: Colors.white),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        Text(
          displayName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2),
        ),

        const SizedBox(height: 4),

        Text(
          email.isNotEmpty ? email : 'Trade Account',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500),
        ),

        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: Colors.white.withOpacity(0.25), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.badge_outlined, size: 11, color: Colors.white70),
              const SizedBox(width: 5),
              Text(
                cds.isNotEmpty ? cds : 'No CDS',
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Environment toggle ─────────────────────────────────────────────────────
  Widget _buildEnvToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 3, height: 12,
                  decoration: BoxDecoration(
                    color: _C.gold,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 7),
                Text('ENVIRONMENT',
                    style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: _C.txtSec,
                        letterSpacing: 1.8)),
              ],
            ),
          ),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: _C.bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _C.border),
            ),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: FractionallySizedBox(
                    widthFactor: 0.5,
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: _C.fabGrad),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: _C.teal.withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          widget.onSwitchToFms();
                        },
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.account_balance_outlined,
                                  size: 14, color: _C.txtSec),
                              const SizedBox(width: 5),
                              Text('FMS',
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: _C.txtSec,
                                      letterSpacing: 0.3)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.candlestick_chart_outlined,
                                size: 14, color: Colors.white),
                            SizedBox(width: 5),
                            Text('Trade',
                                style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.3)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section label ──────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          Container(
            width: 3, height: 12,
            decoration: BoxDecoration(
              color: _C.teal,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 7),
          Text(text,
              style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: _C.txtSec,
                  letterSpacing: 1.8)),
        ],
      ),
    );
  }

  // ── Nav item ───────────────────────────────────────────────────────────────
  Widget _item({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + delay),
      curve: Curves.easeOut,
      builder: (ctx, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
            offset: Offset(-20 * (1 - value), 0), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            splashColor:    color.withOpacity(0.1),
            highlightColor: color.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 13),
              child: Row(
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(label,
                        style: const TextStyle(
                            color: _C.txtPrim,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            letterSpacing: 0.1)),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      size: 16, color: _C.txtHint),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Switch to FMS ──────────────────────────────────────────────────────────
  Widget _buildSwitchToFms() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          widget.onSwitchToFms();
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFD6EFF8), Color(0xFFDDF4F2)],
              begin: Alignment.topLeft,
              end:   Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: _C.teal.withOpacity(0.25), width: 1),
            boxShadow: [
              BoxShadow(
                color: _C.teal.withOpacity(0.10),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: _C.fabGrad),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: _C.teal.withOpacity(0.30),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.account_balance_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Switch to FMS',
                          style: TextStyle(
                              color: _C.txtPrim,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                      const SizedBox(height: 2),
                      Text('Fund Management System',
                          style: TextStyle(
                              color: _C.txtSec, fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _C.tealLt,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.swap_horiz_rounded,
                      size: 16, color: _C.teal),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}