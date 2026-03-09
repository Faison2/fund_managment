import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../bloc/bloc.dart';
import '../bloc/event.dart';
import '../bloc/state.dart';
import '../model/model.dart';
import '../repository/repository.dart';
import '../../../../provider/locale_provider.dart';
import '../../../../provider/theme_provider.dart';

// ── Localised strings ─────────────────────────────────────────────────────────
class _FS {
  final String availableFunds, code, issuer, description,
      units, noFunds, welcome, retry, error,
      statusActive, statusPending, statusClosed, statusPaused, statusUnknown;
  const _FS({
    required this.availableFunds, required this.code,
    required this.issuer,         required this.description,
    required this.units,          required this.noFunds,
    required this.welcome,        required this.retry,
    required this.error,          required this.statusActive,
    required this.statusPending,  required this.statusClosed,
    required this.statusPaused,   required this.statusUnknown,
  });
}

const _fsEn = _FS(
  availableFunds: 'Available Funds',
  code:           'Code',
  issuer:         'Issuer',
  description:    'Description',
  units:          'Units',
  noFunds:        'No funds available.',
  welcome:        'Tap refresh to load funds.',
  retry:          'Retry',
  error:          'Error',
  statusActive:   'Active',
  statusPending:  'Pending',
  statusClosed:   'Closed',
  statusPaused:   'Paused',
  statusUnknown:  'Unknown',
);

const _fsSw = _FS(
  availableFunds: 'Fedha Zinazopatikana',
  code:           'Msimbo',
  issuer:         'Mtoa Huduma',
  description:    'Maelezo',
  units:          'Vitengo',
  noFunds:        'Hakuna fedha zinazopatikana.',
  welcome:        'Gusa kuonyesha upya kupakia fedha.',
  retry:          'Jaribu Tena',
  error:          'Hitilafu',
  statusActive:   'Hai',
  statusPending:  'Inasubiri',
  statusClosed:   'Imefungwa',
  statusPaused:   'Imesimamishwa',
  statusUnknown:  'Haijulikani',
);

// ── FundsScreen ───────────────────────────────────────────────────────────────
class FundsScreen extends StatelessWidget {
  const FundsScreen({Key? key}) : super(key: key);

  // ── Accent colours per fund index (same palette as PortfolioScreen) ────────
  static const List<Color> _fundAccents = [
    Color(0xFF2ECC71), Color(0xFF3498DB), Color(0xFFE67E22),
    Color(0xFF9B59B6), Color(0xFFE74C3C), Color(0xFF1ABC9C),
  ];

  Color _accentFor(int index) => _fundAccents[index % _fundAccents.length];

  // ── Status colour ──────────────────────────────────────────────────────────
  Color _statusColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'active':
      case 'available':
      case 'open':
        return const Color(0xFF22C55E);
      case 'pending':
      case 'processing':
        return const Color(0xFFF59E0B);
      case 'closed':
      case 'inactive':
      case 'suspended':
        return const Color(0xFFEF4444);
      case 'paused':
      case 'maintenance':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark   = context.watch<ThemeProvider>().isDark;
    final s      = context.watch<LocaleProvider>().isSwahili ? _fsSw : _fsEn;

    // ── Theme tokens ──────────────────────────────────────────────────────────
    final Color bg       = dark ? const Color(0xFF0B1A0C) : const Color(0xFFB8E6D3);
    final Color cardBg   = dark ? const Color(0xFF132013) : Colors.white;
    final Color border   = dark ? const Color(0xFF1E3320) : const Color(0xFFE2ECE2);
    final Color txtP     = dark ? const Color(0xFFE8F5E9) : const Color(0xFF1A2E1A);
    final Color txtS     = dark ? const Color(0xFF81A884) : const Color(0xFF5A7A5C);
    final Color txtH     = dark ? const Color(0xFF4A7A4D) : const Color(0xFF9AAA9C);
    final Color teal     = dark ? const Color(0xFF38BDF8) : const Color(0xFF2E7D99);
    final Color green    = dark ? const Color(0xFF4ADE80) : const Color(0xFF15803D);

