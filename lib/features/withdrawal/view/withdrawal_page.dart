import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/constants.dart';
import '../../funds/model/model.dart';
import '../../funds/repository/repository.dart';
import '../../../../provider/locale_provider.dart';
import '../../../../provider/theme_provider.dart';

// ── TSL Brand colours ──────────────────────────────────────────────────────────
class _TSL {
  static const Color blue  = Color(0xFF329AD6);
  static const Color teal  = Color(0xFF00A79D);
  static const Color grey  = Color(0xFF939598);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF231F20);
}

// ── Tanzania network providers ────────────────────────────────────────────────
class _NetworkProvider {
  final String name, code;
  final Color  color;
  final bool   comingSoon;
  const _NetworkProvider({
    required this.name, required this.code, required this.color,
    this.comingSoon = false,
  });
}

const _tanzaniaNetworks = [
  _NetworkProvider(name: 'Airtel',      code: 'Airtel',   color: Color(0xFFE20000)),
  _NetworkProvider(name: 'Mixx by YAS', code: 'Tigo',     color: Color(0xFF0057A8)),
  _NetworkProvider(name: 'Halopesa',    code: 'Halopesa', color: Color(0xFFFF9500), comingSoon: true),
  _NetworkProvider(name: 'Azampesa',    code: 'Azampesa', color: Color(0xFF6A0DAD)),
  _NetworkProvider(name: 'Mpesa',       code: 'Mpesa',    color: Color(0xFFE10000)),
];

// ── Localised strings ─────────────────────────────────────────────────────────
class _WS {
  final String withdrawFunds, withdrawSubtitle,
      selectFund, enterAmount, quickSelect,
      availableBalance, units,
      requestWithdrawal, confirmWithdrawal, confirmDetails,
      cancel, confirm, withdrawalRequested, requestFailed,
      done, tryAgain, fund, amount, phone,
      failedLoadFunds, retry, networkError,
      noFunds, notSet, selectNetwork, walletProvider, comingSoon;
  const _WS({
    required this.withdrawFunds,     required this.withdrawSubtitle,
    required this.selectFund,        required this.enterAmount,
    required this.quickSelect,       required this.availableBalance,
    required this.units,
    required this.requestWithdrawal, required this.confirmWithdrawal,
    required this.confirmDetails,    required this.cancel,
    required this.confirm,           required this.withdrawalRequested,
    required this.requestFailed,     required this.done,
    required this.tryAgain,          required this.fund,
    required this.amount,            required this.phone,
    required this.failedLoadFunds,   required this.retry,
    required this.networkError,      required this.noFunds,
    required this.notSet,            required this.selectNetwork,
    required this.walletProvider,    required this.comingSoon,
  });
}

const _wsEn = _WS(
  withdrawFunds:       'Withdraw Funds',
  withdrawSubtitle:    'Choose fund and amount to withdraw',
  selectFund:          'Select Fund',
  enterAmount:         'Enter Amount',
  quickSelect:         'Quick Select',
  availableBalance:    'Available Balance',
  units:               'units',
  requestWithdrawal:   'Request Withdrawal',
  confirmWithdrawal:   'Confirm Withdrawal',
  confirmDetails:      'Please confirm your withdrawal request.',
  cancel:              'Cancel',
  confirm:             'Confirm',
  withdrawalRequested: 'Withdrawal Requested!',
  requestFailed:       'Request Failed',
  done:                'Done',
  tryAgain:            'Try Again',
  fund:                'Fund',
  amount:              'Amount',
  phone:               'Phone',
  failedLoadFunds:     'Failed to load funds',
  retry:               'Retry',
  networkError:        'Network error',
  noFunds:             'No funds available',
  notSet:              'Not set',
  selectNetwork:       'Select Network',
  walletProvider:      'Wallet Provider',
  comingSoon:          'Soon',
);

