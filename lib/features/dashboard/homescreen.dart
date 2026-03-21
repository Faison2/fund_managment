import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../provider/locale_provider.dart';
import '../../provider/theme_provider.dart';
import '../deposits/view/deposits.dart';
import '../funds/view/fund.dart';
import '../sma/sma.dart';
import '../statement /client_statement.dart';
import '../trade/dashboad/trade_dashboad.dart';
import '../withdrawal/view/withdrawal_page.dart';

// ── Localised strings ─────────────────────────────────────────────────────────
class _HS {
  final String deposit, unitPrices, withdrawal, transactions,
      portfolioValue, myUnits, nav, loadingPortfolio,
      connectionError, retry, recentTransactions, latestActivity,
      seeAll, loadingChart, noTransactions, txnLineChart,
      tradingDays, deposits, withdrawals, netFlow,
      loadingSMA, noSMA, noSMADesc, smaTitle, smaPortfolio,
      totalValue, holdings, moreHoldings, notInvestedYet,
      cashBalance, securities, manager, failedLoad,
      contactManager, notInvested, viewDashboard, dseTrading,
      smaTransactions, loadingSMATransactions, balance;
  const _HS({
    required this.deposit,           required this.unitPrices,
    required this.withdrawal,        required this.transactions,
    required this.portfolioValue,    required this.myUnits,
    required this.nav,               required this.loadingPortfolio,
    required this.connectionError,   required this.retry,
    required this.recentTransactions,required this.latestActivity,
    required this.seeAll,            required this.loadingChart,
    required this.noTransactions,    required this.txnLineChart,
    required this.tradingDays,       required this.deposits,
    required this.withdrawals,       required this.netFlow,
    required this.loadingSMA,        required this.noSMA,
    required this.noSMADesc,         required this.smaTitle,
    required this.smaPortfolio,      required this.totalValue,
    required this.holdings,          required this.moreHoldings,
    required this.notInvestedYet,    required this.cashBalance,
    required this.securities,        required this.manager,
    required this.failedLoad,        required this.contactManager,
    required this.notInvested,       required this.viewDashboard,
    required this.dseTrading,        required this.smaTransactions,
    required this.loadingSMATransactions, required this.balance,
  });
}

const _hsEn = _HS(
  deposit:                'Invest',
  unitPrices:             'SMA Portifolios',
  withdrawal:             'Redeem',
  transactions:           'Transactions',
  portfolioValue:         'Portfolio Value',
  myUnits:                'My Units',
  nav:                    'NAV',
  loadingPortfolio:       'Loading portfolio…',
  connectionError:        'Connection error. Please try again.',
  retry:                  'Retry',
  recentTransactions:     'Recent Transactions',
  latestActivity:         'Latest Activity',
  seeAll:                 'See All',
  loadingChart:           'Loading chart data…',
  noTransactions:         'No transactions yet',
  txnLineChart:           'Portfolio Flow',
  tradingDays:            'data points',
  deposits:               'Deposits',
  withdrawals:            'Withdrawals',
  netFlow:                'Net Flow',
  loadingSMA:             'Loading SMA portfolios…',
  noSMA:                  'No SMA Portfolios',
  noSMADesc:              'You don\'t have any Separately Managed Account portfolios yet.',
  smaTitle:               'Separately Managed Account',
  smaPortfolio:           'SMA Portfolio',
  totalValue:             'Total Value',
  holdings:               'Holdings',
  moreHoldings:           'more holdings',
  notInvestedYet:         'Not invested yet',
  cashBalance:            'Cash Balance',
  securities:             'Securities',
  manager:                'Manager',
  failedLoad:             'Failed to load portfolio',
  contactManager:         'Contact your relationship manager to get started.',
  notInvested:            'Not invested yet',
  viewDashboard:          'View Dashboard',
  dseTrading:             'DSE Trading',
  smaTransactions:        'SMA Cash Transactions',
  loadingSMATransactions: 'Loading SMA transactions…',
  balance:                'Balance',
);

const _hsSw = _HS(
  deposit:                'Wekeza',
  unitPrices:             'Bei za Vitengo',
  withdrawal:             'Toa Fedha',
  transactions:           'Miamala',
  portfolioValue:         'Thamani ya Mkoba',
  myUnits:                'Vitengo Vyangu',
  nav:                    'NAV',
  loadingPortfolio:       'Inapakia mkoba…',
  connectionError:        'Hitilafu ya mtandao. Tafadhali jaribu tena.',
  retry:                  'Jaribu Tena',
  recentTransactions:     'Miamala ya Hivi Karibuni',
  latestActivity:         'Shughuli za Hivi Karibuni',
  seeAll:                 'Ona Zote',
  loadingChart:           'Inapakia data ya chati…',
  noTransactions:         'Hakuna miamala bado',
  txnLineChart:           'Mtiririko wa Mkoba',
  tradingDays:            'pointi za data',
  deposits:               'Amana',
  withdrawals:            'Michoto',
  netFlow:                'Mtiririko Halisi',
  loadingSMA:             'Inapakia SMA…',
  noSMA:                  'Hakuna Mkoba wa SMA',
  noSMADesc:              'Huna mkoba wowote wa Akaunti Inayosimamiwa Kando bado.',
  smaTitle:               'Akaunti Inayosimamiwa Kando',
  smaPortfolio:           'Mkoba wa SMA',
  totalValue:             'Jumla ya Thamani',
  holdings:               'Mauzo',
  moreHoldings:           'mauzo zaidi',
  notInvestedYet:         'Bado haujawekeza',
  cashBalance:            'Salio la Fedha',
  securities:             'Hisa',
  manager:                'Msimamizi',
  failedLoad:             'Imeshindwa kupakia mkoba',
  contactManager:         'Wasiliana na msimamizi wako ili kuanza.',
  notInvested:            'Bado haujawekeza',
  viewDashboard:          'Angalia Dashibodi',
  dseTrading:             'Biashara ya DSE',
  smaTransactions:        'Miamala ya SMA',
  loadingSMATransactions: 'Inapakia miamala ya SMA…',
  balance:                'Salio',
);

