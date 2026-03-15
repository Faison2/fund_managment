import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../provider/locale_provider.dart';
import '../../provider/theme_provider.dart';

// ── Colour tokens (shared with ProfileScreen) ─────────────────────────────────
class TSLColors {
  static const darkBg        = Color(0xFF0B1A0C);
  static const darkCard      = Color(0xFF132013);
  static const darkCard2     = Color(0xFF1A2B1B);
  static const darkBorder    = Color(0xFF1E3320);
  static const darkTextPrim  = Color(0xFFE8F5E9);
  static const darkTextSec   = Color(0xFF81A884);
  static const darkTextHint  = Color(0xFF4A7A4D);
  static const darkDivider   = Color(0xFF1E3320);

  static const lightBg       = Color(0xFFB8E6D3);
  static const lightCard     = Color(0xFFFFFFFF);
  static const lightBorder   = Color(0xFFE2ECE2);
  static const lightTextPrim = Color(0xFF1A2E1A);
  static const lightTextSec  = Color(0xFF5A7A5C);
  static const lightTextHint = Color(0xFF9AAA9C);
  static const lightDivider  = Color(0xFFEEEEEE);

  static const green500 = Color(0xFF4ADE80);
  static const green700 = Color(0xFF15803D);
  static const teal     = Color(0xFF2E7D99);
}

// ── Localised strings ─────────────────────────────────────────────────────────
class _S {
  final String settings, appearance, darkMode, darkModeOn, lightModeOn,
      language, english, swahili,
      security, biometric, biometricDesc,
      changePassword, changePasswordDesc,
      comingSoon,
  // Password-dialog strings
      currentPassword, newPassword, confirmNewPassword,
      passwordsDoNotMatch, cancel, submit, changingPassword,
      emailNotFound, currentPasswordHint, newPasswordHint;
  const _S({
    required this.settings,             required this.appearance,
    required this.darkMode,             required this.darkModeOn,
    required this.lightModeOn,          required this.language,
    required this.english,              required this.swahili,
    required this.security,             required this.biometric,
    required this.biometricDesc,
    required this.changePassword,       required this.changePasswordDesc,
    required this.comingSoon,
    required this.currentPassword,      required this.newPassword,
    required this.confirmNewPassword,   required this.passwordsDoNotMatch,
    required this.cancel,               required this.submit,
    required this.changingPassword,     required this.emailNotFound,
    required this.currentPasswordHint,  required this.newPasswordHint,
  });
}

const _en = _S(
  settings:             'Settings',
  appearance:           'Appearance',
  darkMode:             'Dark Mode',
  darkModeOn:           'Dark mode is active',
  lightModeOn:          'Light mode is active',
  language:             'Language',
  english:              'English',
  swahili:              'Swahili',
  security:             'Security',
  biometric:            'Biometric Login',
  biometricDesc:        'Fingerprint or Face ID unlock',
  changePassword:       'Change Password',
  changePasswordDesc:   'Update your account password',
  comingSoon:           'Coming soon',
  currentPassword:      'Current Password',
  newPassword:          'New Password',
  confirmNewPassword:   'Confirm New Password',
  passwordsDoNotMatch:  'New passwords do not match.',
  cancel:               'Cancel',
  submit:               'Update Password',
  changingPassword:     'Updating…',
  emailNotFound:        'Email not found. Please open the Profile page first.',
  currentPasswordHint:  'Enter your current password',
  newPasswordHint:      'Enter your new password',
);

