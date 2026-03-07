// lib/core/theme/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── TSL Design Tokens ─────────────────────────────────────────────────────────
class TSLColors {
  TSLColors._();

  // Brand greens
  static const green900 = Color(0xFF1B5E20);
  static const green700 = Color(0xFF2E7D32);
  static const green500 = Color(0xFF4CAF50);
  static const green300 = Color(0xFF81C784);
  static const green100 = Color(0xFFE8F5E9);

  // ── Light palette ──────────────────────────────────────────────────────
  static const lightBg       = Color(0xFFF0FBF5);
  static const lightSurface  = Color(0xFFFFFFFF);
  static const lightCard     = Color(0xFFFFFFFF);
  static const lightBorder   = Color(0xFFE5E7EB);
  static const lightTextPrim = Color(0xFF111827);
  static const lightTextSec  = Color(0xFF6B7280);
  static const lightTextHint = Color(0xFF9CA3AF);
  static const lightDivider  = Color(0xFFF3F4F6);

  // ── Dark palette ───────────────────────────────────────────────────────
  static const darkBg        = Color(0xFF09100A);
  static const darkSurface   = Color(0xFF111812);
  static const darkCard      = Color(0xFF162016);
  static const darkCard2     = Color(0xFF1C2B1C);
  static const darkBorder    = Color(0xFF243324);
  static const darkTextPrim  = Color(0xFFF0FFF4);
  static const darkTextSec   = Color(0xFF86EFAC);
  static const darkTextHint  = Color(0xFF4ADE80);
  static const darkDivider   = Color(0xFF1C2B1C);
}

// ── ThemeProvider ─────────────────────────────────────────────────────────────
class ThemeProvider extends ChangeNotifier {
  static const _prefKey = 'app_theme_dark';

  bool _isDark = false;
  bool      get isDark    => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider() { _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool(_prefKey) ?? false;
    notifyListeners();
  }

  Future<void> setDark(bool value) async {
    if (_isDark == value) return;
    _isDark = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, _isDark);
    notifyListeners();
  }

  Future<void> toggle() => setDark(!_isDark);

  // ── Light ThemeData ──────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: TSLColors.green700,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: TSLColors.lightBg,
    cardColor: TSLColors.lightCard,
    dividerColor: TSLColors.lightDivider,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFB8E6D3),
      foregroundColor: TSLColors.lightTextPrim,
      elevation: 0,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
      s.contains(WidgetState.selected) ? TSLColors.green700 : Colors.white),
      trackColor: WidgetStateProperty.resolveWith((s) =>
      s.contains(WidgetState.selected) ? TSLColors.green300 : Colors.grey.shade300),
    ),
  );

  // ── Dark ThemeData ───────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: TSLColors.green500,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: TSLColors.darkBg,
    cardColor: TSLColors.darkCard,
    dividerColor: TSLColors.darkDivider,
    appBarTheme: const AppBarTheme(
      backgroundColor: TSLColors.darkSurface,
      foregroundColor: TSLColors.darkTextPrim,
      elevation: 0,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
      s.contains(WidgetState.selected) ? TSLColors.green500 : Colors.grey.shade600),
      trackColor: WidgetStateProperty.resolveWith((s) =>
      s.contains(WidgetState.selected) ? TSLColors.green900 : Colors.grey.shade800),
    ),
  );
}