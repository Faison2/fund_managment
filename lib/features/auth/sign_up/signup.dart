import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:tsl/constants/constants.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../../accounts/individual_account.dart';
import '../login/view/login.dart';

// ─── Entry point ──────────────────────────────────────────────────────────────
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  bool? _isNewClient;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ── TSL Brand colours ──────────────────────────────────────────────────────
  static const Color _primaryGreen = Color(0xFF00A79D);
  static const Color _deepGreen    = Color(0xFF329AD6);
  static const Color _softMint     = Color(0xFFE0F5F4);
  static const Color _textDark     = Color(0xFF231F20);
  static const Color _textMuted    = Color(0xFF939598);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
            CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _restart() {
    setState(() => _isNewClient = null);
    _animController.forward(from: 0);
  }

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
            colors: [Color(0xFFB8E6E4), Color(0xFF98D8D4), Color(0xFFB8D8E8)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: _buildBody(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isNewClient == null) return _ClientTypePicker(onPick: _onTypePicked);
    if (_isNewClient == true) {
      return _NewClientFlow(
        primaryGreen: _primaryGreen,
        softMint: _softMint,
        textDark: _textDark,
        textMuted: _textMuted,
        onBack: _restart,
      );
    }
    return _ExistingClientFlow(
      primaryGreen: _primaryGreen,
      softMint: _softMint,
      textDark: _textDark,
      textMuted: _textMuted,
      onBack: _restart,
    );
  }

  void _onTypePicked(bool isNew) {
    setState(() => _isNewClient = isNew);
    _animController.forward(from: 0);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CLIENT TYPE PICKER
// ─────────────────────────────────────────────────────────────────────────────
class _ClientTypePicker extends StatelessWidget {
  final void Function(bool isNew) onPick;
  static const Color _primaryGreen = Color(0xFF00A79D);
  static const Color _softMint     = Color(0xFFE0F5F4);
  static const Color _textDark     = Color(0xFF231F20);
  static const Color _textMuted    = Color(0xFF939598);

  const _ClientTypePicker({required this.onPick});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 32),
          const Text('Create Account',
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                  letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Text('Are you a new or existing client?',
              style: TextStyle(fontSize: 15, color: _textMuted)),
          const SizedBox(height: 40),
          _PickCard(
            icon: Icons.person_add_rounded,
            title: 'New Client',
            subtitle: 'Register a brand new account with us',
            onTap: () => onPick(true),
          ),
          const SizedBox(height: 16),
          _PickCard(
            icon: Icons.manage_accounts_rounded,
            title: 'Existing Client',
            subtitle: 'Already have an Account number? Set up online access',
            onTap: () => onPick(false),
          ),
          const SizedBox(height: 32),
          Center(
            child: GestureDetector(
              onTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen())),
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 14, color: _textMuted),
                  children: [
                    TextSpan(text: 'Already have an account? '),
                    TextSpan(
                        text: 'Sign In',
                        style: TextStyle(
                            color: _primaryGreen,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  static const Color _primaryGreen = Color(0xFF00A79D);
  static const Color _softMint     = Color(0xFFE0F5F4);
  static const Color _textDark     = Color(0xFF231F20);
  static const Color _textMuted    = Color(0xFF939598);

  const _PickCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: _softMint, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: _primaryGreen, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: _textDark)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(fontSize: 13, color: _textMuted)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: _primaryGreen, size: 24),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NEW CLIENT FLOW
// ─────────────────────────────────────────────────────────────────────────────
class _NewClientFlow extends StatefulWidget {
  final Color primaryGreen, softMint, textDark, textMuted;
  final VoidCallback onBack;
  const _NewClientFlow({
    required this.primaryGreen,
    required this.softMint,
    required this.textDark,
    required this.textMuted,
    required this.onBack,
  });

  @override
  State<_NewClientFlow> createState() => _NewClientFlowState();
}

class _NewClientFlowState extends State<_NewClientFlow> {
  final _emailCtrl       = TextEditingController();
  final _phoneCtrl       = TextEditingController();
  final _passCtrl        = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _passVisible = false, _confirmVisible = false;
  bool _agreeToTerms = false, _isLoading = false;

  Color get _g    => widget.primaryGreen;
  Color get _mint => widget.softMint;
  Color get _dark => widget.textDark;
  Color get _muted => widget.textMuted;

  Future<void> _saveCredentials(String email, String phone, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_email', email);
    await prefs.setString('saved_phone', phone);
    // ✅ Save password so IndividualAccountScreen can read it for CreateAccount
    await prefs.setString('saved_password', password);
  }

  Future<void> _register() async {
    if (!_validate()) return;
    if (!_agreeToTerms) {
      _snack('Please agree to the Terms & Conditions');
      return;
    }
    setState(() => _isLoading = true);
    try {
      // ✅ Normalise phone: strip leading zero, do NOT prepend 255
      // (let the server handle country code logic)
      String phone = _phoneCtrl.text.trim();
      if (phone.startsWith('0')) phone = phone.substring(1);

      final res = await http.post(
        Uri.parse('$cSharpApi/UserSignUp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "APIUsername": apiUsername,
          "APIPassword": apiPassword,
          "Email":       _emailCtrl.text.trim(),
          "PhoneNumber": phone,
          "Password":    _passCtrl.text,
          "Source":      "MobileApp", // ✅ FIXED: was "Mobile"
        }),
      );

      setState(() => _isLoading = false);

      if (res.statusCode == 200) {
        final d = jsonDecode(res.body);
        // ✅ Handle both 'success' string and status == 200 int
        final isSuccess = d['status'] == 'success' ||
            d['status'] == 200 ||
            (d['statusDesc'] ?? '').toString().toLowerCase() == 'success';

        if (isSuccess) {
          await _saveCredentials(
            _emailCtrl.text.trim(),
            _phoneCtrl.text.trim(),
            _passCtrl.text,
          );
          _showSuccessDialog();
        } else {
          _snack(d['statusDesc'] ?? d['message'] ?? 'Registration failed');
        }
      } else {
        _snack('Network error (${res.statusCode}). Please try again.');
      }
    } catch (_) {
      setState(() => _isLoading = false);
      _snack('An error occurred. Please check your connection.');
    }
  }

  bool _validate() {
    if (_emailCtrl.text.isEmpty || !_emailCtrl.text.contains('@')) {
      _snack('Please enter a valid email');
      return false;
    }
    if (_phoneCtrl.text.isEmpty) {
      _snack('Please enter your phone number');
      return false;
    }
    if (_passCtrl.text.length < 8) {
      // ✅ FIXED: raised to 8 to match IndividualAccountScreen validation
      _snack('Password must be at least 8 characters');
      return false;
    }
    if (!RegExp(r'[A-Z]').hasMatch(_passCtrl.text)) {
      _snack('Password must contain at least one uppercase letter');
      return false;
    }
    if (!RegExp(r'[0-9]').hasMatch(_passCtrl.text)) {
      _snack('Password must contain at least one number');
      return false;
    }
    if (_passCtrl.text != _confirmPassCtrl.text) {
      _snack('Passwords do not match');
      return false;
    }
    return true;
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.info_outline, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg)),
      ]),
      behavior: SnackBarBehavior.floating,
      backgroundColor: widget.textDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration:
              BoxDecoration(color: widget.softMint, shape: BoxShape.circle),
              child:
              Icon(Icons.check_rounded, color: widget.primaryGreen, size: 44),
            ),
            const SizedBox(height: 20),
            Text('Account Created!',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: widget.textDark)),
            const SizedBox(height: 10),
            Text('Your account has been created successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, color: widget.textMuted, height: 1.5)),
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
                    backgroundColor: widget.primaryGreen,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const IndividualAccountScreen()));
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: Icon(Icons.login_rounded,
                    size: 18, color: widget.primaryGreen),
                label: Text('Go to Login',
                    style: TextStyle(
                        color: widget.primaryGreen,
                        fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                    side: BorderSide(color: widget.primaryGreen, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()));
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(
          onTap: widget.onBack,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF1A2332), size: 18),
          ),
        ),
        const SizedBox(height: 10),
        const Text('New Client',
            style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A2332),
                letterSpacing: -0.5)),
        const SizedBox(height: 6),
        Text('Fill in your details to get started',
            style: TextStyle(fontSize: 15, color: _muted)),
        const SizedBox(height: 28),
        _card(children: [
          _sectionLabel('Account Info'),
          _inputField(
              controller: _emailCtrl,
              label: 'Email Address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 14),
          _inputField(
              controller: _phoneCtrl,
              label: 'Phone Number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone),
          const SizedBox(height: 22),
          _sectionLabel('Security'),
          _passField(
              controller: _passCtrl,
              label: 'Password',
              isVisible: _passVisible,
              onToggle: () => setState(() => _passVisible = !_passVisible)),
          const SizedBox(height: 14),
          _passField(
              controller: _confirmPassCtrl,
              label: 'Confirm Password',
              isVisible: _confirmVisible,
              onToggle: () =>
                  setState(() => _confirmVisible = !_confirmVisible)),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.info_outline_rounded, size: 13, color: _muted),
                  const SizedBox(width: 5),
                  Text('Minimum 8 characters', // ✅ FIXED: was 6
                      style: TextStyle(fontSize: 12, color: _muted)),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.info_outline_rounded, size: 13, color: _muted),
                  const SizedBox(width: 5),
                  Text('At least 1 uppercase letter and 1 number',
                      style: TextStyle(fontSize: 12, color: _muted)),
                ]),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _agreeToTerms ? _mint : Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: _agreeToTerms ? _g : Colors.grey.withOpacity(0.2),
                  width: _agreeToTerms ? 1.5 : 1),
            ),
            child: Row(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _agreeToTerms ? _g : Colors.transparent,
                    border: Border.all(
                        color: _agreeToTerms ? _g : Colors.grey[400]!,
                        width: 2)),
                child: _agreeToTerms
                    ? const Icon(Icons.check_rounded,
                    size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text.rich(TextSpan(
                  style: TextStyle(fontSize: 14, color: _muted),
                  children: [
                    const TextSpan(text: 'I agree to the '),
                    TextSpan(
                        text: 'Terms & Conditions',
                        style: TextStyle(
                            color: _g,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                            fontSize: 14)),
                  ],
                )),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _register,
            style: ElevatedButton.styleFrom(
                backgroundColor: _g,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                disabledBackgroundColor: _g.withOpacity(0.5)),
            child: _isLoading
                ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
                : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Create Account',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ]),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: () => Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const LoginScreen())),
            child: Text.rich(TextSpan(
              style: TextStyle(fontSize: 14, color: _muted),
              children: [
                const TextSpan(text: 'Already have an account? '),
                TextSpan(
                    text: 'Sign In',
                    style: TextStyle(color: _g, fontWeight: FontWeight.w700)),
              ],
            )),
          ),
        ),
        const SizedBox(height: 12),
      ]),
    );
  }

  Widget _card({required List<Widget> children}) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border:
        Border.all(color: Colors.white.withOpacity(0.8), width: 1)),
    child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children),
  );

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
              color: _g, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(label,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A2332),
              letterSpacing: 0.3)),
    ]),
  );

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) =>
      Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ]),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 15, color: Color(0xFF1A2332)),
          decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: _muted, fontSize: 14),
              prefixIcon: Icon(icon, color: _g, size: 20),
              border: InputBorder.none,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
              floatingLabelBehavior: FloatingLabelBehavior.auto),
        ),
      );

  Widget _passField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onToggle,
  }) =>
      Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ]),
        child: TextField(
          controller: controller,
          obscureText: !isVisible,
          style: const TextStyle(fontSize: 15, color: Color(0xFF1A2332)),
          decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: _muted, fontSize: 14),
              prefixIcon:
              Icon(Icons.lock_outline_rounded, color: _g, size: 20),
              suffixIcon: GestureDetector(
                  onTap: onToggle,
                  child: Icon(
                      isVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: _muted,
                      size: 20)),
              border: InputBorder.none,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
              floatingLabelBehavior: FloatingLabelBehavior.auto),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// EXISTING CLIENT FLOW  (3 steps: validate → KYC → complete setup)
