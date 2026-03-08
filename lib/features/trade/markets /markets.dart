import 'package:flutter/material.dart';
import '../trade/trade_shared.dart';


class MarketsPage extends StatefulWidget {
  const MarketsPage({Key? key}) : super(key: key);

  @override
  State<MarketsPage> createState() => _MarketsPageState();
}

class _MarketsPageState extends State<MarketsPage>
    with TickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _fade;
  int _tab = 0; // 0=All, 1=Gainers, 2=Losers

  static const _indices = [
    {'name': 'DSE All Share', 'value': '3,842.10', 'change': '+1.2%', 'up': true},
    {'name': 'DSE 20',        'value': '1,924.50', 'change': '-0.4%', 'up': false},
    {'name': 'DSE Bank',      'value': '5,610.20', 'change': '+2.1%', 'up': true},
    {'name': 'DSE Industrial','value': '2,102.80', 'change': '+0.6%', 'up': true},
  ];

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  List<StockModel> get _tabStocks {
    if (_tab == 1) return kStocks.where((s) => s.isUp).toList();
    if (_tab == 2) return kStocks.where((s) => !s.isUp).toList();
    return kStocks;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TradeColors.bg,
      body: FadeTransition(
        opacity: _fade,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── App Bar ──────────────────────────────────────────────────
            SliverAppBar(
              backgroundColor: TradeColors.bg,
              pinned: true,
              elevation: 0,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: TradeColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: TradeColors.border),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 16, color: TradeColors.txtPrim),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('Markets',
                  style: TextStyle(
                      color: TradeColors.txtPrim,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _liveChip(),
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // ── Indices ────────────────────────────────────────────
                  const TradeSectionHeader(
                      title: 'DSE Indices',
                      icon: Icons.trending_up_rounded),
                  _buildIndicesScroll(),
                  const SizedBox(height: 20),

                  // ── Market summary cards ───────────────────────────────
                  const TradeSectionHeader(
                      title: 'Market Summary',
                      icon: Icons.bar_chart_rounded),
                  _buildSummaryCards(),
                  const SizedBox(height: 20),

                  // ── Stocks tabs ────────────────────────────────────────
                  TradeSectionHeader(
                    title: 'Stocks',
                    icon: Icons.list_alt_rounded,
                    trailing: _tabSwitcher(),
                  ),
                  ..._tabStocks.map((s) => TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    builder: (_, v, child) => Opacity(
                      opacity: v,
                      child: Transform.translate(
                          offset: Offset(0, 16 * (1 - v)),
                          child: child),
                    ),
                    child: StockTile(
                      stock: s,
                      onTap: () => showTradeSheet(context, s),
                    ),
                  )),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Live chip ──────────────────────────────────────────────────────────────
  Widget _liveChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: TradeColors.green.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TradeColors.green.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: TradeColors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          const Text('LIVE',
              style: TextStyle(
                  color: TradeColors.green,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1)),
        ],
      ),
    );
  }

  // ── Indices horizontal scroll ──────────────────────────────────────────────
  Widget _buildIndicesScroll() {
    return SizedBox(
      height: 108,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        itemCount: _indices.length,
        itemBuilder: (_, i) {
          final idx = _indices[i];
          final up = idx['up'] as bool;
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + i * 80),
            curve: Curves.easeOut,
            builder: (_, v, child) =>
                Opacity(opacity: v, child: child),
            child: Container(
              width: 156,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: up
                      ? [
                    const Color(0xFF0D3D2A),
                    const Color(0xFF0A2820)
                  ]
                      : [
                    const Color(0xFF3D0D1A),
                    const Color(0xFF280A10)
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color:
                    (up ? TradeColors.green : TradeColors.red)
                        .withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(idx['name'] as String,
                      style: const TextStyle(
                          color: TradeColors.txtSec, fontSize: 11)),
                  Text(idx['value'] as String,
                      style: const TextStyle(
                          color: TradeColors.txtPrim,
                          fontSize: 16,
                          fontWeight: FontWeight.w800)),
                  Row(
                    children: [
                      Icon(
                          up
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          size: 12,
                          color: up
                              ? TradeColors.green
                              : TradeColors.red),
                      const SizedBox(width: 3),
                      Text(idx['change'] as String,
                          style: TextStyle(
                              color: up
                                  ? TradeColors.green
                                  : TradeColors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Market summary cards ───────────────────────────────────────────────────
  Widget _buildSummaryCards() {
    final items = [
      {'icon': Icons.show_chart_rounded, 'label': 'Advancers', 'value': '8', 'color': TradeColors.green},
      {'icon': Icons.trending_down_rounded, 'label': 'Decliners', 'value': '3', 'color': TradeColors.red},
      {'icon': Icons.remove_rounded, 'label': 'Unchanged', 'value': '4', 'color': TradeColors.gold},
      {'icon': Icons.swap_horiz_rounded, 'label': 'Volume', 'value': '2.4M', 'color': TradeColors.teal},
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: items.map((item) {
          final color = item['color'] as Color;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(
                  right: item != items.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Icon(item['icon'] as IconData,
                      color: color, size: 20),
                  const SizedBox(height: 6),
                  Text(item['value'] as String,
                      style: TextStyle(
                          color: color,
                          fontSize: 15,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(item['label'] as String,
                      style: const TextStyle(
                          color: TradeColors.txtSec,
                          fontSize: 9),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Tab switcher (All / Gainers / Losers) ──────────────────────────────────
  Widget _tabSwitcher() {
    final tabs = ['All', 'Gainers', 'Losers'];
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: TradeColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: tabs.asMap().entries.map((e) {
          final sel = _tab == e.key;
          return GestureDetector(
            onTap: () => setState(() => _tab = e.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
              const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: sel
                    ? TradeColors.teal.withOpacity(0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: sel
                    ? Border.all(
                    color:
                    TradeColors.teal.withOpacity(0.4))
                    : null,
              ),
              child: Center(
                child: Text(e.value,
                    style: TextStyle(
                        color: sel
                            ? TradeColors.teal
                            : TradeColors.txtSec,
                        fontSize: 11,
                        fontWeight: sel
                            ? FontWeight.w700
                            : FontWeight.w500)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}