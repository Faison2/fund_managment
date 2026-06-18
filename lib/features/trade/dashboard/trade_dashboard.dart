import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../buysell/buy.dart';
import '../buysell/sell.dart';
import '../market_watch/market_watch.dart';
import 'drawer.dart';
import 'my_orders.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TSL BRAND PALETTE  (official colors only)
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  static const Color blue      = Color(0xFF329AD6);
  static const Color teal      = Color(0xFF00A79D);
  static const Color grey      = Color(0xFF939598);
  static const Color white     = Color(0xFFFFFFFF);
  static const Color black     = Color(0xFF231F20);

  // Status colors (not brand, but necessary for UI)
  static const Color green     = Color(0xFF34C759);
  static const Color red       = Color(0xFFFF3B30);
  static const Color gold      = Color(0xFFF5A623);

  // Gradients using only official brand colors
  static const List<Color> heroGrad = [Color(0xFF00A79D), Color(0xFF329AD6)];
  static const List<Color> fabGrad  = [Color(0xFF00A79D), Color(0xFF329AD6)];
  static const List<Color> buyGrad  = [Color(0xFF34C759), Color(0xFF1E8E3E)];
  static const List<Color> sellGrad = [Color(0xFFFF6B6B), Color(0xFFFF3B30)];
}

// ─────────────────────────────────────────────────────────────────────────────
// CHART DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────
class _MonthPoint {
  final String label;
  final int    buy;
  final int    sell;
  const _MonthPoint(this.label, this.buy, this.sell);
}

