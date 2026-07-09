import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import '../../constants/constants.dart';
import '../../constants/secure_storage.dart';
import '../funds/view/fund.dart';
import '../portfolio/portfolio.dart';
import '../profile/profile.dart';
import '../trade/dashboard/trade_dashboard.dart';
import '../../provider/locale_provider.dart';
import '../../provider/theme_provider.dart';
import 'drawer.dart';
import 'homescreen.dart';

// ── TSL Brand colours ──────────────────────────────────────────────────────────
class _TSL {
  static const Color blue  = Color(0xFF329AD6);
  static const Color teal  = Color(0xFF00A79D);
  static const Color grey  = Color(0xFF939598);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF231F20);
}

// ── Localised strings ─────────────────────────────────────────────────────────
class _DS {
  final String funds, home, portfolio, profile,
      accNo, accNotAvailable,
      accNotFound, errorLoading, failedToLoad;
  const _DS({
    required this.funds,           required this.home,
    required this.portfolio,       required this.profile,
    required this.accNo,
    required this.accNotAvailable, required this.accNotFound,
    required this.errorLoading,    required this.failedToLoad,
  });
}

const _dsEn = _DS(
  funds:           'Funds',
  home:            'Home',
  portfolio:       'Portfolio',
  profile:         'Profile',
  accNo:           'Acc No',
  accNotAvailable: 'Acc No: Not available',
  accNotFound:     'Acc No Not Found',
  errorLoading:    'Error loading',
  failedToLoad:    'Failed to load user details',
);

const _dsSw = _DS(
  funds:           'Kidude',
  home:            'Nyumbani',
  portfolio:       'Mkoba',
  profile:         'Wasifu',
  accNo:           'Nambari ya Akaunti',
  accNotAvailable: 'Akaunti: Haipatikani',
  accNotFound:     'Nambari ya Akaunti Haikupatikana',
  errorLoading:    'Hitilafu ya kupakia',
  failedToLoad:    'Imeshindwa kupakia maelezo ya mtumiaji',
);

