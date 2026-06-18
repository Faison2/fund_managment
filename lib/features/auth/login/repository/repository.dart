import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsl/constants/constants.dart';

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
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('cdsNumber',     cdsNumber);
      await prefs.setString('accountStatus', accountStatus);
      await prefs.setString('username',      username);
      await prefs.setBool('isLoggedIn',      true);

      if (email != null && email.isNotEmpty) {
        await prefs.setString('userEmail', email);
      }
      if (nida != null && nida.isNotEmpty) {
        await prefs.setString('userNIDA', nida);
      }

      if (rememberMe) {
        await prefs.setString('savedUsername', username);
        await prefs.setBool('rememberMe', true);
      } else {
        await prefs.remove('savedUsername');
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
        'rememberMe':    prefs.getBool('rememberMe')       ?? false,
        'savedUsername': prefs.getString('savedUsername'),
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
        'cdsNumber':     prefs.getString('cdsNumber'),
        'accountStatus': prefs.getString('accountStatus'),
        'username':      prefs.getString('username'),
        'isLoggedIn':    prefs.getBool('isLoggedIn')?.toString(),
        'nida':          prefs.getString('userNIDA'),
      };
    } catch (e) {
      return {};
    }
  }

  // ── Clear user data ────────────────────────────────────────────────────────
  static Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cdsNumber');
      await prefs.remove('accountStatus');
      await prefs.remove('username');
      await prefs.remove('userNIDA');
      await prefs.setBool('isLoggedIn', false);
    } catch (e) {
      throw Exception('Error clearing user data: $e');
    }
  }
}