import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../buysell/buy.dart';
import '../buysell/sell.dart';
import '../market_watch/market_watch.dart';
import 'drawer.dart';

// ─────────────────────────────────────────────────────────────────────────────
// THEME COLORS
// ─────────────────────────────────────────────────────────────────────────────
class PastelColors {
  static const Color bg      = Color(0xFFEAF5F0);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card    = Color(0xFFFFFFFF);
  static const Color border  = Color(0xFFCDE9DE);

  static const Color accent   = Color(0xFF2E7D99);
  static const Color accent2  = Color(0xFF2E7D32);
  static const Color accentLt = Color(0xFFE0F4F0);

  static const Color green   = Color(0xFF34C759);
  static const Color greenLt = Color(0xFFEBFBF2);
  static const Color red     = Color(0xFFFF6B8A);
  static const Color redLt   = Color(0xFFFFEEF2);
  static const Color gold    = Color(0xFFF5A623);
  static const Color goldLt  = Color(0xFFFFF8EC);

  static const Color txtPrim = Color(0xFF0F2318);
  static const Color txtSec  = Color(0xFF5E8A7A);
  static const Color txtHint = Color(0xFFA0C4B8);

  static const List<Color> heroGrad  = [Color(0xFF2E7D99), Color(0xFF1A5F77), Color(0xFF2E7D32)];
  static const List<Color> fabGrad   = [Color(0xFF2E7D99), Color(0xFF1A5F77)];
  static const List<Color> buyGrad   = [Color(0xFF4CAF50), Color(0xFF2E7D32)];
  static const List<Color> sellGrad  = [Color(0xFFFF8AA8), Color(0xFFFF6B8A)];
}

// ─────────────────────────────────────────────────────────────────────────────
// ORDER MODEL
// ─────────────────────────────────────────────────────────────────────────────
class _Order {
  final String symbol;
  final String company;
  final String type;
  final String status;
  final String time;
  final double price;
  final int quantity;

  const _Order({
    required this.symbol,
    required this.company,
    required this.type,
    required this.status,
    required this.time,
    required this.price,
    required this.quantity,
  });
}

const List<_Order> _kOrders = [
  _Order(symbol: 'CRDB', company: 'CRDB Bank',         type: 'BUY',  status: 'Filled',    time: 'Today, 09:42',     price: 420.00,  quantity: 500),
  _Order(symbol: 'NMB',  company: 'NMB Bank',           type: 'SELL', status: 'Filled',    time: 'Today, 10:15',     price: 3850.00, quantity: 100),
  _Order(symbol: 'TBL',  company: 'Tanzania Breweries', type: 'BUY',  status: 'Pending',   time: 'Today, 11:02',     price: 2750.00, quantity: 200),
  _Order(symbol: 'DCB',  company: 'DCB Commercial',     type: 'BUY',  status: 'Filled',    time: 'Yesterday, 14:30', price: 390.00,  quantity: 1000),
  _Order(symbol: 'SWIS', company: 'Swissport TZ',       type: 'SELL', status: 'Cancelled', time: 'Yesterday, 15:55', price: 620.00,  quantity: 150),
  _Order(symbol: 'TOL',  company: 'Tanga Cement',       type: 'BUY',  status: 'Filled',    time: 'Mon, 09:10',       price: 1180.00, quantity: 300),
];

// ─────────────────────────────────────────────────────────────────────────────
// MAIN WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class TradeDashboard extends StatefulWidget {
  const TradeDashboard({Key? key}) : super(key: key);

  @override
  State<TradeDashboard> createState() => _TradeDashboardState();
}

