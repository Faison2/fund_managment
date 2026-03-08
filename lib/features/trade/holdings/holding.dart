import 'package:flutter/material.dart';

import '../trade/trade_shared.dart';


class HoldingsPage extends StatefulWidget {
  const HoldingsPage({Key? key}) : super(key: key);

  @override
  State<HoldingsPage> createState() => _HoldingsPageState();
}

class _HoldingsPageState extends State<HoldingsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _fade;
  String _filter = 'All';

  final _filters = ['All', 'Banking', 'Consumer', 'Exchange'];

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

  List<StockModel> get _filtered => _filter == 'All'
      ? kStocks
      : kStocks.where((s) => s.sector == _filter).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TradeColors.bg,
      body: FadeTransition(
        opacity: _fade,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── App bar ────────────────────────────────────────────────
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
              title: const Text('My Holdings',
                  style: TextStyle(
                      color: TradeColors.txtPrim,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: TradeColors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: TradeColors.teal.withOpacity(0.3)),
                    ),
                    child: Text('${kStocks.length} stocks',
                        style: const TextStyle(
                            color: TradeColors.teal,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),

            // ── Summary banner ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _buildSummaryBanner(),
              ),
            ),

            // ── Filter chips ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: _buildFilterChips(),
            ),

            // ── Holdings list ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  children: [
                    ..._filtered.asMap().entries.map((e) {
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration:
                        Duration(milliseconds: 350 + e.key * 70),
                        curve: Curves.easeOut,
                        builder: (_, v, child) => Opacity(
                          opacity: v,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - v)),
                            child: child,
                          ),
                        ),
                        child: _HoldingDetailTile(
                          stock: e.value,
                          onTap: () =>
                              showTradeSheet(context, e.value),
                        ),
                      );
                    }),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D3D5C), Color(0xFF061820)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: TradeColors.teal.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          _stat('Invested', 'TZS 18.5M', TradeColors.txtSec),
          _vDivider(),
          _stat('Current', 'TZS 21.2M', TradeColors.teal),
          _vDivider(),
          _stat('Gain', '+TZS 2.7M', TradeColors.green),
          _vDivider(),
          _stat('Return', '+14.6%', TradeColors.gold),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  color: TradeColors.txtSec, fontSize: 10)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(
      height: 28, width: 1, color: Colors.white.withOpacity(0.08));

  Widget _buildFilterChips() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        itemCount: _filters.length,
        itemBuilder: (_, i) {
          final sel = _filter == _filters[i];
          return GestureDetector(
            onTap: () => setState(() => _filter = _filters[i]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: sel
                    ? const LinearGradient(colors: [
                  TradeColors.teal,
                  Color(0xFF0080FF)
                ])
                    : null,
                color: sel ? null : TradeColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: sel
                    ? null
                    : Border.all(color: TradeColors.border),
              ),
              child: Text(_filters[i],
                  style: TextStyle(
                      color: sel
                          ? Colors.white
                          : TradeColors.txtSec,
                      fontSize: 12,
                      fontWeight: sel
                          ? FontWeight.w700
                          : FontWeight.w500)),
            ),
          );
        },
      ),
    );
  }
}

// ── Expanded holding tile with P&L ────────────────────────────────────────────

class _HoldingDetailTile extends StatelessWidget {
  final StockModel stock;
  final VoidCallback onTap;
  const _HoldingDetailTile(
      {required this.stock, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = stock;
    // Fake positions
    final shares = (s.allocation * 10).toInt();
    final avgCost = s.price * 0.88;
    final invested = avgCost * shares;
    final current = s.price * shares;
    final gain = current - invested;
    final gainPct = (gain / invested) * 100;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        decoration: BoxDecoration(
          color: TradeColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: TradeColors.border),
        ),
        child: Column(
          children: [
            // Top row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: s.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                          color: s.color.withOpacity(0.3)),
                    ),
                    child: Center(
                      child: Text(s.symbol.substring(0, 2),
                          style: TextStyle(
                              color: s.color,
                              fontSize: 14,
                              fontWeight: FontWeight.w900)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.symbol,
                            style: const TextStyle(
                                color: TradeColors.txtPrim,
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                        Text(s.name,
                            style: const TextStyle(
                                color: TradeColors.txtSec,
                                fontSize: 11)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('TZS ${s.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                              color: TradeColors.txtPrim,
                              fontWeight: FontWeight.w800,
                              fontSize: 15)),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (s.isUp
                              ? TradeColors.green
                              : TradeColors.red)
                              .withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${s.isUp ? '+' : ''}${s.changePercent.toStringAsFixed(2)}%',
                          style: TextStyle(
                              color: s.isUp
                                  ? TradeColors.green
                                  : TradeColors.red,
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Divider
            Divider(
                height: 1,
                color: Colors.white.withOpacity(0.06),
                indent: 16,
                endIndent: 16),

            // Stats row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Row(
                children: [
                  _cell('Shares', '$shares'),
                  _cell('Avg Cost',
                      'TZS ${avgCost.toStringAsFixed(0)}'),
                  _cell('Invested',
                      'TZS ${(invested / 1000).toStringAsFixed(1)}K'),
                  _cell(
                    'P&L',
                    '${gainPct >= 0 ? '+' : ''}${gainPct.toStringAsFixed(1)}%',
                    color: gainPct >= 0
                        ? TradeColors.green
                        : TradeColors.red,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(String label, String value, {Color? color}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: TradeColors.txtSec, fontSize: 10)),
          const SizedBox(height: 3),
          Text(value,
              style: TextStyle(
                  color: color ?? TradeColors.txtPrim,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}