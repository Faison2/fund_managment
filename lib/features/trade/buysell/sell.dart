import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// THEME TOKENS  (shared palette)
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
// SELL API
// ─────────────────────────────────────────────────────────────────────────────
class _SellApi {
  static const _url =
      'https://portaluat.tsl.co.tz/DSEAPI//Home/SellShares';
  static const _hardcodedNida = '19931225100010000001';

  static Future<Map<String, dynamic>> sellShares({
    required String securityReference,
    required double price,
    required int shares,
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

      final payload = jsonEncode({
        'nidaNumber':        _hardcodedNida,
        'price':             price,
        'securityReference': securityReference,
        'shares':            shares,
        'signature':         '',
      });
      request.write(payload);

      final response = await request.close();
      final body     = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      return json;
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
  /// Pre-fill values when navigating from Market Watch
  final String? symbol;
  final double? marketPrice;

  const SellSharesPage({Key? key, this.symbol, this.marketPrice})
      : super(key: key);

  @override
  State<SellSharesPage> createState() => _SellSharesPageState();
}

class _SellSharesPageState extends State<SellSharesPage>
    with SingleTickerProviderStateMixin {
  // ── Controllers ───────────────────────────────────────────────────────────
  late TextEditingController _symbolCtrl;
  late TextEditingController _priceCtrl;

  // ── State ─────────────────────────────────────────────────────────────────
  int    _shares   = 100;
  bool   _loading  = false;
  String? _error;
  String? _success;

  // ── Animation ─────────────────────────────────────────────────────────────
  late AnimationController _animCtrl;
  late Animation<double>   _fade;
  late Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _symbolCtrl = TextEditingController(text: widget.symbol ?? '');
    _priceCtrl  = TextEditingController(
        text: widget.marketPrice?.toStringAsFixed(2) ?? '');

    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    _fade  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _symbolCtrl.dispose();
    _priceCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Computed total ─────────────────────────────────────────────────────────
  double get _total {
    final p = double.tryParse(_priceCtrl.text) ?? 0;
    return p * _shares;
  }

  // ── Submit ─────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    final symbol = _symbolCtrl.text.trim();
    final price  = double.tryParse(_priceCtrl.text.trim());

    if (symbol.isEmpty) {
      setState(() => _error = 'Please enter a security reference.');
      return;
    }
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
        securityReference: symbol,
        price:  price,
        shares: _shares,
      );

      final code    = result['code'] as int?;
      final message = result['message'] as String? ?? 'Order placed.';

      if (code == 9000) {
        HapticFeedback.mediumImpact();
        setState(() {
          _loading = false;
          _success = message;
        });
      } else {
        setState(() {
          _loading = false;
          _error   = message;
        });
      }
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────────
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
              // ── App Bar ───────────────────────────────────────────────────
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
                title: Row(
                  children: [
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Sell Shares',
                            style: TextStyle(
                                color: _C.txtPrim, fontSize: 17,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3)),
                        Text('DSE — Dar es Salaam Stock Exchange',
                            style: TextStyle(
                                color: _C.txtSec, fontSize: 9)),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Body ──────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Hero banner ──────────────────────────────────────
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
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _symbolCtrl.text.isNotEmpty
                                        ? _symbolCtrl.text.toUpperCase()
                                        : 'SELL ORDER',
                                    style: const TextStyle(
                                        color: _C.red, fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -1),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _priceCtrl.text.isNotEmpty
                                        ? 'At TZS ${_priceCtrl.text} per share'
                                        : 'Enter price and quantity below',
                                    style: const TextStyle(
                                        color: _C.txtSec, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 56, height: 56,
                              decoration: BoxDecoration(
                                color: _C.red.withOpacity(0.12),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: _C.red.withOpacity(0.28)),
                              ),
                              child: const Icon(Icons.arrow_downward_rounded,
                                  color: _C.red, size: 26),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Security Reference ───────────────────────────────
                      _SectionLabel(label: 'Security Reference'),
                      const SizedBox(height: 8),
                      _InputBox(
                        controller: _symbolCtrl,
                        hint: 'e.g. CRDB, NMB, TBL',
                        icon: Icons.business_rounded,
                        color: _C.red,
                        keyboardType: TextInputType.text,
                        onChanged: (_) => setState(() {}),
                        textCapitalization: TextCapitalization.characters,
                      ),
                      const SizedBox(height: 16),

                      // ── Price ────────────────────────────────────────────
                      _SectionLabel(label: 'Price per Share (TZS)'),
                      const SizedBox(height: 8),
                      _InputBox(
                        controller: _priceCtrl,
                        hint: 'e.g. 1000.00',
                        icon: Icons.attach_money_rounded,
                        color: _C.red,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),

                      // ── Shares stepper ───────────────────────────────────
                      _SectionLabel(label: 'Number of Shares'),
                      const SizedBox(height: 8),
                      _SharesStepper(
                        value: _shares,
                        color: _C.red,
                        onDecrement: () =>
                            setState(() => _shares = max(100, _shares - 100)),
                        onIncrement: () =>
                            setState(() => _shares += 100),
                        onDecrementSmall: () =>
                            setState(() => _shares = max(1, _shares - 1)),
                        onIncrementSmall: () =>
                            setState(() => _shares += 1),
                      ),
                      const SizedBox(height: 24),

                      // ── Estimated total ──────────────────────────────────
                      _TotalCard(
                        total: _total,
                        shares: _shares,
                        color: _C.red,
                        label: 'Estimated Sell Total',
                      ),
                      const SizedBox(height: 16),

                      // ── Success banner ───────────────────────────────────
                      if (_success != null) ...[
                        _StatusBanner(
                          message: _success!,
                          color: _C.green,
                          icon: Icons.check_circle_rounded,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ── Error banner ─────────────────────────────────────
                      if (_error != null) ...[
                        _StatusBanner(
                          message: _error!,
                          color: _C.red,
                          icon: Icons.error_rounded,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ── Submit button ────────────────────────────────────
                      _SubmitButton(
                        label: _loading
                            ? 'Placing Order…'
                            : 'Confirm Sell Order',
                        color: _C.red,
                        loading: _loading,
                        icon: Icons.trending_down_rounded,
                        onTap: _loading ? null : _submit,
                      ),

                      const SizedBox(height: 16),

                      // ── Disclaimer ───────────────────────────────────────
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
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
        color: _C.txtSec, fontSize: 11, fontWeight: FontWeight.w700,
        letterSpacing: 0.4),
  );
}

class _InputBox extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final Color color;
  final TextInputType keyboardType;
  final ValueChanged<String> onChanged;
  final TextCapitalization textCapitalization;

  const _InputBox({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.color,
    required this.keyboardType,
    required this.onChanged,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _C.card,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _C.border),
      boxShadow: [
        BoxShadow(
            color: color.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2)),
      ],
    ),
    child: TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      onChanged: onChanged,
      style: const TextStyle(
          color: _C.txtPrim, fontSize: 15, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _C.txtHint, fontSize: 14),
        prefixIcon: Icon(icon, color: color, size: 18),
        border: InputBorder.none,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    ),
  );
}

