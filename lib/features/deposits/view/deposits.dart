import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../funds/model/model.dart';
import '../../funds/repository/repository.dart';

class DepositPage extends StatefulWidget {
  const DepositPage({Key? key}) : super(key: key);

  @override
  State<DepositPage> createState() => _DepositPageState();
}

class _DepositPageState extends State<DepositPage> {
  final TextEditingController _amountController = TextEditingController();
  String _selectedPaymentMethod = 'Standard Bank ****1234';
  String _selectedCurrency = 'TSZ';

  // ── User data from SharedPreferences ──────────────────────────────────────
  String _cdsNumber = '';
  String _phoneNumber = '';

  // ── Fund selection ─────────────────────────────────────────────────────────
  List<Fund> _funds = [];
  Fund? _selectedFund;
  bool _isLoadingFunds = true;
  String _fundsError = '';

  // ── Deposit state ──────────────────────────────────────────────────────────
  bool _isSubmitting = false;

  final List<String> _paymentMethods = [
    'Standard Bank ****1234',
    'Visa Card ****5678',
    'EcoCash +263 77 123 4567',
  ];

  final List<String> _currencies = ['TSZ', 'USD', 'ZWL'];

  final List<Map<String, String>> _quickAmounts = [
    {'amount': '1000', 'label': '1K'},
    {'amount': '5000', 'label': '5K'},
    {'amount': '10000', 'label': '10K'},
    {'amount': '50000', 'label': '50K'},
  ];

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
      _cdsNumber = prefs.getString('cdsNumber') ?? '';
      _phoneNumber = prefs.getString('user_mobile') ?? '';
    });
  }

  Future<void> _loadFunds() async {
    try {
      setState(() {
        _isLoadingFunds = true;
        _fundsError = '';
      });
      final funds = await FundsRepository().fetchFunds();
      setState(() {
        _funds = funds;
        _selectedFund = funds.isNotEmpty ? funds.first : null;
        _isLoadingFunds = false;
      });
    } catch (e) {
      setState(() {
        _fundsError = 'Failed to load funds';
        _isLoadingFunds = false;
      });
    }
  }

  // ── API Call ───────────────────────────────────────────────────────────────
  Future<void> _processDeposit() async {
    if (_amountController.text.isEmpty || _selectedFund == null) return;

    // Show confirmation first
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
          'cdsNumber': _cdsNumber,
          'PhoneNumber': _phoneNumber,
          'Fund': _selectedFund!.fundingName ?? '',
          'Amount': _amountController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        _showSuccessDialog(data['statusDesc'] ?? 'Deposit request submitted successfully');
      } else {
        _showErrorSnackbar(data['statusDesc'] ?? 'Deposit failed. Please try again.');
      }
    } catch (e) {
      _showErrorSnackbar('Network error: ${e.toString()}');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────
  Future<bool> _showConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deposit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _confirmRow('Fund', _selectedFund?.fundingName ?? ''),
            const SizedBox(height: 6),
            _confirmRow('Amount', '$_selectedCurrency ${_formatAmount(_amountController.text)}'),
            const SizedBox(height: 6),
            _confirmRow('Payment', _selectedPaymentMethod),
            const SizedBox(height: 6),
            _confirmRow('Phone', _phoneNumber.isNotEmpty ? _phoneNumber : 'Not set'),
            const SizedBox(height: 12),
            const Text('Please confirm your deposit details.',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Widget _confirmRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text('$label:',
              style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.black87)),
        ),
      ],
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                  color: Colors.green, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 20),
            const Text(
              'Deposit Initiated!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // go back
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  IconData _getPaymentIcon(String method) {
    if (method.contains('Bank')) return Icons.account_balance;
    if (method.contains('Card') || method.contains('Visa')) return Icons.credit_card;
    if (method.contains('EcoCash')) return Icons.phone_android;
    return Icons.payment;
  }

  Color _getPaymentColor(String method) {
    if (method.contains('Bank')) return Colors.blue;
    if (method.contains('Card') || method.contains('Visa')) return Colors.purple;
    if (method.contains('EcoCash')) return Colors.green;
    return Colors.grey;
  }

  String _formatAmount(String amount) {
    if (amount.isEmpty) return '0.00';
    final double value = double.tryParse(amount) ?? 0;
    return value.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Deposit Funds',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: const Color(0xFFB8E6D3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFB8E6D3),
              Color(0xFF98D8C8),
              Color(0xFFF7DC6F),
              Color(0xFFFFE5B4),
            ],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add Money to Your Account',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose fund, amount and payment method',
                    style: TextStyle(
                        fontSize: 14, color: Colors.black.withOpacity(0.6)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Fund Selection ─────────────────────────────────────
                      const Text(
                        'Select Fund',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                      const SizedBox(height: 12),

                      if (_isLoadingFunds)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: CircularProgressIndicator(color: Colors.green),
                          ),
                        )
                      else if (_fundsError.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_fundsError,
                                    style:
                                    const TextStyle(color: Colors.red)),
                              ),
                              TextButton(
                                onPressed: _loadFunds,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<Fund>(
                              value: _selectedFund,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down),
                              items: _funds.map((fund) {
                                return DropdownMenuItem<Fund>(
                                  value: fund,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: fund.status?.toLowerCase() ==
                                              'active'
                                              ? Colors.green
                                              : Colors.orange,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              fund.fundingName ?? 'Unknown Fund',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                color: Colors.black87,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (fund.issuer != null)
                                              Text(
                                                fund.issuer!,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (fund) =>
                                  setState(() => _selectedFund = fund),
                            ),
                          ),
                        ),

                      const SizedBox(height: 28),

                      // ── Amount Section ─────────────────────────────────────
                      const Text(
                        'Enter Amount',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(15),
                                bottomLeft: Radius.circular(15),
                              ),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedCurrency,
                              underline: const SizedBox(),
                              items: _currencies.map((c) {
                                return DropdownMenuItem<String>(
                                  value: c,
                                  child: Text(c,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87)),
                                );
                              }).toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedCurrency = v!),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87),
                              decoration: InputDecoration(
                                hintText: '0.00',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(15),
                                    bottomRight: Radius.circular(15),
                                  ),
                                  borderSide:
                                  BorderSide(color: Colors.grey[300]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(15),
                                    bottomRight: Radius.circular(15),
                                  ),
                                  borderSide:
                                  BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(15),
                                    bottomRight: Radius.circular(15),
                                  ),
                                  borderSide:
                                  BorderSide(color: Colors.green, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── Quick Amounts ──────────────────────────────────────
                      const Text(
                        'Quick Select',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: _quickAmounts.map((amount) {
                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => setState(() =>
                                _amountController.text = amount['amount']!),
                                child: Container(
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: Colors.green.withOpacity(0.3)),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        amount['label']!,
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green[700]),
                                      ),
                                      Text(
                                        '$_selectedCurrency ${_formatAmount(amount['amount']!)}',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.green[600]),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 30),

                      // ── Payment Method ─────────────────────────────────────
                      const Text(
                        'Payment Method',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedPaymentMethod,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down),
                            items: _paymentMethods.map((method) {
                              return DropdownMenuItem<String>(
                                value: method,
                                child: Row(
                                  children: [
                                    Icon(_getPaymentIcon(method),
                                        color: _getPaymentColor(method),
                                        size: 20),
                                    const SizedBox(width: 12),
                                    Text(method,
                                        style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.black87)),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (v) =>
                                setState(() => _selectedPaymentMethod = v!),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // ── Summary ────────────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          children: [
                            _summaryRow(
                              'Fund',
                              _selectedFund?.fundingName ?? '—',
                            ),
                            const SizedBox(height: 8),
                            _summaryRow(
                              'Deposit Amount',
                              '$_selectedCurrency ${_amountController.text.isEmpty ? "0.00" : _formatAmount(_amountController.text)}',
                            ),
                            const SizedBox(height: 8),
                            _summaryRow('Processing Fee',
                                '$_selectedCurrency 0.00'),
                            const Divider(height: 20),
                            _summaryRow(
                              'Total Amount',
                              '$_selectedCurrency ${_amountController.text.isEmpty ? "0.00" : _formatAmount(_amountController.text)}',
                              isBold: true,
                              valueColor: Colors.green,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // ── Submit Button ──────────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (_amountController.text.isEmpty ||
                              _selectedFund == null ||
                              _isSubmitting)
                              ? null
                              : _processDeposit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            elevation: 0,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : const Text(
                            'Deposit Now',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: isBold ? 16 : 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: isBold ? Colors.black87 : Colors.grey[600])),
        Text(value,
            style: TextStyle(
                fontSize: isBold ? 16 : 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black87)),
      ],
    );
  }
}