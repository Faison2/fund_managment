import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsl/features/settings/settings.dart';
import 'package:tsl/features/statement /client_statement.dart';
import '../../provider/locale_provider.dart';
import '../../provider/theme_provider.dart';
import '../auth/login/view/login.dart';
import '../contact_us/contact.dart';
import '../payments/my_orders.dart';
import '../payments/view/payment.dart';
import '../trade/dashboad/trade_dashboad.dart';

class AppDrawer extends StatefulWidget {
  final int currentIndex;
  final Function(int) onNavigationChanged;
  const AppDrawer({
    Key? key,
    required this.currentIndex,
    required this.onNavigationChanged,
  }) : super(key: key);

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer>
    with SingleTickerProviderStateMixin {
  String _userName = '', _cdsNumber = '';
  bool _isTradeMode = false;

  late AnimationController _headerAnim;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _headerFade = CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut);
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, -0.15), end: Offset.zero).animate(
            CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userName = prefs.getString('user_fullname') ?? '';
        _cdsNumber = prefs.getString('cdsNumber') ?? '';
      });
    }
  }

  // ── Theme helpers ──────────────────────────────────────────────────────────
  bool get _dark => context.watch<ThemeProvider>().isDark;
  _DS get _s =>
      context.watch<LocaleProvider>().isSwahili ? _sw : _en;

  Color get _drawerBg =>
      _dark ? const Color(0xFF0F1F10) : Colors.white;

  Color get _accent => _isTradeMode
      ? (_dark ? const Color(0xFFFFB347) : const Color(0xFFE67E22))
      : (_dark ? const Color(0xFF4CAF50) : const Color(0xFF2E7D99));

  Color get _accentGreen => const Color(0xFF4CAF50);
  Color get _txtPrim =>
      _dark ? Colors.white : const Color(0xFF1A1A2E);
  Color get _txtSec =>
      _dark ? Colors.white54 : Colors.grey.shade500;
  Color get _divider =>
      _dark ? Colors.white12 : Colors.grey.shade100;

  String get _greeting {
    final h = DateTime.now().hour;
    final s = _s;
    if (h < 12) return s.goodMorning;
    if (h < 17) return s.goodAfternoon;
    return s.goodEvening;
  }

  String get _formattedName {
    if (_userName.isEmpty) return '';
    return _userName
        .toLowerCase()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  String get _initials {
    final parts = _formattedName
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'T';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Future<void> _logout(BuildContext context) async {
    final s = _s;
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _drawerBg,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded,
                    color: Color(0xFFEF4444), size: 32),
              ),
              const SizedBox(height: 16),
              Text(s.logoutTitle,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _txtPrim)),
              const SizedBox(height: 8),
              Text(s.logoutMsg,
                  textAlign: TextAlign.center,
                  style:
                  TextStyle(fontSize: 14, color: _txtSec, height: 1.5)),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _divider, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(s.cancel,
                        style: TextStyle(
                            color: _txtSec, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(s.logout,
                        style:
                        const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );

    if (shouldLogout == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => LoginScreen()),
              (route) => false,
        );
      }
    }
  }

  void _showAboutDialog(BuildContext context) {
    Navigator.pop(context);
    showAboutDialog(
      context: context,
      applicationName: 'TSL Investment',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2024 TSL Investment App',
      applicationIcon:
      Icon(Icons.account_balance, size: 48, color: _accent),
    );
  }

  void _switchToTrade() {
    HapticFeedback.mediumImpact();
    setState(() => _isTradeMode = true);
    Navigator.pop(context);
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const TradeDashboard(),
        transitionsBuilder: (_, animation, __, child) {
          final curved =
          CurvedAnimation(parent: animation, curve: Curves.easeInOut);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position:
              Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero)
                  .animate(curved),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 450),
      ),
    ).then((_) => setState(() => _isTradeMode = false));
  }

  // ─────────────────────────────── BUILD ────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    context.watch<LocaleProvider>();
    final s = _s;

    return Drawer(
      backgroundColor: _drawerBg,
      width: MediaQuery.of(context).size.width * 0.80,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(s),
          _buildEnvToggle(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              physics: const BouncingScrollPhysics(),
              children: [
                _sectionLabel('NAVIGATION'),
                const SizedBox(height: 4),
                _item(
                  icon: Icons.receipt_long_outlined,
                  label: s.myOrders,
                  color: const Color(0xFF2E7D99),
                  delay: 0,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                            const MyOrdersPage(transactionData: {})));
                  },
                ),
                _item(
                  icon: Icons.credit_card_outlined,
                  label: s.paymentMethods,
                  color: const Color(0xFF388E3C),
                  delay: 50,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const BankingDetailsPage()));
                  },
                ),
                _item(
                  icon: Icons.description_outlined,
                  label: s.clientStatement,
                  color: const Color(0xFF2E7D99),
                  delay: 100,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ClientStatementPage()));
                  },
                ),
                const SizedBox(height: 16),
                _sectionLabel('GENERAL'),
                const SizedBox(height: 4),
                _item(
                  icon: Icons.settings_outlined,
                  label: s.settings,
                  color: const Color(0xFF388E3C),
                  delay: 150,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SettingsPage()));
                  },
                ),
                _item(
                  icon: Icons.info_outline_rounded,
                  label: s.about,
                  color: const Color(0xFF2E7D99),
                  delay: 200,
                  onTap: () => _showAboutDialog(context),
                ),
                // ── Contact Us ───────────────────────────────────────────
                _item(
                  icon: Icons.contact_support_outlined,
                  label: s.contactUs,
                  color: const Color(0xFF4CAF50),
                  delay: 250,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ContactUsPage()));
                  },
                ),
              ],
            ),
          ),
          _buildLogout(s),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Environment Toggle ─────────────────────────────────────────────────────
  Widget _buildEnvToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  'ENVIRONMENT',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: _txtSec,
                    letterSpacing: 1.8,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: _dark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _dark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.grey.shade200,
              ),
            ),
            child: Stack(
              children: [
                AnimatedAlign(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOutCubic,
                  alignment: _isTradeMode
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: 0.5,
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isTradeMode
                              ? [
                            const Color(0xFFE67E22),
                            const Color(0xFFFFB347),
                          ]
                              : [
                            const Color(0xFF2E7D99),
                            const Color(0xFF4CAF50),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: (_isTradeMode
                                ? const Color(0xFFE67E22)
                                : const Color(0xFF2E7D99))
                                .withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (_isTradeMode) {
                            HapticFeedback.selectionClick();
                            setState(() => _isTradeMode = false);
                          }
                        },
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.account_balance_outlined,
                                size: 14,
                                color: !_isTradeMode
                                    ? Colors.white
                                    : _txtSec,
                              ),
                              const SizedBox(width: 5),
                              AnimatedDefaultTextStyle(
                                duration:
                                const Duration(milliseconds: 200),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: !_isTradeMode
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                  color: !_isTradeMode
                                      ? Colors.white
                                      : _txtSec,
                                  letterSpacing: 0.3,
                                ),
                                child: const Text('FMS'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (!_isTradeMode) _switchToTrade();
                        },
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.candlestick_chart_outlined,
                                size: 14,
                                color:
                                _isTradeMode ? Colors.white : _txtSec,
                              ),
                              const SizedBox(width: 5),
                              AnimatedDefaultTextStyle(
                                duration:
                                const Duration(milliseconds: 200),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: _isTradeMode
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                  color: _isTradeMode
                                      ? Colors.white
                                      : _txtSec,
                                  letterSpacing: 0.3,
                                ),
                                child: const Text('Trade'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(_DS s) {
    return SlideTransition(
      position: _headerSlide,
      child: FadeTransition(
        opacity: _headerFade,
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2E7D99),
                Color(0xFF1A5F77),
                Color(0xFF2E7D32),
              ],
            ),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(1),
              bottomLeft: Radius.circular(5),
              bottomRight: Radius.circular(5),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.28),
                              Colors.white.withOpacity(0.10),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _initials,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: _accentGreen,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFF1A5F77), width: 2),
                          ),
                          child: const Icon(Icons.check,
                              size: 10, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _greeting,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formattedName.isNotEmpty
                        ? _formattedName
                        : 'TSL Investor',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.25), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.badge_outlined,
                            size: 13, color: Colors.white70),
                        const SizedBox(width: 5),
                        Text(
                          _cdsNumber.isNotEmpty
                              ? '${s.accountNumber}: $_cdsNumber'
                              : 'TSL Investment',
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 12,
            decoration: BoxDecoration(
              color: _accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            text,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: _txtSec,
              letterSpacing: 1.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _item({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required int delay,
    int? index,
  }) {
    final selected = index != null && widget.currentIndex == index;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + delay),
      curve: Curves.easeOut,
      builder: (ctx, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(-20 * (1 - value), 0),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          color: selected
              ? color.withOpacity(_dark ? 0.18 : 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            splashColor: color.withOpacity(0.12),
            highlightColor: color.withOpacity(0.06),
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withOpacity(_dark ? 0.20 : 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: selected ? color : _txtPrim,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 14,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                  if (selected)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    )
                  else
                    Icon(Icons.chevron_right_rounded,
                        size: 16,
                        color: _txtSec.withOpacity(0.4)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogout(_DS s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFFEF4444).withOpacity(0.2), width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () => _logout(context),
            borderRadius: BorderRadius.circular(14),
            splashColor: const Color(0xFFEF4444).withOpacity(0.08),
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.logout_rounded,
                        color: Color(0xFFEF4444), size: 20),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    s.logout,
                    style: const TextStyle(
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right_rounded,
                      size: 16, color: Color(0x66EF4444)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── String tables ──────────────────────────────────────────────────────────────
class _DS {
  final String goodMorning,
      goodAfternoon,
      goodEvening,
      accountNumber,
      home,
      myOrders,
      paymentMethods,
      clientStatement,
      settings,
      about,
      contactUs, // ← NEW
      logout,
      logoutTitle,
      logoutMsg,
      cancel;
  const _DS({
    required this.goodMorning,
    required this.goodAfternoon,
    required this.goodEvening,
    required this.accountNumber,
    required this.home,
    required this.myOrders,
    required this.paymentMethods,
    required this.clientStatement,
    required this.settings,
    required this.about,
    required this.contactUs, // ← NEW
    required this.logout,
    required this.logoutTitle,
    required this.logoutMsg,
    required this.cancel,
  });
}

const _en = _DS(
  goodMorning: 'Good Morning',
  goodAfternoon: 'Good Afternoon',
  goodEvening: 'Good Evening',
  accountNumber: 'Account No.',
  home: 'Home',
  myOrders: 'My Orders',
  paymentMethods: 'Banking Details',
  clientStatement: 'Client Statement',
  settings: 'Settings',
  about: 'About',
  contactUs: 'Contact Us',
  logout: 'Logout',
  logoutTitle: 'Logout',
  logoutMsg: 'Are you sure you want to logout?',
  cancel: 'Cancel',
);

const _sw = _DS(
  goodMorning: 'Habari za Asubuhi',
  goodAfternoon: 'Habari za Mchana',
  goodEvening: 'Habari za Jioni',
  accountNumber: 'Nambari ya Akaunti',
  home: 'Nyumbani',
  myOrders: 'Maagizo Yangu',
  paymentMethods: 'Maelezo ya Benki',
  clientStatement: 'Taarifa ya Mteja',
  settings: 'Mipangilio',
  about: 'Kuhusu',
  contactUs: 'Wasiliana Nasi',
  logout: 'Toka',
  logoutTitle: 'Toka?',
  logoutMsg: 'Una uhakika unataka kutoka?',
  cancel: 'Ghairi',
);