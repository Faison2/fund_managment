import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import '../deposits/view/deposits.dart';
import '../funds/view/fund.dart';
import '../withdrawal/view/withdrawal_page.dart';
import '../payments/view/payment.dart' as payment_view;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isBalanceVisible = true;
  int _currentFundIndex = 0;
  final PageController _fundPageController = PageController();

  // ── API state ──────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _funds = [];
  bool _isLoadingFunds = true;
  String? _fundsError;

  // ── Action buttons ─────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _actions = [
    {'icon': Icons.account_balance_wallet_outlined, 'label': 'Deposit'},
    {'icon': Icons.monetization_on_outlined,        'label': 'Unit Prices'},
    {'icon': Icons.trending_down_outlined,           'label': 'Withdrawal'},
    {'icon': Icons.swap_horiz_outlined,              'label': 'Transfers'},
    {'icon': Icons.library_add_outlined,             'label': 'Fund\nSubscription'},
    {'icon': Icons.credit_card_outlined,             'label': 'Payment\nMethods'},
  ];

  // ── Recent transactions ────────────────────────────────────────────────────
  // Each entry has: type ('Deposit' | 'Withdrawal'), amount (double), label, date
  final List<Map<String, dynamic>> _transactions = [
    {
      'type': 'Withdrawal',
      'amount': 12400.00,
      'label': 'Unit Transfer',
      'date': '09 Sep',
      'status': 'Success',
    },
    {
      'type': 'Deposit',
      'amount': 50000.00,
      'label': 'Fund Deposit',
      'date': '10 Sep',
      'status': 'Success',
    },
    {
      'type': 'Withdrawal',
      'amount': 2400.00,
      'label': 'Unit Transfer',
      'date': '11 Sep',
      'status': 'Success',
    },
    {
      'type': 'Deposit',
      'amount': 30000.00,
      'label': 'Fund Deposit',
      'date': '12 Sep',
      'status': 'Success',
    },
    {
      'type': 'Withdrawal',
      'amount': 9000.00,
      'label': 'Unit Transfer',
      'date': '13 Sep',
      'status': 'Success',
    },
    {
      'type': 'Deposit',
      'amount': 15000.00,
      'label': 'Fund Deposit',
      'date': '14 Sep',
      'status': 'Success',
    },
  ];

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fetchFunds();
  }

  @override
  void dispose() {
    _fundPageController.dispose();
    super.dispose();
  }

  // ── API call ───────────────────────────────────────────────────────────────
  Future<void> _fetchFunds() async {
    setState(() {
      _isLoadingFunds = true;
      _fundsError = null;
    });

    try {
      final response = await http.post(
        Uri.parse('https://portaluat.tsl.co.tz/FMSAPI/Home/GetFunds'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'APIUsername': 'User2',
          'APIPassword': 'CBZ1234#2',
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);

        if (json['status'] == 'success') {
          final List<dynamic> data = json['data'] as List<dynamic>;

          setState(() {
            _funds = data.map((item) {
              final rawUnits = item['Units']?.toString() ?? '0';
              final formattedUnits = _formatNumber(rawUnits);

              return {
                'name': item['fundingName'] ?? 'Unknown Fund',
                'currency': 'TZS',
                'units': formattedUnits,
                'description': item['description'] ?? '',
                'fundingCode': item['fundingCode'] ?? '',
                'status': item['status'] ?? '',
                'value': 'N/A',
              };
            }).toList();

            _isLoadingFunds = false;
          });
        } else {
          setState(() {
            _fundsError = json['statusDesc'] ?? 'Failed to load funds.';
            _isLoadingFunds = false;
          });
        }
      } else {
        setState(() {
          _fundsError = 'Server error: ${response.statusCode}';
          _isLoadingFunds = false;
        });
      }
    } catch (e) {
      setState(() {
        _fundsError = 'Connection error. Please try again.';
        _isLoadingFunds = false;
      });
    }
  }

  String _formatNumber(String raw) {
    try {
      final double value = double.parse(raw);
      final parts = value.toStringAsFixed(2).split('.');
      final intPart = parts[0];
      final decPart = parts[1];
      final formatted = intPart.replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'),
            (m) => '${m[1]},',
      );
      return '$formatted.$decPart';
    } catch (_) {
      return raw;
    }
  }

  String _mask(String value) => '•' * 9;

  void _onActionTap(String label) {
    Widget? targetPage;

    switch (label) {
      case 'Deposit':
        targetPage = const DepositPage();
        break;
      case 'Unit Prices':
        targetPage = const FundsScreen();
        break;
      case 'Withdrawal':
        targetPage = const WithdrawalPage();
        break;
      case 'Transfers':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Transfers page coming soon'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        return;
      case 'Fund\nSubscription':
        targetPage = const FundsScreen();
        break;
      case 'Payment\nMethods':
        targetPage = const payment_view.PaymentMethodsPage();
        break;
    }

    if (targetPage != null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (context) => targetPage!),
      );
    }
  }

  // ── Chart helpers ──────────────────────────────────────────────────────────

  /// Total deposits amount
  double get _totalDeposits => _transactions
      .where((t) => t['type'] == 'Deposit')
      .fold(0.0, (sum, t) => sum + (t['amount'] as double));

  /// Total withdrawals amount
  double get _totalWithdrawals => _transactions
      .where((t) => t['type'] == 'Withdrawal')
      .fold(0.0, (sum, t) => sum + (t['amount'] as double));

  /// Line chart spots — one point per transaction (x = index, y = amount)
  List<FlSpot> get _lineSpots => List.generate(
    _transactions.length,
        (i) => FlSpot(i.toDouble(), _transactions[i]['amount'] as double),
  );

  /// Max y value for line chart scaling
  double get _maxY {
    final amounts = _transactions.map((t) => t['amount'] as double).toList();
    return (amounts.reduce(max) * 1.3).ceilToDouble();
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFB8E6D3),
              Color(0xFF98D8C8),
              Color(0xFFFFE5B4),
            ],
          ),
         // borderRadius: BorderRadius.circular(25),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 20, 15, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Fund PageView / Loading / Error ─────────────────────────
                SizedBox(
                  height: 150,
                  child: _buildFundSection(),
                ),

                const SizedBox(height: 10),

                // ── Page dots ───────────────────────────────────────────────
                if (!_isLoadingFunds && _fundsError == null && _funds.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_funds.length, (i) {
                      final active = i == _currentFundIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active ? Colors.green[700] : Colors.black26,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                const SizedBox(height: 10),

                _buildActionGrid(),

                const SizedBox(height: 18),

                // ── Recent Transactions section ──────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                  decoration: BoxDecoration(
                   // color: Colors.white.withValues(alpha: 0.15),
                   // borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Recent Transactions',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              'See All',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Two chart cards side by side ───────────────────────
                      SizedBox(
                        height: 340,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: _buildLineChartCard()),
                            const SizedBox(width: 10),
                            Expanded(child: _buildPieChartCard()),
                          ],
                        ),
                      ),

                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Line chart card ────────────────────────────────────────────────────────
  Widget _buildLineChartCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.green[700]!.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(Icons.show_chart_rounded,
                    color: Colors.green[700], size: 14),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Trend',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              Text(
                '${_transactions.length} txns',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.green[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Line chart — fixed height
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: _maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _maxY / 3,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.black.withOpacity(0.07),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      interval: _maxY / 3,
                      getTitlesWidget: (value, _) => Text(
                        _shortAmount(value),
                        style: const TextStyle(
                            fontSize: 8, color: Colors.black45),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 ||
                            idx >= _transactions.length ||
                            idx % 2 != 0) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            (_transactions[idx]['date'] as String)
                                .split(' ')
                                .first,
                            style: const TextStyle(
                                fontSize: 8, color: Colors.black45),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => Colors.green[800]!,
                    getTooltipItems: (spots) => spots
                        .map(
                          (s) => LineTooltipItem(
                        _shortAmount(s.y),
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                        .toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: _transactions
                        .asMap()
                        .entries
                        .where((e) => e.value['type'] == 'Deposit')
                        .map((e) => FlSpot(
                      e.key.toDouble(),
                      e.value['amount'] as double,
                    ))
                        .toList(),
                    isCurved: true,
                    color: Colors.green[600],
                    barWidth: 2,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 3,
                        color: Colors.white,
                        strokeColor: Colors.green[600]!,
                        strokeWidth: 1.5,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.green[400]!.withOpacity(0.22),
                          Colors.green[400]!.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  LineChartBarData(
                    spots: _transactions
                        .asMap()
                        .entries
                        .where((e) => e.value['type'] == 'Withdrawal')
                        .map((e) => FlSpot(
                      e.key.toDouble(),
                      e.value['amount'] as double,
                    ))
                        .toList(),
                    isCurved: true,
                    color: Colors.red[400],
                    barWidth: 2,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 3,
                        color: Colors.white,
                        strokeColor: Colors.red[400]!,
                        strokeWidth: 1.5,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.red[300]!.withOpacity(0.15),
                          Colors.red[300]!.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(Colors.green[600]!, 'In'),
              const SizedBox(width: 12),
              _legendDot(Colors.red[400]!, 'Out'),
            ],
          ),
        ],
      ),
    );
  }

  // ── Pie chart card ─────────────────────────────────────────────────────────
  Widget _buildPieChartCard() {
    final total = _totalDeposits + _totalWithdrawals;
    final depositPct = total == 0 ? 0.0 : (_totalDeposits / total * 100);
    final withdrawalPct = total == 0 ? 0.0 : (_totalWithdrawals / total * 100);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Card header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.blue[700]!.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(Icons.pie_chart_outline_rounded,
                    color: Colors.blue[700], size: 14),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Breakdown',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Pie chart — fixed height so it never overflows
          SizedBox(
            height: 120,
            child: PieChart(
              PieChartData(
                startDegreeOffset: -90,
                sectionsSpace: 3,
                centerSpaceRadius: 24,
                sections: [
                  PieChartSectionData(
                    value: _totalDeposits,
                    color: Colors.green[500],
                    radius: 30,
                    title: '${depositPct.toStringAsFixed(0)}%',
                    titlePositionPercentageOffset: 0.6,
                    titleStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: _totalWithdrawals,
                    color: Colors.red[400],
                    radius: 30,
                    title: '${withdrawalPct.toStringAsFixed(0)}%',
                    titlePositionPercentageOffset: 0.6,
                    titleStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
                pieTouchData: PieTouchData(enabled: true),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Stats — stacked below pie
          _pieStat(
            label: 'Deposits',
            amount: _totalDeposits,
            count: _transactions.where((t) => t['type'] == 'Deposit').length,
            color: Colors.green[500]!,
          ),
          const SizedBox(height: 8),
          _pieStat(
            label: 'Withdrawals',
            amount: _totalWithdrawals,
            count:
            _transactions.where((t) => t['type'] == 'Withdrawal').length,
            color: Colors.red[400]!,
          ),
          const SizedBox(height: 10),

          // Net bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total == 0
                  ? 0
                  : (_totalDeposits / total).clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: Colors.red[100],
              valueColor:
              AlwaysStoppedAnimation<Color>(Colors.green[500]!),
            ),
          ),
        ],
      ),
    );
  }

  // ── Legend dot ─────────────────────────────────────────────────────────────
  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }

  // ── Pie stat row ───────────────────────────────────────────────────────────
  Widget _pieStat({
    required String label,
    required double amount,
    required int count,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          'TZS ${_formatNumber(amount.toStringAsFixed(0))}',
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black87),
        ),
        Text(
          '$count transaction${count == 1 ? '' : 's'}',
          style: const TextStyle(fontSize: 10, color: Colors.black38),
        ),
      ],
    );
  }

  // ── Short amount label (e.g. 50000 → "50K") ───────────────────────────────
  String _shortAmount(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toStringAsFixed(0);
  }

  // ── Fund section ───────────────────────────────────────────────────────────
  Widget _buildFundSection() {
    if (_isLoadingFunds) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.35),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.green),
              SizedBox(height: 12),
              Text('Loading funds…', style: TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      );
    }

    if (_fundsError != null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.35),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_outlined, color: Colors.red, size: 28),
              const SizedBox(height: 8),
              Text(
                _fundsError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _fetchFunds,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.green[700],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return PageView.builder(
      controller: _fundPageController,
      itemCount: _funds.length,
      onPageChanged: (i) => setState(() => _currentFundIndex = i),
      itemBuilder: (context, index) => _buildFundCard(_funds[index]),
    );
  }

  // ── Fund card ──────────────────────────────────────────────────────────────
  Widget _buildFundCard(Map<String, dynamic> fund) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  fund['name'],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: () =>
                    setState(() => _isBalanceVisible = !_isBalanceVisible),
                child: Icon(
                  _isBalanceVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.black54,
                  size: 20,
                ),
              ),
            ],
          ),
          if ((fund['description'] as String).isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              fund['description'],
              style: TextStyle(fontSize: 11, color: Colors.green[700]),
            ),
          ],
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Units',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isBalanceVisible
                          ? fund['units']
                          : _mask(fund['units']),
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                  ],
                ),
              ),
              Container(
                height: 36,
                width: 1,
                color: Colors.black12,
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Value (${fund['currency']})',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isBalanceVisible
                          ? fund['value']
                          : _mask(fund['value']),
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Action grid ────────────────────────────────────────────────────────────
  Widget _buildActionGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (context, index) {
        final action = _actions[index];
        return _buildActionButton(
          icon: action['icon'] as IconData,
          label: action['label'] as String,
          onTap: () => _onActionTap(action['label'] as String),
        );
      },
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
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.6), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.black87, size: 22),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}