const _sw = _S(
  settings:             'Mipangilio',
  appearance:           'Muonekano',
  darkMode:             'Hali ya Giza',
  darkModeOn:           'Hali ya giza imewashwa',
  lightModeOn:          'Hali ya mwanga imewashwa',
  language:             'Lugha',
  english:              'Kiingereza',
  swahili:              'Kiswahili',
  security:             'Usalama',
  biometric:            'Kuingia kwa Biometriki',
  biometricDesc:        'Fungua kwa alama ya kidole au uso',
  changePassword:       'Badilisha Nenosiri',
  changePasswordDesc:   'Sasisha nywila ya akaunti yako',
  comingSoon:           'Inakuja hivi karibuni',
  currentPassword:      'Nenosiri la Sasa',
  newPassword:          'Nenosiri Jipya',
  confirmNewPassword:   'Thibitisha Nenosiri Jipya',
  passwordsDoNotMatch:  'Manenosiri mapya hayafanani.',
  cancel:               'Ghairi',
  submit:               'Sasisha Nenosiri',
  changingPassword:     'Inasasisha…',
  emailNotFound:        'Barua pepe haipatikani. Tafadhali fungua ukurasa wa Wasifu kwanza.',
  currentPasswordHint:  'Weka nenosiri lako la sasa',
  newPasswordHint:      'Weka nenosiri jipya',
);

