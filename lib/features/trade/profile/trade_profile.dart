// profile_page.dart
// Trade account profile page — user details fetched from TSL API.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../trade/trade_shared.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────

class _UserDetails {
  final String names;
  final String email;
  final String mobile;
  final String address;
  final String bank;
  final String accountNo;
  final String accountName;
  final String branch;

  const _UserDetails({
    required this.names,
    required this.email,
    required this.mobile,
    required this.address,
    required this.bank,
    required this.accountNo,
    required this.accountName,
    required this.branch,
  });

  factory _UserDetails.fromJson(Map<String, dynamic> json) {
    return _UserDetails(
      names:       json['Names']       ?? '',
      email:       json['Email']       ?? '',
      mobile:      json['Mobile']      ?? '',
      address:     json['Add_1']       ?? '',
      bank:        json['Bank']        ?? '',
      accountNo:   json['AccountNo']   ?? '',
      accountName: json['AccountName'] ?? '',
      branch:      json['Branch']      ?? '',
    );
  }

  /// Display-ready full name (title case).
  String get displayName {
    if (names.trim().isEmpty) return 'TSL Investor';
    return names
        .toLowerCase()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  /// Two-letter initials from display name.
  String get initials {
    final parts = displayName
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'TI';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────────────────────────────────────

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  // ── Animation ──────────────────────────────────────────────────────────────
  late AnimationController _anim;
  late Animation<double> _fade;

  // ── API state ──────────────────────────────────────────────────────────────
  _UserDetails? _user;
  String _cdsNumber = '';
  bool _loading = true;
  String? _error;
  bool _shimmerTick = false; // used to loop shimmer

  // ── Preferences ────────────────────────────────────────────────────────────
  bool _notificationsOn = true;
  bool _biometricsOn    = false;
  bool _priceAlertsOn   = true;

  static const _apiUrl =
      'https://portaluat.tsl.co.tz/FMSAPI/Home/UserBasicDetails';

  // ─────────────────────────────── LIFECYCLE ────────────────────────────────
  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _fetchUserDetails();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  // ─────────────────────────────── API CALL ─────────────────────────────────
  Future<void> _fetchUserDetails() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error   = null;
    });

