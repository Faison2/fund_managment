import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsl/constants/constants.dart';
import 'package:tsl/features/auth/sign_up/signup.dart';
import '../../accounts/individual_account.dart';
import '../../dashboard/dashboard.dart';
import '../forgot_password/forgot-password.dart';
// Update path as needed

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  // API configuration
  static const String apiUrl = '$cSharpApi/Userlogin';
  static const String apiUsername = 'User2';
  static const String apiPassword = 'CBZ1234#2';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showNoCdsNumberDialog(String username) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Complete Account Setup',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green[900],
            ),
          ),
          content: const Text(
            'Please finish up creating your individual account to continue.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => IndividualAccountScreen(),
                  ),
                );
              },
              child: Text(
                'Continue Setup',
                style: TextStyle(
                  color: Colors.green[900],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _login() async {
    print('Login pressed');
    print('Email/Phone: ${_emailController.text}');
    print('Password: ${_passwordController.text}');
    print('Remember me: $_rememberMe');

    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('Please enter both email/phone number and password', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare the request body
      Map<String, String> requestBody = {
        'APIUsername': apiUsername,
        'APIPassword': apiPassword,
        'Username': _emailController.text.trim(),
        'Password': _passwordController.text,
      };

      print('Request body: $requestBody');

      // Make the API call
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        // Check for the new response format
        if (responseData['status'] == 'success' && responseData['statusDesc'] == 'Logged in') {
          // Extract data from the response
          final data = responseData['data'] as Map<String, dynamic>?;

          if (data != null) {
            final cdsNumber = data['CDSNumber'] as String? ?? '';
            final accountStatus = data['accountStatus'] as String? ?? '';
            final username = _emailController.text.trim();

            // Save user data to SharedPreferences
            await _saveUserData(
              cdsNumber: cdsNumber,
              accountStatus: accountStatus,
              username: username,
            );

            // Check if user has no CDS number - redirect directly without success message
            if (cdsNumber.isEmpty) {
              // Show dialog to finish account setup and redirect
              _showNoCdsNumberDialog(username);
            } else {
              // User has CDS number - show success message and proceed
              _showSnackBar('Login successful!', Colors.green);

              // Check account status and handle accordingly
              if (accountStatus.toLowerCase().contains('pending')) {
                _showSnackBar('Account is pending authorization', Colors.orange);
                // You might want to navigate to a pending status screen instead
                // Or show additional information to the user
              }

              // Navigate to Dashboard (user has CDS number)
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const DashboardScreen()),
              );
            }
          } else {
            _showSnackBar('Login failed: Invalid response data', Colors.red);
          }
        }
        // Keep backward compatibility with old response format
        else if (responseData['status'] == 200 && responseData['statusDesc'] == 'success') {
          // Handle old response format
          final username = _emailController.text.trim();

          // Save basic user data for old format
          await _saveUserData(
            cdsNumber: '', // Not available in old format
            accountStatus: 'Active', // Assume active for old format
            username: username,
          );

          // For old format, assume no CDS number and redirect to account setup
          _showNoCdsNumberDialog(username);
        } else {
          // Login failed - API returned error
          _showSnackBar('Login failed: ${responseData['statusDesc'] ?? 'Unknown error'}', Colors.red);
        }
      } else {
        // HTTP error
        _showSnackBar('Login failed: Server error (${response.statusCode})', Colors.red);
      }
    } catch (e) {
      print('Login error: $e');
      _showSnackBar('Login failed: Network error. Please check your connection.', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveUserData({
    required String cdsNumber,
    required String accountStatus,
    required String username,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();


      await prefs.setString('cdsNumber', cdsNumber);
      await prefs.setString('accountStatus', accountStatus);
      await prefs.setString('username', username);
      await prefs.setBool('isLoggedIn', true);
      if (_rememberMe) {
        await prefs.setString('savedUsername', username);
        await prefs.setBool('rememberMe', true);
      } else {
        await prefs.remove('savedUsername');
        await prefs.setBool('rememberMe', false);
      }

      print('User data saved to SharedPreferences');
      print('CDS Number: $cdsNumber');
      print('Account Status: $accountStatus');
    } catch (e) {
      print('Error saving user data: $e');
    }
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool('rememberMe') ?? false;

      if (rememberMe) {
        final savedUsername = prefs.getString('savedUsername');
        if (savedUsername != null) {
          setState(() {
            _emailController.text = savedUsername;
            _rememberMe = rememberMe;
          });
        }
      }
    } catch (e) {
      print('Error loading saved credentials: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials(); // Load saved credentials when screen initializes
  }


  // Method to get user data from SharedPreferences (utility method)
  static Future<Map<String, String?>> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'cdsNumber': prefs.getString('cdsNumber'),
        'accountStatus': prefs.getString('accountStatus'),
        'username': prefs.getString('username'),
        'isLoggedIn': prefs.getBool('isLoggedIn')?.toString(),
      };
    } catch (e) {
      print('Error getting user data: $e');
      return {};
    }
  }

  // Method to clear user data (for logout)
  static Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cdsNumber');
      await prefs.remove('accountStatus');
      await prefs.remove('username');
      await prefs.setBool('isLoggedIn', false);
      print('User data cleared from SharedPreferences');
    } catch (e) {
      print('Error clearing user data: $e');
    }
  }

  void _signUp() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  void _forgotPassword() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF7FFFD4), // Aquamarine
              Color(0xFF98FB98), // Pale Green
              Color(0xFFAFEEEE), // Pale Turquoise
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 12),
                      Image.asset("assets/logo.png", width: 120, height: 120),
                    ],
                  ),
                  const SizedBox(height: 60),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Enter your email/phone number and password to login',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Email/Phone Input
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.text,
                            decoration: const InputDecoration(
                              hintText: 'Phone number/ Email',
                              hintStyle: TextStyle(color: Colors.black54),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Password Input
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              hintText: 'Password',
                              hintStyle: const TextStyle(
                                color: Colors.black54,
                                fontSize: 20,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Remember me and Forgot password
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    onChanged: (value) {
                                      setState(() {
                                        _rememberMe = value ?? false;
                                      });
                                    },
                                    activeColor: Colors.blue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Remember me',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: _forgotPassword,
                              child: const Text(
                                'Forgot Password ?',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Login Button with Loading State
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : const Text(
                              'Log In',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.white,
                                thickness: 1,
                                endIndent: 10,
                              ),
                            ),
                            Text(
                              "Don't have an account?",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.white,
                                thickness: 1,
                                indent: 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: TextButton(
                            onPressed: _signUp,
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 200),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}