    return BlocProvider(
      create: (_) => FundsBloc(fundsRepository: FundsRepository())
        ..add(const LoadFunds()),
      child: Scaffold(
        backgroundColor: bg,
        body: Column(children: [
          // ── Header ──────────────────────────────────────────────────────────
          _Header(dark: dark, s: s, teal: teal, txtP: txtP, txtS: txtS, bg: bg),

          // ── Body ────────────────────────────────────────────────────────────
          Expanded(
            child: BlocBuilder<FundsBloc, FundsState>(
              builder: (context, state) {
                if (state is FundsLoading) {
                  return _Loader(green: green);
                }
                if (state is FundsError) {
                  return _ErrorView(
                    message: '${s.error}: ${state.message}',
                    retryLabel: s.retry,
                    dark: dark,
                    txtP: txtP,
                    onRetry: () => context.read<FundsBloc>().add(const LoadFunds()),
                  );
                }
                if (state is FundsLoaded) {
                  if (state.funds.isEmpty) {
                    return _Empty(message: s.noFunds, txtS: txtS);
                  }
                  return RefreshIndicator(
                    color: green,
                    onRefresh: () async =>
                        context.read<FundsBloc>().add(const RefreshFunds()),
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                      itemCount: state.funds.length,
                      itemBuilder: (ctx, i) => _FundCard(
                        fund:        state.funds[i],
                        index:       i,
                        accent:      _accentFor(i),
                        dark:        dark,
                        s:           s,
                        cardBg:      cardBg,
                        border:      border,
                        txtP:        txtP,
                        txtS:        txtS,
                        txtH:        txtH,
                        statusColor: _statusColor(state.funds[i].status),
                      ),
                    ),
                  );
                }
                return _Empty(message: s.welcome, txtS: txtS);
              },
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final bool dark;
  final _FS s;
  final Color teal, txtP, txtS, bg;
  const _Header({required this.dark, required this.s, required this.teal,
    required this.txtP, required this.txtS, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
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
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.availableFunds,
                    style: const TextStyle(color: Colors.white, fontSize: 22,
                        fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                const SizedBox(height: 2),
                Text(dark ? '● Live Market Data' : '● Live Market Data',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6), fontSize: 12)),
              ])),
          // Refresh button
          BlocBuilder<FundsBloc, FundsState>(
            builder: (context, state) => GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                context.read<FundsBloc>().add(const RefreshFunds());
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: state is FundsLoading
                    ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.refresh_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ),
        ]),
      )),
    );
  }
}

// ── Fund card ─────────────────────────────────────────────────────────────────
class _FundCard extends StatelessWidget {
  final Fund fund;
  final int index;
  final Color accent, cardBg, border, txtP, txtS, txtH, statusColor;
  final bool dark;
  final _FS s;

