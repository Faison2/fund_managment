import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/account_creation.dart';
import '../dashboad/trade_dashboad.dart';


// ── Brand palette (matches AppColors in open-account page) ──────────────────
class _C {
  static const Color blue      = Color(0xFF329AD6);
  static const Color teal      = Color(0xFF00A79D);
  static const Color grey      = Color(0xFF939598);
  static const Color white     = Color(0xFFFFFFFF);
  static const Color black     = Color(0xFF231F20);
  static const Color lightGrey = Color(0xFFF5F6F7);
  static const Color errorRed  = Color(0xFFD32F2F);
}

// ── DSE Landing / Welcome Page ───────────────────────────────────────────────
class DseLandingPage extends StatefulWidget {
  const DseLandingPage({super.key});

  @override
  State<DseLandingPage> createState() => _DseLandingPageState();
}

class _DseLandingPageState extends State<DseLandingPage>
    with TickerProviderStateMixin {
  // ── Animation controllers ────────────────────────────────────────────────
  late final AnimationController _fadeCtrl;
  late final AnimationController _slideCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  // ── NIDA verification state ──────────────────────────────────────────────
  final TextEditingController _nidaCtrl = TextEditingController();
  bool   _isVerifying  = false;
  String _nidaError    = '';
  bool   _nidaSuccess  = false;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));

    _fadeAnim  = CurvedAnimation(parent: _fadeCtrl,  curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));

    // staggered entry
    Future.delayed(const Duration(milliseconds: 100), () {
      _fadeCtrl.forward();
      _slideCtrl.forward();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    _nidaCtrl.dispose();
    super.dispose();
  }

  // ── Verify NIDA ──────────────────────────────────────────────────────────
  Future<void> _verifyNida() async {
    final nida = _nidaCtrl.text.trim();
    if (nida.isEmpty) {
      setState(() => _nidaError = 'Please enter your NIDA number');
      return;
    }
    if (nida.length != 20) {
      setState(() => _nidaError = 'NIDA must be exactly 20 digits');
      return;
    }

    setState(() { _isVerifying = true; _nidaError = ''; _nidaSuccess = false; });

    try {
      final uri = Uri.parse(
        'https://portaluat.tsl.co.tz/DSEAPI/Home/CheckAccountExists'
            '?nat_id=$nida',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['status'] == 'success') {
          final data = body['data'] as Map<String, dynamic>;
          await _saveToPrefs(data);
          setState(() { _nidaSuccess = true; _isVerifying = false; });

          // brief success flash then navigate
          await Future.delayed(const Duration(milliseconds: 600));
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const TradeDashboard()),
            );
          }
        } else {
          setState(() {
            _nidaError   = body['statusDesc'] ?? 'Account not found';
            _isVerifying = false;
          });
        }
      } else {
        setState(() {
          _nidaError   = 'Server error (${res.statusCode})';
          _isVerifying = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _nidaError   = 'Network error. Please try again.';
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _saveToPrefs(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString('dse_id',          '${data['id'] ?? ''}'),
      prefs.setString('client_type',     data['client_type']  ?? ''),
      prefs.setString('broker_ref',      data['broker_ref']   ?? ''),
      prefs.setString('cdsNumber',       data['cds_number']   ?? ''),
      prefs.setString('user_names',
          '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}'.trim()),
      prefs.setString('first_name',      data['first_name']   ?? ''),
      prefs.setString('last_name',       data['last_name']    ?? ''),
      prefs.setString('nida_number',     data['nida_number']  ?? ''),
      prefs.setString('user_email',      data['email']        ?? ''),
      prefs.setString('user_mobile',     data['phone_number'] ?? ''),
    ]);
  }

  // ── UI ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _C.white,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(0, 0, 0, bottom + 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHero(),
                const SizedBox(height: 36),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildNidaCard(),
                      const SizedBox(height: 20),
                      _buildDivider(),
                      const SizedBox(height: 20),
                      _buildOpenAccountCard(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Hero section ──────────────────────────────────────────────────────────
  Widget _buildHero() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
          colors: [_C.teal, _C.blue],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // top bar
              Row(children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.arrow_back_ios_new,
                      color: _C.white, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                // DSE logo badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _C.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('DSE',
                      style: TextStyle(
                          color: _C.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 1.5)),
                ),
              ]),
              const SizedBox(height: 32),

              // icon
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: _C.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: _C.white.withOpacity(0.3), width: 1.5),
                ),
                child: const Icon(Icons.candlestick_chart_outlined,
                    color: _C.white, size: 32),
              ),
              const SizedBox(height: 20),

              const Text(
                'Welcome to\nDSE Trading',
                style: TextStyle(
                  color: _C.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Dar es Salaam Stock Exchange — trade shares,\nbonds, and funds directly from your phone.',
                style: TextStyle(
                  color: _C.white.withOpacity(0.72),
                  fontSize: 13,
                  height: 1.55,
                ),
              ),

              const SizedBox(height: 28),

              // stats row
              Row(children: [
                _heroStat('Listed\nCompanies', '28+'),
                _heroStatDivider(),
                _heroStat('Market\nCap', 'TZS 14T'),
                _heroStatDivider(),
                _heroStat('Est.', '1998'),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroStat(String label, String value) => Expanded(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: TextStyle(
          color: _C.white, fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(
          color: _C.white.withOpacity(0.6), fontSize: 11, height: 1.35)),
    ]),
  );

  Widget _heroStatDivider() => Container(
    width: 1, height: 36,
    margin: const EdgeInsets.symmetric(horizontal: 16),
    color: _C.white.withOpacity(0.2),
  );

  // ── NIDA verification card ─────────────────────────────────────────────────
  Widget _buildNidaCard() {
    final hasError   = _nidaError.isNotEmpty;
    final borderColor = _nidaSuccess
        ? _C.teal
        : hasError
        ? _C.errorRed
        : _C.grey.withOpacity(0.2);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.lightGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // header
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _C.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.fingerprint, color: _C.teal, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Already have an account?',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                      color: _C.black)),
              SizedBox(height: 2),
              Text('Verify with your NIDA number',
                  style: TextStyle(fontSize: 12, color: _C.grey)),
            ],
          )),
        ]),

        const SizedBox(height: 18),

        // NIDA input
        TextFormField(
          controller: _nidaCtrl,
          keyboardType: TextInputType.number,
          maxLength: 20,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) {
            if (_nidaError.isNotEmpty || _nidaSuccess) {
              setState(() { _nidaError = ''; _nidaSuccess = false; });
            }
          },
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: _C.black,
              letterSpacing: 1.5),
          decoration: InputDecoration(
            hintText: '20-digit NIDA number',
            hintStyle: TextStyle(
                color: _C.grey.withOpacity(0.6), fontSize: 14,
                fontWeight: FontWeight.normal, letterSpacing: 0),
            counterText: '',
            filled: true,
            fillColor: _C.white,
            suffixIcon: _nidaSuccess
                ? const Icon(Icons.check_circle_rounded,
                color: _C.teal, size: 22)
                : null,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: _C.grey.withOpacity(0.2), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _C.teal, width: 1.5),
            ),
          ),
        ),

        // error message
        if (hasError) ...[
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.error_outline_rounded,
                color: _C.errorRed, size: 15),
            const SizedBox(width: 6),
            Expanded(child: Text(_nidaError,
                style: const TextStyle(color: _C.errorRed, fontSize: 12))),
          ]),
        ],

        const SizedBox(height: 16),

        // verify button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isVerifying ? null : _verifyNida,
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.teal,
              foregroundColor: _C.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: _isVerifying
                ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: _C.white))
                : const Text('Verify & Continue',
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14)),
          ),
        ),
      ]),
    );
  }

  // ── Divider ────────────────────────────────────────────────────────────────
  Widget _buildDivider() {
    return Row(children: [
      Expanded(child: Divider(color: _C.grey.withOpacity(0.2), height: 1)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Text('OR',
            style: TextStyle(
                color: _C.grey.withOpacity(0.6),
                fontSize: 11, fontWeight: FontWeight.w700,
                letterSpacing: 1.2)),
      ),
      Expanded(child: Divider(color: _C.grey.withOpacity(0.2), height: 1)),
    ]);
  }

  // ── Open account card ──────────────────────────────────────────────────────
  Widget _buildOpenAccountCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.lightGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.grey.withOpacity(0.15), width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // header
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_C.teal, _C.blue]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.account_balance_outlined,
                color: _C.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New to DSE?',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                      color: _C.black)),
              SizedBox(height: 2),
              Text('Create your trading account',
                  style: TextStyle(fontSize: 12, color: _C.grey)),
            ],
          )),
        ]),

        const SizedBox(height: 16),

        // benefits list
        _benefit(Icons.speed_outlined,      'Fast 4-step registration'),
        _benefit(Icons.security_outlined,   'NIDA-verified & secure'),
        _benefit(Icons.payments_outlined,   'Linked to your bank account'),
        _benefit(Icons.bar_chart_outlined,  'Access all DSE-listed stocks'),

        const SizedBox(height: 18),

        // open account button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const DseOpenAccountPage()),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _C.teal,
              side: const BorderSide(color: _C.teal, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Open DSE Account',
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14)),
          ),
        ),
      ]),
    );
  }

  Widget _benefit(IconData icon, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Icon(icon, size: 16, color: _C.teal),
      const SizedBox(width: 10),
      Text(label, style: const TextStyle(
          fontSize: 13, color: _C.black, fontWeight: FontWeight.w500)),
    ]),
  );
}