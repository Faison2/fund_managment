import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../funds/model/model.dart';
import '../funds/repository/repository.dart';

// ── Data model ───────────────────────────────────────────────────────────────
class _Txn {
  final String id;
  final String description;
  final String rawDate;   // "07-Mar-2026 00:00"
  final double units;
  final double price;
  final double amount;
  final bool isDeposit;

  _Txn({
    required this.id,
    required this.description,
    required this.rawDate,
    required this.units,
    required this.price,
    required this.amount,
    required this.isDeposit,
  });

  DateTime get date {
    try {
      return DateFormat('dd-MMM-yyyy HH:mm').parse(rawDate);
    } catch (_) {
      return DateTime.now();
    }
  }

  factory _Txn.fromJson(Map<String, dynamic> j) {
    final desc = j['Description'] as String? ?? '';
    final lower = desc.toLowerCase();
    final isDeposit = lower.contains('deposit') ||
        lower.contains('credit') ||
        lower.contains('purchase') ||
        lower.contains('buy');
    return _Txn(
      id:          j['TrxnID']?.toString() ?? '',
      description: desc,
      rawDate:     j['TrxnDate']  as String? ?? '',
      units:       double.tryParse(j['Units']?.toString() ?? '0') ?? 0,
      price:       double.tryParse(j['Price']?.toString() ?? '0') ?? 0,
      amount:      double.tryParse(j['amount']?.toString() ?? '0') ?? 0,
      isDeposit:   isDeposit,
    );
  }
}

// ── Filter enum ───────────────────────────────────────────────────────────────
enum _Filter { both, deposits, withdrawals }

// ─────────────────────────────────────────────────────────────────────────────
class ClientStatementPage extends StatefulWidget {
  const ClientStatementPage({Key? key}) : super(key: key);
  @override
  State<ClientStatementPage> createState() => _ClientStatementPageState();
}

