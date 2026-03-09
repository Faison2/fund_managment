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
      performance, summaryHeader, activeInvestments,
      cashTransactions, tabInvestments, tabCash, creditTxn, debitTxn,
      totalCredits, totalDebits, netFlow;
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
    required this.cashTransactions, required this.tabInvestments,
    required this.tabCash,          required this.creditTxn,
    required this.debitTxn,         required this.totalCredits,
    required this.totalDebits,      required this.netFlow,
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
  cashTransactions:  'Cash Transactions',
  tabInvestments:    'Investments',
  tabCash:           'Cash',
  creditTxn:         'Credit',
  debitTxn:          'Debit',
  totalCredits:      'Total Credits',
  totalDebits:       'Total Debits',
  netFlow:           'Net Flow',
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
  cashTransactions:  'Miamala ya Fedha',
  tabInvestments:    'Uwekezaji',
  tabCash:           'Fedha',
  creditTxn:         'Ingizo',
  debitTxn:          'Toa',
  totalCredits:      'Jumla ya Ingizo',
  totalDebits:       'Jumla ya Kutoa',
  netFlow:           'Mtiririko Halisi',
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

// ── Cash transaction models ───────────────────────────────────────────────────
class _CashData {
  final String cdsNumber;
  final double cashBalance;
  final List<_CashTxn> transactions;
  const _CashData({
    required this.cdsNumber,
    required this.cashBalance,
    required this.transactions,
  });
}