    try {
      // 1. Read CDS from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final cds   = prefs.getString('cdsNumber') ?? '';

      if (cds.isEmpty) {
        if (!mounted) return;
        setState(() {
          _error   = 'CDS number not found. Please log in again.';
          _loading = false;
        });
        return;
      }
      _cdsNumber = cds;

      // 2. POST to API
      final response = await http
          .post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept':       'application/json',
        },
        body: jsonEncode({'CDSNumber': cds}),
      )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      // 3. Parse response
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['status'] == 'success' && body['data'] != null) {
          setState(() {
            _user    = _UserDetails.fromJson(body['data'] as Map<String, dynamic>);
            _loading = false;
          });
        } else {
          setState(() {
            _error   = body['statusDesc']?.toString() ?? 'Failed to load profile.';
            _loading = false;
          });
        }
      } else {
        setState(() {
          _error   = 'Server error (${response.statusCode}). Please try again.';
          _loading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error   = 'Network error. Please check your connection.';
        _loading = false;
      });
    }
  }

  // ─────────────────────────────── BUILD ────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TradeColors.bg,
      body: FadeTransition(
        opacity: _fade,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── App bar ──────────────────────────────────────────────────
            SliverAppBar(
              backgroundColor: TradeColors.bg,
              pinned: true,
              elevation: 0,
              leading: IconButton(
                icon: _iconBtn(Icons.arrow_back_ios_new_rounded,
                    TradeColors.txtPrim),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('Profile',
                  style: TextStyle(
                      color: TradeColors.txtPrim,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              actions: [
                IconButton(
                  icon: _loading
                      ? _spinnerBtn()
                      : _iconBtn(Icons.refresh_rounded, TradeColors.teal),
                  onPressed: _loading ? null : _fetchUserDetails,
                ),
                const SizedBox(width: 8),
              ],
            ),

            // ── Body ─────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _loading
                  ? _buildSkeleton()
                  : _error != null
                  ? _buildErrorState()
                  : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Icon button helper ─────────────────────────────────────────────────────
  Widget _iconBtn(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: TradeColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TradeColors.border),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }

  Widget _spinnerBtn() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: TradeColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TradeColors.border),
      ),
      child: const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
            strokeWidth: 2, color: TradeColors.teal),
      ),
    );
  }

  // ─────────────────────────────── SUCCESS ──────────────────────────────────
  Widget _buildContent() {
    final u = _user!;
    return Column(
      children: [
        const SizedBox(height: 8),
        _buildAvatarCard(u),
        const SizedBox(height: 20),
        _buildStatsRow(),
        const SizedBox(height: 20),
        const TradeSectionHeader(
            title: 'Account Details',
            icon: Icons.account_circle_outlined),
        _buildAccountCard(u),
        const SizedBox(height: 20),
        const TradeSectionHeader(
            title: 'Bank Details',
            icon: Icons.account_balance_outlined),
        _buildBankCard(u),
        const SizedBox(height: 20),

      ],
    );
  }

  // ── Avatar card ────────────────────────────────────────────────────────────
  Widget _buildAvatarCard(_UserDetails u) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D3D5C), Color(0xFF061820)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: TradeColors.teal.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
                color: TradeColors.teal.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            // ── Initials avatar ──────────────────────────────────────────
            Stack(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                        colors: [TradeColors.teal, Color(0xFF0080FF)]),
                    boxShadow: [
                      BoxShadow(
                          color: TradeColors.teal.withOpacity(0.3),
                          blurRadius: 14,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Center(
                    child: Text(u.initials,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1)),
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: TradeColors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF0D3D5C), width: 2),
                    ),
                    child: const Icon(Icons.check,
                        size: 10, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),

            // ── Info ─────────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(u.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: TradeColors.txtPrim,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(u.email.isNotEmpty ? u.email : '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: TradeColors.txtSec, fontSize: 12)),
                  const SizedBox(height: 10),
                  // CDS chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: TradeColors.teal.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: TradeColors.teal.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.badge_outlined,
                            size: 11, color: TradeColors.teal),
                        const SizedBox(width: 5),
                        Text(_cdsNumber,
                            style: const TextStyle(
                                color: TradeColors.teal,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
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

  // ── Stats row ──────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    final stats = [
      {'label': 'Total Trades', 'value': '142',    'color': TradeColors.teal},
      {'label': 'Win Rate',     'value': '68%',    'color': TradeColors.green},
      {'label': 'Avg Return',   'value': '+12.4%', 'color': TradeColors.gold},
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: stats.asMap().entries.map((e) {
          final item  = e.value;
          final color = item['color'] as Color;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: e.key < 2 ? 10 : 0),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Text(item['value'] as String,
                      style: TextStyle(
                          color: color,
                          fontSize: 18,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(item['label'] as String,
                      style: const TextStyle(
                          color: TradeColors.txtSec, fontSize: 10),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Account details ────────────────────────────────────────────────────────
  Widget _buildAccountCard(_UserDetails u) {
    return _infoCard([
      {'icon': Icons.badge_outlined,           'label': 'User Acc No',   'value': _cdsNumber},
      {'icon': Icons.account_balance_outlined, 'label': 'Account Type', 'value': 'Individual Retail'},
      {'icon': Icons.verified_outlined,        'label': 'KYC Status',   'value': 'Verified ✓'},
      {'icon': Icons.phone_outlined,           'label': 'Mobile',       'value': u.mobile.isNotEmpty   ? u.mobile  : '—'},
      {'icon': Icons.location_on_outlined,     'label': 'Address',      'value': u.address.isNotEmpty  ? u.address : '—'},
    ]);
  }

  // ── Bank details ───────────────────────────────────────────────────────────
  Widget _buildBankCard(_UserDetails u) {
    return _infoCard([
      {'icon': Icons.account_balance_rounded,      'label': 'Bank',         'value': u.bank.isNotEmpty        ? u.bank        : '—'},
      {'icon': Icons.credit_card_rounded,          'label': 'Bank Acc No.',  'value': u.accountNo.isNotEmpty   ? u.accountNo   : '—'},
      {'icon': Icons.person_outline_rounded,       'label': 'Account Name', 'value': u.accountName.isNotEmpty ? u.accountName : '—'},
      {'icon': Icons.store_mall_directory_outlined,'label': 'Branch',       'value': u.branch.isNotEmpty      ? u.branch      : '—'},
    ]);
  }

  // ── Generic info card ──────────────────────────────────────────────────────
  Widget _infoCard(List<Map<String, Object>> rows) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: TradeColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: TradeColors.border),
        ),
        child: Column(
          children: rows.asMap().entries.map((e) {
            final row  = e.value;
            final last = e.key == rows.length - 1;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(row['icon'] as IconData,
                          size: 18, color: TradeColors.teal),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(row['label'] as String,
                            style: const TextStyle(
                                color: TradeColors.txtSec,
                                fontSize: 13)),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(row['value'] as String,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: TradeColors.txtPrim,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                if (!last)
                  Divider(
                      height: 1,
                      color: Colors.white.withOpacity(0.05),
                      indent: 16,
                      endIndent: 16),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }


  Widget _prefToggle(IconData icon, String label, bool value,
      ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: TradeColors.teal),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: TradeColors.txtPrim, fontSize: 13)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: TradeColors.teal,
            activeTrackColor: TradeColors.teal.withOpacity(0.25),
            inactiveThumbColor: TradeColors.txtSec,
            inactiveTrackColor: TradeColors.txtSec.withOpacity(0.15),
          ),
        ],
      ),
    );
  }


  // ─────────────────────────────── SKELETON ─────────────────────────────────
  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _skelBox(height: 138, radius: 22),
          const SizedBox(height: 20),
          // Stats row skeleton
          Row(
            children: List.generate(3, (i) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < 2 ? 10 : 0),
                  height: 72,
                  decoration: BoxDecoration(
                    color: TradeColors.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: _shimmer(),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          _skelBox(height: 230, radius: 18),
          const SizedBox(height: 20),
          _skelBox(height: 175, radius: 18),
          const SizedBox(height: 20),
          _skelBox(height: 145, radius: 18),
        ],
      ),
    );
  }

  Widget _skelBox({required double height, required double radius}) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: TradeColors.surface,
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.hardEdge,
      child: _shimmer(),
    );
  }

  /// Looping shimmer via TweenAnimationBuilder.
  Widget _shimmer() {
    return TweenAnimationBuilder<double>(
      key: ValueKey(_shimmerTick),
      tween: Tween(begin: -1.5, end: 1.5),
      duration: const Duration(milliseconds: 1000),
      onEnd: () {
        if (mounted) setState(() => _shimmerTick = !_shimmerTick);
      },
      builder: (_, v, __) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                (v - 0.4).clamp(0.0, 1.0),
                v.clamp(0.0, 1.0),
                (v + 0.4).clamp(0.0, 1.0),
              ],
              colors: [
                Colors.white.withOpacity(0.03),
                Colors.white.withOpacity(0.10),
                Colors.white.withOpacity(0.03),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────── ERROR ────────────────────────────────────
  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: TradeColors.red.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(
                  color: TradeColors.red.withOpacity(0.2)),
            ),
            child: Icon(Icons.wifi_off_rounded,
                size: 48,
                color: TradeColors.red.withOpacity(0.7)),
          ),
          const SizedBox(height: 20),
          const Text('Could not load profile',
              style: TextStyle(
                  color: TradeColors.txtPrim,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(_error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: TradeColors.txtSec,
                  fontSize: 13,
                  height: 1.5)),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: _fetchUserDetails,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [TradeColors.teal, Color(0xFF0080FF)]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: TradeColors.teal.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.refresh_rounded,
                      color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Try Again',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}