// ─────────────────────────────────────────────────────────────────────────────
// ORDERS CHART API
// ─────────────────────────────────────────────────────────────────────────────
class _ChartApi {
  static const _buyUrl  = 'https://portaluat.tsl.co.tz/DSEAPI/Home/GetBuyOrders';
  static const _sellUrl = 'https://portaluat.tsl.co.tz/DSEAPI/Home/GetSellOrders';

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Future<List<Map<String, dynamic>>> _fetchRaw(
      String url, DateTime start, DateTime end, String nida) async {
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
        'nidaNumber': nida,
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

  static Future<List<_MonthPoint>> fetchMonthly(int year) async {
    final prefs = await SharedPreferences.getInstance();
    final nida  = prefs.getString('nida_number') ?? '';
    if (nida.isEmpty) throw Exception('NIDA number not set. Please log in again.');

    final start = DateTime(year, 1, 1);
    final end   = DateTime(year, 12, 31);

    final results = await Future.wait([
      _fetchRaw(_buyUrl,  start, end, nida),
      _fetchRaw(_sellUrl, start, end, nida),
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
  final int highlightIndex;

  _LineChartPainter({required this.points, this.highlightIndex = -1});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final maxVal = points.fold<int>(1, (m, p) => max(m, max(p.buy, p.sell)));
    const padL = 4.0, padR = 4.0, padT = 12.0, padB = 24.0;
    final w = size.width  - padL - padR;
    final h = size.height - padT - padB;
    final n = points.length;

    Offset pt(int i, int v) => Offset(
      padL + (i / (n - 1)) * w,
      padT + h - (v / maxVal) * h,
    );

    // Grid lines using grey
    final gridPaint = Paint()
      ..color = _C.grey.withOpacity(0.25)
      ..strokeWidth = 1;
    for (int g = 0; g <= 3; g++) {
      final y = padT + (g / 3) * h;
      canvas.drawLine(Offset(padL, y), Offset(padL + w, y), gridPaint);
    }

    void drawLine(List<Offset> pts, Color lineColor, Color fillTop, Color fillBot) {
      if (pts.length < 2) return;
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (int i = 0; i < pts.length - 1; i++) {
        final cp1 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i].dy);
        final cp2 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i + 1].dy);
        path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts[i + 1].dx, pts[i + 1].dy);
      }
      final fillPath = Path.from(path)
        ..lineTo(pts.last.dx,  padT + h)
        ..lineTo(pts.first.dx, padT + h)
        ..close();
      canvas.drawPath(fillPath, Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [fillTop, fillBot],
        ).createShader(Rect.fromLTWH(0, padT, size.width, h))
        ..style = PaintingStyle.fill);
      canvas.drawPath(path, Paint()
        ..color = lineColor
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round);
    }

    final buyPts  = List.generate(n, (i) => pt(i, points[i].buy));
    final sellPts = List.generate(n, (i) => pt(i, points[i].sell));

    drawLine(buyPts,  _C.teal, _C.teal.withOpacity(0.22), _C.teal.withOpacity(0.0));
    drawLine(sellPts, _C.blue, _C.blue.withOpacity(0.18), _C.blue.withOpacity(0.0));

    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < n; i++) {
      if (i % 2 != 0) continue;
      tp.text = TextSpan(
        text: points[i].label,
        style: TextStyle(
          color: _C.grey.withOpacity(i == highlightIndex ? 1 : 0.8),
          fontSize: 9,
          fontWeight: i == highlightIndex ? FontWeight.w800 : FontWeight.w500,
        ),
      );
      tp.layout();
      tp.paint(canvas, Offset(pt(i, 0).dx - tp.width / 2, size.height - padB + 6));
    }

    for (int i = 0; i < n; i++) {
      final isHl = i == highlightIndex;
      for (final isB in [true, false]) {
        final o     = isB ? buyPts[i] : sellPts[i];
        final color = isB ? _C.teal : _C.blue;
        if (isHl) {
          canvas.drawCircle(o, 8, Paint()..color = color.withOpacity(0.15));
          canvas.drawCircle(o, 5, Paint()..color = color.withOpacity(0.35));
        }
        canvas.drawCircle(o, isHl ? 4 : 2.5, Paint()..color = color);
        canvas.drawCircle(o, isHl ? 4 : 2.5, Paint()
          ..color = _C.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
        if (isHl) {
          final val = isB ? points[i].buy : points[i].sell;
          tp.text = TextSpan(
            text: '$val',
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900),
          );
          tp.layout();
          tp.paint(canvas, Offset(o.dx - tp.width / 2, o.dy - tp.height - 6));
        }
      }
    }

    if (highlightIndex >= 0 && highlightIndex < n) {
      final x = pt(highlightIndex, 0).dx;
      canvas.drawLine(Offset(x, padT), Offset(x, padT + h),
          Paint()..color = _C.teal.withOpacity(0.25)..strokeWidth = 1);
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
  bool    _loading = true;
  String? _error;
  int     _hlIndex = -1;
  int     _year    = DateTime.now().year;

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _load();
  }

  @override
  void dispose() { _fadeCtrl.dispose(); super.dispose(); }

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
        color: _C.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _C.grey.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(color: _C.teal.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
          child: Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: _C.heroGrad, begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.show_chart_rounded, color: _C.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Order Activity',
                    style: TextStyle(color: _C.black, fontSize: 15, fontWeight: FontWeight.w900)),
                Text('Monthly buy vs sell — $_year',
                    style: TextStyle(color: _C.grey, fontSize: 11)),
              ]),
            ),
            _YearToggle(
              year: _year, loading: _loading,
              onPrev: () { setState(() => _year--); _load(); },
              onNext: () {
                if (_year < DateTime.now().year) { setState(() => _year++); _load(); }
              },
            ),
          ]),
        ),

        const SizedBox(height: 16),

        if (!_loading && _error == null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              _LegendDot(color: _C.teal, label: 'Buy',  value: '$_totalBuy orders'),
              const SizedBox(width: 20),
              _LegendDot(color: _C.blue, label: 'Sell', value: '$_totalSell orders'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _C.teal.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _C.teal.withOpacity(0.3)),
                ),
                child: Text('Total: ${_totalBuy + _totalSell}',
                    style: const TextStyle(color: _C.teal, fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            ]),
          ),

        const SizedBox(height: 12),

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
                onTapDown:   (d) => _onTap(d, context),
                onPanUpdate: (d) => _onPan(d, context),
                onPanEnd:    (_) => setState(() => _hlIndex = -1),
                onTapUp:     (_) => Future.delayed(const Duration(seconds: 2),
                        () { if (mounted) setState(() => _hlIndex = -1); }),
                child: CustomPaint(
                  size: const Size(double.infinity, 180),
                  painter: _LineChartPainter(points: _points, highlightIndex: _hlIndex),
                ),
              ),
            ),
          ),
        ),

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

  void _onTap(TapDownDetails d, BuildContext ctx) => _updateHL(d.localPosition.dx, ctx);
  void _onPan(DragUpdateDetails d, BuildContext ctx) => _updateHL(d.localPosition.dx, ctx);
  void _updateHL(double dx, BuildContext ctx) {
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
    final w    = box.size.width - 24;
    final step = w / (_points.length - 1);
    final i    = ((dx - 12) / step).round().clamp(0, _points.length - 1);
    if (i != _hlIndex) setState(() => _hlIndex = i);
  }
}

// ── Year toggle ────────────────────────────────────────────────────────────────
class _YearToggle extends StatelessWidget {
  final int year; final bool loading;
  final VoidCallback onPrev; final VoidCallback onNext;
  const _YearToggle({required this.year, required this.loading, required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _C.teal.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _C.teal.withOpacity(0.25)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      _Arr(icon: Icons.chevron_left_rounded,  onTap: loading ? null : onPrev),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text('$year', style: const TextStyle(color: _C.teal, fontSize: 12, fontWeight: FontWeight.w800)),
      ),
      _Arr(icon: Icons.chevron_right_rounded, onTap: loading || year >= DateTime.now().year ? null : onNext),
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
      child: Icon(icon, size: 16, color: onTap == null ? _C.grey : _C.teal),
    ),
  );
}

