import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tsl/constants/constants.dart';

import '../model/model.dart';


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
}