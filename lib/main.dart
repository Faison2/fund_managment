import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tsl/features/splash%20screen/initial_splash.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tsl/provider/locale_provider.dart';
import 'package:tsl/provider/theme_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const TSLApp(),
    ),
  );
}

class TSLApp extends StatelessWidget {
  const TSLApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider  = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();

    return MaterialApp(
      title: 'TSL',
      debugShowCheckedModeBanner: false,

      // ── Themes ──────────────────────────────────────────────────────────
      theme:     ThemeProvider.light,
      darkTheme: ThemeProvider.dark,
      themeMode: themeProvider.themeMode,

      // ── Locale ──────────────────────────────────────────────────────────
      locale: localeProvider.locale,
      supportedLocales: LocaleProvider.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      home: const InitialSplashScreen(),

      builder: (context, child) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        return child!;
      },
    );
  }
}
