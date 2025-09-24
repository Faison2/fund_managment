import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';


class ClientStatementPage extends StatefulWidget {
  const ClientStatementPage({Key? key}) : super(key: key);

  @override
  State<ClientStatementPage> createState() => _ClientStatementPageState();
}

class _ClientStatementPageState extends State<ClientStatementPage> {
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();
  String _selectedStatementType = 'All Transactions';
  bool _isLoading = false;
  List<Map<String, dynamic>> _statementData = [];
  bool _hasGeneratedStatement = false;

  final List<String> _statementTypes = [
    'All Transactions',
    'Deposits Only',
    'Withdrawals Only',
    'Dividends Only',
    'Fund Purchases',
    'Fund Sales',
  ];

  final List<Map<String, String>> _quickDateRanges = [
    {'label': 'Last 7 Days', 'days': '7'},
    {'label': 'Last 30 Days', 'days': '30'},
    {'label': 'Last 90 Days', 'days': '90'},
    {'label': 'This Year', 'days': '365'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Client Statement',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor:   Color(0xFFB8E6D3),
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
            // Header Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Generate Account Statement',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select date range and statement type',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),

            // Main Content
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
                child: Column(
                  children: [
                    // Filter Section
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Statement Type Selection
                          const Text(
                            'Statement Type',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedStatementType,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down),
                                items: _statementTypes.map((type) {
                                  return DropdownMenuItem<String>(
                                    value: type,
                                    child: Row(
                                      children: [
                                        Icon(
                                          _getStatementTypeIcon(type),
                                          color: _getStatementTypeColor(type),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          type,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedStatementType = value!;
                                  });
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 25),

                          // Quick Date Range Selection
                          const Text(
                            'Quick Date Range',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _quickDateRanges.map((range) {
                                return Container(
                                  margin: const EdgeInsets.only(right: 10),
                                  child: GestureDetector(
                                    onTap: () => _selectQuickRange(int.parse(range['days']!)),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.blue.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Text(
                                        range['label']!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                          const SizedBox(height: 25),

                          // Custom Date Range Selection
                          const Text(
                            'Custom Date Range',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 15),

                          // From Date
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'From Date',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    GestureDetector(
                                      onTap: () => _selectDate(context, true),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.grey[300]!),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              DateFormat('MMM dd, yyyy').format(_fromDate),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            Icon(
                                              Icons.calendar_today,
                                              color: Colors.grey[600],
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'To Date',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    GestureDetector(
                                      onTap: () => _selectDate(context, false),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.grey[300]!),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              DateFormat('MMM dd, yyyy').format(_toDate),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            Icon(
                                              Icons.calendar_today,
                                              color: Colors.grey[600],
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 30),

                          // Generate Statement Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _generateStatement,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                                  : const Text(
                                'Generate Statement',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Statement Results
                    if (_hasGeneratedStatement) ...[
                      const Divider(thickness: 1),
                      Expanded(
                        child: Column(
                          children: [
                            // Statement Header
                            Container(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Statement Results',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        '${DateFormat('MMM dd, yyyy').format(_fromDate)} - ${DateFormat('MMM dd, yyyy').format(_toDate)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Text(
                                        '${_statementData.length} transactions found',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Download Options
                                  Row(
                                    children: [
                                      _buildDownloadButton(
                                        'PDF',
                                        Icons.picture_as_pdf,
                                        Colors.red,
                                        _downloadPDF,
                                      ),
                                      const SizedBox(width: 10),
                                      _buildDownloadButton(
                                        'CSV',
                                        Icons.table_chart,
                                        Colors.green,
                                        _downloadCSV,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Statement Summary
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 20),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildSummaryItem('Total Deposits', _calculateTotalDeposits(), Colors.green),
                                  Container(width: 1, height: 40, color: Colors.grey[300]),
                                  _buildSummaryItem('Total Withdrawals', _calculateTotalWithdrawals(), Colors.red),
                                  Container(width: 1, height: 40, color: Colors.grey[300]),
                                  _buildSummaryItem('Net Balance', _calculateNetBalance(), Colors.blue),
                                ],
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Statement List
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: _statementData.length,
                                itemBuilder: (context, index) {
                                  final transaction = _statementData[index];
                                  return _buildTransactionItem(transaction);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final isCredit = transaction['type'].toString().toLowerCase().contains('deposit') ||
        transaction['type'].toString().toLowerCase().contains('dividend');
    final color = isCredit ? Colors.green : Colors.red;
    final icon = _getTransactionIcon(transaction['type']);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          transaction['description'] ?? 'Transaction',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              transaction['type'] ?? '',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              DateFormat('MMM dd, yyyy • hh:mm a').format(
                DateTime.parse(transaction['date']),
              ),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isCredit ? '+' : '-'}${transaction['currency']} ${_formatAmount(transaction['amount'].toString())}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (transaction['balance'] != null) ...[
              Text(
                'Bal: ${transaction['currency']} ${_formatAmount(transaction['balance'].toString())}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getStatementTypeIcon(String type) {
    if (type.contains('All')) return Icons.list_alt;
    if (type.contains('Deposits')) return Icons.trending_up;
    if (type.contains('Withdrawals')) return Icons.trending_down;
    if (type.contains('Dividends')) return Icons.payments;
    if (type.contains('Purchases')) return Icons.shopping_cart;
    if (type.contains('Sales')) return Icons.sell;
    return Icons.receipt;
  }

  Color _getStatementTypeColor(String type) {
    if (type.contains('All')) return Colors.blue;
    if (type.contains('Deposits')) return Colors.green;
    if (type.contains('Withdrawals')) return Colors.red;
    if (type.contains('Dividends')) return Colors.purple;
    if (type.contains('Purchases')) return Colors.orange;
    if (type.contains('Sales')) return Colors.teal;
    return Colors.grey;
  }

  IconData _getTransactionIcon(String type) {
    if (type.toLowerCase().contains('deposit')) return Icons.trending_up;
    if (type.toLowerCase().contains('withdrawal')) return Icons.trending_down;
    if (type.toLowerCase().contains('dividend')) return Icons.payments;
    if (type.toLowerCase().contains('purchase')) return Icons.shopping_cart;
    if (type.toLowerCase().contains('sale')) return Icons.sell;
    return Icons.receipt;
  }

  void _selectQuickRange(int days) {
    setState(() {
      _toDate = DateTime.now();
      _fromDate = DateTime.now().subtract(Duration(days: days));
    });
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate ? _fromDate : _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
          if (_fromDate.isAfter(_toDate)) {
            _toDate = _fromDate.add(const Duration(days: 1));
          }
        } else {
          _toDate = picked;
          if (_toDate.isBefore(_fromDate)) {
            _fromDate = _toDate.subtract(const Duration(days: 1));
          }
        }
      });
    }
  }

  Future<void> _generateStatement() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 2));

    // Mock statement data - replace with actual API call
    _statementData = _generateMockStatementData();

    setState(() {
      _isLoading = false;
      _hasGeneratedStatement = true;
    });

    _showSnackBar('Statement generated successfully!', Colors.green);
  }

  List<Map<String, dynamic>> _generateMockStatementData() {
    // This would be replaced with actual API call to fetch statement data
    List<Map<String, dynamic>> mockData = [
      {
        'id': '1',
        'date': '2024-01-15T10:30:00Z',
        'type': 'Deposit',
        'description': 'Fund Deposit - Standard Bank',
        'amount': 50000,
        'currency': 'TSZ',
        'balance': 150000,
      },
      {
        'id': '2',
        'date': '2024-01-10T14:20:00Z',
        'type': 'Dividend Payout',
        'description': 'Quarterly Dividend Payment',
        'amount': 12500,
        'currency': 'TSZ',
        'balance': 100000,
      },
      {
        'id': '3',
        'date': '2024-01-05T09:15:00Z',
        'type': 'Withdrawal',
        'description': 'Fund Withdrawal - EcoCash',
        'amount': 25000,
        'currency': 'TSZ',
        'balance': 87500,
      },
      {
        'id': '4',
        'date': '2024-01-01T16:45:00Z',
        'type': 'Fund Purchase',
        'description': 'TSL Growth Fund Purchase',
        'amount': 75000,
        'currency': 'TSZ',
        'balance': 112500,
      },
    ];

    // Filter based on selected statement type
    if (_selectedStatementType != 'All Transactions') {
      mockData = mockData.where((transaction) {
        String type = transaction['type'].toString().toLowerCase();
        String selectedType = _selectedStatementType.toLowerCase();

        if (selectedType.contains('deposits') && type.contains('deposit')) return true;
        if (selectedType.contains('withdrawals') && type.contains('withdrawal')) return true;
        if (selectedType.contains('dividends') && type.contains('dividend')) return true;
        if (selectedType.contains('purchases') && type.contains('purchase')) return true;
        if (selectedType.contains('sales') && type.contains('sale')) return true;

        return false;
      }).toList();
    }

    return mockData;
  }

  String _formatAmount(String amount) {
    if (amount.isEmpty) return '0.00';
    final double value = double.tryParse(amount) ?? 0;
    return value.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  String _calculateTotalDeposits() {
    double total = _statementData
        .where((t) => t['type'].toString().toLowerCase().contains('deposit'))
        .fold(0.0, (sum, t) => sum + (t['amount'] ?? 0));
    return _formatAmount(total.toString());
  }

  String _calculateTotalWithdrawals() {
    double total = _statementData
        .where((t) => t['type'].toString().toLowerCase().contains('withdrawal'))
        .fold(0.0, (sum, t) => sum + (t['amount'] ?? 0));
    return _formatAmount(total.toString());
  }

  String _calculateNetBalance() {
    double deposits = _statementData
        .where((t) => t['type'].toString().toLowerCase().contains('deposit') ||
        t['type'].toString().toLowerCase().contains('dividend'))
        .fold(0.0, (sum, t) => sum + (t['amount'] ?? 0));

    double withdrawals = _statementData
        .where((t) => t['type'].toString().toLowerCase().contains('withdrawal'))
        .fold(0.0, (sum, t) => sum + (t['amount'] ?? 0));

    return _formatAmount((deposits - withdrawals).toString());
  }

  void _downloadPDF() {
    _showSnackBar('PDF download started...', Colors.blue);
    // Implement PDF generation and download logic here
    // You might use packages like pdf, printing, etc.
  }

  void _downloadCSV() {
    _showSnackBar('CSV download started...', Colors.green);
    // Implement CSV generation and download logic here
    // You might use packages like csv, path_provider, etc.
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}