// ── HomeScreen ────────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _isBalanceVisible = true;
  int  _currentFundIndex = 0;
  final PageController _fundPageController = PageController();

  // ── Fund portfolio ─────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _funds = [];
  bool    _isLoadingFunds = true;
  String? _fundsError;
  String  _cdsNumber = '';

  // ── SMA ────────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _smaPortfolios   = [];
  List<Map<String, dynamic>> _smaInvestments  = [];
  List<Map<String, dynamic>> _smaCashTxns     = [];
  double _smaCashBalance    = 0;
  double _smaTotalPortfolio = 0;
  bool   _isLoadingSMA      = true;
  bool   _isLoadingSMATxns  = false;

  // ── Fund transactions ──────────────────────────────────────────────────────
  List<Map<String, dynamic>> _fundTransactions = [];
  bool _isLoadingFundTxns = true;

  late AnimationController _chartFadeCtrl;
  late Animation<double>   _chartFadeAnim;

  static const List<Color> _cardColors = [
    Color(0xFF1B5E20), Color(0xFF1B5E20), Color(0xFF1B5E20),
    Color(0xFF1B5E20), Color(0xFF1B5E20), Color(0xFF1B5E20),
  ];

  static const _kDeposit      = 'Invest';
  static const _kUnitPrices   = 'Unit Prices';
  static const _kWithdrawal   = 'Redeem';
  static const _kTransactions = 'Transactions';

  static const List<IconData> _actionIcons = [
    Icons.account_balance_wallet_outlined,
    Icons.monetization_on_outlined,
    Icons.trending_down_outlined,
    Icons.swap_horiz_outlined,
  ];
  static const List<String> _actionKeys = [
    _kDeposit, _kUnitPrices, _kWithdrawal, _kTransactions,
  ];

  bool get _dark => context.watch<ThemeProvider>().isDark;
  _HS  get _s    => context.watch<LocaleProvider>().isSwahili ? _hsSw : _hsEn;

  bool get _onSMASlide =>
      _funds.isNotEmpty && _currentFundIndex == _funds.length;

  List<Map<String, dynamic>> get _activeTransactions =>
      _onSMASlide ? _smaCashTxns : _fundTransactions;

  bool get _isLoadingActiveTxns =>
      _onSMASlide ? _isLoadingSMATxns : _isLoadingFundTxns;

  double get _totalDeposits => _activeTransactions
      .where((t) => t['type'] == 'Deposit')
      .fold(0.0, (s, t) => s + (t['amount'] as double));
  double get _totalWithdrawals => _activeTransactions
      .where((t) => t['type'] == 'Withdrawal')
      .fold(0.0, (s, t) => s + (t['amount'] as double));

  @override
  void initState() {
    super.initState();
    _chartFadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
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

  // ── APIs ───────────────────────────────────────────────────────────────────
  Future<void> _fetchPortfolio() async {
    setState(() { _isLoadingFunds = true; _fundsError = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      _cdsNumber  = prefs.getString('cdsNumber') ?? '';
      final response = await http.post(
        Uri.parse('https://portaluat.tsl.co.tz/FMSAPI/home/GetFundsDetailed'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'APIUsername': 'User2',
          'APIPassword': 'CBZ1234#2',
          'cdsNumber':   _cdsNumber,
        }),
      ).timeout(const Duration(seconds: 15));
      final json = jsonDecode(response.body);
      if (response.statusCode == 200 && json['status'] == 'success') {
        final data         = json['data'];
        final List<dynamic> fundsRaw = data['funds'] ?? [];
        setState(() {
          _funds          = fundsRaw.map((f) => Map<String, dynamic>.from(f)).toList();
          _isLoadingFunds = false;
        });
        if (_funds.isNotEmpty) {
          _fetchFundTransactions(_funds[0]['fundName'] as String);
        }
        _fetchSMAData();
      } else {
        setState(() {
          _fundsError     = json['statusDesc'] ?? _s.failedLoad;
          _isLoadingFunds = false;
        });
      }
    } catch (_) {
      setState(() { _fundsError = _s.connectionError; _isLoadingFunds = false; });
    }
  }

  // ── Fund transactions ──────────────────────────────────────────────────────
  Future<void> _fetchFundTransactions(String fundName) async {
    setState(() { _isLoadingFundTxns = true; });
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
        final List<dynamic> raw = (data['data']['trans'] as List<dynamic>?) ?? [];
        final parsed = raw.map((j) {
          final desc      = (j['Description'] as String? ?? '').toLowerCase();
          final isDeposit = desc.contains('deposit') ||
              desc.contains('credit') || desc.contains('purchase');
          DateTime date;
          try {
            date = DateFormat('dd-MMM-yyyy HH:mm')
                .parse(j['TrxnDate'] as String? ?? '');
          } catch (_) { date = DateTime.now(); }
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
          _fundTransactions = parsed;
          _isLoadingFundTxns = false;
        });
        if (!_onSMASlide) _chartFadeCtrl..reset()..forward();
      } else {
        setState(() { _fundTransactions = []; _isLoadingFundTxns = false; });
      }
    } catch (_) {
      setState(() { _fundTransactions = []; _isLoadingFundTxns = false; });
    }
  }

  // ── SMA data ───────────────────────────────────────────────────────────────
  Future<void> _fetchSMAData() async {
    setState(() { _isLoadingSMA = true; _isLoadingSMATxns = true; });
    try {
      final results = await Future.wait([
        http.post(
          Uri.parse('https://portaluat.tsl.co.tz/FMSAPI/home/GetSMAPortfolios'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'APIUsername': 'User2', 'APIPassword': 'CBZ1234#2',
            'cdsNumber': _cdsNumber,
          }),
        ).timeout(const Duration(seconds: 15)),
        http.post(
          Uri.parse('https://portaluat.tsl.co.tz/FMSAPI/home/GetSMAInvestments'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'APIUsername': 'User2', 'APIPassword': 'CBZ1234#2',
            'cdsNumber': _cdsNumber,
          }),
        ).timeout(const Duration(seconds: 15)),
        http.post(
          Uri.parse('https://portaluat.tsl.co.tz/FMSAPI/home/GetSMACashTransactions'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'APIUsername': 'User2', 'APIPassword': 'CBZ1234#2',
            'cdsNumber': _cdsNumber,
          }),
        ).timeout(const Duration(seconds: 15)),
      ]);

      if (results[0].statusCode == 200) {
        final j = jsonDecode(results[0].body);
        if (j['status'] == 'success') {
          final raw = (j['data'] as List<dynamic>?) ?? [];
          _smaPortfolios = raw.map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }

      if (results[1].statusCode == 200) {
        final j = jsonDecode(results[1].body);
        if (j['status'] == 'success') {
          final d   = j['data'] as Map<String, dynamic>;
          final raw = (d['smaInvestments'] as List<dynamic>?) ?? [];
          _smaTotalPortfolio = (d['totalPortfolioValue'] as num?)?.toDouble() ?? 0.0;
          _smaCashBalance    = (d['cashBal'] as num?)?.toDouble() ?? 0.0;
          _smaInvestments = raw.map((item) {
            DateTime dt;
            try { dt = DateTime.parse(item['TrxnDate'] as String); }
            catch (_) { dt = DateTime.now(); }
            return {
              'description': item['Description'] as String? ?? '',
              'date':        dt,
              'txnId':       item['TrxnID']?.toString() ?? '',
              'amount':      (item['Amount'] as num?)?.toDouble() ?? 0.0,
            };
          }).toList();
        }
      }

      if (results[2].statusCode == 200) {
        final j = jsonDecode(results[2].body);
        if (j['status'] == 'success') {
          final d   = j['data'] as Map<String, dynamic>;
          final raw = (d['smaInvestments'] as List<dynamic>?) ?? [];
          if ((d['CashBalance'] as num?) != null) {
            _smaCashBalance = (d['CashBalance'] as num).toDouble();
          }
          _smaCashTxns = raw.map((item) {
            DateTime dt;
            try { dt = DateTime.parse(item['TrxnDate'] as String); }
            catch (_) { dt = DateTime.now(); }
            final amt  = (item['Amount'] as num?)?.toDouble() ?? 0.0;
            final desc = item['Description'] as String? ?? '';
            return {
              'type':   amt >= 0 ? 'Deposit' : 'Withdrawal',
              'amount': amt.abs(),
              'label':  desc,
              'date':   dt,
              'id':     item['TrxnID']?.toString() ?? '',
            };
          }).toList()
            ..sort((a, b) =>
                (a['date'] as DateTime).compareTo(b['date'] as DateTime));
        }
      }

      setState(() {
        _isLoadingSMA     = false;
        _isLoadingSMATxns = false;
      });
      if (_onSMASlide) _chartFadeCtrl..reset()..forward();
    } catch (_) {
      setState(() { _isLoadingSMA = false; _isLoadingSMATxns = false; });
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _fmt(double v, {int decimals = 2}) {
    final parts     = v.toStringAsFixed(decimals).split('.');
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

  String _actionLabel(String key, _HS s) {
    switch (key) {
      case _kDeposit:      return s.deposit;
      case _kUnitPrices:   return s.unitPrices;
      case _kWithdrawal:   return s.withdrawal;
      case _kTransactions: return s.transactions;
      default:             return key;
    }
  }

  void _onActionTap(String key) {
    Widget? page;
    switch (key) {
      case _kDeposit:      page = const DepositPage(); break;
      case _kUnitPrices:   page = const SMAPage(); break;
      case _kWithdrawal:   page = const WithdrawalPage(); break;
      case _kTransactions: page = const ClientStatementPage(); break;
    }
    if (page != null) {
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => page!));
    }
  }

  // ── Build line chart data points from transactions ─────────────────────────
  List<_LinePoint> _buildLinePoints() {
    if (_activeTransactions.isEmpty) return [];
    double running = 0;
    final points = <_LinePoint>[];
    for (final t in _activeTransactions) {
      final amt = t['amount'] as double;
      running += t['type'] == 'Deposit' ? amt : -amt;
      points.add(_LinePoint(
        date:  t['date']  as DateTime,
        value: running,
        type:  t['type']  as String,
      ));
    }
    return points;
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    context.watch<LocaleProvider>();

    final dark    = _dark;
    final s       = _s;
    final txtP    = dark ? const Color(0xFFE8F5E9) : Colors.black87;
    final txtS    = dark ? const Color(0xFF81A884)  : Colors.black54;
    final txtH    = dark ? const Color(0xFF4A7A4D)  : Colors.grey.shade400;
    final green   = dark ? const Color(0xFF4ADE80)  : const Color(0xFF1B5E20);
    final cardBg  = dark ? const Color(0xFF132013)  : Colors.white.withOpacity(0.62);
    final cardBg2 = dark ? const Color(0xFF0F1A10)  : Colors.white.withOpacity(0.55);
    final border  = dark ? const Color(0xFF1E3320)  : Colors.white.withOpacity(0.7);
    final divider = dark ? const Color(0xFF1E3320)  : Colors.black.withOpacity(0.05);

    final int totalSlides = _funds.isNotEmpty ? _funds.length + 1 : 0;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          gradient: dark
              ? const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF0B1A0C), Color(0xFF0D1A0E), Color(0xFF111D12)])
              : const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFFB8E6D3), Color(0xFF98D8C8), Color(0xFFFFE5B4)]),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 20, 15, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                _buildPortfolioSection(dark, txtP, txtS, s),
                const SizedBox(height: 10),

                if (!_isLoadingFunds && _fundsError == null && totalSlides > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(totalSlides, (i) {
                      final active    = i == _currentFundIndex;
                      final isSmaDot  = i == _funds.length;
                      final dotColor  = active
                          ? (isSmaDot ? const Color(0xFF0891B2) : green)
                          : (dark ? Colors.white24 : Colors.black26);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 20 : 8, height: 8,
                        decoration: BoxDecoration(
                            color: dotColor,
                            borderRadius: BorderRadius.circular(4)),
                      );
                    }),
                  ),

                const SizedBox(height: 16),

                _buildDSETradingButton(dark, txtP, txtS, border, s),
                const SizedBox(height: 14),

                Row(
                  children: List.generate(_actionKeys.length, (i) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          right: i < _actionKeys.length - 1 ? 10 : 0),
                      child: _buildActionButton(
                        icon:  _actionIcons[i],
                        label: _actionLabel(_actionKeys[i], s),
                        dark:  dark, txtP: txtP,
                        onTap: () => _onActionTap(_actionKeys[i]),
                      ),
                    ),
                  )),
                ),

                const SizedBox(height: 20),

                _buildTransactionsSection(
                    dark, txtP, txtS, txtH, green,
                    cardBg, cardBg2, border, divider, s),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── DSE Trading banner ─────────────────────────────────────────────────────
  Widget _buildDSETradingButton(
      bool dark, Color txtP, Color txtS, Color border, _HS s,
      ) {
    const Color accent = Color(0xFF0891B2);
    final bg = dark
        ? const Color(0xFF0C1F2A).withOpacity(0.9)
        : Colors.white.withOpacity(0.45);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const TradeDashboard())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 1.2),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(dark ? 0.2 : 0.05),
              blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(11)),
            child: const Icon(Icons.candlestick_chart_outlined,
                color: accent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.dseTrading, style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800, color: txtP)),
            const SizedBox(height: 2),
            Text('Dar es Salaam Stock Exchange',
                style: TextStyle(fontSize: 11, color: txtS)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accent.withOpacity(0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 6, height: 6,
                  decoration: const BoxDecoration(
                      color: accent, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              const Text('Live', style: TextStyle(
                  fontSize: 10, color: accent, fontWeight: FontWeight.w700)),
            ]),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: accent.withOpacity(0.10),
                borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.arrow_forward_ios_rounded,
                color: accent, size: 13),
          ),
        ]),
      ),
    );
  }

  // ── Transactions section ───────────────────────────────────────────────────
  Widget _buildTransactionsSection(
      bool dark, Color txtP, Color txtS, Color txtH, Color green,
      Color cardBg, Color cardBg2, Color border, Color divider, _HS s,
      ) {
    const Color smaAccent = Color(0xFF0891B2);
    final sectionLabel =
    _onSMASlide ? s.smaTransactions : s.recentTransactions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                Text(sectionLabel, style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: txtP)),
                if (_onSMASlide) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: smaAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: smaAccent.withOpacity(0.3)),
                    ),
                    child: const Text('SMA', style: TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w800,
                        color: smaAccent)),
                  ),
                ],
              ]),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => _onSMASlide
                            ? const SMAPage()
                            : const ClientStatementPage())),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: _onSMASlide ? smaAccent : green,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(
                        color: (_onSMASlide ? smaAccent : green)
                            .withOpacity(0.3),
                        blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(s.seeAll, style: const TextStyle(
                        fontSize: 12, color: Colors.white,
                        fontWeight: FontWeight.w700)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 10, color: Colors.white),
                  ]),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        if (!_isLoadingActiveTxns && _activeTransactions.isNotEmpty) ...[
          _buildSummaryPills(dark, s),
          const SizedBox(height: 14),
        ],

        if (_onSMASlide)
          _buildSMAInvestmentsPreview(dark, txtP, txtS, txtH, border, s)
        else
          _buildLineChartCard(dark, txtP, txtS, green, cardBg, border, s),

        const SizedBox(height: 16),
        _buildRecentList(dark, txtP, txtS, cardBg, divider, s),
      ],
    );
  }

  // ── Summary pills ──────────────────────────────────────────────────────────
  Widget _buildSummaryPills(bool dark, _HS s) {
    final net        = _totalDeposits - _totalWithdrawals;
    final isPositive = net >= 0;
    final depFg = _onSMASlide
        ? const Color(0xFF0891B2) : const Color(0xFF2E7D32);
    final depBg = dark ? const Color(0xFF1A2E1A) : const Color(0xFFE8F5E9);
    final witBg = dark ? const Color(0xFF2A1010) : const Color(0xFFFFEBEE);
    final netBg = isPositive
        ? (dark ? const Color(0xFF0D1F30) : const Color(0xFFE3F2FD))
        : (dark ? const Color(0xFF1E0A2A) : const Color(0xFFF3E5F5));

    return Row(children: [
      _summaryPill(s.deposits, 'TZS ${_shortAmt(_totalDeposits)}',
          Icons.arrow_downward_rounded, depFg, depBg),
      const SizedBox(width: 10),
      _summaryPill(s.withdrawals, 'TZS ${_shortAmt(_totalWithdrawals)}',
          Icons.arrow_upward_rounded, const Color(0xFFC62828), witBg),
      const SizedBox(width: 10),
      _summaryPill(s.netFlow,
          '${isPositive ? '+' : ''}TZS ${_shortAmt(net)}',
          isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
          isPositive ? const Color(0xFF1565C0) : const Color(0xFF6A1B9A),
          netBg),
    ]);
  }

  Widget _summaryPill(String label, String value,
      IconData icon, Color fg, Color bg) =>
      Expanded(
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
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(fontSize: 9,
                  color: fg.withOpacity(0.7), fontWeight: FontWeight.w500)),
              Text(value, style: TextStyle(fontSize: 11,
                  fontWeight: FontWeight.w800, color: fg),
                  overflow: TextOverflow.ellipsis),
            ])),
          ]),
        ),
      );

  // ── SMA investment preview ─────────────────────────────────────────────────
  Widget _buildSMAInvestmentsPreview(
      bool dark, Color txtP, Color txtS, Color txtH, Color border, _HS s,
      ) {
    const Color accent = Color(0xFF0891B2);
    final cardBg = dark
        ? const Color(0xFF132013) : Colors.white.withOpacity(0.62);

    if (_isLoadingSMA) {
      return Container(
        height: 130,
        decoration: BoxDecoration(color: cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: border, width: 1.5)),
        child: Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center, children: [
          const SizedBox(width: 22, height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: accent)),
          const SizedBox(height: 10),
          Text(s.loadingSMA, style: TextStyle(fontSize: 12, color: txtS)),
        ])),
      );
    }

    if (_smaInvestments.isEmpty) {
      return Container(
        height: 110,
        decoration: BoxDecoration(color: cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: border, width: 1.5)),
        child: Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.account_tree_outlined, size: 32, color: txtS.withOpacity(0.4)),
          const SizedBox(height: 8),
          Text(s.noSMA, style: TextStyle(fontSize: 13, color: txtS)),
        ])),
      );
    }

    final preview = _smaInvestments.take(3).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border, width: 1.5),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(dark ? 0.2 : 0.06),
            blurRadius: 12, offset: const Offset(0, 5))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
                color: accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(9)),
            child: const Icon(Icons.account_tree_outlined, color: accent, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.smaTitle, style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800, color: txtP)),
            Text('${_smaInvestments.length} active investments',
                style: TextStyle(fontSize: 10, color: txtS)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('Total', style: TextStyle(fontSize: 9, color: txtH)),
            Text('TZS ${_shortAmt(_smaTotalPortfolio)}',
                style: const TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w800, color: accent)),
          ]),
        ]),
        const SizedBox(height: 14),
        ...preview.map((inv) {
          final desc   = inv['description'] as String;
          final amount = inv['amount'] as double;
          final date   = inv['date'] as DateTime;
          final bank   = desc.trim().split(RegExp(r'\s+@|\s+%')).first.trim();
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: accent.withOpacity(dark ? 0.06 : 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withOpacity(0.15)),
            ),
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                    color: accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text(
                  bank.isNotEmpty ? bank[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 14,
                      fontWeight: FontWeight.w900, color: accent),
                )),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(bank, style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: txtP),
                    overflow: TextOverflow.ellipsis),
                Text(DateFormat('dd MMM yyyy').format(date),
                    style: TextStyle(fontSize: 10, color: txtS)),
              ])),
              Text('TZS ${_shortAmt(amount)}',
                  style: const TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w800, color: accent)),
            ]),
          );
        }),
        if (_smaInvestments.length > 3) ...[
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SMAPage())),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: accent.withOpacity(dark ? 0.10 : 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withOpacity(0.25)),
              ),
              child: Text(
                '+ ${_smaInvestments.length - 3} more · ${s.viewDashboard}',
                style: const TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w700, color: accent),
              ),
            ),
          ),
        ],
      ]),
    );
  }

  // ── Beautiful Line Chart Card ──────────────────────────────────────────────
  Widget _buildLineChartCard(
      bool dark, Color txtP, Color txtS, Color green,
      Color cardBg, Color border, _HS s,
      ) {
    final points     = _buildLinePoints();
    final labelColor = dark ? const Color(0xFF81A884) : Colors.black38;
    final gridColor  = dark
        ? Colors.white.withOpacity(0.05)
        : Colors.black.withOpacity(0.05);

    // Determine trend colour: green if net positive, red if negative
    final double lastVal = points.isNotEmpty ? points.last.value : 0;
    final lineColor = lastVal >= 0 ? green : Colors.red.shade400;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border, width: 1.5),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(dark ? 0.2 : 0.06),
            blurRadius: 12, offset: const Offset(0, 5))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header ──
        Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
                color: lineColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(9)),
            child: Icon(Icons.show_chart_rounded, color: lineColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.txnLineChart, style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800, color: txtP)),
            if (!_isLoadingFundTxns && points.isNotEmpty)
              Text(
                '${points.length} ${s.tradingDays} · '
                    '${_currentFundIndex < _funds.length ? _funds[_currentFundIndex]['fundName'] : ''}',
                style: TextStyle(fontSize: 10, color: txtS),
              ),
          ])),
          // Trend badge
          if (!_isLoadingFundTxns && points.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: lineColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: lineColor.withOpacity(0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  lastVal >= 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 12, color: lineColor,
                ),
                const SizedBox(width: 4),
                Text(
                  'TZS ${_shortAmt(lastVal.abs())}',
                  style: TextStyle(
                      fontSize: 10, color: lineColor,
                      fontWeight: FontWeight.w800),
                ),
              ]),
            ),
        ]),

        const SizedBox(height: 16),

        // ── Chart area ──
        SizedBox(
          height: 200,
          child: _isLoadingFundTxns
              ? Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: green)),
            const SizedBox(height: 10),
            Text(s.loadingChart,
                style: TextStyle(fontSize: 12, color: txtS)),
          ]))
              : points.isEmpty
              ? Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.show_chart_rounded,
                size: 40, color: txtS.withOpacity(0.4)),
            const SizedBox(height: 10),
            Text(s.noTransactions,
                style: TextStyle(fontSize: 13, color: txtS)),
          ]))
              : FadeTransition(
            opacity: _chartFadeAnim,
            child: _LineChart(
              points:     points,
              lineColor:  lineColor,
              labelColor: labelColor,
              gridColor:  gridColor,
              shortAmt:   _shortAmt,
              dark:       dark,
            ),
          ),
        ),
      ]),
    );
  }

  // ── Recent transactions list ───────────────────────────────────────────────
  Widget _buildRecentList(
      bool dark, Color txtP, Color txtS, Color cardBg, Color divider, _HS s,
      ) {
    if (_isLoadingActiveTxns || _activeTransactions.isEmpty) {
      return const SizedBox.shrink();
    }
    const Color smaAccent = Color(0xFF0891B2);
    final depositColor =
    _onSMASlide ? smaAccent : const Color(0xFF2E7D32);
    final recent = _activeTransactions.reversed.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(_s.latestActivity, style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700, color: txtS)),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: dark
                    ? const Color(0xFF1E3320)
                    : Colors.white.withOpacity(0.8),
                width: 1.5),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(dark ? 0.2 : 0.05),
                blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recent.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: divider, indent: 66),
            itemBuilder: (_, i) => _buildTxnRow(
                recent[i], dark, txtP, txtS, depositColor),
          ),
        ),
      ],
    );
  }

  Widget _buildTxnRow(
      Map<String, dynamic> txn, bool dark, Color txtP, Color txtS,
      Color depositColor,
      ) {
    final isDeposit = txn['type'] == 'Deposit';
    final color   = isDeposit ? depositColor : const Color(0xFFC62828);
    final bgColor = isDeposit
        ? (dark ? const Color(0xFF1A2E1A) : const Color(0xFFE8F5E9))
        : (dark ? const Color(0xFF2A1010) : const Color(0xFFFFEBEE));
    final icon    = isDeposit
        ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    final amount  = txn['amount'] as double;
    final date    = txn['date']   as DateTime;
    final label   = txn['label']  as String;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(children: [
        Container(width: 42, height: 42,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18)),
        const SizedBox(width: 12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 13,
              fontWeight: FontWeight.w700, color: txtP),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Text(DateFormat('dd MMM yyyy').format(date),
              style: TextStyle(fontSize: 11, color: txtS)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${isDeposit ? '+' : '-'} TZS',
              style: TextStyle(fontSize: 9,
                  color: color.withOpacity(0.6),
                  fontWeight: FontWeight.w600)),
          Text(_fmt(amount), style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w900, color: color)),
        ]),
      ]),
    );
  }

  // ── Portfolio section ──────────────────────────────────────────────────────
  Widget _buildPortfolioSection(
      bool dark, Color txtP, Color txtS, _HS s,
      ) {
    if (_isLoadingFunds) {
      return _blankCard(height: 175, color: const Color(0xFF1B5E20),
        child: Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center, children: [
          const CircularProgressIndicator(
              color: Colors.white54, strokeWidth: 2),
          const SizedBox(height: 12),
          Text(s.loadingPortfolio,
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
        ])),
      );
    }
    if (_fundsError != null) {
      return _blankCard(height: 175, color: const Color(0xFF1B5E20),
        child: Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.cloud_off_outlined, color: Colors.white54, size: 28),
          const SizedBox(height: 8),
          Text(_fundsError!, textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _fetchPortfolio,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white30)),
              child: Text(s.retry,
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
            ),
          ),
        ])),
      );
    }

    final int totalSlides = _funds.length + 1;

    return SizedBox(
      height: 175,
      child: PageView.builder(
        controller: _fundPageController,
        itemCount: totalSlides,
        onPageChanged: (i) {
          setState(() => _currentFundIndex = i);
          if (i < _funds.length) {
            _fetchFundTransactions(_funds[i]['fundName'] as String);
          } else {
            if (_smaCashTxns.isNotEmpty) {
              _chartFadeCtrl..reset()..forward();
            }
          }
        },
        itemBuilder: (_, i) {
          if (i == _funds.length) {
            return _buildSMASlideCard(dark, txtP, txtS, s);
          }
          return _buildFundCard(_funds[i], i, dark, txtP, txtS, s);
        },
      ),
    );
  }

  // ── SMA slide card ─────────────────────────────────────────────────────────
  Widget _buildSMASlideCard(bool dark, Color txtP, Color txtS, _HS s) {
    const Color accent = Color(0xFF0891B2);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(PageRouteBuilder(
        pageBuilder: (_, a, __) => const SMAPage(),
        transitionsBuilder: (_, a, __, child) {
          final c = CurvedAnimation(parent: a, curve: Curves.easeInOut);
          return FadeTransition(
            opacity: c,
            child: SlideTransition(
              position: Tween<Offset>(
                  begin: const Offset(0.04, 0), end: Offset.zero).animate(c),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 380),
      )),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF0C4A6E), Color(0xFF0891B2)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: accent.withOpacity(0.4),
              blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Stack(children: [
          Positioned(right: -20, top: -20, child: _circle(110, 0.07)),
          Positioned(right: 40, bottom: -25, child: _circle(70, 0.05)),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white24, width: 1)),
                  child: const Icon(Icons.account_tree_outlined,
                      color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('SMA', style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w800,
                      color: Colors.white70, letterSpacing: 0.5)),
                  Text(s.smaTitle, style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800,
                      color: Colors.white, letterSpacing: 0.1),
                      overflow: TextOverflow.ellipsis),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24, width: 1)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.touch_app_outlined,
                        color: Colors.white70, size: 11),
                    const SizedBox(width: 4),
                    Text(s.viewDashboard, style: const TextStyle(
                        fontSize: 9, color: Colors.white70,
                        fontWeight: FontWeight.w600)),
                  ]),
                ),
              ]),
              const Spacer(),
              if (_isLoadingSMA)
                const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white54, strokeWidth: 2))
              else
                Row(children: [
                  Expanded(flex: 5, child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.totalValue, style: TextStyle(fontSize: 10,
                        color: Colors.white.withOpacity(0.5),
                        fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    _smaTotalPortfolio > 0
                        ? Text(
                        _isBalanceVisible
                            ? 'TZS ${_fmt(_smaTotalPortfolio)}'
                            : _mask(''),
                        style: const TextStyle(fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Colors.white, letterSpacing: -0.3))
                        : Text(s.notInvestedYet, style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.4),
                        fontStyle: FontStyle.italic)),
                  ])),
                  _vDivider(),
                  Expanded(flex: 4, child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.cashBalance, style: TextStyle(fontSize: 10,
                        color: Colors.white.withOpacity(0.5),
                        fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(
                      _isBalanceVisible
                          ? 'TZS ${_fmt(_smaCashBalance)}'
                          : _mask(''),
                      style: const TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ])),
                  _vDivider(),
                  Expanded(flex: 3, child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.holdings, style: TextStyle(fontSize: 10,
                        color: Colors.white.withOpacity(0.5),
                        fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text('${_smaInvestments.length}',
                        style: const TextStyle(fontSize: 13,
                            fontWeight: FontWeight.w700, color: Colors.white)),
                  ])),
                ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _blankCard({required Widget child, required Color color,
    double height = 175}) =>
      Container(
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [color, color.withOpacity(0.75)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: color.withOpacity(0.3),
              blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: child,
      );

  Widget _buildFundCard(Map<String, dynamic> fund, int index,
      bool dark, Color txtP, Color txtS, _HS s,
      ) {
    final baseColor     = _cardColor(index);
    final portfolioVal  = (fund['portfolioValue'] as num).toDouble();
    final units         = (fund['investorUnits']  as num).toDouble();
    final nav           = (fund['nav']            as num).toDouble();
    final status        = fund['status'] as String;
    final hasInvestment = portfolioVal > 0;

    Color statusColor; IconData statusIcon;
    switch (status.toLowerCase()) {
      case 'active':
        statusColor = const Color(0xFF69F0AE);
        statusIcon  = Icons.check_circle_outline; break;
      case 'ipo':
        statusColor = const Color(0xFFFFD740);
        statusIcon  = Icons.new_releases_outlined; break;
      default:
        statusColor = Colors.white38;
        statusIcon  = Icons.info_outline;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [baseColor, baseColor.withOpacity(0.72)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: baseColor.withOpacity(0.45),
            blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Stack(children: [
        Positioned(right: -20, top: -20, child: _circle(110, 0.05)),
        Positioned(right: 40, bottom: -25, child: _circle(70, 0.04)),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24, width: 1)),
                child: Text(fund['fundCode'] as String,
                    style: const TextStyle(fontSize: 10,
                        fontWeight: FontWeight.w800, color: Colors.white70,
                        letterSpacing: 0.5)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(fund['fundName'] as String,
                    style: const TextStyle(fontSize: 14,
                        fontWeight: FontWeight.w800, color: Colors.white,
                        letterSpacing: 0.1),
                    overflow: TextOverflow.ellipsis),
                Text(fund['description'] as String,
                    style: TextStyle(fontSize: 10,
                        color: Colors.white.withOpacity(0.55))),
              ])),
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
                  Text(status, style: TextStyle(fontSize: 10,
                      fontWeight: FontWeight.w700, color: statusColor)),
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
                    color: Colors.white38, size: 17),
              ),
            ]),
            const Spacer(),
            Row(children: [
              Expanded(flex: 5, child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.portfolioValue, style: TextStyle(fontSize: 10,
                    color: Colors.white.withOpacity(0.5),
                    fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                hasInvestment
                    ? Text(
                    _isBalanceVisible
                        ? 'TZS ${_fmt(portfolioVal)}' : _mask(''),
                    style: const TextStyle(fontSize: 17,
                        fontWeight: FontWeight.w900, color: Colors.white,
                        letterSpacing: -0.3))
                    : Text(s.notInvestedYet, style: TextStyle(
                    fontSize: 12, color: Colors.white.withOpacity(0.4),
                    fontStyle: FontStyle.italic)),
              ])),
              _vDivider(),
              Expanded(flex: 3, child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.myUnits, style: TextStyle(fontSize: 10,
                    color: Colors.white.withOpacity(0.5),
                    fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(_isBalanceVisible ? _fmt(units) : _mask(''),
                    style: const TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w700, color: Colors.white)),
              ])),
              _vDivider(),
              Expanded(flex: 3, child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.nav, style: TextStyle(fontSize: 10,
                    color: Colors.white.withOpacity(0.5),
                    fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(_fmt(nav), style: const TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w700, color: Colors.white)),
              ])),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _circle(double size, double opacity) => Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle,
          color: Colors.white.withOpacity(opacity)));

  Widget _vDivider() => Container(
      width: 1, height: 34, color: Colors.white12,
      margin: const EdgeInsets.symmetric(horizontal: 10));

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool dark,
    required Color txtP,
    required VoidCallback onTap,
  }) {
    final containerBg = dark
        ? const Color(0xFF132013).withOpacity(0.85)
        : Colors.white.withOpacity(0.35);
    final containerBorder = dark
        ? const Color(0xFF1E3320) : Colors.white.withOpacity(0.6);
    final iconBg = dark
        ? const Color(0xFF1A2B1B) : Colors.white.withOpacity(0.5);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 78,
        decoration: BoxDecoration(
          color: containerBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: containerBorder, width: 1),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 38, height: 38,
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(11)),
              child: Icon(icon, color: txtP, size: 19)),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: txtP,
                  fontWeight: FontWeight.w600, height: 1.2)),
        ]),
      ),
    );
  }
}