// ─────────────────────────────────────────────────────────────────────────────

/// SWIFT codes keyed by bank name (lowercase-contains match)
const Map<String, String> _bankSwiftMap = {
  'crdb':              'CORUTZTZ',
  'nmb':               'NMBATZTZ',
  'nbct':              'NLCBTZTX',
  'national bank':     'NLCBTZTX',
  'standard chartered':'SCBLTZTX',
  'stanchart':         'SCBLTZTX',
  'barclays':          'BARCTZTZ',
  'absa':              'BARCTZTZ',
  'stanbic':           'SBICTZTX',
  'exim':              'EXTNTZTZ',
  'equity':            'EQBLTZTZ',
  'kcb':               'KCBLTZTZ',
  'azania':            'AZANTZTX',
  'dtb':               'DTKETZTZ',
  'diamond trust':     'DTKETZTZ',
  'citi':              'CITITZTZ',
  'citibank':          'CITITZTZ',
  'tib':               'TIBDTZTX',
  'uchumi':            'UCMTTZTZ',
  'mkombozi':          'MKCBTZTZ',
  'tpb':               'TPBKTZTZ',
  'postal':            'TPBKTZTZ',
  "people's bank":     'TPBKTZTZ',
};

String? _lookupSwift(String bankName) {
  final lower = bankName.toLowerCase();
  for (final entry in _bankSwiftMap.entries) {
    if (lower.contains(entry.key)) return entry.value;
  }
  return null;
}

class _ExistingClientFlow extends StatefulWidget {
  final Color primaryGreen, softMint, textDark, textMuted;
  final VoidCallback onBack;
  const _ExistingClientFlow({
    required this.primaryGreen,
    required this.softMint,
    required this.textDark,
    required this.textMuted,
    required this.onBack,
  });

  @override
  State<_ExistingClientFlow> createState() => _ExistingClientFlowState();
}