  const _FundCard({
    required this.fund,        required this.index,
    required this.accent,      required this.dark,
    required this.s,           required this.cardBg,
    required this.border,      required this.txtP,
    required this.txtS,        required this.txtH,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final status = fund.status ?? s.statusUnknown;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + index * 80),
      curve: Curves.easeOut,
      builder: (_, val, child) => Opacity(
        opacity: val,
        child: Transform.translate(offset: Offset(0, 24 * (1 - val)), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
          boxShadow: [BoxShadow(
            color: accent.withOpacity(dark ? 0.08 : 0.12),
            blurRadius: 16, offset: const Offset(0, 6),
          )],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(children: [
            // ── Coloured header strip ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: BoxDecoration(
                color: accent.withOpacity(dark ? 0.12 : 0.08),
              ),
              child: Row(children: [
                // Fund code badge
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(dark ? 0.2 : 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: accent.withOpacity(0.35), width: 1.5),
                  ),
                  child: Center(child: Text(
                    (fund.fundingCode ?? '??').length > 5
                        ? (fund.fundingCode ?? '??').substring(0, 5)
                        : (fund.fundingCode ?? '??'),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
                        color: accent, letterSpacing: -0.5),
                    textAlign: TextAlign.center,
                  )),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fund.fundingName ?? '',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                              color: txtP, letterSpacing: -0.2),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Text('${s.issuer}: ${fund.issuer ?? 'N/A'}',
                          style: TextStyle(fontSize: 12, color: txtS),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ])),
                const SizedBox(width: 8),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 6, height: 6,
                        decoration: BoxDecoration(
                            color: statusColor, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text(status, style: TextStyle(fontSize: 11,
                        fontWeight: FontWeight.w700, color: statusColor)),
                  ]),
                ),
              ]),
            ),

            // ── Body ────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Description
                if ((fund.description ?? '').isNotEmpty) ...[
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(dark ? 0.12 : 0.08),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(Icons.description_outlined,
                          color: accent, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s.description, style: TextStyle(fontSize: 10,
                          color: txtH, fontWeight: FontWeight.w600,
                          letterSpacing: 0.3)),
                      const SizedBox(height: 2),
                      Text(fund.description ?? '',
                          style: TextStyle(fontSize: 13, color: txtP,
                              height: 1.4),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                    ])),
                  ]),
                  const SizedBox(height: 14),
                ],

                // ── Stats row ───────────────────────────────────────────────
                Row(children: [
                  _stat(s.code,  fund.fundingCode ?? 'N/A', accent,  dark),
                  _divider(dark),
                  _stat(s.units, '${fund.units ?? 0}',       Colors.purple.shade400, dark),
                  _divider(dark),
                  _stat(s.issuer, fund.issuer ?? 'N/A',      Colors.orange.shade600, dark),
                ]),
              ]),
            ),

            // ── Accent bottom bar ────────────────────────────────────────────
            Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent.withOpacity(0.7), accent.withOpacity(0.1)],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color color, bool dark) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(dark ? 0.08 : 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        Text(label, style: TextStyle(fontSize: 9, color: txtH,
            fontWeight: FontWeight.w600, letterSpacing: 0.3)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 12,
            fontWeight: FontWeight.w800, color: color),
            overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
      ]),
    ),
  );

  Widget _divider(bool dark) => Container(
    width: 1, height: 36,
    color: (dark ? Colors.white : Colors.black).withOpacity(0.07),
    margin: const EdgeInsets.symmetric(horizontal: 6),
  );
}

// ── Loading ───────────────────────────────────────────────────────────────────
class _Loader extends StatelessWidget {
  final Color green;
  const _Loader({required this.green});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      SizedBox(width: 48, height: 48,
          child: CircularProgressIndicator(color: green, strokeWidth: 3)),
      const SizedBox(height: 16),
      Text('Loading...', style: TextStyle(color: green, fontSize: 14,
          fontWeight: FontWeight.w600)),
    ]),
  );
}

// ── Error ─────────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message, retryLabel;
  final bool dark;
  final Color txtP;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.retryLabel,
    required this.dark, required this.txtP, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red.withOpacity(0.1),
            border: Border.all(color: Colors.red.withOpacity(0.3), width: 2),
          ),
          child: const Icon(Icons.error_outline_rounded,
              size: 48, color: Colors.redAccent),
        ),
        const SizedBox(height: 20),
        Text(message, textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red.shade400, fontSize: 14,
                height: 1.5)),
        const SizedBox(height: 28),
        GestureDetector(
          onTap: onRetry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF388E3C)]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(
                  color: const Color(0xFF4CAF50).withOpacity(0.35),
                  blurRadius: 14, offset: const Offset(0, 6))],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(retryLabel, style: const TextStyle(color: Colors.white,
                  fontSize: 14, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ]),
    ),
  );
}

// ── Empty ─────────────────────────────────────────────────────────────────────
class _Empty extends StatelessWidget {
  final String message;
  final Color txtS;
  const _Empty({required this.message, required this.txtS});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.inbox_outlined, size: 56,
          color: txtS.withOpacity(0.4)),
      const SizedBox(height: 16),
      Text(message, style: TextStyle(color: txtS, fontSize: 14,
          fontWeight: FontWeight.w500)),
    ]),
  );
}