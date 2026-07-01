import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../constants/constants.dart';
import '../../../constants/app_logger.dart';
import '../login/view/login.dart';

/// Email verification screen for newly registered users.
///
/// After a successful sign-up the user is redirected here instead of
/// directly to the login page.  The user must enter the OTP sent to
/// their email address before their account is activated.
class EmailVerificationScreen extends StatefulWidget {
  final String email;
  const EmailVerificationScreen({Key? key, required this.email})
      : super(key: key);

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with SingleTickerProviderStateMixin {
  final _codeCtrl   = TextEditingController();
  bool _submitting  = false;
  bool _resent      = false;

  // ── Resend cooldown ──────────────────────────────────────────────────────
  late AnimationController _animCtrl;
  int _cooldown = 0;
  static const int _cooldownSec = 30;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _cooldownSec),
    );
    _startCooldown();
  }

  void _startCooldown() {
    _cooldown = _cooldownSec;
    _animCtrl.reset();
    _animCtrl.forward();
    _animCtrl.addListener(() {
      final remaining =
          _cooldownSec - (_animCtrl.value * _cooldownSec).round();
      if (remaining != _cooldown && mounted) {
        setState(() => _cooldown = remaining);
      }
    });
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Verify code ──────────────────────────────────────────────────────────
  Future<void> _verify() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      _snack('Please enter the verification code');
      return;
    }

    setState(() => _submitting = true);

    try {
      final url   = Uri.parse('$cSharpApi/VerifyEmail');
      final res   = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'APIUsername': apiUsername,
            'APIPassword': apiPassword,
            'Email':       widget.email,
            'Code':        code,
          }),
      );

      final data      = json.decode(res.body);
      final isSuccess = data['status'] == 'success';

      if (!mounted) return;

      if (isSuccess) {
        _snack('Email verified successfully! You can now log in.');
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      } else {
        setState(() => _submitting = false);
        _snack(data['statusDesc'] ?? 'Verification failed');
      }
    } catch (e) {
      AppLogger.error('Email verification error', e);
      if (!mounted) return;
      setState(() => _submitting = false);
      _snack('Network error. Please try again.');
    }
  }

  // ── Resend code ──────────────────────────────────────────────────────────
  Future<void> _resend() async {
    setState(() => _resent = true);

    try {
      final url = Uri.parse('$cSharpApi/ResendVerificationCode');
      await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'APIUsername': apiUsername,
            'APIPassword': apiPassword,
            'Email':       widget.email,
          }),
      );
    } catch (e) {
      AppLogger.error('Resend verification code error', e);
    }

    if (!mounted) return;
    setState(() => _resent = false);
    _startCooldown();
    _snack('Verification code resent to ${widget.email}');
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── UI ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mail_outline_rounded,
                  size: 72, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 24),
              Text('Check your email',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(
                'We sent a verification code to\n${widget.email}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _codeCtrl,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  hintText: '000000',
                  counterText: '',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _verify,
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Verify Email'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: (_cooldown > 0 || _resent) ? null : _resend,
                child: _resent
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_cooldown > 0
                        ? 'Resend code in ${_cooldown}s'
                        : 'Resend code'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
