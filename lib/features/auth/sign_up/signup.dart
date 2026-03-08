import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tsl/constants/constants.dart';
import 'dart:convert';
import '../../accounts/individual_account.dart';
import '../login/view/login.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreeToTerms = false;
  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ─── Theme ───────────────────────────────────────────────────────────────────
  static const Color _primaryGreen = Color(0xFF2DC98E);
  static const Color _deepGreen = Color(0xFF1A9B6C);
  static const Color _softMint = Color(0xFFE8FBF4);
  static const Color _textDark = Color(0xFF1A2332);
  static const Color _textMuted = Color(0xFF8A9BB0);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOut),
        );
    _animController.forward();
  }

  // ─── Terms Dialog ─────────────────────────────────────────────────────────────

  void _showTermsAndConditions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _softMint,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.gavel_rounded,
                          color: _primaryGreen, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Terms & Conditions',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _textDark),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: _textMuted),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Divider(height: 24, color: Colors.grey[100]),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTermsSection(
                        'Welcome',
                        'By accessing and using this application, you accept and agree to be bound by the terms and provision of this agreement.',
                        icon: Icons.waving_hand_rounded,
                      ),
                      _buildTermsSection(
                        '1. Account Registration',
                        'You must provide accurate and complete information during registration. You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account.',
                        icon: Icons.how_to_reg_outlined,
                      ),
                      _buildTermsSection(
                        '2. User Responsibilities',
                        'You agree to use the service only for lawful purposes and in accordance with these Terms. You must not use the service in any way that could damage, disable, or impair the service.',
                        icon: Icons.person_outline_rounded,
                      ),
                      _buildTermsSection(
                        '3. Privacy',
                        'Your privacy is important to us. We collect and use your personal information in accordance with our Privacy Policy. By using our service, you consent to the collection and use of your information as described.',
                        icon: Icons.lock_outline_rounded,
                      ),
                      _buildTermsSection(
                        '4. Data Security',
                        'We implement appropriate security measures to protect your personal information. However, no method of transmission over the internet is 100% secure, and we cannot guarantee absolute security.',
                        icon: Icons.security_rounded,
                      ),
                      _buildTermsSection(
                        '5. Service Availability',
                        'We strive to provide uninterrupted service, but we do not guarantee that the service will be available at all times. We may suspend or terminate the service for maintenance or other reasons.',
                        icon: Icons.cloud_outlined,
                      ),
                      _buildTermsSection(
                        '6. Intellectual Property',
                        'All content, features, and functionality of the service are owned by us and are protected by international copyright, trademark, and other intellectual property laws.',
                        icon: Icons.copyright_outlined,
                      ),
                      _buildTermsSection(
                        '7. Limitation of Liability',
                        'To the maximum extent permitted by law, we shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of the service.',
                        icon: Icons.balance_outlined,
                      ),
                      _buildTermsSection(
                        '8. Changes to Terms',
                        'We reserve the right to modify these terms at any time. We will notify users of any material changes. Your continued use of the service after changes constitutes acceptance of the new terms.',
                        icon: Icons.edit_note_rounded,
                      ),
                      _buildTermsSection(
                        '9. Termination',
                        'We may terminate or suspend your account and access to the service immediately, without prior notice, for any breach of these Terms.',
                        icon: Icons.block_outlined,
                      ),
                      _buildTermsSection(
                        '10. Contact Information',
                        'If you have any questions about these Terms, please contact our support team through the app or via our official channels.',
                        icon: Icons.contact_support_outlined,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Last Updated: ${DateTime.now().year}',
                        style: TextStyle(
                            fontSize: 12,
                            color: _textMuted,
                            fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => _agreeToTerms = true);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('I Accept & Continue',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermsSection(String title, String content,
      {required IconData icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _softMint,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _primaryGreen, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _textDark)),
                const SizedBox(height: 6),
                Text(content,
                    style: TextStyle(
                        fontSize: 13, color: _textMuted, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Register Logic ───────────────────────────────────────────────────────────

  Future<void> _register() async {
    if (!_validateForm()) return;
    if (!_agreeToTerms) {
      _showSnackBar('Please agree to the Terms & Conditions');
      return;
    }
    setState(() => _isLoading = true);
    try {
      String formattedPhone = _phoneController.text.trim();
      if (formattedPhone.startsWith('0')) {
        formattedPhone = formattedPhone.substring(1);
      }
      final response = await http.post(
        Uri.parse('$cSharpApi/UserSignUp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "APIUsername": "User2",
          "APIPassword": "CBZ1234#2",
          "Email": _emailController.text.trim(),
          "PhoneNumber": formattedPhone,
          "Password": _passwordController.text,
          "Source": "Mobile",
        }),
      );
      setState(() => _isLoading = false);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          _showSuccessDialog();
        } else {
          _showSnackBar(responseData['statusDesc'] ?? 'Registration failed');
        }
      } else {
        _showSnackBar('Network error. Please try again.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('An error occurred. Please check your connection.');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                    color: _softMint, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded,
                    color: _primaryGreen, size: 44),
              ),
              const SizedBox(height: 20),
              const Text('Account Created!',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _textDark)),
              const SizedBox(height: 10),
              Text(
                'Your account has been created successfully. What would you like to do next?',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, color: _textMuted, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.person_add_rounded,
                      size: 18, color: Colors.white),
                  label: const Text('Create Individual Account',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                            const IndividualAccountScreen()));
                  },
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.login_rounded,
                      size: 18, color: _primaryGreen),
                  label: const Text('Go to Login',
                      style: TextStyle(
                          color: _primaryGreen,
                          fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _primaryGreen, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LoginScreen()));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _validateForm() {
    if (_emailController.text.isEmpty ||
        !_emailController.text.contains('@')) {
      _showSnackBar('Please enter a valid email');
      return false;
    }
    if (_phoneController.text.isEmpty) {
      _showSnackBar('Please enter your phone number');
      return false;
    }
    if (_passwordController.text.isEmpty ||
        _passwordController.text.length < 6) {
      _showSnackBar('Password must be at least 6 characters');
      return false;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('Passwords do not match');
      return false;
    }
    return true;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _textDark,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Back Button ─────────────────────────────────────────
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (_) => const LoginScreen())),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: _textDark, size: 18),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Create Account',
                      style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: _textDark,
                          letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Fill in your details to get started',
                      style: TextStyle(fontSize: 15, color: _textMuted),
                    ),
                    const SizedBox(height: 36),

                    // ── Form Card ───────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.8), width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel('Account Info'),
                          _buildInputField(
                            controller: _emailController,
                            label: 'Email Address',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 14),
                          _buildInputField(
                            controller: _phoneController,
                            label: 'Phone Number',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 22),
                          _buildSectionLabel('Security'),
                          _buildPasswordField(
                            controller: _passwordController,
                            label: 'Password',
                            isVisible: _isPasswordVisible,
                            onToggle: () => setState(
                                    () => _isPasswordVisible = !_isPasswordVisible),
                          ),
                          const SizedBox(height: 14),
                          _buildPasswordField(
                            controller: _confirmPasswordController,
                            label: 'Confirm Password',
                            isVisible: _isConfirmPasswordVisible,
                            onToggle: () => setState(() =>
                            _isConfirmPasswordVisible =
                            !_isConfirmPasswordVisible),
                          ),
                          const SizedBox(height: 6),
                          // Password strength hint
                          Padding(
                            padding: const EdgeInsets.only(left: 4, top: 6),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline_rounded,
                                    size: 13, color: _textMuted),
                                const SizedBox(width: 5),
                                Text('Minimum 6 characters',
                                    style: TextStyle(
                                        fontSize: 12, color: _textMuted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Terms Checkbox ──────────────────────────────────────
                    GestureDetector(
                      onTap: () =>
                          setState(() => _agreeToTerms = !_agreeToTerms),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: _agreeToTerms
                              ? _softMint
                              : Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _agreeToTerms
                                ? _primaryGreen
                                : Colors.grey.withOpacity(0.2),
                            width: _agreeToTerms ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _agreeToTerms
                                    ? _primaryGreen
                                    : Colors.transparent,
                                border: Border.all(
                                  color: _agreeToTerms
                                      ? _primaryGreen
                                      : Colors.grey[400]!,
                                  width: 2,
                                ),
                              ),
                              child: _agreeToTerms
                                  ? const Icon(Icons.check_rounded,
                                  size: 14, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                      fontSize: 14, color: _textMuted),
                                  children: [
                                    const TextSpan(text: 'I agree to the '),
                                    WidgetSpan(
                                      child: GestureDetector(
                                        onTap: _showTermsAndConditions,
                                        child: const Text(
                                          'Terms & Conditions',
                                          style: TextStyle(
                                            color: _primaryGreen,
                                            fontWeight: FontWeight.w700,
                                            decoration:
                                            TextDecoration.underline,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Sign Up Button ──────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          disabledBackgroundColor:
                          _primaryGreen.withOpacity(0.5),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                            : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Create Account',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Login Link ──────────────────────────────────────────
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pushReplacement(context,
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen())),
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                                fontSize: 14, color: _textMuted),
                            children: const [
                              TextSpan(text: 'Already have an account? '),
                              TextSpan(
                                text: 'Sign In',
                                style: TextStyle(
                                    color: _primaryGreen,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Shared Widgets ───────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                  color: _primaryGreen,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                  letterSpacing: 0.3)),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 15, color: _textDark),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: _textMuted, fontSize: 14),
          prefixIcon: Icon(icon, color: _primaryGreen, size: 20),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: !isVisible,
        style: const TextStyle(fontSize: 15, color: _textDark),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: _textMuted, fontSize: 14),
          prefixIcon:
          const Icon(Icons.lock_outline_rounded, color: _primaryGreen, size: 20),
          suffixIcon: GestureDetector(
            onTap: onToggle,
            child: Icon(
              isVisible
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: _textMuted,
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}