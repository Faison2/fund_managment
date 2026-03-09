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
  final String depositFunds, addMoney, chooseFund,
      selectFund, enterAmount, quickSelect,
      paymentMethod, summary, fund, depositAmount,
      processingFee, totalAmount, depositNow,
      confirmDeposit, confirmDetails, cancel, confirm,
      depositInitiated, done, phone, amount, payment,
      failedLoadFunds, retry, noFunds, networkError,
      free, notSet;
  const _DS({
    required this.depositFunds,    required this.addMoney,
    required this.chooseFund,      required this.selectFund,
    required this.enterAmount,     required this.quickSelect,
    required this.paymentMethod,   required this.summary,
    required this.fund,            required this.depositAmount,
    required this.processingFee,   required this.totalAmount,
    required this.depositNow,      required this.confirmDeposit,
    required this.confirmDetails,  required this.cancel,
    required this.confirm,         required this.depositInitiated,
    required this.done,            required this.phone,
    required this.amount,          required this.payment,
    required this.failedLoadFunds, required this.retry,
    required this.noFunds,         required this.networkError,
    required this.free,            required this.notSet,
  });
}

const _dsEn = _DS(
  depositFunds:   'Deposit Funds',
  addMoney:       'Add Money to Your Account',
  chooseFund:     'Choose fund, amount and payment method',
  selectFund:     'Select Fund',
  enterAmount:    'Enter Amount',
  quickSelect:    'Quick Select',
  paymentMethod:  'Payment Method',
  summary:        'Summary',
  fund:           'Fund',
  depositAmount:  'Deposit Amount',
  processingFee:  'Processing Fee',
  totalAmount:    'Total Amount',
  depositNow:     'Deposit Now',
  confirmDeposit: 'Confirm Deposit',
  confirmDetails: 'Please confirm your deposit details.',
  cancel:         'Cancel',
  confirm:        'Confirm',
  depositInitiated: 'Deposit Initiated!',
  done:           'Done',
  phone:          'Phone',
  amount:         'Amount',
  payment:        'Payment',
  failedLoadFunds:'Failed to load funds',
  retry:          'Retry',
  noFunds:        'No funds available',
  networkError:   'Network error',
  free:           'Free',
  notSet:         'Not set',
);

const _dsSw = _DS(
  depositFunds:   'Weka Fedha',
  addMoney:       'Ongeza Pesa kwenye Akaunti Yako',
  chooseFund:     'Chagua fedha, kiasi na njia ya malipo',
  selectFund:     'Chagua Fedha',
  enterAmount:    'Ingiza Kiasi',
  quickSelect:    'Chaguo la Haraka',
  paymentMethod:  'Njia ya Malipo',
  summary:        'Muhtasari',
  fund:           'Fedha',
  depositAmount:  'Kiasi cha Amana',
  processingFee:  'Ada ya Usindikaji',
  totalAmount:    'Jumla ya Kiasi',
  depositNow:     'Weka Sasa',
  confirmDeposit: 'Thibitisha Amana',
  confirmDetails: 'Tafadhali thibitisha maelezo ya amana yako.',
  cancel:         'Ghairi',
  confirm:        'Thibitisha',
  depositInitiated: 'Amana Imeanzishwa!',
  done:           'Imekamilika',
  phone:          'Simu',
  amount:         'Kiasi',
  payment:        'Malipo',
  failedLoadFunds:'Imeshindwa kupakia fedha',
  retry:          'Jaribu Tena',
  noFunds:        'Hakuna fedha zinazopatikana',
  networkError:   'Hitilafu ya mtandao',
  free:           'Bure',
  notSet:         'Haijawekwa',
);

// ── DepositPage ───────────────────────────────────────────────────────────────
class DepositPage extends StatefulWidget {
  const DepositPage({Key? key}) : super(key: key);

  @override
  State<DepositPage> createState() => _DepositPageState();
}

class _DepositPageState extends State<DepositPage> {
  final TextEditingController _amountController = TextEditingController();
  String _selectedPaymentMethod = 'Standard Bank ****1234';
  String _selectedCurrency = 'TZS';

  String _cdsNumber   = '';
  String _phoneNumber = '';

  List<Fund> _funds        = [];
  Fund?      _selectedFund;
  bool       _isLoadingFunds = true;
  String     _fundsError     = '';
  bool       _isSubmitting   = false;

  final List<String> _paymentMethods = [
    'Standard Bank ****1234',
    'Visa Card ****5678',
    'M-Pesa +255 71 234 5678',
  ];
  final List<String> _currencies = ['TZS', 'USD'];
  final List<Map<String, String>> _quickAmounts = [
    {'amount': '1000',  'label': '1K'},
    {'amount': '5000',  'label': '5K'},
    {'amount': '10000', 'label': '10K'},
    {'amount': '50000', 'label': '50K'},
  ];

