import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsl/constants/constants.dart';

class LoginRepository {
  static const String apiUrl = '$cSharpApi/Userlogin';
  static const String apiUsername = 'User2';
  static const String apiPassword = 'CBZ1234#2';

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

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;

        // Check for new response format
        if (responseData['status'] == 'success' && responseData['statusDesc'] == 'Logged in') {
          final data = responseData['data'] as Map<String, dynamic>?;
          if (data != null) {
            return {
              'success': true,
              'cdsNumber': data['CDSNumber'] as String? ?? '',
              'accountStatus': data['accountStatus'] as String? ?? '',
            };
          }
        }
        // Check for old response format
        else if (responseData['status'] == 200 && responseData['statusDesc'] == 'success') {
          return {
            'success': true,
            'cdsNumber': '', // Not available in old format
            'accountStatus': 'Active',
          };
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

  Future<void> saveUserData({
    required String cdsNumber,
    required String accountStatus,
    required String username,
    required bool rememberMe,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('cdsNumber', cdsNumber);
      await prefs.setString('accountStatus', accountStatus);
      await prefs.setString('username', username);
      await prefs.setBool('isLoggedIn', true);

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

  Future<Map<String, dynamic>> loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool('rememberMe') ?? false;
      final savedUsername = prefs.getString('savedUsername');

      return {
        'rememberMe': rememberMe,
        'savedUsername': savedUsername,
      };
    } catch (e) {
      return {
        'rememberMe': false,
        'savedUsername': null,
      };
    }
  }

  static Future<Map<String, String?>> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'cdsNumber': prefs.getString('cdsNumber'),
        'accountStatus': prefs.getString('accountStatus'),
        'username': prefs.getString('username'),
        'isLoggedIn': prefs.getBool('isLoggedIn')?.toString(),
      };
    } catch (e) {
      return {};
    }
  }

  static Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cdsNumber');
      await prefs.remove('accountStatus');
      await prefs.remove('username');
      await prefs.setBool('isLoggedIn', false);
    } catch (e) {
      throw Exception('Error clearing user data: $e');
    }
  }
}