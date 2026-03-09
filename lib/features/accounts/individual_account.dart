import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsl/constants/constants.dart';

import '../accounts/api_service/bank_controller.dart';
import '../auth/login/view/login.dart';

// ─── Comma-separator formatter ────────────────────────────────────────────────
class _ThousandsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final raw = newValue.text.replaceAll(',', '');
    if (raw.isEmpty) return newValue;
    final parts = raw.split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? '.${parts[1]}' : '';
    final formatted = intPart.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
    );
    final result = '$formatted$decPart';
    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}

class IndividualAccountScreen extends StatefulWidget {
  const IndividualAccountScreen({Key? key}) : super(key: key);

  @override
  State<IndividualAccountScreen> createState() =>
      _IndividualAccountScreenState();
}

class _IndividualAccountScreenState extends State<IndividualAccountScreen>
    with TickerProviderStateMixin {
  final BankController _bankController = BankController();
  final String _apiUrl = "$cSharpApi/CreateAccount";
  final String _getBanksUrl = "$cSharpApi/GetBanks";
  final String _apiUsername = "User2";
  final String _apiPassword = "CBZ1234#2";

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // ─── Controllers ─────────────────────────────────────────────────────────────
  final TextEditingController _titleController =
  TextEditingController(text: "Mr");
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  final TextEditingController _placeOfBirthController =
  TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _identificationNumberController =
  TextEditingController();
  final TextEditingController _validityDateController =
  TextEditingController();
  final TextEditingController _issuingAuthorityController =
  TextEditingController(); // used for non-TZ custom entry

  // Address
  final TextEditingController _houseNumberController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _wardController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _physicalAddressController =
  TextEditingController();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _fundsSourceController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _investmentPurposeController =
  TextEditingController();

  // Bank
  final TextEditingController _accountNumberController =
  TextEditingController();
  final TextEditingController _accountHolderNameController =
  TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _branchController = TextEditingController();
  final TextEditingController _swiftCodeController = TextEditingController();
  final TextEditingController _bankSearchController = TextEditingController();

  // Investment
  final TextEditingController _initialAmountController =
  TextEditingController();

  // ─── Form State ───────────────────────────────────────────────────────────────
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isPoliticallyExposed = false;

  String _selectedIdType = 'National ID';
  String _selectedPaymentMethod = 'Cash';
  String _selectedGender = 'Male';
  // FIX #6 – only Individual / Minor
  String _selectedAccountType = 'Individual';
  String _selectedBankType = 'Local';
  String _selectedAmountCurrency = 'TZS';
  String? _cdsNumber;

  // FIX #1 – Nationality dropdown
  String _selectedNationality = '';
  // FIX #1 – Issuing authority dropdown (Tanzania)
  String _selectedIssuingAuthority = '';

  // FIX #2 – Country dropdown for address
  String _selectedCountry = '';
  // FIX #2 – Tanzania sub-fields
  String _selectedRegion = '';
  String _selectedDistrict = '';

  // FIX #8 – Source of funds dropdown
  String _selectedSourceOfFunds = '';

  // Inline errors (#9)
  final Map<String, String?> _errors = {};

  // ID Upload
  File? _idFile;
  String? _idFileName;
  String? _idFileExtension;

  // ─── Static Data ─────────────────────────────────────────────────────────────

  // Common countries list (abbreviated – extend as needed)
  static const List<String> _countries = [
    'Tanzania',
    'Kenya',
    'Uganda',
    'Rwanda',
    'Burundi',
    'South Africa',
    'Zimbabwe',
    'Zambia',
    'Malawi',
    'Mozambique',
    'Ethiopia',
    'Nigeria',
    'Ghana',
    'Egypt',
    'United Kingdom',
    'United States',
    'Germany',
    'France',
    'China',
    'India',
    'Other',
  ];

  // Common nationalities
  static const List<String> _nationalities = [
    'Tanzanian',
    'Kenyan',
    'Ugandan',
    'Rwandan',
    'Burundian',
    'South African',
    'Zimbabwean',
    'Zambian',
    'Malawian',
    'Mozambican',
    'Ethiopian',
    'Nigerian',
    'Ghanaian',
    'Egyptian',
    'British',
    'American',
    'German',
    'French',
    'Chinese',
    'Indian',
    'Other',
  ];

  // FIX #1 – Tanzania issuing authorities
  static const List<String> _tzIssuingAuthorities = [
    'NIDA',
    'TRA',
    'NEC',
    'ZCSRA',
  ];

  // FIX #2 – Tanzania regions
  static const List<String> _tanzaniaRegions = [
    'Arusha',
    'Dar es Salaam',
    'Dodoma',
    'Geita',
    'Iringa',
    'Kagera',
    'Katavi',
    'Kigoma',
    'Kilimanjaro',
    'Lindi',
    'Manyara',
    'Mara',
    'Mbeya',
    'Morogoro',
    'Mtwara',
    'Mwanza',
    'Njombe',
    'Pemba North',
    'Pemba South',
    'Pwani',
    'Rukwa',
    'Ruvuma',
    'Shinyanga',
    'Simiyu',
    'Singida',
    'Songwe',
    'Tabora',
    'Tanga',
    'Zanzibar North',
    'Zanzibar South',
    'Zanzibar West',
  ];

  static const Map<String, List<String>> _tanzaniaDistricts = {
    'Arusha': [
      'Arusha City',
      'Arusha DC',
      'Karatu',
      'Longido',
      'Monduli',
      'Ngorongoro'
    ],
    'Dar es Salaam': [
      'Ilala',
      'Kinondoni',
      'Temeke',
      'Ubungo',
      'Kigamboni'
    ],
    'Dodoma': [
      'Dodoma City',
      'Bahi',
      'Chamwino',
      'Chemba',
      'Kondoa',
      'Kongwa',
      'Mpwapwa'
    ],
    'Geita': [
      'Geita DC',
      'Geita Town',
      'Bukombe',
      'Chato',
      'Mbogwe',
      "Nyang'hwale"
    ],
    'Iringa': [
      'Iringa DC',
      'Iringa Municipal',
      'Kilolo',
      'Mafinga Town'
    ],
    'Kagera': [
      'Bukoba DC',
      'Bukoba Municipal',
      'Biharamulo',
      'Karagwe',
      'Kyerwa',
      'Missenyi',
      'Muleba',
      'Ngara'
    ],
    'Katavi': ['Mlele', 'Mpanda DC', 'Mpanda Town'],
    'Kigoma': [
      'Kigoma DC',
      'Kigoma-Ujiji Municipal',
      'Buhigwe',
      'Kakonko',
      'Kasulu DC',
      'Kasulu Town',
      'Kibondo',
      'Uvinza'
    ],
    'Kilimanjaro': [
      'Moshi DC',
      'Moshi Municipal',
      'Hai',
      'Mwanga',
      'Rombo',
      'Same',
      'Siha'
    ],
    'Lindi': [
      'Lindi DC',
      'Lindi Municipal',
      'Kilwa',
      'Liwale',
      'Nachingwea',
      'Ruangwa'
    ],
    'Manyara': [
      'Babati DC',
      'Babati Town',
      'Hanang',
      'Kiteto',
      'Mbulu',
      'Simanjiro'
    ],
    'Mara': [
      'Musoma DC',
      'Musoma Municipal',
      'Bunda',
      'Butiama',
      'Rorya',
      'Serengeti',
      'Tarime DC',
      'Tarime Town'
    ],
    'Mbeya': [
      'Mbeya City',
      'Mbeya DC',
      'Busokelo',
      'Chunya',
      'Kyela',
      'Rungwe'
    ],
    'Morogoro': [
      'Morogoro DC',
      'Morogoro Municipal',
      'Gairo',
      'Ifakara Town',
      'Kilombero',
      'Kilosa',
      'Malinyi',
      'Mvomero',
      'Ulanga'
    ],
    'Mtwara': [
      'Mtwara DC',
      'Mtwara Municipal',
      'Masasi DC',
      'Masasi Town',
      'Nanyumbu',
      'Newala',
      'Tandahimba'
    ],
    'Mwanza': [
      'Mwanza City',
      'Ilemela',
      'Kwimba',
      'Magu',
      'Misungwi',
      'Nyamagana',
      'Sengerema',
      'Ukerewe'
    ],
    'Njombe': [
      'Njombe DC',
      'Njombe Town',
      'Ludewa',
      'Makete',
      "Wanging'ombe"
    ],
    'Pemba North': ['Micheweni', 'Wete'],
    'Pemba South': ['Chake Chake', 'Mkoani'],
    'Pwani': [
      'Kibaha DC',
      'Kibaha Town',
      'Bagamoyo',
      'Mafia',
      'Mkuranga',
      'Rufiji'
    ],
    'Rukwa': ['Sumbawanga DC', 'Sumbawanga Municipal', 'Kalambo', 'Nkasi'],
    'Ruvuma': [
      'Songea DC',
      'Songea Municipal',
      'Mbinga DC',
      'Mbinga Town',
      'Namtumbo',
      'Nyasa',
      'Tunduru'
    ],
    'Shinyanga': [
      'Shinyanga DC',
      'Shinyanga Municipal',
      'Kahama DC',
      'Kahama Town',
      'Kishapu'
    ],
    'Simiyu': [
      'Bariadi DC',
      'Bariadi Town',
      'Busega',
      'Itilima',
      'Maswa',
      'Meatu'
    ],
    'Singida': [
      'Singida DC',
      'Singida Municipal',
      'Ikungi',
      'Iramba',
      'Manyoni',
      'Mkalama'
    ],
    'Songwe': ['Mbozi', 'Momba', 'Songwe DC', 'Tunduma Town'],
    'Tabora': [
      'Tabora Municipal',
      'Igunga',
      'Kaliua',
      'Nzega DC',
      'Nzega Town',
      'Sikonge',
      'Urambo',
      'Uyui'
    ],
    'Tanga': [
      'Tanga City',
      'Handeni DC',
      'Handeni Town',
      'Kilindi',
      'Korogwe DC',
      'Korogwe Town',
      'Lushoto',
      'Mkinga',
      'Muheza',
      'Pangani'
    ],
    'Zanzibar North': ['Kaskazini A', 'Kaskazini B'],
    'Zanzibar South': ['Kati', 'Kusini'],
    'Zanzibar West': ['Magharibi', 'Mjini'],
  };

  // FIX #8 – Source of funds options
  static const List<String> _sourcesOfFunds = [
    'Employment / Salary',
    'Business Income',
    'Investments / Dividends',
    'Inheritance',
    'Property Sale',
    'Savings',
    'Pension / Retirement',
    'Gift / Donation',
    'Loan',
    'Other',
  ];

  // FIX #6 – Account types limited to Individual and Minor
  final List<String> _accountTypes = ['Individual', 'Minor'];

  final List<String> _identificationTypes = [
    'National ID',
    'Passport',
    "Driver's License",
    "Voter's ID",
  ];
  final List<String> _genders = ['Male', 'Female'];
  final List<String> _titles = ['Mr', 'Mrs', 'Miss', 'Dr', 'Prof'];
  final List<String> _paymentMethods = [
    'Cash',
    'Cheque',
    'Direct Fund Transfer',
  ];
  final List<String> _bankTypes = ['Local', 'Savings', 'Current', 'Corporate'];
  final List<String> _currencies = ['TZS', 'USD', 'ZWL', 'EUR', 'GBP'];

  // FIX #7 – Removed "Investment Preferences" step entirely
  final List<Map<String, dynamic>> _steps = [
    {'title': 'Personal Info', 'icon': Icons.person_outline_rounded},
    {'title': 'Identification', 'icon': Icons.badge_outlined},
    {'title': 'Address', 'icon': Icons.location_on_outlined},
    {'title': 'Bank Details', 'icon': Icons.account_balance_outlined},
    {'title': 'Investment', 'icon': Icons.trending_up_rounded},
    {'title': 'Final Details', 'icon': Icons.checklist_rounded},
  ];

  // ─── Theme Colors ─────────────────────────────────────────────────────────────
  static const Color _primaryGreen = Color(0xFF2DC98E);
  static const Color _deepGreen = Color(0xFF1A9B6C);
  static const Color _softMint = Color(0xFFE8FBF4);
  static const Color _cardBg = Colors.white;
  static const Color _textDark = Color(0xFF1A2332);
  static const Color _textMuted = Color(0xFF8A9BB0);
  static const Color _errorRed = Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _loadBanks();
  }

  Future<void> _saveCDSNumber(String cdsNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cds_number', cdsNumber);
      await prefs.setString('user_email', _emailController.text);
      await prefs.setString('user_phone', _phoneController.text);
      await prefs.setString('user_first_name', _firstNameController.text);
      await prefs.setString('user_surname', _lastNameController.text);
    } catch (e) {
      debugPrint('Error saving CDS number: $e');
    }
  }

  Future<void> _loadBanks() async {
    setState(() => _bankController.isLoading = true);
    try {
      await _bankController.loadBanks(
        apiUrl: _getBanksUrl,
        username: _apiUsername,
        password: _apiPassword,
      );
      setState(() {});
    } catch (e) {
      _showSnackBar('Failed to load banks. Please try again.');
    } finally {
      setState(() => _bankController.isLoading = false);
    }
  }

  Future<void> _selectDate(TextEditingController controller,
      {DateTime? firstDate, DateTime? lastDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: firstDate ?? DateTime(1900),
      lastDate: lastDate ?? DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      controller.text =
      "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  Future<void> _pickIdFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.first;
        setState(() {
          _idFile = File(pickedFile.path!);
          _idFileName = pickedFile.name;
          _idFileExtension = pickedFile.extension?.toLowerCase();
        });
      }
    } catch (e) {
      _showSnackBar('Failed to pick file: $e');
    }
  }

  void _removeIdFile() => setState(() {
    _idFile = null;
    _idFileName = null;
    _idFileExtension = null;
  });

  // ─── Navigation ───────────────────────────────────────────────────────────────

  void _nextStep() {
    // FIX #9 – validate inline before proceeding
    if (_validateCurrentStep()) {
      if (_currentStep < _steps.length - 1) {
        _animationController.reset();
        setState(() => _currentStep++);
        _animationController.forward();
      } else {
        _submitApplication();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _animationController.reset();
      setState(() {
        _currentStep--;
        _errors.clear();
      });
      _animationController.forward();
    }
  }

  // FIX #9 – Inline validation: sets _errors and returns false when invalid
  bool _validateCurrentStep() {
    final Map<String, String?> newErrors = {};

    switch (_currentStep) {
      case 0: // Personal Info
        if (_firstNameController.text.trim().isEmpty) {
          newErrors['firstName'] = 'First name is required';
        }
        if (_lastNameController.text.trim().isEmpty) {
          newErrors['lastName'] = 'Last name is required';
        }
        if (_dateOfBirthController.text.isEmpty) {
          newErrors['dob'] = 'Date of birth is required';
        }
        if (_occupationController.text.trim().isEmpty) {
          newErrors['occupation'] = 'Occupation is required';
        }
        break;

      case 1: // Identification
        if (_selectedNationality.isEmpty) {
          newErrors['nationality'] = 'Please select your nationality';
        }
        if (_identificationNumberController.text.trim().isEmpty) {
          newErrors['idNumber'] = 'Identification number is required';
        }
        // Issuing authority required for Tanzania
        if (_selectedNationality == 'Tanzanian' &&
            _selectedIssuingAuthority.isEmpty) {
          newErrors['issuingAuthority'] = 'Please select an issuing authority';
        }
        break;

      case 2: // Address
        if (_selectedCountry.isEmpty) {
          newErrors['country'] = 'Please select your country';
        }
        if (_selectedCountry == 'Tanzania') {
          if (_selectedRegion.isEmpty) {
            newErrors['region'] = 'Please select your region';
          }
          if (_selectedDistrict.isEmpty) {
            newErrors['district'] = 'Please select your district';
          }
          if (_wardController.text.trim().isEmpty) {
            newErrors['ward'] = 'Ward is required';
          }
          if (_houseNumberController.text.trim().isEmpty) {
            newErrors['houseNumber'] = 'House number is required';
          }
        } else {
          if (_physicalAddressController.text.trim().isEmpty) {
            newErrors['address'] = 'Physical address is required';
          }
        }
        if (_emailController.text.trim().isEmpty ||
            !_emailController.text.contains('@')) {
          newErrors['email'] = 'Please enter a valid email address';
        }
        if (_phoneController.text.trim().isEmpty) {
          newErrors['phone'] = 'Phone number is required';
        }
        break;

      case 3: // Bank Details
        if (_accountNumberController.text.trim().isEmpty) {
          newErrors['accountNumber'] = 'Account number is required';
        }
        if (_bankController.selectedBank == null) {
          newErrors['bankName'] = 'Please select your bank';
        }
        break;

      case 4: // Investment
      // Initial amount optional – no required fields here beyond dropdowns
        break;

      case 5: // Final Details
        if (_selectedSourceOfFunds.isEmpty) {
          newErrors['sourceOfFunds'] = 'Please select a source of funds';
        }
        if (_isPoliticallyExposed && _positionController.text.trim().isEmpty) {
          newErrors['position'] = 'Please specify the position held';
        }
        break;
    }

    setState(() => _errors
      ..clear()
      ..addAll(newErrors));

    if (newErrors.isNotEmpty) {
      _showSnackBar('Please fill in all required fields highlighted below.');
      return false;
    }
    return true;
  }

  // ─── Computed address string for API ─────────────────────────────────────────
  String get _resolvedAddress {
    if (_selectedCountry == 'Tanzania') {
      final parts = [
        if (_houseNumberController.text.isNotEmpty)
          _houseNumberController.text,
        if (_streetController.text.isNotEmpty) _streetController.text,
        if (_wardController.text.isNotEmpty) _wardController.text,
        if (_selectedDistrict.isNotEmpty) _selectedDistrict,
        if (_selectedRegion.isNotEmpty) _selectedRegion,
        'Tanzania',
      ];
      return parts.join(', ');
    }
    return _physicalAddressController.text;
  }

  // ─── Submit ───────────────────────────────────────────────────────────────────

  Future<void> _submitApplication() async {
    setState(() => _isLoading = true);
    try {
      final issuingAuthority = _selectedNationality == 'Tanzanian'
          ? _selectedIssuingAuthority
          : _issuingAuthorityController.text;

      // Strip commas from amount
      final rawAmount =
      _initialAmountController.text.replaceAll(',', '');

      final requestBody = {
        "APIUsername": _apiUsername,
        "APIPassword": _apiPassword,
        "AccountType": _selectedAccountType,
        "Title": _titleController.text,
        "JointName": "",
        "FirstName": _firstNameController.text,
        "Surname": _lastNameController.text,
        "OtherNames": _middleNameController.text,
        "DOB": _dateOfBirthController.text,
        "BirthPlace": _placeOfBirthController.text,
        "Gender": _selectedGender,
        "Occupation": _occupationController.text,
        "Nationality": _selectedNationality,
        "IdentificatinType": _selectedIdType,
        "ID": _identificationNumberController.text,
        "IdentificationExpiryDate": _validityDateController.text,
        "IssuingAuthority": issuingAuthority,
        "City": _selectedCountry == 'Tanzania'
            ? _selectedDistrict
            : _cityController.text,
        "PhysicalAddress": _resolvedAddress,
        "Country": _selectedCountry,
        "Email": _emailController.text,
        "MobileNumber": _phoneController.text,
        "InvestmentPurpose": _investmentPurposeController.text,
        "IncomeSource": _selectedSourceOfFunds,
        "InvestmentAccountType": _selectedAccountType,
        "InvestorType": "Individual",
        "Disclosure": _isPoliticallyExposed ? "Yes" : "No",
        "PositionHeld":
        _isPoliticallyExposed ? _positionController.text.trim() : "None",
        "BankType": _selectedBankType,
        "BankAccountNumber": _accountNumberController.text,
        "BankAccountName": _accountHolderNameController.text,
        "BankName": _bankNameController.text,
        "BankBranch": _branchController.text,
        "BankSwiftCode": _swiftCodeController.text,
        "BankAddress": _resolvedAddress,
        "InitialAmountInvested": rawAmount.isEmpty ? "0" : rawAmount,
        "AmountSuppliedIn": _selectedAmountCurrency,
        "ServiceRequired": "Trading",
        "InvestmentPeriod": "Long Term",
        "RiskTolerance": "Medium",
        "Charge": "0",
      };

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 200) {
          setState(() => _cdsNumber = responseData['data']['CDSNumber']);
          if (_cdsNumber != null) await _saveCDSNumber(_cdsNumber!);
          _showSuccessDialog();
        } else {
          _showSnackBar('Error: ${responseData['statusDesc']}');
        }
      } else {
        _showSnackBar('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Failed to submit application: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ─── Dialogs & Snackbars ──────────────────────────────────────────────────────

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                    color: _softMint, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded,
                    color: _primaryGreen, size: 48),
              ),
              const SizedBox(height: 20),
              const Text(
                "Application Submitted!",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _textDark),
              ),
              const SizedBox(height: 12),
              const Text(
                "Your individual account application has been submitted successfully.",
                textAlign: TextAlign.center,
                style:
                TextStyle(color: _textMuted, fontSize: 14, height: 1.5),
              ),
              if (_cdsNumber != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: _softMint,
                    borderRadius: BorderRadius.circular(14),
                    border:
                    Border.all(color: _primaryGreen.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text("CDS Number",
                          style:
                          TextStyle(color: _textMuted, fontSize: 13)),
                      const SizedBox(height: 6),
                      Text(
                        _cdsNumber!,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _primaryGreen,
                            letterSpacing: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Save this number for future reference.",
                  style: TextStyle(fontSize: 12, color: _textMuted),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LoginScreen()));
                  },
                  child: const Text("Continue to Login",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _textDark,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─── Generic searchable bottom-sheet picker ────────────────────────────────

  void _showDropdownPicker(
      String title,
      List<String> options,
      String currentValue,
      Function(String) onSelected, {
        bool searchable = false,
      }) {
    final TextEditingController searchCtrl = TextEditingController();
    List<String> filtered = List.from(options);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return DraggableScrollableSheet(
            initialChildSize: searchable ? 0.75 : 0.55,
            maxChildSize: 0.92,
            minChildSize: 0.35,
            builder: (_, scrollCtrl) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding:
              const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: _textDark)),
                  if (searchable) ...[
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: searchCtrl,
                        onChanged: (q) {
                          setModalState(() {
                            filtered = options
                                .where((o) => o
                                .toLowerCase()
                                .contains(q.toLowerCase()))
                                .toList();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          hintStyle: TextStyle(
                              color: Colors.grey[400], fontSize: 14),
                          prefixIcon: Icon(Icons.search,
                              color: Colors.grey[400], size: 20),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 14),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollCtrl,
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final option = filtered[i];
                        final bool selected = currentValue == option;
                        return InkWell(
                          onTap: () {
                            onSelected(option);
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color:
                              selected ? _softMint : Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? _primaryGreen
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                    child: Text(option,
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: selected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                            color: selected
                                                ? _primaryGreen
                                                : _textDark))),
                                if (selected)
                                  const Icon(
                                      Icons.check_circle_rounded,
                                      color: _primaryGreen,
                                      size: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── FIX #3 – Bank search bottom sheet ────────────────────────────────────────
  void _showBankSearchPicker() {
    final TextEditingController searchCtrl = TextEditingController();
    List filteredBanks = List.from(_bankController.banks);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.75,
            maxChildSize: 0.92,
            minChildSize: 0.4,
            builder: (_, scrollCtrl) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding:
              const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  const Text('Select Bank',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: _textDark)),
                  const SizedBox(height: 14),
                  // Search field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: searchCtrl,
                      onChanged: (q) {
                        setModalState(() {
                          filteredBanks = _bankController.banks
                              .where((b) => b.bankName
                              .toLowerCase()
                              .contains(q.toLowerCase()))
                              .toList();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search bank...',
                        hintStyle: TextStyle(
                            color: Colors.grey[400], fontSize: 14),
                        prefixIcon: Icon(Icons.search,
                            color: Colors.grey[400], size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filteredBanks.isEmpty
                        ? Center(
                        child: Text('No banks found',
                            style: TextStyle(color: _textMuted)))
                        : ListView.builder(
                      controller: scrollCtrl,
                      itemCount: filteredBanks.length,
                      itemBuilder: (_, i) {
                        final bank = filteredBanks[i];
                        final bool selected =
                            _bankController.selectedBank ==
                                bank.bankName;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _bankController
                                  .selectBank(bank.bankName);
                              _bankNameController.text =
                                  bank.bankName;
                              _errors.remove('bankName');
                              // Auto-populate SWIFT/BIC code when bank selected
                              try {
                                _swiftCodeController.text = bank.bicCode ?? '';
                              } catch (e) {
                                _swiftCodeController.text = '';
                              }
                            });
                            Navigator.pop(context);
                          },
                          borderRadius:
                          BorderRadius.circular(12),
                          child: Container(
                            margin:
                            const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: selected
                                  ? _softMint
                                  : Colors.grey[50],
                              borderRadius:
                              BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? _primaryGreen
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(bank.bankName,
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: selected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: selected
                                              ? _primaryGreen
                                              : _textDark)),
                                ),
                                if (selected)
                                  const Icon(
                                      Icons.check_circle_rounded,
                                      color: _primaryGreen,
                                      size: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Step Router ──────────────────────────────────────────────────────────────

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildPersonalInformationStep();
      case 1:
        return _buildIdentificationStep();
      case 2:
        return _buildAddressInformationStep();
      case 3:
        return _buildBankInformationStep();
      case 4:
        return _buildInvestmentMandateStep();
      case 5:
        return _buildFinalDetailsStep();
      default:
        return Container();
    }
  }

  // ─── Step 0: Personal Information ────────────────────────────────────────────

  Widget _buildPersonalInformationStep() {
    return _buildStepCard(
      children: [
        _buildSectionLabel('Title & Name'),
        Row(
          children: [
            Expanded(
              child: _buildDropdownTile(
                label: 'Title',
                value: _titleController.text,
                onTap: () => _showDropdownPicker(
                  'Select Title',
                  _titles,
                  _titleController.text,
                      (v) => setState(() => _titleController.text = v),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDropdownTile(
                label: 'Gender',
                value: _selectedGender,
                onTap: () => _showDropdownPicker(
                  'Select Gender',
                  _genders,
                  _selectedGender,
                      (v) => setState(() => _selectedGender = v),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildInputField(
          controller: _firstNameController,
          label: 'First Name',
          icon: Icons.person_outline_rounded,
          required: true,
          errorText: _errors['firstName'],
          onChanged: (_) => setState(() => _errors.remove('firstName')),
        ),
        const SizedBox(height: 14),
        _buildInputField(
          controller: _middleNameController,
          label: 'Middle Name',
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 14),
        _buildInputField(
          controller: _lastNameController,
          label: 'Last Name (Surname)',
          icon: Icons.person_outline_rounded,
          required: true,
          errorText: _errors['lastName'],
          onChanged: (_) => setState(() => _errors.remove('lastName')),
        ),
        const SizedBox(height: 20),
        _buildSectionLabel('Personal Details'),
        _buildDateField(
          controller: _dateOfBirthController,
          label: 'Date of Birth',
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          required: true,
          errorText: _errors['dob'],
        ),
        const SizedBox(height: 14),
        _buildInputField(
          controller: _placeOfBirthController,
          label: 'Place of Birth',
          icon: Icons.location_city_rounded,
        ),
        const SizedBox(height: 14),
        _buildInputField(
          controller: _occupationController,
          label: 'Occupation / Objective',
          icon: Icons.work_outline_rounded,
          required: true,
          errorText: _errors['occupation'],
          onChanged: (_) => setState(() => _errors.remove('occupation')),
        ),
      ],
    );
  }

  // ─── Step 1: Identification ───────────────────────────────────────────────────

  Widget _buildIdentificationStep() {
    final bool isTanzanian = _selectedNationality == 'Tanzanian';

    return _buildStepCard(
      children: [
        _buildSectionLabel('Identity Details'),

        // FIX #1 – Nationality as searchable dropdown
        _buildDropdownTile(
          label: 'Nationality *',
          value: _selectedNationality.isEmpty
              ? 'Select nationality'
              : _selectedNationality,
          onTap: () => _showDropdownPicker(
            'Select Nationality',
            _nationalities,
            _selectedNationality,
                (v) => setState(() {
              _selectedNationality = v;
              _selectedIssuingAuthority = '';
              _errors.remove('nationality');
            }),
            searchable: true,
          ),
          errorText: _errors['nationality'],
          highlighted: _selectedNationality.isNotEmpty,
        ),
        const SizedBox(height: 14),
        _buildDropdownTile(
          label: 'Identification Type',
          value: _selectedIdType,
          onTap: () => _showDropdownPicker(
            'Select ID Type',
            _identificationTypes,
            _selectedIdType,
                (v) => setState(() => _selectedIdType = v),
          ),
        ),
        const SizedBox(height: 14),
        _buildInputField(
          controller: _identificationNumberController,
          label: 'Identification Number',
          icon: Icons.numbers_rounded,
          required: true,
          errorText: _errors['idNumber'],
          onChanged: (_) => setState(() => _errors.remove('idNumber')),
        ),
        const SizedBox(height: 14),
        _buildDateField(
          controller: _validityDateController,
          label: 'Expiry / Validity Date',
          firstDate: DateTime.now(),
          lastDate: DateTime(2100),
        ),
        const SizedBox(height: 14),

        // FIX #1 – If Tanzanian → dropdown; else free-text
        if (isTanzanian) ...[
          _buildDropdownTile(
            label: 'Issuing Authority *',
            value: _selectedIssuingAuthority.isEmpty
                ? 'Select authority'
                : _selectedIssuingAuthority,
            onTap: () => _showDropdownPicker(
              'Select Issuing Authority',
              _tzIssuingAuthorities,
              _selectedIssuingAuthority,
                  (v) => setState(() {
                _selectedIssuingAuthority = v;
                _errors.remove('issuingAuthority');
              }),
            ),
            errorText: _errors['issuingAuthority'],
            highlighted: _selectedIssuingAuthority.isNotEmpty,
          ),
        ] else ...[
          _buildInputField(
            controller: _issuingAuthorityController,
            label: 'Issuing Authority & Country',
            icon: Icons.verified_outlined,
          ),
        ],
        const SizedBox(height: 20),
        _buildSectionLabel('Upload ID Document'),
        Text(
          'Upload a photo or PDF of your identification (optional)',
          style: TextStyle(fontSize: 13, color: _textMuted),
        ),
        const SizedBox(height: 12),
        _idFile == null ? _buildUploadButton() : _buildUploadedFileCard(),
      ],
    );
  }

  Widget _buildUploadButton() {
    return GestureDetector(
      onTap: _pickIdFile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: _softMint,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: _primaryGreen.withOpacity(0.4),
              width: 1.5,
              style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _primaryGreen.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.upload_file_rounded,
                  size: 28, color: _primaryGreen),
            ),
            const SizedBox(height: 10),
            const Text('Tap to upload',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _primaryGreen)),
            const SizedBox(height: 4),
            Text('JPG, PNG or PDF supported',
                style: TextStyle(fontSize: 12, color: _textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadedFileCard() {
    final bool isImage = _idFileExtension == 'jpg' ||
        _idFileExtension == 'jpeg' ||
        _idFileExtension == 'png';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryGreen.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: _primaryGreen.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          if (isImage)
            ClipRRect(
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(14)),
              child: Image.file(_idFile!,
                  width: double.infinity, height: 180, fit: BoxFit.cover),
            ),
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isImage
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isImage
                        ? Icons.image_rounded
                        : Icons.picture_as_pdf_rounded,
                    color: isImage ? Colors.blue : Colors.red[700],
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_idFileName ?? 'Uploaded file',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis),
                      Text('Document uploaded',
                          style:
                          TextStyle(fontSize: 12, color: _textMuted)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _removeIdFile,
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.red),
                  tooltip: 'Remove file',
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[100]),
          TextButton.icon(
            onPressed: _pickIdFile,
            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
            label: const Text('Replace file'),
            style: TextButton.styleFrom(foregroundColor: _primaryGreen),
          ),
        ],
      ),
    );
  }

  // ─── Step 2: Address Information ──────────────────────────────────────────────

  Widget _buildAddressInformationStep() {
    final bool isTanzania = _selectedCountry == 'Tanzania';

    return _buildStepCard(
      children: [
        _buildSectionLabel('Location'),

        // FIX #2 – Country dropdown FIRST
        _buildDropdownTile(
          label: 'Country *',
          value: _selectedCountry.isEmpty ? 'Select country' : _selectedCountry,
          onTap: () => _showDropdownPicker(
            'Select Country',
            _countries,
            _selectedCountry,
                (v) => setState(() {
              _selectedCountry = v;
              _selectedRegion = '';
              _selectedDistrict = '';
              _errors.remove('country');
            }),
            searchable: true,
          ),
          errorText: _errors['country'],
          highlighted: _selectedCountry.isNotEmpty,
        ),
        const SizedBox(height: 14),

        // FIX #2 – Tanzania-specific sub-fields
        if (isTanzania) ...[
          _buildDropdownTile(
            label: 'Region *',
            value:
            _selectedRegion.isEmpty ? 'Select region' : _selectedRegion,
            onTap: () => _showDropdownPicker(
              'Select Region',
              _tanzaniaRegions,
              _selectedRegion,
                  (v) => setState(() {
                _selectedRegion = v;
                _selectedDistrict = '';
                _errors.remove('region');
              }),
              searchable: true,
            ),
            errorText: _errors['region'],
            highlighted: _selectedRegion.isNotEmpty,
          ),
          const SizedBox(height: 14),
          if (_selectedRegion.isNotEmpty) ...[
            _buildDropdownTile(
              label: 'District *',
              value: _selectedDistrict.isEmpty
                  ? 'Select district'
                  : _selectedDistrict,
              onTap: () => _showDropdownPicker(
                'Select District',
                _tanzaniaDistricts[_selectedRegion] ?? [],
                _selectedDistrict,
                    (v) => setState(() {
                  _selectedDistrict = v;
                  _errors.remove('district');
                }),
                searchable: true,
              ),
              errorText: _errors['district'],
              highlighted: _selectedDistrict.isNotEmpty,
            ),
            const SizedBox(height: 14),
          ],
          _buildInputField(
            controller: _wardController,
            label: 'Ward *',
            icon: Icons.location_on_outlined,
            required: true,
            errorText: _errors['ward'],
            onChanged: (_) => setState(() => _errors.remove('ward')),
          ),
          const SizedBox(height: 14),
          _buildInputField(
            controller: _houseNumberController,
            label: 'House Number *',
            icon: Icons.home_outlined,
            required: true,
            errorText: _errors['houseNumber'],
            onChanged: (_) =>
                setState(() => _errors.remove('houseNumber')),
          ),
          const SizedBox(height: 14),
          _buildInputField(
            controller: _streetController,
            label: 'Street Name',
            icon: Icons.alt_route_outlined,
          ),
        ] else ...[
          // Non-Tanzania: city + address
          _buildInputField(
            controller: _cityController,
            label: 'City',
            icon: Icons.location_city_rounded,
          ),
          const SizedBox(height: 14),
          _buildInputField(
            controller: _physicalAddressController,
            label: 'Physical Address *',
            icon: Icons.home_outlined,
            maxLines: 2,
            required: true,
            errorText: _errors['address'],
            onChanged: (_) => setState(() => _errors.remove('address')),
          ),
        ],

        const SizedBox(height: 20),
        _buildSectionLabel('Contact Details'),
        _buildInputField(
          controller: _emailController,
          label: 'Email Address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          required: true,
          errorText: _errors['email'],
          onChanged: (_) => setState(() => _errors.remove('email')),
        ),
        const SizedBox(height: 14),
        _buildInputField(
          controller: _phoneController,
          label: 'Phone Number',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          required: true,
          errorText: _errors['phone'],
          onChanged: (_) => setState(() => _errors.remove('phone')),
        ),
      ],
    );
  }

  // ─── Step 3: Bank Information ─────────────────────────────────────────────────

  Widget _buildBankInformationStep() {
    return _buildStepCard(
      children: [
        _buildSectionLabel('Account Details'),
        _buildDropdownTile(
          label: 'Bank Type',
          value: _selectedBankType,
          onTap: () => _showDropdownPicker(
            'Select Bank Type',
            _bankTypes,
            _selectedBankType,
                (v) => setState(() => _selectedBankType = v),
          ),
        ),
        const SizedBox(height: 14),
        _buildInputField(
          controller: _accountNumberController,
          label: 'Account Number',
          icon: Icons.credit_card_rounded,
          keyboardType: TextInputType.number,
          required: true,
          errorText: _errors['accountNumber'],
          onChanged: (_) =>
              setState(() => _errors.remove('accountNumber')),
        ),
        const SizedBox(height: 14),
        _buildInputField(
          controller: _accountHolderNameController,
          label: 'Account Holder Name',
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 20),
        _buildSectionLabel('Bank Details'),

        // FIX #3 – Bank search picker
        GestureDetector(
          onTap: _showBankSearchPicker,
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(14),
              border: _errors['bankName'] != null
                  ? Border.all(color: _errorRed, width: 1.5)
                  : null,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.account_balance_outlined,
                    color: _primaryGreen, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bank Name *',
                          style: TextStyle(
                              fontSize: 12, color: _textMuted)),
                      const SizedBox(height: 4),
                      Text(
                        _bankController.selectedBank ??
                            (_bankController.isLoading
                                ? 'Loading banks...'
                                : 'Tap to search & select'),
                        style: TextStyle(
                            fontSize: 15,
                            color: _bankController.selectedBank != null
                                ? _textDark
                                : _textMuted,
                            fontWeight: _bankController.selectedBank !=
                                null
                                ? FontWeight.w500
                                : FontWeight.normal),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.search_rounded, color: _textMuted),
              ],
            ),
          ),
        ),
        if (_errors['bankName'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(_errors['bankName']!,
                style:
                const TextStyle(color: _errorRed, fontSize: 12)),
          ),
        const SizedBox(height: 14),
        _buildInputField(
          controller: _branchController,
          label: 'Branch',
          icon: Icons.business_outlined,
        ),
        const SizedBox(height: 14),
        _buildInputField(
          controller: _swiftCodeController,
          label: 'SWIFT Code',
          icon: Icons.code_rounded,
        ),
      ],
    );
  }

  // ─── Step 4: Investment Mandate ───────────────────────────────────────────────

  Widget _buildInvestmentMandateStep() {
    return _buildStepCard(
      children: [
        _buildSectionLabel('Initial Investment'),
        // FIX #5 – Comma separators on amount field
        _buildInputFieldFormatted(
          controller: _initialAmountController,
          label: 'Initial Amount (optional)',
          icon: Icons.attach_money_rounded,
          formatter: _ThousandsInputFormatter(),
        ),
        const SizedBox(height: 14),
        _buildDropdownTile(
          label: 'Currency',
          value: _selectedAmountCurrency,
          onTap: () => _showDropdownPicker(
            'Select Currency',
            _currencies,
            _selectedAmountCurrency,
                (v) => setState(() => _selectedAmountCurrency = v),
          ),
        ),
        const SizedBox(height: 20),
        _buildSectionLabel('Account Type'),
        // FIX #6 – Only Individual / Minor
        Column(
          children: _accountTypes.map((type) {
            final bool selected = _selectedAccountType == type;
            return GestureDetector(
              onTap: () => setState(() => _selectedAccountType = type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: selected ? _softMint : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? _primaryGreen
                        : Colors.grey.withOpacity(0.2),
                    width: selected ? 1.5 : 1,
                  ),
                  boxShadow: selected
                      ? [
                    BoxShadow(
                        color: _primaryGreen.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ]
                      : [],
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected
                            ? _primaryGreen
                            : Colors.transparent,
                        border: Border.all(
                          color: selected
                              ? _primaryGreen
                              : Colors.grey[400]!,
                          width: 2,
                        ),
                      ),
                      child: selected
                          ? const Icon(Icons.check_rounded,
                          size: 14, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Text(type,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: selected ? _primaryGreen : _textDark)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        _buildSectionLabel('Payment Method'),
        Column(
          children: _paymentMethods.map((method) {
            final bool selected = _selectedPaymentMethod == method;
            return GestureDetector(
              onTap: () => setState(() => _selectedPaymentMethod = method),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: selected ? _softMint : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? _primaryGreen
                        : Colors.grey.withOpacity(0.2),
                    width: selected ? 1.5 : 1,
                  ),
                  boxShadow: selected
                      ? [
                    BoxShadow(
                        color: _primaryGreen.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ]
                      : [],
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected
                            ? _primaryGreen
                            : Colors.transparent,
                        border: Border.all(
                          color: selected
                              ? _primaryGreen
                              : Colors.grey[400]!,
                          width: 2,
                        ),
                      ),
                      child: selected
                          ? const Icon(Icons.check_rounded,
                          size: 14, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Text(method,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color:
                            selected ? _primaryGreen : _textDark)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── Step 5: Final Details ────────────────────────────────────────────────────
  // FIX #7 – Investor type, service & period and risk tolerance removed entirely

  Widget _buildFinalDetailsStep() {
    return _buildStepCard(
      children: [
        _buildSectionLabel('Investment Purpose'),
        _buildInputField(
          controller: _investmentPurposeController,
          label: 'Purpose of Investment (e.g. Wealth Creation)',
          icon: Icons.flag_outlined,
          maxLines: 2,
        ),
        const SizedBox(height: 20),
        _buildSectionLabel('Source of Funds'),
        // FIX #8 – Source of funds as dropdown
        _buildDropdownTile(
          label: 'Source of Funds *',
          value: _selectedSourceOfFunds.isEmpty
              ? 'Select source'
              : _selectedSourceOfFunds,
          onTap: () => _showDropdownPicker(
            'Source of Funds',
            _sourcesOfFunds,
            _selectedSourceOfFunds,
                (v) => setState(() {
              _selectedSourceOfFunds = v;
              _fundsSourceController.text = v;
              _errors.remove('sourceOfFunds');
            }),
          ),
          errorText: _errors['sourceOfFunds'],
          highlighted: _selectedSourceOfFunds.isNotEmpty,
        ),
        const SizedBox(height: 20),
        _buildSectionLabel('Political Exposure Disclosure'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border:
            Border.all(color: Colors.orange.withOpacity(0.2), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: Colors.orange[600], size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Politically Exposed Person (PEP)',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Are you or any immediate family member related to a senior government official, military officer (general+), president of a state-owned company, head of a government agency, supreme court judge, or political party representative?',
                style: TextStyle(
                    fontSize: 12, color: _textMuted, height: 1.5),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _buildToggleOption(
                    label: 'Yes',
                    selected: _isPoliticallyExposed,
                    onTap: () =>
                        setState(() => _isPoliticallyExposed = true),
                  ),
                  const SizedBox(width: 12),
                  _buildToggleOption(
                    label: 'No',
                    selected: !_isPoliticallyExposed,
                    onTap: () =>
                        setState(() => _isPoliticallyExposed = false),
                  ),
                ],
              ),
              if (_isPoliticallyExposed) ...[
                const SizedBox(height: 14),
                _buildInputField(
                  controller: _positionController,
                  label: 'Position Held',
                  icon: Icons.badge_outlined,
                  required: true,
                  errorText: _errors['position'],
                  onChanged: (_) =>
                      setState(() => _errors.remove('position')),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleOption({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? _primaryGreen : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? _primaryGreen
                  : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : _textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Shared Widgets ───────────────────────────────────────────────────────────

  Widget _buildStepCard({required List<Widget> children}) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                  color: _primaryGreen,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                  letterSpacing: 0.3)),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    TextInputType? keyboardType,
    bool enabled = true,
    int maxLines = 1,
    bool required = false,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    final bool hasError = errorText != null && errorText.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(14),
            border: hasError
                ? Border.all(color: _errorRed, width: 1.5)
                : null,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            enabled: enabled,
            maxLines: maxLines,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 15, color: _textDark),
            decoration: InputDecoration(
              labelText: required ? '$label *' : label,
              labelStyle: TextStyle(
                  color: hasError ? _errorRed : _textMuted,
                  fontSize: 14),
              prefixIcon: icon != null
                  ? Icon(icon,
                  color: hasError ? _errorRed : _primaryGreen,
                  size: 20)
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                  horizontal: icon != null ? 4 : 18, vertical: 16),
              floatingLabelBehavior: FloatingLabelBehavior.auto,
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    size: 13, color: _errorRed),
                const SizedBox(width: 4),
                Text(errorText,
                    style: const TextStyle(
                        fontSize: 12, color: _errorRed)),
              ],
            ),
          ),
      ],
    );
  }

  // FIX #5 – Formatted amount field
  Widget _buildInputFieldFormatted({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    required TextInputFormatter formatter,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType:
        const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
          formatter,
        ],
        style: const TextStyle(fontSize: 15, color: _textDark),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: _textMuted, fontSize: 14),
          prefixIcon: icon != null
              ? Icon(icon, color: _primaryGreen, size: 20)
              : null,
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    DateTime? firstDate,
    DateTime? lastDate,
    bool required = false,
    String? errorText,
  }) {
    final bool hasError = errorText != null && errorText.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            _selectDate(controller,
                firstDate: firstDate, lastDate: lastDate);
            setState(() => _errors.remove('dob'));
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(14),
              border: hasError
                  ? Border.all(color: _errorRed, width: 1.5)
                  : null,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: TextField(
              controller: controller,
              enabled: false,
              style: const TextStyle(fontSize: 15, color: _textDark),
              decoration: InputDecoration(
                labelText: required ? '$label *' : label,
                labelStyle: TextStyle(
                    color: hasError ? _errorRed : _textMuted,
                    fontSize: 14),
                prefixIcon: Icon(Icons.calendar_today_outlined,
                    color: hasError ? _errorRed : _primaryGreen,
                    size: 20),
                suffixIcon: const Icon(Icons.arrow_forward_ios_rounded,
                    color: _textMuted, size: 14),
                border: InputBorder.none,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
                disabledBorder: InputBorder.none,
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    size: 13, color: _errorRed),
                const SizedBox(width: 4),
                Text(errorText,
                    style: const TextStyle(
                        fontSize: 12, color: _errorRed)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDropdownTile({
    required String label,
    required String value,
    required VoidCallback onTap,
    String? errorText,
    bool highlighted = false,
  }) {
    final bool hasError = errorText != null && errorText.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: highlighted ? _softMint : _cardBg,
              borderRadius: BorderRadius.circular(14),
              border: hasError
                  ? Border.all(color: _errorRed, width: 1.5)
                  : highlighted
                  ? Border.all(
                  color: _primaryGreen.withOpacity(0.4),
                  width: 1)
                  : null,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: TextStyle(
                              fontSize: 12,
                              color: hasError ? _errorRed : _textMuted)),
                      const SizedBox(height: 4),
                      Text(value,
                          style: TextStyle(
                              fontSize: 15,
                              color: highlighted ? _primaryGreen : _textDark,
                              fontWeight: highlighted
                                  ? FontWeight.w600
                                  : FontWeight.w500)),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: hasError ? _errorRed : _textMuted,
                ),
              ],
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    size: 13, color: _errorRed),
                const SizedBox(width: 4),
                Text(errorText,
                    style: const TextStyle(
                        fontSize: 12, color: _errorRed)),
              ],
            ),
          ),
      ],
    );
  }

  // ─── Step Progress Indicator ──────────────────────────────────────────────────

  Widget _buildStepIndicator() {
    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _steps.length,
        itemBuilder: (context, index) {
          final bool isCompleted = index < _currentStep;
          final bool isCurrent = index == _currentStep;
          return GestureDetector(
            onTap: () {
              if (index < _currentStep) {
                _animationController.reset();
                setState(() {
                  _currentStep = index;
                  _errors.clear();
                });
                _animationController.forward();
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isCompleted
                    ? _primaryGreen
                    : isCurrent
                    ? Colors.white
                    : Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                border: isCurrent
                    ? Border.all(color: _primaryGreen, width: 1.5)
                    : null,
                boxShadow: isCurrent
                    ? [
                  BoxShadow(
                      color: _primaryGreen.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isCompleted
                        ? Icons.check_rounded
                        : _steps[index]['icon'] as IconData,
                    size: 16,
                    color: isCompleted
                        ? Colors.white
                        : isCurrent
                        ? _primaryGreen
                        : _textMuted,
                  ),
                  if (isCurrent) ...[
                    const SizedBox(width: 6),
                    Text(
                      _steps[index]['title'] as String,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _primaryGreen),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF7FFFD4),
              Color(0xFF98FB98),
              Color(0xFFAFEEEE),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top Header ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (_currentStep == 0) {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen()));
                        } else {
                          _previousStep();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: _textDark, size: 18),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Individual Account',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _textDark),
                          ),
                          Text(
                            _steps[_currentStep]['title'] as String,
                            style:
                            TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentStep + 1} / ${_steps.length}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _textDark),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Progress Bar ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_currentStep + 1) / _steps.length,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor:
                    const AlwaysStoppedAnimation<Color>(_deepGreen),
                    minHeight: 5,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Step Chips ────────────────────────────────────────────────
              _buildStepIndicator(),
              const SizedBox(height: 4),

              // ── Form Content ──────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: _buildCurrentStep(),
                ),
              ),

              // ── Navigation Buttons ────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    if (_currentStep > 0) ...[
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          onPressed: _previousStep,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: _primaryGreen, width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding:
                            const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor:
                            Colors.white.withOpacity(0.5),
                          ),
                          child: const Text('Back',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _primaryGreen)),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _nextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          padding:
                          const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                            : Row(
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentStep == _steps.length - 1
                                  ? 'Submit Application'
                                  : 'Continue',
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700),
                            ),
                            if (_currentStep < _steps.length - 1)
                              const SizedBox(width: 6),
                            if (_currentStep < _steps.length - 1)
                              const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _dateOfBirthController.dispose();
    _placeOfBirthController.dispose();
    _occupationController.dispose();
    _identificationNumberController.dispose();
    _validityDateController.dispose();
    _issuingAuthorityController.dispose();
    _houseNumberController.dispose();
    _streetController.dispose();
    _wardController.dispose();
    _cityController.dispose();
    _physicalAddressController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _fundsSourceController.dispose();
    _positionController.dispose();
    _investmentPurposeController.dispose();
    _accountNumberController.dispose();
    _accountHolderNameController.dispose();
    _bankNameController.dispose();
    _branchController.dispose();
    _swiftCodeController.dispose();
    _bankSearchController.dispose();
    _initialAmountController.dispose();
    super.dispose();
  }
}

