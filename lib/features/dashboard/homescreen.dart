import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isBalanceVisible = true;
  int _currentFundIndex = 0;
  final PageController _fundPageController = PageController();

  // ── Per-fund data ──────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _funds = [
    {
      'name': 'Umoja Fund',
      'currency': 'TZS',
      'units': '98,800.00',
      'value': '9,456,400.00',
    },
    {
      'name': 'Jikimu Fund',
      'currency': 'TZS',
      'units': '45,250.00',
      'value': '5,122,750.00',
    },
    {
      'name': 'Wekeza Maisha Fund',
      'currency': 'TZS',
      'units': '120,000.00',
      'value': '18,300,000.00',
    },
  ];

  // ── Action buttons ─────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _actions = [
    {'icon': Icons.account_balance_wallet_outlined, 'label': 'Deposit'},
    {'icon': Icons.monetization_on_outlined,        'label': 'Unit Prices'},
    {'icon': Icons.trending_down_outlined,           'label': 'Withdrawal'},
    {'icon': Icons.swap_horiz_outlined,              'label': 'Transfers'},
    {'icon': Icons.library_add_outlined,             'label': 'Fund\nSubscription'},
    {'icon': Icons.credit_card_outlined,             'label': 'Payment\nMethods'},
  ];

  // ── Recent transactions ────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _transactions = [
    {
      'type': 'Unit Transfer',
      'amount': 'TZS - 12,400.00',
      'date': '09 September 2024 – 15:03 PM',
      'status': 'Success',
    },
    {
      'type': 'Unit Transfer',
      'amount': 'TZS - 2,400.00',
      'date': '09 September 2024 – 15:03 PM',
      'status': 'Success',
    },
    {
      'type': 'Unit Transfer',
      'amount': 'TZS - 9,000.00',
      'date': '09 September 2024 – 15:03 PM',
      'status': 'Success',
    },
  ];

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _mask(String value) => '•' * 9;

  void _onActionTap(String label) {
    // TODO: wire up navigation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label tapped'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _fundPageController.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFB8E6D3),
              Color(0xFF98D8C8),
              Color(0xFFF7DC6F),
              Color(0xFFFFE5B4),
            ],
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          children: [
            // ── Fund card + actions ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 20, 15, 0),
              child: Column(
                children: [
                  // ── Fund PageView ─────────────────────────────────────────
                  SizedBox(
                    height: 160,
                    child: PageView.builder(
                      controller: _fundPageController,
                      itemCount: _funds.length,
                      onPageChanged: (i) =>
                          setState(() => _currentFundIndex = i),
                      itemBuilder: (context, index) {
                        final fund = _funds[index];
                        return _buildFundCard(fund);
                      },
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Page dots ─────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_funds.length, (i) {
                      final active = i == _currentFundIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active ? Colors.green[700] : Colors.black26,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 22),

                  // ── Action buttons (2 rows × 3) ───────────────────────────
                  _buildActionGrid(),

                  const SizedBox(height: 18),
                ],
              ),
            ),

            // ── Recent Transactions ─────────────────────────────────────────
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
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
                        Text(
                          'See All',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) =>
                            _buildTransactionTile(_transactions[index]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Fund card ──────────────────────────────────────────────────────────────
  Widget _buildFundCard(Map<String, dynamic> fund) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fund name + visibility toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                fund['name'],
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: () =>
                    setState(() => _isBalanceVisible = !_isBalanceVisible),
                child: Icon(
                  _isBalanceVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.black54,
                  size: 20,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Units | Value — side by side
          Row(
            children: [
              // Units
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Units',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isBalanceVisible ? fund['units'] : _mask(fund['units']),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              // Divider
              Container(
                height: 36,
                width: 1,
                color: Colors.black12,
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),

              // Value
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Value (${fund['currency']})',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isBalanceVisible ? fund['value'] : _mask(fund['value']),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 2 × 3 action grid ─────────────────────────────────────────────────────
  Widget _buildActionGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (context, index) {
        final action = _actions[index];
        return _buildActionButton(
          icon: action['icon'] as IconData,
          label: action['label'] as String,
          onTap: () => _onActionTap(action['label'] as String),
        );
      },
    );
  }

  // ── Single action button ───────────────────────────────────────────────────
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.6), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.black87, size: 22),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Transaction tile ───────────────────────────────────────────────────────
  Widget _buildTransactionTile(Map<String, dynamic> tx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.swap_horiz_outlined,
                color: Colors.grey[600], size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx['type'],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  tx['date'],
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                tx['amount'],
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    tx['status'],
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}