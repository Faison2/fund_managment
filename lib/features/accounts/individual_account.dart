import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsl/constants/constants.dart';

import '../accounts/api_service/bank_controller.dart';
import '../auth/login/view/login.dart';

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

  // Animation controller for step transitions
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // ─── Controllers ────────────────────────────────────────────────────────────
  final TextEditingController _titleController =
  TextEditingController(text: "Mr");
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  final TextEditingController _placeOfBirthController =
  TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _nationalityController = TextEditingController();
  final TextEditingController _identificationNumberController =
  TextEditingController();
  final TextEditingController _validityDateController =
  TextEditingController();
  final TextEditingController _issuingAuthorityController =
  TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _physicalAddressController =
  TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _fundsSourceController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _investmentPurposeController =
  TextEditingController();

  // Bank Information
  final TextEditingController _accountNumberController =
  TextEditingController();
  final TextEditingController _accountHolderNameController =
  TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _branchController = TextEditingController();
  final TextEditingController _swiftCodeController = TextEditingController();

  // Investment
  final TextEditingController _initialAmountController =
  TextEditingController();

  // ─── Form State ──────────────────────────────────────────────────────────────
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isPoliticallyExposed = false;
  String _selectedIdType = 'National ID';
  String _selectedPaymentMethod = 'Cash';
  String _selectedRiskTolerance = 'Medium';
  String _selectedGender = 'Male';
  String _selectedAccountType = 'Individual';
  String _selectedInvestmentAccountType = 'Standard';
  String _selectedInvestorType = 'Individual';
  String _selectedBankType = 'Local';
  String _selectedAmountCurrency = 'USD';
  String _selectedServiceRequired = 'Trading';
  String _selectedInvestmentPeriod = 'Long Term';
  String? _cdsNumber;

  // ID Upload
  File? _idFile;
  String? _idFileName;
  String? _idFileExtension;

  // ─── Dropdown Options ────────────────────────────────────────────────────────
  final List<String> _identificationTypes = [
    'National ID',
    'Passport',
    'Driver\'s License',
    'Voter\'s ID',
  ];
  final List<String> _genders = ['Male', 'Female'];
  final List<String> _titles = ['Mr', 'Mrs', 'Miss', 'Dr', 'Prof'];
  final List<String> _paymentMethods = [
    'Cash',
    'Cheque',
    'Direct Fund Transfer',
  ];
  final List<String> _riskToleranceLevels = ['Low', 'Medium', 'High'];

  // ✅ Updated to match API
  final List<String> _bankTypes = ['Local', 'Savings', 'Current', 'Corporate'];
  final List<String> _currencies = ['USD', 'TZS', 'ZWL', 'EUR', 'GBP'];
  final List<String> _investmentAccountTypes = [
    'Standard',
    'Unit Trust',
    'Discretionary',
  ];
  final List<String> _investorTypes = [
    'Individual',
    'Retail',
    'Institutional',
  ];
  final List<String> _servicesRequired = [
    'Trading',
    'Advisory',
    'Portfolio Management',
    'Custody',
  ];
  final List<String> _investmentPeriods = [
    'Short Term',
    'Medium Term',
    'Long Term',
  ];

  final List<Map<String, dynamic>> _steps = [
    {'title': 'Personal Info', 'icon': Icons.person_outline_rounded},
    {'title': 'Identification', 'icon': Icons.badge_outlined},
    {'title': 'Address', 'icon': Icons.location_on_outlined},
    {'title': 'Bank Details', 'icon': Icons.account_balance_outlined},
    {'title': 'Investment', 'icon': Icons.trending_up_rounded},
    {'title': 'Preferences', 'icon': Icons.tune_rounded},
    {'title': 'Final Details', 'icon': Icons.checklist_rounded},
  ];

  // ─── Theme Colors ────────────────────────────────────────────────────────────
  static const Color _primaryGreen = Color(0xFF2DC98E);
  static const Color _deepGreen = Color(0xFF1A9B6C);
  static const Color _lightAqua = Color(0xFF7FFFD4);
  static const Color _softMint = Color(0xFFE8FBF4);
  static const Color _cardBg = Colors.white;
  static const Color _textDark = Color(0xFF1A2332);
  static const Color _textMuted = Color(0xFF8A9BB0);

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
      SharedPreferences prefs = await SharedPreferences.getInstance();
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

  void _nextStep() {
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
      setState(() => _currentStep--);
      _animationController.forward();
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_firstNameController.text.isEmpty) {
          _showSnackBar('Please enter your first name');
          return false;
        }
        if (_lastNameController.text.isEmpty) {
          _showSnackBar('Please enter your last name');
          return false;
        }
        if (_dateOfBirthController.text.isEmpty) {
          _showSnackBar('Please enter your date of birth');
          return false;
        }
        if (_occupationController.text.isEmpty) {
          _showSnackBar('Please enter your occupation');
          return false;
        }
        break;
      case 1:
        if (_nationalityController.text.isEmpty) {
          _showSnackBar('Please enter your nationality');
          return false;
        }
        if (_identificationNumberController.text.isEmpty) {
          _showSnackBar('Please enter your identification number');
          return false;
        }
        break;
      case 2:
        if (_physicalAddressController.text.isEmpty) {
          _showSnackBar('Please enter your physical address');
          return false;
        }
        if (_emailController.text.isEmpty ||
            !_emailController.text.contains('@')) {
          _showSnackBar('Please enter a valid email');
          return false;
        }
        if (_phoneController.text.isEmpty) {
          _showSnackBar('Please enter your phone number');
          return false;
        }
        break;
      case 3:
        if (_accountNumberController.text.isEmpty) {
          _showSnackBar('Please enter your account number');
          return false;
        }
        if (_bankController.selectedBank == null) {
          _showSnackBar('Please select your bank');
          return false;
        }
        break;
      case 6:
        if (_isPoliticallyExposed && _positionController.text.isEmpty) {
          _showSnackBar('Please specify the position held');
          return false;
        }
        if (_fundsSourceController.text.isEmpty) {
          _showSnackBar('Please enter the source of funds');
          return false;
        }
        break;
    }
    return true;
  }

  Future<void> _submitApplication() async {
    setState(() => _isLoading = true);
    try {
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
        "Nationality": _nationalityController.text,
        "IdentificatinType": _selectedIdType,
        "ID": _identificationNumberController.text,
        "IdentificationExpiryDate": _validityDateController.text,
        "IssuingAuthority": _issuingAuthorityController.text,
        "City": _cityController.text,
        "PhysicalAddress": _physicalAddressController.text,
        "Country": _countryController.text,
        "Email": _emailController.text,
        "MobileNumber": _phoneController.text,
        // ✅ Now captured from form
        "InvestmentPurpose": _investmentPurposeController.text,
        "IncomeSource": _fundsSourceController.text,
        "InvestmentAccountType": _selectedInvestmentAccountType,
        "InvestorType": _selectedInvestorType,
        // ✅ Aligned with API: "Yes" / "No"
        "Disclosure": _isPoliticallyExposed ? "Yes" : "No",
        "PositionHeld":
        _isPoliticallyExposed ? _positionController.text.trim() : "None",
        "BankType": _selectedBankType,
        "BankAccountNumber": _accountNumberController.text,
        "BankAccountName": _accountHolderNameController.text,
        "BankName": _bankNameController.text,
        "BankBranch": _branchController.text,
        "BankSwiftCode": _swiftCodeController.text,
        "BankAddress": _physicalAddressController.text,
        "InitialAmountInvested": _initialAmountController.text.isEmpty
            ? "0"
            : _initialAmountController.text,
        "AmountSuppliedIn": _selectedAmountCurrency,
        // ✅ Now captured from form
        "ServiceRequired": _selectedServiceRequired,
        "InvestmentPeriod": _selectedInvestmentPeriod,
        "RiskTolerance": _selectedRiskTolerance,
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

  // ─── Dialogs & Snackbars ─────────────────────────────────────────────────────

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
                decoration: BoxDecoration(
                  color: _softMint,
                  shape: BoxShape.circle,
                ),
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
                style: TextStyle(color: _textMuted, fontSize: 14, height: 1.5),
              ),
              if (_cdsNumber != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: _softMint,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _primaryGreen.withOpacity(0.3)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showDropdownPicker(
      String title,
      List<String> options,
      String currentValue,
      Function(String) onSelected,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
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
            const SizedBox(height: 16),
            ...options.map((option) {
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
                    color: selected ? _softMint : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                      selected ? _primaryGreen : Colors.transparent,
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
                        const Icon(Icons.check_circle_rounded,
                            color: _primaryGreen, size: 20),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // ─── Step Router ────────────────────────────────────────────────────────────

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
        return _buildInvestmentPreferencesStep();
      case 6:
        return _buildFinalDetailsStep();
      default:
        return Container();
    }
  }

  // ─── Step 0: Personal Information ───────────────────────────────────────────

  Widget _buildPersonalInformationStep() {
    return _buildStepCard(
      children: [
        _buildSectionLabel('Title & Name'),
        // ── Title + Gender side by side ──────────────────────────────────────
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
        ),
        const SizedBox(height: 20),
        _buildSectionLabel('Personal Details'),
        _buildDateField(
          controller: _dateOfBirthController,
          label: 'Date of Birth',
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          required: true,
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
        ),
      ],
    );
  }

  // ─── Step 1: Identification ──────────────────────────────────────────────────

  Widget _buildIdentificationStep() {
    return _buildStepCard(
      children: [
        _buildSectionLabel('Identity Details'),
        _buildInputField(
          controller: _nationalityController,
          label: 'Nationality',
          icon: Icons.flag_outlined,
          required: true,
        ),
        const SizedBox(height: 14),
        _buildDropdownTile(
          label: 'Identification Type',
          value: _selectedIdType,
          onTap: () => _showDropdownPicker(
              'Select ID Type',
              _identificationTypes,
              _selectedIdType,
                  (v) => setState(() => _selectedIdType = v)),
        ),
        const SizedBox(height: 14),
        _buildInputField(
          controller: _identificationNumberController,
          label: 'Identification Number',
          icon: Icons.numbers_rounded,
          required: true,
        ),
        const SizedBox(height: 14),
        _buildDateField(
          controller: _validityDateController,
          label: 'Expiry / Validity Date',
          firstDate: DateTime.now(),
          lastDate: DateTime(2100),
        ),
        const SizedBox(height: 14),
        _buildInputField(
          controller: _issuingAuthorityController,
          label: 'Issuing Authority & Country',
          icon: Icons.verified_outlined,
        ),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                              fontSize: 14, fontWeight: FontWeight.w500),
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

  // ─── Step 2: Address Information ────────────────────────────────────────────

  Widget _buildAddressInformationStep() {
    return _buildStepCard(
      children: [
        _buildSectionLabel('Location'),
        _buildInputField(
            controller: _cityController,
            label: 'City',
            icon: Icons.location_city_rounded),
        const SizedBox(height: 14),
        _buildInputField(
          controller: _physicalAddressController,
          label: 'Physical Address',
          icon: Icons.home_outlined,
          maxLines: 2,
          required: true,
        ),
        const SizedBox(height: 14),
        _buildInputField(
            controller: _countryController,
            label: 'Country',
            icon: Icons.public_rounded),
        const SizedBox(height: 20),
        _buildSectionLabel('Contact Details'),
        _buildInputField(
          controller: _emailController,
          label: 'Email Address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          required: true,
        ),
        const SizedBox(height: 14),
        _buildInputField(
          controller: _phoneController,
          label: 'Phone Number',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          required: true,
        ),
      ],
    );
  }

  // ─── Step 3: Bank Information ────────────────────────────────────────────────

  Widget _buildBankInformationStep() {
    return _buildStepCard(
      children: [
        _buildSectionLabel('Account Details'),
        _buildDropdownTile(
          label: 'Bank Type',
          value: _selectedBankType,
          onTap: () => _showDropdownPicker('Select Bank Type', _bankTypes,
              _selectedBankType, (v) => setState(() => _selectedBankType = v)),
        ),
        const SizedBox(height: 14),
        _buildInputField(
          controller: _accountNumberController,
          label: 'Account Number',
          icon: Icons.credit_card_rounded,
          keyboardType: TextInputType.number,
          required: true,
        ),
        const SizedBox(height: 14),
        _buildInputField(
            controller: _accountHolderNameController,
            label: 'Account Holder Name',
            icon: Icons.person_outline_rounded),
        const SizedBox(height: 20),
        _buildSectionLabel('Bank Details'),
        _buildBankDropdown(),
        const SizedBox(height: 14),
        _buildInputField(
            controller: _branchController,
            label: 'Branch',
            icon: Icons.business_outlined),
        const SizedBox(height: 14),
        _buildInputField(
            controller: _swiftCodeController,
            label: 'SWIFT Code',
            icon: Icons.code_rounded),
      ],
    );
  }

  Widget _buildBankDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: DropdownButtonFormField<String>(
          value: _bankController.selectedBank,
          decoration: InputDecoration(
            labelText: 'Bank Name',
            border: InputBorder.none,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
            labelStyle: TextStyle(color: _textMuted, fontSize: 14),
            prefixIcon: const Icon(Icons.account_balance_outlined,
                color: _primaryGreen, size: 20),
            suffixIcon: _bankController.isLoading
                ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                    width: 16,
                    height: 16,
                    child:
                    CircularProgressIndicator(strokeWidth: 2)))
                : null,
          ),
          items: _bankController.banks.map((bank) {
            return DropdownMenuItem<String>(
              value: bank.bankName,
              child: Text(bank.bankName,
                  style: const TextStyle(fontSize: 15),
                  overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _bankController.selectBank(value);
              _bankNameController.text = value ?? '';
            });
          },
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: _textMuted),
          hint: Text(_bankController.isLoading ? 'Loading banks...' : 'Select Bank',
              style: TextStyle(color: _textMuted, fontSize: 14)),
        ),
      ),
    );
  }

  // ─── Step 4: Investment Mandate ──────────────────────────────────────────────

  Widget _buildInvestmentMandateStep() {
    return _buildStepCard(
      children: [
        _buildSectionLabel('Initial Investment'),
        _buildInputField(
          controller: _initialAmountController,
          label: 'Initial Amount (optional)',
          icon: Icons.attach_money_rounded,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 14),
        _buildDropdownTile(
          label: 'Currency',
          value: _selectedAmountCurrency,
          onTap: () => _showDropdownPicker(
              'Select Currency',
              _currencies,
              _selectedAmountCurrency,
                  (v) => setState(() => _selectedAmountCurrency = v)),
        ),
        const SizedBox(height: 20),
        _buildSectionLabel('Account Configuration'),
        _buildDropdownTile(
          label: 'Investment Account Type',
          value: _selectedInvestmentAccountType,
          onTap: () => _showDropdownPicker(
              'Select Account Type',
              _investmentAccountTypes,
              _selectedInvestmentAccountType,
                  (v) => setState(() => _selectedInvestmentAccountType = v)),
        ),
        const SizedBox(height: 14),
        _buildDropdownTile(
          label: 'Investor Type',
          value: _selectedInvestorType,
          onTap: () => _showDropdownPicker(
              'Select Investor Type',
              _investorTypes,
              _selectedInvestorType,
                  (v) => setState(() => _selectedInvestorType = v)),
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
                        color: selected ? _primaryGreen : Colors.transparent,
                        border: Border.all(
                          color: selected ? _primaryGreen : Colors.grey[400]!,
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

  // ─── Step 5: Investment Preferences ─────────────────────────────────────────

  Widget _buildInvestmentPreferencesStep() {
    return _buildStepCard(
      children: [
        _buildSectionLabel('Service & Period'),
        _buildDropdownTile(
          label: 'Service Required',
          value: _selectedServiceRequired,
          onTap: () => _showDropdownPicker(
              'Service Required',
              _servicesRequired,
              _selectedServiceRequired,
                  (v) => setState(() => _selectedServiceRequired = v)),
        ),
        const SizedBox(height: 14),
        _buildDropdownTile(
          label: 'Investment Period',
          value: _selectedInvestmentPeriod,
          onTap: () => _showDropdownPicker(
              'Investment Period',
              _investmentPeriods,
              _selectedInvestmentPeriod,
                  (v) => setState(() => _selectedInvestmentPeriod = v)),
        ),
        const SizedBox(height: 20),
        _buildSectionLabel('Risk Tolerance'),
        Text(
          'How tolerant are you to short-term fluctuations in prices?',
          style: TextStyle(fontSize: 13, color: _textMuted, height: 1.5),
        ),
        const SizedBox(height: 14),
        ..._riskToleranceLevels.map((level) {
          final bool selected = _selectedRiskTolerance == level;
          final Map<String, dynamic> details = {
            'Low': {
              'desc': 'Little tolerance for price fluctuations',
              'icon': Icons.shield_outlined,
              'color': Colors.green[600],
            },
            'Medium': {
              'desc': 'Some tolerance for price fluctuations',
              'icon': Icons.balance_outlined,
              'color': Colors.orange[600],
            },
            'High': {
              'desc': 'High tolerance for significant fluctuations',
              'icon': Icons.trending_up_rounded,
              'color': Colors.red[600],
            },
          }[level]!;

          return GestureDetector(
            onTap: () => setState(() => _selectedRiskTolerance = level),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: selected ? _softMint : Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                      (details['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(details['icon'] as IconData,
                        color: details['color'] as Color, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(level,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: selected
                                    ? _primaryGreen
                                    : _textDark)),
                        const SizedBox(height: 3),
                        Text(details['desc'] as String,
                            style: TextStyle(
                                color: _textMuted, fontSize: 13)),
                      ],
                    ),
                  ),
                  if (selected)
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                          color: _primaryGreen, shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded,
                          size: 14, color: Colors.white),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  // ─── Step 6: Final Details ───────────────────────────────────────────────────

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
        _buildInputField(
          controller: _fundsSourceController,
          label: 'Source of Funds (savings, salary, inheritance…)',
          icon: Icons.account_balance_wallet_outlined,
          maxLines: 3,
          required: true,
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
              color: selected ? _primaryGreen : Colors.grey.withOpacity(0.3),
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

  // ─── Shared Widgets ──────────────────────────────────────────────────────────

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
        keyboardType: keyboardType,
        enabled: enabled,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 15, color: _textDark),
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          labelStyle: TextStyle(color: _textMuted, fontSize: 14),
          prefixIcon: icon != null
              ? Icon(icon, color: _primaryGreen, size: 20)
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
              horizontal: icon != null ? 4 : 18, vertical: 16),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
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
  }) {
    return GestureDetector(
      onTap: () => _selectDate(controller,
          firstDate: firstDate, lastDate: lastDate),
      child: Container(
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
          enabled: false,
          style: const TextStyle(fontSize: 15, color: _textDark),
          decoration: InputDecoration(
            labelText: required ? '$label *' : label,
            labelStyle: TextStyle(color: _textMuted, fontSize: 14),
            prefixIcon: const Icon(Icons.calendar_today_outlined,
                color: _primaryGreen, size: 20),
            suffixIcon: const Icon(Icons.arrow_forward_ios_rounded,
                color: _textMuted, size: 14),
            border: InputBorder.none,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
            disabledBorder: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownTile({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style:
                      TextStyle(fontSize: 12, color: _textMuted)),
                  const SizedBox(height: 4),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 15,
                          color: _textDark,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: _textMuted),
          ],
        ),
      ),
    );
  }

  // ─── Step Progress Header ────────────────────────────────────────────────────

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
                setState(() => _currentStep = index);
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

  // ─── Build ───────────────────────────────────────────────────────────────────

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
              // ── Top Header ──────────────────────────────────────────────────
              Padding(
                padding:
                const EdgeInsets.fromLTRB(20, 16, 20, 12),
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
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[600]),
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

              // ── Progress Bar ────────────────────────────────────────────────
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

              // ── Step Chips ──────────────────────────────────────────────────
              _buildStepIndicator(),
              const SizedBox(height: 4),

              // ── Form Content ────────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: _buildCurrentStep(),
                ),
              ),

              // ── Navigation Buttons ───────────────────────────────────────────
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
    _nationalityController.dispose();
    _identificationNumberController.dispose();
    _validityDateController.dispose();
    _issuingAuthorityController.dispose();
    _cityController.dispose();
    _physicalAddressController.dispose();
    _countryController.dispose();
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
    _initialAmountController.dispose();
    super.dispose();
  }
}