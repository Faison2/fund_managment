import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../login/view/login.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  // ─── API credentials ────────────────────────────────────────────────────────
  static const String _apiUsername = 'User2';
  static const String _apiPassword = 'CBZ1234#2';
  static const String _requestResetUrl =
      'https://portaluat.tsl.co.tz/FMSAPI/Home/RequestReset';

  // ─── Step 1: Request OTP ────────────────────────────────────────────────────
  Future<void> _sendOTP() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar('Please enter your email address');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(_requestResetUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'APIUsername': _apiUsername,
          'APIPassword': _apiPassword,
          'Email': email,
        }),
      );

      final data = jsonDecode(response.body);
      final status = (data['status'] as String? ?? '').toLowerCase();

      if (response.statusCode == 200 && status == 'success') {
        // Navigate to the full-screen reset page
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _ResetPasswordScreen(
                email: _emailController.text.trim(),
                apiUsername: _apiUsername,
                apiPassword: _apiPassword,
              ),
            ),
          );
        }
      } else {
        final msg = data['statusDesc'] as String? ?? 'Failed to send OTP';
        _showSnackBar(msg);
      }
    } catch (e) {
      _showSnackBar('Network error. Please check your connection.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Snackbar ────────────────────────────────────────────────────────────────
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF1565C0),
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF7FFFD4),
              Color(0xFF98FB98),
              Color(0xFFAFEEEE),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  Container(
                    padding: const EdgeInsets.all(30),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Forgot Password',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Can't remember your password? Enter your email and we'll send you an OTP to reset it.",
                          style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[600],
                              height: 1.5),
                        ),
                        const SizedBox(height: 30),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'Enter your email',
                            prefixIcon: const Icon(Icons.email_outlined,
                                color: Colors.blue),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(
                                  color: Colors.blue, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                          ),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF1565C0),
                                  Color(0xFF42A5F5)
                                ],
                              ),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1565C0)
                                      .withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _sendOTP,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2),
                              )
                                  : const Text(
                                'Send OTP',
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Center(
                          child: Text('Remembered your password?',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 14)),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen()),
                            ),
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                  color: Color(0xFF1565C0),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
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

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  Full-screen Reset Password Page
// ════════════════════════════════════════════════════════════════════════════