// ── Line data model ────────────────────────────────────────────────────────────
class _LinePoint {
  final DateTime date;
  final double value;
  final String type; // 'Deposit' | 'Withdrawal'
  const _LinePoint({required this.date, required this.value, required this.type});
}

// ── Line chart widget ──────────────────────────────────────────────────────────
class _LineChart extends StatefulWidget {
  final List<_LinePoint> points;
  final Color lineColor, labelColor, gridColor;
  final String Function(double) shortAmt;
  final bool dark;

  const _LineChart({
    required this.points,
    required this.lineColor,
    required this.labelColor,
    required this.gridColor,
    required this.shortAmt,
    required this.dark,
  });

  @override
  State<_LineChart> createState() => _LineChartState();
}

class _LineChartState extends State<_LineChart>
    with SingleTickerProviderStateMixin {
  int? _hoveredIndex;
  late AnimationController _lineAnimCtrl;
  late Animation<double>   _lineAnim;

  @override
  void initState() {
    super.initState();
    _lineAnimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _lineAnim = CurvedAnimation(parent: _lineAnimCtrl, curve: Curves.easeInOut);
    _lineAnimCtrl.forward();
  }

  @override
  void dispose() {
    _lineAnimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      const double yLabelW = 46.0;
      const double xLabelH = 22.0;
      final double chartW  = w - yLabelW - 8;
      final double chartH  = h - xLabelH;

      final values  = widget.points.map((p) => p.value).toList();
      final dataMax = values.reduce(max);
      final dataMin = values.reduce(min);
      final range   = (dataMax - dataMin) == 0 ? 1.0 : (dataMax - dataMin);
      final visMax  = dataMax + range * 0.15;
      final visMin  = dataMin - range * 0.15;
      final visRange = visMax - visMin;

      double toY(double v) => chartH - ((v - visMin) / visRange) * chartH;
      double toX(int i)    => yLabelW + (i / (widget.points.length - 1)) * chartW;

      final int n         = widget.points.length;
      final int labelStep = max(1, (n / 5).ceil());

      return GestureDetector(
        onTapDown: (d) {
          final localX = d.localPosition.dx - yLabelW;
          final ratio  = (localX / chartW).clamp(0.0, 1.0);
          final idx    = (ratio * (n - 1)).round().clamp(0, n - 1);
          setState(() => _hoveredIndex = idx);
        },
        onHorizontalDragUpdate: (d) {
          final localX = d.localPosition.dx - yLabelW;
          final ratio  = (localX / chartW).clamp(0.0, 1.0);
          final idx    = (ratio * (n - 1)).round().clamp(0, n - 1);
          setState(() => _hoveredIndex = idx);
        },
        onTapUp: (_) => setState(() => _hoveredIndex = null),
        onHorizontalDragEnd: (_) => setState(() => _hoveredIndex = null),
        child: AnimatedBuilder(
          animation: _lineAnim,
          builder: (_, __) {
            return Stack(children: [

              // ── Chart canvas ──
              Positioned(left: yLabelW, top: 0, width: chartW + 8, height: chartH,
                child: CustomPaint(
                  painter: _LinePainter(
                    points:       widget.points,
                    lineColor:    widget.lineColor,
                    gridColor:    widget.gridColor,
                    hoveredIndex: _hoveredIndex,
                    visMin:       visMin,
                    visRange:     visRange,
                    chartH:       chartH,
                    chartW:       chartW,
                    progress:     _lineAnim.value,
                    dark:         widget.dark,
                  ),
                ),
              ),

              // ── Y-axis labels ──
              ...List.generate(5, (i) {
                final v = visMin + visRange * i / 4;
                final y = toY(v);
                return Positioned(
                  left: 0, top: y - 7, width: yLabelW - 4,
                  child: Text(widget.shortAmt(v),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 9, color: widget.labelColor)),
                );
              }),

              // ── X-axis date labels ──
              ...List.generate(n, (i) {
                if (i % labelStep != 0 && i != n - 1) return const SizedBox.shrink();
                final cx = toX(i);
                return Positioned(
                  left: cx - 18, top: chartH + 3, width: 36,
                  child: Text(
                    DateFormat('dd/MM').format(widget.points[i].date),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 9, color: widget.labelColor),
                  ),
                );
              }),

              // ── Tooltip ──
              if (_hoveredIndex != null && _lineAnim.value == 1.0)
                Builder(builder: (_) {
                  final idx = _hoveredIndex!;
                  final pt  = widget.points[idx];
                  final cx  = toX(idx);
                  final cy  = toY(pt.value);
                  const double ttW = 110.0;
                  double ttLeft    = cx + 10;
                  if (ttLeft + ttW > w) ttLeft = cx - ttW - 10;
                  final ttTop = max(0.0, cy - 70.0);
                  return Positioned(
                    left: ttLeft, top: ttTop,
                    child: Container(
                      width: ttW,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: widget.dark
                            ? const Color(0xFF0D2E10)
                            : const Color(0xFF1B5E20),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(DateFormat('dd MMM yyyy').format(pt.date),
                                style: const TextStyle(fontSize: 9,
                                    color: Colors.white60,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Row(children: [
                              Container(
                                width: 6, height: 6,
                                decoration: BoxDecoration(
                                    color: pt.type == 'Deposit'
                                        ? const Color(0xFF69F0AE)
                                        : Colors.red.shade300,
                                    shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 5),
                              Text(pt.type,
                                  style: TextStyle(
                                      fontSize: 9,
                                      color: pt.type == 'Deposit'
                                          ? const Color(0xFF69F0AE)
                                          : Colors.red.shade300,
                                      fontWeight: FontWeight.w700)),
                            ]),
                            const SizedBox(height: 3),
                            Text('TZS ${widget.shortAmt(pt.value)}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900)),
                          ]),
                    ),
                  );
                }),
            ]);
          },
        ),
      );
    });
  }
}

