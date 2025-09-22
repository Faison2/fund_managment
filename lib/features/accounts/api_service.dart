import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://192.168.3.204/TSLFMSAPI/home';
  static const String apiUsername = 'User2';
  static const String apiPassword = 'CBZ1234#2';

  // Create account API call
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
    required String investmentPurpose,
    required String incomeSource,
    required String investmentAccountType,
    required String investorType,
    required String disclosure,
    required String positionHeld,
    required String bankType,
    required String bankAccountNumber,
    required String bankAccountName,
    required String bankName,
    required String bankBranch,
    required String bankSwiftCode,
    required String bankAddress,
    required String initialAmountInvested,
    required String amountSuppliedIn,
    required String serviceRequired,
    required String investmentPeriod,
    required String riskTolerance,
    required String charge,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/CreateAccount'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "APIUsername": apiUsername,
          "APIPassword": apiPassword,
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
          "IdentificatinType": identificationType,
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
            'message': 'Account created successfully'
          };
        } else {
          return {
            'success': false,
            'message': responseData['statusDesc'] ?? 'Unknown error occurred'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'HTTP error: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e'
      };
    }
  }

  // Helper method to format date from DD/MM/YYYY to YYYY-MM-DD
  static String formatDateForApi(String date) {
    try {
      final parts = date.split('/');
      if (parts.length == 3) {
        return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
      }
      return date;
    } catch (e) {
      return date;
    }
  }

  // Helper method to map UI identification types to API values
  static String mapIdentificationType(String uiType) {
    switch (uiType) {
      case 'National ID':
        return 'National ID';
      case 'Passport':
        return 'Passport';
      case 'Driver\'s License':
        return 'Driver\'s License';
      case 'Voter\'s ID':
        return 'Voter\'s ID';
      default:
        return uiType;
    }
  }
}