class _ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String apiUsername;
  final String apiPassword;

  static const String _confirmResetUrl =
      'https://portaluat.tsl.co.tz/FMSAPI/Home/ConfirmReset';

  const _ResetPasswordScreen({
    required this.email,
    required this.apiUsername,
    required this.apiPassword,
  });

  @override
  State<_ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<_ResetPasswordScreen> {
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  // ─── Resend OTP ──────────────────────────────────────────────────────────────
  Future<void> _resendOTP() async {
    _showSnackBar('Resending OTP…');
    try {
      final response = await http.post(
        Uri.parse('https://portaluat.tsl.co.tz/FMSAPI/Home/RequestReset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'APIUsername': widget.apiUsername,
          'APIPassword': widget.apiPassword,
          'Email': widget.email,
        }),
      );
      final data = jsonDecode(response.body);
      final status = (data['status'] as String? ?? '').toLowerCase();
      final msg = status == 'success'
          ? 'OTP resent successfully'
          : (data['statusDesc'] as String? ?? 'Failed to resend OTP');
      _showSnackBar(msg);
    } catch (_) {
      _showSnackBar('Network error. Please check your connection.');
    }
  }

  // ─── Confirm Reset ───────────────────────────────────────────────────────────
  Future<void> _resetPassword() async {
    final otp = _otpController.text.trim();
    final newPwd = _newPasswordController.text;
    final confirmPwd = _confirmPasswordController.text;

    if (otp.length != 6) {
      _showSnackBar('Please enter the 6-digit OTP');
      return;
    }
    if (newPwd.isEmpty || confirmPwd.isEmpty) {
      _showSnackBar('Please fill in all password fields');
      return;
    }
    if (newPwd != confirmPwd) {
      _showSnackBar('Passwords do not match');
      return;
    }
    if (newPwd.length < 6) {
      _showSnackBar('Password must be at least 6 characters');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(_ResetPasswordScreen._confirmResetUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'APIUsername': widget.apiUsername,
          'APIPassword': widget.apiPassword,
          'Email': widget.email,
          'Otp': otp,
          'NewPassword': newPwd,
        }),
      );

      final data = jsonDecode(response.body);
      final status = (data['status'] as String? ?? '').toLowerCase();

      if (response.statusCode == 200 && status == 'success') {
        _showSuccessDialog();
      } else {
        final msg =
            data['statusDesc'] as String? ?? 'Password reset failed';
        _showSnackBar(msg);
      }
    } catch (_) {
      _showSnackBar('Network error. Please check your connection.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Success dialog ──────────────────────────────────────────────────────────
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.2),
                blurRadius: 40,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 50),
              ),
              const SizedBox(height: 24),
              const Text(
                'Password Changed!',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(height: 10),
              Text(
                'Your password has been updated successfully.\nYou can now sign in with your new password.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, color: Colors.grey[500], height: 1.6),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1565C0).withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen()),
                          (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Back to Login',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Snackbar ────────────────────────────────────────────────────────────────
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF1565C0),
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────
  Widget _sectionLabel(String label) => Text(
    label,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: Color(0xFF1565C0),
      letterSpacing: 0.8,
    ),
  );

  InputDecoration _passwordDecoration({
    required String hint,
    required bool isObscure,
    required VoidCallback onToggle,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF0F7FF),
        prefixIcon: const Icon(Icons.lock_outline_rounded,
            color: Color(0xFF42A5F5), size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            isObscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: Colors.grey[400],
            size: 20,
          ),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          const BorderSide(color: Color(0xFF42A5F5), width: 2),
        ),
        contentPadding:
        const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      );

  // ─── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1565C0),
              Color(0xFF1E88E5),
              Color(0xFF42A5F5),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ────────────────────────────────────────────────
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'Reset Password',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    // Balances the row so the title stays centered
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // ── Header icon + subtitle ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.5), width: 2),
                      ),
                      child: const Icon(Icons.lock_reset_rounded,
                          color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'OTP sent to',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.7), fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.email,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

              // ── White card with form ───────────────────────────────────
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // OTP field
                        _sectionLabel('One-Time Password (OTP)'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 12,
                            color: Color(0xFF1565C0),
                          ),
                          decoration: InputDecoration(
                            hintText: '· · · · · ·',
                            hintStyle: TextStyle(
                              fontSize: 22,
                              letterSpacing: 8,
                              color: Colors.grey[300],
                            ),
                            counterText: '',
                            filled: true,
                            fillColor: const Color(0xFFF0F7FF),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: Color(0xFF42A5F5), width: 2),
                            ),
                            contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),

                        // Resend OTP link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _resendOTP,
                            child: const Text(
                              'Resend OTP',
                              style: TextStyle(
                                  color: Color(0xFF1565C0),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),

                        // Divider
                        Row(children: [
                          const Expanded(
                              child:
                              Divider(color: Color(0xFFEEEEEE))),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10),
                            child: Text('NEW PASSWORD',
                                style: TextStyle(
                                    fontSize: 10,
                                    letterSpacing: 1.2,
                                    color: Colors.grey[400])),
                          ),
                          const Expanded(
                              child:
                              Divider(color: Color(0xFFEEEEEE))),
                        ]),

                        const SizedBox(height: 20),

                        // New password
                        _sectionLabel('New Password'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _newPasswordController,
                          obscureText: _obscureNew,
                          style: const TextStyle(
                              color: Colors.black87, fontSize: 15),
                          decoration: _passwordDecoration(
                            hint: 'Enter new password',
                            isObscure: _obscureNew,
                            onToggle: () =>
                                setState(() => _obscureNew = !_obscureNew),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Confirm password
                        _sectionLabel('Confirm Password'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirm,
                          style: const TextStyle(
                              color: Colors.black87, fontSize: 15),
                          decoration: _passwordDecoration(
                            hint: 'Confirm new password',
                            isObscure: _obscureConfirm,
                            onToggle: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Reset button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF1565C0),
                                  Color(0xFF42A5F5)
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1565C0)
                                      .withOpacity(0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _resetPassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5),
                              )
                                  : const Text(
                                'Reset Password',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}