// ── Legend dot ─────────────────────────────────────────────────────────────────
class _LegendDot extends StatelessWidget {
  final Color color; final String label; final String value;
  const _LegendDot({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 6),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: _C.grey, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
      Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
    ]),
  ]);
}

// ── Tooltip bar ────────────────────────────────────────────────────────────────
class _Tooltip extends StatelessWidget {
  final _MonthPoint point;
  const _Tooltip({required this.point});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(20, 4, 20, 16),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: _C.heroGrad, begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(children: [
      const Icon(Icons.calendar_today_rounded, color: Colors.white70, size: 13),
      const SizedBox(width: 8),
      Text(point.label, style: const TextStyle(color: _C.white, fontSize: 13, fontWeight: FontWeight.w800)),
      const Spacer(),
      _TipStat(label: 'Buy',   value: '${point.buy}',              color: _C.white),
      const SizedBox(width: 16),
      _TipStat(label: 'Sell',  value: '${point.sell}',             color: _C.white.withOpacity(0.75)),
      const SizedBox(width: 16),
      _TipStat(label: 'Total', value: '${point.buy + point.sell}', color: _C.gold),
    ]),
  );
}

class _TipStat extends StatelessWidget {
  final String label; final String value; final Color color;
  const _TipStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
    Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900)),
    Text(label, style: const TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.w500)),
  ]);
}

// ── Chart shimmer ──────────────────────────────────────────────────────────────
class _ChartShimmer extends StatefulWidget {
  const _ChartShimmer();
  @override State<_ChartShimmer> createState() => _ChartShimmerState();
}

class _ChartShimmerState extends State<_ChartShimmer> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double>   _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
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
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [
            Color.lerp(_C.grey.withOpacity(0.1), _C.teal.withOpacity(0.1), _a.value)!,
            Color.lerp(_C.teal.withOpacity(0.1), _C.grey.withOpacity(0.1), _a.value)!,
          ],
        ),
      ),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(width: 24, height: 24,
              child: CircularProgressIndicator(color: _C.teal.withOpacity(0.5), strokeWidth: 2)),
          const SizedBox(height: 10),
          Text('Loading chart…', style: TextStyle(color: _C.grey, fontSize: 12)),
        ]),
      ),
    ),
  );
}

