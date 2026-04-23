import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../buysell/trade.dart';

class _C {
  static const bg      = Color(0xFFE8F4EF);
  static const surface = Color(0xFFF2FAF6);
  static const card    = Color(0xFFFFFFFF);
  static const border  = Color(0xFFD0E8DF);
  static const blue    = Color(0xFF1A7A65);
  static const green   = Color(0xFF27AE72);
  static const red     = Color(0xFFE05C7A);
  static const gray    = Color(0xFF9E9E9E);
  static const gold    = Color(0xFFF5A623);
  static const txtPrim = Color(0xFF1A2B28);
  static const txtSec  = Color(0xFF7A9990);
  static const txtHint = Color(0xFFAAC9C0);
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPANY META
// ─────────────────────────────────────────────────────────────────────────────
const Map<String, Map<String, String>> _kMeta = {
  'TBL':        {'name': 'Tanzania Breweries Ltd',       'sector': 'Consumer Goods'},
  'CRDB':       {'name': 'CRDB Bank PLC',                'sector': 'Banking'},
  'NMB':        {'name': 'NMB Bank PLC',                 'sector': 'Banking'},
  'SWIS':       {'name': 'Swissport Tanzania PLC',       'sector': 'Aviation'},
  'TOL':        {'name': 'Tanga Cement PLC',             'sector': 'Construction'},
  'DCB':        {'name': 'DCB Commercial Bank',          'sector': 'Banking'},
  'TPCC':       {'name': 'Tanzania Portland Cement',     'sector': 'Construction'},
  'MUCOBA':     {'name': 'Mufindi Community Bank',       'sector': 'Banking'},
  'TCCL':       {'name': 'Tanzania Cigarette Company',   'sector': 'Consumer Goods'},
  'TCC':        {'name': 'Tanzania Cigarette Company',   'sector': 'Consumer Goods'},
  'VODA':       {'name': 'Vodacom Tanzania PLC',         'sector': 'Telecom'},
  'MCB':        {'name': 'Mkombozi Commercial Bank',     'sector': 'Banking'},
  'MKCB':       {'name': 'Maendeleo Bank PLC',           'sector': 'Banking'},
  'MBP':        {'name': 'Mwalimu Commercial Bank',      'sector': 'Banking'},
  'PAL':        {'name': 'Precision Air Services PLC',   'sector': 'Aviation'},
  'NICO':       {'name': 'NICO Holdings PLC',            'sector': 'Insurance'},
  'DSE':        {'name': 'Dar es Salaam Stock Exchange', 'sector': 'Financial Services'},
  'TTP':        {'name': 'Tanzania Tea Packers Ltd',     'sector': 'Agriculture'},
  'AFRIPRISE':  {'name': 'Afriprise Investments Ltd',   'sector': 'Financial Services'},
  'VERTEX-ETF': {'name': 'Vertex Exchange Fund',         'sector': 'ETF'},
};

String _companyName(String symbol) => _kMeta[symbol]?['name'] ?? symbol;
String _sector(String symbol)      => _kMeta[symbol]?['sector'] ?? 'Equity';

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
  final List<double> sparkline;
  final double high;
  final double low;
  final double openingPrice;
  final double bestBidPrice;
  final double bestOfferPrice;
  final int    bestBidQty;
  final int    bestOfferQty;
  final double marketCap;
  final String lastTradeTime;

  const DseStock({
    required this.symbol,
    required this.company,
    required this.sector,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.volume,
    required this.sparkline,
    required this.high,
    required this.low,
    required this.openingPrice,
    required this.bestBidPrice,
    required this.bestOfferPrice,
    required this.bestBidQty,
    required this.bestOfferQty,
    required this.marketCap,
    required this.lastTradeTime,
  });

  factory DseStock.fromJson(Map<String, dynamic> j) {
    final symbol       = (j['securityName'] as String).trim();
    final price        = (j['marketPrice'] as num).toDouble();
    final change       = (j['change'] as num).toDouble();
    final open         = (j['openingPrice'] as num).toDouble();
    final high         = (j['high'] as num).toDouble();
    final low          = (j['low'] as num).toDouble();
    final rawVol       = (j['volume'] as num).toInt();
    final bestBid      = (j['bestBidPrice'] as num).toDouble();
    final bestOffer    = (j['bestOfferPrice'] as num).toDouble();
    final bestBidQty   = (j['bestBidQuantity'] as num).toInt();
    final bestOfferQty = (j['bestOfferQuantity'] as num).toInt();
    final marketCap    = (j['marketCap'] as num).toDouble();
    final time         = (j['time'] as String?) ?? '';
    final pct          = open != 0 ? (change / open) * 100 : 0.0;

    return DseStock(
      symbol:         symbol,
      company:        _companyName(symbol),
      sector:         _sector(symbol),
      price:          price,
      change:         change,
      changePercent:  pct,
      volume:         _fmtVolume(rawVol),
      sparkline:      _buildSparkline(open, high, low, price),
      high:           high,
      low:            low,
      openingPrice:   open,
      bestBidPrice:   bestBid,
      bestOfferPrice: bestOffer,
      bestBidQty:     bestBidQty,
      bestOfferQty:   bestOfferQty,
      marketCap:      marketCap,
      lastTradeTime:  time,
    );
  }