// ── Line painter ───────────────────────────────────────────────────────────────
class _LinePainter extends CustomPainter {
  final List<_LinePoint> points;
  final Color lineColor, gridColor;
  final int? hoveredIndex;
  final double visMin, visRange, chartH, chartW, progress;
  final bool dark;

  _LinePainter({
    required this.points,
    required this.lineColor,
    required this.gridColor,
    required this.hoveredIndex,
    required this.visMin,
    required this.visRange,
    required this.chartH,
    required this.chartW,
    required this.progress,
    required this.dark,
  });

  double _toY(double v) => chartH - ((v - visMin) / visRange) * chartH;
  double _toX(int i)    => (i / (points.length - 1)) * chartW;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final n = points.length;

    // ── Grid ──
    final gridPaint = Paint()
      ..color       = gridColor
      ..strokeWidth = 1
      ..style       = PaintingStyle.stroke;
    for (int i = 0; i <= 4; i++) {
      final y = chartH * i / 4;
      final path = Path();
      double x = 0;
      while (x < size.width) {
        path.moveTo(x, y);
        path.lineTo(x + 4, y);
        x += 9;
      }
      canvas.drawPath(path, gridPaint);
    }

    // ── Build full path ──
    final allOffsets = List.generate(n, (i) {
      return Offset(_toX(i), _toY(points[i].value));
    });

