import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// THEME TOKENS
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  static const bg      = Color(0xFFE8F4EF);
  static const surface = Color(0xFFF2FAF6);
  static const card    = Color(0xFFFFFFFF);
  static const border  = Color(0xFFD0E8DF);
  static const blue    = Color(0xFF1A7A65);
  static const green   = Color(0xFF27AE72);
  static const red     = Color(0xFFE05C7A);
  static const gray    = Color(0xFF9E9E9E);
  static const txtPrim = Color(0xFF1A2B28);
  static const txtSec  = Color(0xFF7A9990);
  static const txtHint = Color(0xFFAAC9C0);
}

// ─────────────────────────────────────────────────────────────────────────────
// TRADE TYPE
// ─────────────────────────────────────────────────────────────────────────────
enum TradeType { buy, sell }

// ─────────────────────────────────────────────────────────────────────────────
// TRADE API
// ─────────────────────────────────────────────────────────────────────────────
class _TradeApi {
  static const _buyUrl  = 'https://portaluat.tsl.co.tz/DSEAPI/Home/BuyShares';
  static const _sellUrl = 'https://portaluat.tsl.co.tz/DSEAPI//Home/SellShares';
  static const _nida    = '19931225100010000001';

  static Future<Map<String, dynamic>> execute({
    required TradeType type,
    required String    securityReference,
    required double    price,
    required int       shares,
  }) async {
    final url    = type == TradeType.buy ? _buyUrl : _sellUrl;
    final client = HttpClient();
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    client.connectionTimeout = const Duration(seconds: 15);

    try {
      final request = await client.postUrl(Uri.parse(url));
      request.headers
        ..set('Accept',       'application/json')
        ..set('Content-Type', 'application/json')
        ..set('User-Agent',   'DSEApp/1.0 (Flutter; Dart)');

      request.write(jsonEncode({
        'nidaNumber':        _nida,
        'price':             price,
        'securityReference': securityReference,
        'shares':            shares,
        'signature':         '',
      }));

      final response = await request.close();
      final body     = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      return jsonDecode(body) as Map<String, dynamic>;
    } finally {
      client.close();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SPARKLINE PAINTER  (mini chart at top of trade page)
// ─────────────────────────────────────────────────────────────────────────────
class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _SparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final pts = <Offset>[
      for (int i = 0; i < data.length; i++)
        Offset(i / (data.length - 1) * size.width, (1 - data[i]) * size.height)
    ];

    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final cp1 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i].dy);
      final cp2 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i + 1].dy);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts[i + 1].dx, pts[i + 1].dy);
    }

    // fill
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fill, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.30), color.withOpacity(0.00)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill);

    // line
    canvas.drawPath(path, Paint()
      ..color = color ..strokeWidth = 2.0 ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round ..strokeJoin = StrokeJoin.round);

    // dot
    canvas.drawCircle(pts.last, 4, Paint()..color = color.withOpacity(0.25));
    canvas.drawCircle(pts.last, 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────
String _fmtMoney(double v) {
  if (v >= 1e9)  return 'TZS ${(v / 1e9).toStringAsFixed(2)}B';
  if (v >= 1e6)  return 'TZS ${(v / 1e6).toStringAsFixed(2)}M';
  if (v >= 1000) return 'TZS ${(v / 1000).toStringAsFixed(1)}K';
  return 'TZS ${v.toStringAsFixed(0)}';
}

String _fmtMarketCap(double v) {
  if (v >= 1e12) return 'TZS ${(v / 1e12).toStringAsFixed(2)}T';
  if (v >= 1e9)  return 'TZS ${(v / 1e9).toStringAsFixed(2)}B';
  if (v >= 1e6)  return 'TZS ${(v / 1e6).toStringAsFixed(2)}M';
  return 'TZS ${v.toStringAsFixed(0)}';
}

// ─────────────────────────────────────────────────────────────────────────────
// TRADE PAGE
// ─────────────────────────────────────────────────────────────────────────────
class TradePage extends StatefulWidget {
  // Stock data passed in from MarketWatch — all fields auto-populate
  final String       symbol;
  final String       company;
  final String       sector;
  final double       price;
  final double       high;
  final double       low;
  final double       changePercent;
  final double       change;
  final double       bestBidPrice;
  final double       bestOfferPrice;
  final int          bestBidQty;
  final int          bestOfferQty;
  final double       marketCap;
  final String       lastTradeTime;
  final List<double> sparkline;
  final String       volume;

  const TradePage({
    Key? key,
    required this.symbol,
    required this.company,
    required this.sector,
    required this.price,
    required this.high,
    required this.low,
    required this.changePercent,
    required this.change,
    required this.bestBidPrice,
    required this.bestOfferPrice,
    required this.bestBidQty,
    required this.bestOfferQty,
    required this.marketCap,
    required this.lastTradeTime,
    required this.sparkline,
    required this.volume,
  }) : super(key: key);

  @override
  State<TradePage> createState() => _TradePageState();
}

class _TradePageState extends State<TradePage>
    with SingleTickerProviderStateMixin {
  // ── Trade state ───────────────────────────────────────────────────────────
  TradeType _tradeType = TradeType.buy;
  int       _shares    = 100;
  late double _price;

  bool    _loading = false;
  String? _error;
  String? _success;

  // ── Animation ─────────────────────────────────────────────────────────────
  late AnimationController _animCtrl;
  late Animation<double>   _fade;
  late Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _price = widget.price;

    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 480))
      ..forward();
    _fade  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Derived ───────────────────────────────────────────────────────────────
  bool get _isBuy      => _tradeType == TradeType.buy;
  Color get _accent    => _isBuy ? _C.green : _C.red;
  double get _total    => _price * _shares;

  bool get _isGain     => widget.changePercent > 0;
  bool get _isLoss     => widget.changePercent < 0;
  Color get _trendClr  => _isGain ? _C.green : _isLoss ? _C.red : _C.gray;

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (_shares <= 0) {
      setState(() => _error = 'Shares must be greater than zero.');
      return;
    }
    if (_price <= 0) {
      setState(() => _error = 'Please enter a valid price.');
      return;
    }

    HapticFeedback.heavyImpact();
    setState(() { _loading = true; _error = null; _success = null; });

    try {
      final result = await _TradeApi.execute(
        type:              _tradeType,
        securityReference: widget.symbol,
        price:             _price,
        shares:            _shares,
      );

      final code    = result['code'] as int?;
      final message = result['message'] as String? ??
          (_isBuy ? 'Buy order placed.' : 'Sell order placed.');

      setState(() {
        _loading = false;
        if (code == 9000) {
          _success = message;
          _error   = null;
        } else {
          _error   = message;
          _success = null;
        }
      });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); _success = null; });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [

              // ── App Bar ─────────────────────────────────────────────────
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
                title: Row(children: [
                  // Colour dot tracks trade type
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: _accent.withOpacity(0.35)),
                    ),
                    child: Center(
                      child: Text(
                        widget.symbol.substring(0, min(2, widget.symbol.length)),
                        style: TextStyle(color: _accent, fontSize: 11,
                            fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.symbol,
                            style: const TextStyle(color: _C.txtPrim, fontSize: 16,
                                fontWeight: FontWeight.w900, letterSpacing: -0.3)),
                        Text(widget.company,
                            style: const TextStyle(color: _C.txtSec, fontSize: 10),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ]),
                actions: [
                  // Live price badge
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _trendClr.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _trendClr.withOpacity(0.30)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('TZS ${widget.price.toStringAsFixed(2)}',
                            style: TextStyle(color: _trendClr, fontSize: 12,
                                fontWeight: FontWeight.w900)),
                        Text(
                          '${widget.changePercent >= 0 ? '+' : ''}${widget.changePercent.toStringAsFixed(2)}%',
                          style: TextStyle(color: _trendClr, fontSize: 9,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Body ────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Sparkline hero ─────────────────────────────────
                      Container(
                        width: double.infinity,
                        height: 130,
                        decoration: BoxDecoration(
                          color: _C.card,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _C.border),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Stack(children: [
                            // Full bleed chart
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _SparklinePainter(
                                    data: widget.sparkline, color: _trendClr),
                              ),
                            ),
                            // Overlay labels
                            Positioned(
                              top: 12, left: 14,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('TZS ${widget.price.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          color: _C.txtPrim, fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.8)),
                                  const SizedBox(height: 2),
                                  Row(children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _trendClr.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                                        Icon(
                                          _isGain
                                              ? Icons.arrow_upward_rounded
                                              : _isLoss
                                              ? Icons.arrow_downward_rounded
                                              : Icons.remove_rounded,
                                          size: 10, color: _trendClr,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${widget.changePercent >= 0 ? '+' : ''}${widget.changePercent.toStringAsFixed(2)}%  '
                                              '(${widget.change >= 0 ? '+' : ''}${widget.change.toStringAsFixed(0)})',
                                          style: TextStyle(color: _trendClr, fontSize: 10,
                                              fontWeight: FontWeight.w800),
                                        ),
                                      ]),
                                    ),
                                  ]),
                                ],
                              ),
                            ),
                            // High/Low/Vol bottom-right
                            Positioned(
                              bottom: 10, right: 14,
                              child: Row(children: [
                                _MiniStat(label: 'H', value: widget.high.toStringAsFixed(0), color: _C.green),
                                const SizedBox(width: 10),
                                _MiniStat(label: 'L', value: widget.low.toStringAsFixed(0), color: _C.red),
                                const SizedBox(width: 10),
                                _MiniStat(label: 'Vol', value: widget.volume, color: _C.blue),
                              ]),
                            ),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Market depth row ───────────────────────────────
                      Row(children: [
                        Expanded(child: _DepthTile(
                          label: 'Best Bid',
                          price: 'TZS ${widget.bestBidPrice.toStringAsFixed(0)}',
                          qty: '${widget.bestBidQty} shares',
                          color: _C.green,
                        )),
                        const SizedBox(width: 8),
                        Expanded(child: _DepthTile(
                          label: 'Best Offer',
                          price: 'TZS ${widget.bestOfferPrice.toStringAsFixed(0)}',
                          qty: '${widget.bestOfferQty} shares',
                          color: _C.red,
                        )),
                        const SizedBox(width: 8),
                        Expanded(child: _DepthTile(
                          label: 'Mkt Cap',
                          price: _fmtMarketCap(widget.marketCap),
                          qty: widget.sector,
                          color: _C.blue,
                        )),
                      ]),
                      const SizedBox(height: 20),

                      // ── Trade Type Dropdown ────────────────────────────
                      _Label('Trade Type'),
                      const SizedBox(height: 8),
                      _TradeDropdown(
                        value: _tradeType,
                        onChanged: (v) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _tradeType = v;
                            _error     = null;
                            _success   = null;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // ── Price (pre-filled, editable) ───────────────────
                      _Label('Price per Share (TZS)'),
                      const SizedBox(height: 8),
                      _PriceField(
                        initialValue: _price,
                        accent: _accent,
                        onChanged: (v) => setState(() => _price = v),
                      ),
                      const SizedBox(height: 16),

                      // ── Shares stepper ─────────────────────────────────
                      _Label('Number of Shares'),
                      const SizedBox(height: 8),
                      _SharesStepper(
                        value: _shares,
                        accent: _accent,
                        onChanged: (v) => setState(() => _shares = v),
                      ),
                      const SizedBox(height: 20),

                      // ── Order summary card ─────────────────────────────
                      _OrderSummary(
                        symbol:    widget.symbol,
                        tradeType: _tradeType,
                        shares:    _shares,
                        price:     _price,
                        total:     _total,
                        accent:    _accent,
                      ),
                      const SizedBox(height: 14),

                      // ── Success / Error banners ────────────────────────
                      if (_success != null) ...[
                        _Banner(message: _success!, color: _C.green,
                            icon: Icons.check_circle_rounded),
                        const SizedBox(height: 12),
                      ],
                      if (_error != null) ...[
                        _Banner(message: _error!, color: _C.red,
                            icon: Icons.error_rounded),
                        const SizedBox(height: 12),
                      ],

                      // ── Confirm button ─────────────────────────────────
                      _ConfirmButton(
                        isBuy:   _isBuy,
                        symbol:  widget.symbol,
                        accent:  _accent,
                        loading: _loading,
                        onTap:   _loading ? null : _submit,
                      ),
                      const SizedBox(height: 14),

                      // ── Disclaimer ─────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _C.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _C.border),
                        ),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                          Icon(Icons.info_outline_rounded, size: 13, color: _C.txtHint),
                          SizedBox(width: 8),
                          Expanded(child: Text(
                            'Orders are subject to market conditions and DSE regulations. '
                                'Execution price may differ. UAT environment — no real trades placed.',
                            style: TextStyle(color: _C.txtHint, fontSize: 10, height: 1.5),
                          )),
                        ]),
                      ),
                    ],
                  ),
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
// TRADE DROPDOWN
// ─────────────────────────────────────────────────────────────────────────────
class _TradeDropdown extends StatelessWidget {
  final TradeType value;
  final ValueChanged<TradeType> onChanged;

