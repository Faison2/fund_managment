import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsl/features/statement%20/client_statement.dart';
import 'package:tsl/features/withdrawal/view/withdrawal_page.dart';

import '../auth/login/login.dart';
import '../deposits/view/deposits.dart';
import '../payments/payment_confamation.dart';
import '../payments/view/payment.dart';

class AppDrawer extends StatelessWidget {
  final int currentIndex;
  final Function(int) onNavigationChanged;

  const AppDrawer({
    Key? key,
    required this.currentIndex,
    required this.onNavigationChanged,
  }) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Logout', style: TextStyle(color: Color(0xFF4A6741))),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
              (Route<dynamic> route) => false,
        );
      }
    }
  }

  void _navigateToScreen(BuildContext context, int index) {
    Navigator.pop(context);
    onNavigationChanged(index);
  }

  void _showAboutDialog(BuildContext context) {
    Navigator.pop(context);
    showAboutDialog(
      context: context,
      applicationName: 'TSL Investment',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2024 TSL Investment App',
      applicationIcon: const Icon(Icons.account_balance, size: 48, color: Color(0xFF4A6741)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Drawer Header
          Container(
            height: 200,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFB8E6D3),
                  Color(0xFF98D8C8),
                  Color(0xFF4A6741),
                ],
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Color(0xFF4A6741), size: 35),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Welcome',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'TSL Investment App',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          // Drawer Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context: context,
                  icon: Icons.home,
                  title: 'Home',
                  index: 1,
                  isSelected: currentIndex == 1,
                  onTap: () => _navigateToScreen(context, 1),
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.settings,
                  title: 'Funds',
                  index: 0,
                  isSelected: currentIndex == 0,
                  onTap: () => _navigateToScreen(context, 0),
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.pie_chart_outline,
                  title: 'Portfolio',
                  index: 2,
                  isSelected: currentIndex == 2,
                  onTap: () => _navigateToScreen(context, 2),
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.person,
                  title: 'Profile',
                  index: 3,
                  isSelected: currentIndex == 3,
                  onTap: () => _navigateToScreen(context, 3),
                ),

                // ✅ New Pages
                _buildDrawerItem(
                  context: context,
                  icon: Icons.confirmation_number,
                  title: 'Payment Confirmation',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PaymentConfirmationPage(transactionData: {},)),
                    );
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.payment,
                  title: 'Payment Methods',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PaymentMethodsPage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.account_balance_wallet,
                  title: 'Deposit',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DepositPage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.account_balance_wallet,
                  title: 'Withdrawal',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const WithdrawalPage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.account_balance_wallet,
                  title: 'Client Statement',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ClientStatementPage()),
                    );
                  },
                ),

                const Divider(thickness: 1, color: Colors.grey),

                _buildDrawerItem(
                  context: context,
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Help & Support - Coming Soon!')),
                    );
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings - Coming Soon!')),
                    );
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.info_outline,
                  title: 'About',
                  onTap: () => _showAboutDialog(context),
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.feedback_outlined,
                  title: 'Feedback',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Feedback - Coming Soon!')),
                    );
                  },
                ),
              ],
            ),
          ),

          // Logout Section
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFF4A6741)),
              title: const Text(
                'Logout',
                style: TextStyle(color: Color(0xFF4A6741), fontWeight: FontWeight.w500),
              ),
              onTap: () => _logout(context),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    int? index,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isSelected ? const Color(0xFF4A6741).withOpacity(0.1) : Colors.transparent,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFF4A6741) : Colors.grey[600],
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? const Color(0xFF4A6741) : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
