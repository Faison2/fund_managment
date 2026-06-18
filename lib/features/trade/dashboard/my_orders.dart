import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TSL BRAND PALETTE
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  static const Color blue      = Color(0xFF329AD6);
  static const Color teal      = Color(0xFF00A79D);
  static const Color grey      = Color(0xFF939598);
  static const Color white     = Color(0xFFFFFFFF);
  static const Color black     = Color(0xFF231F20);
  static const Color lightGrey = Color(0xFFF5F6F7);
  static const Color errorRed  = Color(0xFFD32F2F);

  static const Color bg        = Color(0xFFF0F8FA);
  static const Color surface   = Color(0xFFFFFFFF);
  static const Color border    = Color(0xFFB8DDE8);

  static const Color green     = Color(0xFF34C759);
  static const Color greenLt   = Color(0xFFEBFBF2);
  static const Color red       = Color(0xFFFF6B8A);
  static const Color redLt     = Color(0xFFFFEEF2);
  static const Color gold      = Color(0xFFF5A623);
  static const Color goldLt    = Color(0xFFFFF8EC);

  static const Color tealLt    = Color(0xFFE0F5F4);
  static const Color blueLt    = Color(0xFFE6F3FB);

  static const Color txtPrim   = Color(0xFF0D2B2A);
  static const Color txtSec    = Color(0xFF4A8080);
  static const Color txtHint   = Color(0xFF93BFC0);

  static const List<Color> heroGrad = [Color(0xFF00A79D), Color(0xFF1A7BAF), Color(0xFF329AD6)];
  static const List<Color> fabGrad  = [Color(0xFF00A79D), Color(0xFF1A7BAF)];
  static const List<Color> buyGrad  = [Color(0xFF34C759), Color(0xFF1E8E3E)];
  static const List<Color> sellGrad = [Color(0xFFFF8AA8), Color(0xFFFF6B8A)];
}

// ─────────────────────────────────────────────────────────────────────────────
// ORDER MODEL
// ─────────────────────────────────────────────────────────────────────────────
class Order {
  final String  orderDate;
  final String  orderReference;
  final String  orderStatus;
  final double  price;
  final String  securityId;
  final String  securityName;
  final String? controlNumber;
  final int     shares;
  final String  type;

  const Order({
    required this.orderDate,
    required this.orderReference,
    required this.orderStatus,
    required this.price,
    required this.securityId,
    required this.securityName,
    required this.controlNumber,
    required this.shares,
    required this.type,
  });

  factory Order.fromJson(Map<String, dynamic> j, {required String type}) => Order(
    orderDate:      (j['orderDate']      as String?) ?? '',
    orderReference: (j['orderReference'] as String?) ?? '',
    orderStatus:    (j['orderStatus']    as String?) ?? '',
    price:          (j['price']          as num).toDouble(),
    securityId:     (j['securityId']     as String?) ?? '',
    securityName:   (j['securityName']   as String?) ?? '',
    controlNumber:  j['controlNumber']   as String?,
    shares:         (j['shares']         as num).toInt(),
    type:           type,
  );

  String get displayDate {
    try {
      final dt = DateTime.parse(orderDate);
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month]} ${dt.year}, $h:$m';
    } catch (_) {
      return orderDate;
    }
  }

  double get total => price * shares;
}

// ─────────────────────────────────────────────────────────────────────────────
// API SERVICE
// ─────────────────────────────────────────────────────────────────────────────
class _OrdersApi {
  static const _buyUrl  = 'https://portaluat.tsl.co.tz/DSEAPI/Home/GetBuyOrders';
  static const _sellUrl = 'https://portaluat.tsl.co.tz/DSEAPI/Home/GetSellOrders';

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Future<String> _getNida() async {
    final prefs = await SharedPreferences.getInstance();
    final nida  = prefs.getString('nida_number') ?? '';
    if (nida.isEmpty) throw Exception('NIDA number not set. Please log in again.');
    return nida;
  }

