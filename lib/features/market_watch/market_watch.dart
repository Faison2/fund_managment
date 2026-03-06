import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ─── Data model ───────────────────────────────────────────────────────────────
class _Security {
  final String symbol;
  final int bidQty;
  final double bid;
  final double offer;
  final int askQty;
  final double last;
  final double chg;
  final double pctChg;
  final String time;

  const _Security({
    required this.symbol,
    required this.bidQty,
    required this.bid,
    required this.offer,
    required this.askQty,
    required this.last,
    required this.chg,
    required this.pctChg,
    required this.time,
  });
}

// ─── Static DSE seed data ─────────────────────────────────────────────────────
final List<_Security> _seedData = [
  _Security(symbol: 'AFRIPRISE', bidQty: 837,   bid: 820,   offer: 820,   askQty: 250,    last: 820,   chg: -25.00,  pctChg: -2.96, time: '13:13:44'),
  _Security(symbol: 'CRDB',      bidQty: 0,     bid: 2530,  offer: 2530,  askQty: 200,    last: 2530,  chg: -130.00, pctChg: -4.89, time: '13:13:44'),
  _Security(symbol: 'DCB',       bidQty: 5891,  bid: 665,   offer: 665,   askQty: 119936, last: 665,   chg: -115.00, pctChg: -14.74,time: '13:13:44'),
  _Security(symbol: 'DSE',       bidQty: 20,    bid: 6420,  offer: 6440,  askQty: 100,    last: 6440,  chg: -60.00,  pctChg: -0.92, time: '13:13:44'),
  _Security(symbol: 'IEACLC-ETF',bidQty: 300,   bid: 1290,  offer: 1300,  askQty: 43,     last: 1300,  chg: 0.00,    pctChg: 0.00,  time: '13:13:44'),
  _Security(symbol: 'JHL',       bidQty: 1200,  bid: 540,   offer: 545,   askQty: 800,    last: 545,   chg: 5.00,    pctChg: 0.93,  time: '13:14:10'),
  _Security(symbol: 'KA',        bidQty: 400,   bid: 310,   offer: 315,   askQty: 600,    last: 315,   chg: 10.00,   pctChg: 3.28,  time: '13:14:10'),
  _Security(symbol: 'MAENDELEO', bidQty: 2500,  bid: 430,   offer: 435,   askQty: 1100,   last: 435,   chg: -5.00,   pctChg: -1.14, time: '13:14:22'),
  _Security(symbol: 'MCB',       bidQty: 750,   bid: 900,   offer: 910,   askQty: 320,    last: 910,   chg: 20.00,   pctChg: 2.25,  time: '13:14:22'),
  _Security(symbol: 'MBP',       bidQty: 1800,  bid: 220,   offer: 225,   askQty: 900,    last: 225,   chg: 0.00,    pctChg: 0.00,  time: '13:14:30'),
  _Security(symbol: 'NMB',       bidQty: 3200,  bid: 3150,  offer: 3160,  askQty: 400,    last: 3160,  chg: 60.00,   pctChg: 1.93,  time: '13:14:30'),
  _Security(symbol: 'NICOL',     bidQty: 650,   bid: 570,   offer: 575,   askQty: 250,    last: 575,   chg: -10.00,  pctChg: -1.71, time: '13:14:45'),
  _Security(symbol: 'SWALA',     bidQty: 500,   bid: 195,   offer: 200,   askQty: 1200,   last: 200,   chg: 5.00,    pctChg: 2.56,  time: '13:14:45'),
  _Security(symbol: 'TATEPA',    bidQty: 980,   bid: 800,   offer: 810,   askQty: 430,    last: 810,   chg: -15.00,  pctChg: -1.82, time: '13:14:55'),
  _Security(symbol: 'TBL',       bidQty: 300,   bid: 3800,  offer: 3820,  askQty: 150,    last: 3820,  chg: 40.00,   pctChg: 1.06,  time: '13:14:55'),
  _Security(symbol: 'TCL',       bidQty: 1100,  bid: 580,   offer: 590,   askQty: 600,    last: 590,   chg: 0.00,    pctChg: 0.00,  time: '13:15:00'),
  _Security(symbol: 'TICL',      bidQty: 2200,  bid: 470,   offer: 480,   askQty: 800,    last: 480,   chg: 10.00,   pctChg: 2.13,  time: '13:15:00'),
  _Security(symbol: 'TOL',       bidQty: 420,   bid: 610,   offer: 620,   askQty: 370,    last: 620,   chg: -20.00,  pctChg: -3.13, time: '13:15:10'),
  _Security(symbol: 'TPS',       bidQty: 5000,  bid: 2100,  offer: 2120,  askQty: 1800,   last: 2120,  chg: 30.00,   pctChg: 1.44,  time: '13:15:10'),
  _Security(symbol: 'TWIGA',     bidQty: 700,   bid: 6900,  offer: 6950,  askQty: 200,    last: 6950,  chg: 100.00,  pctChg: 1.46,  time: '13:15:20'),
];

