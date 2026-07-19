import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:provider/provider.dart';
import 'package:tsl/constants/constants.dart';

import '../../provider/locale_provider.dart';
import '../../provider/theme_provider.dart';
import 'minor_profile.dart';

// ── TSL Brand colours ──────────────────────────────────────────────────────
class _TSL {
  static const Color blue  = Color(0xFF329AD6);
  static const Color teal  = Color(0xFF00A79D);
  static const Color grey  = Color(0xFF939598);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF231F20);
}

// ════════════════════════════════════════════════════════════════════════
// MODEL — maps POST /FMSAPI/MinorAccounts/GetLinkedMinors response
// ════════════════════════════════════════════════════════════════════════
class LinkedMinorAccount {
  final String cdsNumber;
  final String brokerCode;
  final String accountType; // raw API code, e.g. "M"
  final String surname;
  final String middlename;
  final String forenames;
  final String initials;
  final String title;
  final String idNoPP;
  final String idType;
  final String nationality;
  final String dob; // "YYYY-MM-DD"
  final String gender;
  final String address;
  final String guardianIdentification;
  final String gMaritalStatus;
  final String gEmail;
  final String gTitle;

  const LinkedMinorAccount({
    required this.cdsNumber,
    required this.brokerCode,
    required this.accountType,
    required this.surname,
    required this.middlename,
    required this.forenames,
    required this.initials,
    required this.title,
    required this.idNoPP,
    required this.idType,
    required this.nationality,
    required this.dob,
    required this.gender,
    required this.address,
    required this.guardianIdentification,
    required this.gMaritalStatus,
    required this.gEmail,
    required this.gTitle,
  });

  factory LinkedMinorAccount.fromJson(Map<String, dynamic> j) {
    return LinkedMinorAccount(
      cdsNumber:  j['cdsNumber']  as String? ?? '',
      brokerCode: j['brokerCode'] as String? ?? '',
      accountType: j['accountType'] as String? ?? '',
      surname:    j['surname']    as String? ?? '',
      middlename: j['middlename'] as String? ?? '',
      forenames:  j['forenames']  as String? ?? '',
      initials:   j['initials']   as String? ?? '',
      title:      j['title']      as String? ?? '',
      idNoPP:     j['idNoPP']     as String? ?? '',
      idType:     j['idType']     as String? ?? '',
      nationality: j['nationality'] as String? ?? '',
      dob:        j['dob']        as String? ?? '',
      gender:     j['gender']     as String? ?? '',
      address:    j['add_1']      as String? ?? '',
      guardianIdentification: j['guardianIdentification'] as String? ?? '',
      gMaritalStatus: j['gMaritalStatus'] as String? ?? '',
      gEmail:     j['gEmail']     as String? ?? '',
      gTitle:     j['gTitle']     as String? ?? '',
    );
  }

  /// Nicely formatted "Forenames Middlename Surname"
  String get fullName {
    final parts = [forenames, middlename, surname]
        .where((s) => s.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'Minor';
    return parts
        .map((p) => p
        .toLowerCase()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' '))
        .join(' ');
  }

  /// Human readable label for the account-type badge shown on the dashboard.
  String get accountTypeLabel {
    switch (accountType.toUpperCase()) {
      case 'M':
        return 'Minor Account';
      default:
        return accountType.isEmpty ? 'Minor Account' : accountType;
    }
  }

  /// dd/mm/yyyy for display; falls back to the raw string if unparsable.
  String get formattedDob {
    try {
      final parsed = DateTime.parse(dob);
      return '${parsed.day.toString().padLeft(2, '0')}/'
          '${parsed.month.toString().padLeft(2, '0')}/'
          '${parsed.year}';
    } catch (_) {
      return dob;
    }
  }
}

// ── Portfolio data (replace with a real model once a fund/portfolio ───────
// endpoint for minor accounts exists — GetLinkedMinors only returns the
// minor's personal/guardian details, not fund holdings).
class MinorFundSummary {
  final String fundCode;      // e.g. "101"
  final String fundName;      // e.g. "IMARA FUND"
  final String fundType;      // e.g. "LIQUID FUND"
  final bool active;
  final double? totalPortfolio; // null => "Not invested yet"