  bool get isGain => changePercent > 0;
  bool get isLoss => changePercent < 0;
  bool get isFlat => changePercent == 0;

  Color get trendColor =>
      isGain ? _C.green : isLoss ? _C.red : _C.gray;
}

String _fmtVolume(int v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
  if (v >= 1000)    return '${(v / 1000).toStringAsFixed(1)}K';
  return v.toString();
}

List<double> _buildSparkline(double open, double high, double low, double close) {
  if (high == low) return List.filled(12, 0.5);
  final rng    = Random(open.toInt() ^ close.toInt());
  final prices = <double>[open];
  final midHigh = low + (high - low) * (0.55 + rng.nextDouble() * 0.3);
  final midLow  = low + (high - low) * (0.15 + rng.nextDouble() * 0.25);
  final goUp    = close >= open;
  prices.add(goUp ? midLow : midHigh);
  for (int i = 2; i < 10; i++) {
    final prev  = prices.last;
    final nudge = (rng.nextDouble() - 0.47) * (high - low) * 0.18;
    prices.add((prev + nudge).clamp(low, high));
  }
  prices.add(close);
  final mn    = prices.reduce(min);
  final mx    = prices.reduce(max);
  final range = mx - mn;
  if (range == 0) return List.filled(prices.length, 0.5);
  return prices.map((p) => (p - mn) / range).toList();
}

// ─────────────────────────────────────────────────────────────────────────────
// API SERVICE
// ─────────────────────────────────────────────────────────────────────────────
class _DseApi {
  static const _url           = 'https://portaluat.tsl.co.tz/DSEAPI/Home/GetMarketWatch';
  static const _hardcodedNida = '19931225100010000001';

