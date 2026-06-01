import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../buysell/buy.dart';
import '../buysell/sell.dart';
import '../market_watch/market_watch.dart';
import 'drawer.dart';
import 'my_oders.dart';

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

  static const List<Color> heroGrad = [Color(0xFF2E7D99), Color(0xFF1A5F77), Color(0xFF2E7D32)];
  static const List<Color> fabGrad  = [Color(0xFF2E7D99), Color(0xFF1A5F77)];
  static const List<Color> buyGrad  = [Color(0xFF4CAF50), Color(0xFF2E7D32)];
  static const List<Color> sellGrad = [Color(0xFFFF8AA8), Color(0xFFFF6B8A)];
}

// ─────────────────────────────────────────────────────────────────────────────
// CHART DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────
class _MonthPoint {
  final String label; // "Jan", "Feb" …
  final int    buy;
  final int    sell;
  const _MonthPoint(this.label, this.buy, this.sell);
}

// ─────────────────────────────────────────────────────────────────────────────
// ORDERS CHART API  (same endpoints as my_orders.dart)
// ─────────────────────────────────────────────────────────────────────────────
class _ChartApi {
  static const _buyUrl  = 'https://portalprod.tsl.co.tz/DSEAPI/Home/GetBuyOrders';
  static const _sellUrl = 'https://portalprod.tsl.co.tz/DSEAPI/Home/GetSellOrders';
  static const _nida    = '19931109111010000522';

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Future<List<Map<String, dynamic>>> _fetchRaw(
      String url, DateTime start, DateTime end) async {
    final client = HttpClient();
    client.badCertificateCallback = (_, __, ___) => true;
    client.connectionTimeout = const Duration(seconds: 15);
    try {
      final req = await client.postUrl(Uri.parse(url));
      req.headers
        ..set('Accept', 'application/json')
        ..set('Content-Type', 'application/json')
        ..set('User-Agent', 'DSEApp/1.0');
      req.write(jsonEncode({
        'nidaNumber': _nida,
        'startDate': _fmt(start),
        'endDate': _fmt(end),
        'orderStatus': '',
        'signature': '',
      }));
      final res  = await req.close();
      final body = await res.transform(utf8.decoder).join();
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final json = jsonDecode(body) as Map<String, dynamic>;
      if ((json['code'] as int) != 9000) throw Exception(json['message']);
      return (json['data'] as List).cast<Map<String, dynamic>>();
    } finally {
      client.close();
    }
  }

