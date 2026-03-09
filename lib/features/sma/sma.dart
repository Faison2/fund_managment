import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../provider/locale_provider.dart';
import '../../../../provider/theme_provider.dart';

// ── Localised strings ─────────────────────────────────────────────────────────
class _SS {
  final String title, subtitle, totalPortfolio, cashBalance,
      investments, viewAll, viewLess, loading, errorRetry,
      noInvestments, amount, date, txnId, invested, currency,
      performance, summaryHeader, activeInvestments;
  const _SS({
    required this.title,            required this.subtitle,
    required this.totalPortfolio,   required this.cashBalance,
    required this.investments,      required this.viewAll,
    required this.viewLess,         required this.loading,
    required this.errorRetry,       required this.noInvestments,
    required this.amount,           required this.date,
    required this.txnId,            required this.invested,
    required this.currency,         required this.performance,
    required this.summaryHeader,    required this.activeInvestments,
  });
}

const _ssEn = _SS(
  title:             'SMA Dashboard',
  subtitle:          'Separately Managed Account',
  totalPortfolio:    'Total Portfolio Value',
  cashBalance:       'Cash Balance',
  investments:       'Investments',
  viewAll:           'View All',
  viewLess:          'View Less',
  loading:           'Loading SMA data…',
  errorRetry:        'Retry',
  noInvestments:     'No investments found',
  amount:            'Amount',
  date:              'Date',
  txnId:             'Txn ID',
  invested:          'Invested',
  currency:          'TZS',
  performance:       'Portfolio Performance',
  summaryHeader:     'Account Summary',
  activeInvestments: 'Active Investments',
);

const _ssSw = _SS(
  title:             'Dashibodi ya SMA',
  subtitle:          'Akaunti Inayosimamiwa Kando',
  totalPortfolio:    'Jumla ya Thamani ya Mkoba',
  cashBalance:       'Salio la Fedha',
  investments:       'Uwekezaji',
  viewAll:           'Ona Zote',
  viewLess:          'Ona Kidogo',
  loading:           'Inapakia data ya SMA…',
  errorRetry:        'Jaribu Tena',
  noInvestments:     'Hakuna uwekezaji uliopatikana',
  amount:            'Kiasi',
  date:              'Tarehe',
  txnId:             'Nambari ya Muamala',
  invested:          'Kilichowekwa',
  currency:          'TZS',
  performance:       'Utendaji wa Mkoba',
  summaryHeader:     'Muhtasari wa Akaunti',
  activeInvestments: 'Uwekezaji Unaoendelea',
);

// ── SMA data models ───────────────────────────────────────────────────────────
class _SMAData {
  final String cdsNumber;
  final double cashBal;
  final double totalPortfolioValue;
  final List<_SMAInvestment> investments;
  const _SMAData({
    required this.cdsNumber,
    required this.cashBal,
    required this.totalPortfolioValue,
    required this.investments,
  });
}

class _SMAInvestment {
  final String description;
  final DateTime date;
  final String txnId;
  final double amount;
  const _SMAInvestment({
    required this.description,
    required this.date,
    required this.txnId,
    required this.amount,
  });
}

// ── SMA Page ──────────────────────────────────────────────────────────────────
class SMAPage extends StatefulWidget {
  const SMAPage({Key? key}) : super(key: key);

  @override
  State<SMAPage> createState() => _SMAPageState();
}

class _SMAPageState extends State<SMAPage> with SingleTickerProviderStateMixin {
  _SMAData? _data;
  bool   _loading  = true;
  String? _error;
  bool   _showAll  = false;
  String _cdsNumber = '';

  late AnimationController _entryCtrl;
  late Animation<double>   _entryFade;
  late Animation<Offset>   _entrySlide;