// ── Chart error ────────────────────────────────────────────────────────────────
class _ChartError extends StatelessWidget {
  final VoidCallback onRetry;
  const _ChartError({required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.wifi_off_rounded, color: _C.grey, size: 26),
      const SizedBox(height: 8),
      Text('Could not load chart', style: TextStyle(color: _C.grey, fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: onRetry,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
          decoration: BoxDecoration(
            color: _C.teal.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _C.teal.withOpacity(0.35)),
          ),
          child: const Text('Retry', style: TextStyle(color: _C.teal, fontSize: 11, fontWeight: FontWeight.w800)),
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

class _TradeDashboardState extends State<TradeDashboard> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _pageAnim;
  late Animation<double>   _pageFade;

  @override
  void initState() {
    super.initState();
    _pageAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    _pageFade = CurvedAnimation(parent: _pageAnim, curve: Curves.easeOut);
  }

  @override
  void dispose() { _pageAnim.dispose(); super.dispose(); }

  void _push(Widget page) {
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (_, a, __) => page,
      transitionsBuilder: (_, a, __, child) {
        final c = CurvedAnimation(parent: a, curve: Curves.easeInOut);
        return FadeTransition(opacity: c,
            child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(c),
                child: child));
      },
      transitionDuration: const Duration(milliseconds: 380),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF5F6F7), // light grey bg
        drawer: TradeDrawer(onSwitchToFms: () { Navigator.pop(context); Navigator.pop(context); }),
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

                  // Analytics header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Row(children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: _C.heroGrad, begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.analytics_rounded, color: _C.white, size: 14),
                      ),
                      const SizedBox(width: 10),
                      const Text('Order Analytics',
                          style: TextStyle(color: _C.black, fontSize: 15, fontWeight: FontWeight.w900)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _push(const OrdersPage()),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: _C.teal.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _C.teal.withOpacity(0.3)),
                          ),
                          child: const Text('View All →',
                              style: TextStyle(color: _C.teal, fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ]),
                  ),

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

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: const Color(0xFFF5F6F7),
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
            gradient: const LinearGradient(colors: _C.fabGrad),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: _C.teal.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: const Text('TRADE',
              style: TextStyle(color: _C.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        ),
        const SizedBox(width: 10),
        const Text('Portfolio', style: TextStyle(color: _C.black, fontSize: 18, fontWeight: FontWeight.w800)),
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
        color: _C.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.grey.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: _C.grey.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Stack(clipBehavior: Clip.none, children: [
        Icon(icon, size: 18, color: _C.black),
        if (badge)
          Positioned(right: -1, top: -1,
              child: Container(width: 6, height: 6,
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
      ]),
    );
  }

  Widget _buildPortfolioCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight, colors: _C.heroGrad),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _C.white.withOpacity(0.25), width: 1.5),
          boxShadow: [BoxShadow(color: _C.teal.withOpacity(0.30), blurRadius: 30, offset: const Offset(0, 10))],
        ),
        child: Stack(children: [
          Positioned(top: -20, right: -20,
            child: Container(width: 140, height: 140,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [_C.white.withOpacity(0.18), Colors.transparent]))),
          ),
          Positioned(bottom: -30, left: 20,
            child: Container(width: 100, height: 100,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [_C.white.withOpacity(0.10), Colors.transparent]))),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Total Portfolio Value',
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                _changeChip('+5.8% today'),
              ]),
              const SizedBox(height: 10),
              const Text('TZS 21,200,000',
                  style: TextStyle(color: _C.white, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              const SizedBox(height: 4),
              const Row(children: [
                Icon(Icons.trending_up_rounded, size: 16, color: Colors.white70),
                SizedBox(width: 4),
                Text('+TZS 1,160,000 this month',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _changeChip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: _C.white.withOpacity(0.18),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _C.white.withOpacity(0.3)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.arrow_upward_rounded, size: 11, color: _C.white),
      const SizedBox(width: 3),
      Text(label, style: const TextStyle(color: _C.white, fontSize: 11, fontWeight: FontWeight.w700)),
    ]),
  );

  Widget _buildActionGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        Row(children: [
          Expanded(child: _primaryBtn(
            label: 'Buy', icon: Icons.trending_up_rounded, grad: _C.buyGrad, shadow: _C.green,
            onTap: () { HapticFeedback.mediumImpact(); _push(const BuySharesPage()); },
          )),
          const SizedBox(width: 12),
          Expanded(child: _primaryBtn(
            label: 'Sell', icon: Icons.trending_down_rounded, grad: _C.sellGrad, shadow: _C.red,
            onTap: () { HapticFeedback.mediumImpact(); _push(const SellSharesPage()); },
          )),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _secondaryBtn(
            label: 'My Orders', sublabel: 'Live orders',
            icon: Icons.receipt_long_rounded, iconColor: _C.teal,
            iconBg: _C.teal.withOpacity(0.10), borderColor: _C.teal.withOpacity(0.30),
            onTap: () { HapticFeedback.mediumImpact(); _push(const OrdersPage()); },
          )),
          const SizedBox(width: 12),
          Expanded(child: _secondaryBtn(
            label: 'Market Watch', sublabel: 'DSE live',
            icon: Icons.bar_chart_rounded, iconColor: _C.blue,
            iconBg: _C.blue.withOpacity(0.10), borderColor: _C.blue.withOpacity(0.30),
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
        gradient: LinearGradient(colors: grad, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: shadow.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: _C.white, size: 20),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: _C.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
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
        color: _C.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [BoxShadow(color: _C.grey.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Container(width: 40, height: 40,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 20)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: _C.black, fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(sublabel, style: TextStyle(color: _C.grey, fontSize: 11)),
        ])),
        Icon(Icons.chevron_right_rounded, color: _C.grey, size: 18),
      ]),
    ),
  );

  Widget _buildFmsShortcut() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () { HapticFeedback.mediumImpact(); Navigator.pop(context); },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          decoration: BoxDecoration(
            color: _C.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _C.teal.withOpacity(0.25), width: 1.5),
            boxShadow: [BoxShadow(color: _C.teal.withOpacity(0.10), blurRadius: 20, offset: const Offset(0, 6))],
          ),
          child: Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: _C.fabGrad, begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: _C.teal.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.account_balance_rounded, color: _C.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Fund Management System',
                  style: TextStyle(color: _C.black, fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              const Text('Tap to open FMS dashboard →',
                  style: TextStyle(color: _C.teal, fontSize: 12, fontWeight: FontWeight.w500)),
            ])),
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: _C.teal.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: _C.teal.withOpacity(0.25)),
              ),
              child: const Icon(Icons.arrow_forward_rounded, color: _C.teal, size: 18),
            ),
          ]),
        ),
      ),
    );
  }
}