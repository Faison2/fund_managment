enum Environment { uat, production }

class EnvironmentConfig {
  static const Environment currentEnvironment = Environment.production;
  //static const Environment currentEnvironment = Environment.uat;

  static const Map<Environment, String> apiBaseUrls = {
  Environment.uat: 'https://portaluat.tsl.co.tz/FMSAPI/Home',
    Environment.production: 'https://portalprod.tsl.co.tz/FMSAPI/Home',
  };

  static const Map<Environment, String> apiUsernames = {
    Environment.uat: 'User2',
    Environment.production: 'User2',
  };

  static const Map<Environment, String> apiPasswords = {
    Environment.uat: 'CBZ1234#2',
    Environment.production: 'CBZ1234#2',
  };

  static String get apiBaseUrl => apiBaseUrls[currentEnvironment]!;
  static String get apiUsername => apiUsernames[currentEnvironment]!;
  static String get apiPassword => apiPasswords[currentEnvironment]!;
  static String get environmentName => currentEnvironment.toString().split('.').last.toUpperCase();
}