  bool get _dark => context.watch<ThemeProvider>().isDark;
  _SS  get _s    => context.watch<LocaleProvider>().isSwahili ? _ssSw : _ssEn;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _entryFade  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(
        begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
    _load();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      _cdsNumber  = prefs.getString('cdsNumber') ?? 'FC00318';

      final response = await http.post(
        Uri.parse('https://portaluat.tsl.co.tz/FMSAPI/home/GetSMAInvestments'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'APIUsername': 'User2',
          'APIPassword': 'CBZ1234#2',
          'cdsNumber':   _cdsNumber,
        }),
      ).timeout(const Duration(seconds: 15));

      final json = jsonDecode(response.body);
      if (response.statusCode == 200 && json['status'] == 'success') {
        final d = json['data'] as Map<String, dynamic>;
        final List<dynamic> rawInv = (d['smaInvestments'] as List<dynamic>?) ?? [];
        final investments = rawInv.map((j) {
          DateTime dt;
          try { dt = DateTime.parse(j['TrxnDate'] as String); }
          catch (_) { dt = DateTime.now(); }
          return _SMAInvestment(
            description: j['Description'] as String? ?? '',
            date:        dt,
            txnId:       j['TrxnID']?.toString() ?? '',
            amount:      (j['Amount'] as num?)?.toDouble() ?? 0.0,
          );
        }).toList();

        setState(() {
          _data = _SMAData(
            cdsNumber:          d['cdsNumber'] as String? ?? _cdsNumber,
            cashBal:            (d['cashBal']             as num?)?.toDouble() ?? 0.0,
            totalPortfolioValue:(d['totalPortfolioValue'] as num?)?.toDouble() ?? 0.0,
            investments:        investments,
          );
          _loading = false;
        });
        _entryCtrl.forward();
      } else {
        setState(() {
          _error   = json['statusDesc'] ?? 'Failed to load';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() { _error = 'Connection error. Please try again.'; _loading = false; });
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _fmt(double v, {int decimals = 2}) {
    final parts = v.toStringAsFixed(decimals).split('.');
    final int = parts[0].replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
    return decimals > 0 ? '$int.${parts[1]}' : int;
  }

  String _shortAmt(double v) {
    if (v.abs() >= 1e9) return '${(v / 1e9).toStringAsFixed(2)}B';
    if (v.abs() >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v.abs() >= 1e3) return '${(v / 1e3).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  /// Parse bank name from description e.g. "AZANIA @ 15.00% P.A" → "AZANIA"
  String _bankName(String desc) {
    final parts = desc.trim().split(RegExp(r'\s+@|\s+%|\s+P\.A'));
    return parts.first.trim();
  }

  /// Parse rate from description e.g. "AZANIA @ 15.00% P.A" → "15.00%"
  String _rate(String desc) {
    final match = RegExp(r'(\d+\.\d+)%').firstMatch(desc);
    return match != null ? '${match.group(1)}%' : '';
  }

  /// Parse maturity date if present e.g. "May 18, 2026" → "18 May 2026"
  String? _maturity(String desc) {
    // Look for pattern like "May 18, 2026" or "February 16, 2026"
    final match = RegExp(
      r'(January|February|March|April|May|June|July|August|September|October|November|December)\s+(\d{1,2}),?\s+(\d{4})',
    ).firstMatch(desc);
    if (match == null) return null;
    try {
      final dt = DateFormat('MMMM d, yyyy')
          .parse('${match.group(1)} ${match.group(2)}, ${match.group(3)}');
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) { return null; }
  }

  Color _bankColor(String bank) {
    final b = bank.toLowerCase();
    if (b.contains('azania')) return const Color(0xFF1565C0);
    if (b.contains('exim'))   return const Color(0xFF6A1B9A);
    if (b.contains('crdb'))   return const Color(0xFFC62828);
    if (b.contains('nmb'))    return const Color(0xFF2E7D32);
    if (b.contains('stb'))    return const Color(0xFFE65100);
    return const Color(0xFF37474F);
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    context.watch<LocaleProvider>();

    final dark   = _dark;
    final s      = _s;
    final bg     = dark ? const Color(0xFF0B1A0C) : const Color(0xFFB8E6D3);
    final sheet  = dark ? const Color(0xFF0F1A10) : Colors.white;
    final border = dark ? const Color(0xFF1E3320) : const Color(0xFFE5E7EB);
    final txtP   = dark ? const Color(0xFFE8F5E9) : Colors.black87;
    final txtS   = dark ? const Color(0xFF81A884)  : Colors.black54;
    final txtH   = dark ? const Color(0xFF4A7A4D)  : Colors.grey.shade400;
    final green  = dark ? const Color(0xFF4ADE80)  : const Color(0xFF15803D);

    return Scaffold(
      backgroundColor: bg,
      body: Column(children: [

        // ── Gradient header ──────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            gradient: dark
                ? const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF0B1A0C), Color(0xFF132013), Color(0xFF09100A)])
                : const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)]),
          ),
          child: SafeArea(bottom: false, child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(children: [
              // back + title row
              Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.title, style: const TextStyle(
                      color: Colors.white, fontSize: 22,
                      fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  Text(s.subtitle, style: TextStyle(
                      color: Colors.white.withOpacity(0.65), fontSize: 12)),
                ])),
                GestureDetector(
                  onTap: () { HapticFeedback.lightImpact(); _load(); },
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.refresh_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ]),

