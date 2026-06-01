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
          final List<dynamic> data = jsonData["data"];
          if (data.isNotEmpty) {
            print("First item Units field: ${data[0]['Units']} (${data[0]['Units'].runtimeType})");
          }
          return data.map((fundJson) => Fund.fromJson(fundJson)).toList();
        } else {
          throw Exception("Failed: ${jsonData['statusDesc']}");
        }
      } else {
        throw Exception("Failed to fetch funds. Status code: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Network error: $e");
    }
  }

  /// Creates sub-accounts for a given CDS number.
  /// [cdsNo] - the client's CDS number
  /// [subAccounts] - list of funds to subscribe to (Funding_Code + Funding_Name)
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
        final jsonData = jsonDecode(response.body);

        if (jsonData["status"] == "success") {
          return SubAccount.fromJson(jsonData["data"]);
        } else {
          throw Exception("Failed: ${jsonData['statusDesc']}");
        }
      } else {
        throw Exception("Failed to create sub-accounts. Status code: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Network error: $e");
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