import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'features/splash screen/splash.dart';


void main() {
  runApp(const TSLApp());
}

class TSLApp extends StatelessWidget {
  const TSLApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TSL',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const SplashScreen(),
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


