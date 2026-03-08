import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../provider/locale_provider.dart';
import '../../provider/theme_provider.dart';
import '../funds/model/model.dart';
import '../funds/repository/repository.dart';

// ─── Model ───────────────────────────────────────────────────────────────────
class _Txn {
  final String id, description, rawDate;
  final double units, price, amount;
  final bool isDeposit;
  _Txn({
    required this.id, required this.description, required this.rawDate,
    required this.units, required this.price, required this.amount,
    required this.isDeposit,
  });
  DateTime get date {
    try { return DateFormat('dd-MMM-yyyy HH:mm').parse(rawDate); }
    catch (_) { return DateTime.now(); }
  }
  factory _Txn.fromJson(Map<String, dynamic> j) {
    final desc  = j['Description'] as String? ?? '';
    final lower = desc.toLowerCase();
    return _Txn(
      id: j['TrxnID']?.toString() ?? '',
      description: desc,
      rawDate: j['TrxnDate'] as String? ?? '',
      units:  double.tryParse(j['Units']?.toString()  ?? '0') ?? 0,
      price:  double.tryParse(j['Price']?.toString()  ?? '0') ?? 0,
      amount: double.tryParse(j['amount']?.toString() ?? '0') ?? 0,
      isDeposit: lower.contains('deposit') || lower.contains('credit') ||
          lower.contains('purchase') || lower.contains('buy'),
    );
  }
}

enum _Filter { both, deposits, withdrawals }

// ─── Page ─────────────────────────────────────────────────────────────────────
class ClientStatementPage extends StatefulWidget {
  const ClientStatementPage({Key? key}) : super(key: key);
  @override State<ClientStatementPage> createState() => _ClientStatementPageState();
}