  // ── Theme helpers (captured in build — never call watch inside callbacks) ──
  bool  get _dark => context.watch<ThemeProvider>().isDark;
  _DS   get _s    => context.watch<LocaleProvider>().isSwahili ? _dsSw : _dsEn;

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
      _cdsNumber   = prefs.getString('cdsNumber')    ?? '';
      _phoneNumber = prefs.getString('user_mobile')  ?? '';
    });
  }

  Future<void> _loadFunds() async {
    try {
      setState(() { _isLoadingFunds = true; _fundsError = ''; });
      final funds = await FundsRepository().fetchFunds();
      setState(() {
        _funds        = funds;
        _selectedFund = funds.isNotEmpty ? funds.first : null;
        _isLoadingFunds = false;
      });
    } catch (_) {
      setState(() {
        _fundsError     = _s.failedLoadFunds;
        _isLoadingFunds = false;
      });
    }
  }

  // ── API ───────────────────────────────────────────────────────────────────
  Future<void> _processDeposit() async {
    if (_amountController.text.isEmpty || _selectedFund == null) return;
    final confirmed = await _showConfirmationDialog();
    if (!confirmed) return;

    setState(() => _isSubmitting = true);
    try {
      final response = await http.post(
        Uri.parse('https://portaluat.tsl.co.tz/FMSAPI/home/Deposit'),
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
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        _showSuccessDialog(data['statusDesc'] ?? '${_s.depositInitiated}');
      } else {
        _showErrorSnackbar(data['statusDesc'] ?? '${_s.depositFunds} failed.');
      }
    } catch (e) {
      _showErrorSnackbar('${_s.networkError}: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────
  Future<bool> _showConfirmationDialog() async {
    // Capture theme values — dialogs build outside the normal widget tree
    final dark    = _dark;
    final s       = _s;
    final cardBg  = dark ? const Color(0xFF132013) : Colors.white;
    final txtP    = dark ? const Color(0xFFE8F5E9) : Colors.black87;
    final txtS    = dark ? const Color(0xFF81A884)  : Colors.grey.shade600;
    final border  = dark ? const Color(0xFF1E3320)  : Colors.grey.shade200;
    final green   = dark ? const Color(0xFF4ADE80)  : Colors.green;

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
                  Text(s.confirmDeposit, style: TextStyle(fontSize: 17,
                      fontWeight: FontWeight.w800, color: txtP)),
                ]),
                const SizedBox(height: 20),
                _confirmRowStyled(s.fund,    _selectedFund?.fundingName ?? '—', txtP, txtS, border),
                _confirmRowStyled(s.amount,  '$_selectedCurrency ${_formatAmount(_amountController.text)}', txtP, txtS, border),
                _confirmRowStyled(s.payment, _selectedPaymentMethod, txtP, txtS, border),
                _confirmRowStyled(s.phone,   _phoneNumber.isNotEmpty ? _phoneNumber : s.notSet, txtP, txtS, border),
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
                        border: Border.all(color: border, width: 1.5),
                      ),
                      child: Center(child: Text(s.cancel,
                          style: TextStyle(color: txtS, fontWeight: FontWeight.w600))),
                    ),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [green, green.withOpacity(0.75)]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: green.withOpacity(0.35),
                            blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Center(child: Text(s.confirm,
                          style: const TextStyle(color: Colors.white,
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

  Widget _confirmRowStyled(String label, String value,
      Color txtP, Color txtS, Color border) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        SizedBox(width: 72, child: Text(label,
            style: TextStyle(fontSize: 12, color: txtS,
                fontWeight: FontWeight.w500))),
        Expanded(child: Text(value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                color: txtP), overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  void _showSuccessDialog(String message) {
    final dark   = _dark;
    final s      = _s;
    final cardBg = dark ? const Color(0xFF132013) : Colors.white;
    final txtP   = dark ? const Color(0xFFE8F5E9) : Colors.black87;
    final txtS   = dark ? const Color(0xFF81A884)  : Colors.grey.shade600;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 72, height: 72,
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF388E3C)]),
                  shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 20),
            Text(s.depositInitiated,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                    color: txtP)),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: txtS, height: 1.5)),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity,
              child: GestureDetector(
                onTap: () { Navigator.pop(context); Navigator.pop(context); },
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF388E3C)]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.35),
                        blurRadius: 12, offset: const Offset(0, 5))],
                  ),
                  child: Center(child: Text(s.done,
                      style: const TextStyle(color: Colors.white,
                          fontSize: 15, fontWeight: FontWeight.w700))),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 4),
    ));
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  IconData _paymentIcon(String m) {
    if (m.contains('Bank'))              return Icons.account_balance_rounded;
    if (m.contains('Card') || m.contains('Visa')) return Icons.credit_card_rounded;
    if (m.contains('Pesa') || m.contains('Cash')) return Icons.phone_android_rounded;
    return Icons.payment_rounded;
  }

  Color _paymentColor(String m) {
    if (m.contains('Bank'))              return const Color(0xFF3B82F6);
    if (m.contains('Card') || m.contains('Visa')) return const Color(0xFF8B5CF6);
    if (m.contains('Pesa') || m.contains('Cash')) return const Color(0xFF22C55E);
    return Colors.grey;
  }

  String _formatAmount(String amount) {
    if (amount.isEmpty) return '0.00';
    final value = double.tryParse(amount) ?? 0;
    return value.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    context.watch<LocaleProvider>();

    // Capture all theme tokens as locals
    final dark    = _dark;
    final s       = _s;
    final bg      = dark ? const Color(0xFF0B1A0C) : const Color(0xFFB8E6D3);
    final cardBg  = dark ? const Color(0xFF132013) : Colors.white;
    final sheet   = dark ? const Color(0xFF111D12) : Colors.white;
    final border  = dark ? const Color(0xFF1E3320) : const Color(0xFFE5E7EB);
    final txtP    = dark ? const Color(0xFFE8F5E9) : Colors.black87;
    final txtS    = dark ? const Color(0xFF81A884)  : Colors.black54;
    final txtH    = dark ? const Color(0xFF4A7A4D)  : Colors.grey.shade400;
    final green   = dark ? const Color(0xFF4ADE80)  : const Color(0xFF15803D);
    final teal    = dark ? const Color(0xFF38BDF8)  : const Color(0xFF2E7D99);
    final inputBg = dark ? const Color(0xFF132013)  : const Color(0xFFF9FAFB);
    final summaryBg = dark ? const Color(0xFF0F1A10) : const Color(0xFFF9FAFB);

    return Scaffold(
      backgroundColor: bg,
      body: Column(children: [

        // ── Gradient header ──────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            gradient: dark
                ? const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF0B1A0C), Color(0xFF132013), Color(0xFF09100A)])
                : const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)]),
          ),
          child: SafeArea(bottom: false, child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.depositFunds, style: const TextStyle(color: Colors.white,
                    fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                const SizedBox(height: 2),
                Text(s.chooseFund,
                    style: TextStyle(color: Colors.white.withOpacity(0.65),
                        fontSize: 12)),
              ])),
            ]),
          )),
        ),

        // ── Scrollable form sheet ────────────────────────────────────────────
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: sheet,
              // borderRadius: const BorderRadius.only(
              //     topLeft: Radius.circular(2), topRight: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // ── Fund selection ─────────────────────────────────────────
                _sectionLabel(s.selectFund, txtH),
                const SizedBox(height: 10),
                if (_isLoadingFunds)
                  Center(child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(color: green, strokeWidth: 2.5),
                  ))
                else if (_fundsError.isNotEmpty)
                  _errorBanner(_fundsError, s.retry, green, dark)
                else
                  _styledDropdown(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Fund>(
                        value: _selectedFund,
                        isExpanded: true,
                        dropdownColor: cardBg,
                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: txtS),
                        items: _funds.map((fund) => DropdownMenuItem<Fund>(
                          value: fund,
                          child: Row(children: [
                            Container(width: 8, height: 8,
                                decoration: BoxDecoration(
                                    color: (fund.status?.toLowerCase() == 'active')
                                        ? const Color(0xFF22C55E) : Colors.orange,
                                    shape: BoxShape.circle)),
                            const SizedBox(width: 10),
                            Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min, children: [
                              Text(fund.fundingName ?? s.noFunds,
                                  style: TextStyle(fontWeight: FontWeight.w600,
                                      fontSize: 14, color: txtP),
                                  overflow: TextOverflow.ellipsis),
                              if (fund.issuer != null)
                                Text(fund.issuer!,
                                    style: TextStyle(fontSize: 11, color: txtS)),
                            ])),
                          ]),
                        )).toList(),
                        onChanged: (f) => setState(() => _selectedFund = f),
                      ),
                    ),
                    bg: inputBg, border: border,
                  ),

                const SizedBox(height: 24),

                // ── Amount ─────────────────────────────────────────────────
                _sectionLabel(s.enterAmount, txtH),
                const SizedBox(height: 10),
                Row(children: [
                  // Currency picker
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14),
                          bottomLeft: Radius.circular(14)),
                      border: Border.all(color: border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCurrency,
                        dropdownColor: cardBg,
                        isDense: true,
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
                  // Amount field
                  Expanded(child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(fontSize: 18,
                        fontWeight: FontWeight.w800, color: txtP),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: TextStyle(color: txtH),
                      filled: true, fillColor: inputBg,
                      border: OutlineInputBorder(
                        borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(14),
                            bottomRight: Radius.circular(14)),
                        borderSide: BorderSide(color: border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(14),
                            bottomRight: Radius.circular(14)),
                        borderSide: BorderSide(color: border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(14),
                            bottomRight: Radius.circular(14)),
                        borderSide: BorderSide(color: green, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                  )),
                ]),

                const SizedBox(height: 20),

                // ── Quick amounts ──────────────────────────────────────────
                _sectionLabel(s.quickSelect, txtH),
                const SizedBox(height: 10),
                Row(
                  children: _quickAmounts.asMap().entries.map((e) {
                    final amt = e.value;
                    return Expanded(child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _amountController.text = amt['amount']!);
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
                          Text(amt['label']!,
                              style: TextStyle(fontSize: 14,
                                  fontWeight: FontWeight.w800, color: green)),
                          const SizedBox(height: 2),
                          Text('$_selectedCurrency ${_formatAmount(amt['amount']!)}',
                              style: TextStyle(fontSize: 9, color: green.withOpacity(0.7))),
                        ]),
                      ),
                    ));
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // ── Payment method ─────────────────────────────────────────
                _sectionLabel(s.paymentMethod, txtH),
                const SizedBox(height: 10),
                _styledDropdown(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedPaymentMethod,
                      isExpanded: true,
                      dropdownColor: cardBg,
                      icon: Icon(Icons.keyboard_arrow_down_rounded, color: txtS),
                      items: _paymentMethods.map((m) => DropdownMenuItem(
                        value: m,
                        child: Row(children: [
                          Container(
                            width: 34, height: 34,
                            decoration: BoxDecoration(
                              color: _paymentColor(m).withOpacity(dark ? 0.15 : 0.08),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(_paymentIcon(m),
                                color: _paymentColor(m), size: 18),
                          ),
                          const SizedBox(width: 12),
                          Text(m, style: TextStyle(fontSize: 14, color: txtP)),
                        ]),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedPaymentMethod = v!),
                    ),
                  ),
                  bg: inputBg, border: border,
                ),

                const SizedBox(height: 24),

                // ── Summary card ───────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: summaryBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: border),
                  ),
                  child: Column(children: [
                    _summaryRow(s.fund,
                        _selectedFund?.fundingName ?? '—', txtP, txtS),
                    _summaryDivider(border),
                    _summaryRow(s.depositAmount,
                        '$_selectedCurrency ${_formatAmount(_amountController.text)}',
                        txtP, txtS),
                    _summaryDivider(border),
                    _summaryRow(s.processingFee,
                        s.free, txtP, txtS),
                    _summaryDivider(border),
                    _summaryRow(s.totalAmount,
                        '$_selectedCurrency ${_formatAmount(_amountController.text)}',
                        green, txtS, bold: true),
                  ]),
                ),

                const SizedBox(height: 28),

                // ── Submit button ──────────────────────────────────────────
                GestureDetector(
                  onTap: (_amountController.text.isEmpty ||
                      _selectedFund == null || _isSubmitting)
                      ? null
                      : _processDeposit,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: (_amountController.text.isEmpty || _selectedFund == null)
                          ? LinearGradient(colors: [txtH, txtH])
                          : LinearGradient(colors: [
                        green, dark ? const Color(0xFF16A34A) : const Color(0xFF15803D)
                      ]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: (_amountController.text.isEmpty || _selectedFund == null)
                          ? []
                          : [BoxShadow(color: green.withOpacity(0.35),
                          blurRadius: 14, offset: const Offset(0, 6))],
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

  // ── Shared widgets ─────────────────────────────────────────────────────────
  Widget _sectionLabel(String text, Color color) => Padding(
    padding: const EdgeInsets.only(left: 2),
    child: Text(text.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
            color: color, letterSpacing: 1.2)),
  );

  Widget _styledDropdown({
    required Widget child,
    required Color bg,
    required Color border,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: child,
      );

  Widget _errorBanner(String msg, String retryLabel, Color green, bool dark) =>
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
          Expanded(child: Text(msg,
              style: const TextStyle(color: Colors.red, fontSize: 13))),
          GestureDetector(onTap: _loadFunds,
              child: Text(retryLabel,
                  style: TextStyle(color: green, fontWeight: FontWeight.w700,
                      fontSize: 13))),
        ]),
      );

  Widget _summaryRow(String label, String value,
      Color valueColor, Color labelColor, {bool bold = false}) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: bold ? 15 : 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: labelColor)),
        Text(value, style: TextStyle(fontSize: bold ? 15 : 13,
            fontWeight: FontWeight.w700, color: valueColor)),
      ]);

  Widget _summaryDivider(Color border) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Divider(height: 1, color: border),
  );
}