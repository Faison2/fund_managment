import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../provider/locale_provider.dart';
import '../../provider/theme_provider.dart';

// ── Localised strings ─────────────────────────────────────────────────────────
class _PS {
  final String portfolio, totalPortfolioValue, accNo,
      funds, active, totalUnits, overview, myFunds,
      fundsPerformance, fundAllocation, fundSummary,
      ipo, totalFunds, myInvestment, unitsHeld,
      nav, navDate, minInvest, subMin, issuer,
      noInvestment, noActiveFunds,
      loading, retry, networkError,
      fundsAvailable;
  const _PS({
    required this.portfolio,          required this.totalPortfolioValue,
    required this.accNo,              required this.funds,
    required this.active,             required this.totalUnits,
    required this.overview,           required this.myFunds,
    required this.fundsPerformance,   required this.fundAllocation,
    required this.fundSummary,        required this.ipo,
    required this.totalFunds,         required this.myInvestment,
    required this.unitsHeld,          required this.nav,
    required this.navDate,            required this.minInvest,
    required this.subMin,             required this.issuer,
    required this.noInvestment,       required this.noActiveFunds,
    required this.loading,            required this.retry,
    required this.networkError,       required this.fundsAvailable,
  });
}

const _psEn = _PS(
  portfolio:           'Portfolio',
  totalPortfolioValue: 'Total Portfolio Value',
  accNo:               'Acc No',
  funds:               'Funds',
  active:              'Active',
  totalUnits:          'Total Units',
  overview:            'Overview',
  myFunds:             'My Funds',
  fundsPerformance:    'Funds Performance',
  fundAllocation:      'Fund Allocation',
  fundSummary:         'Fund Summary',
  ipo:                 'IPO',
  totalFunds:          'Total Funds',
  myInvestment:        'My Investment',
  unitsHeld:           'Units Held',
  nav:                 'NAV',
  navDate:             'NAV Date',
  minInvest:           'Min. Invest',
  subMin:              'Sub. Min',
  issuer:              'Issuer',
  noInvestment:        'No investment in this fund yet',
  noActiveFunds:       'No active fund investments yet',
  loading:             'Loading portfolio...',
  retry:               'Retry',
  networkError:        'Network error',
  fundsAvailable:      'fund(s) available for Acc No',
);

const _psSw = _PS(
  portfolio:           'Mkoba',
  totalPortfolioValue: 'Jumla ya Thamani ya Mkoba',
  accNo:               'Nambari ya Akaunti',
  funds:               'Fedha',
  active:              'Hai',
  totalUnits:          'Jumla ya Vitengo',
  overview:            'Muhtasari',
  myFunds:             'Fedha Zangu',
  fundsPerformance:    'Utendaji wa Fedha',
  fundAllocation:      'Ugawaji wa Fedha',
  fundSummary:         'Muhtasari wa Fedha',
  ipo:                 'Toleo la Awali',
  totalFunds:          'Jumla ya Fedha',
  myInvestment:        'Uwekezaji Wangu',
  unitsHeld:           'Vitengo Vilivyoshikiliwa',
  nav:                 'Thamani ya Sasa',
  navDate:             'Tarehe ya Thamani',
  minInvest:           'Kiwango cha Chini',
  subMin:              'Kiwango Kinachofuata',
  issuer:              'Mtoa Huduma',
  noInvestment:        'Hakuna uwekezaji katika fedha hii bado',
  noActiveFunds:       'Hakuna uwekezaji wa fedha bado',
  loading:             'Inapakia mkoba...',
  retry:               'Jaribu Tena',
  networkError:        'Hitilafu ya mtandao',
  fundsAvailable:      'fedha zinapatikana kwa Akaunti Nambari',
);