  const MinorFundSummary({
    required this.fundCode,
    required this.fundName,
    required this.fundType,
    this.active = true,
    this.totalPortfolio,
  });
}

class MinorTransaction {
  final String title;
  final String subtitle;
  final double amount;
  final DateTime date;
  final bool isCredit;

  const MinorTransaction({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    this.isCredit = true,
  });
}

// ════════════════════════════════════════════════════════════════════════
// REPOSITORY — same HttpClient/IOClient pattern as LoginRepository
// ════════════════════════════════════════════════════════════════════════
class MinorAccountsRepository {
  Future<Map<String, dynamic>> getLinkedMinors({
    required String cdsNumber,
  }) async {
    try {
      final requestBody = {
        'APIUsername': apiUsername,
        'APIPassword': apiPassword,
        // TODO: hardcoded for testing against UAT — swap back to `cdsNumber`
        // (the real, logged-in guardian's CDS number) before release.
        'cdsNumber': 'FC00000000956',
      };

      final ioClient = HttpClient()
        ..badCertificateCallback = (cert, host, port) => true;
      final client = IOClient(ioClient);

      final response = await client.post(
        Uri.parse(
            'https://portaluat.tsl.co.tz/FMSAPI/MinorAccounts/GetLinkedMinors'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      client.close();

      if (response.statusCode == 200) {
        final responseData =
        json.decode(response.body) as Map<String, dynamic>;

        if (responseData['status'] == 'success') {
          final rawList = responseData['data'] as List<dynamic>? ?? [];
          final minors = rawList
              .map((e) =>
              LinkedMinorAccount.fromJson(e as Map<String, dynamic>))
              .toList();

          return {
            'success': true,
            'minors': minors,
          };
        }

        return {
          'success': false,
          'message': responseData['statusDesc'] ?? 'Unknown error',
        };
      } else {
        return {
          'success': false,
          'message': 'Server error (${response.statusCode})',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }
}

// ════════════════════════════════════════════════════════════════════════
// PICKER — shown only when a guardian has more than one linked minor
// ════════════════════════════════════════════════════════════════════════
class SelectMinorAccountScreen extends StatelessWidget {
  final List<LinkedMinorAccount> minors;
  final String guardianName;

  const SelectMinorAccountScreen({
    Key? key,
    required this.minors,
    required this.guardianName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dark = context.watch<ThemeProvider>().isDark;
    final sw   = context.watch<LocaleProvider>().isSwahili;

    final bg      = dark ? _TSL.black : const Color(0xFFEAF6F1);
    final cardBg  = dark ? const Color(0xFF1B2321) : _TSL.white;
    final txtPrim = dark ? _TSL.white : _TSL.black;
    final txtSec  = dark ? _TSL.white.withOpacity(0.6) : _TSL.grey;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Row(
              children: [
                InkWell(
                  onTap: () => Navigator.maybePop(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        size: 20, color: txtPrim),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  sw ? 'Chagua Akaunti ya Mtoto' : 'Select Minor Account',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: txtPrim,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Text(
                sw
                    ? 'Una akaunti zaidi ya moja za watoto zilizounganishwa'
                    : 'You have more than one linked minor account',
                style: TextStyle(fontSize: 13, color: txtSec),
              ),
            ),
            const SizedBox(height: 20),
            ...minors.map((m) => _minorTile(
              context,
              minor: m,
              cardBg: cardBg,
              txtPrim: txtPrim,
              txtSec: txtSec,
              sw: sw,
            )),
          ],
        ),
      ),
    );
  }

  Widget _minorTile(
      BuildContext context, {
        required LinkedMinorAccount minor,
        required Color cardBg,
        required Color txtPrim,
        required Color txtSec,
        required bool sw,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _TSL.grey.withOpacity(0.15)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => MinorDashboardScreen(
                  minor: minor,
                  guardianName: guardianName,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_TSL.teal, _TSL.blue],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      minor.fullName.isNotEmpty
                          ? minor.fullName[0].toUpperCase()
                          : 'M',
                      style: const TextStyle(
                        color: _TSL.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        minor.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: txtPrim,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${sw ? "Tarehe ya kuzaliwa" : "DOB"}: '
                            '${minor.formattedDob}  •  CDS: ${minor.cdsNumber}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: txtSec),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: txtSec.withOpacity(0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// DASHBOARD
// ════════════════════════════════════════════════════════════════════════
class MinorDashboardScreen extends StatefulWidget {
  final LinkedMinorAccount minor;
  final String guardianName;
  final MinorFundSummary? fund;
  final List<MinorTransaction> transactions;

  const MinorDashboardScreen({
    Key? key,
    required this.minor,
    required this.guardianName,
    this.fund,
    this.transactions = const [],
  }) : super(key: key);

  @override
  State<MinorDashboardScreen> createState() => _MinorDashboardScreenState();
}

class _MinorDashboardScreenState extends State<MinorDashboardScreen> {
  bool _balanceHidden = false;

  bool get _dark => context.watch<ThemeProvider>().isDark;
  bool get _sw   => context.watch<LocaleProvider>().isSwahili;

  Color get _scaffoldBg => _dark ? _TSL.black : const Color(0xFFEAF6F1);
  Color get _txtPrim     => _dark ? _TSL.white : _TSL.black;
  Color get _txtSec      => _dark ? _TSL.white.withOpacity(0.6) : _TSL.grey;
  Color get _cardBg      => _dark ? const Color(0xFF1B2321) : _TSL.white;

  String _fmt(double v) => v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    context.watch<LocaleProvider>();

    return Scaffold(
      backgroundColor: _scaffoldBg,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _dark
                  ? [_TSL.black, _TSL.black]
                  : [
                const Color(0xFFDCF2E7),
                const Color(0xFFEFF6E9),
                const Color(0xFFFBF3E3),
              ],
            ),
          ),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              _buildTopBar(),
              const SizedBox(height: 22),
              _buildGuardianStrip(),
              const SizedBox(height: 18),
              _buildFundCard(),
              const SizedBox(height: 20),
              _buildQuickActions(),
              const SizedBox(height: 26),
              _buildTransactionsHeader(),
              const SizedBox(height: 14),
              _buildTransactionsPanel(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top bar: back / minor name / avatar ────────────────────────────────
  Widget _buildTopBar() {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.maybePop(context),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Icon(Icons.arrow_back_ios_new_rounded,
                size: 20, color: _txtPrim),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            widget.minor.fullName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _txtPrim,
            ),
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(21),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MinorProfileScreen(
                  minor: widget.minor,
                  guardianName: widget.guardianName,
                ),
              ),
            );
          },
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _cardBg,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _TSL.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(Icons.person, color: _txtPrim, size: 22),
          ),
        ),
      ],
    );
  }

