class Fund {
  final String? fundingName;
  final String? fundingCode;
  final String? issuer;
  final String? description;
  final String? status;
  final int? units;

  const Fund({
    this.fundingName,
    this.fundingCode,
    this.issuer,
    this.description,
    this.status,
    this.units,
  });

  factory Fund.fromJson(Map<String, dynamic> json) {
    return Fund(
      // Try multiple casing variants the API might send
      fundingName: _str(json['fundingName'] ?? json['FundingName'] ?? json['funding_name']),
      fundingCode: _str(json['fundingCode'] ?? json['FundingCode'] ?? json['funding_code']),
      issuer:      _str(json['issuer']      ?? json['Issuer']),
      description: _str(json['description'] ?? json['Description']),
      status:      _str(json['status']      ?? json['Status']),
      units:       _parseInt(json['Units']  ?? json['units']),
    );
  }

  static String? _str(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }

  Map<String, dynamic> toJson() => {
    'fundingName': fundingName,
    'fundingCode': fundingCode,
    'issuer':      issuer,
    'description': description,
    'status':      status,
    'Units':       units,
  };
}