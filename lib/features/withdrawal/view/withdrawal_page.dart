import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../funds/model/model.dart';
import '../../funds/repository/repository.dart';
import '../../../../provider/locale_provider.dart';
import '../../../../provider/theme_provider.dart';

// ── Localised strings ─────────────────────────────────────────────────────────
class _WS {
  final String withdrawFunds, withdrawSubtitle,
      selectFund, enterAmount, quickSelect,
      availableBalance, units, bankingDetails,
      bank, accountNo, accountName, branch,
      requestWithdrawal, confirmWithdrawal, confirmDetails,
      cancel, confirm, withdrawalRequested, requestFailed,
      done, tryAgain, fund, amount, phone,
      failedLoadFunds, retry, networkError,
      noFunds, notSet, noBankingDetails,
      tapToView, tapToHide;
  const _WS({
    required this.withdrawFunds,     required this.withdrawSubtitle,
    required this.selectFund,        required this.enterAmount,
    required this.quickSelect,       required this.availableBalance,
    required this.units,             required this.bankingDetails,
    required this.bank,              required this.accountNo,
    required this.accountName,       required this.branch,
    required this.requestWithdrawal, required this.confirmWithdrawal,
    required this.confirmDetails,    required this.cancel,
    required this.confirm,           required this.withdrawalRequested,
    required this.requestFailed,     required this.done,
    required this.tryAgain,          required this.fund,
    required this.amount,            required this.phone,
    required this.failedLoadFunds,   required this.retry,
    required this.networkError,      required this.noFunds,
    required this.notSet,            required this.noBankingDetails,
    required this.tapToView,         required this.tapToHide,
  });
}

const _wsEn = _WS(
  withdrawFunds:     'Withdraw Funds',
  withdrawSubtitle:  'Choose fund and amount to withdraw',
  selectFund:        'Select Fund',
  enterAmount:       'Enter Amount',
  quickSelect:       'Quick Select',
  availableBalance:  'Available Balance',
  units:             'units',
  bankingDetails:    'Banking Details',
  bank:              'Bank',
  accountNo:         'Account No',
  accountName:       'Account Name',
  branch:            'Branch',
  requestWithdrawal: 'Request Withdrawal',
  confirmWithdrawal: 'Confirm Withdrawal',
  confirmDetails:    'Please confirm your withdrawal request.',
  cancel:            'Cancel',
  confirm:           'Confirm',
  withdrawalRequested: 'Withdrawal Requested!',
  requestFailed:     'Request Failed',
  done:              'Done',
  tryAgain:          'Try Again',
  fund:              'Fund',
  amount:            'Amount',
  phone:             'Phone',
  failedLoadFunds:   'Failed to load funds',
  retry:             'Retry',
  networkError:      'Network error',
  noFunds:           'No funds available',
  notSet:            'Not set',
  noBankingDetails:  'No banking details saved',
  tapToView:         'Tap to view banking details',
  tapToHide:         'Tap to hide banking details',
);

const _wsSw = _WS(
  withdrawFunds:     'Toa Fedha',
  withdrawSubtitle:  'Chagua fedha na kiasi cha kutoa',
  selectFund:        'Chagua Fedha',
  enterAmount:       'Ingiza Kiasi',
  quickSelect:       'Chaguo la Haraka',
  availableBalance:  'Salio Linalopatikana',
  units:             'vitengo',
  bankingDetails:    'Maelezo ya Benki',
  bank:              'Benki',
  accountNo:         'Nambari ya Akaunti',
  accountName:       'Jina la Akaunti',
  branch:            'Tawi',
  requestWithdrawal: 'Omba Kutoa',
  confirmWithdrawal: 'Thibitisha Kutoa',
  confirmDetails:    'Tafadhali thibitisha ombi lako la kutoa.',
  cancel:            'Ghairi',
  confirm:           'Thibitisha',
  withdrawalRequested: 'Ombi la Kutoa Limewasilishwa!',
  requestFailed:     'Ombi Limeshindwa',
  done:              'Imekamilika',
  tryAgain:          'Jaribu Tena',
  fund:              'Fedha',
  amount:            'Kiasi',
  phone:             'Simu',
  failedLoadFunds:   'Imeshindwa kupakia fedha',
  retry:             'Jaribu Tena',
  networkError:      'Hitilafu ya mtandao',
  noFunds:           'Hakuna fedha zinazopatikana',
  notSet:            'Haijawekwa',
  noBankingDetails:  'Hakuna maelezo ya benki yaliyohifadhiwa',
  tapToView:         'Gonga kuona maelezo ya benki',
  tapToHide:         'Gonga kuficha maelezo ya benki',
);

