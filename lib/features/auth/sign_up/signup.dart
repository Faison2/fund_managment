import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsl/constants/constants.dart';
import 'dart:convert';
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

  static const Color _primaryGreen = Color(0xFF2DC98E);
  static const Color _deepGreen = Color(0xFF1A9B6C);
  static const Color _softMint = Color(0xFFE8FBF4);
  static const Color _textDark = Color(0xFF1A2332);
  static const Color _textMuted = Color(0xFF8A9BB0);

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
            colors: [Color(0xFF7FFFD4), Color(0xFF98FB98), Color(0xFFAFEEEE)],
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
  static const Color _primaryGreen = Color(0xFF2DC98E);
  static const Color _softMint = Color(0xFFE8FBF4);
  static const Color _textDark = Color(0xFF1A2332);
  static const Color _textMuted = Color(0xFF8A9BB0);

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
            subtitle: 'Already have a CDS number? Set up online access',
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
  static const Color _primaryGreen = Color(0xFF2DC98E);
  static const Color _softMint = Color(0xFFE8FBF4);
  static const Color _textDark = Color(0xFF1A2332);
  static const Color _textMuted = Color(0xFF8A9BB0);

  const _PickCard(
      {required this.icon,
        required this.title,
        required this.subtitle,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          border:
          Border.all(color: Colors.white.withOpacity(0.9), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: _softMint,
                  borderRadius: BorderRadius.circular(14)),
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
          ],
        ),
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
  const _NewClientFlow(
      {required this.primaryGreen,
        required this.softMint,
        required this.textDark,
        required this.textMuted,
        required this.onBack});

  @override
  State<_NewClientFlow> createState() => _NewClientFlowState();
}

class _NewClientFlowState extends State<_NewClientFlow> {
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _passVisible = false, _confirmVisible = false;
  bool _agreeToTerms = false, _isLoading = false;

  Color get _g => widget.primaryGreen;
  Color get _mint => widget.softMint;
  Color get _dark => widget.textDark;
  Color get _muted => widget.textMuted;

  // ── Save credentials to SharedPreferences ──────────────────────────────────
  Future<void> _saveCredentials(String email, String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_email', email);
    await prefs.setString('saved_phone', phone);
  }