  static Future<List<DseStock>> fetchMarketWatch() async {
    final client = HttpClient();
    client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    client.connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client.postUrl(Uri.parse(_url));
      request.headers
        ..set('Accept',       'application/json')
        ..set('Content-Type', 'application/json')
        ..set('User-Agent',   'DSEApp/1.0 (Flutter; Dart)');
      request.write(jsonEncode({'nidaNumber': _hardcodedNida, 'signature': ''}));
      final response = await request.close();
      final body     = await response.transform(utf8.decoder).join();
      if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');
      final json = jsonDecode(body) as Map<String, dynamic>;
      final code = json['code'] as int;
      if (code != 9000) throw Exception('API code $code: ${json['message']}');
      final data = (json['data'] as List<dynamic>).cast<Map<String, dynamic>>();
      return data.map(DseStock.fromJson).toList()
        ..sort((a, b) => a.symbol.compareTo(b.symbol));
    } finally {
      client.close();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SPARKLINE PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final bool showFill;
  SparklinePainter({required this.data, required this.color, this.showFill = true});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      points.add(Offset(i / (data.length - 1) * size.width, (1 - data[i]) * size.height));
    }
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final cp1 = Offset((points[i].dx + points[i + 1].dx) / 2, points[i].dy);
      final cp2 = Offset((points[i].dx + points[i + 1].dx) / 2, points[i + 1].dy);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, points[i + 1].dx, points[i + 1].dy);
    }
    if (showFill) {
      final fillPath = Path.from(path)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(fillPath, Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.28), color.withOpacity(0.00)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill);
    }
    canvas.drawPath(path, Paint()
      ..color = color ..strokeWidth = 1.8 ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round ..strokeJoin = StrokeJoin.round);
    canvas.drawCircle(points.last, 3.0, Paint()..color = color.withOpacity(0.3));
    canvas.drawCircle(points.last, 3.0, Paint()..color = color);
  }

  @override
  bool shouldRepaint(SparklinePainter old) => old.data != data || old.color != color;
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
    final totalVol = stocks.fold<int>(0, (s, e) {
      final raw = e.volume;
      if (raw.endsWith('M')) return s + ((double.tryParse(raw.replaceAll('M', '')) ?? 0) * 1000000).toInt();
      if (raw.endsWith('K')) return s + ((double.tryParse(raw.replaceAll('K', '')) ?? 0) * 1000).toInt();
      return s + (int.tryParse(raw) ?? 0);
    });
    final items = [
      _BannerItem(icon: Icons.trending_up_rounded,   label: 'Gainers',   value: '$gainers',          color: _C.green),
      _BannerItem(icon: Icons.trending_down_rounded, label: 'Losers',    value: '$losers',            color: _C.red),
      _BannerItem(icon: Icons.remove_rounded,        label: 'Unchanged', value: '$flat',              color: _C.gray),
      _BannerItem(icon: Icons.bar_chart_rounded,     label: 'Vol',       value: _fmtVolume(totalVol), color: _C.blue),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Row(
        children: items.asMap().entries.map((e) {
          final item   = e.value;
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
              child: Column(children: [
                Icon(item.icon, color: item.color, size: 18),
                const SizedBox(height: 5),
                Text(item.value,
                    style: TextStyle(color: item.color, fontSize: 16,
                        fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                const SizedBox(height: 2),
                Text(item.label,
                    style: const TextStyle(color: _C.txtSec, fontSize: 9,
                        fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _BannerItem {
  final IconData icon; final String label; final String value; final Color color;
  const _BannerItem({required this.icon, required this.label, required this.value, required this.color});
}

// ─────────────────────────────────────────────────────────────────────────────
// STOCK CARD  — display only, no trade actions
// ─────────────────────────────────────────────────────────────────────────────
class _StockCard extends StatefulWidget {
  final DseStock stock;
  final int index;
  const _StockCard({required this.stock, required this.index});

  @override
  State<_StockCard> createState() => _StockCardState();
}

class _StockCardState extends State<_StockCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450))..forward();
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final s     = widget.stock;
    final color = s.trendColor;
    final sign  = s.isGain ? '+' : '';

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TradePage(
                  symbol:         s.symbol,
                  company:        s.company,
                  sector:         s.sector,
                  price:          s.price,
                  high:           s.high,
                  low:            s.low,
                  changePercent:  s.changePercent,
                  change:         s.change,
                  bestBidPrice:   s.bestBidPrice,
                  bestOfferPrice: s.bestOfferPrice,
                  bestBidQty:     s.bestBidQty,
                  bestOfferQty:   s.bestOfferQty,
                  marketCap:      s.marketCap,
                  lastTradeTime:  s.lastTradeTime,
                  sparkline:      s.sparkline,
                  volume:         s.volume,
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            decoration: BoxDecoration(
              color: _C.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _C.border),
              boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(children: [
              // ── Top row ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withOpacity(0.25)),
                    ),
                    child: Center(child: Text(
                      s.symbol.substring(0, min(2, s.symbol.length)),
                      style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                    )),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.symbol, style: const TextStyle(color: _C.txtPrim, fontSize: 15, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(s.company, style: const TextStyle(color: _C.txtSec, fontSize: 11), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: _C.blue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _C.blue.withOpacity(0.2)),
                      ),
                      child: Text(s.sector, style: const TextStyle(color: _C.blue, fontSize: 9, fontWeight: FontWeight.w700)),
                    ),
                  ])),
                ]),
              ),

              // ── Full-width sparkline ──────────────────────────────────────
              SizedBox(
                height: 56, width: double.infinity,
                child: CustomPaint(painter: SparklinePainter(data: s.sparkline, color: color)),
              ),

              Container(height: 1, color: _C.border),

              // ── Bottom row ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('TZS ${s.price.toStringAsFixed(2)}',
                        style: const TextStyle(color: _C.txtPrim, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                    const SizedBox(height: 3),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: color.withOpacity(0.25)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(s.isGain ? Icons.arrow_upward_rounded : s.isLoss ? Icons.arrow_downward_rounded : Icons.remove_rounded,
                              size: 10, color: color),
                          const SizedBox(width: 3),
                          Text('$sign${s.changePercent.toStringAsFixed(2)}%',
                              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
                        ]),
                      ),
                      const SizedBox(width: 6),
                      Text('${s.change >= 0 ? '+' : ''}${s.change.toStringAsFixed(0)}',
                          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      Row(children: [
                        const Icon(Icons.swap_vert_rounded, size: 11, color: _C.txtHint),
                        const SizedBox(width: 3),
                        Text('Vol ${s.volume}',
                            style: const TextStyle(color: _C.txtSec, fontSize: 10, fontWeight: FontWeight.w600)),
                      ]),
                    ]),
                  ])),

                  // High / Low
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Row(children: [
                      const Text('H', style: TextStyle(color: _C.txtHint, fontSize: 9, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 4),
                      Text(s.high.toStringAsFixed(0), style: const TextStyle(color: _C.green, fontSize: 10, fontWeight: FontWeight.w800)),
                    ]),
                    const SizedBox(height: 3),
                    Row(children: [
                      const Text('L', style: TextStyle(color: _C.txtHint, fontSize: 9, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 4),
                      Text(s.low.toStringAsFixed(0), style: const TextStyle(color: _C.red, fontSize: 10, fontWeight: FontWeight.w800)),
                    ]),
                  ]),
                ]),
              ),
            ]),
          ), // Container
        ), // GestureDetector
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP STATS ROW
// ─────────────────────────────────────────────────────────────────────────────
class _LiveStatsRow extends StatelessWidget {
  final List<DseStock> stocks;
  const _LiveStatsRow({required this.stocks});