  const _TradeDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isBuy  = value == TradeType.buy;
    final accent = isBuy ? _C.green : _C.red;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(0.45), width: 1.5),
        boxShadow: [
          BoxShadow(color: accent.withOpacity(0.07),
              blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TradeType>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: accent),
          dropdownColor: _C.card,
          borderRadius: BorderRadius.circular(14),
          onChanged: (v) { if (v != null) onChanged(v); },
          items: [
            _item(TradeType.buy,  '↑  Buy Shares',  _C.green),
            _item(TradeType.sell, '↓  Sell Shares', _C.red),
          ],
          selectedItemBuilder: (_) => [
            _selected(TradeType.buy,  '↑  Buy Shares',  _C.green,  value),
            _selected(TradeType.sell, '↓  Sell Shares', _C.red,    value),
          ],
        ),
      ),
    );
  }

  DropdownMenuItem<TradeType> _item(TradeType t, String label, Color col) =>
      DropdownMenuItem(
        value: t,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: col.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: col.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                t == TradeType.buy
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: col, size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t == TradeType.buy ? 'Buy Shares' : 'Sell Shares',
                  style: TextStyle(color: col, fontSize: 14,
                      fontWeight: FontWeight.w800)),
              Text(
                t == TradeType.buy
                    ? 'Purchase securities from the market'
                    : 'Offer your securities for sale',
                style: const TextStyle(color: _C.txtHint, fontSize: 10),
              ),
            ]),
          ]),
        ),
      );

  Widget _selected(TradeType t, String label, Color col, TradeType current) {
    final sel = t == current;
    return sel
        ? Row(children: [
      Icon(
        t == TradeType.buy
            ? Icons.trending_up_rounded
            : Icons.trending_down_rounded,
        color: col, size: 18,
      ),
      const SizedBox(width: 8),
      Text(
        t == TradeType.buy ? 'Buy Shares' : 'Sell Shares',
        style: TextStyle(
            color: col, fontSize: 15, fontWeight: FontWeight.w800),
      ),
    ])
        : const SizedBox.shrink();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRICE FIELD  (pre-filled, editable inline)
// ─────────────────────────────────────────────────────────────────────────────
class _PriceField extends StatefulWidget {
  final double initialValue;
  final Color  accent;
  final ValueChanged<double> onChanged;

  const _PriceField({
    required this.initialValue,
    required this.accent,
    required this.onChanged,
  });

  @override
  State<_PriceField> createState() => _PriceFieldState();
}

class _PriceFieldState extends State<_PriceField> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue.toStringAsFixed(2));
  }

  @override
  void didUpdateWidget(_PriceField old) {
    super.didUpdateWidget(old);
    // Re-sync only when accent changes (trade type switch), not every keystroke
    if (old.accent != widget.accent) {
      _ctrl.text = widget.initialValue.toStringAsFixed(2);
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _C.card,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _C.border),
    ),
    child: Row(children: [
      // Decrement
      _PriceBtn(
        icon: Icons.remove_rounded, color: widget.accent,
        onTap: () {
          final v = (double.tryParse(_ctrl.text) ?? widget.initialValue) - 10;
          final clamped = max(1.0, v);
          _ctrl.text = clamped.toStringAsFixed(2);
          widget.onChanged(clamped);
        },
      ),
      // Text field
      Expanded(
        child: TextField(
          controller: _ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: _C.txtPrim, fontSize: 18, fontWeight: FontWeight.w900),
          decoration: InputDecoration(
            hintText: '0.00',
            hintStyle: const TextStyle(color: _C.txtHint),
            border: InputBorder.none,
            prefixText: 'TZS  ',
            prefixStyle: TextStyle(
                color: widget.accent, fontSize: 11, fontWeight: FontWeight.w700),
          ),
          onChanged: (s) {
            final v = double.tryParse(s);
            if (v != null) widget.onChanged(v);
          },
        ),
      ),
      // Increment
      _PriceBtn(
        icon: Icons.add_rounded, color: widget.accent,
        onTap: () {
          final v = (double.tryParse(_ctrl.text) ?? widget.initialValue) + 10;
          _ctrl.text = v.toStringAsFixed(2);
          widget.onChanged(v);
        },
      ),
    ]),
  );
}