class _ClientStatementPageState extends State<ClientStatementPage>
    with TickerProviderStateMixin {

  String _cdsNumber = '', _userName = '';
  List<Fund> _funds = [];
  Fund? _selectedFund;
  bool _loadingFunds = true;
  String _fundsError = '';
  List<_Txn> _allTxns = [];
  bool _loadingTxns = false;
  String? _txnsError;
  bool _hasFetched = false;
  _Filter _filter = _Filter.both;

  late AnimationController _listCtrl;
  late AnimationController _headerCtrl;
  late Animation<double> _listFade;
  late Animation<Offset> _headerSlide;

  // ── Palette ──────────────────────────────────────────────────────────────
  bool  get _dark   => context.watch<ThemeProvider>().isDark;
  _CS   get _s      => context.watch<LocaleProvider>().isSwahili ? _sw : _en;

  Color get _bg        => _dark ? const Color(0xFF0A160B) : const Color(0xFFF0FBF5);
  Color get _card      => _dark ? const Color(0xFF152216) : Colors.white;
  Color get _border    => _dark ? const Color(0xFF1E3320) : const Color(0xFFE0F2E9);
  Color get _txtP      => _dark ? const Color(0xFFEEF7EE) : const Color(0xFF0D2010);
  Color get _txtS      => _dark ? const Color(0xFF7FAF80) : const Color(0xFF6B8F70);
  Color get _accent    => _dark ? const Color(0xFF4CAF50) : const Color(0xFF1B5E20);
  Color get _teal      => const Color(0xFF2E7D99);
  Color get _greenSoft => _dark ? const Color(0xFF0A2010) : const Color(0xFFE8F5E9);
  Color get _redSoft   => _dark ? const Color(0xFF2D0A0A) : const Color(0xFFFFEBEE);

  static const Color _depositColor    = Color(0xFF2E7D32);
  static const Color _withdrawColor   = Color(0xFFC62828);

  // ── Init ─────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _listCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _headerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _listFade   = CurvedAnimation(parent: _listCtrl, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut));
    _headerCtrl.forward();
    _init();
  }

  @override
  void dispose() {
    _listCtrl.dispose();
    _headerCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _cdsNumber = p.getString('cdsNumber')     ?? '';
      _userName  = p.getString('user_fullname') ?? 'Investor';
    });
    _loadFunds();
  }

  Future<void> _loadFunds() async {
    setState(() { _loadingFunds = true; _fundsError = ''; });
    try {
      final funds = await FundsRepository().fetchFunds();
      setState(() {
        _funds        = funds;
        _selectedFund = funds.isNotEmpty ? funds.first : null;
        _loadingFunds = false;
      });
    } catch (_) {
      setState(() { _fundsError = _s.failedFunds; _loadingFunds = false; });
    }
  }

  Future<void> _fetchTransactions() async {
    if (_selectedFund == null) return;
    setState(() { _loadingTxns = true; _txnsError = null; _hasFetched = false; });
    _listCtrl.reset();
    try {
      final response = await http.post(
        Uri.parse('https://portaluat.tsl.co.tz/FMSAPI/home/GetTransactions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'APIUsername': 'User2', 'APIPassword': 'CBZ1234#2',
          'cdsNumber': _cdsNumber, 'Fund': _selectedFund!.fundingName ?? '',
        }),
      ).timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        final raw = (data['data']['trans'] as List<dynamic>?) ?? [];
        setState(() {
          _allTxns = raw.map((j) => _Txn.fromJson(j)).toList()
            ..sort((a, b) => b.date.compareTo(a.date));
          _loadingTxns = false;
          _hasFetched  = true;
        });
        _listCtrl.forward();
      } else {
        setState(() {
          _txnsError   = data['statusDesc'] ?? _s.failedTxns;
          _loadingTxns = false;
          _hasFetched  = true;
        });
      }
    } catch (_) {
      setState(() {
        _txnsError   = _s.connError;
        _loadingTxns = false;
        _hasFetched  = true;
      });
    }
  }

  List<_Txn> get _filtered {
    switch (_filter) {
      case _Filter.deposits:    return _allTxns.where((t) =>  t.isDeposit).toList();
      case _Filter.withdrawals: return _allTxns.where((t) => !t.isDeposit).toList();
      case _Filter.both:        return _allTxns;
    }
  }

  double get _totalDeposits    => _allTxns.where((t) =>  t.isDeposit).fold(0.0, (s,t) => s+t.amount);
  double get _totalWithdrawals => _allTxns.where((t) => !t.isDeposit).fold(0.0, (s,t) => s+t.amount);
  double get _netFlow          => _totalDeposits - _totalWithdrawals;

  String _fmt(double v) {
    final s = v.toStringAsFixed(2).split('.');
    return '${s[0].replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}\.${s[1]}';
  }

  // ─── PDF ────────────────────────────────────────────────────────────────
  Future<void> _downloadPDF() async {
    final pdf  = pw.Document();
    final txns = _filtered;
    final fundName = _selectedFund?.fundingName ?? 'Fund';
    final now = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => [
        pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#1B5E20'),
            borderRadius: pw.BorderRadius.circular(12),
          ),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('TSL Investment',
                style: pw.TextStyle(color: PdfColors.white, fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(_s.clientStatement,
                style: pw.TextStyle(color: PdfColors.white, fontSize: 13)),
          ]),
        ),
        pw.SizedBox(height: 20),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            _pdfLbl('${_s.cdsNumber}:', _cdsNumber),
            pw.SizedBox(height: 6),
            _pdfLbl('${_s.fund}:', fundName),
            pw.SizedBox(height: 6),
            _pdfLbl('${_s.generated}:', now),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            _pdfLbl('${_s.totalDeposits}:', 'TZS ${_fmt(_totalDeposits)}'),
            pw.SizedBox(height: 6),
            _pdfLbl('${_s.totalWithdrawals}:', 'TZS ${_fmt(_totalWithdrawals)}'),
            pw.SizedBox(height: 6),
            _pdfLbl('${_s.netFlow}:', 'TZS ${_fmt(_netFlow)}'),
          ]),
        ]),
        pw.SizedBox(height: 24),
        pw.Table(
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1.5),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColor.fromHex('#E8F5E9')),
              children: [_s.description, _s.units, _s.date, _s.amountTZS]
                  .map((h) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: pw.Text(h, style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 10,
                    color: PdfColor.fromHex('#1B5E20'))),
              ))
                  .toList(),
            ),
            ...txns.asMap().entries.map((e) {
              final t = e.value; final odd = e.key.isOdd;
              return pw.TableRow(
                decoration: pw.BoxDecoration(color: odd ? PdfColors.grey100 : PdfColors.white),
                children: [
                  t.description, _fmt(t.units),
                  DateFormat('dd MMM yy').format(t.date),
                  '${t.isDeposit ? '+' : '-'} ${_fmt(t.amount)}',
                ].map((cell) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: pw.Text(cell, style: pw.TextStyle(
                      fontSize: 9,
                      color: cell.startsWith('+') ? PdfColors.green800
                          : cell.startsWith('-') ? PdfColors.red800
                          : PdfColors.black)),
                )).toList(),
              );
            }).toList(),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Divider(),
        pw.SizedBox(height: 8),
        pw.Text(_s.pdfFooter,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
      ],
    ));
    await Printing.layoutPdf(
      onLayout: (fmt) => pdf.save(),
      name: 'TSL_Statement_${fundName.replaceAll(' ', '_')}.pdf',
    );
  }

  pw.Widget _pdfLbl(String label, String value) => pw.RichText(
    text: pw.TextSpan(children: [
      pw.TextSpan(text: '$label ',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey700)),
      pw.TextSpan(text: value,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.black)),
    ]),
  );

  // ─── Root build ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    context.watch<LocaleProvider>();
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          Column(children: [
            _buildHeroHeader(),
            Expanded(child: _buildScrollBody()),
          ]),
        ],
      ),
    );
  }

  // ─── Hero Header ─────────────────────────────────────────────────────────
  Widget _buildHeroHeader() {
    return SlideTransition(
      position: _headerSlide,
      child: Container(
        decoration: BoxDecoration(
          gradient: _dark
              ? const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF0B1A0C), Color(0xFF143516), Color(0xFF0A1E0B)])
              : const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF1565C0)]),
        ),
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // Decorative circle top-right
              Positioned(
                top: -30, right: -30,
                child: Container(
                  width: 140, height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              Positioned(
                top: 40, right: 50,
                child: Container(
                  width: 70, height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Top row: back + PDF button
                  Row(children: [
                    _headerIconBtn(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    if (_hasFetched && _filtered.isNotEmpty)
                      _pdfButton(),
                  ]),
                  const SizedBox(height: 22),
                  // Title block
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: const Icon(Icons.receipt_long_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_s.clientStatement,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      Text(_s.statementSubtitle,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.68),
                              fontSize: 12)),
                    ]),
                  ]),
                  // Summary strip — only when data loaded
                  if (_hasFetched && _txnsError == null) ...[
                    const SizedBox(height: 22),
                    _buildHeroSummaryStrip(),
                  ],
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerIconBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.22)),
        ),
        child: Icon(icon, color: Colors.white, size: 17),
      ),
    );
  }

  Widget _pdfButton() {
    return GestureDetector(
      onTap: _downloadPDF,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 15),
          const SizedBox(width: 6),
          Text(_s.downloadPDF,
              style: const TextStyle(color: Colors.white,
                  fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  // Hero summary strip (3 metrics in a row inside the header)
  Widget _buildHeroSummaryStrip() {
    final net     = _netFlow;
    final netColor = net >= 0 ? const Color(0xFF81C784) : const Color(0xFFEF9A9A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(children: [
        _heroMetric(_s.deposits,     _fmt(_totalDeposits),    const Color(0xFF81C784)),
        _heroDivider(),
        _heroMetric(_s.withdrawals,  _fmt(_totalWithdrawals), const Color(0xFFEF9A9A)),
        _heroDivider(),
        _heroMetric(_s.netFlow,      _fmt(net.abs()),         netColor),
      ]),
    );
  }

  Widget _heroMetric(String label, String value, Color color) {
    return Expanded(child: Column(children: [
      Text(label,
          style: TextStyle(color: Colors.white.withOpacity(0.62),
              fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
      const SizedBox(height: 5),
      Text(value,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: color, fontSize: 13,
              fontWeight: FontWeight.w900, letterSpacing: -0.3)),
    ]));
  }

  Widget _heroDivider() {
    return Container(width: 1, height: 32,
        color: Colors.white.withOpacity(0.18),
        margin: const EdgeInsets.symmetric(horizontal: 6));
  }

  // ─── Scroll body ─────────────────────────────────────────────────────────
  Widget _buildScrollBody() {
    return Container(
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28), topRight: Radius.circular(28),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28), topRight: Radius.circular(28),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── Fund selector ──────────────────────────────────────────
              _sectionLabel('SELECT FUND', Icons.account_balance_outlined),
              const SizedBox(height: 10),
              _buildFundPicker(),
              const SizedBox(height: 22),

              // ── Filter chips ───────────────────────────────────────────
              _sectionLabel('FILTER BY', Icons.filter_list_rounded),
              const SizedBox(height: 10),
              _buildFilterSegment(),
              const SizedBox(height: 22),

              // ── Load button ────────────────────────────────────────────
              _buildLoadButton(),
              const SizedBox(height: 28),

              // ── Results ────────────────────────────────────────────────
              if (_hasFetched) ...[
                if (_txnsError != null)
                  _buildErrorState()
                else ...[
                  _buildSummaryCards(),
                  const SizedBox(height: 24),
                  _buildTransactionList(),
                ],
              ],
            ]),
          ),
        ),
      ),
    );
  }

  // ─── Section label ────────────────────────────────────────────────────────
  Widget _sectionLabel(String text, IconData icon) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _accent.withOpacity(0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: _accent),
      ),
      const SizedBox(width: 8),
      Text(text, style: TextStyle(
          fontSize: 10, fontWeight: FontWeight.w800,
          color: _txtS, letterSpacing: 1.6)),
    ]);
  }

  // ─── Fund picker ─────────────────────────────────────────────────────────
  Widget _buildFundPicker() {
    if (_loadingFunds) {
      return _shimmerBox(double.infinity, 62);
    }
    if (_fundsError.isNotEmpty) {
      return GestureDetector(
        onTap: _loadFunds,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _redSoft, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withOpacity(0.25)),
          ),
          child: Row(children: [
            const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(_fundsError,
                style: const TextStyle(color: Colors.red, fontSize: 13))),
            Text(_s.retry, style: const TextStyle(
                color: Colors.red, fontWeight: FontWeight.w700, fontSize: 13)),
          ]),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 1.5),
        boxShadow: [
          BoxShadow(color: _accent.withOpacity(_dark ? 0.1 : 0.06),
              blurRadius: 14, offset: const Offset(0, 5)),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Fund>(
          value: _selectedFund,
          isExpanded: true,
          dropdownColor: _card,
          icon: Icon(Icons.expand_more_rounded, color: _accent),
          style: TextStyle(color: _txtP, fontSize: 14),
          items: _funds.map((fund) {
            final isActive = fund.status?.toLowerCase() == 'active';
            return DropdownMenuItem<Fund>(
              value: fund,
              child: Row(children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? _depositColor : Colors.orange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(fund.fundingName ?? 'Unknown',
                        style: TextStyle(fontWeight: FontWeight.w700,
                            fontSize: 14, color: _txtP),
                        overflow: TextOverflow.ellipsis),
                    if (fund.issuer != null)
                      Text(fund.issuer!,
                          style: TextStyle(fontSize: 11, color: _txtS)),
                  ],
                )),
              ]),
            );
          }).toList(),
          onChanged: (f) => setState(() {
            _selectedFund = f;
            _hasFetched   = false;
            _allTxns      = [];
          }),
        ),
      ),
    );
  }

  // ─── Filter segment ───────────────────────────────────────────────────────
  Widget _buildFilterSegment() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 1.5),
      ),
      child: Row(children: [
        _segTab(_Filter.both,        _s.all,        Icons.swap_vert_rounded),
        _segTab(_Filter.deposits,    _s.deposits,   Icons.arrow_downward_rounded),
        _segTab(_Filter.withdrawals, _s.withdrawals, Icons.arrow_upward_rounded),
      ]),
    );
  }

  Widget _segTab(_Filter f, String label, IconData icon) {
    final active     = _filter == f;
    final tabColor   = f == _Filter.deposits ? _depositColor
        : f == _Filter.withdrawals ? _withdrawColor
        : _teal;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filter = f),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? tabColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: active ? [
              BoxShadow(color: tabColor.withOpacity(0.30),
                  blurRadius: 10, offset: const Offset(0, 4)),
            ] : [],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 13,
                color: active ? Colors.white : _txtS),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? Colors.white : _txtS)),
          ]),
        ),
      ),
    );
  }

  // ─── Load button ──────────────────────────────────────────────────────────
  Widget _buildLoadButton() {
    final loading = _loadingFunds || _loadingTxns;
    return GestureDetector(
      onTap: loading ? null : _fetchTransactions,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: loading
              ? null
              : LinearGradient(
              colors: _dark
                  ? [const Color(0xFF2E7D32), const Color(0xFF1B5E20)]
                  : [const Color(0xFF2E7D32), const Color(0xFF1B5E20)]),
          color: loading ? _border : null,
          boxShadow: loading ? [] : [
            BoxShadow(color: _accent.withOpacity(0.35),
                blurRadius: 18, offset: const Offset(0, 8)),
          ],
        ),
        child: Center(
          child: _loadingTxns
              ? const SizedBox(width: 22, height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.search_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(_s.loadTransactions,
                style: const TextStyle(color: Colors.white,
                    fontSize: 15, fontWeight: FontWeight.w800,
                    letterSpacing: 0.3)),
          ]),
        ),
      ),
    );
  }

  // ─── Summary cards ────────────────────────────────────────────────────────
  Widget _buildSummaryCards() {
    final txns = _filtered;
    final deps = txns.where((t) =>  t.isDeposit).fold(0.0, (s,t) => s+t.amount);
    final wds  = txns.where((t) => !t.isDeposit).fold(0.0, (s,t) => s+t.amount);
    final depCount = txns.where((t) =>  t.isDeposit).length;
    final wdCount  = txns.where((t) => !t.isDeposit).length;

    return Row(children: [
      Expanded(child: _summaryCard(
        label: _s.deposits, value: _fmt(deps),
        icon: Icons.arrow_downward_rounded,
        color: _depositColor, bgColor: _greenSoft, count: depCount,
      )),
      const SizedBox(width: 12),
      Expanded(child: _summaryCard(
        label: _s.withdrawals, value: _fmt(wds),
        icon: Icons.arrow_upward_rounded,
        color: _withdrawColor, bgColor: _redSoft, count: wdCount,
      )),
    ]);
  }

  Widget _summaryCard({
    required String label, required String value,
    required IconData icon, required Color color,
    required Color bgColor, required int count,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border, width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withOpacity(_dark ? 0.12 : 0.08),
              blurRadius: 18, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: bgColor, borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, color: color, size: 16),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: bgColor, borderRadius: BorderRadius.circular(20)),
            child: Text('$count ${_s.txns}',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                    color: color)),
          ),
        ]),
        const SizedBox(height: 14),
        Text(label, style: TextStyle(fontSize: 11, color: _txtS,
            fontWeight: FontWeight.w600, letterSpacing: 0.2)),
        const SizedBox(height: 5),
        Text('TZS $value',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900,
                color: color, letterSpacing: -0.3)),
      ]),
    );
  }

  // ─── Transaction list ─────────────────────────────────────────────────────
  Widget _buildTransactionList() {
    final txns = _filtered;
    if (txns.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                  color: _greenSoft, shape: BoxShape.circle),
              child: Icon(Icons.receipt_long_outlined,
                  size: 40, color: _accent.withOpacity(0.5)),
            ),
            const SizedBox(height: 18),
            Text(_s.noTxns, style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: _txtP)),
            const SizedBox(height: 6),
            Text(_s.tryFilter, style: TextStyle(fontSize: 13, color: _txtS)),
          ]),
        ),
      );
    }

    return FadeTransition(
      opacity: _listFade,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header row
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(_s.transactionCount(txns.length),
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                  color: _txtP, letterSpacing: -0.2)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(_selectedFund?.fundingName ?? '',
                style: TextStyle(fontSize: 11, color: _accent,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 16),

        // Timeline list
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: txns.length,
          itemBuilder: (_, i) => _buildTimelineItem(txns[i], i, txns.length),
        ),
      ]),
    );
  }

  Widget _buildTimelineItem(_Txn t, int index, int total) {
    final isLast   = index == total - 1;
    final color    = t.isDeposit ? _depositColor : _withdrawColor;
    final bgColor  = t.isDeposit ? _greenSoft    : _redSoft;
    final icon     = t.isDeposit
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 40).clamp(0, 400)),
      curve: Curves.easeOut,
      builder: (ctx, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: child),
      ),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Timeline spine
          SizedBox(
            width: 36,
            child: Column(children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: bgColor, shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.3), width: 1.5),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              if (!isLast)
                Expanded(child: Center(
                  child: Container(width: 2,
                      color: _border),
                )),
            ]),
          ),
          const SizedBox(width: 12),

          // Card
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _border, width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: color.withOpacity(_dark ? 0.08 : 0.05),
                      blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Top row: description + amount
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: Text(t.description,
                        overflow: TextOverflow.ellipsis, maxLines: 2,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                            color: _txtP, height: 1.4)),
                  ),
                  const SizedBox(width: 8),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${t.isDeposit ? '+' : '-'} TZS',
                        style: TextStyle(fontSize: 10,
                            color: color.withOpacity(0.7),
                            fontWeight: FontWeight.w600)),
                    Text(_fmt(t.amount),
                        style: TextStyle(fontSize: 15,
                            fontWeight: FontWeight.w900, color: color,
                            letterSpacing: -0.3)),
                  ]),
                ]),
                const SizedBox(height: 10),
                // Bottom row: date + pills
                Wrap(spacing: 6, runSpacing: 4, children: [
                  _pill(
                    icon: Icons.access_time_rounded,
                    label: DateFormat('dd MMM yyyy • HH:mm').format(t.date),
                    bg: _card, fg: _txtS,
                  ),
                  _pill(
                    icon: Icons.tag_rounded,
                    label: t.id,
                    bg: _accent.withOpacity(0.08), fg: _accent,
                  ),
                  _pill(
                    icon: Icons.stacked_line_chart_rounded,
                    label: '${_fmt(t.units)} ${_s.units}',
                    bg: bgColor, fg: color,
                  ),
                ]),
                // Price per unit
                if (t.price > 0) ...[
                  const SizedBox(height: 6),
                  Text('@TZS ${_fmt(t.price)} / unit',
                      style: TextStyle(fontSize: 10, color: _txtS,
                          fontStyle: FontStyle.italic)),
                ],
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _pill({required IconData icon, required String label,
    required Color bg, required Color fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withOpacity(0.15)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: fg),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 10, color: fg, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  // ─── Error state ──────────────────────────────────────────────────────────
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: _redSoft, shape: BoxShape.circle),
            child: Icon(Icons.cloud_off_outlined,
                color: Colors.red.shade400, size: 36),
          ),
          const SizedBox(height: 16),
          Text(_txnsError!, textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade400, fontSize: 14, height: 1.5)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _fetchTransactions,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
              decoration: BoxDecoration(
                color: _accent, borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: _accent.withOpacity(0.3),
                      blurRadius: 14, offset: const Offset(0, 6)),
                ],
              ),
              child: Text(_s.tryAgain,
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
        ]),
      ),
    );
  }

  // ─── Shimmer placeholder ──────────────────────────────────────────────────
  Widget _shimmerBox(double w, double h, {double radius = 14}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1200),
      builder: (_, v, __) => Container(
        width: w, height: h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment(-1.0 + v * 2, 0),
            end: Alignment(v * 2, 0),
            colors: [_border, _card, _border],
          ),
        ),
      ),
    );
  }
}

