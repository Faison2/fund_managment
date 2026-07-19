import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tsl/constants/secure_storage.dart';
import '../buysell/buy.dart';
import '../buysell/sell.dart';
import '../market_watch/market_watch.dart';
import 'drawer.dart';
import 'my_orders.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TSL BRAND PALETTE
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  static const Color blue      = Color(0xFF329AD6);
  static const Color teal      = Color(0xFF00A79D);
  static const Color grey      = Color(0xFF939598);
  static const Color white     = Color(0xFFFFFFFF);
  static const Color black     = Color(0xFF231F20);
  static const Color green     = Color(0xFF34C759);
  static const Color red       = Color(0xFFFF3B30);
  static const Color gold      = Color(0xFFF5A623);
  static const Color bg        = Color(0xFFF0F7FC);   // soft blue-grey page bg

  static const List<Color> heroGrad = [Color(0xFF00A79D), Color(0xFF329AD6)];
  static const List<Color> fabGrad  = [Color(0xFF00A79D), Color(0xFF329AD6)];
  static const List<Color> buyGrad  = [Color(0xFF34C759), Color(0xFF1E8E3E)];
  static const List<Color> sellGrad = [Color(0xFFFF6B6B), Color(0xFFFF3B30)];
}

// ─────────────────────────────────────────────────────────────────────────────
// HOLDINGS MODEL
// ─────────────────────────────────────────────────────────────────────────────
class Holding {
  final String brokerName;
  final String securityId;
  final String securityName;
  final int    freeBalance;
  final int    pledgedBalance;
  final int    totalBalance;

  const Holding({
    required this.brokerName,
    required this.securityId,
    required this.securityName,
    required this.freeBalance,
    required this.pledgedBalance,
    required this.totalBalance,
  });

