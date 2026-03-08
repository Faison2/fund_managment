import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tsl/constants/constants.dart';

class ApiService {
  static const String _apiUsername = 'User2';
  static const String _apiPassword = 'CBZ1234#2';
  static const String _createAccountUrl = '$cSharpApi/CreateAccount';

  /// Create an Individual Account.
  /// All fields now match the live API body exactly.
  static Future<Map<String, dynamic>> createIndividualAccount({
    required String title,
    required String firstName,
    required String surname,
    required String otherNames,
    required String dob,
    required String birthPlace,
    required String gender,
    required String occupation,
    required String nationality,
    required String identificationType,
    required String id,
    required String identificationExpiryDate,
    required String issuingAuthority,
    required String city,
    required String physicalAddress,
    required String country,
    required String email,
    required String mobileNumber,
    // ✅ Now required — captured from the form
    required String investmentPurpose,
    required String incomeSource,
    // ✅ Updated defaults: "Standard", "Individual"
    required String investmentAccountType,
    required String investorType,
    // ✅ Aligned to API: "Yes" / "No"
    required String disclosure,
    required String positionHeld,
    // ✅ Updated defaults: "Local"
    required String bankType,
    required String bankAccountNumber,
    required String bankAccountName,
    required String bankName,
    required String bankBranch,
    required String bankSwiftCode,
    required String bankAddress,
    required String initialAmountInvested,
    required String amountSuppliedIn,
    // ✅ Now required — captured from the form
    required String serviceRequired,
    required String investmentPeriod,
    required String riskTolerance,
    String charge = '0',
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_createAccountUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "APIUsername": _apiUsername,
          "APIPassword": _apiPassword,
          "AccountType": "Individual",
          "Title": title,
          "JointName": "",
          "FirstName": firstName,
          "Surname": surname,
          "OtherNames": otherNames,
          "DOB": dob,
          "BirthPlace": birthPlace,
          "Gender": gender,
          "Occupation": occupation,
          "Nationality": nationality,
          "IdentificatinType": identificationType, // note: typo preserved from API
          "ID": id,
          "IdentificationExpiryDate": identificationExpiryDate,
          "IssuingAuthority": issuingAuthority,
          "City": city,
          "PhysicalAddress": physicalAddress,
          "Country": country,
          "Email": email,
          "MobileNumber": mobileNumber,
          "InvestmentPurpose": investmentPurpose,
          "IncomeSource": incomeSource,
          "InvestmentAccountType": investmentAccountType,
          "InvestorType": investorType,
          "Disclosure": disclosure,
          "PositionHeld": positionHeld,
          "BankType": bankType,
          "BankAccountNumber": bankAccountNumber,
          "BankAccountName": bankAccountName,
          "BankName": bankName,
          "BankBranch": bankBranch,
          "BankSwiftCode": bankSwiftCode,
          "BankAddress": bankAddress,
          "InitialAmountInvested": initialAmountInvested,
          "AmountSuppliedIn": amountSuppliedIn,
          "ServiceRequired": serviceRequired,
          "InvestmentPeriod": investmentPeriod,
          "RiskTolerance": riskTolerance,
          "Charge": charge,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 200) {
          return {
            'success': true,
            'cdsNumber': responseData['data']['CDSNumber'],
            'message': 'Account created successfully',
          };
        }
        return {
          'success': false,
          'message': responseData['statusDesc'] ?? 'Unknown error',
        };
      }

      return {
        'success': false,
        'message': 'HTTP error: ${response.statusCode}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  /// Converts DD/MM/YYYY → YYYY-MM-DD for the API.
  static String formatDateForApi(String date) {
    try {
      final parts = date.split('/');
      if (parts.length == 3) {
        return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
      }
      return date;
    } catch (_) {
      return date;
    }
  }

  /// Maps UI identification type labels to API values (1-to-1 for now).
  static String mapIdentificationType(String uiType) {
    const map = {
      'National ID': 'National ID',
      'Passport': 'Passport',
      "Driver's License": "Driver's License",
      "Voter's ID": "Voter's ID",
    };
    return map[uiType] ?? uiType;
  }

  /// Maps boolean PEP flag to the API "Yes" / "No" string.
  static String mapDisclosure(bool isPoliticallyExposed) =>
      isPoliticallyExposed ? 'Yes' : 'No';
}