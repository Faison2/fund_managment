import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tsl/constants/constants.dart';

import '../model/model.dart';
import '../model/sub_account.dart';

class FundsRepository {
  Future<List<Fund>> fetchFunds() async {
    const url = "$cSharpApi/GetFunds";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "APIUsername": "User2",
          "APIPassword": "CBZ1234#2",
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData["status"] == "success") {
          final dynamic raw = jsonData["data"];

          if (raw == null) return [];

          if (raw is! List) {
            throw Exception("Unexpected funds format: ${raw.runtimeType}");
          }

          return raw
              .whereType<Map<String, dynamic>>()
              .map((fundJson) => Fund.fromJson(fundJson))
              .toList();
        } else {
          throw Exception(jsonData['statusDesc'] ?? 'Unknown error');
        }
      } else {
        throw Exception("HTTP ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Network error: $e");
    }
  }

  Future<SubAccount> createSubAccounts({
    required String cdsNo,
    required List<SubAccountEntry> subAccounts,
  }) async {
    const url = "$cSharpApi/CreateSubAccounts";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "APIUsername": "User2",
          "APIPassword": "CBZ1234#2",
          "cdsNo": cdsNo,
          "SubAccountsList": subAccounts.map((e) => e.toJson()).toList(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);

        if (jsonData["status"] == "success") {
          return SubAccount.fromJson(jsonData);
        } else {
          throw Exception(jsonData['statusDesc'] ?? 'Subscription failed');
        }
      } else {
        throw Exception("HTTP ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("$e");
    }
  }
}

/// Represents a single entry in the SubAccountsList payload.
class SubAccountEntry {
  final String fundingCode;
  final String fundingName;

  const SubAccountEntry({
    required this.fundingCode,
    required this.fundingName,
  });

  Map<String, dynamic> toJson() => {
    "Funding_Code": fundingCode,
    "Funding_Name": fundingName,
  };
}