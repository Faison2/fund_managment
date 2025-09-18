import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tsl/constants/constants.dart';

// Bank model class
class Bank {
  final String bankName;
  final String bankCode;

  Bank({required this.bankName, required this.bankCode});

  factory Bank.fromJson(Map<String, dynamic> json) {
    return Bank(
      bankName: json['bankName'] ?? '',
      bankCode: json['bankCode'] ?? '',
    );
  }
}

// API response model
class BankApiResponse {
  final int status;
  final String statusDesc;
  final List<Bank> data;

  BankApiResponse({
    required this.status,
    required this.statusDesc,
    required this.data,
  });

  factory BankApiResponse.fromJson(Map<String, dynamic> json) {
    var dataList = json['data'] as List;
    List<Bank> banks = dataList.map((item) => Bank.fromJson(item)).toList();

    return BankApiResponse(
      status: json['status'] ?? 0,
      statusDesc: json['statusDesc'] ?? '',
      data: banks,
    );
  }
}

class BankService {
  static const String baseUrl = '$cSharpApi/GetBanks';
  static const String apiUsername = 'User2';
  static const String apiPassword = 'CBZ1234#2';

  // Fetch banks from API
  static Future<BankApiResponse> fetchBanks() async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'APIUsername': apiUsername,
          'APIPassword': apiPassword,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return BankApiResponse.fromJson(responseData);
      } else {
        throw Exception('Failed to load banks. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch banks: $e');
    }
  }
}