// ── WithdrawalPage ────────────────────────────────────────────────────────────
class WithdrawalPage extends StatefulWidget {
  const WithdrawalPage({Key? key}) : super(key: key);

  @override
  State<WithdrawalPage> createState() => _WithdrawalPageState();
}

class _WithdrawalPageState extends State<WithdrawalPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _amountController = TextEditingController();
  String _selectedCurrency = 'TZS';

  // ── User / banking data from SharedPreferences ─────────────────────────────
  String _cdsNumber   = '';
  String _phoneNumber = '';
  String _bank        = '';
  String _accountNo   = '';
  String _accountName = '';
  String _branch      = '';

  // ── Funds ──────────────────────────────────────────────────────────────────
  List<Fund> _funds         = [];
  Fund?      _selectedFund;
  bool       _isLoadingFunds = true;
  String     _fundsError     = '';

  // ── Balance ────────────────────────────────────────────────────────────────
  double? _availableBalance;
  double? _availableUnits;
  bool    _isLoadingBalance = false;

  // ── UI state ───────────────────────────────────────────────────────────────
  bool _isSubmitting        = false;
  bool _bankingDetailsOpen  = false;   // expand/collapse accordion

  // Animation controller for the banking details accordion
  late final AnimationController _accordionCtrl;
  late final Animation<double>   _accordionAnim;

  final List<String> _currencies = ['TZS', 'USD'];
  final List<Map<String, String>> _quickAmounts = [
    {'amount': '1000',  'label': '1K'},
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
    _accordionCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _accordionAnim = CurvedAnimation(
        parent: _accordionCtrl, curve: Curves.easeInOut);
    _loadUserData();
    _loadFunds();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _accordionCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _cdsNumber   = prefs.getString('cdsNumber')       ?? '';
      _phoneNumber = prefs.getString('user_mobile')     ?? '';
      _bank        = prefs.getString('user_bank')        ?? '';
      _accountNo   = prefs.getString('user_accountNo')   ?? '';
      _accountName = prefs.getString('user_accountName') ?? '';
      _branch      = prefs.getString('user_branch')      ?? '';
    });
  }

  Future<void> _loadFunds() async {
    try {
      setState(() { _isLoadingFunds = true; _fundsError = ''; });
      final funds = await FundsRepository().fetchFunds();
      setState(() {
        _funds          = funds;
        _selectedFund   = funds.isNotEmpty ? funds.first : null;
        _isLoadingFunds = false;
      });
      if (_selectedFund != null) _fetchAvailableBalance();
    } catch (_) {
      setState(() { _fundsError = _s.failedLoadFunds; _isLoadingFunds = false; });
    }
  }

  Future<void> _fetchAvailableBalance() async {
    if (_selectedFund == null) return;
    setState(() { _isLoadingBalance = true; _availableBalance = null; _availableUnits = null; });
    try {
      final res = await http.post(
        Uri.parse('https://portaluat.tsl.co.tz/FMSAPI/home/GetAvailableBalance'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'APIUsername': 'User2',
          'APIPassword': 'CBZ1234#2',
          'cdsNumber':   _cdsNumber,
          'Fund':        _selectedFund!.fundingName ?? '',
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

  // ── Toggle banking accordion ───────────────────────────────────────────────
  void _toggleBankingDetails() {
    setState(() => _bankingDetailsOpen = !_bankingDetailsOpen);
    if (_bankingDetailsOpen) {
      _accordionCtrl.forward();
    } else {
      _accordionCtrl.reverse();
    }
  }

  // ── Withdrawal API ─────────────────────────────────────────────────────────
  Future<void> _processWithdrawal() async {
    if (_amountController.text.isEmpty || _selectedFund == null) return;
    final confirmed = await _showConfirmationDialog();
    if (!confirmed) return;

    setState(() => _isSubmitting = true);
    try {
      final res = await http.post(
        Uri.parse('https://portaluat.tsl.co.tz/FMSAPI/home/Redeem'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'APIUsername': 'User2',
          'APIPassword': 'CBZ1234#2',
          'cdsNumber':   _cdsNumber,
          'PhoneNumber': _phoneNumber,
          'Fund':        _selectedFund!.fundingName ?? '',
          'Amount':      _amountController.text,
        }),
      );
      final data      = jsonDecode(res.body);
      final String msg = data['statusDesc'] ?? 'No response from server';
      final bool ok   = res.statusCode == 200 && data['status'] == 'success';
      _showResultDialog(success: ok, message: msg);
    } catch (e) {
      _showResultDialog(success: false, message: '${_s.networkError}: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  // ── Confirmation dialog ────────────────────────────────────────────────────
  Future<bool> _showConfirmationDialog() async {
    final dark   = Provider.of<ThemeProvider>(context, listen: false).isDark;
    final s      = Provider.of<LocaleProvider>(context, listen: false).isSwahili
        ? _wsSw : _wsEn;
    final fund   = _selectedFund?.fundingName ?? '—';
    final amt    = '$_selectedCurrency ${_fmt(_amountController.text)}';
    final phone  = _phoneNumber.isNotEmpty ? _phoneNumber : s.notSet;

    final cardBg = dark ? const Color(0xFF132013) : Colors.white;
    final txtP   = dark ? const Color(0xFFE8F5E9) : Colors.black87;
    final txtS   = dark ? const Color(0xFF81A884)  : Colors.grey.shade600;
    final border = dark ? const Color(0xFF1E3320)  : Colors.grey.shade200;
    final orange = dark ? const Color(0xFFFB923C)  : Colors.orange;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: orange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.receipt_long_outlined, color: orange, size: 20)),
                  const SizedBox(width: 12),
                  Flexible(child: Text(s.confirmWithdrawal,
                      style: TextStyle(fontSize: 17,
                          fontWeight: FontWeight.w800, color: txtP))),
                ]),
                const SizedBox(height: 20),
                _dRow(s.fund,   fund,  txtP, txtS, border),
                _dRow(s.amount, amt,   txtP, txtS, border),
                _dRow(s.phone,  phone, txtP, txtS, border),
                const SizedBox(height: 12),
                Text(s.confirmDetails,
                    style: TextStyle(color: txtS, fontSize: 12, height: 1.4)),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: Container(height: 46,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: border, width: 1.5)),
                        child: Center(child: Text(s.cancel,
                            style: TextStyle(color: txtS,
                                fontWeight: FontWeight.w600)))),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Container(height: 46,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: [orange, orange.withOpacity(0.75)]),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: orange.withOpacity(0.35),
                              blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Center(child: Text(s.confirm,
                            style: const TextStyle(color: Colors.white,
                                fontWeight: FontWeight.w700)))),
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
        decoration: BoxDecoration(border: Border.all(color: bd),
            borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          SizedBox(width: 72, child: Text(lbl, style: TextStyle(
              fontSize: 12, color: ts, fontWeight: FontWeight.w500))),
          Expanded(child: Text(val, style: TextStyle(fontSize: 13,
              fontWeight: FontWeight.w700, color: tp),
              overflow: TextOverflow.ellipsis)),
        ]),
      );

  // ── Result dialog ──────────────────────────────────────────────────────────
  void _showResultDialog({required bool success, required String message}) {
    final dark   = Provider.of<ThemeProvider>(context, listen: false).isDark;
    final s      = Provider.of<LocaleProvider>(context, listen: false).isSwahili
        ? _wsSw : _wsEn;
    final cardBg = dark ? const Color(0xFF132013) : Colors.white;
    final txtP   = dark ? const Color(0xFFE8F5E9) : Colors.black87;
    final txtS   = dark ? const Color(0xFF81A884)  : Colors.grey.shade600;
    final accent = success ? Colors.orange : Colors.red;

    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 72, height: 72,
                decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      accent, accent.withOpacity(0.75)]),
                    shape: BoxShape.circle),
                child: Icon(success ? Icons.check_rounded : Icons.close_rounded,
                    color: Colors.white, size: 36)),
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
              child: Container(width: double.infinity, height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [accent, accent.withOpacity(0.75)]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: accent.withOpacity(0.35),
                        blurRadius: 12, offset: const Offset(0, 5))],
                  ),
                  child: Center(child: Text(
                      success ? s.done : s.tryAgain,
                      style: const TextStyle(color: Colors.white,
                          fontSize: 15, fontWeight: FontWeight.w700)))),
            ),
          ]),
        ),
      ),
    );
  }

  void _snackErr(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4)),
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
          _selectedFund != null &&
          !_isSubmitting;

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    context.watch<LocaleProvider>();

    final dark      = _dark; final s = _s;
    final bg        = dark ? const Color(0xFF0B1A0C) : const Color(0xFFB8E6D3);
    final cardBg    = dark ? const Color(0xFF132013) : Colors.white;
    final sheet     = dark ? const Color(0xFF111D12) : Colors.white;
    final border    = dark ? const Color(0xFF1E3320) : const Color(0xFFE5E7EB);
    final txtP      = dark ? const Color(0xFFE8F5E9) : Colors.black87;
    final txtS      = dark ? const Color(0xFF81A884)  : Colors.black54;
    final txtH      = dark ? const Color(0xFF4A7A4D)  : Colors.grey.shade400;
    final orange    = dark ? const Color(0xFFFB923C)  : Colors.orange;
    final inputBg   = dark ? const Color(0xFF132013)  : const Color(0xFFF9FAFB);
    final balanceBg = dark ? const Color(0xFF0F1A10)  : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      body: Column(children: [

        // ── Gradient header ──────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            gradient: dark
                ? const LinearGradient(begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0B1A0C), Color(0xFF132013), Color(0xFF09100A)])
                : const LinearGradient(begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)]),
          ),
          child: SafeArea(bottom: false, child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 18)),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.withdrawFunds, style: const TextStyle(color: Colors.white,
                    fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                const SizedBox(height: 2),
                Text(s.withdrawSubtitle, style: TextStyle(
                    color: Colors.white.withOpacity(0.65), fontSize: 12)),
              ])),
            ]),
          )),
        ),

        // ── Available balance banner (inside header area) ────────────────────
        Container(
          decoration: BoxDecoration(
            gradient: dark
                ? const LinearGradient(colors: [Color(0xFF132013), Color(0xFF0F1A10)])
                : const LinearGradient(colors: [Color(0xFF388E3C), Color(0xFF2E7D32)]),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: balanceBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(dark ? 0.3 : 0.08),
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
                    child: CircularProgressIndicator(strokeWidth: 2, color: orange))
                    : Text(
                    _availableBalance != null
                        ? 'TZS ${_fmt(_availableBalance!.toStringAsFixed(2))}'
                        : '—',
                    style: TextStyle(fontSize: 22,
                        fontWeight: FontWeight.w900, color: orange)),
                if (_availableUnits != null && !_isLoadingBalance) ...[
                  const SizedBox(height: 4),
                  Text('${_fmt(_availableUnits!.toStringAsFixed(2))} ${s.units}',
                      style: TextStyle(fontSize: 11, color: txtH)),
                ],
              ])),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: orange.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(Icons.account_balance_wallet_outlined,
                    color: orange, size: 26),
              ),
            ]),
          ),
        ),

        // ── Scrollable form ──────────────────────────────────────────────────
        Expanded(
          child: Container(color: sheet,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Fund dropdown ─────────────────────────────────────────
                    _secLabel(s.selectFund, txtH),
                    const SizedBox(height: 10),
                    if (_isLoadingFunds)
                      Center(child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: CircularProgressIndicator(color: orange, strokeWidth: 2.5)))
                    else if (_fundsError.isNotEmpty)
                      _errBanner(_fundsError, s.retry, orange, border, onRetry: _loadFunds)
                    else
                      _dropdown(bg: inputBg, border: border,
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<Fund>(
                            value: _selectedFund, isExpanded: true,
                            dropdownColor: cardBg,
                            icon: Icon(Icons.keyboard_arrow_down_rounded, color: txtS),
                            items: _funds.map((f) => DropdownMenuItem<Fund>(
                              value: f,
                              child: Row(children: [
                                Container(width: 8, height: 8,
                                    decoration: BoxDecoration(
                                        color: f.status?.toLowerCase() == 'active'
                                            ? const Color(0xFF22C55E) : Colors.orange,
                                        shape: BoxShape.circle)),
                                const SizedBox(width: 10),
                                Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min, children: [
                                  Text(f.fundingName ?? s.noFunds,
                                      style: TextStyle(fontWeight: FontWeight.w600,
                                          fontSize: 14, color: txtP),
                                      overflow: TextOverflow.ellipsis),
                                  if (f.issuer != null)
                                    Text(f.issuer!, style: TextStyle(
                                        fontSize: 11, color: txtS)),
                                ])),
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

                    // ── Amount ────────────────────────────────────────────────
                    _secLabel(s.enterAmount, txtH),
                    const SizedBox(height: 10),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(color: inputBg,
                            borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(14),
                                bottomLeft: Radius.circular(14)),
                            border: Border.all(color: border)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCurrency,
                            dropdownColor: cardBg, isDense: true,
                            icon: Icon(Icons.expand_more, size: 18, color: txtS),
                            items: _currencies.map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c, style: TextStyle(
                                  fontWeight: FontWeight.w700, color: txtP)),
                            )).toList(),
                            onChanged: (v) => setState(() => _selectedCurrency = v!),
                          ),
                        ),
                      ),
                      Expanded(child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: TextStyle(fontSize: 18,
                            fontWeight: FontWeight.w800, color: txtP),
                        decoration: InputDecoration(
                          hintText: '0.00', hintStyle: TextStyle(color: txtH),
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

                    // ── Quick amounts ─────────────────────────────────────────
                    _secLabel(s.quickSelect, txtH),
                    const SizedBox(height: 10),
                    Row(
                      children: _quickAmounts.asMap().entries.map((e) {
                        final a = e.value;
                        return Expanded(child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _amountController.text = a['amount']!);
                          },
                          child: Container(
                            margin: EdgeInsets.only(
                                right: e.key < _quickAmounts.length - 1 ? 8 : 0),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: orange.withOpacity(dark ? 0.1 : 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: orange.withOpacity(0.3)),
                            ),
                            child: Column(children: [
                              Text(a['label']!, style: TextStyle(fontSize: 14,
                                  fontWeight: FontWeight.w800, color: orange)),
                              const SizedBox(height: 2),
                              Text('$_selectedCurrency ${_fmt(a['amount']!)}',
                                  style: TextStyle(fontSize: 9,
                                      color: orange.withOpacity(0.7))),
                            ]),
                          ),
                        ));
                      }).toList(),
                    ),

                    const SizedBox(height: 28),

                    // ── Banking details accordion ──────────────────────────────
                    GestureDetector(
                      onTap: _toggleBankingDetails,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: inputBg,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(14),
                            topRight: const Radius.circular(14),
                            bottomLeft: Radius.circular(_bankingDetailsOpen ? 0 : 14),
                            bottomRight: Radius.circular(_bankingDetailsOpen ? 0 : 14),
                          ),
                          border: Border.all(color: _bankingDetailsOpen
                              ? orange.withOpacity(0.5) : border),
                        ),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: orange.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10)),
                            child: Icon(Icons.account_balance_outlined,
                                color: orange, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.bankingDetails,
                                    style: TextStyle(fontSize: 14,
                                        fontWeight: FontWeight.w700, color: txtP)),
                                const SizedBox(height: 2),
                                Text(
                                  _bankingDetailsOpen ? s.tapToHide : s.tapToView,
                                  style: TextStyle(fontSize: 11, color: txtS),
                                ),
                              ])),
                          AnimatedRotation(
                            turns: _bankingDetailsOpen ? 0.5 : 0,
                            duration: const Duration(milliseconds: 280),
                            child: Icon(Icons.keyboard_arrow_down_rounded,
                                color: txtS, size: 22),
                          ),
                        ]),
                      ),
                    ),

                    // ── Banking details expand panel ───────────────────────────
                    SizeTransition(
                      sizeFactor: _accordionAnim,
                      child: Container(
                        decoration: BoxDecoration(
                          color: dark
                              ? const Color(0xFF0F1A10)
                              : const Color(0xFFF0FDF4),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(14),
                            bottomRight: Radius.circular(14),
                          ),
                          border: Border(
                            left: BorderSide(color: orange.withOpacity(0.5)),
                            right: BorderSide(color: orange.withOpacity(0.5)),
                            bottom: BorderSide(color: orange.withOpacity(0.5)),
                          ),
                        ),
                        child: _bank.isEmpty && _accountNo.isEmpty &&
                            _accountName.isEmpty && _branch.isEmpty
                        // ── No data saved ────────────────────────────────
                            ? Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(children: [
                            Icon(Icons.info_outline,
                                color: txtH, size: 18),
                            const SizedBox(width: 10),
                            Text(s.noBankingDetails,
                                style: TextStyle(color: txtH,
                                    fontSize: 13)),
                          ]),
                        )
                        // ── Show saved banking details ────────────────────
                            : Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          child: Column(children: [
                            _bankRow(Icons.account_balance_outlined,
                                s.bank, _bank.isNotEmpty ? _bank : s.notSet,
                                orange, txtP, txtS, border, dark),
                            _bankRow(Icons.credit_card_outlined,
                                s.accountNo, _accountNo.isNotEmpty ? _accountNo : s.notSet,
                                orange, txtP, txtS, border, dark),
                            _bankRow(Icons.badge_outlined,
                                s.accountName, _accountName.isNotEmpty ? _accountName : s.notSet,
                                orange, txtP, txtS, border, dark),
                            _bankRow(Icons.store_outlined,
                                s.branch, _branch.isNotEmpty ? _branch : s.notSet,
                                orange, txtP, txtS, border, dark,
                                last: true),
                          ]),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Submit button ─────────────────────────────────────────
                    GestureDetector(
                      onTap: _canWithdraw ? _processWithdrawal : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200), height: 56,
                        decoration: BoxDecoration(
                          gradient: _canWithdraw
                              ? LinearGradient(colors: [orange,
                            dark ? Colors.deepOrange : Colors.orange.shade700])
                              : LinearGradient(colors: [txtH, txtH]),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _canWithdraw
                              ? [BoxShadow(color: orange.withOpacity(0.35),
                              blurRadius: 14, offset: const Offset(0, 6))]
                              : [],
                        ),
                        child: Center(child: _isSubmitting
                            ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                            : Text(s.requestWithdrawal,
                            style: const TextStyle(color: Colors.white,
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

  // ── Banking detail row ─────────────────────────────────────────────────────
  Widget _bankRow(IconData icon, String label, String value,
      Color orange, Color txtP, Color txtS, Color border, bool dark,
      {bool last = false}) =>
      Container(
        margin: EdgeInsets.only(bottom: last ? 0 : 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF132013) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
                color: orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: orange, size: 15),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 11,
                color: txtS, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 14,
                fontWeight: FontWeight.w700, color: txtP),
                overflow: TextOverflow.ellipsis),
          ])),
        ]),
      );

  // ── Shared helpers ─────────────────────────────────────────────────────────
  Widget _secLabel(String t, Color c) => Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(t.toUpperCase(), style: TextStyle(fontSize: 11,
          fontWeight: FontWeight.w800, color: c, letterSpacing: 1.2)));

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
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(msg, style: const TextStyle(
              color: Colors.red, fontSize: 13))),
          GestureDetector(onTap: onRetry,
              child: Text(lbl, style: TextStyle(color: orange,
                  fontWeight: FontWeight.w700, fontSize: 13))),
        ]),
      );
}