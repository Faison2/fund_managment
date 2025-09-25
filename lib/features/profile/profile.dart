import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic>? _userData;
  String? _accountStatus; // <-- Added

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? cdsNumber = prefs.getString('cdsNumber');
      String? accountStatus = prefs.getString('accountStatus');

      setState(() {
        _accountStatus = accountStatus ?? "Unknown";
      });

      if (cdsNumber == null || cdsNumber.isEmpty) {
        setState(() {
          _errorMessage = 'CDS Number not found. Please login again.';
          _isLoading = false;
        });
        return;
      }

      // Prepare API request
      final url = Uri.parse('http://192.168.3.204/TSLFMSAPI/home/UserBasicDetails');
      final headers = {
        'Content-Type': 'application/json',
      };
      final body = json.encode({
        "APIUsername": "User2",
        "APIPassword": "CBZ1234#2",
        "AccountNumber": cdsNumber,
      });

      // Make API call
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['status'] == 'success' &&
            responseData['data'] != null &&
            responseData['data'].isNotEmpty) {
          setState(() {
            _userData = responseData['data'][0];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = responseData['statusDesc'] ?? 'Failed to load user data';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Network error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [

          const SizedBox(height: 16),
          Text(
            "Individual Account",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D99),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Account Status from SharedPreferences
          if (_accountStatus != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "Account Status: $_accountStatus",
                style: const TextStyle(
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoTile(
            icon: Icons.email,
            title: 'Email Address',
            subtitle: _userData?['email'] ?? 'Not provided',
            color: const Color(0xFF388E3C),
          ),
          const Divider(height: 1),
          _buildInfoTile(
            icon: Icons.person,
            title: 'Full Name',
            subtitle: _userData?['fullname'] ?? 'Not provided',
            color: const Color(0xFF388E3C),
          ),
          const Divider(height: 1),
          _buildInfoTile(
            icon: Icons.phone,
            title: 'Mobile Number',
            subtitle: _userData?['mobile'] ?? 'Not provided',
            color: const Color(0xFF388E3C),
          ),
          const Divider(height: 1),
          _buildInfoTile(
            icon: Icons.location_on,
            title: 'Address',
            subtitle: _userData?['address'] ?? 'Not provided',
            color: const Color(0xFF388E3C),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF333333),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildActionButton(
            icon: Icons.edit,
            title: 'Edit Profile',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit profile feature coming soon!')),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.refresh,
            title: 'Refresh Data',
            onTap: _fetchUserProfile,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF4CAF50)),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB8E6D3),
      body: SafeArea(
        child: _isLoading
            ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
              SizedBox(height: 16),
              Text(
                'Loading profile...',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        )
            : _errorMessage.isNotEmpty
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Oops! Something went wrong',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _fetchUserProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        )
            : SingleChildScrollView(
          child: Column(
            children: [
              _buildProfileHeader(),
              _buildProfileInfo(),
              _buildActionButtons(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