  factory Holding.fromJson(Map<String, dynamic> j) => Holding(
    brokerName:      j['brokerName']      as String,
    securityId:      j['securityId']      as String,
    securityName:    j['securityName']    as String,
    freeBalance:     (j['freeBalance']    as num).toInt(),
    pledgedBalance:  (j['pledgedBalance'] as num).toInt(),
    totalBalance:    (j['totalBalance']   as num).toInt(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// HOLDINGS API
// ─────────────────────────────────────────────────────────────────────────────
class _HoldingsApi {
  static const _url = 'https://portaluat.tsl.co.tz/DSEAPI/Home/GetInvestorHoldings';

  static Future<List<Holding>> fetch() async {
    final nida = await SecureStorage.read('nida_number') ?? '';
    if (nida.isEmpty) throw Exception('NIDA number not set. Please log in again.');

    final client = HttpClient();
    client.badCertificateCallback = (_, __, ___) => true;
    client.connectionTimeout = const Duration(seconds: 15);
    try {
      final req = await client.postUrl(Uri.parse(_url));
      req.headers
        ..set('Accept',       'application/json')
        ..set('Content-Type', 'application/json')
        ..set('User-Agent',   'DSEApp/1.0');
      req.write(jsonEncode({
        'payload':   {'nidaNumber': nida},
        'signature': '',
      }));
      final res  = await req.close();
      final body = await res.transform(utf8.decoder).join();
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final json = jsonDecode(body) as Map<String, dynamic>;
      if ((json['code'] as int) != 9000) throw Exception(json['message']);
      return (json['data'] as List)
          .cast<Map<String, dynamic>>()
          .map(Holding.fromJson)
          .toList();
    } finally {
      client.close();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PORTFOLIO MODEL
// ─────────────────────────────────────────────────────────────────────────────
class PortfolioPosition {
  final String securityId;
  final String securityName;
  final String securityRef;
  final String brokerName;
  final String brokerReference;
  final int    freeBalance;
  final int    pledgedBalance;
  final int    totalBalance;
  final double marketPrice;
  final double positionValue;
  final double freeValue;
  final double change;
  final double percentageChange;
  final bool   priceAvailable;

  const PortfolioPosition({
    required this.securityId,
    required this.securityName,
    required this.securityRef,
    required this.brokerName,
    required this.brokerReference,
    required this.freeBalance,
    required this.pledgedBalance,
    required this.totalBalance,
    required this.marketPrice,
    required this.positionValue,
    required this.freeValue,
    required this.change,
    required this.percentageChange,
    required this.priceAvailable,
  });

  factory PortfolioPosition.fromJson(Map<String, dynamic> j) => PortfolioPosition(
    securityId:       j['securityId']       as String? ?? '',
    securityName:     j['securityName']     as String? ?? '',
    securityRef:      j['securityRef']      as String? ?? '',
    brokerName:       j['brokerName']       as String? ?? '',
    brokerReference:  j['brokerReference']  as String? ?? '',
    freeBalance:      (j['freeBalance']      as num?)?.toInt()    ?? 0,
    pledgedBalance:   (j['pledgedBalance']   as num?)?.toInt()    ?? 0,
    totalBalance:     (j['totalBalance']     as num?)?.toInt()    ?? 0,
    marketPrice:      (j['marketPrice']      as num?)?.toDouble() ?? 0,
    positionValue:    (j['positionValue']    as num?)?.toDouble() ?? 0,
    freeValue:        (j['freeValue']        as num?)?.toDouble() ?? 0,
    change:           (j['change']           as num?)?.toDouble() ?? 0,
    percentageChange: (j['percentageChange'] as num?)?.toDouble() ?? 0,
    priceAvailable:   j['priceAvailable'] as bool? ?? false,
  );
}

class Portfolio {
  final String nidaNumber;
  final int    positionCount;
  final int    totalShares;
  final double portfolioValue;
  final double freePortfolioValue;
  final List<PortfolioPosition> positions;

  const Portfolio({
    required this.nidaNumber,
    required this.positionCount,
    required this.totalShares,
    required this.portfolioValue,
    required this.freePortfolioValue,
    required this.positions,
  });

  factory Portfolio.fromJson(Map<String, dynamic> j) => Portfolio(
    nidaNumber:         j['nidaNumber']          as String? ?? '',
    positionCount:      (j['positionCount']      as num?)?.toInt()    ?? 0,
    totalShares:        (j['totalShares']        as num?)?.toInt()    ?? 0,
    portfolioValue:     (j['portfolioValue']     as num?)?.toDouble() ?? 0,
    freePortfolioValue: (j['freePortfolioValue'] as num?)?.toDouble() ?? 0,
    positions: ((j['positions'] as List?) ?? [])
        .cast<Map<String, dynamic>>()
        .map(PortfolioPosition.fromJson)
        .toList(),
  );

  // Weighted day-change %, using each priced position's percentageChange
  // weighted by its position value. Positions without a live price
  // (priceAvailable == false) are excluded from the weighting.
  double get dayChangePercent {
    final priced = positions.where((p) => p.priceAvailable && p.positionValue > 0);
    if (priced.isEmpty) return 0;
    final totalValue = priced.fold<double>(0, (s, p) => s + p.positionValue);
    if (totalValue == 0) return 0;
    final weighted = priced.fold<double>(
        0, (s, p) => s + (p.percentageChange * p.positionValue));
    return weighted / totalValue;
  }

  // Approximate absolute day-change in value: each position's per-share
  // `change` times the shares held.
  double get dayChangeValue =>
      positions.fold<double>(0, (s, p) => s + (p.change * p.totalBalance));
}

// ─────────────────────────────────────────────────────────────────────────────
// PORTFOLIO API
// ─────────────────────────────────────────────────────────────────────────────
class _PortfolioApi {
  static const _url = 'https://portaluat.tsl.co.tz/DSEAPI/Home/GetPortfolio';

  // Same self-healing NIDA resolution used in Market Watch: prefer the
  // verified 'nida_number', fall back to the session 'userNIDA' if the
  // dashboard is reached before the user has completed DSE verification
  // on this device, and backfill 'nida_number' so future calls (from any
  // page) don't need to fall back again.
  static Future<String> _resolveWorkingNida() async {
    final saved = await SecureStorage.read('nida_number') ?? '';
    if (saved.isNotEmpty) return saved;

    final sessionNida = await SecureStorage.read('userNIDA') ?? '';
    if (sessionNida.isNotEmpty) {
      await SecureStorage.write('nida_number', sessionNida);
      return sessionNida;
    }
    return '';
  }

  static Future<Portfolio> fetch() async {
    final nida = await _resolveWorkingNida();
    if (nida.isEmpty) throw Exception('NIDA number not set. Please log in again.');

    final client = HttpClient();
    client.badCertificateCallback = (_, __, ___) => true;
    client.connectionTimeout = const Duration(seconds: 15);
    try {
      final req = await client.postUrl(Uri.parse(_url));
      req.headers
        ..set('Accept',       'application/json')
        ..set('Content-Type', 'application/json')
        ..set('User-Agent',   'DSEApp/1.0');
      req.write(jsonEncode({
        'payload':   {'nidaNumber': nida},
        'signature': '',
      }));
      final res  = await req.close();
      final body = await res.transform(utf8.decoder).join();
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final json = jsonDecode(body) as Map<String, dynamic>;
      if ((json['code'] as int) != 9000) throw Exception(json['message']);
      return Portfolio.fromJson(json['data'] as Map<String, dynamic>);
    } finally {
      client.close();
    }
  }
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
    final nida = await SecureStorage.read('nida_number') ?? '';
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
      try { buyCounts[DateTime.parse(r['orderDate'] as String).month - 1]++; } catch (_) {}
    }
    for (final r in results[1]) {
      try { sellCounts[DateTime.parse(r['orderDate'] as String).month - 1]++; } catch (_) {}
    }

    const labels = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return List.generate(12, (i) => _MonthPoint(labels[i], buyCounts[i], sellCounts[i]));
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

    final gridPaint = Paint()..color = _C.grey.withOpacity(0.20)..strokeWidth = 1;
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
        ..color = lineColor ..strokeWidth = 2.2 ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round ..strokeJoin = StrokeJoin.round);
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
          ..color = _C.white ..style = PaintingStyle.stroke ..strokeWidth = 1.5);
        if (isHl) {
          final val = isB ? points[i].buy : points[i].sell;
          tp.text = TextSpan(text: '$val',
              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900));
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
// HOLDINGS PAGE (full screen)
// ─────────────────────────────────────────────────────────────────────────────
class HoldingsPage extends StatefulWidget {
  const HoldingsPage({Key? key}) : super(key: key);
  @override
  State<HoldingsPage> createState() => _HoldingsPageState();
}

class _HoldingsPageState extends State<HoldingsPage> with SingleTickerProviderStateMixin {
  List<Holding> _holdings = [];
  bool    _loading = true;
  String? _error;
  late AnimationController _anim;
  late Animation<double>   _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 400))..forward();
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _load();
  }

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final h = await _HoldingsApi.fetch();
      setState(() { _holdings = h; _loading = false; });
      _anim.forward(from: 0);
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  int get _totalShares => _holdings.fold(0, (s, h) => s + h.totalBalance);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: FadeTransition(
        opacity: _fade,
        child: RefreshIndicator(
          color: _C.teal, backgroundColor: _C.white, onRefresh: _load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // ── App Bar ──────────────────────────────────────────────────
              SliverAppBar(
                backgroundColor: _C.bg,
                pinned: true,
                elevation: 0,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _C.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _C.grey.withOpacity(0.25)),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: _C.black),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                title: const Text('My Holdings',
                    style: TextStyle(color: _C.black, fontSize: 18, fontWeight: FontWeight.w900)),
                actions: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _C.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _C.grey.withOpacity(0.25)),
                      ),
                      child: const Icon(Icons.refresh_rounded, size: 14, color: _C.teal),
                    ),
                    onPressed: _loading ? null : _load,
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              // ── Summary Banner ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: _C.heroGrad,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: _C.teal.withOpacity(0.30), blurRadius: 24, offset: const Offset(0, 8))],
                    ),
                    child: Stack(children: [
                      Positioned(top: -18, right: -18,
                        child: Container(width: 120, height: 120,
                          decoration: BoxDecoration(shape: BoxShape.circle,
                              gradient: RadialGradient(colors: [_C.white.withOpacity(0.15), Colors.transparent])),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(22),
                        child: Row(children: [
                          Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(
                              color: _C.white.withOpacity(0.20),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _C.white.withOpacity(0.35)),
                            ),
                            child: const Icon(Icons.pie_chart_rounded, color: _C.white, size: 26),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Total Holdings',
                                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text(
                              _loading ? '—' : '$_totalShares shares',
                              style: const TextStyle(color: _C.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _loading ? '' : '${_holdings.length} securit${_holdings.length == 1 ? 'y' : 'ies'}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ])),
                        ]),
                      ),
                    ]),
                  ),
                ),
              ),

              // ── Content ───────────────────────────────────────────────────
              if (_loading)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (_, i) => _HoldingSkeletonCard(), childCount: 4,
                  ),
                )
              else if (_error != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                    child: Column(children: [
                      Container(width: 64, height: 64,
                          decoration: BoxDecoration(color: _C.red.withOpacity(0.10), shape: BoxShape.circle),
                          child: const Icon(Icons.wifi_off_rounded, color: _C.red, size: 28)),
                      const SizedBox(height: 16),
                      const Text('Unable to load holdings',
                          style: TextStyle(color: _C.black, fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text(_error!, style: TextStyle(color: _C.grey, fontSize: 12), textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: _load,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: _C.teal.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _C.teal.withOpacity(0.4)),
                          ),
                          child: const Text('Retry', style: TextStyle(color: _C.teal, fontSize: 13, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ]),
                  ),
                )
              else if (_holdings.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: Column(children: [
                        Icon(Icons.inbox_rounded, color: _C.grey, size: 40),
                        SizedBox(height: 12),
                        Text('No holdings found', style: TextStyle(color: _C.grey, fontSize: 14)),
                      ])),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (_, i) => _HoldingCard(holding: _holdings[i], index: i),
                        childCount: _holdings.length,
                      ),
                    ),
                  ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HOLDING CARD