  static Future<List<Order>> _fetch({
    required String   url,
    required String   type,
    required String   nida,
    required DateTime startDate,
    required DateTime endDate,
    String orderStatus = '',
  }) async {
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
        'nidaNumber':  nida,
        'startDate':   _fmt(startDate),
        'endDate':     _fmt(endDate),
        'orderStatus': orderStatus,
        'signature':   '',
      }));

      final response = await request.close();
      final body     = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');

      final json = jsonDecode(body) as Map<String, dynamic>;
      if ((json['code'] as int) != 9000) throw Exception('API: ${json['message']}');

      final data = (json['data'] as List<dynamic>).cast<Map<String, dynamic>>();
      return data.map((j) => Order.fromJson(j, type: type)).toList();
    } finally {
      client.close();
    }
  }

  static Future<List<Order>> fetchAll({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final nida = await _getNida();
    final results = await Future.wait([
      _fetch(url: _buyUrl,  type: 'BUY',  nida: nida, startDate: startDate, endDate: endDate),
      _fetch(url: _sellUrl, type: 'SELL', nida: nida, startDate: startDate, endDate: endDate),
    ]);
    final all = [...results[0], ...results[1]];
    all.sort((a, b) => b.orderDate.compareTo(a.orderDate));
    return all;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ORDERS PAGE
// ─────────────────────────────────────────────────────────────────────────────
class OrdersPage extends StatefulWidget {
  const OrdersPage({Key? key}) : super(key: key);

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late DateTime _startDate;
  late DateTime _endDate;

  List<Order> _orders  = [];
  bool        _loading = true;
  String?     _error;
  int         _filterIndex = 0;

  @override
  void initState() {
    super.initState();
    final now  = DateTime.now();
    _startDate = DateTime(now.year, 1, 1);
    _endDate   = DateTime(now.year, 12, 31);
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final orders = await _OrdersApi.fetchAll(
          startDate: _startDate, endDate: _endDate);
      setState(() { _orders = orders; _loading = false; });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  List<Order> get _filtered {
    switch (_filterIndex) {
      case 1: return _orders.where((o) => o.type == 'BUY').toList();
      case 2: return _orders.where((o) => o.type == 'SELL').toList();
      default: return _orders;
    }
  }

  String _fmtDisplay(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate:   DateTime(2020),
      lastDate:    DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary:   _C.teal,
            onPrimary: Colors.white,
            surface:   _C.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_startDate.isAfter(_endDate)) _endDate = _startDate;
      } else {
        _endDate = picked;
        if (_endDate.isBefore(_startDate)) _startDate = _endDate;
      }
    });
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    final filled  = _orders.where((o) => o.orderStatus == 'Full Filled').length;
    final pending = _orders.where((o) => o.orderStatus == 'Pending').length;
    final expired = _orders.where((o) => o.orderStatus == 'Expired').length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: RefreshIndicator(
          color: _C.teal,
          backgroundColor: _C.surface,
          onRefresh: _fetch,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            slivers: [

              // ── App bar ──────────────────────────────────────────────────
              SliverAppBar(
                backgroundColor: _C.bg,
                elevation: 0,
                floating: true,
                pinned: true,
                automaticallyImplyLeading: false,
                leading: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _C.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _C.border),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          size: 18, color: _C.txtPrim),
                    ),
                  ),
                ),
                title: Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: _C.fabGrad),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('TRADE',
                        style: TextStyle(
                            color: Colors.white, fontSize: 11,
                            fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  ),
                  const SizedBox(width: 10),
                  const Text('My Orders',
                      style: TextStyle(
                          color: _C.txtPrim,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                ]),
                actions: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _C.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _C.border),
                      ),
                      child: _loading
                          ? SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(
                              color: _C.teal, strokeWidth: 2))
                          : const Icon(Icons.refresh_rounded,
                          size: 14, color: _C.teal),
                    ),
                    onPressed: _loading ? null : _fetch,
                  ),
                  const SizedBox(width: 4),
                ],
              ),

              // ── Static header ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Column(children: [

                    // Date range row
                    Row(children: [
                      Expanded(child: _DatePill(
                        label: 'From',
                        value: _fmtDisplay(_startDate),
                        icon:  Icons.calendar_today_rounded,
                        onTap: () => _pickDate(isStart: true),
                      )),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Container(
                          width: 24, height: 2,
                          decoration: BoxDecoration(
                            color: _C.txtHint,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                      Expanded(child: _DatePill(
                        label: 'To',
                        value: _fmtDisplay(_endDate),
                        icon:  Icons.calendar_month_rounded,
                        onTap: () => _pickDate(isStart: false),
                      )),
                    ]),
                    const SizedBox(height: 14),

                    // Summary card
                    if (_loading)
                      const _SummaryShimmer()
                    else if (_error == null)
                      _SummaryCard(
                        total:   _orders.length,
                        filled:  filled,
                        pending: pending,
                        expired: expired,
                      ),

                    const SizedBox(height: 14),

                    // Filter chips
                    _FilterChips(
                      selected:  _filterIndex,
                      onChanged: (i) {
                        HapticFeedback.selectionClick();
                        setState(() => _filterIndex = i);
                      },
                    ),
                    const SizedBox(height: 14),
                  ]),
                ),
              ),

              // ── Body ─────────────────────────────────────────────────────
              if (_loading)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                            (_, __) => const _SkeletonCard(),
                        childCount: 5),
                  ),
                )
              else if (_error != null)
                SliverToBoxAdapter(
                    child: _ErrorState(message: _error!, onRetry: _fetch))
              else if (_filtered.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 64, horizontal: 32),
                      child: Column(children: [
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                            color: _C.tealLt,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.receipt_long_rounded,
                              color: _C.teal, size: 28),
                        ),
                        const SizedBox(height: 16),
                        const Text('No orders found',
                            style: TextStyle(
                                color: _C.txtPrim,
                                fontSize: 16,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        const Text('Try adjusting the date range or filter.',
                            style: TextStyle(color: _C.txtSec, fontSize: 13),
                            textAlign: TextAlign.center),
                      ]),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                              (_, i) => OrderCard(order: _filtered[i]),
                          childCount: _filtered.length),
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
// DATE PILL
// ─────────────────────────────────────────────────────────────────────────────
class _DatePill extends StatelessWidget {
  final String    label;
  final String    value;
  final IconData  icon;
  final VoidCallback onTap;

