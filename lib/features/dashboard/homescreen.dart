import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../deposits/view/deposits.dart';
import '../funds/view/fund.dart';
import '../withdrawal/view/withdrawal_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isBalanceVisible = true;
  int _currentFundIndex = 0;
  final PageController _fundPageController = PageController();

  // ── Portfolio state ────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _funds = [];
  bool _isLoadingFunds = true;
  String? _fundsError;
  double _totalPortfolioValue = 0;
  String _cdsNumber = '';

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

  final List<Map<String, dynamic>> _transactions = [
    {'type': 'Withdrawal', 'amount': 12400.00, 'label': 'Unit Transfer', 'date': '09 Sep', 'status': 'Success'},
    {'type': 'Deposit',    'amount': 50000.00, 'label': 'Fund Deposit',  'date': '10 Sep', 'status': 'Success'},
    {'type': 'Withdrawal', 'amount': 2400.00,  'label': 'Unit Transfer', 'date': '11 Sep', 'status': 'Success'},
    {'type': 'Deposit',    'amount': 30000.00, 'label': 'Fund Deposit',  'date': '12 Sep', 'status': 'Success'},
    {'type': 'Withdrawal', 'amount': 9000.00,  'label': 'Unit Transfer', 'date': '13 Sep', 'status': 'Success'},
    {'type': 'Deposit',    'amount': 15000.00, 'label': 'Fund Deposit',  'date': '14 Sep', 'status': 'Success'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchPortfolio();
  }

  @override
  void dispose() {
    _fundPageController.dispose();
    super.dispose();
  }

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

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == 'success') {
          final data = json['data'];
          final List<dynamic> funds = data['funds'] ?? [];
          setState(() {
            _totalPortfolioValue = (data['totalPortfolioValue'] as num).toDouble();
            _funds = funds.map((f) => Map<String, dynamic>.from(f)).toList();
            _isLoadingFunds = false;
          });
        } else {
          setState(() { _fundsError = json['statusDesc'] ?? 'Failed to load portfolio'; _isLoadingFunds = false; });
        }
      } else {
        setState(() { _fundsError = 'Server error: ${response.statusCode}'; _isLoadingFunds = false; });
      }
    } catch (e) {
      setState(() { _fundsError = 'Connection error. Please try again.'; _isLoadingFunds = false; });
    }
  }

  String _fmt(double v, {int decimals = 2}) {
    final parts = v.toStringAsFixed(decimals).split('.');
    final formatted = parts[0].replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
    return decimals > 0 ? '$formatted.${parts[1]}' : formatted;
  }

  String _formatNumber(String raw) {
    try {
      final double value = double.parse(raw);
      final parts = value.toStringAsFixed(2).split('.');
      final formatted = parts[0].replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
      return '$formatted.${parts[1]}';
    } catch (_) { return raw; }
  }

  String _mask(String _) => '••••••••';
  Color _cardColor(int i) => _cardColors[i % _cardColors.length];

  void _onActionTap(String label) {
    Widget? page;
    switch (label) {
      case 'Deposit':     page = const DepositPage(); break;
      case 'Unit Prices': page = const FundsScreen(); break;
      case 'Withdrawal':  page = const WithdrawalPage(); break;
      case 'Transfers':
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Transfers coming soon'),
            behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
        return;
    }
    if (page != null) Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page!));
  }

  double get _totalDeposits    => _transactions.where((t) => t['type'] == 'Deposit').fold(0.0, (s, t) => s + (t['amount'] as double));
  double get _totalWithdrawals => _transactions.where((t) => t['type'] == 'Withdrawal').fold(0.0, (s, t) => s + (t['amount'] as double));
  double get _maxY { final amounts = _transactions.map((t) => t['amount'] as double).toList(); return (amounts.reduce(max) * 1.3).ceilToDouble(); }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFFB8E6D3), Color(0xFF98D8C8), Color(0xFFFFE5B4)],
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 20, 15, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ── Portfolio cards ────────────────────────────────────────
              _buildPortfolioSection(),
              const SizedBox(height: 10),

              // ── Page dots ──────────────────────────────────────────────
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

              // ── Actions ────────────────────────────────────────────────
              Row(
                children: List.generate(_actions.length, (i) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < _actions.length - 1 ? 10 : 0),
                    child: _buildActionButton(
                      icon: _actions[i]['icon'] as IconData,
                      label: _actions[i]['label'] as String,
                      onTap: () => _onActionTap(_actions[i]['label'] as String),
                    ),
                  ),
                )),
              ),

              const SizedBox(height: 12),

              // ── Buy / Sell ─────────────────────────────────────────────
              _buildBuySellRow(),

              const SizedBox(height: 18),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  Text('See All', style: TextStyle(fontSize: 14, color: Colors.green[700], fontWeight: FontWeight.w600)),
                ]),
              ),
              const SizedBox(height: 16),

              SizedBox(
                height: 340,
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Expanded(child: _buildLineChartCard()),
                  const SizedBox(width: 10),
                  Expanded(child: _buildPieChartCard()),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Portfolio section ──────────────────────────────────────────────────────
  Widget _buildPortfolioSection() {
    if (_isLoadingFunds) {
      return _blankCard(
        height: 175,
        child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircularProgressIndicator(color: Colors.white54, strokeWidth: 2),
          SizedBox(height: 12),
          Text('Loading portfolio…', style: TextStyle(color: Colors.white54, fontSize: 13)),
        ])),
        color: const Color(0xFF1B5E20),
      );
    }

    if (_fundsError != null) {
      return _blankCard(
        height: 175,
        color: const Color(0xFF1B5E20),
        child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.cloud_off_outlined, color: Colors.white54, size: 28),
          const SizedBox(height: 8),
          Text(_fundsError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _fetchPortfolio,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white30)),
              child: const Text('Retry', style: TextStyle(color: Colors.white, fontSize: 13)),
            ),
          ),
        ])),
      );
    }

    return SizedBox(
      height: 175,
      child: PageView.builder(
        controller: _fundPageController,
        itemCount: _funds.length,
        onPageChanged: (i) => setState(() => _currentFundIndex = i),
        itemBuilder: (_, i) => _buildFundCard(_funds[i], i),
      ),
    );
  }

  Widget _blankCard({required Widget child, required Color color, double height = 175}) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(0.75)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: child,
    );
  }

  // ── Per-fund card ──────────────────────────────────────────────────────────
  Widget _buildFundCard(Map<String, dynamic> fund, int index) {
    final baseColor     = _cardColor(index);
    final portfolioVal  = (fund['portfolioValue'] as num).toDouble();
    final units         = (fund['investorUnits'] as num).toDouble();
    final nav           = (fund['nav'] as num).toDouble();
    final status        = fund['status'] as String;
    final hasInvestment = portfolioVal > 0;

    Color statusColor;
    IconData statusIcon;
    switch (status.toLowerCase()) {
      case 'active': statusColor = const Color(0xFF69F0AE); statusIcon = Icons.check_circle_outline; break;
      case 'ipo':    statusColor = const Color(0xFFFFD740); statusIcon = Icons.new_releases_outlined; break;
      default:       statusColor = Colors.white38;          statusIcon = Icons.info_outline;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [baseColor, baseColor.withOpacity(0.72)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: baseColor.withOpacity(0.45), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Stack(children: [
        // Decorative circles
        Positioned(right: -20, top: -20, child: _circle(110, 0.05)),
        Positioned(right: 40, bottom: -25, child: _circle(70, 0.04)),

        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Header row ───────────────────────────────────────────────
            Row(children: [
              // Fund code badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: Text(fund['fundCode'] as String,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white70, letterSpacing: 0.5)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(fund['fundName'] as String,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.1),
                      overflow: TextOverflow.ellipsis),
                  Text(fund['description'] as String,
                      style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.55))),
                ]),
              ),
              // Status chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.4), width: 1),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(statusIcon, size: 9, color: statusColor),
                  const SizedBox(width: 4),
                  Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
                ]),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _isBalanceVisible = !_isBalanceVisible),
                child: Icon(_isBalanceVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: Colors.white38, size: 17),
              ),
            ]),

            const Spacer(),

            // ── Stats row ─────────────────────────────────────────────────
            Row(children: [
              // Portfolio value
              Expanded(flex: 5, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Portfolio Value', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                hasInvestment
                    ? Text(
                  _isBalanceVisible ? 'TZS ${_fmt(portfolioVal)}' : _mask(''),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.3),
                )
                    : Text('Not invested yet',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4), fontStyle: FontStyle.italic)),
              ])),

              _vDivider(),

              // Units
              Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('My Units', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(_isBalanceVisible ? _fmt(units) : _mask(''),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
              ])),

              _vDivider(),

              // NAV
              Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('NAV', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(_fmt(nav), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
              ])),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _circle(double size, double opacity) => Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(opacity)));

  Widget _vDivider() => Container(width: 1, height: 34, color: Colors.white12,
      margin: const EdgeInsets.symmetric(horizontal: 10));

  // ── Buy / Sell ─────────────────────────────────────────────────────────────
  Widget _buildBuySellRow() {
    return Row(children: [
      Expanded(child: _gradBtn('BUY', Icons.trending_up_rounded,
          [Colors.green.shade500, Colors.green.shade700], Colors.green.shade700, 'Buy order coming soon')),
      const SizedBox(width: 12),
      Expanded(child: _gradBtn('SELL', Icons.trending_down_rounded,
          [Colors.red.shade400, Colors.red.shade700], Colors.red.shade600, 'Sell order coming soon')),
    ]);
  }

  Widget _gradBtn(String label, IconData icon, List<Color> colors, Color shadow, String snack) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(snack), behavior: SnackBarBehavior.floating,
          backgroundColor: colors.last, duration: const Duration(seconds: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: shadow.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        ]),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 78,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.6), width: 1),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 38, height: 38,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(11)),
              child: Icon(icon, color: Colors.black87, size: 19)),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Colors.black87, fontWeight: FontWeight.w600, height: 1.2)),
        ]),
      ),
    );
  }

  // ── Charts (unchanged) ─────────────────────────────────────────────────────
  Widget _buildLineChartCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55), borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(color: Colors.green[700]!.withOpacity(0.12), borderRadius: BorderRadius.circular(7)),
              child: Icon(Icons.show_chart_rounded, color: Colors.green[700], size: 14)),
          const SizedBox(width: 6),
          const Expanded(child: Text('Trend', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87))),
          Text('${_transactions.length} txns', style: TextStyle(fontSize: 10, color: Colors.green[700], fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 10),
        SizedBox(height: 150, child: LineChart(LineChartData(
          minY: 0, maxY: _maxY,
          gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: _maxY / 3,
              getDrawingHorizontalLine: (_) => FlLine(color: Colors.black.withOpacity(0.07), strokeWidth: 1, dashArray: [4, 4])),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 34, interval: _maxY / 3,
                getTitlesWidget: (v, _) => Text(_shortAmt(v), style: const TextStyle(fontSize: 8, color: Colors.black45)))),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 2,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= _transactions.length || idx % 2 != 0) return const SizedBox.shrink();
                  return Padding(padding: const EdgeInsets.only(top: 4),
                      child: Text((_transactions[idx]['date'] as String).split(' ').first,
                          style: const TextStyle(fontSize: 8, color: Colors.black45)));
                })),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineTouchData: LineTouchData(touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => Colors.green[800]!,
              getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                  _shortAmt(s.y), const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600))).toList())),
          lineBarsData: [
            _lineBar(_transactions.asMap().entries.where((e) => e.value['type'] == 'Deposit').toList(), Colors.green[600]!),
            _lineBar(_transactions.asMap().entries.where((e) => e.value['type'] == 'Withdrawal').toList(), Colors.red[400]!),
          ],
        ))),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _dot(Colors.green[600]!, 'In'), const SizedBox(width: 12), _dot(Colors.red[400]!, 'Out'),
        ]),
      ]),
    );
  }

  LineChartBarData _lineBar(List<MapEntry<int, Map<String, dynamic>>> entries, Color color) {
    return LineChartBarData(
      spots: entries.map((e) => FlSpot(e.key.toDouble(), e.value['amount'] as double)).toList(),
      isCurved: true, color: color, barWidth: 2,
      dotData: FlDotData(show: true, getDotPainter: (_, __, ___, ____) =>
          FlDotCirclePainter(radius: 3, color: Colors.white, strokeColor: color, strokeWidth: 1.5)),
      belowBarData: BarAreaData(show: true, gradient: LinearGradient(
          colors: [color.withOpacity(0.2), color.withOpacity(0.0)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter)),
    );
  }

  Widget _buildPieChartCard() {
    final total = _totalDeposits + _totalWithdrawals;
    final dPct  = total == 0 ? 0.0 : (_totalDeposits    / total * 100);
    final wPct  = total == 0 ? 0.0 : (_totalWithdrawals / total * 100);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55), borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(color: Colors.blue[700]!.withOpacity(0.12), borderRadius: BorderRadius.circular(7)),
              child: Icon(Icons.pie_chart_outline_rounded, color: Colors.blue[700], size: 14)),
          const SizedBox(width: 6),
          const Expanded(child: Text('Breakdown', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87))),
        ]),
        const SizedBox(height: 8),
        SizedBox(height: 120, child: PieChart(PieChartData(
          startDegreeOffset: -90, sectionsSpace: 3, centerSpaceRadius: 24,
          sections: [
            PieChartSectionData(value: _totalDeposits,    color: Colors.green[500], radius: 30,
                title: '${dPct.toStringAsFixed(0)}%', titlePositionPercentageOffset: 0.6,
                titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
            PieChartSectionData(value: _totalWithdrawals, color: Colors.red[400],   radius: 30,
                title: '${wPct.toStringAsFixed(0)}%', titlePositionPercentageOffset: 0.6,
                titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ))),
        const SizedBox(height: 10),
        _pieStat('Deposits',    _totalDeposits,    _transactions.where((t) => t['type'] == 'Deposit').length,    Colors.green[500]!),
        const SizedBox(height: 8),
        _pieStat('Withdrawals', _totalWithdrawals, _transactions.where((t) => t['type'] == 'Withdrawal').length, Colors.red[400]!),
        const SizedBox(height: 10),
        ClipRRect(borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: total == 0 ? 0 : (_totalDeposits / total).clamp(0.0, 1.0),
                minHeight: 5, backgroundColor: Colors.red[100],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green[500]!))),
      ]),
    );
  }

  Widget _dot(Color color, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 5),
    Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
  ]);

  Widget _pieStat(String label, double amount, int count, Color color) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w500)),
        ]),
        const SizedBox(height: 3),
        Text('TZS ${_formatNumber(amount.toStringAsFixed(0))}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
        Text('$count transaction${count == 1 ? '' : 's'}',
            style: const TextStyle(fontSize: 10, color: Colors.black38)),
      ]);

  String _shortAmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}