              // ── Summary cards (only when loaded) ────────────────────────
              if (!_loading && _data != null) ...[
                const SizedBox(height: 24),
                Row(children: [
                  _headerStatCard(
                    label: s.totalPortfolio,
                    value: 'TZS ${_shortAmt(_data!.totalPortfolioValue)}',
                    fullValue: _fmt(_data!.totalPortfolioValue),
                    icon: Icons.account_balance_outlined,
                    accent: const Color(0xFF69F0AE),
                  ),
                  const SizedBox(width: 12),
                  _headerStatCard(
                    label: s.cashBalance,
                    value: 'TZS ${_shortAmt(_data!.cashBal)}',
                    fullValue: _fmt(_data!.cashBal),
                    icon: Icons.account_balance_wallet_outlined,
                    accent: _data!.cashBal >= 0
                        ? const Color(0xFF69F0AE)
                        : const Color(0xFFFF8A80),
                    negative: _data!.cashBal < 0,
                  ),
                ]),
                const SizedBox(height: 12),
                _investmentCountBanner(dark, s),
              ],
            ]),
          )),
        ),

        // ── Body ─────────────────────────────────────────────────────────────
        Expanded(
          child: Container(
            color: sheet,
            child: _loading
                ? _buildLoading(green, txtS, s)
                : _error != null
                ? _buildError(dark, green, txtP, txtS, s)
                : _buildContent(dark, txtP, txtS, txtH, green, border, s),
          ),
        ),
      ]),
    );
  }

  // ── Header stat card ───────────────────────────────────────────────────────
  Widget _headerStatCard({
    required String label,
    required String value,
    required String fullValue,
    required IconData icon,
    required Color accent,
    bool negative = false,
  }) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: accent.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: accent, size: 14),
              ),
              if (negative) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFF8A80).withOpacity(0.18),
                      borderRadius: BorderRadius.circular(6)),
                  child: const Text('–', style: TextStyle(
                      fontSize: 9, color: Color(0xFFFF8A80),
                      fontWeight: FontWeight.w800)),
                ),
              ],
            ]),
            const SizedBox(height: 10),
            Text(label, style: TextStyle(
                fontSize: 10, color: Colors.white.withOpacity(0.55),
                fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w900,
                color: negative ? const Color(0xFFFF8A80) : Colors.white,
                letterSpacing: -0.5),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(fullValue, style: TextStyle(
                fontSize: 9, color: Colors.white.withOpacity(0.4)),
                overflow: TextOverflow.ellipsis),
          ]),
        ),
      );

  // ── Investment count banner ────────────────────────────────────────────────
  Widget _investmentCountBanner(bool dark, _SS s) {
    final count = _data?.investments.length ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(children: [
        const Icon(Icons.bar_chart_rounded, color: Colors.white70, size: 16),
        const SizedBox(width: 10),
        Text('$count ${s.activeInvestments}',
            style: const TextStyle(fontSize: 13,
                color: Colors.white, fontWeight: FontWeight.w700)),
        const Spacer(),
        if (_data != null) ...[
          // Largest investment highlight
          Text('Largest: TZS ${_shortAmt(_data!.investments.isEmpty ? 0 :
          _data!.investments.map((i) => i.amount).reduce((a, b) => a > b ? a : b))}',
              style: const TextStyle(fontSize: 11, color: Colors.white60)),
        ],
      ]),
    );
  }

  // ── Loading ────────────────────────────────────────────────────────────────
  Widget _buildLoading(Color green, Color txtS, _SS s) =>
      Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        CircularProgressIndicator(color: green, strokeWidth: 2.5),
        const SizedBox(height: 16),
        Text(s.loading, style: TextStyle(fontSize: 14, color: txtS)),
      ]));

  // ── Error ──────────────────────────────────────────────────────────────────
  Widget _buildError(bool dark, Color green, Color txtP, Color txtS, _SS s) =>
      Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.hourglass_empty,
                color: Colors.grey, size: 36),
          ),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: txtS, height: 1.5)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _load,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [green, green.withOpacity(0.75)]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(
                    color: green.withOpacity(0.3),
                    blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Text(s.errorRetry, style: const TextStyle(
                  color: Colors.white, fontSize: 14,
                  fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ));

  // ── Main content ───────────────────────────────────────────────────────────
  Widget _buildContent(
      bool dark, Color txtP, Color txtS, Color txtH, Color green, Color border, _SS s,
      ) {
    final data = _data!;
    final allInv = data.investments;
    final shown  = _showAll ? allInv : allInv.take(4).toList();

    return FadeTransition(
      opacity: _entryFade,
      child: SlideTransition(
        position: _entrySlide,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Portfolio breakdown bar ──────────────────────────────────────
            if (allInv.isNotEmpty)
              _buildPortfolioBreakdownBar(
                  dark, txtP, txtS, txtH, green, border, allInv, s),

            const SizedBox(height: 28),

            // ── Investments section label ────────────────────────────────────
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.activeInvestments.toUpperCase(), style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w800,
                    color: txtH, letterSpacing: 1.2)),
                const SizedBox(height: 2),
                Text('${allInv.length} ${s.investments.toLowerCase()}',
                    style: TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w600, color: txtP)),
              ]),
              Text('TZS ${_fmt(allInv.fold(0.0, (s, i) => s + i.amount))}',
                  style: TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w700, color: green)),
            ]),

            const SizedBox(height: 14),

            // ── Investment cards ─────────────────────────────────────────────
            ...shown.asMap().entries.map((e) =>
                _buildInvestmentCard(e.key, e.value, dark, txtP, txtS, txtH,
                    border, allInv.length, s)),

            // ── View All / Less toggle ───────────────────────────────────────
            if (allInv.length > 4) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _showAll = !_showAll);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: green.withOpacity(dark ? 0.12 : 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: green.withOpacity(0.25)),
                  ),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(
                      _showAll
                          ? s.viewLess
                          : '${s.viewAll} (${allInv.length - 4} more)',
                      style: TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w700, color: green),
                    ),
                    const SizedBox(width: 6),
                    AnimatedRotation(
                      turns: _showAll ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(Icons.keyboard_arrow_down_rounded,
                          color: green, size: 18),
                    ),
                  ]),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  // ── Portfolio breakdown bar ───────────────────────────────────────────────
  Widget _buildPortfolioBreakdownBar(
      bool dark, Color txtP, Color txtS, Color txtH, Color green, Color border,
      List<_SMAInvestment> investments, _SS s,
      ) {
    // Group by bank
    final Map<String, double> byBank = {};
    for (final inv in investments) {
      final b = _bankName(inv.description);
      byBank[b] = (byBank[b] ?? 0) + inv.amount;
    }
    final total = byBank.values.fold(0.0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF132013) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(s.performance, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w800, color: txtP)),
        const SizedBox(height: 16),

        // Segmented bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Row(
            children: byBank.entries.map((e) {
              final pct = total > 0 ? e.value / total : 0.0;
              return Flexible(
                flex: (pct * 1000).round(),
                child: Container(
                  height: 14,
                  color: _bankColor(e.key),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        // Legend
        Wrap(
          spacing: 12, runSpacing: 10,
          children: byBank.entries.map((e) {
            final pct = total > 0 ? (e.value / total * 100) : 0.0;
            return Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 10, height: 10,
                  decoration: BoxDecoration(
                      color: _bankColor(e.key),
                      borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 6),
              Text('${e.key} ${pct.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 11,
                      fontWeight: FontWeight.w600, color: txtS)),
            ]);
          }).toList(),
        ),
      ]),
    );
  }

  // ── Single investment card ────────────────────────────────────────────────
  Widget _buildInvestmentCard(
      int index, _SMAInvestment inv,
      bool dark, Color txtP, Color txtS, Color txtH, Color border,
      int total, _SS s,
      ) {
    final bank     = _bankName(inv.description);
    final rate     = _rate(inv.description);
    final maturity = _maturity(inv.description);
    final bankColor = _bankColor(bank);
    final cardBg    = dark ? const Color(0xFF132013) : Colors.white;
    final subtleBg  = dark
        ? bankColor.withOpacity(0.12) : bankColor.withOpacity(0.07);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + index * 60),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(
          opacity: v,
          child: Transform.translate(
              offset: Offset(0, 16 * (1 - v)), child: child)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(dark ? 0.15 : 0.04),
              blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(children: [
          // ── Card header ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: subtleBg,
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: bankColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(
                      color: bankColor.withOpacity(0.35),
                      blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Center(
                  child: Text(
                    bank.isNotEmpty ? bank[0] : '?',
                    style: const TextStyle(fontSize: 18,
                        fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(bank, style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800, color: txtP)),
                if (rate.isNotEmpty)
                  Row(children: [
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: bankColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: bankColor.withOpacity(0.3)),
                      ),
                      child: Text(rate, style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: bankColor)),
                    ),
                    if (maturity != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        margin: const EdgeInsets.only(top: 3),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.event_outlined,
                              size: 9, color: Colors.orange.shade600),
                          const SizedBox(width: 3),
                          Text(maturity, style: TextStyle(
                              fontSize: 9, fontWeight: FontWeight.w600,
                              color: Colors.orange.shade700)),
                        ]),
                      ),
                    ],
                  ]),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('TZS', style: TextStyle(
                    fontSize: 9, color: txtH, fontWeight: FontWeight.w500)),
                Text(_shortAmt(inv.amount), style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900,
                    color: bankColor, letterSpacing: -0.5)),
              ]),
            ]),
          ),

          // ── Card footer ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(children: [
              _metaChip(Icons.calendar_today_outlined,
                  DateFormat('dd MMM yyyy').format(inv.date), txtS, dark),
              const SizedBox(width: 10),
              _metaChip(Icons.tag_outlined,
                  '#${inv.txnId}', txtS, dark),
              const Spacer(),
              Text(_fmt(inv.amount),
                  style: TextStyle(fontSize: 11, color: txtS,
                      fontStyle: FontStyle.italic)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _metaChip(IconData icon, String label, Color txtS, bool dark) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: dark
              ? Colors.white.withOpacity(0.06)
              : Colors.grey.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 11, color: txtS),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w500, color: txtS)),
        ]),
      );
}