// ─────────────────────────────────────────────────────────────────────────────
class _HoldingCard extends StatefulWidget {
  final Holding holding;
  final int     index;
  const _HoldingCard({required this.holding, required this.index});
  @override
  State<_HoldingCard> createState() => _HoldingCardState();
}

class _HoldingCardState extends State<_HoldingCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _fade;
  late Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: Duration(milliseconds: 350 + widget.index * 60))..forward();
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Color get _accentColor {
    final colors = [_C.teal, _C.blue, const Color(0xFF9B59B6), _C.gold, _C.green];
    return colors[widget.index % colors.length];
  }

  String get _initials {
    final s = widget.holding.securityName.trim();
    if (s.isEmpty) return '??';
    final parts = s.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return s.substring(0, min(2, s.length)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.holding;
    final pct = h.totalBalance > 0 ? (h.freeBalance / h.totalBalance * 100).round() : 0;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _C.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _accentColor.withOpacity(0.18)),
            boxShadow: [
              BoxShadow(color: _accentColor.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(children: [
            // ── Header row ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(children: [
                // Avatar
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [_accentColor, _accentColor.withOpacity(0.70)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: _accentColor.withOpacity(0.30), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: Center(child: Text(_initials,
                      style: const TextStyle(color: _C.white, fontSize: 15, fontWeight: FontWeight.w900))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(h.securityName,
                      style: const TextStyle(color: _C.black, fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(h.securityId,
                      style: TextStyle(color: _accentColor, fontSize: 11, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(h.brokerName,
                      style: TextStyle(color: _C.grey, fontSize: 10),
                      overflow: TextOverflow.ellipsis),
                ])),
                // Total badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _accentColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _accentColor.withOpacity(0.25)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${h.totalBalance}',
                        style: TextStyle(color: _accentColor, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                    Text('shares', style: TextStyle(color: _accentColor.withOpacity(0.70), fontSize: 9, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ]),
            ),

            // ── Progress bar (free vs pledged) ────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Free balance', style: TextStyle(color: _C.grey, fontSize: 10, fontWeight: FontWeight.w600)),
                  Text('$pct% available', style: TextStyle(color: _accentColor, fontSize: 10, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: h.totalBalance > 0 ? h.freeBalance / h.totalBalance : 0,
                    minHeight: 5,
                    backgroundColor: _accentColor.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
                  ),
                ),
              ]),
            ),

            // ── Stat row ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(children: [
                _HoldingStat(label: 'Free',     value: '${h.freeBalance}',    color: _C.teal),
                _vDivider(),
                _HoldingStat(label: 'Pledged',  value: '${h.pledgedBalance}', color: _C.gold),
                _vDivider(),
                _HoldingStat(label: 'Total',    value: '${h.totalBalance}',   color: _accentColor),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _vDivider() => Container(width: 1, height: 32, color: _C.grey.withOpacity(0.15),
      margin: const EdgeInsets.symmetric(horizontal: 8));
}

class _HoldingStat extends StatelessWidget {
  final String label; final String value; final Color color;
  const _HoldingStat({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w900)),
    const SizedBox(height: 2),
    Text(label, style: TextStyle(color: _C.grey, fontSize: 10, fontWeight: FontWeight.w600)),
  ]));
}

class _HoldingSkeletonCard extends StatefulWidget {
  @override
  State<_HoldingSkeletonCard> createState() => _HoldingSkeletonCardState();
}

class _HoldingSkeletonCardState extends State<_HoldingSkeletonCard> with SingleTickerProviderStateMixin {
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
    builder: (_, __) {
      final sh = Color.lerp(const Color(0xFFD6EBF7), const Color(0xFFB8D9EF), _a.value)!;
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        height: 110,
        decoration: BoxDecoration(color: _C.white, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _C.grey.withOpacity(0.15))),
        child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: sh, borderRadius: BorderRadius.circular(14))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(height: 13, width: 100, color: sh),
            const SizedBox(height: 7),
            Container(height: 10, width: 60,  color: sh),
            const SizedBox(height: 7),
            Container(height: 8,  width: 140, color: sh),
          ])),
        ])),
      );
    },
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// INTERACTIVE CHART CARD
// ─────────────────────────────────────────────────────────────────────────────
class _OrdersChartCard extends StatefulWidget {
  const _OrdersChartCard();
  @override State<_OrdersChartCard> createState() => _OrdersChartCardState();
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
        border: Border.all(color: _C.grey.withOpacity(0.18), width: 1.5),
        boxShadow: [
          BoxShadow(color: _C.teal.withOpacity(0.07), blurRadius: 24, offset: const Offset(0, 8)),
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
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Order Activity',
                  style: TextStyle(color: _C.black, fontSize: 15, fontWeight: FontWeight.w900)),
              Text('Monthly buy vs sell — $_year',
                  style: TextStyle(color: _C.grey, fontSize: 11)),
            ])),
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
              ? _ChartTooltip(point: _points[_hlIndex])
              : const SizedBox(height: 16),
        ),
        const SizedBox(height: 4),
      ]),
    );
  }

  void _onTap(TapDownDetails d, BuildContext ctx) => _updateHL(d.localPosition.dx, ctx);
  void _onPan(DragUpdateDetails d, BuildContext ctx) => _updateHL(d.localPosition.dx, ctx);
  void _updateHL(double dx, BuildContext ctx) {
    final box  = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
    final w    = box.size.width - 24;
    final step = w / (_points.length - 1);
    final i    = ((dx - 12) / step).round().clamp(0, _points.length - 1);
    if (i != _hlIndex) setState(() => _hlIndex = i);
  }
}

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
      Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text('$year', style: const TextStyle(color: _C.teal, fontSize: 12, fontWeight: FontWeight.w800))),
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
    child: Padding(padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: onTap == null ? _C.grey : _C.teal)),
  );
}

