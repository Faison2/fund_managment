import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tsl/features/auth/sign_up/signup.dart';
import '../../../accounts/individual_account.dart';
import '../../../dashboard/dashboard.dart';
import '../../forgot_password/forgot-password.dart';
import '../bloc/bloc.dart';
import '../bloc/event.dart';
import '../bloc/state.dart';
import '../repository/repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController    = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocus    = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  late LoginBloc _loginBloc;
  late AnimationController _animController;
  late Animation<double>  _fadeAnim;
  late Animation<Offset>  _slideAnim;

  // ── Brand colours ──────────────────────────────────────────────────────────
  static const Color _aqua      = Color(0xFF7FFFD4);
  static const Color _teal      = Color(0xFF2E7D99);
  static const Color _green     = Color(0xFF1B5E20);
  static const Color _greenMid  = Color(0xFF2E7D32);
  static const Color _greenSoft = Color(0xFFE8F5E9);
  static const Color _mintLight = Color(0xFFB8E6D3);
  // ──────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loginBloc = LoginBloc(repository: LoginRepository());
    _loginBloc.add(LoadSavedCredentials());

    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 750));
    _fadeAnim  = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _loginBloc.close();
    _animController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
            bg == Colors.green ? Icons.check_circle_outline
                : bg == Colors.orange ? Icons.warning_amber_rounded
                : Icons.error_outline,
            color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ]),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showNoCdsNumberDialog(String username) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 64, height: 64,
              decoration: const BoxDecoration(color: _greenSoft, shape: BoxShape.circle),
              child: const Icon(Icons.assignment_ind_rounded, color: _green, size: 32),
            ),
            const SizedBox(height: 16),
            const Text('Complete Account Setup',
                style: TextStyle(fontWeight: FontWeight.w800,
                    fontSize: 18, color: _green)),
            const SizedBox(height: 10),
            const Text(
              'Please finish up creating your individual account to continue.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => IndividualAccountScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Continue Setup',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _signUp()         => Navigator.pushReplacement(context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()));
  void _forgotPassword() => Navigator.pushReplacement(context,
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => _loginBloc,
      child: Scaffold(
        backgroundColor: _aqua,
        body: Stack(children: [

          // ── Gradient background ──────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF7FFFD4), Color(0xFFB2DFDB), Color(0xFFAFEEEE)],
              ),
            ),
          ),

          // ── Decorative blobs ─────────────────────────────────────────────
          Positioned(top: -80, right: -60,
              child: _Blob(size: 220, color: _teal.withOpacity(0.12))),
          Positioned(top: 120, left: -90,
              child: _Blob(size: 180, color: _green.withOpacity(0.08))),
          Positioned(bottom: -80, right: -50,
              child: _Blob(size: 240, color: _greenMid.withOpacity(0.10))),
          Positioned(bottom: 200, left: -40,
              child: _Blob(size: 130, color: _teal.withOpacity(0.08))),

          // ── Content ──────────────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height
                      - MediaQuery.of(context).padding.top
                      - MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: Column(children: [
                          const SizedBox(height: 40),

                          // ── Hero section ───────────────────────────────
                          _buildHero(),
                          const SizedBox(height: 36),

                          // ── Login card ─────────────────────────────────
                          _buildCard(),
                          const SizedBox(height: 28),

                          // ── Footer ─────────────────────────────────────
                          Text('© 2026 TSL Investment. All rights reserved.',
                              style: TextStyle(fontSize: 11,
                                  color: _green.withOpacity(0.45),
                                  letterSpacing: 0.2)),
                          const SizedBox(height: 28),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Hero ──────────────────────────────────────────────────────────────────
  Widget _buildHero() {
    return Column(children: [
      // Logo
      Stack(alignment: Alignment.center, children: [
        // Outer glow ring
        Container(
          width: 112, height: 112,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
            color: Colors.white.withOpacity(0.12),
          ),
        ),
        // Inner frosted circle
        Container(
          width: 140, height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.55),
            border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
            boxShadow: [
              BoxShadow(color: _teal.withOpacity(0.20),
                  blurRadius: 28, spreadRadius: 4, offset: const Offset(0, 8)),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Image.asset('assets/logo.png'),
        ),
      ]),

      const SizedBox(height: 12),

      // Tagline chip
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.38),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.6)),
        ),
        child: Text('Your trusted investment partner',
            style: TextStyle(fontSize: 12, color: _green.withOpacity(0.75),
                fontWeight: FontWeight.w500, letterSpacing: 0.2)),
      ),
    ]);
  }

  // ── Card ──────────────────────────────────────────────────────────────────
  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.50),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.75), width: 1.5),
        boxShadow: [
          BoxShadow(color: _teal.withOpacity(0.12),
              blurRadius: 36, offset: const Offset(0, 14)),
          BoxShadow(color: Colors.black.withOpacity(0.06),
              blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: BlocListener<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state is LoginSuccess) {
            _showSnackBar('Login successful!', Colors.green);
            if (state.accountStatus.toLowerCase().contains('pending')) {
              _showSnackBar('Account is pending authorization', Colors.orange);
            }
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const DashboardScreen()));
          } else if (state is LoginNoCdsNumber) {
            _showNoCdsNumberDialog(state.username);
          } else if (state is LoginFailure) {
            _showSnackBar(state.message, Colors.red);
          } else if (state is CredentialsLoaded) {
            if (state.savedUsername != null) {
              _emailController.text = state.savedUsername!;
            }
          }
        },
        child: BlocBuilder<LoginBloc, LoginState>(
          builder: (context, state) {
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Card heading
              const Text('Welcome Back',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900,
                      color: _green, letterSpacing: -0.4)),
              const SizedBox(height: 5),
              Text('Sign in to your TSL account',
                  style: TextStyle(fontSize: 13,
                      color: _green.withOpacity(0.55), height: 1.4)),

              const SizedBox(height: 26),

              // Email
              _InputField(
                controller: _emailController,
                focusNode: _emailFocus,
                hint: 'Phone number / Email',
                icon: Icons.person_outline_rounded,
                keyboardType: TextInputType.text,
                onSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocus),
                accentColor: _teal,
              ),
              const SizedBox(height: 14),

              // Password
              _PasswordField(
                controller: _passwordController,
                focusNode: _passwordFocus,
                loginBloc: _loginBloc,
                accentColor: _teal,
              ),
              const SizedBox(height: 16),

              // Remember me + forgot password
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                GestureDetector(
                  onTap: () => _loginBloc.add(ToggleRememberMe(!_loginBloc.rememberMe)),
                  child: Row(children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        color: _loginBloc.rememberMe ? _teal : Colors.transparent,
                        border: Border.all(
                            color: _loginBloc.rememberMe ? _teal : Colors.grey.shade400,
                            width: 1.5),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: _loginBloc.rememberMe
                          ? const Icon(Icons.check, size: 13, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text('Remember me',
                        style: TextStyle(color: _green.withOpacity(0.65), fontSize: 13)),
                  ]),
                ),
                GestureDetector(
                  onTap: _forgotPassword,
                  child: const Text('Forgot Password?',
                      style: TextStyle(color: _teal, fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ),
              ]),

              const SizedBox(height: 26),

              // Login button
              _buildLoginButton(state),

              const SizedBox(height: 24),

              // Divider
              Row(children: [
                Expanded(child: Divider(color: _green.withOpacity(0.15), thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text("Don't have an account?",
                      style: TextStyle(color: _green.withOpacity(0.45), fontSize: 12)),
                ),
                Expanded(child: Divider(color: _green.withOpacity(0.15), thickness: 1)),
              ]),

              const SizedBox(height: 16),

              // Sign up button
              _buildSignUpButton(),
            ]);
          },
        ),
      ),
    );
  }

  // ── Login button ──────────────────────────────────────────────────────────
  Widget _buildLoginButton(LoginState state) {
    final loading = state is LoginLoading;
    return GestureDetector(
      onTap: loading ? null : () {
        _loginBloc.add(LoginSubmitted(
          username:   _emailController.text,
          password:   _passwordController.text,
          rememberMe: _loginBloc.rememberMe,
        ));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: loading ? null : const LinearGradient(
            colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
          ),
          color: loading ? Colors.grey.shade300 : null,
          boxShadow: loading ? [] : [
            BoxShadow(color: _green.withOpacity(0.38),
                blurRadius: 18, offset: const Offset(0, 8)),
          ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: loading
                ? const SizedBox(key: ValueKey('spin'), width: 22, height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
                : Row(key: const ValueKey('label'),
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('Log In',
                      style: TextStyle(color: Colors.white, fontSize: 16,
                          fontWeight: FontWeight.w800, letterSpacing: 0.4)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                ]),
          ),
        ),
      ),
    );
  }

  // ── Sign-up button ────────────────────────────────────────────────────────
  Widget _buildSignUpButton() {
    return GestureDetector(
      onTap: _signUp,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withOpacity(0.55),
          border: Border.all(color: _teal.withOpacity(0.45), width: 1.5),
          boxShadow: [
            BoxShadow(color: _teal.withOpacity(0.08),
                blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Center(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(width: 8),
            const Text('Create an Account',
                style: TextStyle(color: _teal, fontSize: 15,
                    fontWeight: FontWeight.w700, letterSpacing: 0.3)),
          ]),
        ),
      ),
    );
  }
}

