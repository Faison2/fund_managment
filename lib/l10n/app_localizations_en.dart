// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'TSL';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get swahili => 'Kiswahili';

  @override
  String get hello => 'Hello';

  @override
  String get welcome => 'Welcome';

  @override
  String get appName => 'TSL Investment App';

  @override
  String get appTagline => 'SECURITIES  ·  BROKERAGE  ·  WEALTH';

  @override
  String get compliance => 'CMSA Licensed  ·  DSE Member  ·  BOT Regulated';

  @override
  String get home => 'Home';

  @override
  String get funds => 'Funds';

  @override
  String get portfolio => 'Portfolio';

  @override
  String get profile => 'Profile';

  @override
  String get myOrders => 'My Orders';

  @override
  String get paymentMethods => 'Payment Methods';

  @override
  String get deposit => 'Deposit';

  @override
  String get withdrawal => 'Withdrawal';

  @override
  String get clientStatement => 'Client Statement';

  @override
  String get multicurrency => 'Multicurrency';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get about => 'About';

  @override
  String get feedback => 'Feedback';

  @override
  String get logout => 'Logout';

  @override
  String get cancel => 'Cancel';

  @override
  String get logoutConfirm => 'Are you sure you want to logout?';

  @override
  String comingSoon(Object feature) {
    return '$feature - Coming Soon!';
  }

  @override
  String get myOrdersComingSoon => 'My Orders - Coming Soon!';

  @override
  String get helpComingSoon => 'Help & Support - Coming Soon!';

  @override
  String get feedbackComingSoon => 'Feedback - Coming Soon!';
}