class _LegendDot extends StatelessWidget {
  final Color color; final String label; final String value;
  const _LegendDot({required this.color, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 6),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: _C.grey, fontSize: 9, fontWeight: FontWeight.w600)),
      Text(value, style: TextStyle(color: color,   fontSize: 12, fontWeight: FontWeight.w800)),
    ]),
  ]);
}

class _ChartTooltip extends StatelessWidget {
  final _MonthPoint point;
  const _ChartTooltip({required this.point});
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
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900)),
    Text(label, style: const TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.w500)),
  ]);
}

class _ChartShimmer extends StatefulWidget {
  const _ChartShimmer();
  @override State<_ChartShimmer> createState() => _ChartShimmerState();
}

class _ChartShimmerState extends State<_ChartShimmer> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double>   _a;
  @override void initState() { super.initState();
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
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [
            Color.lerp(_C.grey.withOpacity(0.1), _C.teal.withOpacity(0.1), _a.value)!,
            Color.lerp(_C.teal.withOpacity(0.1), _C.grey.withOpacity(0.1), _a.value)!,
          ],
        ),
      ),
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(width: 24, height: 24,
            child: CircularProgressIndicator(color: _C.teal.withOpacity(0.5), strokeWidth: 2)),
        const SizedBox(height: 10),
        Text('Loading chart…', style: TextStyle(color: _C.grey, fontSize: 12)),
      ])),
    ),
  );
}

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
// HOLDING CHIP (mini card for strip)
// ─────────────────────────────────────────────────────────────────────────────
class _HoldingChip extends StatelessWidget {
  final Holding? holding;
  final int      index;
  final bool     isSkeleton;

