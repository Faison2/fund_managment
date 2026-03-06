import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({Key? key}) : super(key: key);

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedPeriod = 1; // 0=1W 1=1M 2=3M 3=1Y

  final List<String> _periods = ['1W', '1M', '3M', '1Y'];

  // ── Holdings ────────────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _holdings = [
    {
      'ticker': 'NMB',
      'name': 'NMB Bank Plc',
      'shares': 500,
      'avgCost': 2980.00,
      'currentPrice': 3160.00,
      'allocation': 0.28,
      'color': Color(0xFF2ECC71),
    },
    {
      'ticker': 'CRDB',
      'name': 'CRDB Bank Plc',
      'shares': 200,
      'avgCost': 2400.00,
      'currentPrice': 2530.00,
      'allocation': 0.18,
      'color': Color(0xFF3498DB),
    },
    {
      'ticker': 'TBL',
      'name': 'Tanzania Breweries',
      'shares': 100,
      'avgCost': 3600.00,
      'currentPrice': 3820.00,
      'allocation': 0.14,
      'color': Color(0xFFE67E22),
    },
    {
      'ticker': 'TWIGA',
      'name': 'Twiga Cement',
      'shares': 80,
      'avgCost': 6500.00,
      'currentPrice': 6950.00,
      'allocation': 0.20,
      'color': Color(0xFF9B59B6),
    },
    {
      'ticker': 'TPS',
      'name': 'TPS Eastern Africa',
      'shares': 300,
      'avgCost': 2000.00,
      'currentPrice': 2120.00,
      'allocation': 0.12,
      'color': Color(0xFFE74C3C),
    },
    {
      'ticker': 'KA',
      'name': 'Kenya Airways',
      'shares': 1000,
      'avgCost': 290.00,
      'currentPrice': 315.00,
      'allocation': 0.08,
      'color': Color(0xFF1ABC9C),
    },
  ];

  // ── Chart data per period ───────────────────────────────────────────────────
  final Map<int, List<double>> _chartData = {
    0: [4.8, 4.6, 4.9, 5.1, 5.0, 5.2, 5.4],                      // 1W
    1: [4.2, 4.5, 4.3, 4.8, 4.6, 5.0, 5.2, 5.1, 5.3, 5.4],       // 1M
    2: [3.8, 4.0, 3.9, 4.3, 4.2, 4.5, 4.7, 4.6, 4.9, 5.1, 5.2, 5.4], // 3M
    3: [2.9, 3.2, 3.0, 3.5, 3.4, 3.8, 4.0, 4.2, 4.5, 4.7, 5.0, 5.4], // 1Y
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Computed values ─────────────────────────────────────────────────────────
  double get _totalCurrentValue => _holdings.fold(0.0, (sum, h) =>
  sum + (h['shares'] as int) * (h['currentPrice'] as double));

  double get _totalCostBasis => _holdings.fold(0.0, (sum, h) =>
  sum + (h['shares'] as int) * (h['avgCost'] as double));

  double get _totalGainLoss => _totalCurrentValue - _totalCostBasis;

  double get _totalGainLossPct => (_totalGainLoss / _totalCostBasis) * 100;

  double _holdingValue(Map<String, dynamic> h) =>
      (h['shares'] as int) * (h['currentPrice'] as double);

  double _holdingGainLoss(Map<String, dynamic> h) =>
      ((h['currentPrice'] as double) - (h['avgCost'] as double)) * (h['shares'] as int);

  double _holdingGainLossPct(Map<String, dynamic> h) =>
      (((h['currentPrice'] as double) - (h['avgCost'] as double)) / (h['avgCost'] as double)) * 100;

  String _fmt(double v, {int decimals = 2}) {
    final parts = v.toStringAsFixed(decimals).split('.');
    final formatted = parts[0].replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
    return decimals > 0 ? '$formatted.${parts[1]}' : formatted;
  }

  String _shortVal(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000)    return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

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
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────────────
            _buildTopBar(),

            // ── Total value card ─────────────────────────────────────────
            _buildValueCard(),

            const SizedBox(height: 12),

            // ── Tab bar ──────────────────────────────────────────────────
            _buildTabBar(),

            const SizedBox(height: 8),

            // ── Tab content ──────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildHoldingsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Portfolio',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black87, letterSpacing: -0.4)),
              Text('DSE Securities',
                  style: TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w500)),
            ],
          ),
          Row(children: [
            _iconBtn(Icons.notifications_outlined),
            const SizedBox(width: 8),
            _iconBtn(Icons.tune_rounded),
          ]),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon) => Container(
    width: 38, height: 38,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.4),
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: Colors.white.withOpacity(0.6), width: 1),
    ),
    child: Icon(icon, color: Colors.black54, size: 18),
  );

  // ── Total value card ───────────────────────────────────────────────────────
  Widget _buildValueCard() {
    final isPositive = _totalGainLoss >= 0;
    final gainColor  = isPositive ? Colors.green.shade700 : Colors.red.shade600;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.45),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.1), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Portfolio Value',
              style: TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(
            'TZS ${_shortVal(_totalCurrentValue)}',
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: -0.5),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: gainColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(children: [
                Icon(isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                    size: 13, color: gainColor),
                const SizedBox(width: 4),
                Text(
                  '${isPositive ? '+' : ''}${_totalGainLossPct.toStringAsFixed(2)}%',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: gainColor),
                ),
              ]),
            ),
            const SizedBox(width: 10),
            Text(
              '${isPositive ? '+' : ''}TZS ${_shortVal(_totalGainLoss)}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: gainColor),
            ),
            const Spacer(),
            Text('${_holdings.length} holdings',
                style: const TextStyle(fontSize: 12, color: Colors.black38, fontWeight: FontWeight.w500)),
          ]),

          const SizedBox(height: 16),

          // Mini stat row
          Row(children: [
            _miniStat('Cost Basis', 'TZS ${_shortVal(_totalCostBasis)}', Colors.black54),
            _vLine(),
            _miniStat('Day\'s P&L', '+TZS 12.4K', Colors.green.shade700),
            _vLine(),
            _miniStat('Realised', 'TZS 84.2K', Colors.teal.shade700),
          ]),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color valueColor) => Expanded(
    child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.black38, fontWeight: FontWeight.w500)),
      const SizedBox(height: 3),
      Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: valueColor)),
    ]),
  );

  Widget _vLine() => Container(width: 1, height: 28, color: Colors.black12,
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
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Holdings'),
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
        _buildPerformanceSummaryCard(),
      ]),
    );
  }

  // ── Line chart card ────────────────────────────────────────────────────────
  Widget _buildChartCard() {
    final data = _chartData[_selectedPeriod]!;
    final spots = List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i]));
    final minY  = (data.reduce((a, b) => a < b ? a : b) - 0.3).clamp(0.0, double.infinity);
    final maxY  = data.reduce((a, b) => a > b ? a : b) + 0.3;
    final isUp  = data.last >= data.first;
    final lineColor = isUp ? Colors.green.shade600 : Colors.red.shade500;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          const Expanded(
            child: Text('Portfolio Performance',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87)),
          ),
          // Period selector
          ...List.generate(_periods.length, (i) {
            final active = i == _selectedPeriod;
            return GestureDetector(
              onTap: () => setState(() => _selectedPeriod = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: active ? Colors.teal.shade700 : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_periods[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : Colors.black38,
                    )),
              ),
            );
          }),
        ]),

        const SizedBox(height: 16),

        SizedBox(
          height: 150,
          child: LineChart(LineChartData(
            minY: minY, maxY: maxY,
            gridData: FlGridData(
              show: true, drawVerticalLine: false,
              horizontalInterval: (maxY - minY) / 3,
              getDrawingHorizontalLine: (_) => FlLine(
                  color: Colors.black.withOpacity(0.06), strokeWidth: 1, dashArray: [4, 4]),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true, reservedSize: 34,
                interval: (maxY - minY) / 3,
                getTitlesWidget: (v, _) =>
                    Text('${v.toStringAsFixed(1)}M', style: const TextStyle(fontSize: 8, color: Colors.black45)),
              )),
              bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => Colors.teal.shade800,
                getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                  'TZS ${s.y.toStringAsFixed(2)}M',
                  const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                )).toList(),
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
                    colors: [lineColor.withOpacity(0.25), lineColor.withOpacity(0.0)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          )),
        ),
      ]),
    );
  }

  // ── Allocation donut card ──────────────────────────────────────────────────
  Widget _buildAllocationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(color: Colors.teal.withOpacity(0.12), borderRadius: BorderRadius.circular(7)),
              child: Icon(Icons.donut_large_rounded, color: Colors.teal.shade700, size: 14)),
          const SizedBox(width: 8),
          const Text('Allocation', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87)),
        ]),
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          // Donut chart
          SizedBox(
            width: 120, height: 120,
            child: PieChart(PieChartData(
              startDegreeOffset: -90,
              sectionsSpace: 2,
              centerSpaceRadius: 32,
              sections: _holdings.map((h) => PieChartSectionData(
                value: (h['allocation'] as double) * 100,
                color: h['color'] as Color,
                radius: 28,
                title: '',
              )).toList(),
            )),
          ),
          const SizedBox(width: 16),
          // Legend
          Expanded(
            child: Column(children: _holdings.map((h) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(children: [
                Container(width: 8, height: 8,
                    decoration: BoxDecoration(color: h['color'] as Color, shape: BoxShape.circle)),
                const SizedBox(width: 7),
                Expanded(child: Text(h['ticker'] as String,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87))),
                Text('${((h['allocation'] as double) * 100).toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.teal.shade700)),
              ]),
            )).toList()),
          ),
        ]),
      ]),
    );
  }

  // ── Performance summary card ───────────────────────────────────────────────
  Widget _buildPerformanceSummaryCard() {
    final winners = _holdings.where((h) => _holdingGainLoss(h) > 0).length;
    final losers  = _holdings.length - winners;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.12), borderRadius: BorderRadius.circular(7)),
              child: Icon(Icons.bar_chart_rounded, color: Colors.green.shade700, size: 14)),
          const SizedBox(width: 8),
          const Text('Performance Summary', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87)),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          _perfStat('Winners', '$winners', Colors.green.shade700, Icons.trending_up_rounded),
          const SizedBox(width: 10),
          _perfStat('Losers', '$losers', Colors.red.shade600, Icons.trending_down_rounded),
          const SizedBox(width: 10),
          _perfStat('Total Return', '+${_totalGainLossPct.toStringAsFixed(1)}%', Colors.teal.shade700, Icons.show_chart_rounded),
        ]),
        const SizedBox(height: 16),
        // Win/loss bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: winners / _holdings.length,
            minHeight: 8,
            backgroundColor: Colors.red.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade500),
          ),
        ),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('$winners winning', style: TextStyle(fontSize: 10, color: Colors.green.shade700, fontWeight: FontWeight.w600)),
          Text('$losers losing',   style: TextStyle(fontSize: 10, color: Colors.red.shade600, fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }

  Widget _perfStat(String label, String value, Color color, IconData icon) {
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
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.black45, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  // ── Holdings tab ───────────────────────────────────────────────────────────
  Widget _buildHoldingsTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(children: [
        // Sort / filter bar
        Row(children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.45),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.6), width: 1),
              ),
              child: Row(children: [
                Icon(Icons.search_rounded, size: 16, color: Colors.black38),
                const SizedBox(width: 8),
                const Text('Search holdings…', style: TextStyle(fontSize: 12, color: Colors.black38)),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.45),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.6), width: 1),
            ),
            child: Icon(Icons.sort_rounded, size: 18, color: Colors.teal.shade700),
          ),
        ]),

        const SizedBox(height: 14),

        // Holdings list
        ..._holdings.map((h) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildHoldingCard(h),
        )),
      ]),
    );
  }

  // ── Holding card ───────────────────────────────────────────────────────────
  Widget _buildHoldingCard(Map<String, dynamic> h) {
    final gl       = _holdingGainLoss(h);
    final glPct    = _holdingGainLossPct(h);
    final value    = _holdingValue(h);
    final isPos    = gl >= 0;
    final gainColor = isPos ? Colors.green.shade700 : Colors.red.shade600;
    final color    = h['color'] as Color;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.5),
        boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        // Top row
        Row(children: [
          // Ticker badge
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.25), width: 1),
            ),
            child: Center(
              child: Text(h['ticker'] as String,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.3)),
            ),
          ),
          const SizedBox(width: 12),

          // Name + shares
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(h['name'] as String,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text('${h['shares']} shares',
                style: const TextStyle(fontSize: 11, color: Colors.black45)),
          ])),

          // Current value
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('TZS ${_shortVal(value)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black87)),
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: gainColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(isPos ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                    size: 10, color: gainColor),
                const SizedBox(width: 2),
                Text('${glPct.abs().toStringAsFixed(2)}%',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: gainColor)),
              ]),
            ),
          ]),
        ]),

        const SizedBox(height: 14),

        // Bottom details
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            _holdingDetail('Avg Cost', 'TZS ${_fmt(h['avgCost'] as double, decimals: 0)}'),
            _holdingDivider(),
            _holdingDetail('Curr Price', 'TZS ${_fmt(h['currentPrice'] as double, decimals: 0)}'),
            _holdingDivider(),
            _holdingDetail(
              'P&L',
              '${isPos ? '+' : ''}TZS ${_shortVal(gl.abs())}',
              valueColor: gainColor,
            ),
            _holdingDivider(),
            _holdingDetail('Alloc', '${((h['allocation'] as double) * 100).toStringAsFixed(0)}%',
                valueColor: Colors.teal.shade700),
          ]),
        ),

        const SizedBox(height: 10),

        // Allocation bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: h['allocation'] as double,
            minHeight: 4,
            backgroundColor: color.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ]),
    );
  }

  Widget _holdingDetail(String label, String value, {Color? valueColor}) => Expanded(
    child: Column(children: [
      Text(label, style: const TextStyle(fontSize: 9, color: Colors.black38, fontWeight: FontWeight.w500)),
      const SizedBox(height: 3),
      Text(value,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: valueColor ?? Colors.black87),
          overflow: TextOverflow.ellipsis),
    ]),
  );

  Widget _holdingDivider() =>
      Container(width: 1, height: 24, color: Colors.black.withOpacity(0.07),
          margin: const EdgeInsets.symmetric(horizontal: 2));
}