  /// Returns 12 monthly points for the given year.
  static Future<List<_MonthPoint>> fetchMonthly(int year) async {
    final start = DateTime(year, 1, 1);
    final end   = DateTime(year, 12, 31);

    final results = await Future.wait([
      _fetchRaw(_buyUrl,  start, end),
      _fetchRaw(_sellUrl, start, end),
    ]);

    final buyCounts  = List<int>.filled(12, 0);
    final sellCounts = List<int>.filled(12, 0);

    for (final r in results[0]) {
      try {
        final m = DateTime.parse(r['orderDate'] as String).month - 1;
        buyCounts[m]++;
      } catch (_) {}
    }
    for (final r in results[1]) {
      try {
        final m = DateTime.parse(r['orderDate'] as String).month - 1;
        sellCounts[m]++;
      } catch (_) {}
    }

    const labels = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return List.generate(
        12, (i) => _MonthPoint(labels[i], buyCounts[i], sellCounts[i]));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LINE CHART PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _LineChartPainter extends CustomPainter {
  final List<_MonthPoint> points;
  final int highlightIndex; // -1 = none

  _LineChartPainter({required this.points, this.highlightIndex = -1});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final maxVal = points.fold<int>(1, (m, p) => max(m, max(p.buy, p.sell)));
    final padL = 4.0, padR = 4.0, padT = 12.0, padB = 24.0;
    final w = size.width  - padL - padR;
    final h = size.height - padT - padB;
    final n = points.length;

    Offset pt(int i, int v) => Offset(
      padL + (i / (n - 1)) * w,
      padT + h - (v / maxVal) * h,
    );

    // ── Grid lines ────────────────────────────────────────────────────────
    final gridPaint = Paint()
      ..color = const Color(0xFFCDE9DE).withOpacity(0.7)
      ..strokeWidth = 1;
    for (int g = 0; g <= 3; g++) {
      final y = padT + (g / 3) * h;
      canvas.drawLine(Offset(padL, y), Offset(padL + w, y), gridPaint);
    }

    // ── Helper: draw filled line ─────────────────────────────────────────
    void drawLine(
        List<Offset> pts, Color lineColor, Color fillTop, Color fillBot) {
      if (pts.length < 2) return;

      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (int i = 0; i < pts.length - 1; i++) {
        final cp1 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i].dy);
        final cp2 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i + 1].dy);
        path.cubicTo(
            cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts[i + 1].dx, pts[i + 1].dy);
      }

      // fill
      final fillPath = Path.from(path)
        ..lineTo(pts.last.dx,  padT + h)
        ..lineTo(pts.first.dx, padT + h)
        ..close();
      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [fillTop, fillBot],
          ).createShader(Rect.fromLTWH(0, padT, size.width, h))
          ..style = PaintingStyle.fill,
      );

      // line
      canvas.drawPath(
        path,
        Paint()
          ..color = lineColor
          ..strokeWidth = 2.2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    final buyPts  = List.generate(n, (i) => pt(i, points[i].buy));
    final sellPts = List.generate(n, (i) => pt(i, points[i].sell));

    drawLine(buyPts,
        const Color(0xFF34C759),
        const Color(0xFF34C759).withOpacity(0.22),
        const Color(0xFF34C759).withOpacity(0.0));
    drawLine(sellPts,
        const Color(0xFFFF6B8A),
        const Color(0xFFFF6B8A).withOpacity(0.18),
        const Color(0xFFFF6B8A).withOpacity(0.0));

    // ── Month labels ──────────────────────────────────────────────────────
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < n; i++) {
      // Only show every other label to avoid crowding
      if (i % 2 != 0) continue;
      tp.text = TextSpan(
        text: points[i].label,
        style: TextStyle(
          color: const Color(0xFFA0C4B8).withOpacity(i == highlightIndex ? 1 : 0.8),
          fontSize: 9,
          fontWeight: i == highlightIndex ? FontWeight.w800 : FontWeight.w500,
        ),
      );
      tp.layout();
      tp.paint(canvas,
          Offset(pt(i, 0).dx - tp.width / 2, size.height - padB + 6));
    }

    // ── Dots + highlight ──────────────────────────────────────────────────
    for (int i = 0; i < n; i++) {
      final isHl = i == highlightIndex;

      for (final isB in [true, false]) {
        final o     = isB ? buyPts[i] : sellPts[i];
        final color = isB ? const Color(0xFF34C759) : const Color(0xFFFF6B8A);

        if (isHl) {
          // Outer glow
          canvas.drawCircle(o, 8, Paint()..color = color.withOpacity(0.15));
          canvas.drawCircle(o, 5, Paint()..color = color.withOpacity(0.35));
        }
        // Inner dot
        canvas.drawCircle(o, isHl ? 4 : 2.5, Paint()..color = color);
        canvas.drawCircle(o, isHl ? 4 : 2.5,
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5);

        // Value label on highlight
        if (isHl) {
          final val = isB ? points[i].buy : points[i].sell;
          tp.text = TextSpan(
            text: '$val',
            style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w900),
          );
          tp.layout();
          tp.paint(canvas,
              Offset(o.dx - tp.width / 2, o.dy - tp.height - 6));
        }
      }
    }

    // ── Highlight vertical rule ───────────────────────────────────────────
    if (highlightIndex >= 0 && highlightIndex < n) {
      final x = pt(highlightIndex, 0).dx;
      canvas.drawLine(
        Offset(x, padT),
        Offset(x, padT + h),
        Paint()
          ..color = const Color(0xFF2E7D99).withOpacity(0.25)
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) =>
      old.points != points || old.highlightIndex != highlightIndex;
}