// ─── String tables ────────────────────────────────────────────────────────────
class _CS {
  final String clientStatement, statementSubtitle, downloadPDF, selectFund,
      failedFunds, all, deposits, withdrawals, loadTransactions, loading,
      noTxns, tryFilter, txns, units, totalDeposits, totalWithdrawals,
      netFlow, cdsNumber, fund, generated, description, date, amountTZS,
      pdfFooter, retry, tryAgain, connError, failedTxns;
  final String Function(int) transactionCount;
  const _CS({
    required this.clientStatement,  required this.statementSubtitle,
    required this.downloadPDF,      required this.selectFund,
    required this.failedFunds,      required this.all,
    required this.deposits,         required this.withdrawals,
    required this.loadTransactions, required this.loading,
    required this.noTxns,           required this.tryFilter,
    required this.txns,             required this.units,
    required this.totalDeposits,    required this.totalWithdrawals,
    required this.netFlow,          required this.cdsNumber,
    required this.fund,             required this.generated,
    required this.description,      required this.date,
    required this.amountTZS,        required this.pdfFooter,
    required this.retry,            required this.tryAgain,
    required this.connError,        required this.failedTxns,
    required this.transactionCount,
  });
}

const _en = _CS(
  clientStatement: 'Client Statement',
  statementSubtitle: 'View your deposits & withdrawals per fund',
  downloadPDF: 'Download PDF',
  selectFund: 'Select Fund',
  failedFunds: 'Failed to load funds',
  all: 'All',
  deposits: 'Deposits',
  withdrawals: 'Withdrawals',
  loadTransactions: 'Load Transactions',
  loading: 'Loading…',
  noTxns: 'No transactions found',
  tryFilter: 'Try changing the filter above',
  txns: 'txns',
  units: 'units',
  totalDeposits: 'Total Deposits',
  totalWithdrawals: 'Total Withdrawals',
  netFlow: 'Net Flow',
  cdsNumber: 'Account Number',
  fund: 'Fund',
  generated: 'Generated',
  description: 'Description',
  date: 'Date',
  amountTZS: 'Amount (TZS)',
  pdfFooter: 'This statement is generated electronically and is valid without a signature.',
  retry: 'Retry',
  tryAgain: 'Try Again',
  connError: 'Connection error. Please try again.',
  failedTxns: 'Failed to retrieve transactions',
  transactionCount: _enCount,
);
String _enCount(int n) => '$n Transaction${n == 1 ? '' : 's'}';

