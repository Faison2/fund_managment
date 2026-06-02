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
// SECURITY MODEL
// ─────────────────────────────────────────────────────────────────────────────
class _Security {
  final String name;
  final String ref;
  final double marketPrice;

  const _Security({
    required this.name,
    required this.ref,
    required this.marketPrice,
  });

  factory _Security.fromJson(Map<String, dynamic> j) => _Security(
    name:        (j['securityName'] as String).trim(),
    ref:         (j['securityRef']  as String).trim(),
    marketPrice: (j['marketPrice']  as num).toDouble(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// MARKET WATCH API
// ─────────────────────────────────────────────────────────────────────────────
class _MarketWatchApi {
  static const _url  = 'https://portaluat.tsl.co.tz/DSEAPI/Home/GetMarketWatch';
  static const _nida = '19931109111010000522';

  static Future<List<_Security>> fetch() async {
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
      request.write(jsonEncode({'nidaNumber': _nida, 'signature': ''}));

      final response = await request.close();
      final body     = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');

      final json = jsonDecode(body) as Map<String, dynamic>;
      if ((json['code'] as int) != 9000) {
        throw Exception('API error: ${json['message']}');
      }

      final data = (json['data'] as List<dynamic>).cast<Map<String, dynamic>>();
      return data.map(_Security.fromJson).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    } finally {
      client.close();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SELL API
// ─────────────────────────────────────────────────────────────────────────────
class _SellApi {
  static const _url  = 'https://portalprod.tsl.co.tz/DSEAPI//Home/SellShares';
  static const _nida = '19931109111010000522';

  static Future<Map<String, dynamic>> sellShares({
    required String securityReference,
    required double price,
    required int    shares,
  }) async {
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

      request.write(jsonEncode({
        'nidaNumber':        _nida,
        'price':             price,
        'securityReference': securityReference, // ← sends securityRef UUID
        'shares':            shares,
        'signature':         '',
      }));

      final response = await request.close();
      final body     = await response.transform(utf8.decoder).join();
      if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');
      return jsonDecode(body) as Map<String, dynamic>;
    } finally {
      client.close();
    }
  }
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

// ─────────────────────────────────────────────────────────────────────────────
// SELL SHARES PAGE
// ─────────────────────────────────────────────────────────────────────────────
class SellSharesPage extends StatefulWidget {
  const SellSharesPage({Key? key}) : super(key: key);

  @override
  State<SellSharesPage> createState() => _SellSharesPageState();
}

class _SellSharesPageState extends State<SellSharesPage>
    with SingleTickerProviderStateMixin {

  // ── Market watch state ────────────────────────────────────────────────────
  List<_Security> _securities    = [];
  bool            _loadingMarket = true;
  String?         _marketError;

  // ── Selected security ─────────────────────────────────────────────────────
  _Security? _selected;

  // ── Price controller (auto-filled from market price) ──────────────────────
  late TextEditingController _priceCtrl;

  // ── Shares ────────────────────────────────────────────────────────────────
  int _shares = 100;

  // ── Submit state ──────────────────────────────────────────────────────────
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
    _priceCtrl = TextEditingController();

    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    _fade  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    _loadSecurities();
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Fetch securities from market watch ────────────────────────────────────
  Future<void> _loadSecurities() async {
    setState(() { _loadingMarket = true; _marketError = null; });
    try {
      final list = await _MarketWatchApi.fetch();
      setState(() { _securities = list; _loadingMarket = false; });
    } catch (e) {
      setState(() { _loadingMarket = false; _marketError = e.toString(); });
    }
  }

  // ── When user picks a security ────────────────────────────────────────────
  void _onSecuritySelected(_Security s) {
    setState(() {
      _selected       = s;
      _priceCtrl.text = s.marketPrice.toStringAsFixed(2);
      _error   = null;
      _success = null;
    });
  }

  // ── Computed total ────────────────────────────────────────────────────────
  double get _total {
    final p = double.tryParse(_priceCtrl.text) ?? 0;
    return p * _shares;
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (_selected == null) {
      setState(() => _error = 'Please select a security.');
      return;
    }
    final price = double.tryParse(_priceCtrl.text.trim());
    if (price == null || price <= 0) {
      setState(() => _error = 'Please enter a valid price.');
      return;
    }
    if (_shares <= 0) {
      setState(() => _error = 'Shares must be greater than zero.');
      return;
    }

    HapticFeedback.heavyImpact();
    setState(() { _loading = true; _error = null; _success = null; });

    try {
      final result = await _SellApi.sellShares(
        securityReference: _selected!.ref, // ← UUID, not name
        price:  price,
        shares: _shares,
      );

      final code    = result['code'] as int?;
      final message = result['message'] as String? ?? 'Order placed.';

      setState(() {
        _loading = false;
        if (code == 9000) {
          _success = message;
        } else {
          _error = message;
        }
      });
      if (code == 9000) HapticFeedback.mediumImpact();
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
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

              // ── App Bar ──────────────────────────────────────────────────
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
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: _C.red.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _C.red.withOpacity(0.35)),
                    ),
                    child: const Icon(Icons.trending_down_rounded,
                        color: _C.red, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                    Text('Sell Shares',
                        style: TextStyle(color: _C.txtPrim, fontSize: 17,
                            fontWeight: FontWeight.w900, letterSpacing: -0.3)),
                    Text('DSE — Dar es Salaam Stock Exchange',
                        style: TextStyle(color: _C.txtSec, fontSize: 9)),
                  ]),
                ]),
                actions: [
                  // Refresh securities button
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _C.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _C.border),
                      ),
                      child: const Icon(Icons.refresh_rounded, size: 14, color: _C.blue),
                    ),
                    onPressed: _loadingMarket ? null : _loadSecurities,
                  ),
                ],
              ),

              // ── Body ──────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Hero banner ────────────────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _C.red.withOpacity(0.15),
                              _C.red.withOpacity(0.06),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _C.red.withOpacity(0.22)),
                        ),
                        child: Row(children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(
                                _selected != null ? _selected!.name : 'SELL ORDER',
                                style: const TextStyle(
                                    color: _C.red, fontSize: 22,
                                    fontWeight: FontWeight.w900, letterSpacing: -0.8),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _priceCtrl.text.isNotEmpty
                                    ? 'At TZS ${_priceCtrl.text} per share'
                                    : 'Select a security below',
                                style: const TextStyle(color: _C.txtSec, fontSize: 12),
                              ),
                            ]),
                          ),
                          Container(
                            width: 56, height: 56,
                            decoration: BoxDecoration(
                              color: _C.red.withOpacity(0.12),
                              shape: BoxShape.circle,
                              border: Border.all(color: _C.red.withOpacity(0.28)),
                            ),
                            child: const Icon(Icons.arrow_downward_rounded,
                                color: _C.red, size: 26),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 24),

                      // ── Security dropdown ──────────────────────────────
                      const _SectionLabel(label: 'Security'),
                      const SizedBox(height: 8),
                      _SecurityDropdown(
                        securities: _securities,
                        selected:   _selected,
                        loading:    _loadingMarket,
                        error:      _marketError,
                        color:      _C.red,
                        onChanged:  _onSecuritySelected,
                        onRetry:    _loadSecurities,
                      ),
                      const SizedBox(height: 16),

                      // ── Price (auto-filled, still editable) ────────────
                      const _SectionLabel(label: 'Price per Share (TZS)'),
                      const SizedBox(height: 8),
                      _PriceInput(
                        controller: _priceCtrl,
                        color:      _C.red,
                        onChanged:  (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),

                      // ── Shares stepper ─────────────────────────────────
                      const _SectionLabel(label: 'Number of Shares'),
                      const SizedBox(height: 8),
                      _SharesStepper(
                        value:     _shares,
                        color:     _C.red,
                        onChanged: (v) => setState(() => _shares = v),
                      ),
                      const SizedBox(height: 24),

                      // ── Total card ─────────────────────────────────────
                      _TotalCard(
                        total:  _total,
                        shares: _shares,
                        color:  _C.red,
                        label:  'Estimated Sell Total',
                      ),
                      const SizedBox(height: 16),

                      // ── Banners ────────────────────────────────────────
                      if (_success != null) ...[
                        _StatusBanner(message: _success!, color: _C.green,
                            icon: Icons.check_circle_rounded),
                        const SizedBox(height: 16),
                      ],
                      if (_error != null) ...[
                        _StatusBanner(message: _error!, color: _C.red,
                            icon: Icons.error_rounded),
                        const SizedBox(height: 16),
                      ],

                      // ── Submit ─────────────────────────────────────────
                      _SubmitButton(
                        label:   _loading ? 'Placing Order…' : 'Confirm Sell Order',
                        color:   _C.red,
                        loading: _loading,
                        icon:    Icons.trending_down_rounded,
                        onTap:   _loading ? null : _submit,
                      ),
                      const SizedBox(height: 16),

                      // ── Disclaimer ─────────────────────────────────────
                      const _Disclaimer(),
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
// SECURITY DROPDOWN WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class _SecurityDropdown extends StatelessWidget {
  final List<_Security>         securities;
  final _Security?              selected;
  final bool                    loading;
  final String?                 error;
  final Color                   color;
  final ValueChanged<_Security> onChanged;
  final VoidCallback            onRetry;

  const _SecurityDropdown({
    required this.securities,
    required this.selected,
    required this.loading,
    required this.error,
    required this.color,
    required this.onChanged,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    // ── Loading state ─────────────────────────────────────────────────────
    if (loading) {
      return Container(
        height: 54,
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border),
        ),
        child: const Center(
          child: SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(color: _C.blue, strokeWidth: 2),
          ),
        ),
      );
    }

    // ── Error state ───────────────────────────────────────────────────────
    if (error != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _C.red.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.red.withOpacity(0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.wifi_off_rounded, color: _C.red, size: 16),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Could not load securities.',
                style: TextStyle(color: _C.red, fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _C.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _C.red.withOpacity(0.3)),
              ),
              child: const Text('Retry',
                  style: TextStyle(color: _C.red, fontSize: 11,
                      fontWeight: FontWeight.w800)),
            ),
          ),
        ]),
      );
    }

    // ── Dropdown ──────────────────────────────────────────────────────────
    return Container(
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: selected != null ? color.withOpacity(0.45) : _C.border,
            width: selected != null ? 1.5 : 1),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.05),
              blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_Security>(
          value: selected,
          isExpanded: true,
          hint: const Text('Select a security…',
              style: TextStyle(color: _C.txtHint, fontSize: 14)),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: color),
          dropdownColor: _C.card,
          borderRadius: BorderRadius.circular(14),
          onChanged: (s) {
            if (s != null) {
              HapticFeedback.selectionClick();
              onChanged(s);
            }
          },
          items: securities.map((s) => DropdownMenuItem<_Security>(
            value: s,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                // Coloured avatar
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: color.withOpacity(0.25)),
                  ),
                  child: Center(
                    child: Text(
                      s.name.substring(0, min(2, s.name.length)),
                      style: TextStyle(color: color, fontSize: 11,
                          fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(s.name,
                          style: const TextStyle(color: _C.txtPrim,
                              fontSize: 13, fontWeight: FontWeight.w800),
                          overflow: TextOverflow.ellipsis),
                      Text('TZS ${s.marketPrice.toStringAsFixed(2)}',
                          style: TextStyle(color: color, fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ]),
            ),
          )).toList(),
          // What shows in the collapsed field
          selectedItemBuilder: (_) => securities.map((s) => Align(
            alignment: Alignment.centerLeft,
            child: Row(children: [
              Icon(Icons.business_rounded, color: color, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(s.name,
                    style: TextStyle(color: color, fontSize: 14,
                        fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis),
              ),
              Text('TZS ${s.marketPrice.toStringAsFixed(2)}',
                  style: TextStyle(color: color.withOpacity(0.7),
                      fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
          )).toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRICE INPUT  (editable, auto-filled)
// ─────────────────────────────────────────────────────────────────────────────
class _PriceInput extends StatelessWidget {
  final TextEditingController controller;
  final Color color;
  final ValueChanged<String> onChanged;

  const _PriceInput({
    required this.controller,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _C.card,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _C.border),
    ),
    child: TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      style: const TextStyle(color: _C.txtPrim, fontSize: 15,
          fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        hintText: 'e.g. 1000.00',
        hintStyle: const TextStyle(color: _C.txtHint, fontSize: 14),
        prefixIcon: Icon(Icons.attach_money_rounded, color: color, size: 18),
        border: InputBorder.none,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixText: 'TZS',
        suffixStyle: TextStyle(color: color.withOpacity(0.6), fontSize: 12,
            fontWeight: FontWeight.w700),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARES STEPPER
// ─────────────────────────────────────────────────────────────────────────────
class _SharesStepper extends StatelessWidget {
  final int value;
  final Color color;
  final ValueChanged<int> onChanged;

  const _SharesStepper({
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: _C.card,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _C.border),
    ),
    child: Row(children: [
      _Btn(label: '−100', color: color, onTap: () => onChanged(max(100, value - 100))),
      const SizedBox(width: 6),
      _Btn(label: '−1',   color: color, onTap: () => onChanged(max(1, value - 1))),
      const Spacer(),
      Column(children: [
        Text('$value',
            style: TextStyle(color: color, fontSize: 26,
                fontWeight: FontWeight.w900, letterSpacing: -1)),
        const Text('shares', style: TextStyle(color: _C.txtHint, fontSize: 10)),
      ]),
      const Spacer(),
      _Btn(label: '+1',   color: color, onTap: () => onChanged(value + 1)),
      const SizedBox(width: 6),
      _Btn(label: '+100', color: color, onTap: () => onChanged(value + 100)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(label,
      style: const TextStyle(color: _C.txtSec, fontSize: 11,
          fontWeight: FontWeight.w700, letterSpacing: 0.4));
}

class _Btn extends StatelessWidget {
  final String label; final Color color; final VoidCallback onTap;
  const _Btn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () { HapticFeedback.selectionClick(); onTap(); },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 11,
              fontWeight: FontWeight.w800)),
    ),
  );
}

class _TotalCard extends StatelessWidget {
  final double total; final int shares; final Color color; final String label;
  const _TotalCard({required this.total, required this.shares,
    required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: color.withOpacity(0.06),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: _C.txtSec, fontSize: 11,
            fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('$shares shares',
            style: const TextStyle(color: _C.txtHint, fontSize: 10)),
      ]),
      Text(_fmtMoney(total),
          style: TextStyle(color: color, fontSize: 20,
              fontWeight: FontWeight.w900, letterSpacing: -0.5)),
    ]),
  );
}

class _StatusBanner extends StatelessWidget {
  final String message; final Color color; final IconData icon;
  const _StatusBanner({required this.message, required this.color,
    required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 10),
      Expanded(child: Text(message,
          style: TextStyle(color: color, fontSize: 12,
              fontWeight: FontWeight.w600))),
    ]),
  );
}

class _SubmitButton extends StatelessWidget {
  final String label; final Color color; final bool loading;
  final IconData icon; final VoidCallback? onTap;
  const _SubmitButton({required this.label, required this.color,
    required this.loading, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: loading
              ? [color.withOpacity(0.4), color.withOpacity(0.3)]
              : [color, color.withOpacity(0.75)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: loading ? [] : [
          BoxShadow(color: color.withOpacity(0.35),
              blurRadius: 18, offset: const Offset(0, 6)),
        ],
      ),
      child: Center(
        child: loading
            ? const SizedBox(width: 22, height: 22,
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2.5))
            : Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white,
              fontSize: 15, fontWeight: FontWeight.w900,
              letterSpacing: 0.3)),
        ]),
      ),
    ),
  );
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _C.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _C.border),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: const [
      Icon(Icons.info_outline_rounded, size: 14, color: _C.txtHint),
      SizedBox(width: 8),
      Expanded(child: Text(
        'Orders are subject to market conditions and DSE regulations. '
            'Prices may differ from execution price. '
            'This is a UAT environment — no real trades are placed.',
        style: TextStyle(color: _C.txtHint, fontSize: 10, height: 1.5),
      )),
    ]),
  );
}