import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../trade/trade_shared.dart';


class WatchlistPage extends StatefulWidget {
  const WatchlistPage({Key? key}) : super(key: key);

  @override
  State<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _fade;

  // Simulate a small watched list
  final List<StockModel> _watched = [kStocks[0], kStocks[2]];

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

  void _removeFromWatchlist(StockModel stock) {
    HapticFeedback.lightImpact();
    setState(() => _watched.remove(stock));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${stock.symbol} removed from watchlist'),
        backgroundColor: TradeColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'Undo',
          textColor: TradeColors.teal,
          onPressed: () => setState(() => _watched.add(stock)),
        ),
      ),
    );
  }

  void _addStock(StockModel stock) {
    HapticFeedback.selectionClick();
    if (!_watched.contains(stock)) {
      setState(() => _watched.add(stock));
    }
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
              title: const Text('Watchlist',
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
                      color: TradeColors.gold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: TradeColors.gold.withOpacity(0.3)),
                    ),
                    child: Text('${_watched.length} watching',
                        style: const TextStyle(
                            color: TradeColors.gold,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: _watched.isEmpty
                  ? _buildEmptyState()
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const TradeSectionHeader(
                      title: 'Watching',
                      icon: Icons.star_rounded),
                  ..._watched.map((s) => _WatchTile(
                    stock: s,
                    onTap: () =>
                        showTradeSheet(context, s),
                    onRemove: () =>
                        _removeFromWatchlist(s),
                  )),
                  const SizedBox(height: 24),
                  TradeSectionHeader(
                    title: 'Add More',
                    icon: Icons.add_circle_outline_rounded,
                    trailing: const SizedBox(),
                  ),
                  ...kStocks
                      .where((s) => !_watched.contains(s))
                      .map((s) => _AddableTile(
                    stock: s,
                    onAdd: () => _addStock(s),
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

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: TradeColors.gold.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(
                    color: TradeColors.gold.withOpacity(0.2)),
              ),
              child: Icon(Icons.star_border_rounded,
                  size: 48, color: TradeColors.gold.withOpacity(0.6)),
            ),
            const SizedBox(height: 20),
            const Text('Your watchlist is empty',
                style: TextStyle(
                    color: TradeColors.txtPrim,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Tap + on any stock to start watching',
                style: TextStyle(
                    color: TradeColors.txtSec, fontSize: 13)),
            const SizedBox(height: 32),
            ...kStocks.map((s) => _AddableTile(
              stock: s,
              onAdd: () => _addStock(s),
            )),
          ],
        ),
      ),
    );
  }
}

// ── Watched tile (swipeable to remove) ────────────────────────────────────────

class _WatchTile extends StatelessWidget {
  final StockModel stock;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  const _WatchTile(
      {required this.stock,
        required this.onTap,
        required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(stock.symbol),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        decoration: BoxDecoration(
          color: TradeColors.red.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: TradeColors.red, size: 24),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TradeColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: TradeColors.gold.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              // Star
              const Icon(Icons.star_rounded,
                  color: TradeColors.gold, size: 18),
              const SizedBox(width: 10),
              // Badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: stock.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: stock.color.withOpacity(0.3)),
                ),
                child: Center(
                  child: Text(stock.symbol.substring(0, 2),
                      style: TextStyle(
                          color: stock.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stock.symbol,
                        style: const TextStyle(
                            color: TradeColors.txtPrim,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                    Text(stock.name,
                        style: const TextStyle(
                            color: TradeColors.txtSec,
                            fontSize: 11)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('TZS ${stock.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: TradeColors.txtPrim,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    '${stock.isUp ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%',
                    style: TextStyle(
                        color: stock.isUp
                            ? TradeColors.green
                            : TradeColors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Addable tile ──────────────────────────────────────────────────────────────

class _AddableTile extends StatelessWidget {
  final StockModel stock;
  final VoidCallback onAdd;
  const _AddableTile({required this.stock, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: TradeColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TradeColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: stock.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(stock.symbol.substring(0, 2),
                  style: TextStyle(
                      color: stock.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stock.symbol,
                    style: const TextStyle(
                        color: TradeColors.txtPrim,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                Text(stock.name,
                    style: const TextStyle(
                        color: TradeColors.txtSec, fontSize: 11)),
              ],
            ),
          ),
          Text(
            '${stock.isUp ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%',
            style: TextStyle(
                color: stock.isUp ? TradeColors.green : TradeColors.red,
                fontSize: 12,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: TradeColors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: TradeColors.teal.withOpacity(0.3)),
              ),
              child: const Icon(Icons.add_rounded,
                  color: TradeColors.teal, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}