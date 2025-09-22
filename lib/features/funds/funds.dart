import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FundsScreen extends StatefulWidget {
  const FundsScreen({Key? key}) : super(key: key);

  @override
  State<FundsScreen> createState() => _FundsScreenState();
}

class _FundsScreenState extends State<FundsScreen> {
  late Future<List<dynamic>> _fundsFuture;

  Future<List<dynamic>> fetchFunds() async {
    const url = "http://192.168.3.204/TSLFMSAPI/home/GetFunds";
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
        return jsonData["data"];
      } else {
        throw Exception("Failed: ${jsonData['statusDesc']}");
      }
    } else {
      throw Exception("Failed to fetch funds. Status code: ${response.statusCode}");
    }
  }

  @override
  void initState() {
    super.initState();
    _fundsFuture = fetchFunds();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB8E6D3),
      appBar: AppBar(
        title: const Text("Available Funds", style: TextStyle(color: Colors.white),),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: SafeArea(
        child: FutureBuilder<List<dynamic>>(
          future: _fundsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.green));
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("No funds available."));
            }

            final funds = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: funds.length,
              itemBuilder: (context, index) {
                final fund = funds[index];
                return Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF81C784), Color(0xFFB2DFDB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fund["fundingName"] ?? "",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Code: ${fund['fundingCode']}",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          "Issuer: ${fund['issuer']}",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          "Description: ${fund['description']}",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Chip(
                              label: Text(
                                fund["status"] ?? "",
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.green.shade700,
                            ),
                            Text(
                              "${fund['Units']} Units",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
