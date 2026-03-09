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
class _DS {
  final String depositFunds, chooseFund,
      selectFund, enterAmount, quickSelect,
      summary, fund, depositAmount,
      processingFee, totalAmount, depositNow,
      confirmDeposit, confirmDetails, cancel, confirm,
      depositInitiated, done, phone, amount,
      failedLoadFunds, failedLoadUser, retry, noFunds, networkError,
      free, notSet, loadingUser, bank, accountNo, accountName, branch;
  const _DS({
    required this.depositFunds,    required this.chooseFund,
    required this.selectFund,      required this.enterAmount,
    required this.quickSelect,     required this.summary,
    required this.fund,            required this.depositAmount,
    required this.processingFee,   required this.totalAmount,
    required this.depositNow,      required this.confirmDeposit,
    required this.confirmDetails,  required this.cancel,
    required this.confirm,         required this.depositInitiated,
    required this.done,            required this.phone,
    required this.amount,          required this.failedLoadFunds,
    required this.failedLoadUser,  required this.retry,
    required this.noFunds,         required this.networkError,
    required this.free,            required this.notSet,
    required this.loadingUser,     required this.bank,
    required this.accountNo,       required this.accountName,
    required this.branch,
  });
}

const _dsEn = _DS(
  depositFunds:    'Invest Funds',
  chooseFund:      'Choose fund and amount to deposit',
  selectFund:      'Select Fund',
  enterAmount:     'Enter Amount',
  quickSelect:     'Quick Select',
  summary:         'Summary',
  fund:            'Fund',
  depositAmount:   'Invest Amount',
  processingFee:   'Processing Fee',
  totalAmount:     'Total Amount',
  depositNow:      'Invest Now',
  confirmDeposit:  'Confirm Deposit',
  confirmDetails:  'Please confirm your investment details.',
  cancel:          'Cancel',
  confirm:         'Confirm',
  depositInitiated:'Deposit Initiated!',
  done:            'Done',
  phone:           'Phone',
  amount:          'Amount',
  failedLoadFunds: 'Failed to load funds',
  failedLoadUser:  'Failed to load user details',
  retry:           'Retry',
  noFunds:         'No funds available',
  networkError:    'Network error',
  free:            'Free',
  notSet:          'Not set',
  loadingUser:     'Loading account details...',
  bank:            'Bank',
  accountNo:       'Account No',
  accountName:     'Account Name',
  branch:          'Branch',
);

const _dsSw = _DS(
  depositFunds:    'Weka Fedha',
  chooseFund:      'Chagua fedha na kiasi cha kuweka',
  selectFund:      'Chagua Fedha',
  enterAmount:     'Ingiza Kiasi',
  quickSelect:     'Chaguo la Haraka',
  summary:         'Muhtasari',
  fund:            'Fedha',
  depositAmount:   'Kiasi cha Amana',
  processingFee:   'Ada ya Usindikaji',
  totalAmount:     'Jumla ya Kiasi',
  depositNow:      'Weka Sasa',
  confirmDeposit:  'Thibitisha Amana',
  confirmDetails:  'Tafadhali thibitisha maelezo ya amana yako.',
  cancel:          'Ghairi',
  confirm:         'Thibitisha',
  depositInitiated:'Amana Imeanzishwa!',
  done:            'Imekamilika',
  phone:           'Simu',
  amount:          'Kiasi',
  failedLoadFunds: 'Imeshindwa kupakia fedha',
  failedLoadUser:  'Imeshindwa kupakia maelezo ya mtumiaji',
  retry:           'Jaribu Tena',
  noFunds:         'Hakuna fedha zinazopatikana',
  networkError:    'Hitilafu ya mtandao',
  free:            'Bure',
  notSet:          'Haijawekwa',
  loadingUser:     'Inapakia maelezo ya akaunti...',
  bank:            'Benki',
  accountNo:       'Nambari ya Akaunti',
  accountName:     'Jina la Akaunti',
  branch:          'Tawi',
);

// ── DepositPage ───────────────────────────────────────────────────────────────
class DepositPage extends StatefulWidget {
  const DepositPage({Key? key}) : super(key: key);

  @override
  State<DepositPage> createState() => _DepositPageState();
}

class _DepositPageState extends State<DepositPage> {
  final TextEditingController _amountController  = TextEditingController();
  final TextEditingController _mobileController  = TextEditingController();
  String _selectedCurrency = 'TZS';

  // ── User data ──────────────────────────────────────────────────────────────
  String _cdsNumber   = '';
  String _names       = '';
  String _email       = '';
  String _mobile      = '';
  String _address     = '';
  String _bank        = '';
  String _accountNo   = '';
  String _accountName = '';
  String _branch      = '';
  bool   _isLoadingUser = true;
  String _userError     = '';