// ── SettingsPage ──────────────────────────────────────────────────────────────
class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _biometric = false;

  // ── Theme helpers ────────────────────────────────────────────────────────
  bool  get _dark   => context.watch<ThemeProvider>().isDark;
  _S    get _s      => context.watch<LocaleProvider>().isSwahili ? _sw : _en;
  Color get _bg     => _dark ? TSLColors.darkBg       : TSLColors.lightBg;
  Color get _card   => _dark ? TSLColors.darkCard      : TSLColors.lightCard;
  Color get _border => _dark ? TSLColors.darkBorder    : TSLColors.lightBorder;
  Color get _txtP   => _dark ? TSLColors.darkTextPrim  : TSLColors.lightTextPrim;
  Color get _txtS   => _dark ? TSLColors.darkTextSec   : TSLColors.lightTextSec;
  Color get _txtH   => _dark ? TSLColors.darkTextHint  : TSLColors.lightTextHint;
  Color get _div    => _dark ? TSLColors.darkDivider   : TSLColors.lightDivider;
  Color get _accent => _dark ? TSLColors.green500      : TSLColors.green700;

  // Safe variants for use outside build()
  bool  get _darkNow   => Provider.of<ThemeProvider>(context, listen: false).isDark;
  _S    get _sNow      => Provider.of<LocaleProvider>(context, listen: false).isSwahili
      ? _sw : _en;
  Color get _cardNow   => _darkNow ? TSLColors.darkCard    : TSLColors.lightCard;
  Color get _borderNow => _darkNow ? TSLColors.darkBorder  : TSLColors.lightBorder;
  Color get _txtPNow   => _darkNow ? TSLColors.darkTextPrim : TSLColors.lightTextPrim;
  Color get _txtSNow   => _darkNow ? TSLColors.darkTextSec  : TSLColors.lightTextSec;
  Color get _txtHNow   => _darkNow ? TSLColors.darkTextHint : TSLColors.lightTextHint;

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    context.watch<LocaleProvider>();
    final s  = _s;
    final tp = context.read<ThemeProvider>();
    final lp = context.read<LocaleProvider>();

    return Scaffold(
      backgroundColor: _bg,
      body: Column(children: [
        _buildHeader(s),
        Expanded(child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ── Appearance ───────────────────────────────────────────
              _label(s.appearance),
              const SizedBox(height: 10),
              _cardWidget([
                _toggleRow(
                  Icons.dark_mode_outlined,
                  _dark ? const Color(0xFF818CF8) : const Color(0xFF6366F1),
                  const Color(0xFFEDE9FE),
                  s.darkMode,
                  tp.isDark ? s.darkModeOn : s.lightModeOn,
                  tp.isDark,
                      (v) { HapticFeedback.lightImpact(); tp.setDark(v); },
                ),
              ]),

              const SizedBox(height: 24),

              // ── Language ─────────────────────────────────────────────
              _label(s.language),
              const SizedBox(height: 10),
              _cardWidget([
                _langRow(
                  flag: 'EN', nativeName: s.english, localName: 'English',
                  selected: !lp.isSwahili,
                  onTap: () { HapticFeedback.selectionClick(); lp.setEnglish(); },
                ),
                Divider(height: 1, color: _div, indent: 66),
                _langRow(
                  flag: 'SW', nativeName: s.swahili, localName: 'Kiswahili',
                  selected: lp.isSwahili,
                  onTap: () { HapticFeedback.selectionClick(); lp.setSwahili(); },
                ),
              ]),

              const SizedBox(height: 24),

              // ── Security ─────────────────────────────────────────────
              _label(s.security),
              const SizedBox(height: 10),
              _cardWidget([
                _toggleRow(
                  Icons.fingerprint,
                  const Color(0xFF059669), const Color(0xFFD1FAE5),
                  s.biometric, s.biometricDesc, _biometric,
                      (v) { HapticFeedback.lightImpact(); setState(() => _biometric = v); },
                ),
                Divider(height: 1, color: _div, indent: 66),
                // ✅ Change Password — opens real dialog (PIN row removed)
                _navRow(
                  Icons.lock_outline,
                  const Color(0xFFEF4444), const Color(0xFFFEE2E2),
                  s.changePassword, s.changePasswordDesc,
                  _showChangePasswordDialog,
                ),
              ]),

            ]),
          ),
        )),
      ]),
    );
  }

  // ── Change password dialog ────────────────────────────────────────────────
  void _showChangePasswordDialog() {
    final s      = _sNow;
    final card   = _cardNow;
    final border = _borderNow;
    final txtP   = _txtPNow;
    final txtS   = _txtSNow;
    final txtH   = _txtHNow;
    final isDark = _darkNow;
    const teal   = TSLColors.teal;

    final currentPwCtrl = TextEditingController();
    final newPwCtrl     = TextEditingController();
    final confirmPwCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew     = true;
    bool obscureConfirm = true;
    bool isSubmitting   = false;
    String? dialogError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {

          Future<void> handleSubmit() async {
            final current = currentPwCtrl.text.trim();
            final newPw   = newPwCtrl.text.trim();
            final confirm = confirmPwCtrl.text.trim();

            if (current.isEmpty || newPw.isEmpty || confirm.isEmpty) {
              setDialogState(() => dialogError = 'All fields are required.');
              return;
            }
            if (newPw != confirm) {
              setDialogState(() => dialogError = s.passwordsDoNotMatch);
              return;
            }

            setDialogState(() { isSubmitting = true; dialogError = null; });

            try {
              // ✅ Read email that ProfileScreen saved to SharedPreferences
              final prefs     = await SharedPreferences.getInstance();
              final userEmail = (prefs.getString('userEmail') ?? '').trim();

              if (userEmail.isEmpty) {
                setDialogState(() {
                  dialogError  = s.emailNotFound;
                  isSubmitting = false;
                });
                return;
              }

              final url = Uri.parse(
                  'https://portaluat.tsl.co.tz/FMSAPI/home/ChangePassword');
              final response = await http.post(url,
                  headers: {'Content-Type': 'application/json'},
                  body: json.encode({
                    'APIUsername':     'User2',
                    'APIPassword':     'CBZ1234#2',
                    'Email':           userEmail,
                    'CurrentPassword': current,
                    'NewPassword':     newPw,
                  }));

              final data       = json.decode(response.body);
              final statusDesc = data['statusDesc'] ?? 'Unknown response';
              final isSuccess  = data['status'] == 'success';

              setDialogState(() => isSubmitting = false);

              if (isSuccess) {
                Navigator.of(ctx).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Row(children: [
                      const Icon(Icons.check_circle_outline_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Text(statusDesc,
                          style: const TextStyle(fontWeight: FontWeight.w600))),
                    ]),
                    backgroundColor: const Color(0xFF4CAF50),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    duration: const Duration(seconds: 4),
                  ));
                }
              } else {
                setDialogState(() => dialogError = statusDesc);
              }
            } catch (e) {
              setDialogState(() {
                dialogError  = 'Network error. Please try again.';
                isSubmitting = false;
              });
            }
          }

          // ── Dialog UI ─────────────────────────────────────────────────
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24)),
            backgroundColor: card,
            insetPadding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 40),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Header
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: teal.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.lock_outline_rounded,
                          color: teal, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.changePassword,
                                style: TextStyle(fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: txtP)),
                            Text('Update your account password',
                                style: TextStyle(fontSize: 11,
                                    color: txtH)),
                          ]),
                    ),
                    GestureDetector(
                      onTap: isSubmitting
                          ? null
                          : () => Navigator.of(ctx).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: border,
                            borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.close_rounded,
                            size: 16, color: txtS),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // Error banner
                  if (dialogError != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.red.withOpacity(0.25)),
                      ),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: Colors.redAccent, size: 17),
                            const SizedBox(width: 8),
                            Expanded(child: Text(dialogError!,
                                style: const TextStyle(fontSize: 13,
                                    color: Colors.redAccent,
                                    height: 1.45))),
                          ]),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Current password
                  _pwLabel(s.currentPassword, txtH),
                  const SizedBox(height: 6),
                  _pwField(
                    controller: currentPwCtrl,
                    hint: s.currentPasswordHint,
                    obscure: obscureCurrent,
                    onToggle: () => setDialogState(
                            () => obscureCurrent = !obscureCurrent),
                    enabled: !isSubmitting,
                    isDark: isDark,
                    border: border, txtP: txtP, txtH: txtH,
                  ),

                  const SizedBox(height: 16),

                  // New password
                  _pwLabel(s.newPassword, txtH),
                  const SizedBox(height: 6),
                  _pwField(
                    controller: newPwCtrl,
                    hint: s.newPasswordHint,
                    obscure: obscureNew,
                    onToggle: () => setDialogState(
                            () => obscureNew = !obscureNew),
                    enabled: !isSubmitting,
                    isDark: isDark,
                    border: border, txtP: txtP, txtH: txtH,
                  ),

                  const SizedBox(height: 16),

                  // Confirm new password
                  _pwLabel(s.confirmNewPassword, txtH),
                  const SizedBox(height: 6),
                  _pwField(
                    controller: confirmPwCtrl,
                    hint: s.newPasswordHint,
                    obscure: obscureConfirm,
                    onToggle: () => setDialogState(
                            () => obscureConfirm = !obscureConfirm),
                    enabled: !isSubmitting,
                    isDark: isDark,
                    border: border, txtP: txtP, txtH: txtH,
                  ),

                  const SizedBox(height: 28),

                  // Buttons
                  Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: isSubmitting
                            ? null
                            : () => Navigator.of(ctx).pop(),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: border, width: 1.5),
                          ),
                          child: Center(child: Text(s.cancel,
                              style: TextStyle(fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: txtS))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: isSubmitting ? null : handleSubmit,
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF2E7D99),
                                  Color(0xFF1A5F77),
                                ]),
                            boxShadow: [BoxShadow(
                                color: teal.withOpacity(0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 6))],
                          ),
                          child: Center(
                            child: isSubmitting
                                ? Row(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: [
                                const SizedBox(width: 16, height: 16,
                                    child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2)),
                                const SizedBox(width: 10),
                                Text(s.changingPassword,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white)),
                              ],
                            )
                                : Text(s.submit,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.4)),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Password field helpers ────────────────────────────────────────────────
  Widget _pwLabel(String text, Color color) => Text(text,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
          color: color, letterSpacing: 0.4));

  Widget _pwField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    required bool enabled,
    required bool isDark,
    required Color border,
    required Color txtP,
    required Color txtH,
  }) => Container(
    decoration: BoxDecoration(
      color: isDark
          ? TSLColors.darkCard2.withOpacity(0.8)
          : TSLColors.lightBg.withOpacity(0.6),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: border),
    ),
    child: TextField(
      controller: controller,
      obscureText: obscure,
      enabled: enabled,
      style: TextStyle(fontSize: 14, color: txtP),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: txtH),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        suffixIcon: IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 18, color: txtH,
          ),
          onPressed: onToggle,
        ),
      ),
    ),
  );

  // ── UI helpers ────────────────────────────────────────────────────────────
  Widget _buildHeader(_S s) => Container(
    decoration: BoxDecoration(
      gradient: _dark
          ? const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF0B1A0C), Color(0xFF132013), Color(0xFF09100A)])
          : const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)]),
    ),
    child: SafeArea(bottom: false, child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 255, 255, 0.15),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 18),
          ),
        ),
        const SizedBox(width: 16),
        Text(s.settings,
            style: const TextStyle(color: Colors.white, fontSize: 22,
                fontWeight: FontWeight.w900, letterSpacing: -0.5)),
      ]),
    )),
  );

  Widget _toggleRow(IconData icon, Color iconColor, Color iconBg,
      String title, String subtitle, bool value,
      ValueChanged<bool> onChange) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(children: [
          _iconBox(icon,
              _dark ? Color.fromRGBO(iconColor.red, iconColor.green,
                  iconColor.blue, 0.15) : iconBg,
              iconColor),
          const SizedBox(width: 14),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 14,
                fontWeight: FontWeight.w700, color: _txtP)),
            Text(subtitle, style: TextStyle(fontSize: 12, color: _txtS)),
          ])),
          Transform.scale(scale: 0.88,
              child: Switch(value: value, onChanged: onChange,
                  activeThumbColor: _accent)),
        ]),
      );

  Widget _navRow(IconData icon, Color iconColor, Color iconBg,
      String title, String subtitle, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(children: [
            _iconBox(icon,
                _dark ? Color.fromRGBO(iconColor.red, iconColor.green,
                    iconColor.blue, 0.15) : iconBg,
                iconColor),
            const SizedBox(width: 14),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 14,
                  fontWeight: FontWeight.w700, color: _txtP)),
              Text(subtitle, style: TextStyle(fontSize: 12, color: _txtS)),
            ])),
            Icon(Icons.chevron_right,
                color: Color.fromRGBO(
                    _txtS.red, _txtS.green, _txtS.blue, 0.4),
                size: 20),
          ]),
        ),
      );

  Widget _langRow({
    required String flag,
    required String nativeName,
    required String localName,
    required bool selected,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 40, height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected
                ? Color.fromRGBO(_accent.red, _accent.green,
                _accent.blue, 0.12)
                : (_dark ? TSLColors.darkCard2
                : const Color(0xFFF3F4F6)),
            border: selected ? Border.all(
                color: Color.fromRGBO(_accent.red, _accent.green,
                    _accent.blue, 0.35), width: 2) : null,
          ),
          child: Center(child: Text(flag,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                  color: selected ? _accent : _txtS))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(nativeName, style: TextStyle(fontSize: 14,
              fontWeight: selected
                  ? FontWeight.w800 : FontWeight.w600,
              color: selected ? _accent : _txtP)),
          Text(localName, style: TextStyle(fontSize: 12, color: _txtS)),
        ])),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 22, height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? _accent : Colors.transparent,
            border: Border.all(
                color: selected ? _accent : _border, width: 2),
          ),
          child: selected
              ? const Icon(Icons.check, size: 13, color: Colors.white)
              : null,
        ),
      ]),
    ),
  );

  Widget _iconBox(IconData icon, Color bg, Color fg) => Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: fg, size: 18));

  Widget _cardWidget(List<Widget> children) => Container(
      decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
          boxShadow: [BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.04),
              blurRadius: 12, offset: const Offset(0, 4))]),
      child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(children: children)));

  Widget _label(String text) => Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(text.toUpperCase(),
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
              color: _txtH, letterSpacing: 1.2)));
}