// trade_shared.dart
// Shared models, sample data, painters, constants used across all Trade pages.

import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PALETTE
// ─────────────────────────────────────────────────────────────────────────────

class TradeColors {
  static const bg      = Color(0xFF050D12);
  static const surface = Color(0xFF0D1F2D);
  static const card    = Color(0xFF112233);
  static const border  = Color(0x1A4FFFFF);
  static const teal    = Color(0xFF00D4FF);
  static const green   = Color(0xFF00E676);
  static const red     = Color(0xFFFF4C6A);
  static const gold    = Color(0xFFFFB347);
  static const txtPrim = Colors.white;
  static const txtSec  = Color(0xFF8899AA);
  static const txtHint = Color(0xFF556677);
}

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────

class StockModel {
  final String symbol, name, sector;
  final double price, change, changePercent;
  final Color color;
  final List<double> sparkline;
  final double allocation;

  const StockModel({
    required this.symbol,
    required this.name,
    required this.sector,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.color,
    required this.sparkline,
    required this.allocation,
  });

  bool get isUp => change >= 0;
}

// ─────────────────────────────────────────────────────────────────────────────
// SAMPLE DATA
// ─────────────────────────────────────────────────────────────────────────────

const kStocks = <StockModel>[
  StockModel(
    symbol: 'CRDB', name: 'CRDB Bank', sector: 'Banking',
    price: 580.0, change: 12.5, changePercent: 2.20,
    color: Color(0xFF2E7D99),
    sparkline: [510, 520, 505, 535, 548, 542, 555, 560, 572, 580],
    allocation: 32,
  ),
  StockModel(
    symbol: 'NMB', name: 'NMB Bank', sector: 'Banking',
    price: 4300.0, change: -85.0, changePercent: -1.94,
    color: Color(0xFFEF4444),
    sparkline: [4500, 4480, 4420, 4390, 4350, 4380, 4320, 4300, 4290, 4300],
    allocation: 24,
  ),
  StockModel(
    symbol: 'TBL', name: 'Tanzania Breweries', sector: 'Consumer',
    price: 3900.0, change: 45.0, changePercent: 1.17,
    color: Color(0xFF4CAF50),
    sparkline: [3750, 3780, 3800, 3820, 3810, 3850, 3870, 3890, 3880, 3900],
    allocation: 18,
  ),
  StockModel(
    symbol: 'DSE', name: 'Dar es Salaam SE', sector: 'Exchange',
    price: 1250.0, change: 30.0, changePercent: 2.46,
    color: Color(0xFFFFB347),
    sparkline: [1180, 1195, 1210, 1200, 1220, 1215, 1235, 1240, 1245, 1250],
    allocation: 15,
  ),
  StockModel(
    symbol: 'KCB', name: 'KCB Group', sector: 'Banking',
    price: 1640.0, change: -22.0, changePercent: -1.32,
    color: Color(0xFFAB47BC),
    sparkline: [1700, 1690, 1680, 1670, 1665, 1660, 1655, 1648, 1643, 1640],
    allocation: 11,
  ),
];

