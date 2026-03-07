import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../deposits/view/deposits.dart';
import '../funds/view/fund.dart';
import '../statement /client_statement.dart';
import '../withdrawal/view/withdrawal_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _isBalanceVisible = true;
  int _currentFundIndex = 0;
  final PageController _fundPageController = PageController();

  // ── Portfolio ──────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _funds = [];
  bool _isLoadingFunds = true;
  String? _fundsError;
  double _totalPortfolioValue = 0;
  String _cdsNumber = '';

  // ── Transactions ───────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoadingTxns = true;
  late AnimationController _chartFadeCtrl;
  late Animation<double> _chartFadeAnim;

  final List<Color> _cardColors = [
    const Color(0xFF1B5E20),
    const Color(0xFF1B5E20),
    const Color(0xFF1B5E20),
    const Color(0xFF1B5E20),
    const Color(0xFF1B5E20),
    const Color(0xFF1B5E20),
  ];

  final List<Map<String, dynamic>> _actions = [
    {'icon': Icons.account_balance_wallet_outlined, 'label': 'Deposit'},
    {'icon': Icons.monetization_on_outlined,        'label': 'Unit Prices'},
    {'icon': Icons.trending_down_outlined,           'label': 'Withdrawal'},
    {'icon': Icons.swap_horiz_outlined,              'label': 'Transfers'},
  ];

  @override
  void initState() {
    super.initState();
    _chartFadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _chartFadeAnim =
        CurvedAnimation(parent: _chartFadeCtrl, curve: Curves.easeOut);
    _fetchPortfolio();
  }

  @override
  void dispose() {
    _fundPageController.dispose();
    _chartFadeCtrl.dispose();
    super.dispose();
  }

  // ── API: Portfolio ─────────────────────────────────────────────────────────
  Future<void> _fetchPortfolio() async {
    setState(() { _isLoadingFunds = true; _fundsError = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      _cdsNumber = prefs.getString('cdsNumber') ?? '';

      final response = await http.post(
        Uri.parse('https://portaluat.tsl.co.tz/FMSAPI/home/GetFundsDetailed'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'APIUsername': 'User2',
          'APIPassword': 'CBZ1234#2',
          'cdsNumber': _cdsNumber,
        }),
      ).timeout(const Duration(seconds: 15));

      final json = jsonDecode(response.body);
      if (response.statusCode == 200 && json['status'] == 'success') {
        final data = json['data'];
        final List<dynamic> fundsRaw = data['funds'] ?? [];
        setState(() {
          _totalPortfolioValue =
              (data['totalPortfolioValue'] as num).toDouble();
          _funds = fundsRaw.map((f) => Map<String, dynamic>.from(f)).toList();
          _isLoadingFunds = false;
        });
        if (_funds.isNotEmpty) {
          _fetchTransactions(_funds[0]['fundName'] as String);
        }
      } else {
        setState(() {
          _fundsError = json['statusDesc'] ?? 'Failed to load portfolio';
          _isLoadingFunds = false;
        });
      }
    } catch (_) {
      setState(() {
        _fundsError = 'Connection error. Please try again.';
        _isLoadingFunds = false;
      });
    }
  }

  // ── API: Transactions ──────────────────────────────────────────────────────
  Future<void> _fetchTransactions(String fundName) async {
    setState(() { _isLoadingTxns = true; });
    try {
      final response = await http.post(
        Uri.parse('https://portaluat.tsl.co.tz/FMSAPI/home/GetTransactions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'APIUsername': 'User2',
          'APIPassword': 'CBZ1234#2',
          'cdsNumber':   _cdsNumber,
          'Fund':        fundName,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        final List<dynamic> raw =
            (data['data']['trans'] as List<dynamic>?) ?? [];

        final parsed = raw.map((j) {
          final desc = (j['Description'] as String? ?? '').toLowerCase();
          final isDeposit = desc.contains('deposit') ||
              desc.contains('credit') ||
              desc.contains('purchase');
          DateTime date;
          try {
            date = DateFormat('dd-MMM-yyyy HH:mm')
                .parse(j['TrxnDate'] as String? ?? '');
          } catch (_) {
            date = DateTime.now();
          }
          return {
            'type':   isDeposit ? 'Deposit' : 'Withdrawal',
            'amount': double.tryParse(j['amount']?.toString() ?? '0') ?? 0.0,
            'label':  j['Description'] as String? ?? '',
            'units':  double.tryParse(j['Units']?.toString() ?? '0') ?? 0.0,
            'date':   date,
            'id':     j['TrxnID']?.toString() ?? '',
          };
        }).toList()
          ..sort((a, b) =>
              (a['date'] as DateTime).compareTo(b['date'] as DateTime));

        setState(() {
          _transactions  = parsed;
          _isLoadingTxns = false;
        });
        _chartFadeCtrl..reset()..forward();
      } else {
        setState(() { _isLoadingTxns = false; });
      }
    } catch (_) {
      setState(() { _isLoadingTxns = false; });
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _fmt(double v, {int decimals = 2}) {
    final parts = v.toStringAsFixed(decimals).split('.');
    final formatted = parts[0]
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
    return decimals > 0 ? '$formatted.${parts[1]}' : formatted;
  }

  String _shortAmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  String _mask(String _) => '••••••••';
  Color  _cardColor(int i) => _cardColors[i % _cardColors.length];

  double get _totalDeposits => _transactions
      .where((t) => t['type'] == 'Deposit')
      .fold(0.0, (s, t) => s + (t['amount'] as double));
  double get _totalWithdrawals => _transactions
      .where((t) => t['type'] == 'Withdrawal')
      .fold(0.0, (s, t) => s + (t['amount'] as double));
  double get _maxY {
    if (_transactions.isEmpty) return 100;
    final amounts = _transactions.map((t) => t['amount'] as double).toList();
    return (amounts.reduce(max) * 1.3).ceilToDouble();
  }

  void _onActionTap(String label) {
    Widget? page;
    switch (label) {
      case 'Deposit':     page = const DepositPage(); break;
      case 'Unit Prices': page = const FundsScreen(); break;
      case 'Withdrawal':  page = const WithdrawalPage(); break;
      case 'Transfers':
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Transfers coming soon'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10))));
        return;
    }
    if (page != null) {
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page!));
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFB8E6D3), Color(0xFF98D8C8), Color(0xFFFFE5B4)],
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 20, 15, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                _buildPortfolioSection(),
                const SizedBox(height: 10),

                // Page dots
                if (!_isLoadingFunds && _fundsError == null && _funds.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_funds.length, (i) {
                      final active = i == _currentFundIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 20 : 8, height: 8,
                        decoration: BoxDecoration(
                          color: active ? Colors.green[700] : Colors.black26,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                const SizedBox(height: 14),

                // Actions
                Row(
                  children: List.generate(_actions.length, (i) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < _actions.length - 1 ? 10 : 0),
                      child: _buildActionButton(
                        icon:  _actions[i]['icon']  as IconData,
                        label: _actions[i]['label'] as String,
                        onTap: () => _onActionTap(_actions[i]['label'] as String),
                      ),
                    ),
                  )),
                ),

                const SizedBox(height: 12),

                _buildBuySellRow(),
                const SizedBox(height: 20),
                _buildTransactionsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Transactions section ───────────────────────────────────────────────────
  Widget _buildTransactionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ── Header ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Transactions',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => const ClientStatementPage())),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.green[700],
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.green.shade700.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3))
                    ],
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('See All',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w700)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 10, color: Colors.white),
                  ]),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Summary pills (only when data loaded) ───────────────────────
        if (!_isLoadingTxns && _transactions.isNotEmpty) ...[
          _buildSummaryPills(),
          const SizedBox(height: 14),
        ],

        // ── Full-width line chart ───────────────────────────────────────
        _buildLineChartCard(),
        const SizedBox(height: 16),

        // ── Latest 5 transactions list ──────────────────────────────────
        _buildRecentList(),
      ],
    );
  }

  // ── Summary pills ──────────────────────────────────────────────────────────
  Widget _buildSummaryPills() {
    final net        = _totalDeposits - _totalWithdrawals;
    final isPositive = net >= 0;
    return Row(children: [
      _summaryPill('Deposits',     'TZS ${_shortAmt(_totalDeposits)}',
          Icons.arrow_downward_rounded, const Color(0xFF2E7D32), const Color(0xFFE8F5E9)),
      const SizedBox(width: 10),
      _summaryPill('Withdrawals',  'TZS ${_shortAmt(_totalWithdrawals)}',
          Icons.arrow_upward_rounded,   const Color(0xFFC62828), const Color(0xFFFFEBEE)),
      const SizedBox(width: 10),
      _summaryPill('Net Flow',
          '${isPositive ? '+' : ''}TZS ${_shortAmt(net)}',
          isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
          isPositive ? const Color(0xFF1565C0) : const Color(0xFF6A1B9A),
          isPositive ? const Color(0xFFE3F2FD) : const Color(0xFFF3E5F5)),
    ]);
  }

  Widget _summaryPill(String label, String value, IconData icon, Color fg, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: fg.withOpacity(0.2), width: 1),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration:
            BoxDecoration(color: fg.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, size: 12, color: fg),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 9,
                      color: fg.withOpacity(0.7),
                      fontWeight: FontWeight.w500)),
              Text(value,
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w800, color: fg),
                  overflow: TextOverflow.ellipsis),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── Full-width Line Chart ──────────────────────────────────────────────────
  Widget _buildLineChartCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                  color: Colors.green[700]!.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(9)),
              child: Icon(Icons.show_chart_rounded,
                  color: Colors.green[700], size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Transaction Trend',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87)),
                    if (!_isLoadingTxns && _transactions.isNotEmpty)
                      Text('${_transactions.length} records · '
                          '${_funds.isNotEmpty ? _funds[_currentFundIndex]['fundName'] : ''}',
                          style:
                          TextStyle(fontSize: 10, color: Colors.grey[400])),
                  ]),
            ),
            // Legend
            _dot(Colors.green[600]!, 'In'),
            const SizedBox(width: 12),
            _dot(Colors.red[400]!, 'Out'),
          ]),

          const SizedBox(height: 16),

          // Chart
          SizedBox(
            height: 180,
            child: _isLoadingTxns
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.green)),
                  const SizedBox(height: 10),
                  Text('Loading chart data…',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[400])),
                ],
              ),
            )
                : _transactions.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart_outlined,
                      size: 40, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  Text('No transactions yet',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey[400])),
                ],
              ),
            )
                : FadeTransition(
              opacity: _chartFadeAnim,
              child: LineChart(_buildChartData()),
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _buildChartData() {
    final deposits = _transactions.asMap().entries
        .where((e) => e.value['type'] == 'Deposit').toList();
    final withdrawals = _transactions.asMap().entries
        .where((e) => e.value['type'] == 'Withdrawal').toList();

    return LineChartData(
      minY: 0,
      maxY: _maxY,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: _maxY / 4,
        getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.black.withOpacity(0.06),
            strokeWidth: 1,
            dashArray: [5, 5]),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                interval: _maxY / 4,
                getTitlesWidget: (v, _) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(_shortAmt(v),
                      style: const TextStyle(
                          fontSize: 9, color: Colors.black38)),
                ))),
        bottomTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true,
                interval: max(
                    1.0, (_transactions.length / 4).floorToDouble()),
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= _transactions.length)
                    return const SizedBox.shrink();
                  final date = _transactions[idx]['date'] as DateTime;
                  return Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(DateFormat('dd/MM').format(date),
                        style: const TextStyle(
                            fontSize: 9, color: Colors.black38)),
                  );
                })),
        topTitles:
        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => const Color(0xFF1B5E20),
          tooltipBorderRadius: BorderRadius.circular(10),
          getTooltipItems: (spots) => spots
              .map((s) => LineTooltipItem(
            'TZS ${_shortAmt(s.y)}',
            const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700),
          ))
              .toList(),
        ),
      ),
      lineBarsData: [
        _lineBar(deposits,    Colors.green[600]!),
        _lineBar(withdrawals, Colors.red[400]!),
      ],
    );
  }

  LineChartBarData _lineBar(
      List<MapEntry<int, Map<String, dynamic>>> entries, Color color) {
    return LineChartBarData(
      spots: entries
          .map((e) => FlSpot(
          e.key.toDouble(), e.value['amount'] as double))
          .toList(),
      isCurved: true,
      curveSmoothness: 0.35,
      color: color,
      barWidth: 2.5,
      dotData: FlDotData(
          show: entries.length <= 10,
          getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
              radius: 3.5,
              color: Colors.white,
              strokeColor: color,
              strokeWidth: 2)),
      belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
              colors: [color.withOpacity(0.18), color.withOpacity(0.0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter)),
    );
  }

  // ── Recent list ────────────────────────────────────────────────────────────
  Widget _buildRecentList() {
    if (_isLoadingTxns || _transactions.isEmpty) return const SizedBox.shrink();

    final recent = _transactions.reversed.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('Latest Activity',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black54)),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.62),
            borderRadius: BorderRadius.circular(20),
            border:
            Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recent.length,
            separatorBuilder: (_, __) => Divider(
                height: 1,
                color: Colors.black.withOpacity(0.05),
                indent: 66),
            itemBuilder: (_, i) => _buildTxnRow(recent[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildTxnRow(Map<String, dynamic> txn) {
    final isDeposit = txn['type'] == 'Deposit';
    final color  = isDeposit ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    final bgColor = isDeposit ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
    final icon   = isDeposit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    final amount = txn['amount'] as double;
    final date   = txn['date'] as DateTime;
    final label  = txn['label'] as String;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text(DateFormat('dd MMM yyyy').format(date),
                style: TextStyle(fontSize: 11, color: Colors.grey[400])),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${isDeposit ? '+' : '-'} TZS',
              style: TextStyle(
                  fontSize: 9,
                  color: color.withOpacity(0.6),
                  fontWeight: FontWeight.w600)),
          Text(_fmt(amount),
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: color)),
        ]),
      ]),
    );
  }

  // ── Portfolio section ──────────────────────────────────────────────────────
  Widget _buildPortfolioSection() {
    if (_isLoadingFunds) {
      return _blankCard(
        height: 175,
        color: const Color(0xFF1B5E20),
        child: const Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                    color: Colors.white54, strokeWidth: 2),
                SizedBox(height: 12),
                Text('Loading portfolio…',
                    style: TextStyle(color: Colors.white54, fontSize: 13)),
              ]),
        ),
      );
    }
    if (_fundsError != null) {
      return _blankCard(
        height: 175,
        color: const Color(0xFF1B5E20),
        child: Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_outlined,
                    color: Colors.white54, size: 28),
                const SizedBox(height: 8),
                Text(_fundsError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _fetchPortfolio,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 7),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white30)),
                    child: const Text('Retry',
                        style: TextStyle(
                            color: Colors.white, fontSize: 13)),
                  ),
                ),
              ]),
        ),
      );
    }
    return SizedBox(
      height: 175,
      child: PageView.builder(
        controller: _fundPageController,
        itemCount: _funds.length,
        onPageChanged: (i) {
          setState(() => _currentFundIndex = i);
          _fetchTransactions(_funds[i]['fundName'] as String);
        },
        itemBuilder: (_, i) => _buildFundCard(_funds[i], i),
      ),
    );
  }

  Widget _blankCard(
      {required Widget child, required Color color, double height = 175}) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [color, color.withOpacity(0.75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 14,
              offset: const Offset(0, 6))
        ],
      ),
      child: child,
    );
  }

  // ── Fund card ──────────────────────────────────────────────────────────────
  Widget _buildFundCard(Map<String, dynamic> fund, int index) {
    final baseColor    = _cardColor(index);
    final portfolioVal = (fund['portfolioValue'] as num).toDouble();
    final units        = (fund['investorUnits']  as num).toDouble();
    final nav          = (fund['nav']            as num).toDouble();
    final status       = fund['status'] as String;
    final hasInvestment = portfolioVal > 0;

    Color statusColor;
    IconData statusIcon;
    switch (status.toLowerCase()) {
      case 'active':
        statusColor = const Color(0xFF69F0AE);
        statusIcon  = Icons.check_circle_outline;
        break;
      case 'ipo':
        statusColor = const Color(0xFFFFD740);
        statusIcon  = Icons.new_releases_outlined;
        break;
      default:
        statusColor = Colors.white38;
        statusIcon  = Icons.info_outline;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [baseColor, baseColor.withOpacity(0.72)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: baseColor.withOpacity(0.45),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Stack(children: [
        Positioned(right: -20, top: -20, child: _circle(110, 0.05)),
        Positioned(right: 40,  bottom: -25, child: _circle(70, 0.04)),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24, width: 1)),
                  child: Text(fund['fundCode'] as String,
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white70,
                          letterSpacing: 0.5)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fund['fundName'] as String,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.1),
                            overflow: TextOverflow.ellipsis),
                        Text(fund['description'] as String,
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.white.withOpacity(0.55))),
                      ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: statusColor.withOpacity(0.4), width: 1)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(statusIcon, size: 9, color: statusColor),
                    const SizedBox(width: 4),
                    Text(status,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: statusColor)),
                  ]),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () =>
                      setState(() => _isBalanceVisible = !_isBalanceVisible),
                  child: Icon(
                      _isBalanceVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.white38,
                      size: 17),
                ),
              ]),
              const Spacer(),
              Row(children: [
                Expanded(
                    flex: 5,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Portfolio Value',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white.withOpacity(0.5),
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          hasInvestment
                              ? Text(
                              _isBalanceVisible
                                  ? 'TZS ${_fmt(portfolioVal)}'
                                  : _mask(''),
                              style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.3))
                              : Text('Not invested yet',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.4),
                                  fontStyle: FontStyle.italic)),
                        ])),
                _vDivider(),
                Expanded(
                    flex: 3,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('My Units',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white.withOpacity(0.5),
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text(
                              _isBalanceVisible ? _fmt(units) : _mask(''),
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ])),
                _vDivider(),
                Expanded(
                    flex: 3,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NAV',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white.withOpacity(0.5),
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text(_fmt(nav),
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ])),
              ]),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _circle(double size, double opacity) => Container(
      width: size, height: size,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(opacity)));

  Widget _vDivider() => Container(
      width: 1, height: 34, color: Colors.white12,
      margin: const EdgeInsets.symmetric(horizontal: 10));

  // ── Buy / Sell ─────────────────────────────────────────────────────────────
  Widget _buildBuySellRow() {
    return Row(children: [
      Expanded(child: _gradBtn('BUY', Icons.trending_up_rounded,
          [Colors.green.shade500, Colors.green.shade700],
          Colors.green.shade700, 'Buy order coming soon')),
      const SizedBox(width: 12),
      Expanded(child: _gradBtn('SELL', Icons.trending_down_rounded,
          [Colors.red.shade400, Colors.red.shade700],
          Colors.red.shade600, 'Sell order coming soon')),
    ]);
  }

  Widget _gradBtn(String label, IconData icon, List<Color> colors,
      Color shadow, String snack) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(snack),
          behavior: SnackBarBehavior.floating,
          backgroundColor: colors.last,
          duration: const Duration(seconds: 1),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)))),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: shadow.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5)),
        ]),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 78,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.35),
          borderRadius: BorderRadius.circular(14),
          border:
          Border.all(color: Colors.white.withOpacity(0.6), width: 1),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(11)),
              child: Icon(icon, color: Colors.black87, size: 19)),
          const SizedBox(height: 6),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 10,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  height: 1.2)),
        ]),
      ),
    );
  }

  Widget _dot(Color color, String label) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 8, height: 8,
            decoration:
            BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(fontSize: 10, color: Colors.black54)),
      ]);
}