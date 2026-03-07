import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../provider/locale_provider.dart';
import '../../provider/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _biometric = false;

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

              // ── Appearance ──────────────────────────────────────────
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
                _langRow(flag: 'EN', nativeName: s.english, localName: 'English',
                    selected: !lp.isSwahili,
                    onTap: () { HapticFeedback.selectionClick(); lp.setEnglish(); }),
                Divider(height: 1, color: _div, indent: 66),
                _langRow(flag: 'SW', nativeName: s.swahili, localName: 'Kiswahili',
                    selected: lp.isSwahili,
                    onTap: () { HapticFeedback.selectionClick(); lp.setSwahili(); }),
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
                _navRow(Icons.pin_outlined,
                    const Color(0xFFF59E0B), const Color(0xFFFEF3C7),
                    s.changePIN, s.changePINDesc,
                        () => _snack(s.comingSoon)),
                Divider(height: 1, color: _div, indent: 66),
                _navRow(Icons.lock_outline,
                    const Color(0xFFEF4444), const Color(0xFFFEE2E2),
                    s.changePassword, s.changePasswordDesc,
                        () => _snack(s.comingSoon)),
              ]),

            ]),
          ),
        )),
      ]),
    );
  }

  Widget _buildHeader(_S s) => Container(
    decoration: BoxDecoration(
      gradient: _dark
          ? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF0B1A0C), Color(0xFF132013), Color(0xFF09100A)])
          : const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)]),
    ),
    child: SafeArea(bottom: false, child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Color.fromRGBO(255,255,255,0.15),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          ),
        ),
        const SizedBox(width: 16),
        Text(s.settings, style: const TextStyle(color: Colors.white, fontSize: 22,
            fontWeight: FontWeight.w900, letterSpacing: -0.5)),
      ]),
    )),
  );

  Widget _toggleRow(IconData icon, Color iconColor, Color iconBg,
      String title, String subtitle, bool value, ValueChanged<bool> onChange) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(children: [
          _iconBox(icon, _dark ? Color.fromRGBO(iconColor.red, iconColor.green, iconColor.blue, 0.15) : iconBg, iconColor),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _txtP)),
            Text(subtitle, style: TextStyle(fontSize: 12, color: _txtS)),
          ])),
          Transform.scale(scale: 0.88,
              child: Switch(value: value, onChanged: onChange, activeThumbColor: _accent)),
        ]),
      );

  Widget _navRow(IconData icon, Color iconColor, Color iconBg,
      String title, String subtitle, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(children: [
            _iconBox(icon, _dark ? Color.fromRGBO(iconColor.red, iconColor.green, iconColor.blue, 0.15) : iconBg, iconColor),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _txtP)),
              Text(subtitle, style: TextStyle(fontSize: 12, color: _txtS)),
            ])),
            Icon(Icons.chevron_right, color: Color.fromRGBO(_txtS.red, _txtS.green, _txtS.blue, 0.4), size: 20),
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
            color: selected ? Color.fromRGBO(_accent.red, _accent.green, _accent.blue, 0.12)
                : (_dark ? TSLColors.darkCard2 : const Color(0xFFF3F4F6)),
            border: selected ? Border.all(color: Color.fromRGBO(_accent.red, _accent.green, _accent.blue, 0.35), width: 2) : null,
          ),
          child: Center(child: Text(flag,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                  color: selected ? _accent : _txtS))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(nativeName, style: TextStyle(fontSize: 14,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? _accent : _txtP)),
          Text(localName, style: TextStyle(fontSize: 12, color: _txtS)),
        ])),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 22, height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? _accent : Colors.transparent,
            border: Border.all(color: selected ? _accent : _border, width: 2),
          ),
          child: selected ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
        ),
      ]),
    ),
  );

  Widget _iconBox(IconData icon, Color bg, Color fg) => Container(
      width: 36, height: 36,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: fg, size: 18));

  Widget _cardWidget(List<Widget> children) => Container(
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
          boxShadow: [BoxShadow(color: Color.fromRGBO(0,0,0,0.04),
              blurRadius: 12, offset: const Offset(0, 4))]),
      child: ClipRRect(borderRadius: BorderRadius.circular(18),
          child: Column(children: children)));

  Widget _label(String text) => Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(text.toUpperCase(), style: TextStyle(fontSize: 11,
          fontWeight: FontWeight.w800, color: _txtH, letterSpacing: 1.2)));

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2)));
}

class _S {
  final String settings, appearance, darkMode, darkModeOn, lightModeOn,
      language, english, swahili,
      security, biometric, biometricDesc,
      changePIN, changePINDesc, changePassword, changePasswordDesc,
      comingSoon;
  const _S({
    required this.settings,    required this.appearance,
    required this.darkMode,    required this.darkModeOn,
    required this.lightModeOn, required this.language,
    required this.english,     required this.swahili,
    required this.security,    required this.biometric,
    required this.biometricDesc, required this.changePIN,
    required this.changePINDesc, required this.changePassword,
    required this.changePasswordDesc, required this.comingSoon,
  });
}

const _en = _S(
  settings: 'Settings',         appearance: 'Appearance',
  darkMode: 'Dark Mode',         darkModeOn: 'Dark mode is active',
  lightModeOn: 'Light mode is active',
  language: 'Language',          english: 'English',
  swahili: 'Swahili',            security: 'Security',
  biometric: 'Biometric Login',  biometricDesc: 'Fingerprint or Face ID unlock',
  changePIN: 'Change PIN',        changePINDesc: 'Update your 4-digit security PIN',
  changePassword: 'Change Password', changePasswordDesc: 'Update your account password',
  comingSoon: 'Coming soon',
);

const _sw = _S(
  settings: 'Mipangilio',        appearance: 'Muonekano',
  darkMode: 'Hali ya Giza',       darkModeOn: 'Hali ya giza imewashwa',
  lightModeOn: 'Hali ya mwanga imewashwa',
  language: 'Lugha',             english: 'Kiingereza',
  swahili: 'Kiswahili',           security: 'Usalama',
  biometric: 'Kuingia kwa Biometriki', biometricDesc: 'Fungua kwa alama ya kidole au uso',
  changePIN: 'Badilisha PIN',      changePINDesc: 'Sasisha PIN yako ya usalama',
  changePassword: 'Badilisha Nywila', changePasswordDesc: 'Sasisha nywila ya akaunti yako',
  comingSoon: 'Inakuja hivi karibuni',
);