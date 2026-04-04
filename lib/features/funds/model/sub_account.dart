class SubAccount {
  final String id;
  final String fundingCode;
  final String accountNumber;
  final String status;
  final DateTime createdAt;

  const SubAccount({
    required this.id,
    required this.fundingCode,
    required this.accountNumber,
    required this.status,
    required this.createdAt,
  });

  factory SubAccount.fromJson(Map<String, dynamic> json) => SubAccount(
    id:            json['id'] as String,
    fundingCode:   json['funding_code'] as String,
    accountNumber: json['account_number'] as String,
    status:        json['status'] as String,
    createdAt:     DateTime.parse(json['created_at'] as String),
  );
}