  @override
  Widget build(BuildContext context) {
    if (stocks.isEmpty) return const SizedBox.shrink();
    final sorted    = [...stocks]..sort((a, b) => b.changePercent.compareTo(a.changePercent));
    final topGainer = sorted.first;
    final topLoser  = sorted.last;
    final totalVolRaw = stocks.fold<int>(0, (s, e) {
      final raw = e.volume;
      if (raw.endsWith('M')) return s + ((double.tryParse(raw.replaceAll('M', '')) ?? 0) * 1e6).toInt();
      if (raw.endsWith('K')) return s + ((double.tryParse(raw.replaceAll('K', '')) ?? 0) * 1000).toInt();
      return s + (int.tryParse(raw) ?? 0);
    });
    final items = [
      _StatCard(label: 'Top Gainer', value: topGainer.symbol,
          sub: '${topGainer.changePercent >= 0 ? '+' : ''}${topGainer.changePercent.toStringAsFixed(2)}%',
          color: _C.green, icon: Icons.trending_up_rounded),
      _StatCard(label: 'Top Loser', value: topLoser.symbol,
          sub: '${topLoser.changePercent.toStringAsFixed(2)}%',
          color: _C.red, icon: Icons.trending_down_rounded),
      _StatCard(label: 'Total Vol', value: _fmtVolume(totalVolRaw),
          sub: 'shares traded', color: _C.blue, icon: Icons.bar_chart_rounded),
      _StatCard(label: 'Listed', value: '${stocks.length}',
          sub: 'securities', color: _C.green, icon: Icons.list_alt_rounded),
    ];
    return SizedBox(
      height: 88,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        itemCount: items.length,
        itemBuilder: (_, i) => TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + i * 80),
          curve: Curves.easeOut,
          builder: (_, v, child) => Opacity(opacity: v, child: child),
          child: items[i],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label; final String value; final String sub; final Color color; final IconData icon;
  const _StatCard({required this.label, required this.value, required this.sub, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    width: 148, margin: const EdgeInsets.only(right: 10), padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: _C.txtSec, fontSize: 10, fontWeight: FontWeight.w600)),
      Text(value,  style: const TextStyle(color: _C.txtPrim, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.5), overflow: TextOverflow.ellipsis),
      Row(children: [
        Icon(icon, size: 10, color: color), const SizedBox(width: 3),
        Expanded(child: Text(sub, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis)),
      ]),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title; final IconData icon; final Widget? trailing;
  const _SectionHeader({required this.title, required this.icon, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    child: Row(children: [
      Container(width: 28, height: 28,
          decoration: BoxDecoration(color: _C.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: _C.blue, size: 14)),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(color: _C.txtPrim, fontSize: 13, fontWeight: FontWeight.w800)),
      const Spacer(),
      if (trailing != null) trailing!,
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTER ROW
// ─────────────────────────────────────────────────────────────────────────────
class _FilterRow extends StatelessWidget {
  final int selected; final ValueChanged<int> onChanged;
  const _FilterRow({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const tabs   = ['All', 'Gainers', 'Losers', 'Flat'];
    const colors = [_C.blue, _C.green, _C.red, _C.gray];
    return Container(
      height: 32,
      decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: tabs.asMap().entries.map((e) {
          final sel = selected == e.key; final col = colors[e.key];
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); onChanged(e.key); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: sel ? col.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                border: sel ? Border.all(color: col.withOpacity(0.4)) : null,
              ),
              child: Center(child: Text(e.value,
                  style: TextStyle(color: sel ? col : _C.txtSec, fontSize: 11,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500))),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOADING SKELETON
// ─────────────────────────────────────────────────────────────────────────────
class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();
  @override State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _anim, builder: (_, __) {
      final shimmer = Color.lerp(const Color(0xFF112131), const Color(0xFF1A3045), _anim.value)!;
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        height: 130,
        decoration: BoxDecoration(color: _C.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: _C.border)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: shimmer, borderRadius: BorderRadius.circular(12))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(height: 12, width: 80,  color: shimmer),
              const SizedBox(height: 6),
              Container(height: 10, width: 140, color: shimmer),
              const SizedBox(height: 6),
              Container(height: 8,  width: 60,  color: shimmer),
            ])),
          ]),
        ),
      );
    });
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
  int _filter = 0;

  List<DseStock> _stocks  = [];
  bool   _loading = true;
  String? _error;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 400))..forward();
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _fetchData();
  }

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  Future<void> _fetchData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final stocks = await _DseApi.fetchMarketWatch();
      setState(() { _stocks = stocks; _loading = false; _lastUpdated = DateTime.now(); });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  List<DseStock> get _filtered {
    switch (_filter) {
      case 1:  return _stocks.where((s) => s.isGain).toList();
      case 2:  return _stocks.where((s) => s.isLoss).toList();
      case 3:  return _stocks.where((s) => s.isFlat).toList();
      default: return _stocks;
    }
  }

  String get _lastUpdatedLabel {
    if (_lastUpdated == null) return '';
    final t = _lastUpdated!;
    return 'Updated ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: FadeTransition(
        opacity: _fade,
        child: RefreshIndicator(
          color: _C.blue, backgroundColor: _C.card, onRefresh: _fetchData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              SliverAppBar(
                backgroundColor: _C.bg, pinned: true, elevation: 0,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: _C.border)),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: _C.txtPrim),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('DSE Market Watch',
                      style: TextStyle(color: _C.txtPrim, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: -0.3)),
                  Text(
                    _loading ? 'Fetching live data…' : _error != null ? 'Connection error' : _lastUpdatedLabel,
                    style: TextStyle(color: _error != null ? _C.red : _C.txtSec, fontSize: 10),
                  ),
                ]),
                actions: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: _C.border)),
                      child: const Icon(Icons.refresh_rounded, size: 14, color: _C.blue),
                    ),
                    onPressed: _loading ? null : _fetchData,
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: _C.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _C.green.withOpacity(0.3))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      _PulseDot(color: _C.green), const SizedBox(width: 5),
                      const Text('LIVE', style: TextStyle(color: _C.green, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ]),
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SizedBox(height: 12),
                  if (!_loading && _error == null && _stocks.isNotEmpty) ...[
                    _SectionHeader(
                        title: 'Market Snapshot  ·  ${_stocks.first.lastTradeTime.substring(0, 10)}',
                        icon: Icons.show_chart_rounded),
                    _LiveStatsRow(stocks: _stocks),
                    const SizedBox(height: 20),
                    const _SectionHeader(title: 'Market Summary', icon: Icons.bar_chart_rounded),
                    _MarketBanner(stocks: _stocks),
                  ],
                  _SectionHeader(
                    title: 'Listed Securities${_stocks.isNotEmpty ? ' (${_filtered.length})' : ''}',
                    icon: Icons.list_alt_rounded,
                    trailing: _stocks.isEmpty ? null : _FilterRow(selected: _filter, onChanged: (v) => setState(() => _filter = v)),
                  ),
                ]),
              ),

              if (_loading)
                SliverList(delegate: SliverChildBuilderDelegate((_, i) => const _SkeletonCard(), childCount: 6))
              else if (_error != null)
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                  child: Column(children: [
                    Container(width: 64, height: 64,
                        decoration: BoxDecoration(color: _C.red.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.wifi_off_rounded, color: _C.red, size: 28)),
                    const SizedBox(height: 16),
                    const Text('Unable to connect', style: TextStyle(color: _C.txtPrim, fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(_error!, style: const TextStyle(color: _C.txtSec, fontSize: 12), textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: _fetchData,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(color: _C.blue.withOpacity(0.15), borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _C.blue.withOpacity(0.4))),
                        child: const Text('Retry', style: TextStyle(color: _C.blue, fontSize: 13, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ]),
                ))
              else if (_filtered.isEmpty)
                  const SliverToBoxAdapter(child: Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: Text('No securities match this filter.', style: TextStyle(color: _C.txtSec, fontSize: 13))),
                  ))
                else
                  SliverList(delegate: SliverChildBuilderDelegate(
                        (_, i) { if (i >= _filtered.length) return null; return _StockCard(stock: _filtered[i], index: i); },
                    childCount: _filtered.length,
                  )),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
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
  @override State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.8, end: 1.2).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: _scale,
    child: Container(width: 6, height: 6, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)),
  );
}