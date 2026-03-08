import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../holdings/holding.dart';
import '../market_watch/market_watch.dart';
import '../markets /markets.dart';
import '../profile/trade_profile.dart';
import '../trade/trade_shared.dart';

class TradeDashboard extends StatefulWidget {
  const TradeDashboard({Key? key}) : super(key: key);

  @override
  State<TradeDashboard> createState() => _TradeDashboardState();
}

class _TradeDashboardState extends State<TradeDashboard>
    with TickerProviderStateMixin {
  int _navIndex = 0;
  bool _fabExpanded = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late AnimationController _fabAnim;
  late AnimationController _pageAnim;
  late Animation<double> _pageFade;

  @override
  void initState() {
    super.initState();
    _fabAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _pageAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _pageFade =
        CurvedAnimation(parent: _pageAnim, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fabAnim.dispose();
    _pageAnim.dispose();
    super.dispose();
  }

  // ── Navigation ─────────────────────────────────────────────────────────────
  void _onNavTap(int index) {
    HapticFeedback.selectionClick();
    if (_fabExpanded) _toggleFab();

    switch (index) {
      case 1:
        _push(const MarketsPage());
        break;
      case 3:
        _push(const WatchlistPage());
        break;
      case 4:
        _push(const ProfilePage());
        break;
      default:
        setState(() => _navIndex = index);
    }
  }

  void _push(Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => page,
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
              parent: animation, curve: Curves.easeInOut);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                  begin: const Offset(0.05, 0), end: Offset.zero)
                  .animate(curved),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 380),
      ),
    );
  }

  // ─────────────────────────────── BUILD ────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: TradeColors.bg,
        extendBody: true,
        drawer: _TradeDrawer(onSwitchToFms: () {
          Navigator.pop(context);
          Navigator.pop(context);
        }),
        body: FadeTransition(
          opacity: _pageFade,
          child: _buildPortfolioBody(),
        ),
        floatingActionButton: _buildFab(),
        floatingActionButtonLocation:
        FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  // ── Portfolio body ─────────────────────────────────────────────────────────
  Widget _buildPortfolioBody() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildSliverAppBar(),
        SliverToBoxAdapter(
          child: Column(
            children: [
              _buildPortfolioCard(),
              _buildBuySellButtons(), // ← NEW
              const SizedBox(height: 24),
              _buildPerformanceSection(),
              const SizedBox(height: 24),
              _buildAllocationSection(),
              const SizedBox(height: 24),
              _buildQuickHoldings(),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ],
    );
  }

  // ── App bar ────────────────────────────────────────────────────────────────
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: TradeColors.bg,
      expandedHeight: 70,
      floating: true,
      pinned: true,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: TradeColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: TradeColors.border),
          ),
          child: const Icon(Icons.menu_rounded,
              size: 16, color: TradeColors.txtPrim),
        ),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: Row(
        children: [
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [TradeColors.teal, Color(0xFF0080FF)]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('TRADE',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5)),
          ),
          const SizedBox(width: 10),
          const Text('Portfolio',
              style: TextStyle(
                  color: TradeColors.txtPrim,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
        ],
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: TradeColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: TradeColors.border),
            ),
            child: const Icon(Icons.notifications_none_rounded,
                size: 18, color: TradeColors.txtPrim),
          ),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ── Portfolio hero card ────────────────────────────────────────────────────
  Widget _buildPortfolioCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D3D5C),
              Color(0xFF0A2840),
              Color(0xFF061820),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: TradeColors.teal.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
                color: TradeColors.teal.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8)),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    TradeColors.teal.withOpacity(0.08),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Portfolio Value',
                          style: TextStyle(
                              color: TradeColors.txtSec,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                      _changeChip('+5.8% today', TradeColors.green),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('TZS 21,200,000',
                      style: TextStyle(
                          color: TradeColors.txtPrim,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.trending_up_rounded,
                        size: 16, color: TradeColors.green),
                    const SizedBox(width: 4),
                    const Text('+TZS 1,160,000 this month',
                        style: TextStyle(
                            color: TradeColors.green, fontSize: 13)),
                  ]),
                  const SizedBox(height: 20),
                  Row(children: [
                    _miniStat(
                        'Day P&L', '+TZS 48,200', TradeColors.green),
                    _vDivider(),
                    _miniStat(
                        'Invested', 'TZS 18.5M', TradeColors.txtSec),
                    _vDivider(),
                    _miniStat('Returns', '+14.6%', TradeColors.gold),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _changeChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.arrow_upward_rounded, size: 11, color: color),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: Column(children: [
        Text(label,
            style: const TextStyle(
                color: TradeColors.txtSec, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _vDivider() => Container(
      height: 32, width: 1, color: Colors.white.withOpacity(0.08));

  // ── Buy / Sell buttons ─────────────────────────────────────────────────────
  Widget _buildBuySellButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          // BUY
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                showTradeSheet(context, kStocks.first, isBuy: true);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00C896), Color(0xFF00A878)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: TradeColors.green.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.trending_up_rounded,
                        color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Buy',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // SELL
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                showTradeSheet(context, kStocks.first, isBuy: false);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF4D6A), Color(0xFFE0003C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: TradeColors.red.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.trending_down_rounded,
                        color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Sell',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Performance chart section ──────────────────────────────────────────────
  Widget _buildPerformanceSection() {
    return Column(
      children: [
        const TradeSectionHeader(
            title: 'Portfolio Performance',
            icon: Icons.show_chart_rounded),
        _buildLineChartCard(),
      ],
    );
  }

  Widget _buildLineChartCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _PeriodChart(data: kPortfolioHistory),
    );
  }

  // ── Allocation section ─────────────────────────────────────────────────────
  Widget _buildAllocationSection() {
    return Column(
      children: [
        const TradeSectionHeader(
            title: 'Allocation',
            icon: Icons.pie_chart_outline_rounded),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: TradeColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: TradeColors.border),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child:
                  CustomPaint(painter: DonutPainter(stocks: kStocks)),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: kStocks.map((s) {
                      return Padding(
                        padding:
                        const EdgeInsets.symmetric(vertical: 4),
                        child: Row(children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: s.color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(s.symbol,
                                style: const TextStyle(
                                    color: TradeColors.txtPrim,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ),
                          Text('${s.allocation}%',
                              style: TextStyle(
                                  color: s.color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ]),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Quick holdings preview ─────────────────────────────────────────────────
  Widget _buildQuickHoldings() {
    return Column(
      children: [
        TradeSectionHeader(
          title: 'Holdings',
          icon: Icons.list_alt_rounded,
          trailing: GestureDetector(
            onTap: () => _push(const HoldingsPage()),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: TradeColors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: TradeColors.teal.withOpacity(0.3)),
              ),
              child: const Text('See All',
                  style: TextStyle(
                      color: TradeColors.teal,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ),
        ...kStocks.take(3).map((s) => StockTile(
          stock: s,
          onTap: () => showTradeSheet(context, s),
        )),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: GestureDetector(
            onTap: () => _push(const HoldingsPage()),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: TradeColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: TradeColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('View All Holdings',
                      style: TextStyle(
                          color: TradeColors.teal,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded,
                      size: 14, color: TradeColors.teal),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── FAB ────────────────────────────────────────────────────────────────────
  Widget _buildFab() {
    return AnimatedBuilder(
      animation: _fabAnim,
      builder: (_, __) {
        final t = _fabAnim.value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_fabExpanded) ...[
              _fabAction(
                label: 'Sell',
                icon: Icons.trending_down_rounded,
                color: TradeColors.red,
                offset: Offset(0, -80 * t),
                onTap: () {
                  _toggleFab();
                  showTradeSheet(context, kStocks.first, isBuy: false);
                },
              ),
              _fabAction(
                label: 'Buy',
                icon: Icons.trending_up_rounded,
                color: TradeColors.green,
                offset: Offset(0, -40 * t),
                onTap: () {
                  _toggleFab();
                  showTradeSheet(context, kStocks.first, isBuy: true);
                },
              ),
            ],
            GestureDetector(
              onTap: _toggleFab,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _fabExpanded
                        ? [TradeColors.red, const Color(0xFFFF0040)]
                        : [TradeColors.teal, const Color(0xFF0080FF)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_fabExpanded
                          ? TradeColors.red
                          : TradeColors.teal)
                          .withOpacity(0.45),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: AnimatedRotation(
                  turns: _fabExpanded ? 0.125 : 0,
                  duration: const Duration(milliseconds: 280),
                  child: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 28),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Widget _fabAction({
    required String label,
    required IconData icon,
    required Color color,
    required Offset offset,
    required VoidCallback onTap,
  }) {
    return Transform.translate(
      offset: offset,
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: TradeColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleFab() {
    HapticFeedback.lightImpact();
    setState(() => _fabExpanded = !_fabExpanded);
    _fabExpanded ? _fabAnim.forward() : _fabAnim.reverse();
  }

  // ── Bottom Nav ─────────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    return BottomAppBar(
      color: TradeColors.surface,
      elevation: 0,
      notchMargin: 10,
      shape: const CircularNotchedRectangle(),
      child: SizedBox(
        height: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(0, Icons.pie_chart_rounded, 'Portfolio'),
            _navItem(1, Icons.bar_chart_rounded, 'Markets'),
            const SizedBox(width: 60),
            _navItem(3, Icons.star_rounded, 'Watchlist'),
            _navItem(4, Icons.person_rounded, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int idx, IconData icon, String label) {
    final sel = _navIndex == idx;
    return GestureDetector(
      onTap: () => _onNavTap(idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: sel
              ? TradeColors.teal.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 22,
                color: sel
                    ? TradeColors.teal
                    : TradeColors.txtSec.withOpacity(0.6)),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: sel
                    ? TradeColors.teal
                    : TradeColors.txtSec.withOpacity(0.6),
                fontSize: 10,
                fontWeight:
                sel ? FontWeight.w700 : FontWeight.w500,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PERIOD CHART
// ─────────────────────────────────────────────────────────────────────────────

class _PeriodChart extends StatefulWidget {
  final List<double> data;
  const _PeriodChart({required this.data});

  @override
  State<_PeriodChart> createState() => _PeriodChartState();
}

class _PeriodChartState extends State<_PeriodChart> {
  int _period = 1;
  static const _periods = ['1W', '1M', '3M', '6M'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TradeColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TradeColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: List.generate(_periods.length, (i) {
                final sel = _period == i;
                return GestureDetector(
                  onTap: () => setState(() => _period = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: sel
                          ? const LinearGradient(colors: [
                        TradeColors.teal,
                        Color(0xFF0080FF)
                      ])
                          : null,
                      color: sel ? null : TradeColors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_periods[i],
                        style: TextStyle(
                            color:
                            sel ? Colors.white : TradeColors.txtSec,
                            fontSize: 12,
                            fontWeight: sel
                                ? FontWeight.w700
                                : FontWeight.w500)),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: CustomPaint(
              painter: LineChartPainter(
                data: widget.data,
                lineColor: TradeColors.teal,
                fillColor: TradeColors.teal.withOpacity(0.08),
              ),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TRADE DRAWER
// ─────────────────────────────────────────────────────────────────────────────

class _TradeDrawer extends StatefulWidget {
  final VoidCallback onSwitchToFms;
  const _TradeDrawer({required this.onSwitchToFms});

  @override
  State<_TradeDrawer> createState() => _TradeDrawerState();
}

class _TradeDrawerState extends State<_TradeDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _headerAnim;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _headerFade =
        CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut);
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, -0.15), end: Offset.zero)
            .animate(CurvedAnimation(
            parent: _headerAnim, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF0D1F2D),
      width: MediaQuery.of(context).size.width * 0.80,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildEnvToggle(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              physics: const BouncingScrollPhysics(),
              children: [
                _sectionLabel('TRADE NAVIGATION'),
                const SizedBox(height: 4),
                _item(
                  icon: Icons.pie_chart_rounded,
                  label: 'Portfolio',
                  color: TradeColors.teal,
                  delay: 0,
                  onTap: () => Navigator.pop(context),
                ),
                _item(
                  icon: Icons.bar_chart_rounded,
                  label: 'Markets',
                  color: const Color(0xFF4CAF50),
                  delay: 50,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const MarketsPage()));
                  },
                ),
                _item(
                  icon: Icons.star_rounded,
                  label: 'Watchlist',
                  color: TradeColors.gold,
                  delay: 100,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const WatchlistPage()));
                  },
                ),
                _item(
                  icon: Icons.list_alt_rounded,
                  label: 'Holdings',
                  color: TradeColors.teal,
                  delay: 150,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const HoldingsPage()));
                  },
                ),
                _item(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  color: const Color(0xFFAB47BC),
                  delay: 200,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const ProfilePage()));
                  },
                ),
              ],
            ),
          ),
          _buildSwitchToFms(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SlideTransition(
      position: _headerSlide,
      child: FadeTransition(
        opacity: _headerFade,
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF004D66),
                Color(0xFF003D55),
                Color(0xFF001F2E),
              ],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(5),
              bottomRight: Radius.circular(5),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [TradeColors.teal, Color(0xFF0080FF)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: TradeColors.teal.withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('TI',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1.5)),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: TradeColors.green,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFF003D55), width: 2),
                          ),
                          child: const Icon(Icons.check,
                              size: 10, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text('TSL Investor',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2)),
                  const SizedBox(height: 4),
                  const Text('Trade Account',
                      style: TextStyle(
                          color: TradeColors.teal,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.15), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.account_balance_wallet_outlined,
                            size: 12, color: TradeColors.teal),
                        SizedBox(width: 5),
                        Text('TZS 21,200,000',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnvToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 12,
                  decoration: BoxDecoration(
                    color: TradeColors.gold,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 7),
                const Text('ENVIRONMENT',
                    style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: TradeColors.txtSec,
                        letterSpacing: 1.8)),
              ],
            ),
          ),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border:
              Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: FractionallySizedBox(
                    widthFactor: 0.5,
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE67E22), Color(0xFFFFB347)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color:
                            const Color(0xFFE67E22).withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          widget.onSwitchToFms();
                        },
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.account_balance_outlined,
                                  size: 14, color: TradeColors.txtSec),
                              SizedBox(width: 5),
                              Text('FMS',
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: TradeColors.txtSec,
                                      letterSpacing: 0.3)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.candlestick_chart_outlined,
                                size: 14, color: Colors.white),
                            SizedBox(width: 5),
                            Text('Trade',
                                style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.3)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 12,
            decoration: BoxDecoration(
              color: TradeColors.teal,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 7),
          Text(text,
              style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: TradeColors.txtSec,
                  letterSpacing: 1.8)),
        ],
      ),
    );
  }

  Widget _item({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + delay),
      curve: Curves.easeOut,
      builder: (ctx, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
            offset: Offset(-20 * (1 - value), 0), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            splashColor: color.withOpacity(0.12),
            highlightColor: color.withOpacity(0.06),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 13),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(label,
                        style: const TextStyle(
                            color: TradeColors.txtPrim,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            letterSpacing: 0.1)),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      size: 16,
                      color: TradeColors.txtSec.withOpacity(0.4)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchToFms() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          widget.onSwitchToFms();
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D3D5C), Color(0xFF0A2840)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: TradeColors.teal.withOpacity(0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: TradeColors.teal.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D99), Color(0xFF4CAF50)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color:
                        const Color(0xFF2E7D99).withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.account_balance_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Switch to FMS',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                      SizedBox(height: 2),
                      Text('Fund Management System',
                          style: TextStyle(
                              color: TradeColors.txtSec, fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: TradeColors.teal.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.swap_horiz_rounded,
                      size: 16, color: TradeColors.teal),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}