  // ── Funds ──────────────────────────────────────────────────────────────────
  List<Fund> _funds         = [];
  Fund?      _selectedFund;
  bool       _isLoadingFunds = true;
  String     _fundsError     = '';

  bool _isSubmitting = false;

  final List<String> _currencies = ['TZS', 'USD'];
  final List<Map<String, String>> _quickAmounts = [
    {'amount': '1000',  'label': '1K'},
    {'amount': '5000',  'label': '5K'},
    {'amount': '10000', 'label': '10K'},
    {'amount': '50000', 'label': '50K'},
  ];

  bool get _dark => context.watch<ThemeProvider>().isDark;
  _DS  get _s    => context.watch<LocaleProvider>().isSwahili ? _dsSw : _dsEn;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() => setState(() {}));
    _mobileController.addListener(() => setState(() {}));
    _bootstrap();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    _cdsNumber  = prefs.getString('cdsNumber') ?? '';
    _applyCached(prefs);
    await Future.wait([_fetchUser(), _loadFunds()]);
  }

  void _applyCached(SharedPreferences p) {
    setState(() {
      _names       = p.getString('user_names')       ?? '';
      _email       = p.getString('user_email')       ?? '';
      _mobile      = p.getString('user_mobile')      ?? '';
      _address     = p.getString('user_address')     ?? '';
      _bank        = p.getString('user_bank')        ?? '';
      _accountNo   = p.getString('user_accountNo')   ?? '';
      _accountName = p.getString('user_accountName') ?? '';
      _branch      = p.getString('user_branch')      ?? '';
    });
    if (_mobile.isNotEmpty) _mobileController.text = _mobile;
  }

  Future<void> _fetchUser() async {
    if (_cdsNumber.isEmpty) {
      setState(() { _userError = _s.notSet; _isLoadingUser = false; });
      return;
    }
    try {
      setState(() { _isLoadingUser = true; _userError = ''; });

      final res = await http.post(
        Uri.parse('https://portaluat.tsl.co.tz/FMSAPI/Home/UserBasicDetails'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'CDSNumber': _cdsNumber}),
      ).timeout(const Duration(seconds: 12));

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200 && body['status'] == 'success') {
        final d = Map<String, dynamic>.from(body['data'] as Map);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_names',       d['Names']       ?? '');
        await prefs.setString('user_email',        d['Email']       ?? '');
        await prefs.setString('user_mobile',       d['Mobile']      ?? '');
        await prefs.setString('user_address',      d['Add_1']       ?? '');
        await prefs.setString('user_bank',         d['Bank']        ?? '');
        await prefs.setString('user_accountNo',    d['AccountNo']   ?? '');
        await prefs.setString('user_accountName',  d['AccountName'] ?? '');
        await prefs.setString('user_branch',       d['Branch']      ?? '');

        final mobile = d['Mobile'] ?? '';
        setState(() {
          _names       = d['Names']       ?? '';
          _email       = d['Email']       ?? '';
          _mobile      = mobile;
          _address     = d['Add_1']       ?? '';
          _bank        = d['Bank']        ?? '';
          _accountNo   = d['AccountNo']   ?? '';
          _accountName = d['AccountName'] ?? '';
          _branch      = d['Branch']      ?? '';
          _isLoadingUser = false;
        });
        // Set controller AFTER setState
        if (mobile.isNotEmpty) _mobileController.text = mobile;
      } else {
        setState(() {
          _userError     = body['statusDesc'] ?? _s.failedLoadUser;
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      setState(() {
        _userError     = '${_s.networkError}: $e';
        _isLoadingUser = false;
      });
    }
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
    } catch (_) {
      setState(() { _fundsError = _s.failedLoadFunds; _isLoadingFunds = false; });
    }
  }

  // ── Deposit API ────────────────────────────────────────────────────────────
  Future<void> _processDeposit() async {
    if (_amountController.text.isEmpty || _selectedFund == null) return;
    if (_mobileController.text.trim().isEmpty) {
      _snackErr('Please enter a phone number');
      return;
    }
    final ok = await _showConfirmation();
    if (!ok) return;

    setState(() => _isSubmitting = true);
    try {
      final res = await http.post(
        Uri.parse('https://portaluat.tsl.co.tz/FMSAPI/home/Deposit'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'APIUsername': 'User2',
          'APIPassword': 'CBZ1234#2',
          'cdsNumber':   _cdsNumber,
          'PhoneNumber': _mobileController.text.trim(),   // ← correct field name
          'Fund':        _selectedFund!.fundingName ?? '',
          'Amount':      _amountController.text,
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['status'] == 'success') {
        // Persist edited mobile for next visit
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_mobile', _mobileController.text.trim());
        setState(() => _mobile = _mobileController.text.trim());
        _showSuccess(data['statusDesc'] ?? _s.depositInitiated);
      } else {
        _snackErr(data['statusDesc'] ?? '${_s.depositFunds} failed.');
      }
    } catch (e) {
      _snackErr('${_s.networkError}: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  // ── Confirmation dialog ────────────────────────────────────────────────────
  Future<bool> _showConfirmation() async {
    final dark   = Provider.of<ThemeProvider>(context, listen: false).isDark;
    final s      = Provider.of<LocaleProvider>(context, listen: false).isSwahili ? _dsSw : _dsEn;
    final mobile = _mobileController.text.trim();
    final fund   = _selectedFund?.fundingName ?? '—';
    final amt    = '$_selectedCurrency ${_fmt(_amountController.text)}';
    final bank   = _bank;

    final cardBg = dark ? const Color(0xFF132013) : Colors.white;
    final txtP   = dark ? const Color(0xFFE8F5E9) : Colors.black87;
    final txtS   = dark ? const Color(0xFF81A884)  : Colors.grey.shade600;
    final border = dark ? const Color(0xFF1E3320)  : Colors.grey.shade200;
    final green  = dark ? const Color(0xFF4ADE80)  : Colors.green;

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
                      decoration: BoxDecoration(color: green.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.receipt_long_outlined, color: green, size: 20)),
                  const SizedBox(width: 12),
                  Flexible(child: Text(s.confirmDeposit, style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800, color: txtP))),
                ]),
                const SizedBox(height: 20),
                _dRow(s.fund,   fund,  txtP, txtS, border),
                _dRow(s.amount, amt,   txtP, txtS, border),
                _dRow(s.phone,  mobile.isNotEmpty ? mobile : s.notSet, txtP, txtS, border),
                _dRow(s.bank,   bank.isNotEmpty   ? bank   : s.notSet, txtP, txtS, border),
                const SizedBox(height: 12),
                Text(s.confirmDetails,
                    style: TextStyle(color: txtS, fontSize: 12, height: 1.4)),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: Container(height: 46,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: border, width: 1.5)),
                        child: Center(child: Text(s.cancel, style: TextStyle(
                            color: txtS, fontWeight: FontWeight.w600)))),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Container(height: 46,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [green, green.withOpacity(0.75)]),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: green.withOpacity(0.35),
                              blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Center(child: Text(s.confirm, style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700)))),
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

  // ── Success dialog ─────────────────────────────────────────────────────────
  void _showSuccess(String msg) {
    final dark   = Provider.of<ThemeProvider>(context, listen: false).isDark;
    final s      = Provider.of<LocaleProvider>(context, listen: false).isSwahili ? _dsSw : _dsEn;
    final cardBg = dark ? const Color(0xFF132013) : Colors.white;
    final txtP   = dark ? const Color(0xFFE8F5E9) : Colors.black87;
    final txtS   = dark ? const Color(0xFF81A884)  : Colors.grey.shade600;

    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 72, height: 72,
                decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF388E3C)]),
                    shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 36)),
            const SizedBox(height: 20),
            Text(s.depositInitiated, style: TextStyle(fontSize: 18,
                fontWeight: FontWeight.w800, color: txtP)),
            const SizedBox(height: 10),
            Text(msg, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: txtS, height: 1.5)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () { Navigator.pop(context); Navigator.pop(context); },
              child: Container(width: double.infinity, height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF388E3C)]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.35),
                        blurRadius: 12, offset: const Offset(0, 5))],
                  ),
                  child: Center(child: Text(s.done, style: const TextStyle(
                      color: Colors.white, fontSize: 15,
                      fontWeight: FontWeight.w700)))),
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

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    context.watch<LocaleProvider>();

    final dark      = _dark;  final s = _s;
    final bg        = dark ? const Color(0xFF0B1A0C) : const Color(0xFFB8E6D3);
    final cardBg    = dark ? const Color(0xFF132013) : Colors.white;
    final sheet     = dark ? const Color(0xFF111D12) : Colors.white;
    final border    = dark ? const Color(0xFF1E3320) : const Color(0xFFE5E7EB);
    final txtP      = dark ? const Color(0xFFE8F5E9) : Colors.black87;
    final txtS      = dark ? const Color(0xFF81A884)  : Colors.black54;
    final txtH      = dark ? const Color(0xFF4A7A4D)  : Colors.grey.shade400;
    final green     = dark ? const Color(0xFF4ADE80)  : const Color(0xFF15803D);
    final inputBg   = dark ? const Color(0xFF132013)  : const Color(0xFFF9FAFB);
    final summaryBg = dark ? const Color(0xFF0F1A10)  : const Color(0xFFF9FAFB);

    final bool canSubmit = _amountController.text.isNotEmpty &&
        _selectedFund != null &&
        _mobileController.text.trim().isNotEmpty &&
        !_isSubmitting;

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
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 18)),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.depositFunds, style: const TextStyle(color: Colors.white,
                        fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                    const SizedBox(height: 2),
                    Text(s.chooseFund, style: TextStyle(
                        color: Colors.white.withOpacity(0.65), fontSize: 12)),
                  ])),
            ]),
          )),
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
                          child: CircularProgressIndicator(color: green, strokeWidth: 2.5)))
                    else if (_fundsError.isNotEmpty)
                      _errBanner(_fundsError, s.retry, green, border, onRetry: _loadFunds)
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
                            onChanged: (f) => setState(() => _selectedFund = f),
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // ── Phone number (editable, pre-filled from API) ──────────
                    _secLabel(s.phone, txtH),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: inputBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: border),
                      ),
                      child: Row(children: [
                        Icon(Icons.phone_outlined, color: green, size: 20),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: TextStyle(fontSize: 15,
                              fontWeight: FontWeight.w600, color: txtP),
                          decoration: InputDecoration(
                            hintText: s.notSet,
                            hintStyle: TextStyle(color: txtH),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        )),
                      ]),
                    ),

                    const SizedBox(height: 24),

                    // ── Amount ────────────────────────────────────────────────
                    _secLabel(s.enterAmount, txtH),
                    const SizedBox(height: 10),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
                          border: OutlineInputBorder(borderSide: BorderSide(color: border),
                              borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(14),
                                  bottomRight: Radius.circular(14))),
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: border),
                              borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(14),
                                  bottomRight: Radius.circular(14))),
                          focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: green, width: 2),
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
                              color: green.withOpacity(dark ? 0.1 : 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: green.withOpacity(0.3)),
                            ),
                            child: Column(children: [
                              Text(a['label']!, style: TextStyle(fontSize: 14,
                                  fontWeight: FontWeight.w800, color: green)),
                              const SizedBox(height: 2),
                              Text('$_selectedCurrency ${_fmt(a['amount']!)}',
                                  style: TextStyle(fontSize: 9,
                                      color: green.withOpacity(0.7))),
                            ]),
                          ),
                        ));
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // ── Summary ───────────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: summaryBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: border)),
                      child: Column(children: [
                        _sRow(s.fund, _selectedFund?.fundingName ?? '—', txtP, txtS),
                        _sDiv(border),
                        _sRow(s.phone,
                            _mobileController.text.isNotEmpty ? _mobileController.text : s.notSet,
                            txtP, txtS),
                        _sDiv(border),
                        _sRow(s.depositAmount,
                            '$_selectedCurrency ${_fmt(_amountController.text)}', txtP, txtS),
                        _sDiv(border),
                        _sRow(s.processingFee, s.free, txtP, txtS),
                        _sDiv(border),
                        _sRow(s.totalAmount,
                            '$_selectedCurrency ${_fmt(_amountController.text)}',
                            green, txtS, bold: true),
                      ]),
                    ),

                    const SizedBox(height: 28),

                    // ── Submit button ─────────────────────────────────────────
                    GestureDetector(
                      onTap: canSubmit ? _processDeposit : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200), height: 56,
                        decoration: BoxDecoration(
                          gradient: canSubmit
                              ? LinearGradient(colors: [green,
                            dark ? const Color(0xFF16A34A) : const Color(0xFF15803D)])
                              : LinearGradient(colors: [txtH, txtH]),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: canSubmit
                              ? [BoxShadow(color: green.withOpacity(0.35),
                              blurRadius: 14, offset: const Offset(0, 6))]
                              : [],
                        ),
                        child: Center(child: _isSubmitting
                            ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                            : Text(s.depositNow, style: const TextStyle(
                            color: Colors.white, fontSize: 16,
                            fontWeight: FontWeight.w800, letterSpacing: 0.3))),
                      ),
                    ),
                  ]),
            ),
          ),
        ),
      ]),
    );
  }

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

  Widget _errBanner(String msg, String lbl, Color green, Color border,
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
              child: Text(lbl, style: TextStyle(color: green,
                  fontWeight: FontWeight.w700, fontSize: 13))),
        ]),
      );

  Widget _sRow(String l, String v, Color vc, Color lc, {bool bold = false}) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(l, style: TextStyle(fontSize: bold ? 15 : 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: lc)),
        Text(v, style: TextStyle(fontSize: bold ? 15 : 13,
            fontWeight: FontWeight.w700, color: vc)),
      ]);

  Widget _sDiv(Color c) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Divider(height: 1, color: c));
}