// ── DashboardScreen ───────────────────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 1;
  String _cdsNumber = '';
  String _userName = 'Loading...';
  String _userEmail = '';
  String _userMobile = '';
  String _userAddress = '';
  bool _isLoadingUserData = true;

  late AnimationController _fabController;
  late Animation<double> _fabScale;

  final List<Widget> _pages = [
    const FundsScreen(),
    const HomeScreen(),
    const PortfolioScreen(),
    const ProfileScreen(),
  ];

  // ── Theme helpers ──────────────────────────────────────────────────────────
  bool get _dark => context.watch<ThemeProvider>().isDark;
  _DS  get _s    => context.watch<LocaleProvider>().isSwahili ? _dsSw : _dsEn;

  Color get _scaffoldBg => _dark ? _TSL.black : const Color(0xFFB8E6D3);
  Color get _appBarBg   => _dark ? _TSL.black : const Color(0xFFB8E6D3);
  Color get _txtPrim    => _dark ? _TSL.white : _TSL.black;
  Color get _txtSec     => _dark ? _TSL.teal  : _TSL.grey;

  @override
  void initState() {
    super.initState();
    _loadCDSNumber();

    _fabController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fabScale = CurvedAnimation(parent: _fabController, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  // ── Data loading ───────────────────────────────────────────────────────────
  Future<void> _loadCDSNumber() async {
    try {
      final cdsNumber = await SecureStorage.read('cdsNumber') ?? '';
      setState(() => _cdsNumber = cdsNumber);
      if (cdsNumber.isNotEmpty) {
        await _fetchUserDetails(cdsNumber);
      } else {
        setState(() {
          _userName          = _s.accNotFound;
          _isLoadingUserData = false;
        });
      }
    } catch (e) {
      setState(() {
        _cdsNumber         = _s.errorLoading;
        _userName          = _s.errorLoading;
        _isLoadingUserData = false;
      });
    }
  }

  Future<void> _fetchUserDetails(String cdsNumber) async {
    try {
      setState(() => _isLoadingUserData = true);
      final response = await http.post(
        Uri.parse('$cSharpApi/UserBasicDetails'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: json.encode({'CDSNumber': cdsNumber}),
      ).timeout(const Duration(seconds: 10),
          onTimeout: () => throw Exception('Request timeout'));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        if (responseData['status'] == 'success' && responseData['data'] != null) {
          final userData = Map<String, dynamic>.from(responseData['data']);
          setState(() {
            _userName          = _formatName(userData['Names'] ?? 'Unknown User');
            _userEmail         = userData['Email']  ?? '';
            _userMobile        = userData['Mobile'] ?? '';
            _userAddress       = userData['Add_1']  ?? '';
            _isLoadingUserData = false;
          });
          await _saveUserDataLocally(userData);
        } else {
          throw Exception('API error: ${responseData['statusDesc'] ?? 'Unknown'}');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      await _loadCachedUserData();
      setState(() {
        if (_userName == 'Loading...') _userName = 'User';
        _isLoadingUserData = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${_s.failedToLoad}: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ));
      }
    }
  }

  String _formatName(String fullName) => fullName
      .toLowerCase().split(' ').where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');

  Future<void> _saveUserDataLocally(Map<String, dynamic> userData) async {
    await SecureStorage.write('user_fullname', userData['Names']  ?? '');
    await SecureStorage.write('user_email',    userData['Email']  ?? '');
    await SecureStorage.write('user_mobile',   userData['Mobile'] ?? '');
    await SecureStorage.write('user_address',  userData['Add_1']  ?? '');
  }

  Future<void> _loadCachedUserData() async {
    final cachedName = await SecureStorage.read('user_fullname');
    if (cachedName != null && cachedName.isNotEmpty) {
      final email   = await SecureStorage.read('user_email')   ?? '';
      final mobile  = await SecureStorage.read('user_mobile')  ?? '';
      final address = await SecureStorage.read('user_address') ?? '';
      setState(() {
        _userName    = _formatName(cachedName);
        _userEmail   = email;
        _userMobile  = mobile;
        _userAddress = address;
      });
    }
  }

  Future<void> _refreshUserData() async {
    if (_cdsNumber.isNotEmpty) await _fetchUserDetails(_cdsNumber);
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    context.watch<LocaleProvider>();
    final s = _s;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarBrightness:      _dark ? Brightness.dark  : Brightness.light,
      statusBarIconBrightness:  _dark ? Brightness.light : Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: _scaffoldBg,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: _appBarBg,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(Icons.menu, color: _txtPrim),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: GestureDetector(
          onTap: _refreshUserData,
          child: Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Expanded(child: Text(_userName,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                          color: _txtPrim),
                      overflow: TextOverflow.ellipsis)),
                  if (_isLoadingUserData)
                    SizedBox(width: 12, height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(_txtSec))),
                ]),
              ],
            )),
          ]),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _dark
                  ? _TSL.white.withOpacity(0.08)
                  : _TSL.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(children: [
              Icon(Icons.notifications_outlined, color: _txtPrim, size: 24),
              Positioned(right: 0, top: 0,
                  child: Container(width: 8, height: 8,
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle))),
            ]),
          ),
        ],
      ),
      drawer: AppDrawer(
        currentIndex: _currentIndex,
        onNavigationChanged: (i) => setState(() => _currentIndex = i),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: _buildNavBar(s),
    );
  }

  // ── Bottom nav ─────────────────────────────────────────────────────────────
  Widget _buildNavBar(_DS s) {
    final labels = [s.funds, s.home, s.portfolio, s.profile];
    const icons = [
      (Icons.account_balance_wallet_outlined, Icons.account_balance_wallet),
      (Icons.home_outlined,                   Icons.home),
      (Icons.donut_large_outlined,            Icons.donut_large),
      (Icons.person_outline,                  Icons.person),
    ];

    final bottomInset  = MediaQuery.of(context).padding.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth  = MediaQuery.of(context).size.width;
    final pillHeight   = screenHeight < 680 || screenWidth < 360 ? 56.0 : 64.0;

    final Widget navPill = _dark
        ? _glassPill(labels, icons, pillHeight)
        : _solidPill(labels, icons, pillHeight);

    return Container(
      color: _scaffoldBg,
      padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + bottomInset),
      child: navPill,
    );
  }

  // ── Liquid Glass decoration helper ────────────────────────────────────────
  BoxDecoration _liquidGlassDecoration({
    required bool isDark,
    double borderRadius = 32,
  }) {
    return BoxDecoration(
      color: isDark
          ? _TSL.white.withOpacity(0.08)
          : _TSL.black.withOpacity(0.82),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: isDark
            ? _TSL.white.withOpacity(0.14)
            : Colors.black.withOpacity(0.10),
        width: 1.0,
      ),
      boxShadow: isDark
          ? [
        BoxShadow(
          color: _TSL.black.withOpacity(0.40),
          blurRadius: 32,
          spreadRadius: -4,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: _TSL.black.withOpacity(0.20),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ]
          : [
        BoxShadow(
          color: _TSL.black.withOpacity(0.45),
          blurRadius: 40,
          spreadRadius: -4,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: _TSL.black.withOpacity(0.15),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // ── Inner gloss sheen (top-edge highlight) ────────────────────────────────
  Widget _innerGlossLayer({required Widget child}) {
    return Stack(
      children: [
        child,
        Positioned(
          top: 0,
          left: 16,
          right: 16,
          height: 1,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  _TSL.white.withOpacity(0.18),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Frosted glass pill (dark mode) ────────────────────────────────────────
  Widget _glassPill(
      List<String> labels,
      List<(IconData, IconData)> icons,
      double pillHeight,
      ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: pillHeight,
          decoration: _liquidGlassDecoration(isDark: true),
          child: _innerGlossLayer(
            child: _navItems(
              labels, icons,
              selectedItemColor:   _TSL.teal,
              unselectedItemColor: _TSL.white.withOpacity(0.38),
              selectedBgColor:     _TSL.teal.withOpacity(0.22),
              pillHeight:          pillHeight,
              glowColor:           _TSL.teal,
            ),
          ),
        ),
      ),
    );
  }

  // ── Solid pill (light mode) ───────────────────────────────────────────────
  Widget _solidPill(
      List<String> labels,
      List<(IconData, IconData)> icons,
      double pillHeight,
      ) {
    return Container(
      height: pillHeight,
      decoration: _liquidGlassDecoration(isDark: false),
      child: _innerGlossLayer(
        child: _navItems(
          labels, icons,
          selectedItemColor:   _TSL.teal,
          unselectedItemColor: _TSL.white.withOpacity(0.38),
          selectedBgColor:     _TSL.teal.withOpacity(0.22),
          pillHeight:          pillHeight,
          glowColor:           _TSL.teal,
        ),
      ),
    );
  }

  // ── Shared nav item row ────────────────────────────────────────────────────
  Widget _navItems(
      List<String> labels,
      List<(IconData, IconData)> icons, {
        required Color selectedItemColor,
        required Color unselectedItemColor,
        required Color selectedBgColor,
        required double pillHeight,
        Color glowColor = Colors.transparent,
      }) {
    final double selectedIconSize   = pillHeight < 60 ? 22.0 : 24.0;
    final double unselectedIconSize = pillHeight < 60 ? 20.0 : 22.0;
    final double selectedFontSize   = pillHeight < 60 ? 9.0  : 10.0;
    final double unselectedFontSize = pillHeight < 60 ? 8.0  : 9.0;
    final double verticalMargin     = pillHeight < 60 ? 6.0  : 8.0;

    return Row(
      children: List.generate(labels.length, (index) {
        final isSelected = _currentIndex == index;
        return Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _currentIndex = index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              margin: EdgeInsets.symmetric(horizontal: 4, vertical: verticalMargin),
              decoration: BoxDecoration(
                color: isSelected ? selectedBgColor : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                // Liquid glass teal glow on active item
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: glowColor.withOpacity(0.25),
                    blurRadius: 20,
                    spreadRadius: -2,
                  ),
                ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      isSelected ? icons[index].$2 : icons[index].$1,
                      key: ValueKey(isSelected),
                      color: isSelected ? selectedItemColor : unselectedItemColor,
                      size: isSelected ? selectedIconSize : unselectedIconSize,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize:   isSelected ? selectedFontSize : unselectedFontSize,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                      color:      isSelected ? selectedItemColor : unselectedItemColor,
                      // Subtle text glow on active label
                      shadows: isSelected
                          ? [
                        Shadow(
                          color: glowColor.withOpacity(0.60),
                          blurRadius: 8,
                        ),
                      ]
                          : null,
                    ),
                    child: Text(
                      labels[index],
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}