const _wsSw = _WS(
  withdrawFunds:       'Toa Fedha',
  withdrawSubtitle:    'Chagua fedha na kiasi cha kutoa',
  selectFund:          'Chagua Fedha',
  enterAmount:         'Ingiza Kiasi',
  quickSelect:         'Chaguo la Haraka',
  availableBalance:    'Salio Linalopatikana',
  units:               'vitengo',
  requestWithdrawal:   'Omba Kutoa',
  confirmWithdrawal:   'Thibitisha Kutoa',
  confirmDetails:      'Tafadhali thibitisha ombi lako la kutoa.',
  cancel:              'Ghairi',
  confirm:             'Thibitisha',
  withdrawalRequested: 'Ombi la Kutoa Limewasilishwa!',
  requestFailed:       'Ombi Limeshindwa',
  done:                'Imekamilika',
  tryAgain:            'Jaribu Tena',
  fund:                'Fedha',
  amount:              'Kiasi',
  phone:               'Simu',
  failedLoadFunds:     'Imeshindwa kupakia fedha',
  retry:               'Jaribu Tena',
  networkError:        'Hitilafu ya mtandao',
  noFunds:             'Hakuna fedha zinazopatikana',
  notSet:              'Haijawekwa',
  selectNetwork:       'Chagua Mtandao',
  walletProvider:      'Mtoa Huduma wa Pochi',
  comingSoon:          'Hivi Karibuni',
);

// ── WithdrawalPage ────────────────────────────────────────────────────────────
class WithdrawalPage extends StatefulWidget {
  const WithdrawalPage({Key? key}) : super(key: key);
  @override State<WithdrawalPage> createState() => _WithdrawalPageState();
}

class _WithdrawalPageState extends State<WithdrawalPage> {
  final TextEditingController _amountController = TextEditingController();
  String _selectedCurrency = 'TZS';

  _NetworkProvider? _selectedNetwork;

  String _cdsNumber   = '';
  String _phoneNumber = '';

  List<Fund> _funds         = [];
  Fund?      _selectedFund;
  bool       _isLoadingFunds = true;
  String     _fundsError     = '';

  double? _availableBalance;
  double? _availableUnits;
  bool    _isLoadingBalance = false;

  bool _isSubmitting = false;

  final List<String> _currencies = ['TZS', 'USD'];
  final List<Map<String, String>> _quickAmounts = [
    {'amount': '1000',  'label': '100K'},
    {'amount': '5000',  'label': '5K'},
    {'amount': '10000', 'label': '10K'},
    {'amount': '25000', 'label': '25K'},
  ];

