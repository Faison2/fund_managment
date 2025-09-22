import 'package:http/http.dart' as http;
import 'dart:convert';

class Bank {
  final String bankName;
  final String bankCode;

  Bank({required this.bankName, required this.bankCode});

  factory Bank.fromJson(Map<String, dynamic> json) {
    return Bank(
      bankName: json['bankName'] ?? '', // Changed from 'BankName' to 'bankName'
      bankCode: json['bankCode'] ?? '', // Changed from 'BankCode' to 'bankCode'
    );
  }
}

class BankController {
  List<Bank> banks = [];
  String? selectedBank;
  bool isLoading = false;

  Future<void> loadBanks({
    required String apiUrl,
    required String username,
    required String password,
  }) async {
    isLoading = true;

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "APIUsername": username,
          "APIPassword": password,
        }),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Parsed response data: $responseData');

        if (responseData is Map<String, dynamic>) {
          final status = responseData['status'];
          print('API Status: $status');

          // Handle string status "success" instead of integer 200
          if (status == "success" || status == 200) {
            if (responseData['data'] != null && responseData['data'] is List) {
              banks = (responseData['data'] as List)
                  .map((bankJson) => Bank.fromJson(bankJson))
                  .toList();
              print('Successfully loaded ${banks.length} banks');

              // Clear any previously selected bank that might not exist in new list
              if (selectedBank != null && !banks.any((bank) => bank.bankName == selectedBank)) {
                selectedBank = null;
              }
            } else {
              throw Exception('Invalid data format: data is not a list or is null');
            }
          } else {
            final statusDesc = responseData['statusDesc'] ?? 'Unknown error';
            throw Exception('API Error: $statusDesc (Status: $status)');
          }
        } else {
          throw Exception('Invalid response format: not a JSON object');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in loadBanks: $e');
      rethrow;
    } finally {
      isLoading = false;
    }
  }

  void selectBank(String? bankName) {
    selectedBank = bankName;
  }
}