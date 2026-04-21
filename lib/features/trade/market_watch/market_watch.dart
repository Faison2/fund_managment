import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// THEME TOKENS
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  static const bg      = Color(0xFF080C14);
  static const surface = Color(0xFF0F1520);
  static const card    = Color(0xFF131A27);
  static const border  = Color(0xFF1E2A3A);
  static const green   = Color(0xFF00D97E);
  static const red     = Color(0xFFFF4560);
  static const gray    = Color(0xFF8899AA);
  static const gold    = Color(0xFFFFBB33);
  static const teal    = Color(0xFF00C2FF);
  static const txtPrim = Color(0xFFECF2FF);
  static const txtSec  = Color(0xFF6B7E96);
  static const txtHint = Color(0xFF3D4F62);
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPANY META — local lookup only (the API does NOT return display names or
// sectors). Falls back gracefully to the raw symbol / "Equity" when unknown.
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

String _companyName(String symbol) =>
    _kMeta[symbol]?['name'] ?? symbol;

String _sector(String symbol) =>
    _kMeta[symbol]?['sector'] ?? 'Equity';

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
  // Extra API fields
  final double high;
  final double low;
  final double openingPrice;
  final double bestBidPrice;
  final double bestOfferPrice;
  final int    bestBidQty;
  final int    bestOfferQty;
  final double marketCap;
  /// Raw timestamp string returned by the API ("2026-04-21 10:18:18")
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

  // ── Factory from API JSON ────────────────────────────────────────────────
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

    // percentageChange from the API is always 0 — compute from change/open
    final pct = open != 0 ? (change / open) * 100 : 0.0;

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

  Color get trendBg =>
      isGain
          ? _C.green.withOpacity(0.09)
          : isLoss
          ? _C.red.withOpacity(0.09)
          : _C.gray.withOpacity(0.07);
}

// ── Helpers ────────────────────────────────────────────────────────────────

String _fmtVolume(int v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
  if (v >= 1000)    return '${(v / 1000).toStringAsFixed(1)}K';
  return v.toString();
}

String _fmtMarketCap(double v) {
  if (v >= 1e12) return 'TZS ${(v / 1e12).toStringAsFixed(2)}T';
  if (v >= 1e9)  return 'TZS ${(v / 1e9).toStringAsFixed(2)}B';
  if (v >= 1e6)  return 'TZS ${(v / 1e6).toStringAsFixed(2)}M';
  return 'TZS ${v.toStringAsFixed(0)}';
}