  // ── Guardian + account-type badge + minor's DOB/CDS detail row ────────
  Widget _buildGuardianStrip() {
    final m = widget.minor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _dark
              ? _TSL.white.withOpacity(0.08)
              : _TSL.grey.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _TSL.teal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.family_restroom_rounded,
                    color: _TSL.teal, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _sw ? 'Dashibodi ya Mtoto' : 'Minor Dashboard',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: _txtSec,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _sw
                          ? 'Msimamizi: ${widget.guardianName}'
                          : 'Guardian: ${widget.guardianName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: _txtPrim,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _TSL.blue.withOpacity(_dark ? 0.18 : 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  m.accountTypeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _TSL.blue,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: _dark
                ? _TSL.white.withOpacity(0.08)
                : _TSL.grey.withOpacity(0.15),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _detailChip(
                  icon: Icons.cake_outlined,
                  label: _sw ? 'Tarehe ya Kuzaliwa' : 'Date of Birth',
                  value: m.formattedDob,
                ),
              ),
              Expanded(
                child: _detailChip(
                  icon: Icons.badge_outlined,
                  label: 'CDS ${_sw ? "Namba" : "Number"}',
                  value: m.cdsNumber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 15, color: _txtSec),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 10, color: _txtSec),
              ),
              Text(
                value.isEmpty ? '—' : value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _txtPrim,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Fund summary card ──────────────────────────────────────────────────
  // Single "Total Portfolio" figure — no Subscribe action, since minor
  // accounts only support Invest / Redeem / Transactions.
  Widget _buildFundCard() {
    final f = widget.fund;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_TSL.teal, _TSL.blue],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _TSL.teal.withOpacity(0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _TSL.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  f?.fundCode ?? '—',
                  style: TextStyle(
                    color: _TSL.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
              const Spacer(),
              if (f?.active ?? false)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _TSL.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: Color(0xFFB9F6CA), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        _sw ? 'Hai' : 'Active',
                        style: const TextStyle(
                          color: Color(0xFFB9F6CA),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => setState(() => _balanceHidden = !_balanceHidden),
                borderRadius: BorderRadius.circular(20),
                child: Icon(
                  _balanceHidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: _TSL.white.withOpacity(0.85),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            f?.fundName ?? (_sw ? 'Hakuna Mfuko' : 'No Fund Linked'),
            style: TextStyle(
              color: _TSL.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            f?.fundType ?? '',
            style: TextStyle(
              color: _TSL.white.withOpacity(0.75),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            _sw ? 'Jumla ya Mfuko' : 'Total Portfolio',
            style: TextStyle(
              color: _TSL.white.withOpacity(0.72),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _balanceHidden
                ? '••••••'
                : (f?.totalPortfolio == null
                ? (_sw ? 'Bado hujawekeza' : 'Not invested yet')
                : _fmt(f!.totalPortfolio!)),
            style: TextStyle(
              color: _TSL.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              fontStyle: f?.totalPortfolio == null
                  ? FontStyle.italic
                  : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick actions grid ─────────────────────────────────────────────────
  // Minor accounts only support Invest / Redeem / Transactions.
  Widget _buildQuickActions() {
    final items = [
      (Icons.wallet_outlined, _sw ? 'Wekeza' : 'Invest'),
      (Icons.trending_down_rounded, _sw ? 'Toa' : 'Redeem'),
      (Icons.swap_horiz_rounded, _sw ? 'Miamala' : 'Transactions'),
    ];
    return Row(
      children: items
          .map((it) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: _quickActionTile(it.$1, it.$2),
        ),
      ))
          .toList(),
    );
  }

  Widget _quickActionTile(IconData icon, String label) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // TODO: route to the respective minor-account flow,
          // passing widget.minor.cdsNumber as the sub-account identifier
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _dark
                  ? _TSL.white.withOpacity(0.07)
                  : _TSL.grey.withOpacity(0.15),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _TSL.teal.withOpacity(_dark ? 0.16 : 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: _TSL.teal, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: _txtPrim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Transactions header ────────────────────────────────────────────────
  Widget _buildTransactionsHeader() {
    return Row(
      children: [
        Text(
          _sw ? 'Miamala ya Karibuni' : 'Recent Transactions',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: _txtPrim,
          ),
        ),
        const Spacer(),
        if (widget.transactions.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _TSL.teal,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _sw ? 'Zote' : 'See All',
                  style: TextStyle(
                    color: _TSL.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded,
                    color: _TSL.white, size: 16),
              ],
            ),
          ),
      ],
    );
  }

  // ── Transactions panel (empty state matches screenshot) ────────────────
  Widget _buildTransactionsPanel() {
    if (widget.transactions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _dark
                ? _TSL.white.withOpacity(0.07)
                : _TSL.grey.withOpacity(0.15),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _TSL.teal.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.show_chart_rounded,
                      color: _TSL.teal, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  _sw ? 'Mwenendo wa Mfuko' : 'Portfolio Flow',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _txtPrim,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Icon(Icons.show_chart_rounded,
                size: 40, color: _txtSec.withOpacity(0.4)),
            const SizedBox(height: 14),
            Text(
              _sw ? 'Hakuna miamala bado' : 'No transactions yet',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: _txtSec,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: widget.transactions
          .map((t) => _transactionTile(t))
          .toList(growable: false),
    );
  }

  Widget _transactionTile(MinorTransaction t) {
    final color = t.isCredit ? _TSL.teal : const Color(0xFFEF4444);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _dark
              ? _TSL.white.withOpacity(0.07)
              : _TSL.grey.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              t.isCredit
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.title,
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: _txtPrim),
                ),
                const SizedBox(height: 2),
                Text(
                  t.subtitle,
                  style: TextStyle(fontSize: 12, color: _txtSec),
                ),
              ],
            ),
          ),
          Text(
            '${t.isCredit ? '+' : '-'}${_fmt(t.amount)}',
            style: TextStyle(fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}