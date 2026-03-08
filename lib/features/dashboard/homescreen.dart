import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../deposits/view/deposits.dart';
import '../funds/view/fund.dart';
import '../statement /client_statement.dart';
import '../withdrawal/view/withdrawal_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _isBalanceVisible = true;
  int _currentFundIndex = 0;
  final PageController _fundPageController = PageController();

  // ── Portfolio ──────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _funds = [];
  bool _isLoadingFunds = true;
  String? _fundsError;
  double _totalPortfolioValue = 0;
  String _cdsNumber = '';

  // ── SMA ───────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _smaPortfolios = [];
  bool _isLoadingSMA = true;
  String? _smaError;
  bool _isSMAExpanded = false;

  // ── Transactions ───────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoadingTxns = true;
  late AnimationController _chartFadeCtrl;
  late Animation<double> _chartFadeAnim;

  final List<Color> _cardColors = [
    const Color(0xFF1B5E20),
    const Color(0xFF1B5E20),
    const Color(0xFF1B5E20),
    const Color(0xFF1B5E20),
    const Color(0xFF1B5E20),
    const Color(0xFF1B5E20),
  ];

  final List<Map<String, dynamic>> _actions = [
    {'icon': Icons.account_balance_wallet_outlined, 'label': 'Deposit'},
    {'icon': Icons.monetization_on_outlined,        'label': 'Unit Prices'},
    {'icon': Icons.trending_down_outlined,           'label': 'Withdrawal'},
    {'icon': Icons.swap_horiz_outlined,              'label': 'Transactions'},
  ];

  @override
  void initState() {
    super.initState();
    _chartFadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _chartFadeAnim =
        CurvedAnimation(parent: _chartFadeCtrl, curve: Curves.easeOut);
    _fetchPortfolio();
  }

  @override
  void dispose() {
    _fundPageController.dispose();
    _chartFadeCtrl.dispose();
    super.dispose();
  }

  // ── API: Portfolio ─────────────────────────────────────────────────────────
  Future<void> _fetchPortfolio() async {
    setState(() { _isLoadingFunds = true; _fundsError = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      _cdsNumber = prefs.getString('cdsNumber') ?? '';

      final response = await http.post(
        Uri.parse('https://portaluat.tsl.co.tz/FMSAPI/home/GetFundsDetailed'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'APIUsername': 'User2',
          'APIPassword': 'CBZ1234#2',
          'cdsNumber': _cdsNumber,
        }),
      ).timeout(const Duration(seconds: 15));

      final json = jsonDecode(response.body);
      if (response.statusCode == 200 && json['status'] == 'success') {
        final data = json['data'];
        final List<dynamic> fundsRaw = data['funds'] ?? [];
        setState(() {
          _totalPortfolioValue =
              (data['totalPortfolioValue'] as num).toDouble();
          _funds = fundsRaw.map((f) => Map<String, dynamic>.from(f)).toList();
          _isLoadingFunds = false;
        });
        if (_funds.isNotEmpty) {
          _fetchTransactions(_funds[0]['fundName'] as String);
        }
        _fetchSMAPortfolios();
      } else {
        setState(() {
          _fundsError = json['statusDesc'] ?? 'Failed to load portfolio';
          _isLoadingFunds = false;
        });
      }
    } catch (_) {
      setState(() {
        _fundsError = 'Connection error. Please try again.';
        _isLoadingFunds = false;
      });
    }
  }

  // ── API: SMA Portfolios ────────────────────────────────────────────────────
  Future<void> _fetchSMAPortfolios() async {
    setState(() { _isLoadingSMA = true; _smaError = null; });
    try {
      final response = await http.post(
        Uri.parse('https://portaluat.tsl.co.tz/FMSAPI/home/GetSMAPortfolios'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'APIUsername': 'User2',
          'APIPassword': 'CBZ1234#2',
          'cdsNumber':  _cdsNumber,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        final List<dynamic> raw = (data['data'] as List<dynamic>?) ?? [];
        setState(() {
          _smaPortfolios =
              raw.map((e) => Map<String, dynamic>.from(e)).toList();
          _isLoadingSMA = false;
        });
      } else {
        // Graceful fallback – show placeholder if API not yet available
        setState(() {
          _smaPortfolios = [];
          _isLoadingSMA  = false;
        });
      }
    } catch (_) {
      setState(() {
        _smaPortfolios = [];
        _isLoadingSMA  = false;
      });
    }
  }

  // ── API: Transactions ──────────────────────────────────────────────────────
  Future<void> _fetchTransactions(String fundName) async {
    setState(() { _isLoadingTxns = true; });
    try {
      final response = await http.post(
        Uri.parse('https://portaluat.tsl.co.tz/FMSAPI/home/GetTransactions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'APIUsername': 'User2',
          'APIPassword': 'CBZ1234#2',
          'cdsNumber':   _cdsNumber,
          'Fund':        fundName,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        final List<dynamic> raw =
            (data['data']['trans'] as List<dynamic>?) ?? [];

        final parsed = raw.map((j) {
          final desc = (j['Description'] as String? ?? '').toLowerCase();
          final isDeposit = desc.contains('deposit') ||
              desc.contains('credit') ||
              desc.contains('purchase');
          DateTime date;
          try {
            date = DateFormat('dd-MMM-yyyy HH:mm')
                .parse(j['TrxnDate'] as String? ?? '');
          } catch (_) {
            date = DateTime.now();
          }
          return {
            'type':   isDeposit ? 'Deposit' : 'Withdrawal',
            'amount': double.tryParse(j['amount']?.toString() ?? '0') ?? 0.0,
            'label':  j['Description'] as String? ?? '',
            'units':  double.tryParse(j['Units']?.toString() ?? '0') ?? 0.0,
            'date':   date,
            'id':     j['TrxnID']?.toString() ?? '',
          };
        }).toList()
          ..sort((a, b) =>
              (a['date'] as DateTime).compareTo(b['date'] as DateTime));

        setState(() {
          _transactions  = parsed;
          _isLoadingTxns = false;
        });
        _chartFadeCtrl..reset()..forward();
      } else {
        setState(() { _isLoadingTxns = false; });
      }
    } catch (_) {
      setState(() { _isLoadingTxns = false; });
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _fmt(double v, {int decimals = 2}) {
    final parts = v.toStringAsFixed(decimals).split('.');
    final formatted = parts[0]
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
    return decimals > 0 ? '$formatted.${parts[1]}' : formatted;
  }

  String _shortAmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  String _mask(String _) => '••••••••';
  Color  _cardColor(int i) => _cardColors[i % _cardColors.length];

  double get _totalDeposits => _transactions
      .where((t) => t['type'] == 'Deposit')
      .fold(0.0, (s, t) => s + (t['amount'] as double));
  double get _totalWithdrawals => _transactions
      .where((t) => t['type'] == 'Withdrawal')
      .fold(0.0, (s, t) => s + (t['amount'] as double));
  double get _maxY {
    if (_transactions.isEmpty) return 100;
    final amounts = _transactions.map((t) => t['amount'] as double).toList();
    return (amounts.reduce(max) * 1.3).ceilToDouble();
  }

  void _onActionTap(String label) {
    Widget? page;
    switch (label) {
      case 'Deposit':     page = const DepositPage(); break;
      case 'Unit Prices': page = const FundsScreen(); break;
      case 'Withdrawal':  page = const WithdrawalPage(); break;
      case 'Transactions': page = const ClientStatementPage(); break;
    }
    if (page != null) {
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page!));
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFB8E6D3), Color(0xFF98D8C8), Color(0xFFFFE5B4)],
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 20, 15, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                _buildPortfolioSection(),
                const SizedBox(height: 10),

                // Page dots
                if (!_isLoadingFunds && _fundsError == null && _funds.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_funds.length, (i) {
                      final active = i == _currentFundIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 20 : 8, height: 8,
                        decoration: BoxDecoration(
                          color: active ? Colors.green[700] : Colors.black26,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                const SizedBox(height: 16),

                // ── SMA Section ──────────────────────────────────────────────
                _buildSMASection(),

                const SizedBox(height: 14),

                // Actions
                Row(
                  children: List.generate(_actions.length, (i) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < _actions.length - 1 ? 10 : 0),
                      child: _buildActionButton(
                        icon:  _actions[i]['icon']  as IconData,
                        label: _actions[i]['label'] as String,
                        onTap: () => _onActionTap(_actions[i]['label'] as String),
                      ),
                    ),
                  )),
                ),

                const SizedBox(height: 20),
                _buildTransactionsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── SMA Section ────────────────────────────────────────────────────────────
  Widget _buildSMASection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row (always visible – acts as toggle)
        GestureDetector(
          onTap: () => setState(() => _isSMAExpanded = !_isSMAExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.45),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Colors.white.withOpacity(0.7), width: 1.2),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3))
              ],
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_tree_outlined,
                    color: Color(0xFF1B5E20), size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Separately Managed Account',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87)),
                      Text('SMA Portfolio',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500])),
                    ]),
              ),
              // Total SMA value badge
              if (!_isLoadingSMA && _smaPortfolios.isNotEmpty) ...[
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('Total Value',
                      style: TextStyle(fontSize: 9, color: Colors.grey[400])),
                  Text(
                    'TZS ${_fmt(_smaPortfolios.fold(0.0, (s, p) => s + ((p['portfolioValue'] as num?)?.toDouble() ?? 0.0)))}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B5E20)),
                  ),
                ]),
                const SizedBox(width: 10),
              ],
              AnimatedRotation(
                turns: _isSMAExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 250),
                child: Icon(Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey[500], size: 22),
              ),
            ]),
          ),
        ),

        // Expandable content
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: _isSMAExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: _buildSMAContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildSMAContent() {
    if (_isLoadingSMA) {
      return _smaCard(
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                    color: Color(0xFF1B5E20), strokeWidth: 2),
                SizedBox(height: 12),
                Text('Loading SMA portfolios…',
                    style: TextStyle(fontSize: 12, color: Colors.black45)),
              ],
            ),
          ),
        ),
      );
    }

    if (_smaPortfolios.isEmpty) {
      return _smaCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: const Color(0xFF1B5E20).withOpacity(0.07),
                    shape: BoxShape.circle),
                child: const Icon(Icons.account_tree_outlined,
                    color: Color(0xFF1B5E20), size: 30),
              ),
              const SizedBox(height: 14),
              const Text('No SMA Portfolios',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black54)),
              const SizedBox(height: 6),
              Text(
                'You don\'t have any Separately Managed Account portfolios yet. Contact your relationship manager to get started.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[400], height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _smaPortfolios.map((p) => _buildSMACard(p)).toList(),
    );
  }

  Widget _smaCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: child,
    );
  }

  Widget _buildSMACard(Map<String, dynamic> p) {
    final portfolioName   = p['portfolioName']  as String? ?? 'SMA Portfolio';
    final managerName     = p['managerName']    as String? ?? '—';
    final portfolioValue  = (p['portfolioValue']  as num?)?.toDouble() ?? 0.0;
    final cashBalance     = (p['cashBalance']     as num?)?.toDouble() ?? 0.0;
    final securitiesValue = (p['securitiesValue'] as num?)?.toDouble() ?? 0.0;
    final currency        = p['currency']       as String? ?? 'TZS';
    final returnPct       = (p['returnPercent']   as num?)?.toDouble();
    final status          = p['status']         as String? ?? 'Active';
    final List<dynamic> holdings = (p['holdings'] as List<dynamic>?) ?? [];

    final bool isPositiveReturn = (returnPct ?? 0) >= 0;
    final Color returnColor = isPositiveReturn
        ? const Color(0xFF2E7D32)
        : const Color(0xFFC62828);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1B5E20),
            const Color(0xFF2E7D32),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF1B5E20).withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 5))
        ],
      ),
      child: Stack(children: [
        Positioned(right: -15, top: -15, child: _circle(90, 0.05)),
        Positioned(right: 50, bottom: -20, child: _circle(60, 0.04)),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: name + status ─────────────────────────────────
              Row(children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(portfolioName,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.2),
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text('Manager: $managerName',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.white.withOpacity(0.55))),
                      ]),
                ),
                // Status pill
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: const Color(0xFF69F0AE).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFF69F0AE).withOpacity(0.4))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.circle,
                        size: 6, color: Color(0xFF69F0AE)),
                    const SizedBox(width: 5),
                    Text(status,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF69F0AE))),
                  ]),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () =>
                      setState(() => _isBalanceVisible = !_isBalanceVisible),
                  child: Icon(
                      _isBalanceVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.white38,
                      size: 17),
                ),
              ]),

              const SizedBox(height: 12),
              Divider(color: Colors.white.withOpacity(0.12), height: 1),
              const SizedBox(height: 12),

              // ── Portfolio value ────────────────────────────────────────
              Text('Total Portfolio Value',
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.5),
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _isBalanceVisible
                        ? '$currency ${_fmt(portfolioValue)}'
                        : _mask(''),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5),
                  ),
                  if (returnPct != null) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (isPositiveReturn
                            ? const Color(0xFF69F0AE)
                            : Colors.red[200]!)
                            .withOpacity(0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(
                          isPositiveReturn
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          size: 12,
                          color: isPositiveReturn
                              ? const Color(0xFF69F0AE)
                              : Colors.red[300],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${isPositiveReturn ? '+' : ''}${returnPct.toStringAsFixed(2)}%',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isPositiveReturn
                                  ? const Color(0xFF69F0AE)
                                  : Colors.red[300]),
                        ),
                      ]),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 14),

              // ── Cash / Securities breakdown ────────────────────────────
              Row(children: [
                _smaStatChip(
                  label: 'Cash Balance',
                  value: _isBalanceVisible
                      ? '$currency ${_fmt(cashBalance)}'
                      : _mask(''),
                  icon: Icons.account_balance_wallet_outlined,
                ),
                const SizedBox(width: 10),
                _smaStatChip(
                  label: 'Securities',
                  value: _isBalanceVisible
                      ? '$currency ${_fmt(securitiesValue)}'
                      : _mask(''),
                  icon: Icons.bar_chart_rounded,
                ),
              ]),

              // ── Holdings (if any) ──────────────────────────────────────
              if (holdings.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text('Holdings',
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.5),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3)),
                const SizedBox(height: 8),
                ...holdings.take(4).map((h) {
                  final hMap = Map<String, dynamic>.from(h as Map);
                  final secName = hMap['securityName'] as String? ?? '—';
                  final qty     = (hMap['quantity']    as num?)?.toDouble() ?? 0;
                  final mktVal  = (hMap['marketValue'] as num?)?.toDouble() ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Row(children: [
                      Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.show_chart_rounded,
                            size: 14, color: Colors.white54),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(secName,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                            overflow: TextOverflow.ellipsis),
                      ),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(
                          _isBalanceVisible
                              ? '$currency ${_fmt(mktVal)}'
                              : _mask(''),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                        Text('${_fmt(qty, decimals: 0)} units',
                            style: TextStyle(
                                fontSize: 9,
                                color: Colors.white.withOpacity(0.45))),
                      ]),
                    ]),
                  );
                }).toList(),
                if (holdings.length > 4)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+ ${holdings.length - 4} more holdings',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.4),
                          fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ]),
    );
  }

  Widget _smaStatChip({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(children: [
          Icon(icon, size: 14, color: Colors.white38),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 9,
                          color: Colors.white.withOpacity(0.45),
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                      overflow: TextOverflow.ellipsis),
                ]),
          ),
        ]),
      ),
    );
  }

  // ── Transactions section ───────────────────────────────────────────────────
  Widget _buildTransactionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Transactions',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => const ClientStatementPage())),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.green[700],
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.green.shade700.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3))
                    ],
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('See All',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w700)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 10, color: Colors.white),
                  ]),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (!_isLoadingTxns && _transactions.isNotEmpty) ...[
          _buildSummaryPills(),
          const SizedBox(height: 14),
        ],
        _buildCandlestickChartCard(),
        const SizedBox(height: 16),
        _buildRecentList(),
      ],
    );
  }

  // ── Summary pills ──────────────────────────────────────────────────────────
  Widget _buildSummaryPills() {
    final net        = _totalDeposits - _totalWithdrawals;
    final isPositive = net >= 0;
    return Row(children: [
      _summaryPill('Deposits',    'TZS ${_shortAmt(_totalDeposits)}',
          Icons.arrow_downward_rounded, const Color(0xFF2E7D32), const Color(0xFFE8F5E9)),
      const SizedBox(width: 10),
      _summaryPill('Withdrawals', 'TZS ${_shortAmt(_totalWithdrawals)}',
          Icons.arrow_upward_rounded,   const Color(0xFFC62828), const Color(0xFFFFEBEE)),
      const SizedBox(width: 10),
      _summaryPill('Net Flow',
          '${isPositive ? '+' : ''}TZS ${_shortAmt(net)}',
          isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
          isPositive ? const Color(0xFF1565C0) : const Color(0xFF6A1B9A),
          isPositive ? const Color(0xFFE3F2FD) : const Color(0xFFF3E5F5)),
    ]);
  }

  Widget _summaryPill(String label, String value, IconData icon, Color fg, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: fg.withOpacity(0.2), width: 1),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
                color: fg.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, size: 12, color: fg),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 9,
                      color: fg.withOpacity(0.7),
                      fontWeight: FontWeight.w500)),
              Text(value,
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w800, color: fg),
                  overflow: TextOverflow.ellipsis),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── Candlestick data builder ───────────────────────────────────────────────
  /// Groups transactions by day and builds OHLC candles.
  /// A "bullish" candle day = net deposits > 0; "bearish" = net withdrawals.
  List<_CandleData> _buildCandles() {
    if (_transactions.isEmpty) return [];

    // Group by date (day bucket)
    final Map<String, List<Map<String, dynamic>>> byDay = {};
    for (final t in _transactions) {
      final key = DateFormat('yyyy-MM-dd').format(t['date'] as DateTime);
      byDay.putIfAbsent(key, () => []).add(t);
    }

    final candles = <_CandleData>[];
    final sortedKeys = byDay.keys.toList()..sort();

    for (final key in sortedKeys) {
      final group = byDay[key]!;
      final amounts = group.map((t) => t['amount'] as double).toList();
      final open   = amounts.first;
      final close  = amounts.last;
      final high   = amounts.reduce(max);
      final low    = amounts.reduce(min);
      final date   = group.first['date'] as DateTime;
      // Bullish if more deposits than withdrawals in that day
      final isUp   = group.where((t) => t['type'] == 'Deposit').length >=
          group.where((t) => t['type'] == 'Withdrawal').length;
      candles.add(_CandleData(
          date: date, open: open, high: high, low: low, close: close, isUp: isUp));
    }
    return candles;
  }

  // ── Candlestick Chart Card ─────────────────────────────────────────────────
  Widget _buildCandlestickChartCard() {
    final candles = _buildCandles();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                  color: Colors.green[700]!.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(9)),
              child: Icon(Icons.candlestick_chart_outlined,
                  color: Colors.green[700], size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Transaction Candlestick',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87)),
                    if (!_isLoadingTxns && candles.isNotEmpty)
                      Text('${candles.length} trading days · '
                          '${_funds.isNotEmpty ? _funds[_currentFundIndex]['fundName'] : ''}',
                          style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                  ]),
            ),
            _dot(Colors.green[600]!, 'Bullish'),
            const SizedBox(width: 12),
            _dot(Colors.red[400]!,   'Bearish'),
          ]),

          const SizedBox(height: 16),

          // ── Chart area ───────────────────────────────────────────────────
          SizedBox(
            height: 200,
            child: _isLoadingTxns
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.green)),
                  const SizedBox(height: 10),
                  Text('Loading chart data…',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                ],
              ),
            )
                : candles.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.candlestick_chart_outlined,
                      size: 40, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  Text('No transactions yet',
                      style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                ],
              ),
            )
                : FadeTransition(
              opacity: _chartFadeAnim,
              child: _CandlestickChart(
                candles: candles,
                bullColor: Colors.green[600]!,
                bearColor: Colors.red[400]!,
                labelColor: Colors.black38,
                gridColor: Colors.black.withOpacity(0.06),
                shortAmt: _shortAmt,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Recent list ────────────────────────────────────────────────────────────
  Widget _buildRecentList() {
    if (_isLoadingTxns || _transactions.isEmpty) return const SizedBox.shrink();
    final recent = _transactions.reversed.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('Latest Activity',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black54)),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.62),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recent.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: Colors.black.withOpacity(0.05), indent: 66),
            itemBuilder: (_, i) => _buildTxnRow(recent[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildTxnRow(Map<String, dynamic> txn) {
    final isDeposit = txn['type'] == 'Deposit';
    final color    = isDeposit ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    final bgColor  = isDeposit ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
    final icon     = isDeposit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    final amount   = txn['amount'] as double;
    final date     = txn['date']   as DateTime;
    final label    = txn['label']  as String;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text(DateFormat('dd MMM yyyy').format(date),
                style: TextStyle(fontSize: 11, color: Colors.grey[400])),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${isDeposit ? '+' : '-'} TZS',
              style: TextStyle(
                  fontSize: 9,
                  color: color.withOpacity(0.6),
                  fontWeight: FontWeight.w600)),
          Text(_fmt(amount),
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w900, color: color)),
        ]),
      ]),
    );
  }

  // ── Portfolio section ──────────────────────────────────────────────────────
  Widget _buildPortfolioSection() {
    if (_isLoadingFunds) {
      return _blankCard(
        height: 175,
        color: const Color(0xFF1B5E20),
        child: const Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            CircularProgressIndicator(color: Colors.white54, strokeWidth: 2),
            SizedBox(height: 12),
            Text('Loading portfolio…',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
          ]),
        ),
      );
    }
    if (_fundsError != null) {
      return _blankCard(
        height: 175,
        color: const Color(0xFF1B5E20),
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.cloud_off_outlined, color: Colors.white54, size: 28),
            const SizedBox(height: 8),
            Text(_fundsError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _fetchPortfolio,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white30)),
                child: const Text('Retry',
                    style: TextStyle(color: Colors.white, fontSize: 13)),
              ),
            ),
          ]),
        ),
      );
    }
    return SizedBox(
      height: 175,
      child: PageView.builder(
        controller: _fundPageController,
        itemCount: _funds.length,
        onPageChanged: (i) {
          setState(() => _currentFundIndex = i);
          _fetchTransactions(_funds[i]['fundName'] as String);
        },
        itemBuilder: (_, i) => _buildFundCard(_funds[i], i),
      ),
    );
  }

  Widget _blankCard(
      {required Widget child, required Color color, double height = 175}) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [color, color.withOpacity(0.75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 14,
              offset: const Offset(0, 6))
        ],
      ),
      child: child,
    );
  }

  // ── Fund card ──────────────────────────────────────────────────────────────
  Widget _buildFundCard(Map<String, dynamic> fund, int index) {
    final baseColor    = _cardColor(index);
    final portfolioVal = (fund['portfolioValue'] as num).toDouble();
    final units        = (fund['investorUnits']  as num).toDouble();
    final nav          = (fund['nav']            as num).toDouble();
    final status       = fund['status'] as String;
    final hasInvestment = portfolioVal > 0;

    Color statusColor;
    IconData statusIcon;
    switch (status.toLowerCase()) {
      case 'active':
        statusColor = const Color(0xFF69F0AE);
        statusIcon  = Icons.check_circle_outline;
        break;
      case 'ipo':
        statusColor = const Color(0xFFFFD740);
        statusIcon  = Icons.new_releases_outlined;
        break;
      default:
        statusColor = Colors.white38;
        statusIcon  = Icons.info_outline;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [baseColor, baseColor.withOpacity(0.72)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: baseColor.withOpacity(0.45),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Stack(children: [
        Positioned(right: -20, top: -20, child: _circle(110, 0.05)),
        Positioned(right: 40,  bottom: -25, child: _circle(70, 0.04)),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24, width: 1)),
                  child: Text(fund['fundCode'] as String,
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white70,
                          letterSpacing: 0.5)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fund['fundName'] as String,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.1),
                            overflow: TextOverflow.ellipsis),
                        Text(fund['description'] as String,
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.white.withOpacity(0.55))),
                      ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: statusColor.withOpacity(0.4), width: 1)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(statusIcon, size: 9, color: statusColor),
                    const SizedBox(width: 4),
                    Text(status,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: statusColor)),
                  ]),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () =>
                      setState(() => _isBalanceVisible = !_isBalanceVisible),
                  child: Icon(
                      _isBalanceVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.white38,
                      size: 17),
                ),
              ]),
              const Spacer(),
              Row(children: [
                Expanded(
                    flex: 5,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Portfolio Value',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white.withOpacity(0.5),
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          hasInvestment
                              ? Text(
                              _isBalanceVisible
                                  ? 'TZS ${_fmt(portfolioVal)}'
                                  : _mask(''),
                              style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.3))
                              : Text('Not invested yet',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.4),
                                  fontStyle: FontStyle.italic)),
                        ])),
                _vDivider(),
                Expanded(
                    flex: 3,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('My Units',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white.withOpacity(0.5),
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text(_isBalanceVisible ? _fmt(units) : _mask(''),
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ])),
                _vDivider(),
                Expanded(
                    flex: 3,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NAV',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white.withOpacity(0.5),
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text(_fmt(nav),
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ])),
              ]),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _circle(double size, double opacity) => Container(
      width: size, height: size,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(opacity)));

  Widget _vDivider() => Container(
      width: 1, height: 34, color: Colors.white12,
      margin: const EdgeInsets.symmetric(horizontal: 10));

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 78,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.6), width: 1),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(11)),
              child: Icon(icon, color: Colors.black87, size: 19)),
          const SizedBox(height: 6),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 10,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  height: 1.2)),
        ]),
      ),
    );
  }

  Widget _dot(Color color, String label) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(fontSize: 10, color: Colors.black54)),
      ]);
}

