import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// THEME TOKENS
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  static const bg        = Color(0xFF080C14);
  static const surface   = Color(0xFF0F1520);
  static const card      = Color(0xFF131A27);
  static const border    = Color(0xFF1E2A3A);
  static const green     = Color(0xFF00D97E);
  static const red       = Color(0xFFFF4560);
  static const gray      = Color(0xFF8899AA);
  static const gold      = Color(0xFFFFBB33);
  static const teal      = Color(0xFF00C2FF);
  static const txtPrim   = Color(0xFFECF2FF);
  static const txtSec    = Color(0xFF6B7E96);
  static const txtHint   = Color(0xFF3D4F62);
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────
class DseStock {
  final String symbol;
  final String company;
  final String sector;
  final double price;
  final double change;
  final double changePercent;
  final String volume;
  final List<double> sparkline; // normalised 0-1

  const DseStock({
    required this.symbol,
    required this.company,
    required this.sector,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.volume,
    required this.sparkline,
  });

  bool get isGain   => changePercent > 0;
  bool get isLoss   => changePercent < 0;
  bool get isFlat   => changePercent == 0;

  Color get trendColor =>
      isGain ? _C.green : isLoss ? _C.red : _C.gray;

  Color get trendBg =>
      isGain
          ? _C.green.withOpacity(0.09)
          : isLoss
          ? _C.red.withOpacity(0.09)
          : _C.gray.withOpacity(0.07);
}