class _PriceBtn extends StatelessWidget {
  final IconData icon; final Color color; final VoidCallback onTap;
  const _PriceBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () { HapticFeedback.selectionClick(); onTap(); },
    child: Container(
      width: 46, height: 52,
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: color, size: 18),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARES STEPPER
// ─────────────────────────────────────────────────────────────────────────────
class _SharesStepper extends StatelessWidget {
  final int value;
  final Color accent;
  final ValueChanged<int> onChanged;

  const _SharesStepper({
    required this.value, required this.accent, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    decoration: BoxDecoration(
      color: _C.card,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _C.border),
    ),
    child: Row(children: [
      _Btn(label: '−100', accent: accent, onTap: () => onChanged(max(100, value - 100))),
      const SizedBox(width: 6),
      _Btn(label: '−1',   accent: accent, onTap: () => onChanged(max(1,   value - 1))),
      const Spacer(),
      Column(children: [
        Text('$value',
            style: TextStyle(color: accent, fontSize: 26,
                fontWeight: FontWeight.w900, letterSpacing: -1)),
        const Text('shares',
            style: TextStyle(color: _C.txtHint, fontSize: 10)),
      ]),
      const Spacer(),
      _Btn(label: '+1',   accent: accent, onTap: () => onChanged(value + 1)),
      const SizedBox(width: 6),
      _Btn(label: '+100', accent: accent, onTap: () => onChanged(value + 100)),
    ]),
  );
}

class _Btn extends StatelessWidget {
  final String label; final Color accent; final VoidCallback onTap;
  const _Btn({required this.label, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () { HapticFeedback.selectionClick(); onTap(); },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withOpacity(0.22)),
      ),
      child: Text(label,
          style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w800)),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ORDER SUMMARY CARD
// ─────────────────────────────────────────────────────────────────────────────
class _OrderSummary extends StatelessWidget {
  final String    symbol;
  final TradeType tradeType;
  final int       shares;
  final double    price;
  final double    total;
  final Color     accent;

