import 'package:flutter/material.dart';

class MultiCurrencyWalletPage extends StatefulWidget {
  const MultiCurrencyWalletPage({Key? key}) : super(key: key);

  @override
  State<MultiCurrencyWalletPage> createState() => _MultiCurrencyWalletPageState();
}

class _MultiCurrencyWalletPageState extends State<MultiCurrencyWalletPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedCurrencyIndex = 0;

  final List<Map<String, dynamic>> _currencies = [
    {
      'code': 'TSZ',
      'name': 'Tanzanian Shilling',
      'symbol': 'TSZ',
      'balance': 1001200.50,
      'dividendBalance': 156800.00,
      'units': 98800.00,
      'color': Colors.green,
      'flag': '🇹🇿',
      'rate': 1.0, // Base currency
      'change24h': 0.0,
    },
    {
      'code': 'USD',
      'name': 'US Dollar',
      'symbol': '\$',
      'balance': 4250.75,
      'dividendBalance': 680.50,
      'units': 425.00,
      'color': Colors.blue,
      'flag': '🇺🇸',
      'rate': 0.00042, // 1 TSZ = 0.00042 USD
      'change24h': 1.25,
    },
    {
      'code': 'ZWL',
      'name': 'Zimbabwean Dollar',
      'symbol': 'Z\$',
      'balance': 2500000.00,
      'dividendBalance': 450000.00,
      'units': 185000.00,
      'color': Colors.orange,
      'flag': '🇿🇼',
      'rate': 2.35, // 1 TSZ = 2.35 ZWL
      'change24h': -0.85,
    },
    {
      'code': 'EUR',
      'name': 'Euro',
      'symbol': '€',
      'balance': 3850.25,
      'dividendBalance': 520.75,
      'units': 380.00,
      'color': Colors.purple,
      'flag': '🇪🇺',
      'rate': 0.00038, // 1 TSZ = 0.00038 EUR
      'change24h': 0.95,
    },
  ];

  final List<Map<String, dynamic>> _recentTransactions = [
    {
      'type': 'Currency Exchange',
      'from': 'USD',
      'to': 'TSZ',
      'amount': '500.00',
      'convertedAmount': '1,190,476.19',
      'date': '24 Sep 2025 - 14:30',
      'status': 'Completed',
    },
    {
      'type': 'Deposit',
      'currency': 'USD',
      'amount': '1,000.00',
      'date': '23 Sep 2025 - 16:45',
      'status': 'Completed',
    },
    {
      'type': 'Dividend Payout',
      'currency': 'EUR',
      'amount': '125.50',
      'date': '22 Sep 2025 - 09:15',
      'status': 'Processing',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Multi-Currency Wallet',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onPressed: () => _showWalletMenu(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.green,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Colors.green,
          tabs: const [
            Tab(text: 'Wallets'),
            Tab(text: 'Exchange'),
          ],
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
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildWalletsTab(),
            _buildExchangeTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletsTab() {
    return Column(
      children: [
        // Currency Selector
        Container(
          height: 120,
          margin: const EdgeInsets.symmetric(vertical: 20),
          child: PageView.builder(
            itemCount: _currencies.length,
            onPageChanged: (index) {
              setState(() {
                _selectedCurrencyIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final currency = _currencies[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          currency['flag'],
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currency['code'],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: currency['change24h'] >= 0
                                ? Colors.green.withOpacity(0.2)
                                : Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${currency['change24h'] >= 0 ? '+' : ''}${currency['change24h'].toStringAsFixed(2)}%',
                            style: TextStyle(
                              fontSize: 10,
                              color: currency['change24h'] >= 0
                                  ? Colors.green[700]
                                  : Colors.red[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${currency['symbol']} ${_formatAmount(currency['balance'].toString())}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      currency['name'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Dots Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_currencies.length, (index) {
            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: index == _selectedCurrencyIndex
                    ? Colors.green
                    : Colors.black54,
                shape: BoxShape.circle,
              ),
            );
          }),
        ),

        const SizedBox(height: 20),

        // Wallet Details
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
                  // Balance Breakdown
                  _buildBalanceCard(),

                  const SizedBox(height: 25),

                  // Quick Actions
                  _buildQuickActions(),

                  const SizedBox(height: 25),

                  // Recent Transactions
                  _buildRecentTransactions(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExchangeTab() {
    return Column(
      children: [
        // Exchange Rate Card
        Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Text(
                'Currency Exchange',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              // Exchange Rates List
              ...List.generate(_currencies.length - 1, (index) {
                // Skip TSZ as it's the base currency
                final currency = _currencies[index + 1];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        currency['flag'],
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '1 TSZ = ${currency['rate'].toStringAsFixed(5)} ${currency['code']}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              currency['name'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: currency['change24h'] >= 0
                              ? Colors.green.withOpacity(0.2)
                              : Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${currency['change24h'] >= 0 ? '+' : ''}${currency['change24h'].toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 10,
                            color: currency['change24h'] >= 0
                                ? Colors.green[700]
                                : Colors.red[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),

        // Exchange Form
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
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Exchange Currencies',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // From Currency
                  _buildCurrencySelector('From', 'TSZ', true),

                  const SizedBox(height: 15),

                  // Swap Button
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        // Implement swap functionality
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                          ),
                        ),
                        child: Icon(
                          Icons.swap_vert,
                          color: Colors.green[700],
                          size: 24,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // To Currency
                  _buildCurrencySelector('To', 'USD', false),

                  const SizedBox(height: 25),

                  // Amount Input
                  const Text(
                    'Amount',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '0.00',
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15)),
                        borderSide: BorderSide(color: Colors.green, width: 2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Exchange Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Exchange Rate',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const Text(
                              '1 TSZ = 0.00042 USD',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Exchange Fee (0.5%)',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const Text(
                              'TSZ 0.00',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Exchange Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _showExchangeConfirmation();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Exchange Now',
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
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard() {
    final selectedCurrency = _currencies[_selectedCurrencyIndex];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Balance',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${selectedCurrency['symbol']} ${_formatAmount(selectedCurrency['balance'].toString())}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Units',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatAmount(selectedCurrency['units'].toString()),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 15),
          const Divider(),
          const SizedBox(height: 15),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Dividends',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${selectedCurrency['symbol']} ${_formatAmount(selectedCurrency['dividendBalance'].toString())}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  // Navigate to dividend payout
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    'Claim',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.add,
                label: 'Deposit',
                color: Colors.green,
                onTap: () {
                  // Navigate to deposit
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.remove,
                label: 'Withdraw',
                color: Colors.red,
                onTap: () {
                  // Navigate to withdraw
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.swap_horiz,
                label: 'Exchange',
                color: Colors.blue,
                onTap: () {
                  _tabController.animateTo(1);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
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

  Widget _buildRecentTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            GestureDetector(
              onTap: () {
                // Navigate to all transactions
              },
              child: const Text(
                'See All',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),

        ...List.generate(_recentTransactions.length, (index) {
          final transaction = _recentTransactions[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: _getTransactionColor(transaction['type']).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getTransactionIcon(transaction['type']),
                    color: _getTransactionColor(transaction['type']),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction['type'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        transaction['date'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _getTransactionAmount(transaction),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _getAmountColor(transaction['type']),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(transaction['status']).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        transaction['status'],
                        style: TextStyle(
                          fontSize: 10,
                          color: _getStatusColor(transaction['status']),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCurrencySelector(String label, String selectedCode, bool isFrom) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedCode,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down),
              items: _currencies.map((currency) {
                return DropdownMenuItem<String>(
                  value: currency['code'],
                  child: Row(
                    children: [
                      Text(
                        currency['flag'],
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        currency['code'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        currency['name'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                // Handle currency change
              },
            ),
          ),
        ),
      ],
    );
  }

  String _formatAmount(String amount) {
    if (amount.isEmpty) return '0.00';
    final double value = double.tryParse(amount) ?? 0;
    return value.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  IconData _getTransactionIcon(String type) {
    switch (type.toLowerCase()) {
      case 'currency exchange':
        return Icons.swap_horiz;
      case 'deposit':
        return Icons.add_circle_outline;
      case 'dividend payout':
        return Icons.payments_outlined;
      case 'withdrawal':
        return Icons.remove_circle_outline;
      default:
        return Icons.receipt_outlined;
    }
  }

  Color _getTransactionColor(String type) {
    switch (type.toLowerCase()) {
      case 'currency exchange':
        return Colors.blue;
      case 'deposit':
        return Colors.green;
      case 'dividend payout':
        return Colors.orange;
      case 'withdrawal':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getAmountColor(String type) {
    switch (type.toLowerCase()) {
      case 'deposit':
        return Colors.green;
      case 'withdrawal':
        return Colors.red;
      default:
        return Colors.black87;
    }
  }

  String _getTransactionAmount(Map<String, dynamic> transaction) {
    if (transaction['type'] == 'Currency Exchange') {
      return '${transaction['from']} ${transaction['amount']}';
    }
    return '${transaction['currency']} ${transaction['amount']}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'processing':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showWalletMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 200,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: Colors.green),
              title: const Text('Add New Currency'),
              onTap: () {
                Navigator.pop(context);
                // Add new currency functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.blue),
              title: const Text('Transaction History'),
              onTap: () {
                Navigator.pop(context);
                // Show transaction history
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.grey),
              title: const Text('Wallet Settings'),
              onTap: () {
                Navigator.pop(context);
                // Show wallet settings
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showExchangeConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Exchange'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('From: TSZ 1,000.00'),
            Text('To: USD 0.42'),
            Text('Exchange Rate: 1 TSZ = 0.00042 USD'),
            Text('Fee: TSZ 5.00'),
            SizedBox(height: 10),
            Text('Please confirm your currency exchange.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Process exchange
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Currency exchange completed successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}