// ─────────────────────────────────────────────────────────────────────────────
// MOCK DATA — DSE listed companies
// ─────────────────────────────────────────────────────────────────────────────
final List<DseStock> kDseStocks = [
  DseStock(
    symbol: 'TBL',
    company: 'Tanzania Breweries Ltd',
    sector: 'Consumer Goods',
    price: 4800.00,
    change: 120.00,
    changePercent: 2.56,
    volume: '38.4K',
    sparkline: [0.42,0.45,0.43,0.50,0.55,0.52,0.58,0.61,0.60,0.64,0.62,0.68],
  ),
  DseStock(
    symbol: 'CRDB',
    company: 'CRDB Bank PLC',
    sector: 'Banking',
    price: 365.00,
    change: -8.00,
    changePercent: -2.14,
    volume: '1.2M',
    sparkline: [0.70,0.68,0.72,0.65,0.60,0.62,0.58,0.54,0.56,0.50,0.48,0.44],
  ),
  DseStock(
    symbol: 'NMB',
    company: 'NMB Bank PLC',
    sector: 'Banking',
    price: 4200.00,
    change: 0.00,
    changePercent: 0.00,
    volume: '12.1K',
    sparkline: [0.50,0.52,0.49,0.51,0.50,0.52,0.50,0.49,0.51,0.50,0.52,0.50],
  ),
  DseStock(
    symbol: 'SWISSPORT',
    company: 'Swissport Tanzania PLC',
    sector: 'Aviation',
    price: 630.00,
    change: 25.00,
    changePercent: 4.13,
    volume: '5.6K',
    sparkline: [0.30,0.33,0.36,0.34,0.38,0.42,0.46,0.44,0.50,0.55,0.58,0.62],
  ),
  DseStock(
    symbol: 'TOL',
    company: 'Tanga Cement PLC',
    sector: 'Construction',
    price: 1100.00,
    change: -45.00,
    changePercent: -3.93,
    volume: '9.8K',
    sparkline: [0.72,0.68,0.70,0.65,0.60,0.58,0.55,0.53,0.50,0.47,0.44,0.40],
  ),
  DseStock(
    symbol: 'DCB',
    company: 'DCB Commercial Bank',
    sector: 'Banking',
    price: 310.00,
    change: 5.00,
    changePercent: 1.64,
    volume: '22.3K',
    sparkline: [0.40,0.42,0.41,0.44,0.46,0.45,0.48,0.50,0.52,0.51,0.54,0.56],
  ),
  DseStock(
    symbol: 'TWIGA',
    company: 'Twiga Cement PLC',
    sector: 'Construction',
    price: 3600.00,
    change: -80.00,
    changePercent: -2.17,
    volume: '4.3K',
    sparkline: [0.65,0.63,0.67,0.61,0.58,0.60,0.56,0.53,0.55,0.50,0.48,0.45],
  ),
  DseStock(
    symbol: 'MUCOBA',
    company: 'Mufindi Community Bank',
    sector: 'Banking',
    price: 640.00,
    change: 0.00,
    changePercent: 0.00,
    volume: '800',
    sparkline: [0.50,0.51,0.50,0.49,0.51,0.50,0.50,0.49,0.51,0.50,0.50,0.51],
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// SPARKLINE PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final bool showFill;

  SparklinePainter({
    required this.data,
    required this.color,
    this.showFill = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = i / (data.length - 1) * size.width;
      final y = (1 - data[i]) * size.height;
      points.add(Offset(x, y));
    }

    // Build smooth path using cubic bezier
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final cp1 = Offset(
        (points[i].dx + points[i + 1].dx) / 2,
        points[i].dy,
      );
      final cp2 = Offset(
        (points[i].dx + points[i + 1].dx) / 2,
        points[i + 1].dy,
      );
      path.cubicTo(
        cp1.dx, cp1.dy,
        cp2.dx, cp2.dy,
        points[i + 1].dx, points[i + 1].dy,
      );
    }

    // Fill gradient
    if (showFill) {
      final fillPath = Path.from(path);
      fillPath.lineTo(size.width, size.height);
      fillPath.lineTo(0, size.height);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withOpacity(0.28),
            color.withOpacity(0.00),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill;
      canvas.drawPath(fillPath, fillPaint);
    }

    // Stroke
    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, strokePaint);

    // End dot
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(points.last, 3.0, dotPaint);
    canvas.drawCircle(
      points.last,
      3.0,
      Paint()
        ..color = color.withOpacity(0.3)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(SparklinePainter old) =>
      old.data != data || old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// MARKET SUMMARY BANNER
// ─────────────────────────────────────────────────────────────────────────────
class _MarketBanner extends StatelessWidget {
  final List<DseStock> stocks;
  const _MarketBanner({required this.stocks});

  @override
  Widget build(BuildContext context) {
    final gainers  = stocks.where((s) => s.isGain).length;
    final losers   = stocks.where((s) => s.isLoss).length;
    final flat     = stocks.where((s) => s.isFlat).length;
    final totalVol = '${(stocks.length * 0.3).toStringAsFixed(1)}M';

    final items = [
      _BannerItem(icon: Icons.trending_up_rounded,    label: 'Gainers',   value: '$gainers',  color: _C.green),
      _BannerItem(icon: Icons.trending_down_rounded,  label: 'Losers',    value: '$losers',   color: _C.red),
      _BannerItem(icon: Icons.remove_rounded,          label: 'Unchanged', value: '$flat',     color: _C.gray),
      _BannerItem(icon: Icons.bar_chart_rounded,      label: 'Volume',    value: totalVol,    color: _C.teal),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Row(
        children: items.asMap().entries.map((e) {
          final item  = e.value;
          final isLast = e.key == items.length - 1;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: isLast ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: item.color.withOpacity(0.18)),
              ),
              child: Column(
                children: [
                  Icon(item.icon, color: item.color, size: 18),
                  const SizedBox(height: 5),
                  Text(item.value,
                      style: TextStyle(
                          color: item.color,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5)),
                  const SizedBox(height: 2),
                  Text(item.label,
                      style: const TextStyle(
                          color: _C.txtSec, fontSize: 9,
                          fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _BannerItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _BannerItem({required this.icon, required this.label, required this.value, required this.color});
}

// ─────────────────────────────────────────────────────────────────────────────
// PLACE ORDER BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────
void _showOrderSheet(BuildContext context, DseStock stock) {
  HapticFeedback.mediumImpact();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _OrderSheet(stock: stock),
  );
}

class _OrderSheet extends StatefulWidget {
  final DseStock stock;
  const _OrderSheet({required this.stock});

  @override
  State<_OrderSheet> createState() => _OrderSheetState();
}

class _OrderSheetState extends State<_OrderSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  int _side   = 0; // 0 = Buy, 1 = Sell
  int _type   = 0; // 0 = Market, 1 = Limit
  int _qty    = 100;
  late double _limitPrice;

  @override
  void initState() {
    super.initState();
    _limitPrice = widget.stock.price;
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320))
      ..forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Color get _sideColor => _side == 0 ? _C.green : _C.red;
  String get _sideLabel => _side == 0 ? 'BUY' : 'SELL';

  @override
  Widget build(BuildContext context) {
    final total = (_qty * (_type == 0 ? widget.stock.price : _limitPrice));

    return SlideTransition(
      position: Tween<Offset>(
          begin: const Offset(0, 1), end: Offset.zero)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic)),
      child: Container(
        decoration: const BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: _C.border, width: 1)),
        ),
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: _C.border,
                  borderRadius: BorderRadius.circular(2)),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Place Order',
                          style: const TextStyle(
                              color: _C.txtPrim,
                              fontSize: 20,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text('${widget.stock.symbol} · ${widget.stock.company}',
                          style: const TextStyle(
                              color: _C.txtSec, fontSize: 12)),
                    ],
                  ),
                  // Live price badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: widget.stock.trendColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: widget.stock.trendColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'TZS ${widget.stock.price.toStringAsFixed(2)}',
                          style: TextStyle(
                              color: widget.stock.trendColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w900),
                        ),
                        Text(
                          '${widget.stock.changePercent >= 0 ? '+' : ''}${widget.stock.changePercent.toStringAsFixed(2)}%',
                          style: TextStyle(
                              color: widget.stock.trendColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Buy / Sell toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: _C.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _C.border),
                ),
                child: Row(
                  children: ['BUY', 'SELL'].asMap().entries.map((e) {
                    final sel = _side == e.key;
                    final col = e.key == 0 ? _C.green : _C.red;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _side = e.key);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            color: sel ? col.withOpacity(0.18) : Colors.transparent,
                            borderRadius: BorderRadius.circular(11),
                            border: sel
                                ? Border.all(color: col.withOpacity(0.5))
                                : null,
                          ),
                          child: Center(
                            child: Text(e.value,
                                style: TextStyle(
                                    color: sel ? col : _C.txtSec,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5)),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Order type
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text('Order Type',
                      style: TextStyle(color: _C.txtSec, fontSize: 12)),
                  const SizedBox(width: 12),
                  ...['Market', 'Limit'].asMap().entries.map((e) {
                    final sel = _type == e.key;
                    return GestureDetector(
                      onTap: () => setState(() => _type = e.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: sel
                              ? _C.teal.withOpacity(0.12)
                              : _C.card,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: sel
                                ? _C.teal.withOpacity(0.4)
                                : _C.border,
                          ),
                        ),
                        child: Text(e.value,
                            style: TextStyle(
                                color: sel ? _C.teal : _C.txtSec,
                                fontSize: 12,
                                fontWeight: sel
                                    ? FontWeight.w700
                                    : FontWeight.w500)),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quantity + Limit price row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Quantity stepper
                  Expanded(
                    child: _FieldBox(
                      label: 'Shares',
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _StepBtn(
                              icon: Icons.remove,
                              onTap: () => setState(
                                      () => _qty = max(1, _qty - 100))),
                          Text('$_qty',
                              style: const TextStyle(
                                  color: _C.txtPrim,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900)),
                          _StepBtn(
                              icon: Icons.add,
                              onTap: () => setState(() => _qty += 100)),
                        ],
                      ),
                    ),
                  ),
                  if (_type == 1) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FieldBox(
                        label: 'Limit Price (TZS)',
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _StepBtn(
                                icon: Icons.remove,
                                onTap: () => setState(() =>
                                _limitPrice = max(1, _limitPrice - 10))),
                            Text(_limitPrice.toStringAsFixed(0),
                                style: const TextStyle(
                                    color: _C.txtPrim,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900)),
                            _StepBtn(
                                icon: Icons.add,
                                onTap: () => setState(
                                        () => _limitPrice += 10)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Total estimate
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _sideColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _sideColor.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Estimated Total',
                        style: TextStyle(
                            color: _C.txtSec, fontSize: 12)),
                    Text(
                      'TZS ${_formatNum(total)}',
                      style: TextStyle(
                          color: _sideColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Confirm button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.heavyImpact();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '$_sideLabel order placed: $_qty shares of ${widget.stock.symbol}'),
                      backgroundColor: _sideColor.withOpacity(0.9),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _sideColor,
                        _sideColor.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _sideColor.withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$_sideLabel ${widget.stock.symbol}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNum(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000)    return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

class _FieldBox extends StatelessWidget {
  final String label;
  final Widget child;
  const _FieldBox({required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: _C.card,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _C.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: _C.txtSec,
                fontSize: 10,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        child,
      ],
    ),
  );
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: _C.border,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: _C.txtPrim, size: 14),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// STOCK CARD WITH SPARKLINE + PLACE ORDER
// ─────────────────────────────────────────────────────────────────────────────
class _StockCard extends StatefulWidget {
  final DseStock stock;
  final int index;
  const _StockCard({required this.stock, required this.index});

  @override
  State<_StockCard> createState() => _StockCardState();
}

class _StockCardState extends State<_StockCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 450))
      ..forward();
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final s = widget.stock;
    final color = s.trendColor;
    final sign  = s.isGain ? '+' : '';

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _C.border),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Top row: symbol info + sparkline ──────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Symbol avatar
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: color.withOpacity(0.25)),
                      ),
                      child: Center(
                        child: Text(
                          s.symbol.substring(0, min(2, s.symbol.length)),
                          style: TextStyle(
                              color: color,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Symbol + company
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.symbol,
                              style: const TextStyle(
                                  color: _C.txtPrim,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900)),
                          const SizedBox(height: 2),
                          Text(s.company,
                              style: const TextStyle(
                                  color: _C.txtSec, fontSize: 11),
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: _C.teal.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: _C.teal.withOpacity(0.2)),
                            ),
                            child: Text(s.sector,
                                style: const TextStyle(
                                    color: _C.teal,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),

                    // Sparkline chart
                    SizedBox(
                      width: 90,
                      height: 48,
                      child: CustomPaint(
                        painter: SparklinePainter(
                          data: s.sparkline,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Divider ──────────────────────────────────────────────
              Container(height: 1, color: _C.border),

              // ── Bottom row: price + change + volume + button ──────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                child: Row(
                  children: [
                    // Price block
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TZS ${s.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: _C.txtPrim,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5)),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            // Change badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: color.withOpacity(0.25)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    s.isGain
                                        ? Icons.arrow_upward_rounded
                                        : s.isLoss
                                        ? Icons.arrow_downward_rounded
                                        : Icons.remove_rounded,
                                    size: 10,
                                    color: color,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '$sign${s.changePercent.toStringAsFixed(2)}%',
                                    style: TextStyle(
                                        color: color,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Volume
                            Row(
                              children: [
                                const Icon(Icons.swap_vert_rounded,
                                    size: 11, color: _C.txtHint),
                                const SizedBox(width: 3),
                                Text('Vol ${s.volume}',
                                    style: const TextStyle(
                                        color: _C.txtSec,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),

                    // ── Place Order button ───────────────────────────
                    GestureDetector(
                      onTap: () => _showOrderSheet(context, s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _C.teal.withOpacity(0.9),
                              _C.teal.withOpacity(0.6),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: _C.teal.withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.add_rounded,
                                size: 13, color: _C.bg),
                            SizedBox(width: 4),
                            Text('Place Order',
                                style: TextStyle(
                                    color: _C.bg,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.2)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP INDICES HORIZONTAL SCROLL
// ─────────────────────────────────────────────────────────────────────────────
class _IndicesRow extends StatelessWidget {
  const _IndicesRow();

  final List<Map<String, dynamic>> _indices = const [
    {'name': 'DSEI',      'value': '2,841.67', 'change': '+0.84%',  'up': true},
    {'name': 'DSE-EAC',   'value': '1,124.30', 'change': '-0.32%',  'up': false},
    {'name': 'ALSI',      'value': '4,512.90', 'change': '+1.20%',  'up': true},
    {'name': 'DSE-BANK',  'value': '988.44',   'change': '0.00%',   'up': null},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        itemCount: _indices.length,
        itemBuilder: (_, i) {
          final item   = _indices[i];
          final isUp   = item['up'] as bool?;
          final color  = isUp == null ? _C.gray : isUp ? _C.green : _C.red;

          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + i * 80),
            curve: Curves.easeOut,
            builder: (_, v, child) =>
                Opacity(opacity: v, child: child),
            child: Container(
              width: 148,
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isUp == null
                      ? [
                    const Color(0xFF141E2A),
                    const Color(0xFF0F1822),
                  ]
                      : isUp
                      ? [
                    const Color(0xFF0A2E1E),
                    const Color(0xFF071A12),
                  ]
                      : [
                    const Color(0xFF2E0A14),
                    const Color(0xFF1A070C),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item['name'] as String,
                      style: const TextStyle(
                          color: _C.txtSec, fontSize: 10,
                          fontWeight: FontWeight.w600)),
                  Text(item['value'] as String,
                      style: const TextStyle(
                          color: _C.txtPrim,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5)),
                  Row(
                    children: [
                      Icon(
                        isUp == null
                            ? Icons.remove_rounded
                            : isUp
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 10,
                        color: color,
                      ),
                      const SizedBox(width: 3),
                      Text(item['change'] as String,
                          style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w800)),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;
  const _SectionHeader(
      {required this.title, required this.icon, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    child: Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _C.teal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _C.teal, size: 14),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                color: _C.txtPrim,
                fontSize: 13,
                fontWeight: FontWeight.w800)),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTER / SORT ROW
// ─────────────────────────────────────────────────────────────────────────────
class _FilterRow extends StatefulWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  const _FilterRow({required this.selected, required this.onChanged});

  @override
  State<_FilterRow> createState() => _FilterRowState();
}

class _FilterRowState extends State<_FilterRow> {
  final _tabs = ['All', 'Gainers', 'Losers', 'Unchanged'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: _tabs.asMap().entries.map((e) {
          final sel = widget.selected == e.key;
          final colors = [_C.teal, _C.green, _C.red, _C.gray];
          final col = colors[e.key];
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onChanged(e.key);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: sel ? col.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                border: sel
                    ? Border.all(color: col.withOpacity(0.4))
                    : null,
              ),
              child: Center(
                child: Text(e.value,
                    style: TextStyle(
                        color: sel ? col : _C.txtSec,
                        fontSize: 11,
                        fontWeight:
                        sel ? FontWeight.w700 : FontWeight.w500)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN PAGE
// ─────────────────────────────────────────────────────────────────────────────
class DseMarketWatchPage extends StatefulWidget {
  const DseMarketWatchPage({Key? key}) : super(key: key);

  @override
  State<DseMarketWatchPage> createState() => _DseMarketWatchPageState();
}

class _DseMarketWatchPageState extends State<DseMarketWatchPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _fade;
  int _filter = 0; // 0=All 1=Gainers 2=Losers 3=Unchanged

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400))
      ..forward();
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
  }

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  List<DseStock> get _filtered {
    switch (_filter) {
      case 1:  return kDseStocks.where((s) => s.isGain).toList();
      case 2:  return kDseStocks.where((s) => s.isLoss).toList();
      case 3:  return kDseStocks.where((s) => s.isFlat).toList();
      default: return kDseStocks;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: FadeTransition(
        opacity: _fade,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [

            // ── App Bar ────────────────────────────────────────────────
            SliverAppBar(
              backgroundColor: _C.bg,
              pinned: true,
              elevation: 0,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _C.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _C.border),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 14, color: _C.txtPrim),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('DSE Market Watch',
                      style: TextStyle(
                          color: _C.txtPrim,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3)),
                  Text('Dar es Salaam Stock Exchange',
                      style: TextStyle(
                          color: _C.txtSec, fontSize: 10)),
                ],
              ),
              actions: [
                // Live chip
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _C.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _C.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PulseDot(color: _C.green),
                      const SizedBox(width: 5),
                      const Text('LIVE',
                          style: TextStyle(
                              color: _C.green,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1)),
                    ],
                  ),
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // ── Indices ─────────────────────────────────────────
                  const _SectionHeader(
                      title: 'DSE Indices',
                      icon: Icons.show_chart_rounded),
                  const _IndicesRow(),
                  const SizedBox(height: 20),

                  // ── Market summary ──────────────────────────────────
                  const _SectionHeader(
                      title: 'Market Summary',
                      icon: Icons.bar_chart_rounded),
                  _MarketBanner(stocks: kDseStocks),

                  // ── Stocks with filter ──────────────────────────────
                  _SectionHeader(
                    title: 'Listed Securities',
                    icon: Icons.list_alt_rounded,
                    trailing: _FilterRow(
                      selected: _filter,
                      onChanged: (v) => setState(() => _filter = v),
                    ),
                  ),
                ],
              ),
            ),

            // ── Stock cards list ────────────────────────────────────────
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (_, i) {
                  if (i >= _filtered.length) return null;
                  final delay = Duration(milliseconds: 60 * i);
                  return FutureBuilder(
                    future: Future.delayed(delay),
                    builder: (_, snap) => snap.connectionState ==
                        ConnectionState.done
                        ? _StockCard(
                        stock: _filtered[i], index: i)
                        : const SizedBox.shrink(),
                  );
                },
                childCount: _filtered.length,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PULSING DOT
// ─────────────────────────────────────────────────────────────────────────────
class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.8, end: 1.2).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: _scale,
    child: Container(
      width: 6, height: 6,
      decoration: BoxDecoration(
          color: widget.color, shape: BoxShape.circle),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ENTRY POINT (for standalone testing)
// ─────────────────────────────────────────────────────────────────────────────
void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: DseMarketWatchPage(),
  ));
}