class _TradeDashboardState extends State<TradeDashboard>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late AnimationController _pageAnim;
  late Animation<double>   _pageFade;

  @override
  void initState() {
    super.initState();
    _pageAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _pageFade = CurvedAnimation(parent: _pageAnim, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _pageAnim.dispose();
    super.dispose();
  }

  void _push(Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => page,
        transitionsBuilder: (_, animation, __, child) {
          final c = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
          return FadeTransition(
            opacity: c,
            child: SlideTransition(
              position: Tween<Offset>(
                  begin: const Offset(0.05, 0), end: Offset.zero)
                  .animate(c),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 380),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: PastelColors.bg,
        drawer: TradeDrawer(
          onSwitchToFms: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
        ),
        body: FadeTransition(
          opacity: _pageFade,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildPortfolioCard(),
                    const SizedBox(height: 20),
                    _buildActionGrid(),
                    const SizedBox(height: 20),
                    _buildFmsShortcut(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── App bar ────────────────────────────────────────────────────────────────
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: PastelColors.bg,
      expandedHeight: 70,
      floating: true,
      pinned: true,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: _iconBox(Icons.menu_rounded),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: PastelColors.fabGrad),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                  color: PastelColors.accent.withOpacity(0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3)),
            ],
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
                color: PastelColors.txtPrim,
                fontSize: 18,
                fontWeight: FontWeight.w800)),
      ]),
      actions: [
        IconButton(
          icon: _iconBox(Icons.notifications_none_rounded, badge: true),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _iconBox(IconData icon, {bool badge = false}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: PastelColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PastelColors.border),
        boxShadow: [
          BoxShadow(
              color: PastelColors.accent.withOpacity(0.10),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Stack(clipBehavior: Clip.none, children: [
        Icon(icon, size: 18, color: PastelColors.txtPrim),
        if (badge)
          Positioned(
            right: -1, top: -1,
            child: Container(
              width: 6, height: 6,
              decoration:
              const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
            ),
          ),
      ]),
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
            colors: PastelColors.heroGrad,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: PastelColors.accent.withOpacity(0.30),
                blurRadius: 30,
                offset: const Offset(0, 10)),
          ],
        ),
        child: Stack(children: [
          Positioned(
            top: -20, right: -20,
            child: Container(
              width: 140, height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  Colors.white.withOpacity(0.18), Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: -30, left: 20,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  Colors.white.withOpacity(0.10), Colors.transparent,
                ]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Portfolio Value',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                  _changeChip('+5.8% today', PastelColors.green),
                ],
              ),
              const SizedBox(height: 10),
              const Text('TZS 21,200,000',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Row(children: const [
                Icon(Icons.trending_up_rounded, size: 16, color: Color(0xFF4ADE80)),
                SizedBox(width: 4),
                Text('+TZS 1,160,000 this month',
                    style: TextStyle(color: Color(0xFF4ADE80), fontSize: 13)),
              ]),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  _miniStat('Day P&L', '+TZS 48,200', const Color(0xFF4ADE80)),
                  _vDivider(),
                  _miniStat('Invested', 'TZS 18.5M', Colors.white70),
                  _vDivider(),
                  _miniStat('Returns', '+14.6%', PastelColors.gold),
                ]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _changeChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.arrow_upward_rounded, size: 11, color: color),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _miniStat(String label, String value, Color color) => Expanded(
    child: Column(children: [
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      const SizedBox(height: 4),
      Text(value,
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
    ]),
  );

  Widget _vDivider() => Container(height: 32, width: 1, color: Colors.white24);

  // ── 2 × 2 Action Grid ─────────────────────────────────────────────────────
  //   [ BUY  gradient ]  [ SELL gradient ]
  //   [ My Orders     ]  [ Market Watch  ]
  Widget _buildActionGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        // Row 1 — primary trade buttons
        Row(children: [
          Expanded(
            child: _primaryBtn(
              label: 'Buy',
              icon: Icons.trending_up_rounded,
              grad: PastelColors.buyGrad,
              shadow: PastelColors.accent2,
              onTap: () {
                HapticFeedback.mediumImpact();
                _push(const BuySharesPage());
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _primaryBtn(
              label: 'Sell',
              icon: Icons.trending_down_rounded,
              grad: PastelColors.sellGrad,
              shadow: PastelColors.red,
              onTap: () {
                HapticFeedback.mediumImpact();
                _push(const SellSharesPage());
              },
            ),
          ),
        ]),
        const SizedBox(height: 12),
        // Row 2 — secondary actions
        Row(children: [
          Expanded(
            child: _secondaryBtn(
              label: 'My Orders',
              sublabel: '${_kOrders.length} orders',
              icon: Icons.receipt_long_rounded,
              iconColor: PastelColors.accent,
              iconBg: PastelColors.accentLt,
              borderColor: PastelColors.accent.withOpacity(0.30),
              onTap: () {
                HapticFeedback.mediumImpact();
                _push(const _OrdersPage());
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _secondaryBtn(
              label: 'Market Watch',
              sublabel: 'DSE live',
              icon: Icons.bar_chart_rounded,
              iconColor: PastelColors.gold,
              iconBg: PastelColors.goldLt,
              borderColor: PastelColors.gold.withOpacity(0.30),
              onTap: () {
                HapticFeedback.mediumImpact();
                _push(const DseMarketWatchPage());
              },
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _primaryBtn({
    required String label,
    required IconData icon,
    required List<Color> grad,
    required Color shadow,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: grad, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: shadow.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4)),
        ]),
      ),
    );
  }

  Widget _secondaryBtn({
    required String label,
    required String sublabel,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: PastelColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
                color: PastelColors.accent.withOpacity(0.07),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: const TextStyle(
                      color: PastelColors.txtPrim,
                      fontSize: 13,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(sublabel,
                  style: const TextStyle(color: PastelColors.txtHint, fontSize: 11)),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: PastelColors.txtHint, size: 18),
        ]),
      ),
    );
  }

  // ── FMS shortcut ───────────────────────────────────────────────────────────
  Widget _buildFmsShortcut() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          Navigator.pop(context);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFD4EEF9), Color(0xFFE8F5E9), Color(0xFFB8E6D3)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: PastelColors.accent.withOpacity(0.25), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: PastelColors.accent.withOpacity(0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: PastelColors.fabGrad,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: PastelColors.accent.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: const Icon(Icons.account_balance_rounded,
                  color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                Text('Fund Management System',
                    style: TextStyle(
                        color: PastelColors.txtPrim,
                        fontSize: 15,
                        fontWeight: FontWeight.w800)),
                SizedBox(height: 3),
                Text('Tap to open FMS dashboard →',
                    style: TextStyle(
                        color: PastelColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ]),
            ),
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: PastelColors.accent.withOpacity(0.25)),
              ),
              child: const Icon(Icons.arrow_forward_rounded,
                  color: PastelColors.accent, size: 18),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ORDERS PAGE
