import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../funds/view/fund.dart';
import '../portifolio/portfolio.dart';
import '../profile/profile.dart';
import '../trade/dashboad/trade_dashboad.dart';
import 'drawer.dart';
import 'homescreen.dart';

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

  // FAB animation
  late AnimationController _fabController;
  late Animation<double> _fabScale;

  final List<Widget> _pages = [
    const FundsScreen(),
    const HomeScreen(),
    const PortfolioScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadCDSNumber();

    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fabScale = CurvedAnimation(
      parent: _fabController,
      curve: Curves.elasticOut,
    );
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _fabController.forward();
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _loadCDSNumber() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cdsNumber = prefs.getString('cdsNumber') ?? '';
      setState(() => _cdsNumber = cdsNumber);
      if (cdsNumber.isNotEmpty) {
        await _fetchUserDetails(cdsNumber);
      } else {
        setState(() {
          _userName = 'Acc No Not Found';
          _isLoadingUserData = false;
        });
      }
    } catch (e) {
      setState(() {
        _cdsNumber = 'Error loading';
        _userName = 'Error loading';
        _isLoadingUserData = false;
      });
    }
  }

  Future<void> _fetchUserDetails(String cdsNumber) async {
    try {
      setState(() => _isLoadingUserData = true);

      const String apiUrl =
          'https://portaluat.tsl.co.tz/FMSAPI/Home/UserBasicDetails'; // ✅ Fixed: updated to UAT URL

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'CDSNumber': cdsNumber, // ✅ Fixed: removed APIUsername/APIPassword/AccountNumber
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == 'success' &&
            responseData['data'] != null) {
          // ✅ Fixed: data is an object, not an array — removed [0]
          final userData = Map<String, dynamic>.from(responseData['data']);
          setState(() {
            _userName = _formatName(userData['Names'] ?? 'Unknown User'); // ✅ Fixed: 'fullname' → 'Names'
            _userEmail = userData['Email'] ?? '';                          // ✅ Fixed: 'email' → 'Email'
            _userMobile = userData['Mobile'] ?? '';                        // ✅ Fixed: 'mobile' → 'Mobile'
            _userAddress = userData['Add_1'] ?? '';                        // ✅ Fixed: 'address' → 'Add_1'
            _isLoadingUserData = false;
          });
          await _saveUserDataLocally(userData);
        } else {
          throw Exception(
              'API error: ${responseData['statusDesc'] ?? 'Unknown'}');
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load user details: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _formatName(String fullName) => fullName
      .toLowerCase()
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');

  Future<void> _saveUserDataLocally(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_fullname', userData['Names'] ?? '');   // ✅ Fixed
    await prefs.setString('user_email', userData['Email'] ?? '');      // ✅ Fixed
    await prefs.setString('user_mobile', userData['Mobile'] ?? '');    // ✅ Fixed
    await prefs.setString('user_address', userData['Add_1'] ?? '');    // ✅ Fixed
  }

  Future<void> _loadCachedUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedName = prefs.getString('user_fullname');
    if (cachedName != null && cachedName.isNotEmpty) {
      setState(() {
        _userName = _formatName(cachedName);
        _userEmail = prefs.getString('user_email') ?? '';
        _userMobile = prefs.getString('user_mobile') ?? '';
        _userAddress = prefs.getString('user_address') ?? '';
      });
    }
  }

  Future<void> _refreshUserData() async {
    if (_cdsNumber.isNotEmpty) await _fetchUserDetails(_cdsNumber);
  }

  void _openMarketWatch() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const TradeDashboard(),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 380),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB8E6D3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFB8E6D3),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black87),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: GestureDetector(
          onTap: _refreshUserData,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _userName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_isLoadingUserData)
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.black54),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      _cdsNumber.isNotEmpty
                          ? 'Acc No: $_cdsNumber'
                          : 'Acc No: Not available',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                const Icon(Icons.notifications_outlined,
                    color: Colors.black87, size: 24),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: AppDrawer(
        currentIndex: _currentIndex,
        onNavigationChanged: (i) => setState(() => _currentIndex = i),
      ),
      body: _pages[_currentIndex],

      // ── Market Watch FAB ───────────────────────────────────────────────────
      floatingActionButton: ScaleTransition(
        scale: _fabScale,
        child: FloatingActionButton.extended(
          onPressed: _openMarketWatch,
          backgroundColor: Colors.teal.shade700,
          foregroundColor: Colors.white,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          icon: const Icon(Icons.candlestick_chart_outlined, size: 20),
          label: const Text(
            'DSE TREADEs',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      bottomNavigationBar: _buildFloatingNavBar(),
    );
  }

  Widget _buildFloatingNavBar() {
    const items = [
      {'icon': Icons.account_balance_wallet_outlined, 'activeIcon': Icons.account_balance_wallet, 'label': 'Funds'},
      {'icon': Icons.home_outlined, 'activeIcon': Icons.home, 'label': 'Home'},
      {'icon': Icons.donut_large_outlined, 'activeIcon': Icons.donut_large, 'label': 'Portfolio'},
      {'icon': Icons.person_outline, 'activeIcon': Icons.person, 'label': 'Profile'},
    ];

    return Container(
      color: const Color(0xFFB8E6D3), // matches scaffold bg — makes it feel floating
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF2D4F28).withOpacity(1),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2D4F28).withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: List.generate(items.length, (index) {
                final isSelected = _currentIndex == index;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _currentIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF4CAF50).withOpacity(0.25)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              isSelected
                                  ? items[index]['activeIcon'] as IconData
                                  : items[index]['icon'] as IconData,
                              key: ValueKey(isSelected),
                              color: isSelected
                                  ? const Color(0xFF81C784)
                                  : Colors.white54,
                              size: isSelected ? 24 : 22,
                            ),
                          ),
                          const SizedBox(height: 2),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: isSelected ? 10 : 9,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: isSelected
                                  ? const Color(0xFF81C784)
                                  : Colors.white38,
                            ),
                            child:
                            Text(items[index]['label'] as String),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}