// ─── Screen ───────────────────────────────────────────────────────────────────
class MarketWatchScreen extends StatefulWidget {
  const MarketWatchScreen({super.key});

  @override
  State<MarketWatchScreen> createState() => _MarketWatchScreenState();
}

class _MarketWatchScreenState extends State<MarketWatchScreen>
    with SingleTickerProviderStateMixin {
  late List<_Security> _data;
  late String _lastUpdated;
  bool _isRefreshing = false;
  String _searchQuery = '';
  _SortColumn _sortCol = _SortColumn.symbol;
  bool _sortAsc = true;
  final ScrollController _hScrollController = ScrollController();
  late AnimationController _refreshIconController;

  // Column widths
  static const double _colSecurity = 110;
  static const double _colBidQty   = 74;
  static const double _colBid      = 68;
  static const double _colOffer    = 68;
  static const double _colAskQty   = 78;
  static const double _colLast     = 68;
  static const double _colChg      = 82;
  static const double _colTime     = 78;

  @override
  void initState() {
    super.initState();
    _data = List.from(_seedData);
    _lastUpdated = _nowTime();
    _refreshIconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _hScrollController.dispose();
    _refreshIconController.dispose();
    super.dispose();
  }

  String _nowTime() => DateFormat('h:mm:ss a').format(DateTime.now());

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    _refreshIconController.repeat();
    // Simulate network call
    await Future.delayed(const Duration(milliseconds: 1400));
    if (mounted) {
      setState(() {
        _lastUpdated = _nowTime();
        _isRefreshing = false;
      });
      _refreshIconController.stop();
      _refreshIconController.reset();
    }
  }

  List<_Security> get _filtered {
    var list = _data
        .where((s) => s.symbol.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
    list.sort((a, b) {
      int cmp;
      switch (_sortCol) {
        case _SortColumn.symbol:  cmp = a.symbol.compareTo(b.symbol); break;
        case _SortColumn.bidQty:  cmp = a.bidQty.compareTo(b.bidQty); break;
        case _SortColumn.bid:     cmp = a.bid.compareTo(b.bid); break;
        case _SortColumn.offer:   cmp = a.offer.compareTo(b.offer); break;
        case _SortColumn.askQty:  cmp = a.askQty.compareTo(b.askQty); break;
        case _SortColumn.last:    cmp = a.last.compareTo(b.last); break;
        case _SortColumn.chg:     cmp = a.chg.compareTo(b.chg); break;
        case _SortColumn.time:    cmp = a.time.compareTo(b.time); break;
      }
      return _sortAsc ? cmp : -cmp;
    });
    return list;
  }

  void _onSort(_SortColumn col) {
    setState(() {
      if (_sortCol == col) {
        _sortAsc = !_sortAsc;
      } else {
        _sortCol = col;
        _sortAsc = true;
      }
    });
  }

  // ── Market summary bar stats ───────────────────────────────────────────────
  int get _gainers => _data.where((s) => s.chg > 0).length;
  int get _losers  => _data.where((s) => s.chg < 0).length;
  int get _flat    => _data.where((s) => s.chg == 0).length;

  @override
  Widget build(BuildContext context) {
    final rows = _filtered;

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
              // ── App bar ────────────────────────────────────────────────────
              _buildAppBar(),

              // ── Search bar ─────────────────────────────────────────────────
              _buildSearchBar(),

              // ── Summary ticker ─────────────────────────────────────────────
              _buildSummaryBar(),

              const SizedBox(height: 8),

              // ── Table ──────────────────────────────────────────────────────
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.7), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      children: [
                        // Sticky header
                        _buildTableHeader(),
                        const Divider(height: 1, thickness: 1, color: Color(0x30009688)),
                        // Rows
                        Expanded(
                          child: rows.isEmpty
                              ? _buildEmpty()
                              : ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            itemCount: rows.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              thickness: 0.5,
                              color: Colors.teal.withOpacity(0.15),
                              indent: 12,
                              endIndent: 12,
                            ),
                            itemBuilder: (context, i) =>
                                _buildRow(rows[i], i),
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
      ),

      // ── Refresh FAB ────────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _refresh,
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: RotationTransition(
          turns: _refreshIconController,
          child: const Icon(Icons.refresh_rounded, size: 20),
        ),
        label: Text(
          _isRefreshing ? 'Updating…' : 'Refresh',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.white.withOpacity(0.6), width: 1),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: Colors.black87),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Market Watch',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Last updated: $_lastUpdated',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.teal.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Live indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.green.withOpacity(0.4), width: 1),
            ),
            child: Row(
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
                const SizedBox(width: 5),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.green,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Search bar ─────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
          border:
          Border.all(color: Colors.white.withOpacity(0.7), width: 1),
        ),
        child: TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          decoration: InputDecoration(
            hintText: 'Search security…',
            hintStyle: TextStyle(
                fontSize: 13, color: Colors.black38),
            prefixIcon:
            Icon(Icons.search_rounded, color: Colors.teal.shade600, size: 18),
            border: InputBorder.none,
            contentPadding:
            const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  // ── Summary bar ────────────────────────────────────────────────────────────
  Widget _buildSummaryBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.38),
          borderRadius: BorderRadius.circular(14),
          border:
          Border.all(color: Colors.white.withOpacity(0.6), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _summaryChip('Gainers', _gainers, Colors.green.shade700),
            _vDivider(),
            _summaryChip('Losers', _losers, Colors.red.shade600),
            _vDivider(),
            _summaryChip('Unchanged', _flat, Colors.grey.shade600),
            _vDivider(),
            _summaryChip('Securities', _data.length, Colors.teal.shade700),
          ],
        ),
      ),
    );
  }

  Widget _summaryChip(String label, int count, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
              fontSize: 9.5,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3),
        ),
      ],
    );
  }

  Widget _vDivider() => Container(
      width: 1, height: 28, color: Colors.teal.withOpacity(0.2));

  // ── Table header ───────────────────────────────────────────────────────────
  Widget _buildTableHeader() {
    return Container(
      color: Colors.teal.shade700.withOpacity(0.12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _hScrollController,
        child: Row(
          children: [
            _headerCell('SECURITY', _colSecurity, _SortColumn.symbol, left: true),
            _headerCell('BID Q.',   _colBidQty,   _SortColumn.bidQty),
            _headerCell('BID',      _colBid,       _SortColumn.bid),
            _headerCell('OFFER',    _colOffer,     _SortColumn.offer),
            _headerCell('ASK Q.',   _colAskQty,    _SortColumn.askQty),
            _headerCell('LAST',     _colLast,      _SortColumn.last),
            _headerCell('CHG',      _colChg,       _SortColumn.chg),
            _headerCell('TIME',     _colTime,      _SortColumn.time),
          ],
        ),
      ),
    );
  }

  Widget _headerCell(String label, double width, _SortColumn col,
      {bool left = false}) {
    final active = _sortCol == col;
    return GestureDetector(
      onTap: () => _onSort(col),
      child: SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
          child: Row(
            mainAxisAlignment:
            left ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: active
                      ? Colors.teal.shade800
                      : Colors.black54,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                active
                    ? (_sortAsc
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded)
                    : Icons.unfold_more_rounded,
                size: 10,
                color: active ? Colors.teal.shade700 : Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Table row ──────────────────────────────────────────────────────────────
  Widget _buildRow(_Security s, int index) {
    final isEven = index % 2 == 0;
    final chgColor = s.chg > 0
        ? Colors.green.shade700
        : s.chg < 0
        ? Colors.red.shade600
        : Colors.black54;

    return Container(
      color: isEven
          ? Colors.white.withOpacity(0.0)
          : Colors.teal.withOpacity(0.04),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        // Share the same scroll controller so header + rows scroll together
        child: Row(
          children: [
            // Security name — always visible
            SizedBox(
              width: _colSecurity,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
                child: Text(
                  s.symbol,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
            _numCell(
                s.bidQty == 0 ? '0' : _fmt(s.bidQty.toDouble(), decimals: 0),
                _colBidQty,
                s.bidQty == 0 ? Colors.black38 : Colors.green.shade700),
            _numCell(_fmt(s.bid), _colBid, Colors.green.shade700),
            _numCell(_fmt(s.offer), _colOffer, Colors.red.shade500),
            _numCell(_fmt(s.askQty.toDouble(), decimals: 0), _colAskQty,
                Colors.red.shade500),
            _numCell(_fmt(s.last), _colLast, Colors.black87),
            // CHG cell with arrow icon
            SizedBox(
              width: _colChg,
              child: Padding(
                padding:
                const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (s.chg != 0)
                      Icon(
                        s.chg > 0
                            ? Icons.arrow_drop_up_rounded
                            : Icons.arrow_drop_down_rounded,
                        size: 16,
                        color: chgColor,
                      ),
                    Text(
                      s.chg == 0
                          ? '0.00'
                          : '${s.chg > 0 ? '+' : ''}${s.chg.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: chgColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _numCell(s.time, _colTime, Colors.black54, mono: true),
          ],
        ),
      ),
    );
  }

  Widget _numCell(String value, double width, Color color,
      {bool mono = false}) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
        child: Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
            fontFamily: mono ? 'monospace' : null,
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 48, color: Colors.teal.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text(
            'No securities found for "$_searchQuery"',
            style: const TextStyle(color: Colors.black45, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _fmt(double value, {int decimals = 2}) {
    final formatted = NumberFormat('#,##0${decimals > 0 ? '.${'0' * decimals}' : ''}');
    return formatted.format(value);
  }
}

enum _SortColumn { symbol, bidQty, bid, offer, askQty, last, chg, time }