// ─────────────────────────────────────────────────────────────────────────────
// INTERACTIVE CHART CARD
// ─────────────────────────────────────────────────────────────────────────────
class _OrdersChartCard extends StatefulWidget {
  const _OrdersChartCard();

  @override
  State<_OrdersChartCard> createState() => _OrdersChartCardState();
}

class _OrdersChartCardState extends State<_OrdersChartCard>
    with SingleTickerProviderStateMixin {
  List<_MonthPoint> _points = [];
  bool   _loading = true;
  String? _error;
  int    _hlIndex = -1;
  int    _year    = DateTime.now().year;

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _load();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final pts = await _ChartApi.fetchMonthly(_year);
      setState(() { _points = pts; _loading = false; });
      _fadeCtrl.forward(from: 0);
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  int get _totalBuy  => _points.fold(0, (s, p) => s + p.buy);
  int get _totalSell => _points.fold(0, (s, p) => s + p.sell);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      decoration: BoxDecoration(
        color: PastelColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: PastelColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
              color: PastelColors.accent.withOpacity(0.10),
              blurRadius: 24,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Card header ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
          child: Row(children: [
            // Icon
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: PastelColors.heroGrad,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.show_chart_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Order Activity',
                    style: TextStyle(
                        color: PastelColors.txtPrim,
                        fontSize: 15,
                        fontWeight: FontWeight.w900)),
                Text('Monthly buy vs sell — $_year',
                    style: const TextStyle(
                        color: PastelColors.txtHint, fontSize: 11)),
              ]),
            ),
            // Year selector
            _YearToggle(
              year:       _year,
              loading:    _loading,
              onPrev: () { setState(() => _year--); _load(); },
              onNext: () {
                if (_year < DateTime.now().year) {
                  setState(() => _year++);
                  _load();
                }
              },
            ),
          ]),
        ),

        const SizedBox(height: 16),

        // ── Legend + totals ────────────────────────────────────────────
        if (!_loading && _error == null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              _LegendDot(color: PastelColors.green,
                  label: 'Buy',  value: '$_totalBuy orders'),
              const SizedBox(width: 20),
              _LegendDot(color: PastelColors.red,
                  label: 'Sell', value: '$_totalSell orders'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: PastelColors.accentLt,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: PastelColors.accent.withOpacity(0.25)),
                ),
                child: Text(
                  'Total: ${_totalBuy + _totalSell}',
                  style: const TextStyle(
                      color: PastelColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ]),
          ),

        const SizedBox(height: 12),

        // ── Chart area ─────────────────────────────────────────────────
        SizedBox(
          height: 180,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _loading
                ? const _ChartShimmer()
                : _error != null
                ? _ChartError(onRetry: _load)
                : FadeTransition(
              opacity: _fadeAnim,
              child: GestureDetector(
                onTapDown: (d) => _onTap(d, context),
                onPanUpdate: (d) => _onPan(d, context),
                onPanEnd: (_) => setState(() => _hlIndex = -1),
                onTapUp: (_) =>
                    Future.delayed(const Duration(seconds: 2),
                            () { if (mounted) setState(() => _hlIndex = -1); }),
                child: CustomPaint(
                  size: const Size(double.infinity, 180),
                  painter: _LineChartPainter(
                      points: _points,
                      highlightIndex: _hlIndex),
                ),
              ),
            ),
          ),
        ),

        // ── Highlight tooltip ──────────────────────────────────────────
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _hlIndex >= 0 && _hlIndex < _points.length
              ? _Tooltip(point: _points[_hlIndex])
              : const SizedBox(height: 16),
        ),

        const SizedBox(height: 4),
      ]),
    );
  }

  void _onTap(TapDownDetails d, BuildContext ctx) {
    _updateHL(d.localPosition.dx, ctx);
  }

  void _onPan(DragUpdateDetails d, BuildContext ctx) {
    _updateHL(d.localPosition.dx, ctx);
  }

  void _updateHL(double dx, BuildContext ctx) {
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
    final w = box.size.width - 24; // padL+padR
    final step = w / (_points.length - 1);
    final i = ((dx - 12) / step).round().clamp(0, _points.length - 1);
    if (i != _hlIndex) setState(() => _hlIndex = i);
  }
}

