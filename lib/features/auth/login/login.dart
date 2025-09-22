import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tsl/features/auth/sign_up/signup.dart';
import '../../dashboard/dashboard.dart';
import '../forgot_password/forgot-password.dart';

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
  static const String apiUrl = 'http://192.168.3.204/TSLFMSAPI/home/Userlogin';
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

  Future<void> _login() async {
    print('Login pressed');
    print('Email/Phone: ${_emailController.text}');
    print('Password: ${_passwordController.text}');
    print('Remember me: $_rememberMe');

    // Basic validation - only check if fields are not empty
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

        if (responseData['status'] == 200 && responseData['statusDesc'] == 'success') {
          // Login successful
          _showSnackBar('Login successful!', Colors.green);

          // Navigate to Dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
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
                            keyboardType: TextInputType.text, // Changed from emailAddress to text
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