const _sw = _CS(
  clientStatement: 'Taarifa ya Mteja',
  statementSubtitle: 'Angalia amana na malipo yako kwa kila fedha',
  downloadPDF: 'Pakua PDF',
  selectFund: 'Chagua Fedha',
  failedFunds: 'Imeshindwa kupakia fedha',
  all: 'Yote',
  deposits: 'Amana',
  withdrawals: 'Malipo',
  loadTransactions: 'Pakia Miamala',
  loading: 'Inapakia…',
  noTxns: 'Hakuna miamala iliyopatikana',
  tryFilter: 'Jaribu kubadilisha kichujio hapo juu',
  txns: 'miamala',
  units: 'vitengo',
  totalDeposits: 'Jumla ya Amana',
  totalWithdrawals: 'Jumla ya Malipo',
  netFlow: 'Mtiririko Halisi',
  cdsNumber: 'Nambari ya Akaunti',
  fund: 'Fedha',
  generated: 'Imetolewa',
  description: 'Maelezo',
  date: 'Tarehe',
  amountTZS: 'Kiasi (TZS)',
  pdfFooter: 'Taarifa hii imetolewa kwa njia ya kielektroniki na ni halali bila sahihi.',
  retry: 'Jaribu Tena',
  tryAgain: 'Jaribu Tena',
  connError: 'Hitilafu ya mtandao. Tafadhali jaribu tena.',
  failedTxns: 'Imeshindwa kupata miamala',
  transactionCount: _swCount,
);
String _swCount(int n) => 'Miamala $n';