class _ExistingClientFlowState extends State<_ExistingClientFlow> {
  // Step 0 = verify, 1 = KYC review, 2 = complete setup
  int _step = 0;

  // Step 0
  final _emailCtrl = TextEditingController();
  final _cdsCtrl   = TextEditingController();
  bool _validating = false;

  // Fetched client data
  Map<String, dynamic>? _clientData;

  // KYC controllers (auto-filled from API)
  final _kycNameCtrl    = TextEditingController();
  final _kycEmailCtrl   = TextEditingController();
  final _kycMobileCtrl  = TextEditingController();
  final _kycAddrCtrl    = TextEditingController();
  final _kycBankCtrl    = TextEditingController();
  final _kycAccNoCtrl   = TextEditingController();
  final _kycAccNameCtrl = TextEditingController();
  final _kycBranchCtrl  = TextEditingController();

  // Step 2: Additional required fields
  final _passCtrl        = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _firstNameCtrl   = TextEditingController();
  final _surnameCtrl     = TextEditingController();
  final _otherNamesCtrl  = TextEditingController();
  final _dobCtrl         = TextEditingController();
  final _birthPlaceCtrl  = TextEditingController();
  final _occupationCtrl  = TextEditingController();
  final _nationalityCtrl = TextEditingController();
  final _idCtrl          = TextEditingController();
  final _idExpiryCtrl    = TextEditingController();
  final _cityCtrl        = TextEditingController();
  final _countryCtrl     = TextEditingController();
  final _swiftCodeCtrl   = TextEditingController();
  final _bankAddressCtrl = TextEditingController();
  final _pepDetailsCtrl  = TextEditingController();

  // ── Dropdowns ─────────────────────────────────────────────────────────────
  String _gender            = 'Male';
  String _title             = 'Mr';
  String _investmentPurpose = 'Wealth Creation';
  String _incomeSource      = 'Salary';
  String _riskTolerance     = 'Moderate'; // ✅ FIXED: was 'Medium'
  String _investmentPeriod  = '12 Months'; // ✅ FIXED: was 'Long Term'
  String _bankType          = 'Local';
  String _disclosure        = 'No';
  // ✅ NEW: Service required (matches correct cURL)
  String _serviceRequired   = 'Unit Trust Investment';

  // ID Type dropdown
  static const List<String> _idTypes = [
    'Driving License',
    'Voter ID',
    'Zanzibar ID',
  ];
  String _idType = 'Driving License';

  // Issuing Authority dropdown
  static const List<String> _issuingAuthorities = [
    'TRA',
    'NEC',
    'Zanzibar Registration Institute',
  ];
  String _issuingAuthority = 'TRA';

  // ID document upload
  File? _idDocument;
  String? _idDocumentName;
  bool _idDocumentIsPdf = false;
  final _imagePicker = ImagePicker();

  bool _passVisible = false, _confirmVisible = false;
  bool _submitting  = false;

  Color get _g    => widget.primaryGreen;
  Color get _mint => widget.softMint;
  Color get _dark => widget.textDark;
  Color get _muted => widget.textMuted;

  Future<void> _saveCredentials(String email, String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_email', email);
    await prefs.setString('saved_phone', phone);
  }

  // ── Step 0: Validate via API ───────────────────────────────────────────────
  Future<void> _validateClient() async {
    final email = _emailCtrl.text.trim();
    final cds   = _cdsCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _snack('Enter a valid email');
      return;
    }
    if (cds.isEmpty) {
      _snack('Enter your Account number');
      return;
    }

    setState(() => _validating = true);
    try {
      final res = await http.post(
        Uri.parse('$cSharpApi/UserBasicDetails'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"CDSNumber": cds}),
      );