class _CashTxn {
  final String description;
  final DateTime date;
  final String txnId;
  final double amount;
  bool get isCredit => amount >= 0;
  const _CashTxn({
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

class _SMAPageState extends State<SMAPage>
    with SingleTickerProviderStateMixin {
  _SMAData? _data;
  _CashData? _cashData;

  bool   _loading    = true;
  String? _error;
  bool   _showAll    = false;
  bool   _showAllCash = false;
  String _cdsNumber  = '';
  int    _tabIndex   = 0; // 0 = Investments, 1 = Cash

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

      // ── Fire both requests in parallel ────────────────────────────────────
      final results = await Future.wait([
        http.post(
          Uri.parse('https://portaluat.tsl.co.tz/FMSAPI/home/GetSMAInvestments'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'APIUsername': 'User2',
            'APIPassword': 'CBZ1234#2',
            'cdsNumber':   _cdsNumber,
          }),
        ).timeout(const Duration(seconds: 15)),
        http.post(
          Uri.parse('https://portaluat.tsl.co.tz/FMSAPI/home/GetSMACashTransactions'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'APIUsername': 'User2',
            'APIPassword': 'CBZ1234#2',
            'cdsNumber':   _cdsNumber,
          }),
        ).timeout(const Duration(seconds: 15)),
      ]);

      final invResp  = results[0];
      final cashResp = results[1];

      // ── Parse investments ─────────────────────────────────────────────────
      _SMAData? parsedInv;
      if (invResp.statusCode == 200) {
        final j = jsonDecode(invResp.body);
        if (j['status'] == 'success') {
          final d = j['data'] as Map<String, dynamic>;
          final rawInv = (d['smaInvestments'] as List<dynamic>?) ?? [];
          parsedInv = _SMAData(
            cdsNumber:           d['cdsNumber'] as String? ?? _cdsNumber,
            cashBal:             (d['cashBal']             as num?)?.toDouble() ?? 0.0,
            totalPortfolioValue: (d['totalPortfolioValue'] as num?)?.toDouble() ?? 0.0,
            investments: rawInv.map((item) {
              DateTime dt;
              try { dt = DateTime.parse(item['TrxnDate'] as String); }
              catch (_) { dt = DateTime.now(); }
              return _SMAInvestment(
                description: item['Description'] as String? ?? '',
                date:        dt,
                txnId:       item['TrxnID']?.toString() ?? '',
                amount:      (item['Amount'] as num?)?.toDouble() ?? 0.0,
              );
            }).toList(),
          );
        }
      }

      // ── Parse cash transactions ───────────────────────────────────────────
      _CashData? parsedCash;
      if (cashResp.statusCode == 200) {
        final j = jsonDecode(cashResp.body);
        if (j['status'] == 'success') {
          final d = j['data'] as Map<String, dynamic>;
          final rawTxns = (d['smaInvestments'] as List<dynamic>?) ?? [];
          parsedCash = _CashData(
            cdsNumber:   d['cdsNumber'] as String? ?? _cdsNumber,
            cashBalance: (d['CashBalance'] as num?)?.toDouble() ?? 0.0,
            transactions: rawTxns.map((item) {
              DateTime dt;
              try { dt = DateTime.parse(item['TrxnDate'] as String); }
              catch (_) { dt = DateTime.now(); }
              return _CashTxn(
                description: item['Description'] as String? ?? '',
                date:        dt,
                txnId:       item['TrxnID']?.toString() ?? '',
                amount:      (item['Amount'] as num?)?.toDouble() ?? 0.0,
              );
            }).toList(),
          );
        }
      }

      if (parsedInv == null && parsedCash == null) {
        setState(() { _error = 'Failed to load data'; _loading = false; });
        return;
      }

      setState(() {
        _data     = parsedInv;
        _cashData = parsedCash;
        _loading  = false;
      });
      _entryCtrl.forward(from: 0);
    } catch (e) {
      setState(() { _error = 'Connection error. Please try again.'; _loading = false; });
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _fmt(double v, {int decimals = 2}) {
    final parts = v.abs().toStringAsFixed(decimals).split('.');
    final intPart = parts[0].replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
    final formatted = decimals > 0 ? '$intPart.${parts[1]}' : intPart;
    return v < 0 ? '-$formatted' : formatted;
  }

  String _shortAmt(double v) {
    final abs = v.abs();
    String s;
    if (abs >= 1e9)      s = '${(abs / 1e9).toStringAsFixed(2)}B';
    else if (abs >= 1e6) s = '${(abs / 1e6).toStringAsFixed(1)}M';
    else if (abs >= 1e3) s = '${(abs / 1e3).toStringAsFixed(0)}K';
    else                 s = abs.toStringAsFixed(0);
    return v < 0 ? '-$s' : s;
  }

  String _bankName(String desc) {
    final parts = desc.trim().split(RegExp(r'\s+@|\s+%|\s+P\.A'));
    return parts.first.trim();
  }

  String _rate(String desc) {
    final match = RegExp(r'(\d+\.\d+)%').firstMatch(desc);
    return match != null ? '${match.group(1)}%' : '';
  }

  String? _maturity(String desc) {
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

  /// Pick icon + colour for cash transaction description
  _TxnMeta _txnMeta(String desc, bool isCredit) {
    final d = desc.toLowerCase();
    if (d.contains('deposit'))            return _TxnMeta(Icons.arrow_downward_rounded, const Color(0xFF00897B));
    if (d.contains('redemption in'))      return _TxnMeta(Icons.swap_horiz_rounded,     const Color(0xFF1E88E5));
    if (d.contains('redemption out'))     return _TxnMeta(Icons.swap_horiz_rounded,     const Color(0xFFE53935));
    if (d.contains('redemption'))         return _TxnMeta(Icons.currency_exchange,       const Color(0xFF8E24AA));
    if (d.contains('invest') || d.contains('fdr')) return _TxnMeta(Icons.trending_up_rounded, const Color(0xFF43A047));
    if (d.contains('call deposit'))       return _TxnMeta(Icons.savings_outlined,        const Color(0xFFFB8C00));
    if (d.contains('withdraw'))           return _TxnMeta(Icons.arrow_upward_rounded,    const Color(0xFFE53935));
    if (d.contains('interest'))           return _TxnMeta(Icons.percent_rounded,         const Color(0xFF00ACC1));
    return isCredit
        ? _TxnMeta(Icons.add_circle_outline, const Color(0xFF43A047))
        : _TxnMeta(Icons.remove_circle_outline, const Color(0xFFE53935));
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
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
              if (!_loading && (_data != null || _cashData != null)) ...[
                const SizedBox(height: 20),
                Row(children: [
                  _headerStatCard(
                    label: s.totalPortfolio,
                    value: 'TZS ${_shortAmt(_data?.totalPortfolioValue ?? 0)}',
                    fullValue: _fmt(_data?.totalPortfolioValue ?? 0),
                    icon: Icons.account_balance_outlined,
                    accent: const Color(0xFF69F0AE),
                  ),
                  const SizedBox(width: 12),
                  _headerStatCard(
                    label: s.cashBalance,
                    value: 'TZS ${_shortAmt(_cashData?.cashBalance ?? _data?.cashBal ?? 0)}',
                    fullValue: _fmt(_cashData?.cashBalance ?? _data?.cashBal ?? 0),
                    icon: Icons.account_balance_wallet_outlined,
                    accent: (_cashData?.cashBalance ?? _data?.cashBal ?? 0) >= 0
                        ? const Color(0xFF69F0AE)
                        : const Color(0xFFFF8A80),
                    negative: (_cashData?.cashBalance ?? _data?.cashBal ?? 0) < 0,
                  ),
                ]),
                const SizedBox(height: 12),
                _investmentCountBanner(dark, s),
                const SizedBox(height: 16),
                // ── Tab switcher ──────────────────────────────────────────
                _buildTabSwitcher(s),
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
                : _tabIndex == 0
                ? _buildInvestmentsContent(dark, txtP, txtS, txtH, green, border, s)
                : _buildCashContent(dark, txtP, txtS, txtH, green, border, s),
          ),
        ),
      ]),
    );
  }

  // ── Tab Switcher ───────────────────────────────────────────────────────────
  Widget _buildTabSwitcher(_SS s) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(children: [
        _tabBtn(1, Icons.trending_up_rounded, s.tabInvestments),
        _tabBtn(0, Icons.swap_horiz_rounded,  s.tabCash),
      ]),
    );
  }

  Widget _tabBtn(int idx, IconData icon, String label) {
    final selected = _tabIndex == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _tabIndex = idx);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(1),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon,
                size: 14,
                color: selected ? const Color(0xFF1B5E20) : Colors.white70),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: selected ? const Color(0xFF1B5E20) : Colors.white70)),
          ]),
        ),
      ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
        if (_data != null && _data!.investments.isNotEmpty)
          Text('Largest: TZS ${_shortAmt(_data!.investments.map((i) => i.amount).reduce((a, b) => a > b ? a : b))}',
              style: const TextStyle(fontSize: 11, color: Colors.white60)),
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

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 0 — INVESTMENTS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildInvestmentsContent(
      bool dark, Color txtP, Color txtS, Color txtH,
      Color green, Color border, _SS s,
      ) {
    if (_data == null) {
      return Center(child: Text(s.noInvestments,
          style: TextStyle(fontSize: 14, color: txtS)));
    }
    final allInv = _data!.investments;
    final shown  = _showAll ? allInv : allInv.take(4).toList();

    return FadeTransition(
      opacity: _entryFade,
      child: SlideTransition(
        position: _entrySlide,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            if (allInv.isNotEmpty)
              _buildPortfolioBreakdownBar(
                  dark, txtP, txtS, txtH, green, border, allInv, s),

            const SizedBox(height: 28),

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

            ...shown.asMap().entries.map((e) =>
                _buildInvestmentCard(e.key, e.value, dark, txtP, txtS, txtH,
                    border, allInv.length, s)),

            if (allInv.length > 4) ...[
              const SizedBox(height: 4),
              _viewToggleBtn(_showAll, s, green, dark,
                  allInv.length - 4, () => setState(() => _showAll = !_showAll)),
            ],
          ]),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 1 — CASH TRANSACTIONS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildCashContent(
      bool dark, Color txtP, Color txtS, Color txtH,
      Color green, Color border, _SS s,
      ) {
    if (_cashData == null) {
      return Center(child: Text(s.cashTransactions,
          style: TextStyle(fontSize: 14, color: txtS)));
    }
    final allTxns = _cashData!.transactions;
    final shown   = _showAllCash ? allTxns : allTxns.take(6).toList();

    final totalCredits = allTxns.where((t) => t.isCredit).fold(0.0, (a, t) => a + t.amount);
    final totalDebits  = allTxns.where((t) => !t.isCredit).fold(0.0, (a, t) => a + t.amount.abs());
    final netFlow      = totalCredits - totalDebits;

    return FadeTransition(
      opacity: _entryFade,
      child: SlideTransition(
        position: _entrySlide,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Cash flow summary card ─────────────────────────────────────
            _buildCashSummaryCard(dark, txtP, txtS, border, green,
                totalCredits, totalDebits, netFlow, s),

            const SizedBox(height: 24),

            // ── Section header ─────────────────────────────────────────────
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.cashTransactions.toUpperCase(), style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w800,
                    color: txtH, letterSpacing: 1.2)),
                const SizedBox(height: 2),
                Text('${allTxns.length} transactions',
                    style: TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w600, color: txtP)),
              ]),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (netFlow >= 0 ? const Color(0xFF43A047) : const Color(0xFFE53935))
                      .withOpacity(dark ? 0.15 : 0.09),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Net ${netFlow >= 0 ? '+' : ''}TZS ${_shortAmt(netFlow)}',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: netFlow >= 0
                          ? const Color(0xFF43A047) : const Color(0xFFE53935)),
                ),
              ),
            ]),

            const SizedBox(height: 14),

            ...shown.asMap().entries.map((e) =>
                _buildCashTxnCard(e.key, e.value, dark, txtP, txtS, txtH, border)),

            if (allTxns.length > 6) ...[
              const SizedBox(height: 4),
              _viewToggleBtn(_showAllCash, s, green, dark,
                  allTxns.length - 6, () => setState(() => _showAllCash = !_showAllCash)),
            ],
          ]),
        ),
      ),
    );
  }

  // ── Cash flow summary card ─────────────────────────────────────────────────
  Widget _buildCashSummaryCard(
      bool dark, Color txtP, Color txtS, Color border, Color green,
      double credits, double debits, double net, _SS s,
      ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF132013) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.swap_horiz_rounded, color: green, size: 16),
          ),
          const SizedBox(width: 10),
          Text(s.cashTransactions, style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w800, color: txtP)),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          _cashFlowStat(s.totalCredits, credits, const Color(0xFF43A047), dark, true),
          const SizedBox(width: 10),
          _cashFlowStat(s.totalDebits,  debits,  const Color(0xFFE53935), dark, false),
          const SizedBox(width: 10),
          _cashFlowStat(s.netFlow,      net,
              net >= 0 ? const Color(0xFF00ACC1) : const Color(0xFFE53935), dark, net >= 0),
        ]),
      ]),
    );
  }

  Widget _cashFlowStat(String label, double value, Color color, bool dark, bool credit) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(dark ? 0.12 : 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(credit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  size: 11, color: color),
              const SizedBox(width: 4),
              Expanded(child: Text(label, style: TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w600,
                  color: color), overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 6),
            Text(_shortAmt(value),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900,
                    color: color, letterSpacing: -0.4)),
            Text('TZS', style: TextStyle(fontSize: 8, color: color.withOpacity(0.6))),
          ]),
        ),
      );

  // ── Single cash transaction card ──────────────────────────────────────────
  Widget _buildCashTxnCard(
      int index, _CashTxn txn,
      bool dark, Color txtP, Color txtS, Color txtH, Color border,
      ) {
    final meta     = _txnMeta(txn.description, txn.isCredit);
    final cardBg   = dark ? const Color(0xFF132013) : Colors.white;
    final subtleBg = meta.color.withOpacity(dark ? 0.10 : 0.06);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 280 + index * 50),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(
          opacity: v,
          child: Transform.translate(
              offset: Offset(0, 14 * (1 - v)), child: child)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(dark ? 0.12 : 0.04),
              blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          // ── Left colour strip ──────────────────────────────────────────
          Container(
            width: 4,
            height: 72,
            decoration: BoxDecoration(
              color: meta.color,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16)),
            ),
          ),

          // ── Icon ──────────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: subtleBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(meta.icon, size: 20, color: meta.color),
          ),

          // ── Details ───────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(txn.description,
                    style: TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w700, color: txtP),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 5),
                Row(children: [
                  _metaChip(Icons.calendar_today_outlined,
                      DateFormat('dd MMM yyyy').format(txn.date), txtS, dark),
                  const SizedBox(width: 8),
                  _metaChip(Icons.tag_outlined,
                      '#${txn.txnId}', txtS, dark),
                ]),
              ]),
            ),
          ),

          // ── Amount ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(txn.isCredit ? '+' : '−',
                  style: TextStyle(fontSize: 10,
                      fontWeight: FontWeight.w700, color: meta.color)),
              Text('TZS ${_shortAmt(txn.amount.abs())}',
                  style: TextStyle(fontSize: 15,
                      fontWeight: FontWeight.w900, color: meta.color,
                      letterSpacing: -0.4)),
              Text(_fmt(txn.amount.abs(), decimals: 0),
                  style: TextStyle(fontSize: 9, color: txtH)),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── Shared view-all / view-less button ────────────────────────────────────
  Widget _viewToggleBtn(bool expanded, _SS s, Color green, bool dark,
      int remaining, VoidCallback onTap) =>
      GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); onTap(); },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: green.withOpacity(dark ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: green.withOpacity(0.25)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(
              expanded ? s.viewLess : '${s.viewAll} ($remaining more)',
              style: TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w700, color: green),
            ),
            const SizedBox(width: 6),
            AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 250),
              child: Icon(Icons.keyboard_arrow_down_rounded,
                  color: green, size: 18),
            ),
          ]),
        ),
      );

  // ── Portfolio breakdown bar ───────────────────────────────────────────────
  Widget _buildPortfolioBreakdownBar(
      bool dark, Color txtP, Color txtS, Color txtH, Color green, Color border,
      List<_SMAInvestment> investments, _SS s,
      ) {
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
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Row(
            children: byBank.entries.map((e) {
              final pct = total > 0 ? e.value / total : 0.0;
              return Flexible(
                flex: (pct * 1000).round(),
                child: Container(height: 14, color: _bankColor(e.key)),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
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
    final bank      = _bankName(inv.description);
    final rate      = _rate(inv.description);
    final maturity  = _maturity(inv.description);
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
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: subtleBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
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
                        border: Border.all(color: bankColor.withOpacity(0.3)),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(children: [
              _metaChip(Icons.calendar_today_outlined,
                  DateFormat('dd MMM yyyy').format(inv.date), txtS, dark),
              const SizedBox(width: 10),
              _metaChip(Icons.tag_outlined, '#${inv.txnId}', txtS, dark),
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

// ── Transaction meta (icon + colour) ─────────────────────────────────────────
class _TxnMeta {
  final IconData icon;
  final Color    color;
  const _TxnMeta(this.icon, this.color);
}