// ── Year toggle ───────────────────────────────────────────────────────────────
class _YearToggle extends StatelessWidget {
  final int year; final bool loading;
  final VoidCallback onPrev; final VoidCallback onNext;
  const _YearToggle({required this.year, required this.loading,
    required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: PastelColors.accentLt,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: PastelColors.accent.withOpacity(0.2)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      _Arr(icon: Icons.chevron_left_rounded,  onTap: loading ? null : onPrev),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text('$year',
            style: const TextStyle(color: PastelColors.accent,
                fontSize: 12, fontWeight: FontWeight.w800)),
      ),
      _Arr(icon: Icons.chevron_right_rounded,
          onTap: loading || year >= DateTime.now().year ? null : onNext),
    ]),
  );
}

class _Arr extends StatelessWidget {
  final IconData icon; final VoidCallback? onTap;
  const _Arr({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.all(6),
      child: Icon(icon,
          size: 16,
          color: onTap == null
              ? PastelColors.txtHint
              : PastelColors.accent),
    ),
  );
}

// ── Legend dot ────────────────────────────────────────────────────────────────
class _LegendDot extends StatelessWidget {
  final Color color; final String label; final String value;
  const _LegendDot({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(
      width: 10, height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    ),
    const SizedBox(width: 6),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              color: PastelColors.txtHint, fontSize: 9,
              fontWeight: FontWeight.w600, letterSpacing: 0.3)),
      Text(value,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w800)),
    ]),
  ]);
}

// ── Tooltip bar ───────────────────────────────────────────────────────────────
class _Tooltip extends StatelessWidget {
  final _MonthPoint point;
  const _Tooltip({required this.point});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(20, 4, 20, 16),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
          colors: PastelColors.heroGrad,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(children: [
      const Icon(Icons.calendar_today_rounded,
          color: Colors.white70, size: 13),
      const SizedBox(width: 8),
      Text(point.label,
          style: const TextStyle(
              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
      const Spacer(),
      _TipStat(label: 'Buy',  value: '${point.buy}',  color: PastelColors.green),
      const SizedBox(width: 16),
      _TipStat(label: 'Sell', value: '${point.sell}', color: PastelColors.red),
      const SizedBox(width: 16),
      _TipStat(label: 'Total',
          value: '${point.buy + point.sell}', color: PastelColors.gold),
    ]),
  );
}

class _TipStat extends StatelessWidget {
  final String label; final String value; final Color color;
  const _TipStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(value,
          style: TextStyle(
              color: color, fontSize: 14, fontWeight: FontWeight.w900)),
      Text(label,
          style: const TextStyle(
              color: Colors.white60, fontSize: 9, fontWeight: FontWeight.w500)),
    ],
  );
}

// ── Chart shimmer ─────────────────────────────────────────────────────────────
class _ChartShimmer extends StatefulWidget {
  const _ChartShimmer();
  @override State<_ChartShimmer> createState() => _ChartShimmerState();
}

class _ChartShimmerState extends State<_ChartShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double>   _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
    _a = CurvedAnimation(parent: _c, curve: Curves.easeInOut);
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (_, __) => Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(PastelColors.border,
                PastelColors.accentLt, _a.value)!,
            Color.lerp(PastelColors.accentLt,
                PastelColors.border, _a.value)!,
          ],
        ),
      ),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 24, height: 24,
            child: CircularProgressIndicator(
                color: PastelColors.accent.withOpacity(0.5),
                strokeWidth: 2),
          ),
          const SizedBox(height: 10),
          Text('Loading chart…',
              style: TextStyle(
                  color: PastelColors.txtHint.withOpacity(0.8),
                  fontSize: 12)),
        ]),
      ),
    ),
  );
}