    // ── Clip to progress (animate drawing) ──
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, chartW * progress, chartH));

    // ── Gradient fill ──
    final fillPath = Path();
    fillPath.moveTo(allOffsets.first.dx, chartH);
    fillPath.lineTo(allOffsets.first.dx, allOffsets.first.dy);

    for (int i = 0; i < n - 1; i++) {
      final p0 = allOffsets[i];
      final p1 = allOffsets[i + 1];
      final cpX = (p0.dx + p1.dx) / 2;
      fillPath.cubicTo(cpX, p0.dy, cpX, p1.dy, p1.dx, p1.dy);
    }

    fillPath.lineTo(allOffsets.last.dx, chartH);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withOpacity(dark ? 0.35 : 0.20),
          lineColor.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, chartW, chartH))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // ── Smooth line ──
    final linePath = Path();
    linePath.moveTo(allOffsets.first.dx, allOffsets.first.dy);
    for (int i = 0; i < n - 1; i++) {
      final p0 = allOffsets[i];
      final p1 = allOffsets[i + 1];
      final cpX = (p0.dx + p1.dx) / 2;
      linePath.cubicTo(cpX, p0.dy, cpX, p1.dy, p1.dx, p1.dy);
    }

    // Glow effect
    canvas.drawPath(
      linePath,
      Paint()
        ..color       = lineColor.withOpacity(0.25)
        ..strokeWidth = 6
        ..style       = PaintingStyle.stroke
        ..strokeCap   = StrokeCap.round
        ..strokeJoin  = StrokeJoin.round
        ..maskFilter  = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Main line
    canvas.drawPath(
      linePath,
      Paint()
        ..color       = lineColor
        ..strokeWidth = 2.5
        ..style       = PaintingStyle.stroke
        ..strokeCap   = StrokeCap.round
        ..strokeJoin  = StrokeJoin.round,
    );

    canvas.restore();

    // ── Data point dots (only when fully drawn) ──
    if (progress == 1.0) {
      final int step = max(1, (n / 8).ceil());
      for (int i = 0; i < n; i++) {
        if (i % step != 0 && i != n - 1 && i != hoveredIndex) continue;
        final o         = allOffsets[i];
        final isHovered = i == hoveredIndex;
        final r         = isHovered ? 6.0 : 3.5;

        if (isHovered) {
          // Vertical crosshair
          canvas.drawLine(
            Offset(o.dx, 0), Offset(o.dx, chartH),
            Paint()
              ..color       = lineColor.withOpacity(0.25)
              ..strokeWidth = 1
              ..style       = PaintingStyle.stroke,
          );
          // Halo
          canvas.drawCircle(o, 10,
              Paint()..color = lineColor.withOpacity(0.15));
        }

        // Outer white ring
        canvas.drawCircle(o, r + 1.5,
            Paint()..color = (dark ? Colors.black : Colors.white)
              ..style = PaintingStyle.fill);

        // Coloured dot
        canvas.drawCircle(o, r,
            Paint()..color = lineColor ..style = PaintingStyle.fill);
      }
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.hoveredIndex != hoveredIndex ||
          old.progress     != progress     ||
          old.points       != points;
}