      setState(() => _validating = false);

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final data = body['data'];
        if (data != null) {
          final serverEmail = (data['Email'] ?? '') as String;
          if (serverEmail.isNotEmpty &&
              serverEmail.toLowerCase() != email.toLowerCase()) {
            _snack('Email does not match our records for this account.');
            return;
          }
          _clientData = Map<String, dynamic>.from(data);
          _populateFields(data);
          setState(() => _step = 1);
        } else {
          _snack('Account not found. Please check your details.');
        }
      } else {
        _snack('Network error. Please try again.');
      }
    } catch (e) {
      setState(() => _validating = false);
      _snack('Connection error. Please try again.');
    }
  }

  /// Map all fields from the API response into controllers and dropdowns.
  void _populateFields(Map<String, dynamic> data) {
    // ── KYC step 1 fields ────────────────────────────────────────────────────
    final forenames = (data['Forenames'] ?? '').toString().trim();
    final middle    = (data['middlename'] ?? '').toString().trim();
    final surname   = (data['surname'] ?? '').toString().trim();
    final fullName  = [forenames, middle, surname]
        .where((s) => s.isNotEmpty)
        .join(' ');
    _kycNameCtrl.text    = fullName.isNotEmpty ? fullName : (data['Names'] ?? '');
    _kycEmailCtrl.text   = data['Email'] ?? '';
    _kycMobileCtrl.text  = data['Mobile'] ?? '';
    _kycAddrCtrl.text    = data['Add_1'] ?? '';
    _kycBankCtrl.text    = data['Bank'] ?? '';
    _kycAccNoCtrl.text   = data['AccountNo'] ?? '';
    _kycAccNameCtrl.text = data['AccountName'] ?? '';
    _kycBranchCtrl.text  = data['Branch'] ?? '';

    // ── Step 2 personal fields ───────────────────────────────────────────────
    _firstNameCtrl.text   = forenames.isNotEmpty ? forenames : '';
    _surnameCtrl.text     = surname.isNotEmpty ? surname : '';
    _otherNamesCtrl.text  = middle;

    final apiTitle = (data['Title'] ?? '').toString().trim();
    if (['Mr', 'Mrs', 'Ms', 'Dr', 'Prof'].contains(apiTitle)) _title = apiTitle;

    final apiGender = (data['Gender'] ?? '').toString().trim();
    if (['Male', 'Female'].contains(apiGender)) _gender = apiGender;

    final rawDob = (data['DOB'] ?? '').toString().trim();
    _dobCtrl.text = _parseDob(rawDob);

    _birthPlaceCtrl.text  = data['PlaceofBirth'] ?? '';
    _occupationCtrl.text  = data['Occupation'] ?? '';
    _nationalityCtrl.text = data['Nationality'] ?? '';
    _cityCtrl.text        = data['City'] ?? '';
    _countryCtrl.text     = data['Country'] ?? '';

    _idCtrl.text       = data['IdentificationNo'] ?? '';
    _idExpiryCtrl.text = (data['IDExpiry'] ?? '').toString().trim();

    final rawAuthority = (data['placeofissue'] ?? '').toString().trim();
    if (_issuingAuthorities.contains(rawAuthority)) _issuingAuthority = rawAuthority;

    final rawIdType = (data['IDtype'] ?? '').toString().trim();
    if (_idTypes.contains(rawIdType)) _idType = rawIdType;

    _bankAddressCtrl.text = data['BankAddress'] ?? '';
    final apiSwift  = (data['SwiftCode'] ?? '').toString().trim();
    final bankName  = (data['Bank'] ?? '').toString().trim();
    _swiftCodeCtrl.text =
    apiSwift.isNotEmpty ? apiSwift : (_lookupSwift(bankName) ?? '');

    final rawIncome = (data['SourceofIncome'] ?? '').toString().trim();
    const incomeOptions = ['Salary', 'Business', 'Investments', 'Inheritance', 'Other'];
    _incomeSource = incomeOptions.contains(rawIncome) ? rawIncome : 'Salary';

    final rawPurpose = (data['PurposeOfInvestment'] ?? '').toString().trim();
    const purposeOptions = [
      'Wealth Creation', 'Retirement', 'Education', 'Income', 'Speculation'
    ];
    _investmentPurpose =
    purposeOptions.contains(rawPurpose) ? rawPurpose : 'Wealth Creation';

    final rawPep = (data['PEPDisclosure'] ?? '').toString().trim();
    _disclosure = (rawPep.toLowerCase() == 'yes' ||
        rawPep.toLowerCase().contains('politically'))
        ? 'Yes'
        : 'No';

    if (_disclosure == 'Yes') {
      final positionHeld = (data['PositionHeld'] ?? '').toString().trim();
      if (positionHeld.isNotEmpty && positionHeld.toLowerCase() != 'none') {
        _pepDetailsCtrl.text = positionHeld;
      }
    }
  }

  /// Converts "25-Feb-2019" → "2019-02-25". Returns original string on failure.
  String _parseDob(String raw) {
    if (raw.isEmpty) return '';
    try {
      final parts = raw.split('-');
      if (parts.length != 3) return raw;
      const months = {
        'jan': '01', 'feb': '02', 'mar': '03', 'apr': '04',
        'may': '05', 'jun': '06', 'jul': '07', 'aug': '08',
        'sep': '09', 'oct': '10', 'nov': '11', 'dec': '12',
      };
      final day   = parts[0].padLeft(2, '0');
      final month = months[parts[1].toLowerCase()] ?? parts[1];
      final year  = parts[2];
      return '$year-$month-$day';
    } catch (_) {
      return raw;
    }
  }

  void _proceedToSetPassword() => setState(() => _step = 2);

  // ── ID document picker ─────────────────────────────────────────────────────
  Future<void> _pickIdDocument() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Text('Upload ID Document',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _dark)),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('PDF, PNG, JPG or JPEG accepted',
                style: TextStyle(fontSize: 12, color: _muted)),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: _mint, borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.camera_alt_outlined, color: _g),
            ),
            title: const Text('Take a Photo'),
            subtitle:
            Text('PNG / JPG', style: TextStyle(fontSize: 12, color: _muted)),
            onTap: () async {
              Navigator.pop(context);
              final picked = await _imagePicker.pickImage(
                  source: ImageSource.camera, imageQuality: 90);
              if (picked != null) {
                setState(() {
                  _idDocument     = File(picked.path);
                  _idDocumentName = picked.name;
                  _idDocumentIsPdf = false;
                });
              }
            },
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: _mint, borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.photo_library_outlined, color: _g),
            ),
            title: const Text('Choose Image from Gallery'),
            subtitle: Text('PNG / JPG / JPEG',
                style: TextStyle(fontSize: 12, color: _muted)),
            onTap: () async {
              Navigator.pop(context);
              final picked = await _imagePicker.pickImage(
                  source: ImageSource.gallery, imageQuality: 90);
              if (picked != null) {
                setState(() {
                  _idDocument     = File(picked.path);
                  _idDocumentName = picked.name;
                  _idDocumentIsPdf = false;
                });
              }
            },
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: _mint, borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.picture_as_pdf_outlined, color: _g),
            ),
            title: const Text('Browse File'),
            subtitle: Text('PDF, PNG, JPG or JPEG',
                style: TextStyle(fontSize: 12, color: _muted)),
            onTap: () async {
              Navigator.pop(context);
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
                withData: false,
                withReadStream: false,
              );
              if (result != null && result.files.single.path != null) {
                final file = result.files.single;
                final ext  = (file.extension ?? '').toLowerCase();
                setState(() {
                  _idDocument     = File(file.path!);
                  _idDocumentName = file.name;
                  _idDocumentIsPdf = ext == 'pdf';
                });
              }
            },
          ),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }

  // ── Step 2: Submit ─────────────────────────────────────────────────────────
  Future<void> _submitRegistration() async {
    // ── Validation ────────────────────────────────────────────────────────────
    if (_firstNameCtrl.text.trim().isEmpty) {
      _snack('First name is required');
      return;
    }
    if (_surnameCtrl.text.trim().isEmpty) {
      _snack('Surname is required');
      return;
    }
    if (_dobCtrl.text.trim().isEmpty) {
      _snack('Date of birth is required');
      return;
    }
    if (_idCtrl.text.trim().isEmpty) {
      _snack('ID number is required');
      return;
    }
    if (_passCtrl.text.length < 8) {
      // ✅ FIXED: raised to 8 to match correct cURL / IndividualAccountScreen
      _snack('Password must be at least 8 characters');
      return;
    }
    if (!RegExp(r'[A-Z]').hasMatch(_passCtrl.text)) {
      _snack('Password must contain at least one uppercase letter');
      return;
    }
    if (!RegExp(r'[0-9]').hasMatch(_passCtrl.text)) {
      _snack('Password must contain at least one number');
      return;
    }
    if (_passCtrl.text != _confirmPassCtrl.text) {
      _snack('Passwords do not match');
      return;
    }

    setState(() => _submitting = true);

    try {
      // ✅ Normalise mobile — strip leading zero only, no prefix added
      String mobile = _kycMobileCtrl.text.trim();
      if (mobile.startsWith('0')) mobile = mobile.substring(1);

      // ── Base64-encode ID document ──────────────────────────────────────────
      String idDocumentBase64 = '';
      String idContentType    = '';
      if (_idDocument != null) {
        final Uint8List bytes = await _idDocument!.readAsBytes();
        idDocumentBase64 = base64Encode(bytes);
        final ext = (_idDocumentName ?? '').split('.').last.toLowerCase();
        // ✅ FIXED: send proper content type instead of raw extension
        switch (ext) {
          case 'pdf':
            idContentType = 'application/pdf';
            break;
          case 'png':
            idContentType = 'image/png';
            break;
          case 'jpg':
          case 'jpeg':
            idContentType = 'image/jpeg';
            break;
          default:
            idContentType = 'application/octet-stream';
        }
      }

      final payload = {
        // ── Auth ──────────────────────────────────────────────────────────────
        "APIUsername": apiUsername,
        "APIPassword": apiPassword,

        // ── Account basics ────────────────────────────────────────────────────
        "AccountType":          "Individual",
        "Title":                _title,
        "JointName":            "",
        "FirstName":            _firstNameCtrl.text.trim(),
        "Surname":              _surnameCtrl.text.trim(),
        "OtherNames":           _otherNamesCtrl.text.trim(),
        "DOB":                  _dobCtrl.text.trim(),
        "BirthPlace":           _birthPlaceCtrl.text.trim(),
        "Gender":               _gender,
        "Occupation":           _occupationCtrl.text.trim(),

        // ── Identity ──────────────────────────────────────────────────────────
        "Nationality":               _nationalityCtrl.text.trim(),
        "IdentificatinType":         _idType, // ← API typo kept intentionally
        "ID":                        _idCtrl.text.trim(),
        "IdentificationExpiryDate":  _idExpiryCtrl.text.trim(),
        "IssuingAuthority":          _issuingAuthority,

        // ── Address ───────────────────────────────────────────────────────────
        "City":            _cityCtrl.text.trim(),
        "PhysicalAddress": _kycAddrCtrl.text.trim(),
        "Country":         _countryCtrl.text.trim(),

        // ── Contact ───────────────────────────────────────────────────────────
        "Email":        _kycEmailCtrl.text.trim(),
        "MobileNumber": mobile,

        // ── Investment ────────────────────────────────────────────────────────
        "InvestmentPurpose":    _investmentPurpose,
        "IncomeSource":         _incomeSource,
        "InvestmentAccountType":"Standard",
        "InvestorType":         "Retail",         // ✅ FIXED: was "Individual"
        "ServiceRequired":      _serviceRequired, // ✅ FIXED: was hardcoded "Trading"
        "InvestmentPeriod":     _investmentPeriod,// ✅ FIXED: was "Long Term"
        "RiskTolerance":        _riskTolerance,   // ✅ FIXED: was "Medium"
        "Charge":               "0",

        // ── PEP ───────────────────────────────────────────────────────────────
        "Disclosure":  _disclosure,
        "PositionHeld": _disclosure == 'Yes'
            ? _pepDetailsCtrl.text.trim()
            : "", // ✅ FIXED: was "None"

        // ── Bank ──────────────────────────────────────────────────────────────
        "BankType":          _bankType,
        "BankAccountNumber": _kycAccNoCtrl.text.trim(),
        "BankAccountName":   _kycAccNameCtrl.text.trim(),
        "BankName":          _kycBankCtrl.text.trim(),
        "BankBranch":        _kycBranchCtrl.text.trim(),
        "BankSwiftCode":     _swiftCodeCtrl.text.trim(),
        "BankAddress":       _bankAddressCtrl.text.trim(),

        // ── Amount ────────────────────────────────────────────────────────────
        "AmountSuppliedIn": "TZS",

        // ✅ NEW: Required fields from correct cURL
        "Source":        "MobileApp",
        "myExistingCDS": _cdsCtrl.text.trim(),
        "Password":      _passCtrl.text,

        // ── ID document ───────────────────────────────────────────────────────
        "IDDocument": idDocumentBase64, // kept for backward compat
        "IDUpload":   idDocumentBase64, // ✅ NEW: correct field name
        "Content_Type": idContentType,  // ✅ FIXED: proper MIME type
      };

      debugPrint('Submitting existing client registration...');

      final res = await http.post(
        Uri.parse('$cSharpApi/CreateAccountEXISTSING'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      debugPrint('Response status: ${res.statusCode}');
      debugPrint('Response body: ${res.body}');

      setState(() => _submitting = false);

      if (res.statusCode == 200) {
        final d = jsonDecode(res.body);
        // ✅ Handle both status formats
        final isSuccess = d['status'] == 200 ||
            d['status']?.toString().toLowerCase() == 'success' ||
            (d['statusDesc'] ?? '').toString().toLowerCase() == 'success';

        if (isSuccess) {
          await _saveCredentials(
            _kycEmailCtrl.text.trim(),
            _kycMobileCtrl.text.trim(),
          );
          if (!mounted) return;
          _showSuccessDialog();
        } else {
          _snack(d['statusDesc'] ?? d['message'] ?? 'Registration failed. Please try again.');
        }
      } else {
        _snack('Server error (${res.statusCode}). Please try again.');
      }
    } catch (e) {
      debugPrint('Submit error: $e');
      setState(() => _submitting = false);
      _snack('An error occurred. Please check your connection.');
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
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration:
              BoxDecoration(color: widget.softMint, shape: BoxShape.circle),
              child:
              Icon(Icons.check_rounded, color: widget.primaryGreen, size: 44),
            ),
            const SizedBox(height: 20),
            Text('Account Setup Complete!',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: widget.textDark)),
            const SizedBox(height: 10),
            Text('Your online account is ready. You can now sign in.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, color: widget.textMuted, height: 1.5)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.login_rounded,
                    size: 18, color: Colors.white),
                label: const Text('Go to Login',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryGreen,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()));
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.info_outline, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg)),
      ]),
      behavior: SnackBarBehavior.floating,
      backgroundColor: widget.textDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _cdsCtrl.dispose();
    _kycNameCtrl.dispose();
    _kycEmailCtrl.dispose();
    _kycMobileCtrl.dispose();
    _kycAddrCtrl.dispose();
    _kycBankCtrl.dispose();
    _kycAccNoCtrl.dispose();
    _kycAccNameCtrl.dispose();
    _kycBranchCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _firstNameCtrl.dispose();
    _surnameCtrl.dispose();
    _otherNamesCtrl.dispose();
    _dobCtrl.dispose();
    _birthPlaceCtrl.dispose();
    _occupationCtrl.dispose();
    _nationalityCtrl.dispose();
    _idCtrl.dispose();
    _idExpiryCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    _swiftCodeCtrl.dispose();
    _bankAddressCtrl.dispose();
    _pepDetailsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(
          onTap: _step == 0
              ? widget.onBack
              : () => setState(() => _step -= 1),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF1A2332), size: 18),
          ),
        ),
        const SizedBox(height: 16),
        _StepIndicator(
            current: _step, total: 3, primaryGreen: _g, softMint: _mint),
        const SizedBox(height: 24),
        if (_step == 0) _buildStep0(),
        if (_step == 1) _buildStep1(),
        if (_step == 2) _buildStep2(),
      ]),
    );
  }

  // ── Step 0: Verify ─────────────────────────────────────────────────────────
  Widget _buildStep0() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Verify Your Account',
          style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: _dark,
              letterSpacing: -0.5)),
      const SizedBox(height: 6),
      Text('Enter your registered email and account number to continue.',
          style: TextStyle(fontSize: 14, color: _muted)),
      const SizedBox(height: 24),
      _card(children: [
        _sectionLabel('Identity'),
        _inputField(
            controller: _emailCtrl,
            label: 'Registered Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 14),
        _inputField(
            controller: _cdsCtrl,
            label: 'Account Number',
            icon: Icons.badge_outlined),
      ]),
      const SizedBox(height: 24),
      _primaryBtn(
        label: 'Verify & Continue',
        icon: Icons.verified_user_rounded,
        loading: _validating,
        onPressed: _validateClient,
      ),
    ]);
  }

  // ── Step 1: KYC ────────────────────────────────────────────────────────────
  Widget _buildStep1() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Confirm Your Profile',
          style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: _dark,
              letterSpacing: -0.5)),
      const SizedBox(height: 6),
      Text('Review and confirm your information pulled from our records.',
          style: TextStyle(fontSize: 14, color: _muted)),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration:
        BoxDecoration(color: _mint, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(Icons.waving_hand_rounded, color: _g, size: 18),
          const SizedBox(width: 8),
          Text(
              'Welcome back, ${(_clientData?['Forenames'] ?? _clientData?['Names'] ?? '').toString().split(' ').first}!',
              style: TextStyle(
                  color: _g, fontWeight: FontWeight.w600, fontSize: 14)),
        ]),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: _mint,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _g.withOpacity(0.3))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.auto_awesome_rounded, color: _g, size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(
                'Your details have been pre-filled from the FMS core system. '
                    'You may edit any field if needed.',
                style: TextStyle(fontSize: 13, color: _g, height: 1.4),
              )),
        ]),
      ),
      const SizedBox(height: 20),
      _card(children: [
        _sectionLabel('Personal Information'),
        _kycField(
            controller: _kycNameCtrl,
            label: 'Full Name',
            icon: Icons.person_outline_rounded),
        const SizedBox(height: 14),
        _kycField(
            controller: _kycEmailCtrl,
            label: 'Email Address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 14),
        _kycField(
            controller: _kycMobileCtrl,
            label: 'Mobile Number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone),
        const SizedBox(height: 14),
        _kycField(
            controller: _kycAddrCtrl,
            label: 'Address',
            icon: Icons.location_on_outlined),
      ]),
      const SizedBox(height: 16),
      _card(children: [
        _sectionLabel('Banking Details'),
        _kycField(
            controller: _kycBankCtrl,
            label: 'Bank Name',
            icon: Icons.account_balance_outlined),
        const SizedBox(height: 14),
        _kycField(
            controller: _kycAccNoCtrl,
            label: 'Account Number',
            icon: Icons.credit_card_outlined,
            keyboardType: TextInputType.number),
        const SizedBox(height: 14),
        _kycField(
            controller: _kycAccNameCtrl,
            label: 'Account Name',
            icon: Icons.badge_outlined),
        const SizedBox(height: 14),
        _kycField(
            controller: _kycBranchCtrl,
            label: 'Branch',
            icon: Icons.store_outlined),
      ]),
      const SizedBox(height: 24),
      _primaryBtn(
        label: 'Confirm & Continue',
        icon: Icons.arrow_forward_rounded,
        loading: false,
        onPressed: _proceedToSetPassword,
      ),
      const SizedBox(height: 16),
    ]);
  }

  // ── Step 2: Complete Setup ─────────────────────────────────────────────────
  Widget _buildStep2() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Complete Setup',
          style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: _dark,
              letterSpacing: -0.5)),
      const SizedBox(height: 6),
      Text('Fill in the remaining details and set your password.',
          style: TextStyle(fontSize: 14, color: _muted)),
      const SizedBox(height: 20),

      // Email chip
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
            color: _mint,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _g.withOpacity(0.3))),
        child: Row(children: [
          Icon(Icons.email_outlined, color: _g, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Setting up account for',
                      style: TextStyle(fontSize: 12, color: _muted)),
                  const SizedBox(height: 2),
                  Text(_kycEmailCtrl.text.trim(),
                      style: TextStyle(
                          fontSize: 14,
                          color: _dark,
                          fontWeight: FontWeight.w600)),
                ]),
          ),
        ]),
      ),
      const SizedBox(height: 20),

      // ── Personal Details ───────────────────────────────────────────────────
      _card(children: [
        _sectionLabel('Personal Details'),
        _dropdownField(
          label: 'Title',
          icon: Icons.person_outline_rounded,
          value: _title,
          items: ['Mr', 'Mrs', 'Ms', 'Dr', 'Prof'],
          onChanged: (v) => setState(() => _title = v!),
        ),
        const SizedBox(height: 14),
        _inputField(
            controller: _firstNameCtrl,
            label: 'First Name',
            icon: Icons.badge_outlined),
        const SizedBox(height: 14),
        _inputField(
            controller: _surnameCtrl,
            label: 'Surname',
            icon: Icons.badge_outlined),
        const SizedBox(height: 14),
        _inputField(
            controller: _otherNamesCtrl,
            label: 'Other Names (optional)',
            icon: Icons.badge_outlined),
        const SizedBox(height: 14),
        _dropdownField(
          label: 'Gender',
          icon: Icons.wc_rounded,
          value: _gender,
          items: ['Male', 'Female'],
          onChanged: (v) => setState(() => _gender = v!),
        ),
        const SizedBox(height: 14),
        _datePicker(
          controller: _dobCtrl,
          label: 'Date of Birth',
          icon: Icons.cake_outlined,
          firstDate: DateTime(1940),
          lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
        ),
        const SizedBox(height: 14),
        _inputField(
            controller: _birthPlaceCtrl,
            label: 'Birth Place',
            icon: Icons.place_outlined),
        const SizedBox(height: 14),
        _inputField(
            controller: _nationalityCtrl,
            label: 'Nationality',
            icon: Icons.flag_outlined),
        const SizedBox(height: 14),
        _inputField(
            controller: _occupationCtrl,
            label: 'Occupation',
            icon: Icons.work_outline_rounded),
        const SizedBox(height: 14),
        _inputField(
            controller: _cityCtrl,
            label: 'City',
            icon: Icons.location_city_outlined),
        const SizedBox(height: 14),
        _inputField(
            controller: _countryCtrl,
            label: 'Country',
            icon: Icons.public_outlined),
      ]),
      const SizedBox(height: 16),

      // ── Identification ─────────────────────────────────────────────────────
      _card(children: [
        _sectionLabel('Identification'),
        _dropdownField(
          label: 'ID Type',
          icon: Icons.credit_card_outlined,
          value: _idType,
          items: _idTypes,
          onChanged: (v) => setState(() => _idType = v!),
        ),
        const SizedBox(height: 14),
        _inputField(
            controller: _idCtrl,
            label: 'ID Number',
            icon: Icons.numbers_outlined),
        const SizedBox(height: 14),
        _datePicker(
          controller: _idExpiryCtrl,
          label: 'ID Expiry Date',
          icon: Icons.event_outlined,
          firstDate: DateTime.now(),
          lastDate: DateTime(2060),
        ),
        const SizedBox(height: 14),
        _dropdownField(
          label: 'Issuing Authority',
          icon: Icons.account_balance_outlined,
          value: _issuingAuthority,
          items: _issuingAuthorities,
          onChanged: (v) => setState(() => _issuingAuthority = v!),
        ),
        const SizedBox(height: 16),

        // ID Document Upload
        _sectionLabel('Upload ID Document'),
        GestureDetector(
          onTap: _pickIdDocument,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 100),
            decoration: BoxDecoration(
              color: _idDocument != null ? _mint : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: _idDocument != null
                      ? _g
                      : Colors.grey.withOpacity(0.3),
                  width: _idDocument != null ? 1.5 : 1),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: _idDocument != null
                ? Stack(children: [
              if (_idDocumentIsPdf)
                Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                      color: const Color(0xFFFFF3F3),
                      borderRadius: BorderRadius.circular(13)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.picture_as_pdf_rounded,
                          color: const Color(0xFFE53935), size: 52),
                      const SizedBox(height: 8),
                      Padding(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          _idDocumentName ?? 'document.pdf',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 13,
                              color: _dark,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Image.file(_idDocument!,
                      width: double.infinity,
                      height: 160,
                      fit: BoxFit.cover),
                ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => setState(() {
                    _idDocument     = null;
                    _idDocumentName = null;
                    _idDocumentIsPdf = false;
                  }),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.close,
                        color: Colors.white, size: 16),
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: _g,
                      borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: Colors.white, size: 13),
                      const SizedBox(width: 5),
                      Text(
                        _idDocumentIsPdf
                            ? 'PDF Uploaded'
                            : 'ID Uploaded',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ])
                : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: _mint, shape: BoxShape.circle),
                    child: Icon(Icons.upload_file_outlined,
                        color: _g, size: 28),
                  ),
                  const SizedBox(height: 10),
                  Text('Tap to upload your ID document',
                      style: TextStyle(
                          fontSize: 14,
                          color: _dark,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('PDF, PNG, JPG or JPEG accepted',
                      style: TextStyle(fontSize: 12, color: _muted)),
                ],
              ),
            ),
          ),
        ),
      ]),
      const SizedBox(height: 16),

      // ── Banking Details ────────────────────────────────────────────────────
      _card(children: [
        _sectionLabel('Banking Details'),
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
              color: _mint,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _g.withOpacity(0.3))),
          child: Row(children: [
            Icon(Icons.auto_awesome_rounded, color: _g, size: 15),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                  'Pre-filled from your KYC profile. Edit if needed.',
                  style: TextStyle(fontSize: 12, color: _g, height: 1.4)),
            ),
          ]),
        ),
        _fieldContainer(TextField(
          controller: _kycBankCtrl,
          style: TextStyle(fontSize: 15, color: _dark),
          onChanged: (val) {
            final swift = _lookupSwift(val);
            if (swift != null) {
              setState(() => _swiftCodeCtrl.text = swift);
            }
          },
          decoration: InputDecoration(
              labelText: 'Bank Name',
              labelStyle: TextStyle(color: _muted, fontSize: 14),
              prefixIcon:
              Icon(Icons.account_balance_outlined, color: _g, size: 20),
              suffixIcon:
              Icon(Icons.edit_outlined, color: _muted, size: 16),
              border: InputBorder.none,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
              floatingLabelBehavior: FloatingLabelBehavior.auto),
        )),
        const SizedBox(height: 14),
        _kycField(
            controller: _kycAccNoCtrl,
            label: 'Account Number',
            icon: Icons.credit_card_outlined,
            keyboardType: TextInputType.number),
        const SizedBox(height: 14),
        _kycField(
            controller: _kycAccNameCtrl,
            label: 'Account Name',
            icon: Icons.badge_outlined),
        const SizedBox(height: 14),
        _kycField(
            controller: _kycBranchCtrl,
            label: 'Branch',
            icon: Icons.store_outlined),
        const SizedBox(height: 14),
        _dropdownField(
          label: 'Bank Type',
          icon: Icons.account_balance_outlined,
          value: _bankType,
          items: ['Local', 'Foreign'],
          onChanged: (v) => setState(() => _bankType = v!),
        ),
        const SizedBox(height: 14),
        _fieldContainer(TextField(
          controller: _swiftCodeCtrl,
          style: TextStyle(fontSize: 15, color: _dark),
          decoration: InputDecoration(
              labelText: 'SWIFT Code',
              labelStyle: TextStyle(color: _muted, fontSize: 14),
              prefixIcon: Icon(Icons.code_outlined, color: _g, size: 20),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(Icons.auto_awesome_rounded,
                    color: _g.withOpacity(0.6), size: 16),
              ),
              suffixIconConstraints: const BoxConstraints(minWidth: 0),
              border: InputBorder.none,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
              floatingLabelBehavior: FloatingLabelBehavior.auto),
        )),
        const SizedBox(height: 14),
        _inputField(
            controller: _bankAddressCtrl,
            label: 'Bank Address',
            icon: Icons.location_on_outlined),
      ]),
      const SizedBox(height: 16),

      // ── Investment Preferences ─────────────────────────────────────────────
      _card(children: [
        _sectionLabel('Investment Preferences'),
        _dropdownField(
          label: 'Investment Purpose',
          icon: Icons.trending_up_rounded,
          value: _investmentPurpose,
          items: [
            'Wealth Creation',
            'Retirement',
            'Education',
            'Income',
            'Speculation',
          ],
          onChanged: (v) => setState(() => _investmentPurpose = v!),
        ),
        const SizedBox(height: 14),
        _dropdownField(
          label: 'Income Source',
          icon: Icons.attach_money_rounded,
          value: _incomeSource,
          items: ['Salary', 'Business', 'Investments', 'Inheritance', 'Other'],
          onChanged: (v) => setState(() => _incomeSource = v!),
        ),
        const SizedBox(height: 14),

        // ✅ NEW: Service Required picker
        _dropdownField(
          label: 'Service Required',
          icon: Icons.miscellaneous_services_rounded,
          value: _serviceRequired,
          items: ['Unit Trust Investment', 'Trading', 'Both'],
          onChanged: (v) => setState(() => _serviceRequired = v!),
        ),
        const SizedBox(height: 14),

        // ✅ NEW: Investment Period picker (correct values)
        _dropdownField(
          label: 'Investment Period',
          icon: Icons.timelapse_rounded,
          value: _investmentPeriod,
          items: ['3 Months', '6 Months', '12 Months', '24 Months', '36 Months', 'Long Term'],
          onChanged: (v) => setState(() => _investmentPeriod = v!),
        ),
        const SizedBox(height: 14),

        // ✅ NEW: Risk Tolerance picker (correct values)
        _dropdownField(
          label: 'Risk Tolerance',
          icon: Icons.speed_rounded,
          value: _riskTolerance,
          items: ['Low', 'Moderate', 'High'],
          onChanged: (v) => setState(() => _riskTolerance = v!),
        ),
        const SizedBox(height: 14),

        // PEP Disclosure
        _dropdownField(
          label: 'PEP Disclosure',
          icon: Icons.policy_outlined,
          value: _disclosure,
          items: ['No', 'Yes'],
          onChanged: (v) => setState(() => _disclosure = v!),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: _disclosure == 'Yes'
              ? Column(children: [
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color:
                      const Color(0xFFFFB300).withOpacity(0.4))),
              child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFFFB300), size: 16),
                    SizedBox(width: 8),
                    Expanded(
                        child: Text(
                          'As a Politically Exposed Person, please provide '
                              'details of your position and related information.',
                          style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7A5F00),
                              height: 1.4),
                        )),
                  ]),
            ),
            const SizedBox(height: 12),
            _fieldContainer(TextField(
              controller: _pepDetailsCtrl,
              maxLines: 3,
              style: TextStyle(fontSize: 15, color: _dark),
              decoration: InputDecoration(
                  labelText: 'PEP Details / Position Held',
                  alignLabelWithHint: true,
                  labelStyle: TextStyle(color: _muted, fontSize: 14),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.info_outline_rounded,
                        color: _g, size: 20),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 16),
                  floatingLabelBehavior:
                  FloatingLabelBehavior.auto),
            )),
          ])
              : const SizedBox.shrink(),
        ),
      ]),
      const SizedBox(height: 16),

      // ── Password ───────────────────────────────────────────────────────────
      _card(children: [
        _sectionLabel('Set Password'),
        _passField(
          controller: _passCtrl,
          label: 'New Password',
          isVisible: _passVisible,
          onToggle: () => setState(() => _passVisible = !_passVisible),
        ),
        const SizedBox(height: 14),
        _passField(
          controller: _confirmPassCtrl,
          label: 'Confirm Password',
          isVisible: _confirmVisible,
          onToggle: () => setState(() => _confirmVisible = !_confirmVisible),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.info_outline_rounded, size: 13, color: _muted),
                const SizedBox(width: 5),
                Text('Minimum 8 characters', // ✅ FIXED: was 6
                    style: TextStyle(fontSize: 12, color: _muted)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.info_outline_rounded, size: 13, color: _muted),
                const SizedBox(width: 5),
                Text('At least 1 uppercase letter and 1 number',
                    style: TextStyle(fontSize: 12, color: _muted)),
              ]),
            ],
          ),
        ),
      ]),
      const SizedBox(height: 24),
      _primaryBtn(
        label: 'Complete Setup',
        icon: Icons.check_circle_rounded,
        loading: _submitting,
        onPressed: _submitRegistration,
      ),
      const SizedBox(height: 24),
    ]);
  }

  // ── Shared widgets ─────────────────────────────────────────────────────────
  Widget _card({required List<Widget> children}) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border:
        Border.all(color: Colors.white.withOpacity(0.8), width: 1)),
    child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children),
  );

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
              color: _g, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(label,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _dark,
              letterSpacing: 0.3)),
    ]),
  );

  Widget _fieldContainer(Widget child) => Container(
    decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ]),
    child: child,
  );

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) =>
      _fieldContainer(TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 15, color: _dark),
        decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: _muted, fontSize: 14),
            prefixIcon: Icon(icon, color: _g, size: 20),
            border: InputBorder.none,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
            floatingLabelBehavior: FloatingLabelBehavior.auto),
      ));

  Widget _kycField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) =>
      _fieldContainer(TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 15, color: _dark),
        decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: _muted, fontSize: 14),
            prefixIcon: Icon(icon, color: _g, size: 20),
            suffixIcon: Icon(Icons.edit_outlined, color: _muted, size: 16),
            border: InputBorder.none,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
            floatingLabelBehavior: FloatingLabelBehavior.auto),
      ));

  Widget _passField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onToggle,
  }) =>
      _fieldContainer(TextField(
        controller: controller,
        obscureText: !isVisible,
        style: TextStyle(fontSize: 15, color: _dark),
        decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: _muted, fontSize: 14),
            prefixIcon:
            Icon(Icons.lock_outline_rounded, color: _g, size: 20),
            suffixIcon: GestureDetector(
                onTap: onToggle,
                child: Icon(
                    isVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: _muted,
                    size: 20)),
            border: InputBorder.none,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
            floatingLabelBehavior: FloatingLabelBehavior.auto),
      ));

  Widget _dropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) =>
      _fieldContainer(DropdownButtonFormField<String>(
        value: value,
        onChanged: onChanged,
        decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: _muted, fontSize: 14),
            prefixIcon: Icon(icon, color: _g, size: 20),
            border: InputBorder.none,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            floatingLabelBehavior: FloatingLabelBehavior.auto),
        style: TextStyle(fontSize: 15, color: _dark),
        dropdownColor: Colors.white,
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
      ));

  Widget _datePicker({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required DateTime firstDate,
    required DateTime lastDate,
  }) =>
      _fieldContainer(TextField(
        controller: controller,
        readOnly: true,
        style: TextStyle(fontSize: 15, color: _dark),
        decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: _muted, fontSize: 14),
            prefixIcon: Icon(icon, color: _g, size: 20),
            suffixIcon: Icon(Icons.calendar_today_outlined,
                color: _muted, size: 18),
            border: InputBorder.none,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
            floatingLabelBehavior: FloatingLabelBehavior.auto),
        onTap: () async {
          DateTime initial;
          if (controller.text.isNotEmpty) {
            initial = DateTime.tryParse(controller.text) ?? lastDate;
          } else {
            initial = lastDate;
          }
          if (initial.isBefore(firstDate)) initial = firstDate;
          if (initial.isAfter(lastDate)) initial = lastDate;

          final picked = await showDatePicker(
            context: context,
            initialDate: initial,
            firstDate: firstDate,
            lastDate: lastDate,
            builder: (ctx, child) => Theme(
              data: Theme.of(ctx).copyWith(
                colorScheme: ColorScheme.light(
                    primary: _g,
                    onPrimary: Colors.white,
                    surface: Colors.white),
              ),
              child: child!,
            ),
          );
          if (picked != null) {
            controller.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
          }
        },
      ));

  Widget _primaryBtn({
    required String label,
    required IconData icon,
    required bool loading,
    required VoidCallback onPressed,
  }) =>
      SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
              backgroundColor: _g,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              disabledBackgroundColor: _g.withOpacity(0.5)),
          child: loading
              ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2.5))
              : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Icon(icon, size: 18),
              ]),
        ),
      );
}

// ─── Step Indicator ────────────────────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  final int current, total;
  final Color primaryGreen, softMint;
  const _StepIndicator({
    required this.current,
    required this.total,
    required this.primaryGreen,
    required this.softMint,
  });

  @override
  Widget build(BuildContext context) {
    final labels = total == 3
        ? ['Verify', 'KYC Info', 'Setup']
        : ['Verify', 'KYC Info'];

    return Row(
      children: List.generate(total, (i) {
        final done   = i < current;
        final active = i == current;
        return Expanded(
          child: Row(children: [
            Expanded(
              child: Column(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 4,
                  decoration: BoxDecoration(
                      color: done || active
                          ? primaryGreen
                          : Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 6),
                Text(labels[i],
                    style: TextStyle(
                        fontSize: 11,
                        color: active
                            ? primaryGreen
                            : done
                            ? primaryGreen.withOpacity(0.7)
                            : Colors.grey[400],
                        fontWeight: active
                            ? FontWeight.w700
                            : FontWeight.normal)),
              ]),
            ),
            if (i < total - 1) const SizedBox(width: 6),
          ]),
        );
      }),
    );
  }
}