// ─────────────────────────────────────────────────────────────────────────────
class _OrdersPage extends StatefulWidget {
  const _OrdersPage({Key? key}) : super(key: key);

  @override
  State<_OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<_OrdersPage> {
  int _filterIndex = 0;

  List<_Order> get _filtered {
    if (_filterIndex == 1) return _kOrders.where((o) => o.type == 'BUY').toList();
    if (_filterIndex == 2) return _kOrders.where((o) => o.type == 'SELL').toList();
    return _kOrders;
  }

  @override
  Widget build(BuildContext context) {
    final filled    = _kOrders.where((o) => o.status == 'Filled').length;
    final pending   = _kOrders.where((o) => o.status == 'Pending').length;
    final cancelled = _kOrders.where((o) => o.status == 'Cancelled').length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: PastelColors.bg,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── App bar ───────────────────────────────────────────────────
            SliverAppBar(
              backgroundColor: PastelColors.bg,
              elevation: 0,
              floating: true,
              pinned: true,
              automaticallyImplyLeading: false,
              leading: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: PastelColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: PastelColors.border),
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        size: 18, color: PastelColors.txtPrim),
                  ),
                ),
              ),
              title: Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: PastelColors.fabGrad),
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
                const Text('My Orders',
                    style: TextStyle(
                        color: PastelColors.txtPrim,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
              ]),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(children: [
                  // Summary card
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: PastelColors.heroGrad),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: PastelColors.accent.withOpacity(0.28),
                            blurRadius: 24,
                            offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Row(children: [
                      _stat('${_kOrders.length}', 'Total',     Colors.white),
                      _sDivider(),
                      _stat('$filled',            'Filled',    const Color(0xFF4ADE80)),
                      _sDivider(),
                      _stat('$pending',           'Pending',   PastelColors.gold),
                      _sDivider(),
                      _stat('$cancelled',         'Cancelled', PastelColors.red),
                    ]),
                  ),
                  const SizedBox(height: 18),
                  // Filter chips
                  _buildFilterChips(),
                  const SizedBox(height: 16),
                ]),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _OrderCard(order: _filtered[i]),
                  childCount: _filtered.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label, Color color) => Expanded(
    child: Column(children: [
      Text(value,
          style: TextStyle(
              color: color, fontSize: 22, fontWeight: FontWeight.w900)),
      const SizedBox(height: 2),
      Text(label,
          style: const TextStyle(color: Colors.white60, fontSize: 10)),
    ]),
  );

  Widget _sDivider() => Container(height: 36, width: 1, color: Colors.white24);

  Widget _buildFilterChips() {
    const labels = ['All', 'Buy', 'Sell'];
    const colors = [PastelColors.accent, PastelColors.accent2, PastelColors.red];

    return Row(
      children: List.generate(labels.length, (i) {
        final sel = _filterIndex == i;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _filterIndex = i);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            decoration: BoxDecoration(
              color: sel ? colors[i] : PastelColors.surface,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                  color: sel ? colors[i] : PastelColors.border, width: 1.5),
              boxShadow: sel
                  ? [BoxShadow(
                  color: colors[i].withOpacity(0.30),
                  blurRadius: 10,
                  offset: const Offset(0, 4))]
                  : [],
            ),
            child: Text(labels[i],
                style: TextStyle(
                    color: sel ? Colors.white : PastelColors.txtSec,
                    fontSize: 13,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ORDER CARD
// ─────────────────────────────────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final _Order order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final isBuy     = order.type == 'BUY';
    final grad      = isBuy ? PastelColors.buyGrad  : PastelColors.sellGrad;
    final typeBg    = isBuy ? PastelColors.greenLt  : PastelColors.redLt;
    final typeColor = isBuy ? PastelColors.accent2   : PastelColors.red;

    Color statusColor;
    Color statusBg;
    IconData statusIcon;
    switch (order.status) {
      case 'Filled':
        statusColor = PastelColors.green;
        statusBg    = PastelColors.greenLt;
        statusIcon  = Icons.check_circle_rounded;
        break;
      case 'Pending':
        statusColor = PastelColors.gold;
        statusBg    = PastelColors.goldLt;
        statusIcon  = Icons.schedule_rounded;
        break;
      default:
        statusColor = PastelColors.txtHint;
        statusBg    = PastelColors.border;
        statusIcon  = Icons.cancel_rounded;
    }

    final total = (order.price * order.quantity)
        .toStringAsFixed(0)
        .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: PastelColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PastelColors.border),
        boxShadow: [
          BoxShadow(
              color: PastelColors.accent.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Colored left bar
            Container(
              width: 5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: grad,
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Symbol · company · status
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          gradient: LinearGradient(colors: grad),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(order.symbol,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(order.company,
                          style: const TextStyle(
                              color: PastelColors.txtPrim,
                              fontSize: 14,
                              fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                          color: statusBg, borderRadius: BorderRadius.circular(20)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(statusIcon, size: 11, color: statusColor),
                        const SizedBox(width: 3),
                        Text(order.status,
                            style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  // Type · shares · price
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: typeBg, borderRadius: BorderRadius.circular(6)),
                      child: Text(order.type,
                          style: TextStyle(
                              color: typeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8)),
                    ),
                    const SizedBox(width: 8),
                    Text('${order.quantity} shares',
                        style: const TextStyle(
                            color: PastelColors.txtSec, fontSize: 12)),
                    const Spacer(),
                    Text('TZS ${order.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                            color: PastelColors.txtPrim,
                            fontSize: 14,
                            fontWeight: FontWeight.w800)),
                  ]),
                  const SizedBox(height: 6),
                  // Time · total
                  Row(children: [
                    const Icon(Icons.access_time_rounded,
                        size: 11, color: PastelColors.txtHint),
                    const SizedBox(width: 4),
                    Text(order.time,
                        style: const TextStyle(
                            color: PastelColors.txtHint, fontSize: 11)),
                    const Spacer(),
                    Text('Total: TZS $total',
                        style: const TextStyle(
                            color: PastelColors.txtSec,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ]),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}