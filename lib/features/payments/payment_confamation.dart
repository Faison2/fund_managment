import 'package:flutter/material.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({Key? key, required Map transactionData}) : super(key: key);

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Buy', 'Sell'];

  // ── Mock orders data ────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _orders = [
    {
      'orderId': 'ORD-2024-001',
      'type': 'Buy',
      'security': 'NMB',
      'quantity': 500,
      'price': 3160.00,
      'totalValue': 1580000.00,
      'status': 'Completed',
      'date': '14 Sep 2024',
      'time': '10:23 AM',
      'currency': 'TZS',
    },
    {
      'orderId': 'ORD-2024-002',
      'type': 'Sell',
      'security': 'CRDB',
      'quantity': 200,
      'price': 2530.00,
      'totalValue': 506000.00,
      'status': 'Completed',
      'date': '13 Sep 2024',
      'time': '02:45 PM',
      'currency': 'TZS',
    },
    {
      'orderId': 'ORD-2024-003',
      'type': 'Buy',
      'security': 'TBL',
      'quantity': 100,
      'price': 3820.00,
      'totalValue': 382000.00,
      'status': 'Pending',
      'date': '13 Sep 2024',
      'time': '11:10 AM',
      'currency': 'TZS',
    },
    {
      'orderId': 'ORD-2024-004',
      'type': 'Sell',
      'security': 'DSE',
      'quantity': 50,
      'price': 6440.00,
      'totalValue': 322000.00,
      'status': 'Cancelled',
      'date': '12 Sep 2024',
      'time': '09:05 AM',
      'currency': 'TZS',
    },
    {
      'orderId': 'ORD-2024-005',
      'type': 'Buy',
      'security': 'TWIGA',
      'quantity': 80,
      'price': 6950.00,
      'totalValue': 556000.00,
      'status': 'Completed',
      'date': '11 Sep 2024',
      'time': '03:30 PM',
      'currency': 'TZS',
    },
    {
      'orderId': 'ORD-2024-006',
      'type': 'Buy',
      'security': 'KA',
      'quantity': 1000,
      'price': 315.00,
      'totalValue': 315000.00,
      'status': 'Pending',
      'date': '10 Sep 2024',
      'time': '10:55 AM',
      'currency': 'TZS',
    },
    {
      'orderId': 'ORD-2024-007',
      'type': 'Sell',
      'security': 'TPS',
      'quantity': 300,
      'price': 2120.00,
      'totalValue': 636000.00,
      'status': 'Completed',
      'date': '09 Sep 2024',
      'time': '01:15 PM',
      'currency': 'TZS',
    },
    {
      'orderId': 'ORD-2024-008',
      'type': 'Sell',
      'security': 'AFRIPRISE',
      'quantity': 400,
      'price': 820.00,
      'totalValue': 328000.00,
      'status': 'Failed',
      'date': '08 Sep 2024',
      'time': '11:40 AM',
      'currency': 'TZS',
    },
  ];

  List<Map<String, dynamic>> get _filtered {
    if (_selectedFilter == 'All') return _orders;
    return _orders.where((o) => o['type'] == _selectedFilter).toList();
  }

  // Summaries
  int get _totalOrders    => _orders.length;
  int get _completedCount => _orders.where((o) => o['status'] == 'Completed').length;
  int get _pendingCount   => _orders.where((o) => o['status'] == 'Pending').length;
  double get _totalBuyValue => _orders
      .where((o) => o['type'] == 'Buy' && o['status'] == 'Completed')
      .fold(0.0, (s, o) => s + (o['totalValue'] as double));
  double get _totalSellValue => _orders
      .where((o) => o['type'] == 'Sell' && o['status'] == 'Completed')
      .fold(0.0, (s, o) => s + (o['totalValue'] as double));

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF7FFFD4),
              Color(0xFF98FB98),
              Color(0xFFAFEEEE),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── App bar ──────────────────────────────────────────────────
              _buildAppBar(),

              // ── Summary cards ────────────────────────────────────────────
              _buildSummaryRow(),

              const SizedBox(height: 12),

              // ── Filter chips ─────────────────────────────────────────────
              _buildFilterRow(),

              const SizedBox(height: 12),

              // ── Orders list ──────────────────────────────────────────────
              Expanded(
                child: _filtered.isEmpty
                    ? _buildEmpty()
                    : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _buildOrderCard(_filtered[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── App bar ────────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.6), width: 1),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.black87),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My Orders',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87, letterSpacing: -0.3)),
                Text('DSE Securities',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black54)),
              ],
            ),
          ),
          // Total orders badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.6), width: 1),
            ),
            child: Text(
              '$_totalOrders Orders',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.teal.shade700),
            ),
          ),
        ],
      ),
    );
  }

  // ── Summary row ────────────────────────────────────────────────────────────
  Widget _buildSummaryRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          Expanded(child: _summaryCard(
            label: 'Total Bought',
            value: _shortValue(_totalBuyValue),
            color: Colors.green.shade700,
            icon: Icons.trending_up_rounded,
          )),
          const SizedBox(width: 10),
          Expanded(child: _summaryCard(
            label: 'Total Sold',
            value: _shortValue(_totalSellValue),
            color: Colors.red.shade600,
            icon: Icons.trending_down_rounded,
          )),
          const SizedBox(width: 10),
          Expanded(child: _summaryCard(
            label: 'Pending',
            value: '$_pendingCount',
            color: Colors.orange.shade700,
            icon: Icons.schedule_outlined,
          )),
          const SizedBox(width: 10),
          Expanded(child: _summaryCard(
            label: 'Done',
            value: '$_completedCount',
            color: Colors.teal.shade700,
            icon: Icons.check_circle_outline_rounded,
          )),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.7), width: 1),
        boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 9, color: Colors.black54, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ── Filter row ─────────────────────────────────────────────────────────────
  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _filters.map((f) {
          final active = _selectedFilter == f;
          Color activeColor = Colors.teal.shade700;
          if (f == 'Buy')  activeColor = Colors.green.shade700;
          if (f == 'Sell') activeColor = Colors.red.shade600;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: active ? activeColor : Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active ? activeColor : Colors.white.withOpacity(0.6),
                    width: 1,
                  ),
                  boxShadow: active
                      ? [BoxShadow(color: activeColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                      : [],
                ),
                child: Text(
                  f,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : Colors.black54,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Order card ─────────────────────────────────────────────────────────────
  Widget _buildOrderCard(Map<String, dynamic> order) {
    final isBuy      = order['type'] == 'Buy';
    final typeColor  = isBuy ? Colors.green.shade700 : Colors.red.shade600;
    final statusColor = _statusColor(order['status'] as String);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // ── Top row ────────────────────────────────────────────────────
          Row(
            children: [
              // Buy/Sell badge
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: typeColor.withOpacity(0.25), width: 1),
                ),
                child: Icon(
                  isBuy ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  color: typeColor, size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Security + order ID
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(order['security'] as String,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            order['type'] as String,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: typeColor, letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(order['orderId'] as String,
                        style: const TextStyle(fontSize: 11, color: Colors.black38, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),

              // Status chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6,
                        decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text(order['status'] as String,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Divider ────────────────────────────────────────────────────
          Container(height: 1, color: Colors.teal.withOpacity(0.1)),
          const SizedBox(height: 12),

          // ── Bottom details row ─────────────────────────────────────────
          Row(
            children: [
              _orderDetail('Qty', '${order['quantity']}'),
              _vDivider(),
              _orderDetail('Price', 'TZS ${_fmt(order['price'] as double)}'),
              _vDivider(),
              _orderDetail('Total', 'TZS ${_shortValue(order['totalValue'] as double)}', highlight: true),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(order['date'] as String,
                      style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w500)),
                  Text(order['time'] as String,
                      style: const TextStyle(fontSize: 10, color: Colors.black38)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _orderDetail(String label, String value, {bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.black45, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: highlight ? Colors.teal.shade700 : Colors.black87,
        )),
      ],
    );
  }

  Widget _vDivider() => Container(
      width: 1, height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: Colors.teal.withOpacity(0.15));

  // ── Empty state ────────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 56, color: Colors.teal.withOpacity(0.35)),
          const SizedBox(height: 14),
          Text(
            'No ${_selectedFilter == 'All' ? '' : _selectedFilter} orders yet',
            style: const TextStyle(fontSize: 15, color: Colors.black45, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return Colors.green.shade700;
      case 'pending':   return Colors.orange.shade700;
      case 'cancelled': return Colors.grey.shade600;
      case 'failed':    return Colors.red.shade600;
      default:          return Colors.grey.shade600;
    }
  }

  String _fmt(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final formatted = parts[0].replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
    return '$formatted.${parts[1]}';
  }

  String _shortValue(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000)    return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toStringAsFixed(0);
  }
}