class _ClientStatementPageState extends State<ClientStatementPage>
    with TickerProviderStateMixin {

  // ── User ──────────────────────────────────────────────────────────────────
  String _cdsNumber = '';
  String _userName  = '';

  // ── Funds ─────────────────────────────────────────────────────────────────
  List<Fund> _funds          = [];
  Fund?      _selectedFund;
  bool       _loadingFunds   = true;
  String     _fundsError     = '';

  // ── Transactions ──────────────────────────────────────────────────────────
  List<_Txn> _allTxns        = [];
  bool       _loadingTxns    = false;
  String?    _txnsError;
  bool       _hasFetched     = false;

  // ── Filter ────────────────────────────────────────────────────────────────
  _Filter    _filter         = _Filter.both;

  // ── Animation ─────────────────────────────────────────────────────────────
  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _init();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _cdsNumber = prefs.getString('cdsNumber') ?? '';
      _userName  = prefs.getString('user_fullname') ?? 'Investor';
    });
    _loadFunds();
  }

  // ── Load funds ────────────────────────────────────────────────────────────
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
      setState(() { _fundsError = 'Failed to load funds'; _loadingFunds = false; });
    }
  }

  // ── Fetch transactions ────────────────────────────────────────────────────
  Future<void> _fetchTransactions() async {
    if (_selectedFund == null) return;
    setState(() { _loadingTxns = true; _txnsError = null; _hasFetched = false; });
    try {
      final response = await http.post(
        Uri.parse('https://portaluat.tsl.co.tz/FMSAPI/home/GetTransactions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'APIUsername': 'User2',
          'APIPassword': 'CBZ1234#2',
          'cdsNumber':   _cdsNumber,
          'Fund':        _selectedFund!.fundingName ?? '',
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        final List<dynamic> raw =
            (data['data']['trans'] as List<dynamic>?) ?? [];
        setState(() {
          _allTxns   = raw.map((j) => _Txn.fromJson(j)).toList()
            ..sort((a, b) => b.date.compareTo(a.date)); // newest first
          _loadingTxns = false;
          _hasFetched  = true;
        });
        _fadeCtrl
          ..reset()
          ..forward();
      } else {
        setState(() {
          _txnsError   = data['statusDesc'] ?? 'Failed to retrieve transactions';
          _loadingTxns = false;
          _hasFetched  = true;
        });
      }
    } catch (e) {
      setState(() {
        _txnsError   = 'Connection error. Please try again.';
        _loadingTxns = false;
        _hasFetched  = true;
      });
    }
  }

  // ── Filtered list ─────────────────────────────────────────────────────────
  List<_Txn> get _filtered {
    switch (_filter) {
      case _Filter.deposits:    return _allTxns.where((t) =>  t.isDeposit).toList();
      case _Filter.withdrawals: return _allTxns.where((t) => !t.isDeposit).toList();
      case _Filter.both:        return _allTxns;
    }
  }

  double get _totalDeposits =>
      _allTxns.where((t) => t.isDeposit).fold(0.0, (s, t) => s + t.amount);
  double get _totalWithdrawals =>
      _allTxns.where((t) => !t.isDeposit).fold(0.0, (s, t) => s + t.amount);
  double get _netFlow => _totalDeposits - _totalWithdrawals;

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _fmt(double v) {
    final s = v.toStringAsFixed(2).split('.');
    final int = s[0].replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
    return '$int.${s[1]}';
  }

  // ── PDF Download ──────────────────────────────────────────────────────────
  Future<void> _downloadPDF() async {
    final pdf = pw.Document();
    final txns = _filtered;
    final fundName = _selectedFund?.fundingName ?? 'Fund';
    final now = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => [
        // ── Header ──────────────────────────────────────────
        pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#1B5E20'),
            borderRadius: pw.BorderRadius.circular(12),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('TSL Investment',
                  style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('Client Account Statement',
                  style: pw.TextStyle(
                      color: PdfColors.white, fontSize: 13)),
            ],
          ),
        ),
        pw.SizedBox(height: 20),

        // ── Meta ─────────────────────────────────────────────
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              _pdfLabel('CDS Number', _cdsNumber),
              pw.SizedBox(height: 6),
              _pdfLabel('Fund', fundName),
              pw.SizedBox(height: 6),
              _pdfLabel('Generated', now),
            ]),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              _pdfLabel('Total Deposits',    'TZS ${_fmt(_totalDeposits)}'),
              pw.SizedBox(height: 6),
              _pdfLabel('Total Withdrawals', 'TZS ${_fmt(_totalWithdrawals)}'),
              pw.SizedBox(height: 6),
              _pdfLabel('Net Flow',          'TZS ${_fmt(_netFlow)}'),
            ]),
          ],
        ),
        pw.SizedBox(height: 24),

        // ── Table ─────────────────────────────────────────────
        pw.Table(
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1.5),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(2),
          },
          children: [
            // Header row
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColor.fromHex('#E8F5E9')),
              children: ['Description', 'Units', 'Date', 'Amount (TZS)']
                  .map((h) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8, vertical: 8),
                child: pw.Text(h,
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                        color: PdfColor.fromHex('#1B5E20'))),
              ))
                  .toList(),
            ),
            // Data rows
            ...txns.asMap().entries.map((e) {
              final t   = e.value;
              final odd = e.key.isOdd;
              return pw.TableRow(
                decoration: pw.BoxDecoration(
                    color: odd ? PdfColors.grey100 : PdfColors.white),
                children: [
                  t.description,
                  _fmt(t.units),
                  DateFormat('dd MMM yy').format(t.date),
                  '${t.isDeposit ? '+' : '-'} ${_fmt(t.amount)}',
                ].map((cell) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8, vertical: 6),
                  child: pw.Text(cell,
                      style: pw.TextStyle(
                          fontSize: 9,
                          color: cell.startsWith('+')
                              ? PdfColors.green800
                              : cell.startsWith('-')
                              ? PdfColors.red800
                              : PdfColors.black)),
                ))
                    .toList(),
              );
            }),
          ],
        ),

        pw.SizedBox(height: 20),
        pw.Divider(),
        pw.SizedBox(height: 8),
        pw.Text('This statement is generated electronically and is valid without a signature.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
      ],
    ));

    await Printing.layoutPdf(
      onLayout: (fmt) => pdf.save(),
      name: 'TSL_Statement_${fundName.replaceAll(' ', '_')}.pdf',
    );
  }

  pw.Widget _pdfLabel(String label, String value) => pw.RichText(
    text: pw.TextSpan(children: [
      pw.TextSpan(
          text: '$label: ',
          style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
              color: PdfColors.grey700)),
      pw.TextSpan(
          text: value,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.black)),
    ]),
  );

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FBF5),
      body: Column(children: [
        _buildHeader(),
        Expanded(child: _buildBody()),
      ]),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                const Spacer(),
                if (_hasFetched && _filtered.isNotEmpty)
                  GestureDetector(
                    onTap: _downloadPDF,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.4), width: 1),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.picture_as_pdf,
                              color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text('Download PDF',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
              ]),
              const SizedBox(height: 18),
              const Text('Client Statement',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Text('View your deposits & withdrawals per fund',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.7), fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF0FBF5),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Fund picker ────────────────────────────────────────
                _buildFundPicker(),
                const SizedBox(height: 20),

                // ── Filter chips ───────────────────────────────────────
                _buildFilterChips(),
                const SizedBox(height: 20),

                // ── Fetch button ───────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: (_loadingFunds || _loadingTxns)
                        ? null
                        : _fetchTransactions,
                    icon: _loadingTxns
                        ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.search_rounded, size: 20),
                    label: Text(
                      _loadingTxns ? 'Loading…' : 'Load Transactions',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Results ────────────────────────────────────────────
                if (_hasFetched) ...[
                  if (_txnsError != null)
                    _buildError()
                  else ...[
                    _buildSummaryCards(),
                    const SizedBox(height: 20),
                    _buildTransactionList(),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Fund picker ────────────────────────────────────────────────────────────
  Widget _buildFundPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Fund',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B5E20),
                letterSpacing: 0.3)),
        const SizedBox(height: 10),
        if (_loadingFunds)
          Container(
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child: const Center(
                child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF1B5E20)))),
          )
        else if (_fundsError.isNotEmpty)
          GestureDetector(
            onTap: _loadFunds,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 18),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(_fundsError,
                        style: const TextStyle(color: Colors.red))),
                Text('Retry',
                    style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Fund>(
                value: _selectedFund,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down,
                    color: Color(0xFF1B5E20)),
                items: _funds.map((fund) {
                  final isActive =
                      fund.status?.toLowerCase() == 'active';
                  return DropdownMenuItem<Fund>(
                    value: fund,
                    child: Row(children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(fund.fundingName ?? 'Unknown Fund',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: Colors.black87),
                                overflow: TextOverflow.ellipsis),
                            if (fund.issuer != null)
                              Text(fund.issuer!,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500])),
                          ],
                        ),
                      ),
                    ]),
                  );
                }).toList(),
                onChanged: (f) {
                  setState(() {
                    _selectedFund = f;
                    _hasFetched   = false;
                    _allTxns      = [];
                  });
                },
              ),
            ),
          ),
      ],
    );
  }

  // ── Filter chips ───────────────────────────────────────────────────────────
  Widget _buildFilterChips() {
    return Row(children: [
      _chip(_Filter.both,        'All',         Icons.swap_vert_rounded),
      const SizedBox(width: 10),
      _chip(_Filter.deposits,    'Deposits',    Icons.arrow_downward_rounded),
      const SizedBox(width: 10),
      _chip(_Filter.withdrawals, 'Withdrawals', Icons.arrow_upward_rounded),
    ]);
  }

  Widget _chip(_Filter filter, String label, IconData icon) {
    final active = _filter == filter;
    Color activeColor;
    switch (filter) {
      case _Filter.deposits:    activeColor = const Color(0xFF2E7D32); break;
      case _Filter.withdrawals: activeColor = const Color(0xFFC62828); break;
      case _Filter.both:        activeColor = const Color(0xFF1565C0); break;
    }
    return GestureDetector(
      onTap: () => setState(() => _filter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: active ? activeColor : Colors.grey.shade300, width: 1.5),
          boxShadow: active
              ? [
            BoxShadow(
                color: activeColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]
              : [],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: active ? Colors.white : Colors.grey),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                  active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? Colors.white : Colors.grey.shade600)),
        ]),
      ),
    );
  }

  // ── Summary cards ──────────────────────────────────────────────────────────
  Widget _buildSummaryCards() {
    final txns = _filtered;
    final deposits    = txns.where((t) =>  t.isDeposit).fold(0.0, (s, t) => s + t.amount);
    final withdrawals = txns.where((t) => !t.isDeposit).fold(0.0, (s, t) => s + t.amount);

    return Row(children: [
      Expanded(child: _summaryCard(
        label: 'Deposits',
        value: 'TZS ${_fmt(deposits)}',
        icon: Icons.arrow_downward_rounded,
        color: const Color(0xFF2E7D32),
        bg: const Color(0xFFE8F5E9),
        count: txns.where((t) => t.isDeposit).length,
      )),
      const SizedBox(width: 12),
      Expanded(child: _summaryCard(
        label: 'Withdrawals',
        value: 'TZS ${_fmt(withdrawals)}',
        icon: Icons.arrow_upward_rounded,
        color: const Color(0xFFC62828),
        bg: const Color(0xFFFFEBEE),
        count: txns.where((t) => !t.isDeposit).length,
      )),
    ]);
  }

  Widget _summaryCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color bg,
    required int count,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 16),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(20)),
            child: Text('$count txns',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ),
        ]),
        const SizedBox(height: 12),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: -0.3),
            overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  // ── Transaction list ───────────────────────────────────────────────────────
  Widget _buildTransactionList() {
    final txns = _filtered;
    if (txns.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(children: [
            Icon(Icons.receipt_long_outlined,
                size: 52, color: Colors.grey.shade300),
            const SizedBox(height: 14),
            Text('No transactions found',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade400)),
            const SizedBox(height: 6),
            Text('Try changing the filter above',
                style:
                TextStyle(fontSize: 13, color: Colors.grey.shade400)),
          ]),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${txns.length} Transaction${txns.length == 1 ? '' : 's'}',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87)),
            Text(_selectedFund?.fundingName ?? '',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500)),
          ]),
          const SizedBox(height: 14),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: txns.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _buildTxnCard(txns[i]),
          ),
        ],
      ),
    );
  }

  Widget _buildTxnCard(_Txn t) {
    final color = t.isDeposit ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    final bgColor = t.isDeposit ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
    final icon = t.isDeposit
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;
    final sign = t.isDeposit ? '+' : '-';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(children: [
        // Icon
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),

        // Description + date
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.description,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.access_time_rounded,
                    size: 11, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(DateFormat('dd MMM yyyy • HH:mm').format(t.date),
                    style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                _miniPill('ID: ${t.id}', Colors.grey.shade100,
                    Colors.grey.shade500),
                const SizedBox(width: 6),
                _miniPill('${_fmt(t.units)} units', bgColor, color),
              ]),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // Amount
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('$sign TZS',
              style: TextStyle(
                  fontSize: 10,
                  color: color.withOpacity(0.7),
                  fontWeight: FontWeight.w600)),
          Text(_fmt(t.amount),
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: color)),
          const SizedBox(height: 4),
          Text('@${_fmt(t.price)}',
              style: TextStyle(fontSize: 10, color: Colors.grey[400])),
        ]),
      ]),
    );
  }

  Widget _miniPill(String label, Color bg, Color fg) => Container(
    padding:
    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(label,
        style: TextStyle(
            fontSize: 10, color: fg, fontWeight: FontWeight.w600)),
  );

  // ── Error ─────────────────────────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.red.shade50, shape: BoxShape.circle),
            child: Icon(Icons.cloud_off_outlined,
                color: Colors.red.shade400, size: 32),
          ),
          const SizedBox(height: 14),
          Text(_txnsError!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade400, fontSize: 14)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchTransactions,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0),
            child: const Text('Try Again'),
          ),
        ]),
      ),
    );
  }
}