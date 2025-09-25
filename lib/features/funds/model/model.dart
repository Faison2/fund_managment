// // models/fund.dart
// class Fund {
//   final String? fundingName;
//   final String? fundingCode;
//   final String? issuer;
//   final String? description;
//   final String? status;
//   final int? units;
//
//   Fund({
//     this.fundingName,
//     this.fundingCode,
//     this.issuer,
//     this.description,
//     this.status,
//     this.units,
//   });
//
//   factory Fund.fromJson(Map<String, dynamic> json) {
//     return Fund(
//       fundingName: json['fundingName'],
//       fundingCode: json['fundingCode'],
//       issuer: json['issuer'],
//       description: json['description'],
//       status: json['status'],
//       units: json['Units'],
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'fundingName': fundingName,
//       'fundingCode': fundingCode,
//       'issuer': issuer,
//       'description': description,
//       'status': status,
//       'Units': units,
//     };
//   }
// }
// models/fund.dart
class Fund {
  final String? fundingName;
  final String? fundingCode;
  final String? issuer;
  final String? description;
  final String? status;
  final int? units;

  Fund({
    this.fundingName,
    this.fundingCode,
    this.issuer,
    this.description,
    this.status,
    this.units,
  });

  factory Fund.fromJson(Map<String, dynamic> json) {
    return Fund(
      fundingName: json['fundingName'],
      fundingCode: json['fundingCode'],
      issuer: json['issuer'],
      description: json['description'],
      status: json['status'],
      units: _parseUnits(json['Units']),
    );
  }

  // Helper method to safely parse units (handles both String and int)
  static int? _parseUnits(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'fundingName': fundingName,
      'fundingCode': fundingCode,
      'issuer': issuer,
      'description': description,
      'status': status,
      'Units': units,
    };
  }
}