// ── Candlestick data model ─────────────────────────────────────────────────────
class _CandleData {
  final DateTime date;
  final double open, high, low, close;
  final bool isUp;
  const _CandleData({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.isUp,
  });
}

// ── Candlestick chart widget ───────────────────────────────────────────────────
class _CandlestickChart extends StatefulWidget {
  final List<_CandleData> candles;
  final Color bullColor;
  final Color bearColor;
  final Color labelColor;
  final Color gridColor;
  final String Function(double) shortAmt;

  const _CandlestickChart({
    required this.candles,
    required this.bullColor,
    required this.bearColor,
    required this.labelColor,
    required this.gridColor,
    required this.shortAmt,
  });

  @override
  State<_CandlestickChart> createState() => _CandlestickChartState();
}

class _CandlestickChartState extends State<_CandlestickChart> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      // Reserve space for y-labels (left) and x-labels (bottom)
      const double yLabelW  = 48.0;
      const double xLabelH  = 20.0;
      final double chartW   = w - yLabelW;
      final double chartH   = h - xLabelH;

      final allValues = widget.candles
          .expand((c) => [c.high, c.low])
          .toList();
      final double dataMax = allValues.reduce(max);
      final double dataMin = allValues.reduce(min);
      final double range   = (dataMax - dataMin) == 0 ? 1 : (dataMax - dataMin);
      // Add 10 % padding top & bottom
      final double visMax  = dataMax + range * 0.10;
      final double visMin  = max(0, dataMin - range * 0.10);
      final double visRange = visMax - visMin;

      double toY(double v) => chartH - ((v - visMin) / visRange) * chartH;

      final int n          = widget.candles.length;
      final double slotW   = chartW / n;
      final double bodyW   = (slotW * 0.55).clamp(4.0, 18.0);

      // Decide which date labels to show (max ~5)
      final int labelStep  = max(1, (n / 5).ceil());

      return GestureDetector(
        onTapDown: (d) {
          final localX = d.localPosition.dx - yLabelW;
          final idx = (localX / slotW).floor().clamp(0, n - 1);
          setState(() => _hoveredIndex = idx);
        },
        onTapUp: (_) => setState(() => _hoveredIndex = null),
        child: Stack(children: [
          // ── Canvas ───────────────────────────────────────────────────────
          Positioned(
            left: yLabelW,
            top: 0,
            width: chartW,
            height: chartH,
            child: CustomPaint(
              painter: _CandlePainter(
                candles:      widget.candles,
                bullColor:    widget.bullColor,
                bearColor:    widget.bearColor,
                gridColor:    widget.gridColor,
                hoveredIndex: _hoveredIndex,
                visMin:       visMin,
                visRange:     visRange,
                chartH:       chartH,
                slotW:        slotW,
                bodyW:        bodyW,
              ),
            ),
          ),

          // ── Y-axis labels ─────────────────────────────────────────────
          ...List.generate(5, (i) {
            final v    = visMin + visRange * i / 4;
            final y    = toY(v);
            return Positioned(
              left: 0,
              top: y - 7,
              width: yLabelW - 4,
              child: Text(widget.shortAmt(v),
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 9, color: widget.labelColor)),
            );
          }),

          // ── X-axis labels ─────────────────────────────────────────────
          ...List.generate(n, (i) {
            if (i % labelStep != 0) return const SizedBox.shrink();
            final cx = yLabelW + (i + 0.5) * slotW;
            return Positioned(
              left: cx - 18,
              top: chartH + 2,
              width: 36,
              child: Text(
                DateFormat('dd/MM').format(widget.candles[i].date),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 9, color: widget.labelColor),
              ),
            );
          }),

          // ── Tooltip ───────────────────────────────────────────────────
          if (_hoveredIndex != null) ...[
            Builder(builder: (_) {
              final idx = _hoveredIndex!;
              final c   = widget.candles[idx];
              final cx  = yLabelW + (idx + 0.5) * slotW;
              // Position tooltip: flip left if near right edge
              final double ttW  = 100.0;
              double ttLeft     = cx + 6;
              if (ttLeft + ttW > w) ttLeft = cx - ttW - 6;

              final bodyTop  = toY(max(c.open, c.close));
              final tooltipY = max(0.0, bodyTop - 60.0);

              return Positioned(
                left: ttLeft,
                top: tooltipY,
                child: Container(
                  width: ttW,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B5E20),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8)
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(DateFormat('dd MMM').format(c.date),
                          style: const TextStyle(
                              fontSize: 9,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      _ttRow('O', c.open),
                      _ttRow('H', c.high),
                      _ttRow('L', c.low),
                      _ttRow('C', c.close),
                    ],
                  ),
                ),
              );
            }),
          ],
        ]),
      );
    });
  }

  Widget _ttRow(String label, double v) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label,
          style: const TextStyle(
              fontSize: 9, color: Colors.white54, fontWeight: FontWeight.w600)),
      Text(widget.shortAmt(v),
          style: const TextStyle(
              fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
    ],
  );
}

