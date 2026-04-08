import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import '../funds/view/fund.dart';
import '../portifolio/portfolio.dart';
import '../profile/profile.dart';
import '../trade/dashboad/trade_dashboad.dart';
import '../../provider/locale_provider.dart';
import '../../provider/theme_provider.dart';
import 'drawer.dart';
import 'homescreen.dart';

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
  bool get _dark  => context.watch<ThemeProvider>().isDark;
  _DS  get _s     => context.watch<LocaleProvider>().isSwahili ? _dsSw : _dsEn;

  Color get _scaffoldBg => _dark ? const Color(0xFF0B1A0C) : const Color(0xFFB8E6D3);
  Color get _appBarBg   => _dark ? const Color(0xFF0B1A0C) : const Color(0xFFB8E6D3);
  Color get _txtPrim    => _dark ? const Color(0xFFE8F5E9) : Colors.black87;
  Color get _txtSec     => _dark ? const Color(0xFF81A884)  : Colors.black54;

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
      final prefs     = await SharedPreferences.getInstance();
      final cdsNumber = prefs.getString('cdsNumber') ?? '';
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
        Uri.parse('https://portaluat.tsl.co.tz/FMSAPI/Home/UserBasicDetails'),
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_fullname', userData['Names']  ?? '');
    await prefs.setString('user_email',    userData['Email']  ?? '');
    await prefs.setString('user_mobile',   userData['Mobile'] ?? '');
    await prefs.setString('user_address',  userData['Add_1']  ?? '');
  }

  Future<void> _loadCachedUserData() async {
    final prefs      = await SharedPreferences.getInstance();
    final cachedName = prefs.getString('user_fullname');
    if (cachedName != null && cachedName.isNotEmpty) {
      setState(() {
        _userName    = _formatName(cachedName);
        _userEmail   = prefs.getString('user_email')   ?? '';
        _userMobile  = prefs.getString('user_mobile')  ?? '';
        _userAddress = prefs.getString('user_address') ?? '';
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
      statusBarBrightness: _dark ? Brightness.dark : Brightness.light,
      statusBarIconBrightness: _dark ? Brightness.light : Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: _scaffoldBg,
      // KEY FIX: extendBody allows the body to go behind the nav bar.
      // This prevents the system gesture area from squashing the body content.
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
                  ? Colors.white.withOpacity(0.08)
                  : Colors.white.withOpacity(0.3),
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

    // KEY FIX 1: Read the system bottom inset (gesture nav bar / home indicator).
    // This is the height of the system navigation area we must not overlap.
    final bottomInset = MediaQuery.of(context).padding.bottom;

    // KEY FIX 2: Responsive pill height based on screen size.
    // Smaller phones get a shorter pill so it doesn't crowd the screen.
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth  = MediaQuery.of(context).size.width;
    final pillHeight   = screenHeight < 680 || screenWidth < 360 ? 56.0 : 64.0;

    final Widget navPill = _dark
        ? _glassPill(labels, icons, pillHeight)
        : _solidPill(labels, icons, pillHeight);

    // KEY FIX 3: Remove SafeArea wrapper — handle insets manually via padding.
    // SafeArea can double-count padding when extendBody is true on the Scaffold.
    // We add bottomInset directly as bottom padding so the pill floats above
    // the gesture bar without being crushed or unreachable.
    return Container(
      color: _scaffoldBg,
      padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + bottomInset),
      child: navPill,
    );
  }

  // ── Frosted glass pill (dark mode) ─────────────────────────────────────────
  Widget _glassPill(
      List<String> labels,
      List<(IconData, IconData)> icons,
      double pillHeight,
      ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: pillHeight,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
                color: Colors.white.withOpacity(0.12), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: _navItems(
            labels, icons,
            selectedItemColor:   const Color(0xFF4ADE80),
            unselectedItemColor: Colors.white38,
            selectedBgColor:     const Color(0xFF4ADE80).withOpacity(0.12),
            pillHeight:          pillHeight,
          ),
        ),
      ),
    );
  }

  // ── Solid pill (light mode) ────────────────────────────────────────────────
  Widget _solidPill(
      List<String> labels,
      List<(IconData, IconData)> icons,
      double pillHeight,
      ) {
    return Container(
      height: pillHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF2D4F28),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D4F28).withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: _navItems(
        labels, icons,
        selectedItemColor:   const Color(0xFF81C784),
        unselectedItemColor: Colors.white54,
        selectedBgColor:     const Color(0xFF4CAF50).withOpacity(0.25),
        pillHeight:          pillHeight,
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
      }) {
    // KEY FIX 4: Scale icon and font sizes relative to the pill height
    // so they stay proportional on all screen sizes.
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
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              // KEY FIX 5: Use symmetric vertical margin derived from pillHeight
              // instead of a hardcoded value, so items don't overflow on small pills.
              margin: EdgeInsets.symmetric(horizontal: 4, vertical: verticalMargin),
              decoration: BoxDecoration(
                color: isSelected ? selectedBgColor : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
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