class _SharesStepper extends StatelessWidget {
  final int value;
  final Color color;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onDecrementSmall;
  final VoidCallback onIncrementSmall;

  const _SharesStepper({
    required this.value,
    required this.color,
    required this.onDecrement,
    required this.onIncrement,
    required this.onDecrementSmall,
    required this.onIncrementSmall,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: _C.card,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _C.border),
    ),
    child: Row(
      children: [
        _Btn(label: '−100', color: color, onTap: onDecrement),
        const SizedBox(width: 6),
        _Btn(label: '−1',   color: color, onTap: onDecrementSmall),
        const Spacer(),
        Column(
          children: [
            Text('$value',
                style: TextStyle(
                    color: color, fontSize: 26,
                    fontWeight: FontWeight.w900, letterSpacing: -1)),
            const Text('shares',
                style: TextStyle(color: _C.txtHint, fontSize: 10)),
          ],
        ),
        const Spacer(),
        _Btn(label: '+1',   color: color, onTap: onIncrementSmall),
        const SizedBox(width: 6),
        _Btn(label: '+100', color: color, onTap: onIncrement),
      ],
    ),
  );
}

class _Btn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Btn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () {
      HapticFeedback.selectionClick();
      onTap();
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w800)),
    ),
  );
}

class _TotalCard extends StatelessWidget {
  final double total;
  final int shares;
  final Color color;
  final String label;
  const _TotalCard({
    required this.total, required this.shares,
    required this.color, required this.label,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: color.withOpacity(0.06),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: _C.txtSec, fontSize: 11,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('$shares shares',
                style: const TextStyle(
                    color: _C.txtHint, fontSize: 10)),
          ],
        ),
        Text(
          _fmtMoney(total),
          style: TextStyle(
              color: color, fontSize: 20,
              fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
      ],
    ),
  );
}

class _StatusBanner extends StatelessWidget {
  final String message;
  final Color color;
  final IconData icon;
  const _StatusBanner(
      {required this.message, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(message,
              style: TextStyle(
                  color: color, fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}

class _SubmitButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool loading;
  final IconData icon;
  final VoidCallback? onTap;
  const _SubmitButton({
    required this.label, required this.color,
    required this.loading, required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: loading
              ? [color.withOpacity(0.4), color.withOpacity(0.3)]
              : [color, color.withOpacity(0.75)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: loading
            ? []
            : [
          BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Center(
        child: loading
            ? const SizedBox(
          width: 22, height: 22,
          child: CircularProgressIndicator(
              color: Colors.white, strokeWidth: 2.5),
        )
            : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3)),
          ],
        ),
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
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Icon(Icons.info_outline_rounded, size: 14, color: _C.txtHint),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Orders are subject to market conditions and DSE regulations. '
                'Prices may differ from execution price. '
                'This is a UAT environment — no real trades are placed.',
            style: TextStyle(
                color: _C.txtHint, fontSize: 10,
                height: 1.5),
          ),
        ),
      ],
    ),
  );
}