  const _OrderSummary({
    required this.symbol, required this.tradeType, required this.shares,
    required this.price, required this.total, required this.accent,
  });

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 220),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: accent.withOpacity(0.06),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: accent.withOpacity(0.22)),
    ),
    child: Column(children: [
      _SummaryRow(label: 'Order Type',    value: tradeType == TradeType.buy ? 'Buy' : 'Sell', valueColor: accent),
      const SizedBox(height: 8),
      _SummaryRow(label: 'Security',      value: symbol),
      const SizedBox(height: 8),
      _SummaryRow(label: 'Shares',        value: '$shares'),
      const SizedBox(height: 8),
      _SummaryRow(label: 'Price/Share',   value: 'TZS ${price.toStringAsFixed(2)}'),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Divider(color: accent.withOpacity(0.2), thickness: 1),
      ),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Estimated Total',
            style: TextStyle(color: _C.txtSec, fontSize: 12, fontWeight: FontWeight.w700)),
        Text(_fmtMoney(total),
            style: TextStyle(color: accent, fontSize: 19,
                fontWeight: FontWeight.w900, letterSpacing: -0.5)),
      ]),
    ]),
  );
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _SummaryRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(color: _C.txtSec, fontSize: 12)),
      Text(value,
          style: TextStyle(
              color: valueColor ?? _C.txtPrim, fontSize: 12,
              fontWeight: FontWeight.w800)),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// CONFIRM BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _ConfirmButton extends StatelessWidget {
  final bool      isBuy;
  final String    symbol;
  final Color     accent;
  final bool      loading;
  final VoidCallback? onTap;

  const _ConfirmButton({
    required this.isBuy, required this.symbol,
    required this.accent, required this.loading, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: loading
              ? [accent.withOpacity(0.35), accent.withOpacity(0.25)]
              : [accent, accent.withOpacity(0.72)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: loading ? [] : [
          BoxShadow(color: accent.withOpacity(0.38), blurRadius: 18, offset: const Offset(0, 6)),
        ],
      ),
      child: Center(
        child: loading
            ? const SizedBox(width: 22, height: 22,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(isBuy ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            isBuy ? 'Confirm Buy — $symbol' : 'Confirm Sell — $symbol',
            style: const TextStyle(color: Colors.white, fontSize: 15,
                fontWeight: FontWeight.w900, letterSpacing: 0.2),
          ),
        ]),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS BANNER
// ─────────────────────────────────────────────────────────────────────────────
class _Banner extends StatelessWidget {
  final String message; final Color color; final IconData icon;
  const _Banner({required this.message, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 17),
      const SizedBox(width: 10),
      Expanded(child: Text(message,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600))),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SMALL WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(color: _C.txtSec, fontSize: 11,
          fontWeight: FontWeight.w700, letterSpacing: 0.3));
}

class _MiniStat extends StatelessWidget {
  final String label; final String value; final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: _C.card.withOpacity(0.75),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text('$label ', style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800)),
      Text(value, style: const TextStyle(color: _C.txtPrim, fontSize: 9, fontWeight: FontWeight.w700)),
    ]),
  );
}

class _DepthTile extends StatelessWidget {
  final String label; final String price; final String qty; final Color color;
  const _DepthTile({required this.label, required this.price, required this.qty, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    decoration: BoxDecoration(
      color: color.withOpacity(0.07),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.20)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: _C.txtSec, fontSize: 9, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(price, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
          overflow: TextOverflow.ellipsis),
      Text(qty, style: const TextStyle(color: _C.txtHint, fontSize: 9)),
    ]),
  );
}