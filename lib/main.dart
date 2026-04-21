import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tsl/features/splash%20screen/initial_splash.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tsl/provider/locale_provider.dart';
import 'package:tsl/provider/theme_provider.dart';
import 'firebase_options.dart'; // ← ADD THIS

// ── Local notifications plugin instance ───────────────────────────────────────
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// ── Android notification channel ──────────────────────────────────────────────
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'This channel is used for important notifications.',
  importance: Importance.high,
);

// ── Background message handler (must be top-level) ────────────────────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // ← FIXED
  );
  debugPrint('Background message: ${message.messageId}');
}

// ── Notification service ──────────────────────────────────────────────────────
class NotificationService {
  static Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;

    // 1. Request permission
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('Permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('Notification permission denied.');
      return;
    }

    // 2. Get FCM token (wait for APNS token on iOS first)
    await _logFCMToken(messaging);

    // 3. Setup local notifications
    await _setupLocalNotifications();

    // 4. Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 5. App opened from background notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // 6. App opened from terminated state via notification
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  // Logs FCM token — waits for APNS token on iOS to avoid crash
  static Future<void> _logFCMToken(FirebaseMessaging messaging) async {
    try {
      String? token;

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        String? apnsToken;
        for (int i = 0; i < 10; i++) {
          apnsToken = await messaging.getAPNSToken();
          if (apnsToken != null) break;
          debugPrint('Waiting for APNS token... (${i + 1}/10)');
          await Future.delayed(const Duration(milliseconds: 500));
        }

        if (apnsToken == null) {
          debugPrint('APNS token not available — skipping FCM token fetch.');
          return;
        }

        token = await messaging.getToken();
      } else {
        token = await messaging.getToken();
      }

      debugPrint('FCM Token: $token');
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
    }
  }

  static Future<void> _setupLocalNotifications() async {
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification tapped: ${details.payload}');
      },
    );

    // Create Android high-importance channel
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Show notifications while app is in foreground on iOS
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      flutterLocalNotificationsPlugin.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  static void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('App opened from notification: ${message.data}');
  }
}

// ── Entry point ───────────────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // ← FIXED
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await NotificationService.initialize();

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

// ── Root app widget ───────────────────────────────────────────────────────────
class TSLApp extends StatelessWidget {
  const TSLApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();

    return MaterialApp(
      title: 'TSL',
      debugShowCheckedModeBanner: false,
      theme: ThemeProvider.light,
      darkTheme: ThemeProvider.dark,
      themeMode: themeProvider.themeMode,
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