// ── Chart error ───────────────────────────────────────────────────────────────
class _ChartError extends StatelessWidget {
  final VoidCallback onRetry;
  const _ChartError({required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.wifi_off_rounded, color: PastelColors.red, size: 26),
      const SizedBox(height: 8),
      const Text('Could not load chart',
          style: TextStyle(
              color: PastelColors.txtSec, fontSize: 12,
              fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: onRetry,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
          decoration: BoxDecoration(
            color: PastelColors.accentLt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: PastelColors.accent.withOpacity(0.35)),
          ),
          child: const Text('Retry',
              style: TextStyle(
                  color: PastelColors.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800)),
        ),
      ),
    ]),
  );
}

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
  void dispose() { _pageAnim.dispose(); super.dispose(); }

  void _push(Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => page,
        transitionsBuilder: (_, a, __, child) {
          final c = CurvedAnimation(parent: a, curve: Curves.easeInOut);
          return FadeTransition(opacity: c,
            child: SlideTransition(
              position: Tween<Offset>(
                  begin: const Offset(0.05, 0), end: Offset.zero).animate(c),
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
                child: Column(children: [
                  _buildPortfolioCard(),
                  const SizedBox(height: 20),
                  _buildActionGrid(),
                  const SizedBox(height: 20),
                  _buildFmsShortcut(),
                  const SizedBox(height: 24),

                  // ── Section header ─────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Row(children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: PastelColors.heroGrad,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.analytics_rounded,
                            color: Colors.white, size: 14),
                      ),
                      const SizedBox(width: 10),
                      const Text('Order Analytics',
                          style: TextStyle(
                              color: PastelColors.txtPrim,
                              fontSize: 15,
                              fontWeight: FontWeight.w900)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _push(const OrdersPage()),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: PastelColors.accentLt,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: PastelColors.accent.withOpacity(0.3)),
                          ),
                          child: const Text('View All →',
                              style: TextStyle(
                                  color: PastelColors.accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ]),
                  ),

                  // ── Interactive line chart ─────────────────────────────
                  const _OrdersChartCard(),

                  const SizedBox(height: 40),
                ]),
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
              BoxShadow(color: PastelColors.accent.withOpacity(0.35),
                  blurRadius: 8, offset: const Offset(0, 3)),
            ],
          ),
          child: const Text('TRADE',
              style: TextStyle(color: Colors.white, fontSize: 11,
                  fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        ),
        const SizedBox(width: 10),
        const Text('Portfolio',
            style: TextStyle(color: PastelColors.txtPrim,
                fontSize: 18, fontWeight: FontWeight.w800)),
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
          BoxShadow(color: PastelColors.accent.withOpacity(0.10),
              blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Stack(clipBehavior: Clip.none, children: [
        Icon(icon, size: 18, color: PastelColors.txtPrim),
        if (badge)
          Positioned(right: -1, top: -1,
            child: Container(width: 6, height: 6,
                decoration: const BoxDecoration(
                    color: Colors.red, shape: BoxShape.circle)),
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
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: PastelColors.heroGrad),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
          boxShadow: [
            BoxShadow(color: PastelColors.accent.withOpacity(0.30),
                blurRadius: 30, offset: const Offset(0, 10)),
          ],
        ),
        child: Stack(children: [
          Positioned(top: -20, right: -20,
            child: Container(width: 140, height: 140,
              decoration: BoxDecoration(shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    Colors.white.withOpacity(0.18), Colors.transparent])),
            ),
          ),
          Positioned(bottom: -30, left: 20,
            child: Container(width: 100, height: 100,
              decoration: BoxDecoration(shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    Colors.white.withOpacity(0.10), Colors.transparent])),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Total Portfolio Value',
                    style: TextStyle(color: Colors.white70,
                        fontSize: 13, fontWeight: FontWeight.w500)),
                _changeChip('+5.8% today', PastelColors.green),
              ]),
              const SizedBox(height: 10),
              const Text('TZS 21,200,000',
                  style: TextStyle(color: Colors.white, fontSize: 34,
                      fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Row(children: const [
                Icon(Icons.trending_up_rounded, size: 16, color: Color(0xFF4ADE80)),
                SizedBox(width: 4),
                Text('+TZS 1,160,000 this month',
                    style: TextStyle(color: Color(0xFF4ADE80), fontSize: 13)),
              ]),

            ]),
          ),
        ]),
      ),
    );
  }

  Widget _changeChip(String label, Color color) => Container(
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

  Widget _miniStat(String label, String value, Color color) => Expanded(
    child: Column(children: [
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      const SizedBox(height: 4),
      Text(value,
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
    ]),
  );

  Widget _vDivider() => Container(height: 32, width: 1, color: Colors.white24);

  // ── Action grid ────────────────────────────────────────────────────────────
  Widget _buildActionGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        Row(children: [
          Expanded(child: _primaryBtn(
            label: 'Buy', icon: Icons.trending_up_rounded,
            grad: PastelColors.buyGrad, shadow: PastelColors.accent2,
            onTap: () { HapticFeedback.mediumImpact(); _push(const BuySharesPage()); },
          )),
          const SizedBox(width: 12),
          Expanded(child: _primaryBtn(
            label: 'Sell', icon: Icons.trending_down_rounded,
            grad: PastelColors.sellGrad, shadow: PastelColors.red,
            onTap: () { HapticFeedback.mediumImpact(); _push(const SellSharesPage()); },
          )),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _secondaryBtn(
            label: 'My Orders', sublabel: 'Live orders',
            icon: Icons.receipt_long_rounded,
            iconColor: PastelColors.accent, iconBg: PastelColors.accentLt,
            borderColor: PastelColors.accent.withOpacity(0.30),
            onTap: () { HapticFeedback.mediumImpact(); _push(const OrdersPage()); },
          )),
          const SizedBox(width: 12),
          Expanded(child: _secondaryBtn(
            label: 'Market Watch', sublabel: 'DSE live',
            icon: Icons.bar_chart_rounded,
            iconColor: PastelColors.gold, iconBg: PastelColors.goldLt,
            borderColor: PastelColors.gold.withOpacity(0.30),
            onTap: () { HapticFeedback.mediumImpact(); _push(const DseMarketWatchPage()); },
          )),
        ]),
      ]),
    );
  }

  Widget _primaryBtn({
    required String label, required IconData icon,
    required List<Color> grad, required Color shadow, required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: grad, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: shadow.withOpacity(0.35),
              blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white,
            fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
      ]),
    ),
  );

  Widget _secondaryBtn({
    required String label, required String sublabel, required IconData icon,
    required Color iconColor, required Color iconBg, required Color borderColor,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: PastelColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(color: PastelColors.accent.withOpacity(0.07),
              blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(children: [
        Container(width: 40, height: 40,
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 20)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: PastelColors.txtPrim,
              fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(sublabel,
              style: const TextStyle(color: PastelColors.txtHint, fontSize: 11)),
        ])),
        const Icon(Icons.chevron_right_rounded,
            color: PastelColors.txtHint, size: 18),
      ]),
    ),
  );

  // ── FMS shortcut ───────────────────────────────────────────────────────────
  Widget _buildFmsShortcut() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () { HapticFeedback.mediumImpact(); Navigator.pop(context); },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFFD4EEF9), Color(0xFFE8F5E9), Color(0xFFB8E6D3)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: PastelColors.accent.withOpacity(0.25), width: 1.5),
            boxShadow: [
              BoxShadow(color: PastelColors.accent.withOpacity(0.12),
                  blurRadius: 20, offset: const Offset(0, 6)),
            ],
          ),
          child: Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: PastelColors.fabGrad,
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: PastelColors.accent.withOpacity(0.35),
                      blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: const Icon(Icons.account_balance_rounded,
                  color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Fund Management System',
                      style: TextStyle(color: PastelColors.txtPrim,
                          fontSize: 15, fontWeight: FontWeight.w800)),
                  SizedBox(height: 3),
                  Text('Tap to open FMS dashboard →',
                      style: TextStyle(color: PastelColors.accent,
                          fontSize: 12, fontWeight: FontWeight.w500)),
                ])),
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