import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({Key? key}) : super(key: key);

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedPeriod = 1;
  final List<String> _periods = ['1W', '1M', '3M', '1Y'];

  // ── API state ──────────────────────────────────────────────────────────────
  bool _isLoading = true;
  String _errorMessage = '';
  String _cdsNumber = '';
  double _totalPortfolioValue = 0;
  List<Map<String, dynamic>> _funds = [];

  // ── Static chart data ──────────────────────────────────────────────────────
  final Map<int, List<double>> _chartData = {
    0: [4.8, 4.6, 4.9, 5.1, 5.0, 5.2, 5.4],
    1: [4.2, 4.5, 4.3, 4.8, 4.6, 5.0, 5.2, 5.1, 5.3, 5.4],
    2: [3.8, 4.0, 3.9, 4.3, 4.2, 4.5, 4.7, 4.6, 4.9, 5.1, 5.2, 5.4],
    3: [2.9, 3.2, 3.0, 3.5, 3.4, 3.8, 4.0, 4.2, 4.5, 4.7, 5.0, 5.4],
  };

  // Fund card accent colors cycling
  final List<Color> _fundColors = [
    Color(0xFF2ECC71),
    Color(0xFF3498DB),
    Color(0xFFE67E22),
    Color(0xFF9B59B6),
    Color(0xFFE74C3C),
    Color(0xFF1ABC9C),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Fetch ──────────────────────────────────────────────────────────────────
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

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

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        final data = responseData['data'];
        final List<dynamic> funds = data['funds'] ?? [];
        setState(() {
          _totalPortfolioValue = (data['totalPortfolioValue'] as num).toDouble();
          _funds = funds.map((f) => Map<String, dynamic>.from(f)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = responseData['statusDesc'] ?? 'Failed to load portfolio';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Color _colorFor(int index) => _fundColors[index % _fundColors.length];

  String _fmt(double v, {int decimals = 2}) {
    final parts = v.toStringAsFixed(decimals).split('.');
    final formatted = parts[0].replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
    return decimals > 0 ? '$formatted.${parts[1]}' : formatted;
  }

  String _shortVal(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  int get _activeFunds => _funds.where((f) =>
  (f['status'] as String).toLowerCase() == 'active').length;

  double get _totalInvestedUnits => _funds.fold(0.0,
          (sum, f) => sum + (f['investorUnits'] as num).toDouble());

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
        child: _isLoading
            ? _buildLoader()
            : _errorMessage.isNotEmpty
            ? _buildError()
            : Column(children: [
          _buildValueCard(),
          const SizedBox(height: 12),
          _buildTabBar(),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildFundsTab(),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildLoader() => const Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A6741))),
      SizedBox(height: 16),
      Text('Loading portfolio...',
          style: TextStyle(
              color: Color(0xFF2E7D32),
              fontSize: 15,
              fontWeight: FontWeight.w500)),
    ]),
  );

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline, size: 56, color: Colors.red),
        const SizedBox(height: 16),
        Text(_errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 14)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _loadData,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A6741),
              foregroundColor: Colors.white),
        ),
      ]),
    ),
  );

  // ── Value card ─────────────────────────────────────────────────────────────
  Widget _buildValueCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.45),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.teal.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Total Portfolio Value',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.black45,
                  fontWeight: FontWeight.w500)),
          const Spacer(),
          // Refresh button
          GestureDetector(
            onTap: _loadData,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.refresh_rounded,
                  size: 14, color: Colors.teal.shade700),
            ),
          ),
        ]),
        const SizedBox(height: 6),
        Text(
          'TZS ${_fmt(_totalPortfolioValue)}',
          style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
              letterSpacing: -0.5),
        ),
        const SizedBox(height: 6),
        Text(
          'Acc No: $_cdsNumber',
          style: const TextStyle(fontSize: 11, color: Colors.black38),
        ),
        const SizedBox(height: 16),
        Row(children: [
          _miniStat('Funds', '${_funds.length}', Colors.teal.shade700),
          _vLine(),
          _miniStat('Active', '$_activeFunds', Colors.green.shade700),
          _vLine(),
          _miniStat('Total Units', _shortVal(_totalInvestedUnits), Colors.black54),
        ]),
      ]),
    );
  }

  Widget _miniStat(String label, String value, Color valueColor) => Expanded(
    child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  color: Colors.black38,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: valueColor)),
        ]),
  );

  Widget _vLine() => Container(
      width: 1,
      height: 28,
      color: Colors.black12,
      margin: const EdgeInsets.symmetric(horizontal: 4));

  // ── Tab bar ────────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: Colors.teal.shade700,
            borderRadius: BorderRadius.circular(18),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.black54,
          labelStyle:
          const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle:
          const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'My Funds'),
          ],
        ),
      ),
    );
  }

  // ── Overview tab ───────────────────────────────────────────────────────────
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(children: [
        _buildChartCard(),
        const SizedBox(height: 14),
        _buildAllocationCard(),
        const SizedBox(height: 14),
        _buildFundsSummaryCard(),
      ]),
    );
  }

  // ── Chart card ─────────────────────────────────────────────────────────────
  Widget _buildChartCard() {
    final data = _chartData[_selectedPeriod]!;
    final spots =
    List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i]));
    final minY = (data.reduce((a, b) => a < b ? a : b) - 0.3)
        .clamp(0.0, double.infinity);
    final maxY = data.reduce((a, b) => a > b ? a : b) + 0.3;
    final isUp = data.last >= data.first;
    final lineColor =
    isUp ? Colors.green.shade600 : Colors.red.shade500;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(
              child: Text('Funds Performance',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87))),
          ...List.generate(_periods.length, (i) {
            final active = i == _selectedPeriod;
            return GestureDetector(
              onTap: () => setState(() => _selectedPeriod = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(left: 6),
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: active ? Colors.teal.shade700 : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_periods[i],
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: active ? Colors.white : Colors.black38)),
              ),
            );
          }),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: LineChart(LineChartData(
            minY: minY,
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: (maxY - minY) / 3,
              getDrawingHorizontalLine: (_) => FlLine(
                  color: Colors.black.withOpacity(0.06),
                  strokeWidth: 1,
                  dashArray: [4, 4]),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 34,
                    interval: (maxY - minY) / 3,
                    getTitlesWidget: (v, _) => Text('${v.toStringAsFixed(1)}M',
                        style: const TextStyle(
                            fontSize: 8, color: Colors.black45)),
                  )),
              bottomTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => Colors.teal.shade800,
                getTooltipItems: (spots) => spots
                    .map((s) => LineTooltipItem(
                  'TZS ${s.y.toStringAsFixed(2)}M',
                  const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600),
                ))
                    .toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: lineColor,
                barWidth: 2.5,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      lineColor.withOpacity(0.25),
                      lineColor.withOpacity(0.0)
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          )),
        ),
      ]),
    );
  }

  // ── Allocation donut ───────────────────────────────────────────────────────
  Widget _buildAllocationCard() {
    // Only show funds with portfolioValue > 0 in the donut
    final activeFunds = _funds
        .where((f) => (f['portfolioValue'] as num).toDouble() > 0)
        .toList();

    if (activeFunds.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.55),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.5),
        ),
        child: Center(
          child: Text('No active fund investments yet',
              style: TextStyle(color: Colors.black45, fontSize: 13)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(7)),
              child: Icon(Icons.donut_large_rounded,
                  color: Colors.teal.shade700, size: 14)),
          const SizedBox(width: 8),
          const Text('Fund Allocation',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87)),
        ]),
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          SizedBox(
            width: 120,
            height: 120,
            child: PieChart(PieChartData(
              startDegreeOffset: -90,
              sectionsSpace: 2,
              centerSpaceRadius: 32,
              sections: activeFunds.asMap().entries.map((e) {
                final pct = (e.value['portfolioValue'] as num).toDouble() /
                    _totalPortfolioValue *
                    100;
                return PieChartSectionData(
                  value: pct,
                  color: _colorFor(e.key),
                  radius: 28,
                  title: '',
                );
              }).toList(),
            )),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: activeFunds.asMap().entries.map((e) {
                final pct =
                    (e.value['portfolioValue'] as num).toDouble() /
                        _totalPortfolioValue *
                        100;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(children: [
                    Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: _colorFor(e.key),
                            shape: BoxShape.circle)),
                    const SizedBox(width: 7),
                    Expanded(
                        child: Text(e.value['fundName'] as String,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87),
                            overflow: TextOverflow.ellipsis)),
                    Text('${pct.toStringAsFixed(0)}%',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.teal.shade700)),
                  ]),
                );
              }).toList(),
            ),
          ),
        ]),
      ]),
    );
  }

  // ── Funds summary card ─────────────────────────────────────────────────────
  Widget _buildFundsSummaryCard() {
    final ipoCount =
        _funds.where((f) => (f['status'] as String).toLowerCase() == 'ipo').length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(7)),
              child: Icon(Icons.bar_chart_rounded,
                  color: Colors.green.shade700, size: 14)),
          const SizedBox(width: 8),
          const Text('Fund Summary',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87)),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          _perfStat('Total Funds', '${_funds.length}', Colors.teal.shade700,
              Icons.account_balance_rounded),
          const SizedBox(width: 10),
          _perfStat('Active', '$_activeFunds', Colors.green.shade700,
              Icons.check_circle_rounded),
          const SizedBox(width: 10),
          _perfStat('IPO', '$ipoCount', Colors.orange.shade700,
              Icons.new_releases_rounded),
        ]),
      ]),
    );
  }

  Widget _perfStat(
      String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  color: Colors.black45,
                  fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  // ── My Funds tab ───────────────────────────────────────────────────────────
  Widget _buildFundsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: Colors.teal.shade700,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(children: [
          // Info banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.teal.withOpacity(0.2)),
            ),
            child: Row(children: [
              Icon(Icons.info_outline_rounded,
                  size: 15, color: Colors.teal.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    '${_funds.length} fund${_funds.length != 1 ? 's' : ''} available for Acc No $_cdsNumber',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.teal.shade700,
                        fontWeight: FontWeight.w500)),
              ),
            ]),
          ),

          ..._funds.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _buildFundCard(e.value, e.key),
          )),
        ]),
      ),
    );
  }

  // ── Fund card ──────────────────────────────────────────────────────────────
  Widget _buildFundCard(Map<String, dynamic> fund, int index) {
    final color = _colorFor(index);
    final status = fund['status'] as String;
    final isActive = status.toLowerCase() == 'active';
    final isIPO = status.toLowerCase() == 'ipo';
    final portfolioValue = (fund['portfolioValue'] as num).toDouble();
    final investorUnits = (fund['investorUnits'] as num).toDouble();
    final nav = (fund['nav'] as num).toDouble();
    final hasInvestment = portfolioValue > 0;

    Color statusColor = isActive
        ? Colors.green.shade600
        : isIPO
        ? Colors.orange.shade700
        : Colors.grey.shade500;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(children: [
        // ── Header strip ────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Row(children: [
            // Fund badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.3), width: 1.5),
              ),
              child: Center(
                child: Text(
                  fund['fundCode'] as String,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: color,
                      letterSpacing: -0.3),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fund['fundName'] as String,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87)),
                    const SizedBox(height: 3),
                    Text(fund['description'] as String,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black45)),
                  ]),
            ),
            // Status badge
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: statusColor.withOpacity(0.3), width: 1),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                        color: statusColor, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text(status,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor)),
              ]),
            ),
          ]),
        ),

        // ── Body ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // My investment row (highlighted if has investment)
            if (hasInvestment) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: color.withOpacity(0.2), width: 1),
                ),
                child: Row(children: [
                  Icon(Icons.account_balance_wallet_rounded,
                      color: color, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('My Investment',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.black45,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text(
                            'TZS ${_fmt(portfolioValue)}',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: color),
                          ),
                        ]),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    const Text('Units Held',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.black45,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(_fmt(investorUnits),
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87)),
                  ]),
                ]),
              ),
              const SizedBox(height: 12),
            ] else ...[
              // No investment yet
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.grey.withOpacity(0.2), width: 1),
                ),
                child: Row(children: [
                  Icon(Icons.info_outline,
                      size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 8),
                  Text('No investment in this fund yet',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500)),
                ]),
              ),
            ],

            // Key stats grid
            Row(children: [
              _fundStat('NAV', 'TZS ${_fmt(nav)}', Colors.teal.shade700),
              _statDivider(),
              _fundStat('NAV Date', fund['navDate'] as String, Colors.black54),
              _statDivider(),
              _fundStat(
                  'Min. Invest',
                  'TZS ${_shortVal((fund['minInvestment'] as num).toDouble())}',
                  Colors.green.shade700),
            ]),

            const SizedBox(height: 10),

            Row(children: [
              _fundStat(
                  'Sub. Min',
                  'TZS ${_shortVal((fund['subsequentMinInvestment'] as num).toDouble())}',
                  Colors.orange.shade700),
              _statDivider(),
              _fundStat(
                  'Total Units',
                  _shortVal((fund['totalUnitsAllInvestors'] as num)
                      .toDouble()),
                  Colors.purple.shade600),
              _statDivider(),
              _fundStat('Issuer', fund['issuer'] as String, Colors.black45),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _fundStat(String label, String value, Color valueColor) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 9,
                    color: Colors.black38,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: valueColor),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center),
          ]),
        ),
      );

  Widget _statDivider() => const SizedBox(width: 6);
}