// ─── Decorative Blob ──────────────────────────────────────────────────────────

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
      ),
    );
  }
}

// ─── Input Field ──────────────────────────────────────────────────────────────

class _InputField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final void Function(String)? onSubmitted;
  final Color accentColor;

  const _InputField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.onSubmitted,
    required this.accentColor,
  });

  @override
  State<_InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<_InputField> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() {
      if (mounted) setState(() => _focused = widget.focusNode.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(_focused ? 0.85 : 0.68),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: _focused ? widget.accentColor : Colors.white.withOpacity(0.5),
            width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _focused
                ? widget.accentColor.withOpacity(0.16)
                : Colors.black.withOpacity(0.04),
            blurRadius: _focused ? 14 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        keyboardType: widget.keyboardType,
        onSubmitted: widget.onSubmitted,
        style: const TextStyle(fontSize: 15, color: Colors.black87),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(color: Colors.black.withOpacity(0.32), fontSize: 14),
          prefixIcon: Icon(widget.icon,
              color: _focused ? widget.accentColor : Colors.grey.shade400, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

// ─── Password Field ───────────────────────────────────────────────────────────

class _PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final LoginBloc loginBloc;
  final Color accentColor;

  const _PasswordField({
    required this.controller,
    required this.focusNode,
    required this.loginBloc,
    required this.accentColor,
  });

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() {
      if (mounted) setState(() => _focused = widget.focusNode.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, state) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(_focused ? 0.85 : 0.68),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: _focused ? widget.accentColor : Colors.white.withOpacity(0.5),
                width: 1.5),
            boxShadow: [
              BoxShadow(
                color: _focused
                    ? widget.accentColor.withOpacity(0.16)
                    : Colors.black.withOpacity(0.04),
                blurRadius: _focused ? 14 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            obscureText: widget.loginBloc.obscurePassword,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
            decoration: InputDecoration(
              hintText: 'Password',
              hintStyle: TextStyle(color: Colors.black.withOpacity(0.32), fontSize: 14),
              prefixIcon: Icon(Icons.lock_outline_rounded,
                  color: _focused ? widget.accentColor : Colors.grey.shade400, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              suffixIcon: IconButton(
                icon: Icon(
                  widget.loginBloc.obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey.shade400, size: 20,
                ),
                onPressed: () => widget.loginBloc.add(TogglePasswordVisibility()),
              ),
            ),
          ),
        );
      },
    );
  }
}