  bool get _dark => context.watch<ThemeProvider>().isDark;
  _WS  get _s    => context.watch<LocaleProvider>().isSwahili ? _wsSw : _wsEn;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() => setState(() {}));
    _loadUserData();
    _loadFunds();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _cdsNumber   = prefs.getString('cdsNumber')   ?? '';
      _phoneNumber = prefs.getString('user_mobile') ?? '';
    });
  }

  Future<void> _loadFunds() async {
    try {
      setState(() { _isLoadingFunds = true; _fundsError = ''; });
      final funds = await FundsRepository().fetchFunds();
      setState(() {
        _funds = funds; _selectedFund = null; _isLoadingFunds = false;
      });
    } catch (_) {
      setState(() { _fundsError = _s.failedLoadFunds; _isLoadingFunds = false; });
    }
  }

  Future<void> _fetchAvailableBalance() async {
    if (_selectedFund == null) return;
    setState(() {
      _isLoadingBalance = true;
      _availableBalance = null;
      _availableUnits   = null;
    });
    try {
      final res = await http.post(
        Uri.parse('$cSharpApi/GetAvailableBalance'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'APIUsername': 'User2', 'APIPassword': 'CBZ1234#2',
          'cdsNumber': _cdsNumber, 'Fund': _selectedFund!.fundingName ?? '',
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['status'] == 'success') {
        final funds = data['data']['funds'] as List<dynamic>;
        if (funds.isNotEmpty) {
          setState(() {
            _availableBalance = (funds[0]['portfolioValue'] as num).toDouble();
            _availableUnits   = (funds[0]['investorUnits']  as num).toDouble();
          });
        } else {
          setState(() { _availableBalance = 0; _availableUnits = 0; });
        }
      } else {
        setState(() { _availableBalance = 0; _availableUnits = 0; });
      }
    } catch (_) {
      setState(() { _availableBalance = 0; _availableUnits = 0; });
    } finally {
      setState(() => _isLoadingBalance = false);
    }
  }

  Future<void> _processWithdrawal() async {
    if (_amountController.text.isEmpty || _selectedFund == null) return;
    if (_selectedNetwork == null) {
      _snackErr('Please select a network provider');
      return;
    }
    final confirmed = await _showConfirmationDialog();
    if (!confirmed) return;

    setState(() => _isSubmitting = true);
    try {
      final res = await http.post(
        Uri.parse('$cSharpApi/Redeem'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'APIUsername':    'User2', 'APIPassword': 'CBZ1234#2',
          'cdsNumber':      _cdsNumber, 'PhoneNumber': _phoneNumber,
          'Fund':           _selectedFund!.fundingName ?? '',
          'Amount':         _amountController.text,
          'WalletProvider': _selectedNetwork!.code,
        }),
      );
      final data = jsonDecode(res.body);
      final String msg = data['statusDesc'] ?? 'No response from server';
      final bool ok    = res.statusCode == 200 && data['status'] == 'success';
      _showResultDialog(success: ok, message: msg);
    } catch (e) {
      _showResultDialog(success: false, message: '${_s.networkError}: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  // ── Confirmation dialog ────────────────────────────────────────────────────
  Future<bool> _showConfirmationDialog() async {
    final dark  = Provider.of<ThemeProvider>(context, listen: false).isDark;
    final s     = Provider.of<LocaleProvider>(context, listen: false).isSwahili
        ? _wsSw : _wsEn;
    final fund   = _selectedFund?.fundingName ?? '—';
    final amt    = '$_selectedCurrency ${_fmt(_amountController.text)}';
    final phone  = _phoneNumber.isNotEmpty ? _phoneNumber : s.notSet;
    final wallet = _selectedNetwork?.name ?? '—';

    final cardBg = dark ? _TSL.black : _TSL.white;
    final txtP   = dark ? _TSL.white : _TSL.black;
    final txtS   = dark ? _TSL.teal  : _TSL.grey;
    final border = dark ? _TSL.black.withOpacity(0.35) : const Color(0xFFE5E7EB);
    final orange = dark ? const Color(0xFFFB923C) : Colors.orange;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: orange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.receipt_long_outlined,
                          color: orange, size: 20)),
                  const SizedBox(width: 12),
                  Flexible(child: Text(s.confirmWithdrawal,
                      style: TextStyle(fontSize: 17,
                          fontWeight: FontWeight.w800, color: txtP))),
                ]),
                const SizedBox(height: 20),
                _dRow(s.fund,           fund,   txtP, txtS, border),
                _dRow(s.amount,         amt,    txtP, txtS, border),
                _dRow(s.walletProvider, wallet, txtP, txtS, border),
                _dRow(s.phone,          phone,  txtP, txtS, border),
                const SizedBox(height: 12),
                Text(s.confirmDetails,
                    style: TextStyle(color: txtS, fontSize: 12, height: 1.4)),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: border, width: 1.5)),
                      child: Center(child: Text(s.cancel,
                          style: TextStyle(color: txtS,
                              fontWeight: FontWeight.w600))),
                    ),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [orange, orange.withOpacity(0.75)]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(
                            color: orange.withOpacity(0.35),
                            blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Center(child: Text(s.confirm,
                          style: TextStyle(color: _TSL.white,
                              fontWeight: FontWeight.w700))),
                    ),
                  )),
                ]),
              ]),
        ),
      ),
    );
    return result ?? false;
  }

  Widget _dRow(String lbl, String val, Color tp, Color ts, Color bd) =>
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
            border: Border.all(color: bd),
            borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          SizedBox(width: 88, child: Text(lbl,
              style: TextStyle(fontSize: 12, color: ts,
                  fontWeight: FontWeight.w500))),
          Expanded(child: Text(val,
              style: TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w700, color: tp),
              overflow: TextOverflow.ellipsis)),
        ]),
      );

  // ── Result dialog ──────────────────────────────────────────────────────────
  void _showResultDialog({required bool success, required String message}) {
    final dark   = Provider.of<ThemeProvider>(context, listen: false).isDark;
    final s      = Provider.of<LocaleProvider>(context, listen: false).isSwahili
        ? _wsSw : _wsEn;
    final cardBg = dark ? _TSL.black : _TSL.white;
    final txtP   = dark ? _TSL.white : _TSL.black;
    final txtS   = dark ? _TSL.teal  : _TSL.grey;
    final accent = success ? Colors.orange : Colors.red;

    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [accent, accent.withOpacity(0.75)]),
                    shape: BoxShape.circle),
                child: Icon(
                    success ? Icons.check_rounded : Icons.close_rounded,
                    color: _TSL.white, size: 36)),
            const SizedBox(height: 20),
            Text(success ? s.withdrawalRequested : s.requestFailed,
                style: TextStyle(fontSize: 18,
                    fontWeight: FontWeight.w800, color: txtP)),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: txtS, height: 1.5)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                if (success) Navigator.pop(context);
              },
              child: Container(
                width: double.infinity, height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [accent, accent.withOpacity(0.75)]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(
                      color: accent.withOpacity(0.35),
                      blurRadius: 12, offset: const Offset(0, 5))],
                ),
                child: Center(child: Text(
                    success ? s.done : s.tryAgain,
                    style: TextStyle(color: _TSL.white,
                        fontSize: 15, fontWeight: FontWeight.w700))),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _snackErr(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg, style: TextStyle(color: _TSL.white)),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 4),
    ),
  );

  String _fmt(String v) {
    if (v.isEmpty) return '0.00';
    final d = double.tryParse(v) ?? 0;
    return d.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  bool get _canWithdraw =>
      _amountController.text.isNotEmpty &&
          (double.tryParse(_amountController.text) ?? 0) > 0 &&
          _selectedFund    != null &&
          _selectedNetwork != null &&
          !_isSubmitting;

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    context.watch<LocaleProvider>();

    final bottomInset   = MediaQuery.of(context).padding.bottom;
    final scrollPadding = 40.0 + bottomInset;

    final dark = _dark; final s = _s;

    final bg        = dark ? _TSL.black                      : const Color(0xFFB8E6D3);
    final cardBg    = dark ? _TSL.black                      : _TSL.white;
    final sheet     = dark ? _TSL.black.withOpacity(0.95)    : _TSL.white;
    final border    = dark ? _TSL.black.withOpacity(0.35)    : const Color(0xFFE5E7EB);
    final txtP      = dark ? _TSL.white                      : _TSL.black;
    final txtS      = dark ? _TSL.teal                       : _TSL.grey;
    final txtH      = dark ? _TSL.teal.withOpacity(0.6)      : _TSL.grey.withOpacity(0.6);
    final inputBg   = dark ? _TSL.black                      : const Color(0xFFF9FAFB);
    final balanceBg = dark ? _TSL.black                      : _TSL.white;
    final orange    = dark ? const Color(0xFFFB923C) : Colors.orange;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: bg,
      body: Column(children: [

        // ── Gradient header ────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [_TSL.blue, _TSL.teal],
            ),
          ),
          child: SafeArea(bottom: false, child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: _TSL.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.arrow_back_ios_new,
                        color: _TSL.white, size: 18)),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.withdrawFunds, style: TextStyle(
                    color: _TSL.white, fontSize: 22,
                    fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                const SizedBox(height: 2),
                Text(s.withdrawSubtitle, style: TextStyle(
                    color: _TSL.white.withOpacity(0.65), fontSize: 12)),
              ])),
            ]),
          )),
        ),

        // ── Available balance banner ───────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_TSL.teal, _TSL.blue],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: balanceBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
              boxShadow: [BoxShadow(
                  color: _TSL.black.withOpacity(dark ? 0.3 : 0.08),
                  blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(children: [
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.availableBalance,
                    style: TextStyle(fontSize: 12, color: txtS)),
                const SizedBox(height: 6),
                _isLoadingBalance
                    ? SizedBox(height: 22, width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: orange))
                    : Text(
                    _availableBalance != null
                        ? 'TZS ${_fmt(_availableBalance!.toStringAsFixed(2))}'
                        : '—',
                    style: TextStyle(fontSize: 22,
                        fontWeight: FontWeight.w900, color: orange)),
                if (_availableUnits != null && !_isLoadingBalance) ...[
                  const SizedBox(height: 4),
                  Text(
                      '${_fmt(_availableUnits!.toStringAsFixed(2))} ${s.units}',
                      style: TextStyle(fontSize: 11, color: txtH)),
                ],
              ])),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: orange.withOpacity(0.12),
                    shape: BoxShape.circle),
                child: Icon(Icons.account_balance_wallet_outlined,
                    color: orange, size: 26),
              ),
            ]),
          ),
        ),

        // ── Scrollable form ────────────────────────────────────────────────
        Expanded(
          child: Container(
            color: sheet,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(20, 24, 20, scrollPadding),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Fund dropdown ─────────────────────────────────────
                    _secLabel(s.selectFund, txtH),
                    const SizedBox(height: 10),
                    if (_isLoadingFunds)
                      Center(child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: CircularProgressIndicator(
                              color: orange, strokeWidth: 2.5)))
                    else if (_fundsError.isNotEmpty)
                      _errBanner(_fundsError, s.retry, orange, border,
                          onRetry: _loadFunds)
                    else
                      _dropdown(bg: inputBg, border: border,
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<Fund>(
                            value: _selectedFund,
                            isExpanded: true,
                            dropdownColor: cardBg,
                            icon: Icon(Icons.keyboard_arrow_down_rounded,
                                color: txtS),
                            hint: Row(children: [
                              const SizedBox(width: 2),
                              Text(s.selectFund,
                                  style: TextStyle(fontSize: 14,
                                      fontWeight: FontWeight.w500, color: txtH)),
                            ]),
                            items: _funds.map((f) => DropdownMenuItem<Fund>(
                              value: f,
                              child: Row(children: [
                                Container(
                                  width: 8, height: 8,
                                  decoration: BoxDecoration(
                                    color: f.status?.toLowerCase() == 'active'
                                        ? const Color(0xFF22C55E)
                                        : Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Text(
                                  f.fundingName ?? s.noFunds,
                                  style: TextStyle(fontWeight: FontWeight.w600,
                                      fontSize: 14, color: txtP),
                                  overflow: TextOverflow.ellipsis,
                                )),
                              ]),
                            )).toList(),
                            onChanged: (f) {
                              setState(() => _selectedFund = f);
                              _fetchAvailableBalance();
                            },
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // ── Network provider ──────────────────────────────────
                    _secLabel(s.selectNetwork, txtH),
                    const SizedBox(height: 10),
                    _networkProviderPicker(
                      inputBg: inputBg, border: border,
                      txtS: txtS, dark: dark, comingSoonLabel: s.comingSoon,
                    ),

                    const SizedBox(height: 24),

                    // ── Amount ────────────────────────────────────────────
                    _secLabel(s.enterAmount, txtH),
                    const SizedBox(height: 10),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                            color: inputBg,
                            borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(14),
                                bottomLeft: Radius.circular(14)),
                            border: Border.all(color: border)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCurrency,
                            dropdownColor: cardBg, isDense: true,
                            icon: Icon(Icons.expand_more,
                                size: 18, color: txtS),
                            items: _currencies.map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c, style: TextStyle(
                                  fontWeight: FontWeight.w700, color: txtP)),
                            )).toList(),
                            onChanged: (v) =>
                                setState(() => _selectedCurrency = v!),
                          ),
                        ),
                      ),
                      Expanded(child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly],
                        style: TextStyle(fontSize: 18,
                            fontWeight: FontWeight.w800, color: txtP),
                        scrollPadding:
                        EdgeInsets.only(bottom: bottomInset + 80),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: TextStyle(color: txtH),
                          filled: true, fillColor: inputBg,
                          border: OutlineInputBorder(
                              borderSide: BorderSide(color: border),
                              borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(14),
                                  bottomRight: Radius.circular(14))),
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: border),
                              borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(14),
                                  bottomRight: Radius.circular(14))),
                          focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: orange, width: 2),
                              borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(14),
                                  bottomRight: Radius.circular(14))),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                      )),
                    ]),

                    const SizedBox(height: 20),

                    // ── Quick amounts ─────────────────────────────────────
                    _secLabel(s.quickSelect, txtH),
                    const SizedBox(height: 10),
                    Row(
                      children: _quickAmounts.asMap().entries.map((e) {
                        final a = e.value;
                        return Expanded(child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() =>
                            _amountController.text = a['amount']!);
                          },
                          child: Container(
                            margin: EdgeInsets.only(
                                right: e.key < _quickAmounts.length - 1
                                    ? 8 : 0),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: orange.withOpacity(dark ? 0.1 : 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: orange.withOpacity(0.3)),
                            ),
                            child: Column(children: [
                              Text(a['label']!,
                                  style: TextStyle(fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: orange)),
                              const SizedBox(height: 2),
                              Text(
                                  '$_selectedCurrency ${_fmt(a['amount']!)}',
                                  style: TextStyle(fontSize: 9,
                                      color: orange.withOpacity(0.7))),
                            ]),
                          ),
                        ));
                      }).toList(),
                    ),

                    const SizedBox(height: 28),

                    // ── Submit button ─────────────────────────────────────
                    GestureDetector(
                      onTap: _canWithdraw ? _processWithdrawal : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: _canWithdraw
                              ? LinearGradient(colors: [
                            orange,
                            dark ? Colors.deepOrange
                                : Colors.orange.shade700,
                          ])
                              : LinearGradient(colors: [txtH, txtH]),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _canWithdraw
                              ? [BoxShadow(
                              color: orange.withOpacity(0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 6))]
                              : [],
                        ),
                        child: Center(child: _isSubmitting
                            ? SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: _TSL.white, strokeWidth: 2.5))
                            : Text(s.requestWithdrawal,
                            style: TextStyle(color: _TSL.white,
                                fontSize: 16, fontWeight: FontWeight.w800,
                                letterSpacing: 0.3))),
                      ),
                    ),
                  ]),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Network provider picker ───────────────────────────────────────────────
  Widget _networkProviderPicker({
    required Color inputBg, required Color border,
    required Color txtS,    required bool  dark,
    required String comingSoonLabel,
  }) {
    return Column(children: [
      Row(children: [
        _networkTile(_tanzaniaNetworks[0], inputBg, border, txtS, dark, comingSoonLabel),
        const SizedBox(width: 10),
        _networkTile(_tanzaniaNetworks[1], inputBg, border, txtS, dark, comingSoonLabel),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        _networkTile(_tanzaniaNetworks[2], inputBg, border, txtS, dark, comingSoonLabel),
        const SizedBox(width: 10),
        _networkTile(_tanzaniaNetworks[3], inputBg, border, txtS, dark, comingSoonLabel),
      ]),
      const SizedBox(height: 10),
      _networkTile(_tanzaniaNetworks[4], inputBg, border, txtS, dark, comingSoonLabel,
          fullWidth: true),
    ]);
  }

  Widget _networkTile(
      _NetworkProvider n, Color inputBg, Color border,
      Color txtS, bool dark, String comingSoonLabel,
      {bool fullWidth = false}) {
    final selected  = _selectedNetwork?.code == n.code;
    final disabled  = n.comingSoon;

    final tile = GestureDetector(
      onTap: disabled ? null : () {
        HapticFeedback.selectionClick();
        setState(() => _selectedNetwork = n);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 50,
        decoration: BoxDecoration(
          color: disabled
              ? inputBg.withOpacity(0.5)
              : selected
              ? n.color.withOpacity(dark ? 0.25 : 0.12)
              : inputBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: disabled
                  ? border.withOpacity(0.4)
                  : selected ? n.color : border,
              width: selected ? 2 : 1),
          boxShadow: selected && !disabled
              ? [BoxShadow(color: n.color.withOpacity(0.25),
              blurRadius: 8, offset: const Offset(0, 3))]
              : [],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 10, height: 10,
              decoration: BoxDecoration(
                  color: disabled
                      ? n.color.withOpacity(0.35)
                      : n.color,
                  shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Flexible(child: Text(n.name,
              style: TextStyle(fontSize: 13,
                  fontWeight: selected && !disabled
                      ? FontWeight.w800 : FontWeight.w600,
                  color: disabled
                      ? txtS.withOpacity(0.4)
                      : selected ? n.color : txtS),
              overflow: TextOverflow.ellipsis)),
          if (disabled) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: n.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: n.color.withOpacity(0.4), width: 0.5),
              ),
              child: Text(comingSoonLabel,
                  style: TextStyle(fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: n.color.withOpacity(0.7),
                      letterSpacing: 0.3)),
            ),
          ] else if (selected) ...[
            const SizedBox(width: 4),
            Icon(Icons.check_circle_rounded, color: n.color, size: 14),
          ],
        ]),
      ),
    );
    return fullWidth ? tile : Expanded(child: tile);
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────
  Widget _secLabel(String t, Color c) => Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(t.toUpperCase(),
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
              color: c, letterSpacing: 1.2)));

  Widget _dropdown({required Widget child,
    required Color bg, required Color border}) =>
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(color: bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border)),
          child: child);

  Widget _errBanner(String msg, String lbl, Color orange, Color border,
      {required VoidCallback onRetry}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.red, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(msg,
              style: const TextStyle(color: Colors.red, fontSize: 13))),
          GestureDetector(
              onTap: onRetry,
              child: Text(lbl,
                  style: TextStyle(color: orange,
                      fontWeight: FontWeight.w700, fontSize: 13))),
        ]),
      );
}