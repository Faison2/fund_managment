import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tsl/features/funds/funds.dart';
import '../portifolio/portfolio.dart';
import '../profile/profile.dart';
import 'drawer.dart';
import 'homescreen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 1; // Home tab selected by default
  String _cdsNumber = '';
  String _userName = 'Loading...'; // Default loading state
  String _userEmail = '';
  String _userMobile = '';
  String _userAddress = '';
  bool _isLoadingUserData = true;

  // List of pages/screens
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
  }

  Future<void> _loadCDSNumber() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cdsNumber = prefs.getString('cdsNumber') ?? '';
      setState(() {
        _cdsNumber = cdsNumber;
      });
      print('Loaded CDS Number: $_cdsNumber');

      if (cdsNumber.isNotEmpty) {
        await _fetchUserDetails(cdsNumber);
      } else {
        setState(() {
          _userName = 'CDS Not Found';
          _isLoadingUserData = false;
        });
      }
    } catch (e) {
      print('Error loading CDS number: $e');
      setState(() {
        _cdsNumber = 'Error loading';
        _userName = 'Error loading';
        _isLoadingUserData = false;
      });
    }
  }

  Future<void> _fetchUserDetails(String accountNumber) async {
    try {
      setState(() {
        _isLoadingUserData = true;
      });

      const String apiUrl = 'http://192.168.3.204/TSLFMSAPI/home/UserBasicDetails';

      final Map<String, String> requestBody = {
        'APIUsername': 'User2',
        'APIPassword': 'CBZ1234#2',
        'AccountNumber': accountNumber,
      };

      print('Making API request with body: $requestBody');

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 10), // 10 second timeout
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['status'] == 'success' && responseData['data'] != null) {
          final userData = responseData['data'][0]; // Get first item from data array

          setState(() {
            _userName = _formatName(userData['fullname'] ?? 'Unknown User');
            _userEmail = userData['email'] ?? '';
            _userMobile = userData['mobile'] ?? '';
            _userAddress = userData['address'] ?? '';
            _isLoadingUserData = false;
          });

          // Optional: Save user data to SharedPreferences for offline access
          await _saveUserDataLocally(userData);

          print('User data loaded successfully: $_userName');
        } else {
          throw Exception('API returned error: ${responseData['statusDesc'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error fetching user details: $e');

      // Try to load cached data if API fails
      await _loadCachedUserData();

      setState(() {
        if (_userName == 'Loading...') {
          _userName = 'Error loading name';
        }
        _isLoadingUserData = false;
      });

      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load user details: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _formatName(String fullName) {
    // Convert to title case and clean up extra spaces
    return fullName
        .toLowerCase()
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Future<void> _saveUserDataLocally(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_fullname', userData['fullname'] ?? '');
      await prefs.setString('user_email', userData['email'] ?? '');
      await prefs.setString('user_mobile', userData['mobile'] ?? '');
      await prefs.setString('user_address', userData['address'] ?? '');
      await prefs.setString('user_data_timestamp', DateTime.now().toIso8601String());
      print('User data saved locally');
    } catch (e) {
      print('Error saving user data locally: $e');
    }
  }

  Future<void> _loadCachedUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedName = prefs.getString('user_fullname');

      if (cachedName != null && cachedName.isNotEmpty) {
        setState(() {
          _userName = _formatName(cachedName);
          _userEmail = prefs.getString('user_email') ?? '';
          _userMobile = prefs.getString('user_mobile') ?? '';
          _userAddress = prefs.getString('user_address') ?? '';
        });
        print('Loaded cached user data: $_userName');
      }
    } catch (e) {
      print('Error loading cached user data: $e');
    }
  }

  void _onNavigationChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _refreshUserData() async {
    if (_cdsNumber.isNotEmpty) {
      await _fetchUserDetails(_cdsNumber);
    }
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
            icon: const Icon(
              Icons.menu,
              color: Colors.black87,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: GestureDetector(
          onTap: _refreshUserData, // Tap to refresh user data
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
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black54),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      _cdsNumber.isNotEmpty ? 'CDS: $_cdsNumber' : 'CDS: Not available',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
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
                const Icon(
                  Icons.notifications_outlined,
                  color: Colors.black87,
                  size: 24,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: AppDrawer(
        currentIndex: _currentIndex,
        onNavigationChanged: _onNavigationChanged,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF4A6741),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(15),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white60,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Funds',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart_outline),
              label: 'Portfolio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_off_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}