  const _DatePill({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () { HapticFeedback.selectionClick(); onTap(); },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border, width: 1.5),
        boxShadow: [
          BoxShadow(color: _C.teal.withOpacity(0.06),
              blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: _C.tealLt,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.calendar_today_rounded,
              color: _C.teal, size: 14),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    color: _C.txtHint, fontSize: 9,
                    fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    color: _C.txtPrim, fontSize: 11,
                    fontWeight: FontWeight.w800),
                overflow: TextOverflow.ellipsis),
          ]),
        ),
        const Icon(Icons.expand_more_rounded, color: _C.txtHint, size: 16),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SUMMARY CARD
// ─────────────────────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final int total, filled, pending, expired;
  const _SummaryCard({
    required this.total,
    required this.filled,
    required this.pending,
    required this.expired,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
          colors: _C.heroGrad),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(color: _C.teal.withOpacity(0.28),
            blurRadius: 24, offset: const Offset(0, 8)),
      ],
    ),
    child: Row(children: [
      _s('$total',   'Total',       Colors.white),
      _d(),
      _s('$filled',  'Full Filled', const Color(0xFF4ADE80)),
      _d(),
      _s('$pending', 'Pending',     _C.gold),
      _d(),
      _s('$expired', 'Expired',     _C.red),
    ]),
  );

  Widget _s(String v, String l, Color c) => Expanded(
    child: Column(children: [
      Text(v, style: TextStyle(
          color: c, fontSize: 20, fontWeight: FontWeight.w900)),
      const SizedBox(height: 2),
      Text(l, style: const TextStyle(color: Colors.white60, fontSize: 9),
          textAlign: TextAlign.center),
    ]),
  );

  Widget _d() => Container(height: 36, width: 1, color: Colors.white24);
}

// ─────────────────────────────────────────────────────────────────────────────
// SUMMARY SHIMMER
// ─────────────────────────────────────────────────────────────────────────────
class _SummaryShimmer extends StatefulWidget {
  const _SummaryShimmer();
  @override
  State<_SummaryShimmer> createState() => _SummaryShimmerState();
}