// ── Candle painter ─────────────────────────────────────────────────────────────
class _CandlePainter extends CustomPainter {
  final List<_CandleData> candles;
  final Color bullColor, bearColor, gridColor;
  final int? hoveredIndex;
  final double visMin, visRange, chartH, slotW, bodyW;

  _CandlePainter({
    required this.candles,
    required this.bullColor,
    required this.bearColor,
    required this.gridColor,
    required this.hoveredIndex,
    required this.visMin,
    required this.visRange,
    required this.chartH,
    required this.slotW,
    required this.bodyW,
  });

  double _toY(double v) => chartH - ((v - visMin) / visRange) * chartH;

  @override
  void paint(Canvas canvas, Size size) {
    // ── Grid lines ──────────────────────────────────────────────────────────
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final dashPath = Path();
    for (int i = 0; i <= 4; i++) {
      final y = chartH * i / 4;
      dashPath.reset();
      // Draw dashes manually
      double x = 0;
      while (x < size.width) {
        dashPath.moveTo(x, y);
        dashPath.lineTo(x + 5, y);
        x += 10;
      }
      canvas.drawPath(dashPath, gridPaint);
    }

    // ── Candles ─────────────────────────────────────────────────────────────
    for (int i = 0; i < candles.length; i++) {
      final c      = candles[i];
      final color  = c.isUp ? bullColor : bearColor;
      final cx     = (i + 0.5) * slotW;
      final highY  = _toY(c.high);
      final lowY   = _toY(c.low);
      final openY  = _toY(c.open);
      final closeY = _toY(c.close);
      final bodyTop    = min(openY, closeY);
      final bodyBottom = max(openY, closeY);
      final bodyHeight = max(1.0, bodyBottom - bodyTop);

      final isHovered = i == hoveredIndex;

      // Highlight background for hovered candle
      if (isHovered) {
        canvas.drawRect(
          Rect.fromLTWH(cx - slotW / 2, 0, slotW, chartH),
          Paint()..color = color.withOpacity(0.08),
        );
      }

      final wickPaint = Paint()
        ..color = color.withOpacity(isHovered ? 1.0 : 0.7)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;

      final bodyPaint = Paint()
        ..color = color.withOpacity(isHovered ? 1.0 : 0.85)
        ..style = PaintingStyle.fill;

      final bodyBorderPaint = Paint()
        ..color = color
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      // Wick (high-low line)
      canvas.drawLine(Offset(cx, highY), Offset(cx, lowY), wickPaint);

      // Body (open-close rect)
      final bodyRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - bodyW / 2, bodyTop, bodyW, bodyHeight),
        const Radius.circular(2),
      );
      canvas.drawRRect(bodyRect, bodyPaint);
      canvas.drawRRect(bodyRect, bodyBorderPaint);
    }
  }

  @override
  bool shouldRepaint(_CandlePainter old) =>
      old.hoveredIndex != hoveredIndex || old.candles != candles;
}