  Future<void> _register() async {
    if (!_validate()) return;
    if (!_agreeToTerms) { _snack('Please agree to the Terms & Conditions'); return; }
    setState(() => _isLoading = true);
    try {
      String phone = _phoneCtrl.text.trim();
      if (phone.startsWith('0')) phone = phone.substring(1);
      final res = await http.post(
        Uri.parse('$cSharpApi/UserSignUp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "APIUsername": "User2",
          "APIPassword": "CBZ1234#2",
          "Email": _emailCtrl.text.trim(),
          "PhoneNumber": phone,
          "Password": _passCtrl.text,
          "Source": "Mobile",
        }),
      );
      setState(() => _isLoading = false);
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body);
        if (d['status'] == 'success') {
          // ── Save to SharedPreferences on success ──
          await _saveCredentials(_emailCtrl.text.trim(), _phoneCtrl.text.trim());
          _showSuccessDialog();
        } else {
          _snack(d['statusDesc'] ?? 'Registration failed');
        }
      } else {
        _snack('Network error. Please try again.');
      }
    } catch (_) {
      setState(() => _isLoading = false);
      _snack('An error occurred. Please check your connection.');
    }
  }

  bool _validate() {
    if (_emailCtrl.text.isEmpty || !_emailCtrl.text.contains('@')) {
      _snack('Please enter a valid email'); return false;
    }
    if (_phoneCtrl.text.isEmpty) { _snack('Please enter your phone number'); return false; }
    if (_passCtrl.text.length < 6) { _snack('Password must be at least 6 characters'); return false; }
    if (_passCtrl.text != _confirmPassCtrl.text) { _snack('Passwords do not match'); return false; }
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
              decoration: BoxDecoration(color: widget.softMint, shape: BoxShape.circle),
              child: Icon(Icons.check_rounded, color: widget.primaryGreen, size: 44),
            ),
            const SizedBox(height: 20),
            Text('Account Created!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: widget.textDark)),
            const SizedBox(height: 10),
            Text('Your account has been created successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: widget.textMuted, height: 1.5)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.person_add_rounded, size: 18, color: Colors.white),
                label: const Text('Create Individual Account',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryGreen,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const IndividualAccountScreen()));
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: Icon(Icons.login_rounded, size: 18, color: widget.primaryGreen),
                label: Text('Go to Login',
                    style: TextStyle(color: widget.primaryGreen, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                    side: BorderSide(color: widget.primaryGreen, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
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
    _emailCtrl.dispose(); _phoneCtrl.dispose();
    _passCtrl.dispose(); _confirmPassCtrl.dispose();
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
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A2332), size: 18),
          ),
        ),
        const SizedBox(height: 10),
        const Text('New Client',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold,
                color: Color(0xFF1A2332), letterSpacing: -0.5)),
        const SizedBox(height: 6),
        Text('Fill in your details to get started',
            style: TextStyle(fontSize: 15, color: _muted)),
        const SizedBox(height: 28),
        _card(children: [
          _sectionLabel('Account Info'),
          _inputField(controller: _emailCtrl, label: 'Email Address',
              icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 14),
          _inputField(controller: _phoneCtrl, label: 'Phone Number',
              icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
          const SizedBox(height: 22),
          _sectionLabel('Security'),
          _passField(controller: _passCtrl, label: 'Password',
              isVisible: _passVisible, onToggle: () => setState(() => _passVisible = !_passVisible)),
          const SizedBox(height: 14),
          _passField(controller: _confirmPassCtrl, label: 'Confirm Password',
              isVisible: _confirmVisible,
              onToggle: () => setState(() => _confirmVisible = !_confirmVisible)),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 6),
            child: Row(children: [
              Icon(Icons.info_outline_rounded, size: 13, color: _muted),
              const SizedBox(width: 5),
              Text('Minimum 6 characters', style: TextStyle(fontSize: 12, color: _muted)),
            ]),
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
                width: 22, height: 22,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _agreeToTerms ? _g : Colors.transparent,
                    border: Border.all(
                        color: _agreeToTerms ? _g : Colors.grey[400]!, width: 2)),
                child: _agreeToTerms
                    ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text.rich(TextSpan(
                  style: TextStyle(fontSize: 14, color: _muted),
                  children: [
                    const TextSpan(text: 'I agree to the '),
                    TextSpan(text: 'Terms & Conditions',
                        style: TextStyle(color: _g, fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline, fontSize: 14)),
                  ],
                )),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity, height: 54,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _register,
            style: ElevatedButton.styleFrom(
                backgroundColor: _g, foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                disabledBackgroundColor: _g.withOpacity(0.5)),
            child: _isLoading
                ? const SizedBox(height: 22, width: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, size: 18),
            ]),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: () => Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const LoginScreen())),
            child: Text.rich(TextSpan(
              style: TextStyle(fontSize: 14, color: _muted),
              children: [
                const TextSpan(text: 'Already have an account? '),
                TextSpan(text: 'Sign In',
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
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      Container(width: 3, height: 14,
          decoration: BoxDecoration(color: _g, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
          color: Color(0xFF1A2332), letterSpacing: 0.3)),
    ]),
  );

  Widget _inputField({required TextEditingController controller,
    required String label, required IconData icon, TextInputType? keyboardType}) =>
      Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
        child: TextField(
          controller: controller, keyboardType: keyboardType,
          style: const TextStyle(fontSize: 15, color: Color(0xFF1A2332)),
          decoration: InputDecoration(
              labelText: label, labelStyle: TextStyle(color: _muted, fontSize: 14),
              prefixIcon: Icon(icon, color: _g, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
              floatingLabelBehavior: FloatingLabelBehavior.auto),
        ),
      );

  Widget _passField({required TextEditingController controller, required String label,
    required bool isVisible, required VoidCallback onToggle}) =>
      Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
        child: TextField(
          controller: controller, obscureText: !isVisible,
          style: const TextStyle(fontSize: 15, color: Color(0xFF1A2332)),
          decoration: InputDecoration(
              labelText: label, labelStyle: TextStyle(color: _muted, fontSize: 14),
              prefixIcon: Icon(Icons.lock_outline_rounded, color: _g, size: 20),
              suffixIcon: GestureDetector(
                  onTap: onToggle,
                  child: Icon(isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: _muted, size: 20)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
              floatingLabelBehavior: FloatingLabelBehavior.auto),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// EXISTING CLIENT FLOW  (3 steps: validate → KYC → set password)
// ─────────────────────────────────────────────────────────────────────────────
class _ExistingClientFlow extends StatefulWidget {
  final Color primaryGreen, softMint, textDark, textMuted;
  final VoidCallback onBack;
  const _ExistingClientFlow(
      {required this.primaryGreen,
        required this.softMint,
        required this.textDark,
        required this.textMuted,
        required this.onBack});

  @override
  State<_ExistingClientFlow> createState() => _ExistingClientFlowState();
}

class _ExistingClientFlowState extends State<_ExistingClientFlow> {
  // Step 0 = verify, 1 = KYC review, 2 = set password
  int _step = 0;

  // Step 0
  final _emailCtrl = TextEditingController();
  final _cdsCtrl = TextEditingController();
  bool _validating = false;

  // Fetched client data
  Map<String, dynamic>? _clientData;

  // KYC controllers (auto-filled)
  final _kycNameCtrl = TextEditingController();
  final _kycEmailCtrl = TextEditingController();
  final _kycMobileCtrl = TextEditingController();
  final _kycAddrCtrl = TextEditingController();
  final _kycBankCtrl = TextEditingController();
  final _kycAccNoCtrl = TextEditingController();
  final _kycAccNameCtrl = TextEditingController();
  final _kycBranchCtrl = TextEditingController();

  // Step 2: Set password
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _passVisible = false, _confirmVisible = false;
  bool _submitting = false;

  Color get _g => widget.primaryGreen;
  Color get _mint => widget.softMint;
  Color get _dark => widget.textDark;
  Color get _muted => widget.textMuted;

  // ── Save credentials to SharedPreferences ──────────────────────────────────
  Future<void> _saveCredentials(String email, String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_email', email);
    await prefs.setString('saved_phone', phone);
  }

  // ── Step 0: Validate via API ───────────────────────────────────────────────
  Future<void> _validateClient() async {
    final email = _emailCtrl.text.trim();
    final cds = _cdsCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) { _snack('Enter a valid email'); return; }
    if (cds.isEmpty) { _snack('Enter your CDS/Account number'); return; }

    setState(() => _validating = true);
    try {
      final res = await http.post(
        Uri.parse('https://portaluat.tsl.co.tz/FMSAPI/Home/UserBasicDetails'),
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
          _kycNameCtrl.text = data['Names'] ?? '';
          _kycEmailCtrl.text = data['Email'] ?? '';
          _kycMobileCtrl.text = data['Mobile'] ?? '';
          _kycAddrCtrl.text = data['Add_1'] ?? '';
          _kycBankCtrl.text = data['Bank'] ?? '';
          _kycAccNoCtrl.text = data['AccountNo'] ?? '';
          _kycAccNameCtrl.text = data['AccountName'] ?? '';
          _kycBranchCtrl.text = data['Branch'] ?? '';
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

  // ── Step 1 → Step 2: KYC confirmed, move to set password ──────────────────
  void _proceedToSetPassword() {
    setState(() => _step = 2);
  }

  // ── Step 2: Validate password and complete registration ────────────────────
  Future<void> _submitRegistration() async {
    if (_passCtrl.text.length < 6) {
      _snack('Password must be at least 6 characters');
      return;
    }
    if (_passCtrl.text != _confirmPassCtrl.text) {
      _snack('Passwords do not match');
      return;
    }

    setState(() => _submitting = true);

    try {
      // ── Call your registration API here ──────────────────────────────────
      // Example payload — adjust fields to match your actual API:
      // final res = await http.post(
      //   Uri.parse('$cSharpApi/ExistingClientSignUp'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode({
      //     "CDSNumber": _cdsCtrl.text.trim(),
      //     "Email": _kycEmailCtrl.text.trim(),
      //     "Password": _passCtrl.text,
      //     "Source": "Mobile",
      //   }),
      // );

      // ── Save email + phone to SharedPreferences ───────────────────────────
      await _saveCredentials(
        _kycEmailCtrl.text.trim(),
        _kycMobileCtrl.text.trim(),
      );

      setState(() => _submitting = false);

      if (!mounted) return;
      _snack('Account setup complete! Redirecting to login…');
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    } catch (e) {
      setState(() => _submitting = false);
      _snack('An error occurred. Please try again.');
    }
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
    _emailCtrl.dispose(); _cdsCtrl.dispose();
    _kycNameCtrl.dispose(); _kycEmailCtrl.dispose(); _kycMobileCtrl.dispose();
    _kycAddrCtrl.dispose(); _kycBankCtrl.dispose(); _kycAccNoCtrl.dispose();
    _kycAccNameCtrl.dispose(); _kycBranchCtrl.dispose();
    _passCtrl.dispose(); _confirmPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(
          onTap: _step == 0 ? widget.onBack : () => setState(() => _step -= 1),
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
        // ── Now 3 steps ──
        _StepIndicator(current: _step, total: 3, primaryGreen: _g, softMint: _mint),
        const SizedBox(height: 24),
        if (_step == 0) _buildStep0(),
        if (_step == 1) _buildStep1(),
        if (_step == 2) _buildStep2(),
      ]),
    );
  }

  // ── Step 0: Verify ────────────────────────────────────────────────────────
  Widget _buildStep0() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Verify Your Account',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold,
              color: _dark, letterSpacing: -0.5)),
      const SizedBox(height: 6),
      Text('Enter your registered email and CDS number to continue.',
          style: TextStyle(fontSize: 14, color: _muted)),
      const SizedBox(height: 24),
      _card(children: [
        _sectionLabel('Identity'),
        _inputField(controller: _emailCtrl, label: 'Registered Email',
            icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 14),
        _inputField(controller: _cdsCtrl, label: 'CDS / Account Number',
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

  // ── Step 1: KYC ───────────────────────────────────────────────────────────
  Widget _buildStep1() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Complete Your Profile',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold,
              color: _dark, letterSpacing: -0.5)),
      const SizedBox(height: 6),
      Text('Review and confirm your information pulled from our records.',
          style: TextStyle(fontSize: 14, color: _muted)),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: _mint, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(Icons.waving_hand_rounded, color: _g, size: 18),
          const SizedBox(width: 8),
          Text('Welcome back, ${(_clientData?['Names'] ?? '').toString().split(' ').first}!',
              style: TextStyle(color: _g, fontWeight: FontWeight.w600, fontSize: 14)),
        ]),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: _mint, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _g.withOpacity(0.3))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.auto_awesome_rounded, color: _g, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(
            'Your details have been pre-filled from the FMS core system. '
                'You may edit any field if needed.',
            style: TextStyle(fontSize: 13, color: _g, height: 1.4),
          )),
        ]),
      ),
      const SizedBox(height: 20),
      _card(children: [
        _sectionLabel('Personal Information'),
        _kycField(controller: _kycNameCtrl, label: 'Full Name', icon: Icons.person_outline_rounded),
        const SizedBox(height: 14),
        _kycField(controller: _kycEmailCtrl, label: 'Email Address',
            icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 14),
        _kycField(controller: _kycMobileCtrl, label: 'Mobile Number',
            icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
        const SizedBox(height: 14),
        _kycField(controller: _kycAddrCtrl, label: 'Address',
            icon: Icons.location_on_outlined),
      ]),
      const SizedBox(height: 16),
      _card(children: [
        _sectionLabel('Banking Details'),
        _kycField(controller: _kycBankCtrl, label: 'Bank Name', icon: Icons.account_balance_outlined),
        const SizedBox(height: 14),
        _kycField(controller: _kycAccNoCtrl, label: 'Account Number',
            icon: Icons.credit_card_outlined, keyboardType: TextInputType.number),
        const SizedBox(height: 14),
        _kycField(controller: _kycAccNameCtrl, label: 'Account Name',
            icon: Icons.badge_outlined),
        const SizedBox(height: 14),
        _kycField(controller: _kycBranchCtrl, label: 'Branch', icon: Icons.store_outlined),
      ]),
      const SizedBox(height: 24),
      _primaryBtn(
        label: 'Confirm & Set Password',
        icon: Icons.arrow_forward_rounded,
        loading: false,
        onPressed: _proceedToSetPassword,
      ),
      const SizedBox(height: 16),
    ]);
  }

  // ── Step 2: Set Password ──────────────────────────────────────────────────
  Widget _buildStep2() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Set Your Password',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold,
              color: _dark, letterSpacing: -0.5)),
      const SizedBox(height: 6),
      Text('Choose a strong password to secure your account.',
          style: TextStyle(fontSize: 14, color: _muted)),
      const SizedBox(height: 24),

      // ── Confirmed email chip ─────────────────────────────────────────────
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: _mint, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _g.withOpacity(0.3))),
        child: Row(children: [
          Icon(Icons.email_outlined, color: _g, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Setting password for', style: TextStyle(fontSize: 12, color: _muted)),
              const SizedBox(height: 2),
              Text(_kycEmailCtrl.text.trim(),
                  style: TextStyle(fontSize: 14, color: _dark, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 20),

      _card(children: [
        _sectionLabel('Security'),
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
          child: Row(children: [
            Icon(Icons.info_outline_rounded, size: 13, color: _muted),
            const SizedBox(width: 5),
            Text('Minimum 6 characters', style: TextStyle(fontSize: 12, color: _muted)),
          ]),
        ),
      ]),
      const SizedBox(height: 24),
      _primaryBtn(
        label: 'Complete Setup',
        icon: Icons.check_circle_rounded,
        loading: _submitting,
        onPressed: _submitRegistration,
      ),
      const SizedBox(height: 16),
    ]);
  }

  // ── Shared widgets ─────────────────────────────────────────────────────────
  Widget _card({required List<Widget> children}) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      Container(width: 3, height: 14,
          decoration: BoxDecoration(color: _g, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
          color: _dark, letterSpacing: 0.3)),
    ]),
  );

  Widget _inputField({required TextEditingController controller,
    required String label, required IconData icon, TextInputType? keyboardType}) =>
      _fieldContainer(TextField(
        controller: controller, keyboardType: keyboardType,
        style: TextStyle(fontSize: 15, color: _dark),
        decoration: InputDecoration(
            labelText: label, labelStyle: TextStyle(color: _muted, fontSize: 14),
            prefixIcon: Icon(icon, color: _g, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
            floatingLabelBehavior: FloatingLabelBehavior.auto),
      ));

  Widget _kycField({required TextEditingController controller,
    required String label, required IconData icon, TextInputType? keyboardType}) =>
      _fieldContainer(TextField(
        controller: controller, keyboardType: keyboardType,
        style: TextStyle(fontSize: 15, color: _dark),
        decoration: InputDecoration(
            labelText: label, labelStyle: TextStyle(color: _muted, fontSize: 14),
            prefixIcon: Icon(icon, color: _g, size: 20),
            suffixIcon: Icon(Icons.edit_outlined, color: _muted, size: 16),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
            floatingLabelBehavior: FloatingLabelBehavior.auto),
      ));

  Widget _passField({required TextEditingController controller, required String label,
    required bool isVisible, required VoidCallback onToggle}) =>
      _fieldContainer(TextField(
        controller: controller,
        obscureText: !isVisible,
        style: TextStyle(fontSize: 15, color: _dark),
        decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: _muted, fontSize: 14),
            prefixIcon: Icon(Icons.lock_outline_rounded, color: _g, size: 20),
            suffixIcon: GestureDetector(
                onTap: onToggle,
                child: Icon(
                    isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: _muted, size: 20)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
            floatingLabelBehavior: FloatingLabelBehavior.auto),
      ));

  Widget _fieldContainer(Widget child) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))]),
    child: child,
  );

  Widget _primaryBtn({required String label, required IconData icon,
    required bool loading, required VoidCallback onPressed}) =>
      SizedBox(
        width: double.infinity, height: 54,
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
              backgroundColor: _g, foregroundColor: Colors.white, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              disabledBackgroundColor: _g.withOpacity(0.5)),
          child: loading
              ? const SizedBox(height: 22, width: 22,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
  const _StepIndicator(
      {required this.current, required this.total,
        required this.primaryGreen, required this.softMint});

  @override
  Widget build(BuildContext context) {
    // Labels adapt to total steps
    final labels = total == 3
        ? ['Verify', 'KYC Info', 'Password']
        : ['Verify', 'KYC Info'];

    return Row(
      children: List.generate(total, (i) {
        final done = i < current;
        final active = i == current;
        return Expanded(
          child: Row(children: [
            Expanded(
              child: Column(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 4,
                  decoration: BoxDecoration(
                      color: done || active ? primaryGreen : Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 6),
                Text(labels[i],
                    style: TextStyle(
                        fontSize: 11,
                        color: active ? primaryGreen : done ? primaryGreen.withOpacity(0.7) : Colors.grey[400],
                        fontWeight: active ? FontWeight.w700 : FontWeight.normal)),
              ]),
            ),
            if (i < total - 1) const SizedBox(width: 6),
          ]),
        );
      }),
    );
  }
}