  const _HoldingChip({required this.holding, required this.index})
      : isSkeleton = false;

  const _HoldingChip.skeleton()
      : holding = null, index = 0, isSkeleton = true;

  static const _colors = [_C.teal, _C.blue, Color(0xFF9B59B6), _C.gold, _C.green];

  Color get _accent => _colors[index % _colors.length];

  String get _initials {
    final s = holding!.securityName.trim();
    if (s.isEmpty) return '??';
    final parts = s.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return s.substring(0, min(2, s.length)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (isSkeleton) {
      return Container(
        width: 120, height: 116, margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: _C.white, borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _C.grey.withOpacity(0.15)),
        ),
      );
    }

    final h = holding!;
    return Container(
      width: 120, height: 116, margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _accent.withOpacity(0.20)),
        boxShadow: [BoxShadow(color: _accent.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [_accent, _accent.withOpacity(0.70)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(_initials,
                style: const TextStyle(color: _C.white, fontSize: 13, fontWeight: FontWeight.w900))),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(h.securityName, style: const TextStyle(color: _C.black, fontSize: 12, fontWeight: FontWeight.w800),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text('${h.totalBalance} shares',
                style: TextStyle(color: _accent, fontSize: 11, fontWeight: FontWeight.w700)),
          ]),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN DASHBOARD
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

  Portfolio? _portfolio;
  bool       _portfolioLoading = true;
  String?    _portfolioError;

  @override
  void initState() {
    super.initState();
    _pageAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    _pageFade = CurvedAnimation(parent: _pageAnim, curve: Curves.easeOut);
    _loadPortfolio();
  }

  @override
  void dispose() { _pageAnim.dispose(); super.dispose(); }

  Future<void> _loadPortfolio() async {
    setState(() { _portfolioLoading = true; _portfolioError = null; });
    try {
      final p = await _PortfolioApi.fetch();
      setState(() { _portfolio = p; _portfolioLoading = false; });
    } catch (e) {
      setState(() { _portfolioLoading = false; _portfolioError = e.toString(); });
    }
  }

  void _push(Widget page) {
    HapticFeedback.mediumImpact();
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
        backgroundColor: _C.bg,
        drawer: TradeDrawer(onSwitchToFms: () { Navigator.pop(context); Navigator.pop(context); }),
        body: FadeTransition(
          opacity: _pageFade,
          child: RefreshIndicator(
            color: _C.teal,
            backgroundColor: _C.white,
            onRefresh: _loadPortfolio,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(
                  child: Column(children: [
                    _buildPortfolioCard(),
                    const SizedBox(height: 22),
                    _buildActionGrid(),
                    const SizedBox(height: 24),
                    _buildFmsShortcut(),
                    const SizedBox(height: 28),
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
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: _C.bg,
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

  Widget _iconBox(IconData icon, {bool badge = false}) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: _C.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _C.grey.withOpacity(0.25)),
      boxShadow: [BoxShadow(color: _C.grey.withOpacity(0.10), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Stack(clipBehavior: Clip.none, children: [
      Icon(icon, size: 18, color: _C.black),
      if (badge)
        Positioned(right: -1, top: -1,
            child: Container(width: 6, height: 6,
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
    ]),
  );

  Widget _buildPortfolioCard() {
    final loading = _portfolioLoading;
    final error   = _portfolioError;
    final p       = _portfolio;
    final ready   = !loading && error == null && p != null;

    final changePercent = ready ? p.dayChangePercent : 0.0;
    final changeValue   = ready ? p.dayChangeValue   : 0.0;
    final isPositive    = changePercent >= 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight, colors: _C.heroGrad),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _C.white.withOpacity(0.20), width: 1.5),
          boxShadow: [
            BoxShadow(color: _C.teal.withOpacity(0.30), blurRadius: 32, offset: const Offset(0, 12)),
            BoxShadow(color: _C.blue.withOpacity(0.15), blurRadius: 20, offset: const Offset(8, 4)),
          ],
        ),
        child: Stack(children: [
          Positioned(top: -28, right: -28,
            child: Container(width: 160, height: 160,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [_C.white.withOpacity(0.18), Colors.transparent]))),
          ),
          Positioned(bottom: -40, left: 10,
            child: Container(width: 120, height: 120,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [_C.white.withOpacity(0.10), Colors.transparent]))),
          ),
          Padding(
            padding: const EdgeInsets.all(26),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _C.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _C.white.withOpacity(0.30)),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: _C.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  const Text('Portfolio', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
                if (loading)
                  const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _C.white),
                  )
                else if (error != null)
                  GestureDetector(
                    onTap: _loadPortfolio,
                    child: _changeChip('Retry'),
                  )
                else
                  _changeChip('${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}% today'),
              ]),
              const SizedBox(height: 18),
              Text(
                ready ? 'TZS ${_fmtMoney(p.portfolioValue)}' : 'TZS —',
                style: const TextStyle(color: _C.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1.0),
              ),
              const SizedBox(height: 6),
              Row(children: [
                Icon(
                  !ready
                      ? Icons.remove_rounded
                      : isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  size: 14, color: Colors.white70,
                ),
                const SizedBox(width: 4),
                Text(
                  loading
                      ? 'Loading your portfolio…'
                      : error != null
                      ? 'Unable to load portfolio'
                      : '${changeValue >= 0 ? '+' : ''}TZS ${_fmtMoney(changeValue)} today',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ]),
              const SizedBox(height: 20),
              Row(children: [
                _MiniStat(
                  label: 'Total Shares',
                  value: ready ? '${p.totalShares}' : '—',
                  positive: null,
                ),
                Container(width: 1, height: 28, color: _C.white.withOpacity(0.25), margin: const EdgeInsets.symmetric(horizontal: 16)),
                _MiniStat(
                  label: 'Positions',
                  value: ready ? '${p.positionCount}' : '—',
                  positive: null,
                ),
                Container(width: 1, height: 28, color: _C.white.withOpacity(0.25), margin: const EdgeInsets.symmetric(horizontal: 16)),
                _MiniStat(
                  label: 'Free Value',
                  value: ready ? 'TZS ${_fmtMoney(p.freePortfolioValue)}' : '—',
                  positive: null,
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  // Formats a double as a comma-grouped whole-number string, e.g. 37300.0 -> "37,300".
  String _fmtMoney(double v) {
    final s = v.round().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final posFromEnd = s.length - i;
      buf.write(s[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }

  Widget _changeChip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: _C.white.withOpacity(0.18),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _C.white.withOpacity(0.30)),
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
            onTap: () => _push(const BuySharesPage()),
          )),
          const SizedBox(width: 12),
          Expanded(child: _primaryBtn(
            label: 'Sell', icon: Icons.trending_down_rounded, grad: _C.sellGrad, shadow: _C.red,
            onTap: () => _push(const SellSharesPage()),
          )),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _secondaryBtn(
            label: 'My Orders', sublabel: 'Live orders',
            icon: Icons.receipt_long_rounded, iconColor: _C.teal,
            iconBg: _C.teal.withOpacity(0.10), borderColor: _C.teal.withOpacity(0.28),
            onTap: () => _push(const OrdersPage()),
          )),
          const SizedBox(width: 10),
          Expanded(child: _secondaryBtn(
            label: 'Market', sublabel: 'DSE live',
            icon: Icons.bar_chart_rounded, iconColor: _C.blue,
            iconBg: _C.blue.withOpacity(0.10), borderColor: _C.blue.withOpacity(0.28),
            onTap: () => _push(const DseMarketWatchPage()),
          )),
          const SizedBox(width: 10),
          Expanded(child: _secondaryBtn(
            label: 'Holdings', sublabel: 'Portfolio',
            icon: Icons.pie_chart_rounded, iconColor: const Color(0xFF329AD6),
            iconBg: const Color(0xFF329AD6).withOpacity(0.10),
            borderColor: const Color(0xFF329AD6).withOpacity(0.28),
            onTap: () => _push(const HoldingsPage()),
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
        boxShadow: [BoxShadow(color: shadow.withOpacity(0.30), blurRadius: 16, offset: const Offset(0, 6))],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [BoxShadow(color: _C.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 40,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 20)),
        const SizedBox(height: 7),
        Text(label, style: const TextStyle(color: _C.black, fontSize: 12, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center),
        const SizedBox(height: 2),
        Text(sublabel, style: TextStyle(color: _C.grey, fontSize: 10), textAlign: TextAlign.center),
      ]),
    ),
  );

  // ── FMS Shortcut ───────────────────────────────────────────────────────────
  Widget _buildFmsShortcut() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () { HapticFeedback.mediumImpact(); Navigator.pop(context); },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: _C.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _C.teal.withOpacity(0.22), width: 1.5),
            boxShadow: [BoxShadow(color: _C.teal.withOpacity(0.08), blurRadius: 18, offset: const Offset(0, 5))],
          ),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: _C.fabGrad, begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: _C.teal.withOpacity(0.30), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: const Icon(Icons.account_balance_rounded, color: _C.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Fund Management System',
                  style: TextStyle(color: _C.black, fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('Switch to FMS dashboard →',
                  style: TextStyle(color: _C.teal, fontSize: 11, fontWeight: FontWeight.w600)),
            ])),
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: _C.teal.withOpacity(0.08), shape: BoxShape.circle,
                border: Border.all(color: _C.teal.withOpacity(0.25)),
              ),
              child: const Icon(Icons.arrow_forward_rounded, color: _C.teal, size: 16),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MINI STAT (inside portfolio card)
// ─────────────────────────────────────────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final bool?  positive;   // null = neutral
  const _MiniStat({required this.label, required this.value, required this.positive});

  @override
  Widget build(BuildContext context) {
    final valueColor = positive == null
        ? _C.white
        : positive! ? const Color(0xFF7FFFD4) : const Color(0xFFFFB3AE);
    return Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w500)),
      const SizedBox(height: 3),
      Text(value, style: TextStyle(color: valueColor, fontSize: 13, fontWeight: FontWeight.w900)),
    ]));
  }
}