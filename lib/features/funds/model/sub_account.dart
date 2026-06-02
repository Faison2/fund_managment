class SubAccount {
  final List<String> accountNumbers;
  final String status;

  const SubAccount({
    required this.accountNumbers,
    required this.status,
  });

  factory SubAccount.fromJson(Map<String, dynamic> json) {
    // Debug — remove after confirming
    print("SubAccount.fromJson input: $json");

    final dynamic data = json['data'];
    print("data field: $data (${data.runtimeType})");

    List<String> numbers = [];

    if (data is List) {
      numbers = data
          .where((e) => e != null)
          .map((e) => e.toString())
          .toList();
    } else if (data is String && data.isNotEmpty) {
      numbers = [data];
    }

    print("Parsed accountNumbers: $numbers");

    return SubAccount(
      accountNumbers: numbers,
      status: json['status']?.toString() ?? '',
    );
  }

  factory SubAccount.empty() => const SubAccount(
    accountNumbers: [],
    status: 'Pending',
  );

  /// Joins all account numbers for display
  String get accountNumber =>
      accountNumbers.isNotEmpty ? accountNumbers.join(', ') : 'N/A';
}