/// Build a 12-point normalised sparkline from open/high/low/close.
List<double> _buildSparkline(
    double open, double high, double low, double close) {
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
// API SERVICE  — bypasses self-signed / IP TLS cert on the UAT host
// ─────────────────────────────────────────────────────────────────────────────
class _DseApi {
  static const _url =
      'https://portaluat.tsl.co.tz/DSEAPI/Home/GetMarketWatch';

  // TODO: replace with real NIDA number from user session / auth flow
  static const _hardcodedNida = '19931225100010000001';

  static Future<List<DseStock>> fetchMarketWatch() async {
    final client = HttpClient();
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    client.connectionTimeout = const Duration(seconds: 15);

    try {
      final request = await client.postUrl(Uri.parse(_url));
      request.headers
        ..set('Accept',       'application/json')
        ..set('Content-Type', 'application/json')
        ..set('User-Agent',   'DSEApp/1.0 (Flutter; Dart)');

      final payload = jsonEncode({
        'nidaNumber': _hardcodedNida,
        'signature':  '',
      });
      request.write(payload);

      final response = await request.close();
      final body     = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        throw Exception(
            'HTTP ${response.statusCode} — ${body.substring(0, body.length.clamp(0, 200))}');
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      final code = json['code'] as int;
      if (code != 9000) {
        throw Exception('API code $code: ${json['message']}');
      }

      final data =
      (json['data'] as List<dynamic>).cast<Map<String, dynamic>>();
      return data
          .map(DseStock.fromJson)
          .toList()
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
      points.add(Offset(i / (data.length - 1) * size.width,
          (1 - data[i]) * size.height));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final cp1 = Offset((points[i].dx + points[i + 1].dx) / 2, points[i].dy);
      final cp2 = Offset((points[i].dx + points[i + 1].dx) / 2, points[i + 1].dy);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy,
          points[i + 1].dx, points[i + 1].dy);
    }

    if (showFill) {
      final fillPath = Path.from(path)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withOpacity(0.28), color.withOpacity(0.00)],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
          ..style = PaintingStyle.fill,
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawCircle(points.last, 3.0, Paint()..color = color.withOpacity(0.3));
    canvas.drawCircle(points.last, 3.0, Paint()..color = color);
  }

  @override
  bool shouldRepaint(SparklinePainter old) =>
      old.data != data || old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// MARKET SUMMARY BANNER  (computed entirely from live API stocks)
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
      // Parse the already-formatted volume string back to an int estimate
      final raw = e.volume;
      if (raw.endsWith('M')) {
        return s + ((double.tryParse(raw.replaceAll('M', '')) ?? 0) * 1000000).toInt();
      } else if (raw.endsWith('K')) {
        return s + ((double.tryParse(raw.replaceAll('K', '')) ?? 0) * 1000).toInt();
      }
      return s + (int.tryParse(raw) ?? 0);
    });

    final items = [
      _BannerItem(icon: Icons.trending_up_rounded,   label: 'Gainers',   value: '$gainers',         color: _C.green),
      _BannerItem(icon: Icons.trending_down_rounded, label: 'Losers',    value: '$losers',           color: _C.red),
      _BannerItem(icon: Icons.remove_rounded,        label: 'Unchanged', value: '$flat',             color: _C.gray),
      _BannerItem(icon: Icons.bar_chart_rounded,     label: 'Vol',       value: _fmtVolume(totalVol), color: _C.teal),
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
              child: Column(
                children: [
                  Icon(item.icon, color: item.color, size: 18),
                  const SizedBox(height: 5),
                  Text(item.value,
                      style: TextStyle(
                          color: item.color, fontSize: 16,
                          fontWeight: FontWeight.w900, letterSpacing: -0.5)),
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
  const _BannerItem(
      {required this.icon, required this.label, required this.value, required this.color});
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
  int _side  = 0;
  int _type  = 0;
  int _qty   = 100;
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
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color  get _sideColor => _side == 0 ? _C.green : _C.red;
  String get _sideLabel => _side == 0 ? 'BUY' : 'SELL';

  @override
  Widget build(BuildContext context) {
    final total = _qty * (_type == 0 ? widget.stock.price : _limitPrice);

    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
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
                  color: _C.border, borderRadius: BorderRadius.circular(2)),
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
                      const Text('Place Order',
                          style: TextStyle(
                              color: _C.txtPrim, fontSize: 20,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text(
                          '${widget.stock.symbol} · ${widget.stock.company}',
                          style: const TextStyle(
                              color: _C.txtSec, fontSize: 12)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
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
                              fontSize: 14, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          '${widget.stock.changePercent >= 0 ? '+' : ''}${widget.stock.changePercent.toStringAsFixed(2)}%',
                          style: TextStyle(
                              color: widget.stock.trendColor,
                              fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Bid / Offer / Range row — all from API
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _InfoChip(
                        label: 'Best Bid',
                        value: 'TZS ${widget.stock.bestBidPrice.toStringAsFixed(0)}',
                        sub: '${widget.stock.bestBidQty} shares',
                        color: _C.green),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _InfoChip(
                        label: 'Best Offer',
                        value: 'TZS ${widget.stock.bestOfferPrice.toStringAsFixed(0)}',
                        sub: '${widget.stock.bestOfferQty} shares',
                        color: _C.red),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _InfoChip(
                        label: 'Day Range',
                        value: '${widget.stock.low.toStringAsFixed(0)} – ${widget.stock.high.toStringAsFixed(0)}',
                        sub: 'TZS',
                        color: _C.teal),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Market cap row — from API
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.pie_chart_outline_rounded,
                      size: 13, color: _C.txtHint),
                  const SizedBox(width: 5),
                  Text('Market Cap: ${_fmtMarketCap(widget.stock.marketCap)}',
                      style: const TextStyle(color: _C.txtSec, fontSize: 11)),
                  if (widget.stock.lastTradeTime.isNotEmpty) ...[
                    const Spacer(),
                    const Icon(Icons.access_time_rounded,
                        size: 11, color: _C.txtHint),
                    const SizedBox(width: 4),
                    Text(
                      widget.stock.lastTradeTime.length > 10
                          ? widget.stock.lastTradeTime.substring(11, 16)
                          : widget.stock.lastTradeTime,
                      style: const TextStyle(color: _C.txtSec, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

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
                                    fontSize: 13, fontWeight: FontWeight.w800,
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
                          color: sel ? _C.teal.withOpacity(0.12) : _C.card,
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

            // Quantity + limit price
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _FieldBox(
                      label: 'Shares',
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _StepBtn(
                              icon: Icons.remove,
                              onTap: () =>
                                  setState(() => _qty = max(1, _qty - 100))),
                          Text('$_qty',
                              style: const TextStyle(
                                  color: _C.txtPrim, fontSize: 16,
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
                                    color: _C.txtPrim, fontSize: 14,
                                    fontWeight: FontWeight.w900)),
                            _StepBtn(
                                icon: Icons.add,
                                onTap: () =>
                                    setState(() => _limitPrice += 10)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Estimated total
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _sideColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _sideColor.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Estimated Total',
                        style: TextStyle(color: _C.txtSec, fontSize: 12)),
                    Text(
                      'TZS ${_fmtMoney(total)}',
                      style: TextStyle(
                          color: _sideColor, fontSize: 16,
                          fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Confirm
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
                        colors: [_sideColor, _sideColor.withOpacity(0.7)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: _sideColor.withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$_sideLabel ${widget.stock.symbol}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 15,
                          fontWeight: FontWeight.w900, letterSpacing: 0.5),
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

  String _fmtMoney(double v) {
    if (v >= 1e9)  return '${(v / 1e9).toStringAsFixed(2)}B';
    if (v >= 1e6)  return '${(v / 1e6).toStringAsFixed(2)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;
  const _InfoChip(
      {required this.label, required this.value, required this.sub,
        required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.07),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: _C.txtSec, fontSize: 9, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w800),
            overflow: TextOverflow.ellipsis),
        Text(sub,
            style: const TextStyle(color: _C.txtHint, fontSize: 9)),
      ],
    ),
  );
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
                color: _C.txtSec, fontSize: 10, fontWeight: FontWeight.w600)),
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
      width: 28, height: 28,
      decoration: BoxDecoration(
          color: _C.border, borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: _C.txtPrim, size: 14),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// STOCK CARD
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
        vsync: this, duration: const Duration(milliseconds: 450))
      ..forward();
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s     = widget.stock;
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
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              // Top row
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar — initials from symbol
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withOpacity(0.25)),
                      ),
                      child: Center(
                        child: Text(
                          s.symbol.substring(0, min(2, s.symbol.length)),
                          style: TextStyle(
                              color: color, fontSize: 13,
                              fontWeight: FontWeight.w900, letterSpacing: -0.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Symbol + company name + sector — all from API / _kMeta lookup
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.symbol,
                              style: const TextStyle(
                                  color: _C.txtPrim, fontSize: 15,
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
                              border: Border.all(color: _C.teal.withOpacity(0.2)),
                            ),
                            child: Text(s.sector,
                                style: const TextStyle(
                                    color: _C.teal, fontSize: 9,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),

                    // Sparkline — built from open/high/low/close
                    SizedBox(
                      width: 90, height: 48,
                      child: CustomPaint(
                        painter: SparklinePainter(
                            data: s.sparkline, color: color),
                      ),
                    ),
                  ],
                ),
              ),

              Container(height: 1, color: _C.border),

              // Bottom row — price / change / volume all from API
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TZS ${s.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: _C.txtPrim, fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5)),
                        const SizedBox(height: 3),
                        Row(
                          children: [
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
                                      size: 10, color: color),
                                  const SizedBox(width: 3),
                                  Text(
                                      '$sign${s.changePercent.toStringAsFixed(2)}%',
                                      style: TextStyle(
                                          color: color, fontSize: 11,
                                          fontWeight: FontWeight.w800)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${s.change >= 0 ? '+' : ''}${s.change.toStringAsFixed(0)}',
                              style: TextStyle(
                                  color: color, fontSize: 10,
                                  fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              children: [
                                const Icon(Icons.swap_vert_rounded,
                                    size: 11, color: _C.txtHint),
                                const SizedBox(width: 3),
                                Text('Vol ${s.volume}',
                                    style: const TextStyle(
                                        color: _C.txtSec, fontSize: 10,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Place Order button
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
                                offset: const Offset(0, 3)),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.add_rounded, size: 13, color: _C.bg),
                            SizedBox(width: 4),
                            Text('Place Order',
                                style: TextStyle(
                                    color: _C.bg, fontSize: 11,
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
// TOP STATS ROW  — replaces the old hardcoded _IndicesRow
// Computes gainers / losers / total volume / listed count from live data.
// ─────────────────────────────────────────────────────────────────────────────
class _LiveStatsRow extends StatelessWidget {
  final List<DseStock> stocks;
  const _LiveStatsRow({required this.stocks});

  @override
  Widget build(BuildContext context) {
    if (stocks.isEmpty) return const SizedBox.shrink();

    // Best performer
    final sorted = [...stocks]
      ..sort((a, b) => b.changePercent.compareTo(a.changePercent));
    final topGainer = sorted.first;
    final topLoser  = sorted.last;

    final totalVolRaw = stocks.fold<int>(0, (s, e) {
      final raw = e.volume;
      if (raw.endsWith('M')) {
        return s + ((double.tryParse(raw.replaceAll('M', '')) ?? 0) * 1e6).toInt();
      } else if (raw.endsWith('K')) {
        return s + ((double.tryParse(raw.replaceAll('K', '')) ?? 0) * 1000).toInt();
      }
      return s + (int.tryParse(raw) ?? 0);
    });

    final items = [
      _StatCard(
        label: 'Top Gainer',
        value: topGainer.symbol,
        sub: '${topGainer.changePercent >= 0 ? '+' : ''}${topGainer.changePercent.toStringAsFixed(2)}%',
        color: _C.green,
        icon: Icons.trending_up_rounded,
      ),
      _StatCard(
        label: 'Top Loser',
        value: topLoser.symbol,
        sub: '${topLoser.changePercent.toStringAsFixed(2)}%',
        color: _C.red,
        icon: Icons.trending_down_rounded,
      ),
      _StatCard(
        label: 'Total Vol',
        value: _fmtVolume(totalVolRaw),
        sub: 'shares traded',
        color: _C.teal,
        icon: Icons.bar_chart_rounded,
      ),
      _StatCard(
        label: 'Listed',
        value: '${stocks.length}',
        sub: 'securities',
        color: _C.gold,
        icon: Icons.list_alt_rounded,
      ),
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
  final String label;
  final String value;
  final String sub;
  final Color  color;
  final IconData icon;
  const _StatCard({
    required this.label, required this.value, required this.sub,
    required this.color, required this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: 148,
    margin: const EdgeInsets.only(right: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.07),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                color: _C.txtSec, fontSize: 10, fontWeight: FontWeight.w600)),
        Text(value,
            style: TextStyle(
                color: _C.txtPrim, fontSize: 16,
                fontWeight: FontWeight.w900, letterSpacing: -0.5),
            overflow: TextOverflow.ellipsis),
        Row(
          children: [
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
            Expanded(
              child: Text(sub,
                  style: TextStyle(
                      color: color, fontSize: 11,
                      fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ],
    ),
  );
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
          width: 28, height: 28,
          decoration: BoxDecoration(
              color: _C.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: _C.teal, size: 14),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                color: _C.txtPrim, fontSize: 13,
                fontWeight: FontWeight.w800)),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTER ROW
// ─────────────────────────────────────────────────────────────────────────────
class _FilterRow extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  const _FilterRow({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const tabs   = ['All', 'Gainers', 'Losers', 'Flat'];
    const colors = [_C.teal, _C.green, _C.red, _C.gray];

    return Container(
      height: 32,
      decoration: BoxDecoration(
          color: _C.surface, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: tabs.asMap().entries.map((e) {
          final sel = selected == e.key;
          final col = colors[e.key];
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(e.key);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: sel ? col.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                border: sel ? Border.all(color: col.withOpacity(0.4)) : null,
              ),
              child: Center(
                child: Text(e.value,
                    style: TextStyle(
                        color: sel ? col : _C.txtSec, fontSize: 11,
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
// LOADING SKELETON
// ─────────────────────────────────────────────────────────────────────────────
class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final shimmer = Color.lerp(
            const Color(0xFF131A27), const Color(0xFF1E2A3A), _anim.value)!;
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          height: 106,
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _C.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                        color: shimmer,
                        borderRadius: BorderRadius.circular(12))),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(height: 12, width: 80, color: shimmer),
                      const SizedBox(height: 6),
                      Container(height: 10, width: 140, color: shimmer),
                      const SizedBox(height: 6),
                      Container(height: 8, width: 60, color: shimmer),
                    ],
                  ),
                ),
                Container(width: 90, height: 48, color: shimmer),
              ],
            ),
          ),
        );
      },
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
  int _filter = 0;

  List<DseStock> _stocks  = [];
  bool   _loading = true;
  String? _error;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400))
      ..forward();
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _fetchData();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final stocks = await _DseApi.fetchMarketWatch();
      setState(() {
        _stocks      = stocks;
        _loading     = false;
        _lastUpdated = DateTime.now();
      });
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
          color: _C.teal,
          backgroundColor: _C.card,
          onRefresh: _fetchData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            slivers: [
              // ── App Bar ──────────────────────────────────────────────
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
                  children: [
                    const Text('DSE Market Watch',
                        style: TextStyle(
                            color: _C.txtPrim, fontSize: 17,
                            fontWeight: FontWeight.w900, letterSpacing: -0.3)),
                    Text(
                      _loading
                          ? 'Fetching live data…'
                          : _error != null
                          ? 'Connection error'
                          : _lastUpdatedLabel,
                      style: TextStyle(
                          color: _error != null ? _C.red : _C.txtSec,
                          fontSize: 10),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _C.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _C.border),
                      ),
                      child: const Icon(Icons.refresh_rounded,
                          size: 14, color: _C.teal),
                    ),
                    onPressed: _loading ? null : _fetchData,
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _C.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border:
                      Border.all(color: _C.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _PulseDot(color: _C.green),
                        const SizedBox(width: 5),
                        const Text('LIVE',
                            style: TextStyle(
                                color: _C.green, fontSize: 10,
                                fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Body ─────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // Live stats row — replaces the old hardcoded _IndicesRow
                    if (!_loading && _error == null && _stocks.isNotEmpty) ...[
                      _SectionHeader(
                          title: 'Market Snapshot  ·  ${_stocks.first.lastTradeTime.substring(0, 10)}',
                          icon: Icons.show_chart_rounded),
                      _LiveStatsRow(stocks: _stocks),
                      const SizedBox(height: 20),

                      const _SectionHeader(
                          title: 'Market Summary',
                          icon: Icons.bar_chart_rounded),
                      _MarketBanner(stocks: _stocks),
                    ],

                    _SectionHeader(
                      title: 'Listed Securities'
                          '${_stocks.isNotEmpty ? ' (${_filtered.length})' : ''}',
                      icon: Icons.list_alt_rounded,
                      trailing: _stocks.isEmpty
                          ? null
                          : _FilterRow(
                        selected: _filter,
                        onChanged: (v) => setState(() => _filter = v),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Content area ─────────────────────────────────────────
              if (_loading)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (_, i) => const _SkeletonCard(),
                    childCount: 6,
                  ),
                )
              else if (_error != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 48),
                    child: Column(
                      children: [
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                              color: _C.red.withOpacity(0.1),
                              shape: BoxShape.circle),
                          child: const Icon(Icons.wifi_off_rounded,
                              color: _C.red, size: 28),
                        ),
                        const SizedBox(height: 16),
                        const Text('Unable to connect',
                            style: TextStyle(
                                color: _C.txtPrim, fontSize: 16,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: const TextStyle(
                              color: _C.txtSec, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: _fetchData,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: _C.teal.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: _C.teal.withOpacity(0.4)),
                            ),
                            child: const Text('Retry',
                                style: TextStyle(
                                    color: _C.teal, fontSize: 13,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_filtered.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(
                        child: Text('No securities match this filter.',
                            style: TextStyle(color: _C.txtSec, fontSize: 13)),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (_, i) {
                        if (i >= _filtered.length) return null;
                        return _StockCard(stock: _filtered[i], index: i);
                      },
                      childCount: _filtered.length,
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
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.8, end: 1.2).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

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