class _SummaryShimmerState extends State<_SummaryShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => Container(
      height: 72,
      decoration: BoxDecoration(
        color: Color.lerp(_C.teal.withOpacity(0.18),
            _C.teal.withOpacity(0.32), _anim.value),
        borderRadius: BorderRadius.circular(20),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTER CHIPS
// ─────────────────────────────────────────────────────────────────────────────
class _FilterChips extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  const _FilterChips({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const labels = ['All', 'Buy', 'Sell'];
    const colors = [_C.teal, _C.blue, _C.red];
    return Row(
      children: List.generate(labels.length, (i) {
        final sel = selected == i;
        return GestureDetector(
          onTap: () => onChanged(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(
                horizontal: 22, vertical: 10),
            decoration: BoxDecoration(
              color: sel ? colors[i] : _C.surface,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                  color: sel ? colors[i] : _C.border, width: 1.5),
              boxShadow: sel
                  ? [BoxShadow(color: colors[i].withOpacity(0.30),
                  blurRadius: 10, offset: const Offset(0, 4))]
                  : [],
            ),
            child: Text(labels[i],
                style: TextStyle(
                    color: sel ? Colors.white : _C.txtSec,
                    fontSize: 13,
                    fontWeight:
                    sel ? FontWeight.w700 : FontWeight.w500)),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ERROR STATE
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
    child: Column(children: [
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          color: _C.red.withOpacity(0.10),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.wifi_off_rounded, color: _C.red, size: 28),
      ),
      const SizedBox(height: 16),
      const Text('Unable to load orders',
          style: TextStyle(
              color: _C.txtPrim,
              fontSize: 16,
              fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Text(message,
          style: const TextStyle(color: _C.txtSec, fontSize: 12),
          textAlign: TextAlign.center),
      const SizedBox(height: 24),
      GestureDetector(
        onTap: onRetry,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          decoration: BoxDecoration(
            color: _C.teal.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _C.teal.withOpacity(0.35)),
          ),
          child: const Text('Retry',
              style: TextStyle(
                  color: _C.teal,
                  fontSize: 13,
                  fontWeight: FontWeight.w800)),
        ),
      ),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SKELETON CARD
// ─────────────────────────────────────────────────────────────────────────────
class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();
  @override State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) {
      final s = Color.lerp(_C.border, _C.tealLt, _anim.value)!;
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        height: 96,
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _C.border),
        ),
        child: Row(children: [
          Container(width: 40, height: 40,
              decoration: BoxDecoration(
                  color: s, borderRadius: BorderRadius.circular(10))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(height: 12, width: 100, color: s),
                  const SizedBox(height: 8),
                  Container(height: 10, width: 160, color: s),
                  const SizedBox(height: 6),
                  Container(height: 9,  width: 120, color: s),
                ]),
          ),
        ]),
      );
    },
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ORDER CARD
// ─────────────────────────────────────────────────────────────────────────────
class OrderCard extends StatelessWidget {
  final Order order;
  const OrderCard({required this.order, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isBuy     = order.type == 'BUY';
    final grad      = isBuy ? _C.buyGrad  : _C.sellGrad;
    final typeBg    = isBuy ? _C.greenLt  : _C.redLt;
    final typeColor = isBuy ? _C.green     : _C.red;

    Color    statusColor;
    Color    statusBg;
    IconData statusIcon;

    switch (order.orderStatus) {
      case 'Full Filled':
        statusColor = _C.green;
        statusBg    = _C.greenLt;
        statusIcon  = Icons.check_circle_rounded;
        break;
      case 'Pending':
        statusColor = _C.gold;
        statusBg    = _C.goldLt;
        statusIcon  = Icons.schedule_rounded;
        break;
      case 'Expired':
        statusColor = _C.txtHint;
        statusBg    = _C.border;
        statusIcon  = Icons.timer_off_rounded;
        break;
      default:
        statusColor = _C.txtHint;
        statusBg    = _C.border;
        statusIcon  = Icons.cancel_rounded;
    }

    final totalStr = order.total
        .toStringAsFixed(0)
        .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(color: _C.teal.withOpacity(0.06),
              blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // Coloured left bar
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: grad,
                        begin: Alignment.topCenter,
                        end:   Alignment.bottomCenter),
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // Row 1: symbol · securityId · status
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: grad),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text(order.securityName,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(order.securityId,
                                  style: const TextStyle(
                                      color: _C.txtSec,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(20)),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(statusIcon, size: 11, color: statusColor),
                                const SizedBox(width: 3),
                                Text(order.orderStatus,
                                    style: TextStyle(
                                        color: statusColor, fontSize: 10,
                                        fontWeight: FontWeight.w700)),
                              ]),
                            ),
                          ]),
                          const SizedBox(height: 10),

                          // Row 2: type chip · shares · price
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                  color: typeBg,
                                  borderRadius: BorderRadius.circular(6)),
                              child: Text(order.type,
                                  style: TextStyle(
                                      color: typeColor, fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8)),
                            ),
                            const SizedBox(width: 8),
                            Text('${order.shares} shares',
                                style: const TextStyle(
                                    color: _C.txtSec, fontSize: 12)),
                            const Spacer(),
                            Text('TZS ${order.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    color: _C.txtPrim, fontSize: 14,
                                    fontWeight: FontWeight.w800)),
                          ]),
                          const SizedBox(height: 6),

                          // Row 3: date · total
                          Row(children: [
                            const Icon(Icons.access_time_rounded,
                                size: 11, color: _C.txtHint),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(order.displayDate,
                                  style: const TextStyle(
                                      color: _C.txtHint, fontSize: 11)),
                            ),
                            Text('Total: TZS $totalStr',
                                style: const TextStyle(
                                    color: _C.txtSec, fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ]),

                          // Row 4: control number (optional)
                          if (order.controlNumber != null) ...[
                            const SizedBox(height: 6),
                            Row(children: [
                              const Icon(Icons.confirmation_number_rounded,
                                  size: 11, color: _C.txtHint),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text('Ctrl: ${order.controlNumber}',
                                    style: const TextStyle(
                                        color: _C.txtHint,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ]),
                          ],
                        ]),
                  ),
                ),
              ]),
        ),
      ),
    );
  }
}

const List<Order> kOrders = [];