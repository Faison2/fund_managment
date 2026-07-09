import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsl/constants/constants.dart';
import 'package:tsl/constants/secure_storage.dart';

class LoginRepository {
  // ── Login ──────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final requestBody = {
        'APIUsername': apiUsername,
        'APIPassword': apiPassword,
        'Username': username,
        'Password': password,
      };

      final ioClient = HttpClient()
        ..badCertificateCallback = (cert, host, port) => true;
      final client = IOClient(ioClient);

      final response = await client.post(
        Uri.parse('$cSharpApi/Userlogin'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      client.close();

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;

        if (responseData['status'] == 'success' &&
            responseData['statusDesc'] == 'Logged in') {
          final data = responseData['data'] as Map<String, dynamic>?;
          if (data != null) {
            return {
              'success':       true,
              'cdsNumber':     data['CDSNumber']     as String? ?? '',
              'accountStatus': data['accountStatus'] as String? ?? '',
              'email':         data['Email']         as String? ?? username,
              'nida':          data['NIDA']          as String? ?? '',
            };
          }
        }

        return {
          'success': false,
          'message': responseData['statusDesc'] ?? 'Unknown error',
        };
      } else {
        return {
          'success': false,
          'message': 'Server error (${response.statusCode})',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  // ── Save user data ─────────────────────────────────────────────────────────
  Future<void> saveUserData({
    required String cdsNumber,
    required String accountStatus,
    required String username,
    required bool rememberMe,
    String? email,
    String? nida,
  }) async {
    try {
      await SecureStorage.write('cdsNumber',     cdsNumber);
      await SecureStorage.write('accountStatus', accountStatus);
      await SecureStorage.write('username', username);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      if (email != null && email.isNotEmpty) {
        await SecureStorage.write('userEmail', email);
        await SecureStorage.write('user_email', email);
      }
      if (nida != null && nida.isNotEmpty) {
        await SecureStorage.write('userNIDA', nida);
      }

      if (rememberMe) {
        await SecureStorage.write('savedUsername', username);
        await prefs.setBool('rememberMe', true);
      } else {
        await SecureStorage.remove('savedUsername');
        await prefs.setBool('rememberMe', false);
      }
    } catch (e) {
      throw Exception('Error saving user data: $e');
    }
  }

  // ── Load saved credentials ─────────────────────────────────────────────────
  Future<Map<String, dynamic>> loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'rememberMe':    prefs.getBool('rememberMe') ?? false,
        'savedUsername': await SecureStorage.read('savedUsername'),
      };
    } catch (e) {
      return {
        'rememberMe':    false,
        'savedUsername': null,
      };
    }
  }

  // ── Get user data ──────────────────────────────────────────────────────────
  static Future<Map<String, String?>> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'cdsNumber':     await SecureStorage.read('cdsNumber'),
        'accountStatus': await SecureStorage.read('accountStatus'),
        'username':      await SecureStorage.read('username'),
        'isLoggedIn':    prefs.getBool('isLoggedIn')?.toString(),
        'nida':          await SecureStorage.read('userNIDA'),
      };
    } catch (e) {
      return {};
    }
  }

  // ── Clear user data ────────────────────────────────────────────────────────
  static Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await SecureStorage.remove('cdsNumber');
      await SecureStorage.remove('accountStatus');
      await SecureStorage.remove('username');
      await SecureStorage.remove('userNIDA');
      await prefs.setBool('isLoggedIn', false);
    } catch (e) {
      throw Exception('Error clearing user data: $e');
    }
  }
}