const kPortfolioHistory = <double>[
  14200000, 14800000, 14500000, 15200000, 15800000,
  15400000, 16100000, 16600000, 16300000, 17000000,
  17400000, 17200000, 17900000, 18200000, 18000000,
  18700000, 19100000, 18800000, 19400000, 19800000,
  19500000, 20100000, 20400000, 20200000, 20800000,
  21200000,
];

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class TradeSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;
  const TradeSectionHeader({
    Key? key,
    required this.title,
    required this.icon,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: TradeColors.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: TradeColors.teal),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    color: TradeColors.txtPrim,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Reusable stock row tile used in Holdings and Markets pages.
class StockTile extends StatelessWidget {
  final StockModel stock;
  final VoidCallback? onTap;
  const StockTile({Key? key, required this.stock, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final s = stock;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TradeColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TradeColors.border),
        ),
        child: Row(
          children: [
            // Symbol badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: s.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: s.color.withOpacity(0.3)),
              ),
              child: Center(
                child: Text(s.symbol.substring(0, 2),
                    style: TextStyle(
                        color: s.color,
                        fontSize: 13,
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
                          fontSize: 14)),
                  Text(s.sector,
                      style: const TextStyle(
                          color: TradeColors.txtSec, fontSize: 11)),
                ],
              ),
            ),
            // Sparkline
            SizedBox(
              width: 56,
              height: 32,
              child: CustomPaint(
                  painter: SparklinePainter(
                      data: s.sparkline,
                      color: s.isUp ? TradeColors.green : TradeColors.red)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('TZS ${s.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: TradeColors.txtPrim,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: (s.isUp ? TradeColors.green : TradeColors.red)
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${s.isUp ? '+' : ''}${s.changePercent.toStringAsFixed(2)}%',
                    style: TextStyle(
                        color: s.isUp ? TradeColors.green : TradeColors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAINTERS
// ─────────────────────────────────────────────────────────────────────────────

class LineChartPainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;
  final Color fillColor;
  const LineChartPainter(
      {required this.data,
        required this.lineColor,
        required this.fillColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    const pad = EdgeInsets.fromLTRB(16, 12, 16, 24);
    final w = size.width - pad.left - pad.right;
    final h = size.height - pad.top - pad.bottom;
    final minV = data.reduce(math.min);
    final maxV = data.reduce(math.max);
    final range = maxV - minV;

    Offset pt(int i) {
      final x = pad.left + (i / (data.length - 1)) * w;
      final y = pad.top + h - ((data[i] - minV) / range) * h;
      return Offset(x, y);
    }

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = pad.top + (i / 4) * h;
      canvas.drawLine(
          Offset(pad.left, y), Offset(pad.left + w, y), gridPaint);
    }

    // Smooth bezier path
    final path = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (int i = 1; i < data.length; i++) {
      final prev = pt(i - 1);
      final curr = pt(i);
      final ctrlX = (prev.dx + curr.dx) / 2;
      path.cubicTo(ctrlX, prev.dy, ctrlX, curr.dy, curr.dx, curr.dy);
    }

    // Gradient fill
    final fillPath = Path.from(path)
      ..lineTo(pt(data.length - 1).dx, pad.top + h)
      ..lineTo(pt(0).dx, pad.top + h)
      ..close();
    canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [fillColor, Colors.transparent],
          ).createShader(Rect.fromLTWH(pad.left, pad.top, w, h)));

    // Line stroke
    canvas.drawPath(
        path,
        Paint()
          ..color = lineColor
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);

    // Last-point glow dot
    final last = pt(data.length - 1);
    canvas.drawCircle(last, 6,
        Paint()
          ..color = lineColor.withOpacity(0.25)
          ..style = PaintingStyle.fill);
    canvas.drawCircle(last, 3.5,
        Paint()
          ..color = lineColor
          ..style = PaintingStyle.fill);

    // Y-axis labels
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i <= 2; i++) {
      final val = minV + (range * i / 2);
      final label = val >= 1e6
          ? '${(val / 1e6).toStringAsFixed(1)}M'
          : val >= 1e3
          ? '${(val / 1e3).toStringAsFixed(0)}K'
          : val.toStringAsFixed(0);
      tp.text = TextSpan(
          text: label,
          style: const TextStyle(color: TradeColors.txtSec, fontSize: 9));
      tp.layout();
      final y = pad.top + h - (i / 2) * h - tp.height / 2;
      tp.paint(canvas, Offset(0, y));
    }
  }

  @override
  bool shouldRepaint(LineChartPainter old) =>
      old.data != data || old.lineColor != lineColor;
}

class DonutPainter extends CustomPainter {
  final List<StockModel> stocks;
  const DonutPainter({required this.stocks});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const strokeW = 22.0;

    double startAngle = -math.pi / 2;
    final total =
    stocks.fold<double>(0, (sum, s) => sum + s.allocation);

    for (final s in stocks) {
      final sweep = (s.allocation / total) * 2 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeW / 2),
        startAngle,
        sweep - 0.04,
        false,
        Paint()
          ..color = s.color
          ..strokeWidth = strokeW
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
      startAngle += sweep;
    }

    // Center label
    final tp = TextPainter(
        text: const TextSpan(
            text: '5\nStocks',
            style: TextStyle(
                color: Colors.white54, fontSize: 11, height: 1.4)),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center)
      ..layout();
    tp.paint(canvas,
        Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(DonutPainter old) => false;
}

class SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  const SparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final minV = data.reduce(math.min);
    final maxV = data.reduce(math.max);
    final range = maxV == minV ? 1 : maxV - minV;
    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i] - minV) / range) * size.height;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(SparklinePainter old) =>
      old.data != data || old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// TRADE SHEET (shared helper)
// ─────────────────────────────────────────────────────────────────────────────

/// Shows a simple trade bottom sheet for the given [stock].
///
/// Other pages call this as `showTradeSheet(context, stock, isBuy: true)`.
void showTradeSheet(BuildContext context, StockModel stock, {bool isBuy = true}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setState) {
        bool buyMode = isBuy;
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: TradeColors.card,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
              border: Border.all(color: TradeColors.border),
            ),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(stock.symbol,
                            style: const TextStyle(
                                color: TradeColors.txtPrim,
                                fontSize: 18,
                                fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(stock.name,
                            style: const TextStyle(
                                color: TradeColors.txtSec, fontSize: 12)),
                      ],
                    ),
                    Text('TZS ${stock.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: TradeColors.txtPrim,
                            fontSize: 16,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => buyMode = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: buyMode ? TradeColors.surface : TradeColors.teal.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: TradeColors.border),
                          ),
                          child: Center(
                            child: Text('Sell',
                                style: TextStyle(
                                    color: buyMode ? TradeColors.txtSec : TradeColors.teal,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => buyMode = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: buyMode ? TradeColors.teal.withOpacity(0.14) : TradeColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: TradeColors.border),
                          ),
                          child: Center(
                            child: Text('Buy',
                                style: TextStyle(
                                    color: buyMode ? TradeColors.teal : TradeColors.txtSec,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Simple quantity selector placeholder
                Row(
                  children: [
                    const Text('Quantity', style: TextStyle(color: TradeColors.txtSec)),
                    const SizedBox(width: 12),
                    Container(
                      width: 120,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: TradeColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: TradeColors.border),
                      ),
                      child: const Text('1', textAlign: TextAlign.center, style: TextStyle(color: TradeColors.txtPrim)),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Estimated', style: TextStyle(color: TradeColors.txtSec, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('TZS ${(stock.price * 1).toStringAsFixed(0)}', style: const TextStyle(color: TradeColors.txtPrim, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('${buyMode ? 'Bought' : 'Sold'} 1 ${stock.symbol}'),
                            backgroundColor: TradeColors.surface,
                            behavior: SnackBarBehavior.floating,
                          ));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: buyMode ? [TradeColors.teal, const Color(0xFF0080FF)] : [TradeColors.red, const Color(0xFFFF0040)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(buyMode ? 'Buy' : 'Sell', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      });
    },
  );
}
