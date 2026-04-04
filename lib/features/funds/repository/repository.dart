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

  Future<SubAccount> subscribeToFund({
    required String fundingCode,
    required String authToken,
  }) async {
    // TODO: replace with your real endpoint
    const url = "$cSharpApi/SubscribeToFund";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $authToken",
        },
        body: jsonEncode({
          "APIUsername": "User2",
          "APIPassword": "CBZ1234#2",
          "FundingCode": fundingCode,
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
        throw Exception(
            "Failed to subscribe. Status code: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Network error: $e");
    }
  }
}