// ── PortfolioScreen ───────────────────────────────────────────────────────────
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

  final List<Color> _fundColors = [
    const Color(0xFF2ECC71), const Color(0xFF3498DB),
    const Color(0xFFE67E22), const Color(0xFF9B59B6),
    const Color(0xFFE74C3C), const Color(0xFF1ABC9C),
  ];

  // ── Theme helpers ──────────────────────────────────────────────────────────
  bool  get _dark   => context.watch<ThemeProvider>().isDark;
  _PS   get _s      => context.watch<LocaleProvider>().isSwahili ? _psSw : _psEn;

  // Background gradient
  Gradient get _bgGradient => _dark
      ? const LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(0xFF0B1A0C), Color(0xFF091510), Color(0xFF0D1A10)])
      : const LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(0xFFB8E6D3), Color(0xFF98D8C8), Color(0xFFFFE5B4)]);

  // Card surface
  Color get _cardBg     => _dark ? const Color(0xFF132013).withOpacity(0.85)
      : Colors.white.withOpacity(0.55);
  Color get _cardBorder => _dark ? const Color(0xFF1E3320)
      : Colors.white.withOpacity(0.7);
  Color get _txtPrim    => _dark ? const Color(0xFFE8F5E9) : Colors.black87;
  Color get _txtSec     => _dark ? const Color(0xFF81A884) : Colors.black45;
  Color get _txtHint    => _dark ? const Color(0xFF4A7A4D) : Colors.black38;
  Color get _divider    => _dark ? const Color(0xFF1E3320) : Colors.black12;
  Color get _teal       => _dark ? const Color(0xFF38BDF8) : Colors.teal.shade700;
  Color get _tealDim    => _dark ? const Color(0xFF38BDF8).withOpacity(0.12)
      : Colors.teal.withOpacity(0.08);
  Color get _green      => _dark ? const Color(0xFF4ADE80) : Colors.green.shade700;
  Color get _statItem   => _dark ? const Color(0xFF1A2E1C) : Colors.white.withOpacity(0.4);

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
    setState(() { _isLoading = true; _errorMessage = ''; });
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
          _totalPortfolioValue =
              (data['totalPortfolioValue'] as num).toDouble();
          _funds    = funds.map((f) => Map<String, dynamic>.from(f)).toList();
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
        _errorMessage = '${_s.networkError}: $e';
        _isLoading = false;
      });
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Color _colorFor(int i) => _fundColors[i % _fundColors.length];

  String _fmt(double v, {int decimals = 2}) {
    final parts = v.toStringAsFixed(decimals).split('.');
    final formatted = parts[0].replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
    return decimals > 0 ? '$formatted.${parts[1]}' : formatted;
  }

  String _shortVal(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000)    return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  int    get _activeFunds => _funds.where(
          (f) => (f['status'] as String).toLowerCase() == 'active').length;
  double get _totalInvestedUnits => _funds.fold(0.0,
          (sum, f) => sum + (f['investorUnits'] as num).toDouble());

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    context.watch<LocaleProvider>();
    final s = _s;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(gradient: _bgGradient),
        child: _isLoading
            ? _buildLoader(s)
            : _errorMessage.isNotEmpty
            ? _buildError(s)
            : Column(children: [
          _buildValueCard(s),
          const SizedBox(height: 12),
          _buildTabBar(s),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(s),
                _buildFundsTab(s),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  // ── Loader ─────────────────────────────────────────────────────────────────
  Widget _buildLoader(_PS s) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_green)),
      const SizedBox(height: 16),
      Text(s.loading,
          style: TextStyle(color: _green, fontSize: 15,
              fontWeight: FontWeight.w500)),
    ]),
  );

  // ── Error ──────────────────────────────────────────────────────────────────
  Widget _buildError(_PS s) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.error_outline, size: 56, color: Colors.red.shade400),
        const SizedBox(height: 16),
        Text(_errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red.shade400, fontSize: 14)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _loadData,
          icon: const Icon(Icons.refresh),
          label: Text(s.retry),
          style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white),
        ),
      ]),
    ),
  );

  // ── Value card ─────────────────────────────────────────────────────────────
  Widget _buildValueCard(_PS s) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _cardBorder, width: 1.5),
        boxShadow: [BoxShadow(color: _teal.withOpacity(0.1),
            blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(s.totalPortfolioValue,
              style: TextStyle(fontSize: 12, color: _txtSec,
                  fontWeight: FontWeight.w500)),
          const Spacer(),
          GestureDetector(
            onTap: _loadData,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: _tealDim, borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.refresh_rounded, size: 14, color: _teal),
            ),
          ),
        ]),
        const SizedBox(height: 6),
        Text('TZS ${_fmt(_totalPortfolioValue)}',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900,
                color: _txtPrim, letterSpacing: -0.5)),
        const SizedBox(height: 6),
        Text('${s.accNo}: $_cdsNumber',
            style: TextStyle(fontSize: 11, color: _txtHint)),
        const SizedBox(height: 16),
        Row(children: [
          _miniStat(s.funds,      '${_funds.length}',            _teal),
          _vLine(),
          _miniStat(s.active,     '$_activeFunds',               _green),
          _vLine(),
          _miniStat(s.totalUnits, _shortVal(_totalInvestedUnits), _txtSec),
        ]),
      ]),
    );
  }

  Widget _miniStat(String label, String value, Color valueColor) => Expanded(
    child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text(label, style: TextStyle(fontSize: 10, color: _txtHint,
          fontWeight: FontWeight.w500)),
      const SizedBox(height: 3),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
          color: valueColor)),
    ]),
  );

  Widget _vLine() => Container(width: 1, height: 28,
      color: _divider, margin: const EdgeInsets.symmetric(horizontal: 4));

  // ── Tab bar ────────────────────────────────────────────────────────────────
  Widget _buildTabBar(_PS s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: _dark ? const Color(0xFF132013) : Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _cardBorder, width: 1),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(color: _teal,
              borderRadius: BorderRadius.circular(18)),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
          unselectedLabelColor: _txtSec,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle:
          const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          dividerColor: Colors.transparent,
          tabs: [Tab(text: s.overview), Tab(text: s.myFunds)],
        ),
      ),
    );
  }

  // ── Overview tab ───────────────────────────────────────────────────────────
  Widget _buildOverviewTab(_PS s) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(children: [
        _buildChartCard(s),
        const SizedBox(height: 14),
        _buildAllocationCard(s),
        const SizedBox(height: 14),
        _buildFundsSummaryCard(s),
      ]),
    );
  }

  // ── Chart card ─────────────────────────────────────────────────────────────
  Widget _buildChartCard(_PS s) {
    final data      = _chartData[_selectedPeriod]!;
    final spots     = List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i]));
    final minY      = (data.reduce((a, b) => a < b ? a : b) - 0.3).clamp(0.0, double.infinity);
    final maxY      = data.reduce((a, b) => a > b ? a : b) + 0.3;
    final isUp      = data.last >= data.first;
    final lineColor = isUp ? Colors.green.shade500 : Colors.red.shade400;

    // Capture theme values as locals — never call context.watch() inside
    // fl_chart callbacks (getDrawingHorizontalLine, getTitlesWidget, etc.)
    // as those run outside Flutter's build tree and will silently break.
    final isDark       = _dark;
    final gridColor    = (isDark ? Colors.white : Colors.black).withOpacity(0.06);
    final hintColor    = _txtHint;
    final primColor    = _txtPrim;
    final tealColor    = _teal;
    final cardBgColor  = _cardBg;
    final cardBdColor  = _cardBorder;
    final tooltipBg    = isDark ? const Color(0xFF132013) : Colors.teal.shade800;
    final shadowOpacity = isDark ? 0.2 : 0.04;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      decoration: BoxDecoration(
        color: cardBgColor, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBdColor, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(shadowOpacity),
            blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(s.fundsPerformance,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: primColor))),
          ...List.generate(_periods.length, (i) {
            final active = i == _selectedPeriod;
            return GestureDetector(
              onTap: () => setState(() => _selectedPeriod = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: active ? tealColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_periods[i],
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: active ? Colors.white : hintColor)),
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
                  color: gridColor,
                  strokeWidth: 1, dashArray: [4, 4]),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true, reservedSize: 34,
                interval: (maxY - minY) / 3,
                getTitlesWidget: (v, _) => Text('${v.toStringAsFixed(1)}M',
                    style: TextStyle(fontSize: 8, color: hintColor)),
              )),
              bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => tooltipBg,
                getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                  'TZS ${s.y.toStringAsFixed(2)}M',
                  const TextStyle(color: Colors.white, fontSize: 10,
                      fontWeight: FontWeight.w600),
                )).toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots, isCurved: true, color: lineColor, barWidth: 2.5,
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

  // ── Allocation donut ───────────────────────────────────────────────────────
  Widget _buildAllocationCard(_PS s) {
    final activeFunds = _funds
        .where((f) => (f['portfolioValue'] as num).toDouble() > 0)
        .toList();

    if (activeFunds.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: _cardBg, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _cardBorder, width: 1.5)),
        child: Center(child: Text(s.noActiveFunds,
            style: TextStyle(color: _txtSec, fontSize: 13))),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(_dark ? 0.2 : 0.04),
            blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: _tealDim,
                borderRadius: BorderRadius.circular(7)),
            child: Icon(Icons.donut_large_rounded, color: _teal, size: 14),
          ),
          const SizedBox(width: 8),
          Text(s.fundAllocation, style: TextStyle(fontSize: 13,
              fontWeight: FontWeight.w700, color: _txtPrim)),
        ]),
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          SizedBox(
            width: 120, height: 120,
            child: PieChart(PieChartData(
              startDegreeOffset: -90, sectionsSpace: 2, centerSpaceRadius: 32,
              sections: activeFunds.asMap().entries.map((e) {
                final pct = (e.value['portfolioValue'] as num).toDouble() /
                    _totalPortfolioValue * 100;
                return PieChartSectionData(
                    value: pct, color: _colorFor(e.key), radius: 28, title: '');
              }).toList(),
            )),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: activeFunds.asMap().entries.map((e) {
                final pct = (e.value['portfolioValue'] as num).toDouble() /
                    _totalPortfolioValue * 100;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(children: [
                    Container(width: 8, height: 8,
                        decoration: BoxDecoration(
                            color: _colorFor(e.key), shape: BoxShape.circle)),
                    const SizedBox(width: 7),
                    Expanded(child: Text(e.value['fundName'] as String,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                            color: _txtPrim), overflow: TextOverflow.ellipsis)),
                    Text('${pct.toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 11,
                            fontWeight: FontWeight.w600, color: _teal)),
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
  Widget _buildFundsSummaryCard(_PS s) {
    final ipoCount = _funds.where(
            (f) => (f['status'] as String).toLowerCase() == 'ipo').length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(_dark ? 0.2 : 0.04),
            blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: _green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(7)),
            child: Icon(Icons.bar_chart_rounded, color: _green, size: 14),
          ),
          const SizedBox(width: 8),
          Text(s.fundSummary, style: TextStyle(fontSize: 13,
              fontWeight: FontWeight.w700, color: _txtPrim)),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          _perfStat(s.totalFunds, '${_funds.length}', _teal,
              Icons.account_balance_rounded),
          const SizedBox(width: 10),
          _perfStat(s.active, '$_activeFunds', _green,
              Icons.check_circle_rounded),
          const SizedBox(width: 10),
          _perfStat(s.ipo, '$ipoCount', Colors.orange.shade600,
              Icons.new_releases_rounded),
        ]),
      ]),
    );
  }

  Widget _perfStat(String label, String value, Color color, IconData icon) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(_dark ? 0.1 : 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2), width: 1),
          ),
          child: Column(children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 15,
                fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10,
                color: _txtSec, fontWeight: FontWeight.w500)),
          ]),
        ),
      );

  // ── My Funds tab ───────────────────────────────────────────────────────────
  Widget _buildFundsTab(_PS s) {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: _teal,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(children: [
          // Info banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: _tealDim, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _teal.withOpacity(0.2)),
            ),
            child: Row(children: [
              Icon(Icons.info_outline_rounded, size: 15, color: _teal),
              const SizedBox(width: 8),
              Expanded(child: Text(
                  '${_funds.length} ${s.fundsAvailable} $_cdsNumber',
                  style: TextStyle(fontSize: 12, color: _teal,
                      fontWeight: FontWeight.w500))),
            ]),
          ),
          ..._funds.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _buildFundCard(e.value, e.key, s),
          )),
        ]),
      ),
    );
  }

  // ── Fund card ──────────────────────────────────────────────────────────────
  Widget _buildFundCard(Map<String, dynamic> fund, int index, _PS s) {
    final color          = _colorFor(index);
    final status         = fund['status'] as String;
    final isActive       = status.toLowerCase() == 'active';
    final isIPO          = status.toLowerCase() == 'ipo';
    final portfolioValue = (fund['portfolioValue'] as num).toDouble();
    final investorUnits  = (fund['investorUnits'] as num).toDouble();
    final nav            = (fund['nav'] as num).toDouble();
    final hasInvestment  = portfolioValue > 0;

    final Color statusColor = isActive
        ? Colors.green.shade600
        : isIPO ? Colors.orange.shade700 : Colors.grey.shade500;

    return Container(
      decoration: BoxDecoration(
        color: _cardBg, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder, width: 1.5),
        boxShadow: [BoxShadow(color: color.withOpacity(_dark ? 0.08 : 0.1),
            blurRadius: 12, offset: const Offset(0, 5))],
      ),
      child: Column(children: [
        // ── Header strip ────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: color.withOpacity(_dark ? 0.12 : 0.08),
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          ),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(_dark ? 0.18 : 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.3), width: 1.5),
              ),
              child: Center(child: Text(fund['fundCode'] as String,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900,
                      color: color, letterSpacing: -0.3))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fund['fundName'] as String,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                            color: _txtPrim)),
                    const SizedBox(height: 3),
                    Text(fund['description'] as String,
                        style: TextStyle(fontSize: 12, color: _txtSec)),
                  ]),
            ),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6,
                    decoration: BoxDecoration(color: statusColor,
                        shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text(status, style: TextStyle(fontSize: 11,
                    fontWeight: FontWeight.w700, color: statusColor)),
              ]),
            ),
          ]),
        ),

        // ── Body ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            if (hasInvestment) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(_dark ? 0.1 : 0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withOpacity(0.2), width: 1),
                ),
                child: Row(children: [
                  Icon(Icons.account_balance_wallet_rounded,
                      color: color, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.myInvestment, style: TextStyle(fontSize: 10,
                            color: _txtSec, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text('TZS ${_fmt(portfolioValue)}',
                            style: TextStyle(fontSize: 16,
                                fontWeight: FontWeight.w900, color: color)),
                      ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(s.unitsHeld, style: TextStyle(fontSize: 10,
                        color: _txtSec, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(_fmt(investorUnits),
                        style: TextStyle(fontSize: 14,
                            fontWeight: FontWeight.w800, color: _txtPrim)),
                  ]),
                ]),
              ),
              const SizedBox(height: 12),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: _dark
                      ? Colors.grey.withOpacity(0.08)
                      : Colors.grey.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
                ),
                child: Row(children: [
                  Icon(Icons.info_outline, size: 14, color: _txtSec),
                  const SizedBox(width: 8),
                  Text(s.noInvestment,
                      style: TextStyle(fontSize: 12, color: _txtSec)),
                ]),
              ),
            ],

            // Key stats grid
            Row(children: [
              _fundStat(s.nav,     'TZS ${_fmt(nav)}', _teal),
              _statDivider(),
              _fundStat(s.navDate, fund['navDate'] as String, _txtSec),
              _statDivider(),
              _fundStat(s.minInvest,
                  'TZS ${_shortVal((fund['minInvestment'] as num).toDouble())}',
                  _green),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              _fundStat(s.subMin,
                  'TZS ${_shortVal((fund['subsequentMinInvestment'] as num).toDouble())}',
                  Colors.orange.shade600),
              _statDivider(),
              _fundStat(s.totalUnits,
                  _shortVal((fund['totalUnitsAllInvestors'] as num).toDouble()),
                  Colors.purple.shade400),
              _statDivider(),
              _fundStat(s.issuer, fund['issuer'] as String, _txtHint),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _fundStat(String label, String value, Color valueColor) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
          color: _statItem, borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Text(label, style: TextStyle(fontSize: 9, color: _txtHint,
            fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 11,
            fontWeight: FontWeight.w700, color: valueColor),
            overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
      ]),
    ),
  );

  Widget _statDivider() => const SizedBox(width: 6);
}