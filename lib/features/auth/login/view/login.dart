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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  late LoginBloc _loginBloc;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _loginBloc = LoginBloc(repository: LoginRepository());
    _loginBloc.add(LoadSavedCredentials());

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

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

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              backgroundColor == Colors.green
                  ? Icons.check_circle_outline
                  : backgroundColor == Colors.orange
                  ? Icons.warning_amber_rounded
                  : Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showNoCdsNumberDialog(String username) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.assignment_ind_rounded,
                      color: Colors.green[800], size: 30),
                ),
                const SizedBox(height: 16),
                Text(
                  'Complete Account Setup',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: Colors.green[900],
                  ),
                ),
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
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => IndividualAccountScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Continue Setup',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
    return BlocProvider(
      create: (context) => _loginBloc,
      child: Scaffold(
        backgroundColor: const Color(0xFF7FFFD4),
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
          child: Stack(
            children: [
              // Decorative background circles
              Positioned(
                top: -70,
                right: -50,
                child: _GlassCircle(size: 180),
              ),
              Positioned(
                top: 160,
                left: -80,
                child: _GlassCircle(size: 150),
              ),
              Positioned(
                bottom: -60,
                right: -40,
                child: _GlassCircle(size: 200),
              ),

              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: FadeTransition(
                          opacity: _fadeAnim,
                          child: SlideTransition(
                            position: _slideAnim,
                            child: Column(
                              children: [
                                const SizedBox(height: 32),

                                // Logo with glow
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.8),
                                        width: 2.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.teal.withOpacity(0.25),
                                        blurRadius: 24,
                                        spreadRadius: 4,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(14),
                                  child: Image.asset("assets/logo.png"),
                                ),

                                const SizedBox(height: 32),

                                // Card
                                Container(
                                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.45),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.7),
                                        width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 30,
                                        offset: const Offset(0, 12),
                                      ),
                                    ],
                                  ),
                                  child: BlocListener<LoginBloc, LoginState>(
                                    listener: (context, state) {
                                      if (state is LoginSuccess) {
                                        _showSnackBar(
                                            'Login successful!', Colors.green);
                                        if (state.accountStatus
                                            .toLowerCase()
                                            .contains('pending')) {
                                          _showSnackBar(
                                              'Account is pending authorization',
                                              Colors.orange);
                                        }
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                              const DashboardScreen()),
                                        );
                                      } else if (state is LoginNoCdsNumber) {
                                        _showNoCdsNumberDialog(state.username);
                                      } else if (state is LoginFailure) {
                                        _showSnackBar(state.message, Colors.red);
                                      } else if (state is CredentialsLoaded) {
                                        if (state.savedUsername != null) {
                                          _emailController.text =
                                          state.savedUsername!;
                                        }
                                      }
                                    },
                                    child: BlocBuilder<LoginBloc, LoginState>(
                                      builder: (context, state) {
                                        return Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                          children: [
                                            // Header
                                            const Text(
                                              'Welcome Back',
                                              style: TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.black87,
                                                letterSpacing: -0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Sign in to your TSL account',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.black.withOpacity(0.5),
                                                height: 1.4,
                                              ),
                                            ),

                                            const SizedBox(height: 28),

                                            // Email field
                                            _InputField(
                                              controller: _emailController,
                                              focusNode: _emailFocus,
                                              hint: 'Phone number / Email',
                                              icon: Icons.person_outline_rounded,
                                              keyboardType: TextInputType.text,
                                              onSubmitted: (_) => FocusScope.of(context)
                                                  .requestFocus(_passwordFocus),
                                            ),

                                            const SizedBox(height: 14),

                                            // Password field
                                            _PasswordField(
                                              controller: _passwordController,
                                              focusNode: _passwordFocus,
                                              loginBloc: _loginBloc,
                                            ),

                                            const SizedBox(height: 14),

                                            // Remember me + Forgot password
                                            Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                              children: [
                                                GestureDetector(
                                                  onTap: () => _loginBloc.add(
                                                      ToggleRememberMe(
                                                          !_loginBloc.rememberMe)),
                                                  child: Row(
                                                    children: [
                                                      AnimatedContainer(
                                                        duration: const Duration(
                                                            milliseconds: 200),
                                                        width: 20,
                                                        height: 20,
                                                        decoration: BoxDecoration(
                                                          color: _loginBloc.rememberMe
                                                              ? Colors.blue
                                                              : Colors.transparent,
                                                          border: Border.all(
                                                            color: _loginBloc.rememberMe
                                                                ? Colors.blue
                                                                : Colors.grey.shade400,
                                                            width: 1.5,
                                                          ),
                                                          borderRadius:
                                                          BorderRadius.circular(5),
                                                        ),
                                                        child: _loginBloc.rememberMe
                                                            ? const Icon(Icons.check,
                                                            size: 14,
                                                            color: Colors.white)
                                                            : null,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        'Remember me',
                                                        style: TextStyle(
                                                          color: Colors.grey.shade600,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: _forgotPassword,
                                                  child: const Text(
                                                    'Forgot Password?',
                                                    style: TextStyle(
                                                      color: Colors.blue,
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),

                                            const SizedBox(height: 28),

                                            // Login button
                                            SizedBox(
                                              width: double.infinity,
                                              height: 52,
                                              child: ElevatedButton(
                                                onPressed: state is LoginLoading
                                                    ? null
                                                    : () {
                                                  _loginBloc.add(LoginSubmitted(
                                                    username:
                                                    _emailController.text,
                                                    password:
                                                    _passwordController.text,
                                                    rememberMe:
                                                    _loginBloc.rememberMe,
                                                  ));
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.blue,
                                                  foregroundColor: Colors.white,
                                                  disabledBackgroundColor:
                                                  Colors.blue.withOpacity(0.6),
                                                  elevation: 6,
                                                  shadowColor:
                                                  Colors.blue.withOpacity(0.4),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                    BorderRadius.circular(14),
                                                  ),
                                                ),
                                                child: AnimatedSwitcher(
                                                  duration: const Duration(
                                                      milliseconds: 250),
                                                  child: state is LoginLoading
                                                      ? const SizedBox(
                                                    key: ValueKey('loading'),
                                                    height: 22,
                                                    width: 22,
                                                    child:
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2.5,
                                                    ),
                                                  )
                                                      : const Row(
                                                    key: ValueKey('text'),
                                                    mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                    children: [
                                                      Text(
                                                        'Log In',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                          FontWeight.w700,
                                                          letterSpacing: 0.4,
                                                        ),
                                                      ),
                                                      SizedBox(width: 8),
                                                      Icon(
                                                          Icons
                                                              .arrow_forward_rounded,
                                                          size: 20),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),

                                            const SizedBox(height: 28),

                                            // Divider
                                            Row(
                                              children: [
                                                Expanded(
                                                    child: Divider(
                                                        color: Colors.grey.shade300,
                                                        thickness: 1)),
                                                Padding(
                                                  padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12),
                                                  child: Text(
                                                    "Don't have an account?",
                                                    style: TextStyle(
                                                        color: Colors.grey.shade500,
                                                        fontSize: 13),
                                                  ),
                                                ),
                                                Expanded(
                                                    child: Divider(
                                                        color: Colors.grey.shade300,
                                                        thickness: 1)),
                                              ],
                                            ),

                                            const SizedBox(height: 14),

                                            // Sign up button
                                            SizedBox(
                                              width: double.infinity,
                                              height: 50,
                                              child: OutlinedButton(
                                                onPressed: _signUp,
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: Colors.blue,
                                                  side: const BorderSide(
                                                      color: Colors.blue, width: 1.5),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                    BorderRadius.circular(14),
                                                  ),
                                                ),
                                                child: const Text(
                                                  'Create an Account',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 0.3,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 32),

                                // Footer
                                Text(
                                  '© 2026 TSL. All rights reserved.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black.withOpacity(0.35),
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),  // IntrinsicHeight
                  ),   // ConstrainedBox
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Reusable Input Field ────────────────────────────────────────────────────

class _InputField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final void Function(String)? onSubmitted;

  const _InputField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.onSubmitted,
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
      setState(() => _focused = widget.focusNode.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _focused ? Colors.blue : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _focused
                ? Colors.blue.withOpacity(0.12)
                : Colors.black.withOpacity(0.04),
            blurRadius: _focused ? 12 : 6,
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
          hintStyle:
          TextStyle(color: Colors.black.withOpacity(0.35), fontSize: 14),
          prefixIcon:
          Icon(widget.icon, color: _focused ? Colors.blue : Colors.grey, size: 20),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

// ─── Password Field ──────────────────────────────────────────────────────────

class _PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final LoginBloc loginBloc;

  const _PasswordField({
    required this.controller,
    required this.focusNode,
    required this.loginBloc,
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
      setState(() => _focused = widget.focusNode.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, state) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.75),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _focused ? Colors.blue : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _focused
                    ? Colors.blue.withOpacity(0.12)
                    : Colors.black.withOpacity(0.04),
                blurRadius: _focused ? 12 : 6,
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
              hintStyle: TextStyle(
                  color: Colors.black.withOpacity(0.35), fontSize: 14),
              prefixIcon: Icon(Icons.lock_outline_rounded,
                  color: _focused ? Colors.blue : Colors.grey, size: 20),
              border: InputBorder.none,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              suffixIcon: IconButton(
                icon: Icon(
                  widget.loginBloc.obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
                onPressed: () {
                  widget.loginBloc.add(TogglePasswordVisibility());
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Glass Circle Decoration ─────────────────────────────────────────────────

class _GlassCircle extends StatelessWidget {
  final double size;

  const _GlassCircle({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.15),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
      ),
    );
  }
}