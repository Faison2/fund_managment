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
  State<IndividualAccountScreen> createState() => _IndividualAccountScreenState();
}

class _IndividualAccountScreenState extends State<IndividualAccountScreen> {
  final BankController _bankController = BankController();
  final String _apiUrl = "$cSharpApi/CreateAccount";
  final String _getBanksUrl = "$cSharpApi/GetBanks";
  final String _apiUsername = "User2";
  final String _apiPassword = "CBZ1234#2";

  // Controllers for all form fields
  final TextEditingController _titleController = TextEditingController(text: "Mr");
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController(); // was _otherNamesController
  final TextEditingController _lastNameController = TextEditingController();   // was _surnameController
  final TextEditingController _dateOfBirthController = TextEditingController();
  final TextEditingController _placeOfBirthController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _nationalityController = TextEditingController();
  final TextEditingController _identificationNumberController = TextEditingController();
  final TextEditingController _validityDateController = TextEditingController();
  final TextEditingController _issuingAuthorityController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _physicalAddressController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _fundsSourceController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();

  // Bank Information Controllers
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _accountHolderNameController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _branchController = TextEditingController();
  final TextEditingController _swiftCodeController = TextEditingController();

  // Investment Controllers
  final TextEditingController _initialAmountController = TextEditingController();

  // ID Upload state
  File? _idFile;
  String? _idFileName;
  String? _idFileExtension;

  // Form state
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isPoliticallyExposed = false;
  String _selectedIdType = 'National ID';
  String _selectedPaymentMethod = 'Cash';
  String _selectedRiskTolerance = 'Low';
  String _selectedGender = 'Male';
  String _selectedAccountType = 'Individual';
  String _selectedInvestmentAccountType = 'Unit Trust';
  String _selectedInvestorType = 'Retail';
  String _selectedBankType = 'Savings';
  String _selectedAmountCurrency = 'USD';
  String? _cdsNumber;

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
  final List<String> _bankTypes = ['Savings', 'Current', 'Corporate'];

  // ✅ Added TZS to currencies
  final List<String> _currencies = ['USD', 'TZS', 'ZWL', 'EUR', 'GBP'];

  // ✅ Removed: Service Details, Time Horizon, Asset Allocation (Fee %)
  final List<String> _stepTitles = [
    'Personal Information',
    'Identification',
    'Address Information',
    'Bank Information',
    'Investment Mandate',
    'Investment Preferences',
    'Final Details',
  ];

  @override
  void initState() {
    super.initState();
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
      print('CDS Number saved successfully: $cdsNumber');
    } catch (e) {
      print('Error saving CDS number: $e');
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
      print('Error loading banks: $e');
      _showSnackBar('Failed to load banks. Please try again.');
    } finally {
      setState(() => _bankController.isLoading = false);
    }
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
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

  // ✅ ID file upload (supports images and PDF)
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

  void _removeIdFile() {
    setState(() {
      _idFile = null;
      _idFileName = null;
      _idFileExtension = null;
    });
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      if (_currentStep < _stepTitles.length - 1) {
        setState(() => _currentStep++);
      } else {
        _submitApplication();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Personal Information
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

      case 1: // Identification
        if (_nationalityController.text.isEmpty) {
          _showSnackBar('Please enter your nationality');
          return false;
        }
        if (_identificationNumberController.text.isEmpty) {
          _showSnackBar('Please enter your identification number');
          return false;
        }
        // ID file upload is optional but recommended — no hard block
        break;

      case 2: // Address Information
        if (_physicalAddressController.text.isEmpty) {
          _showSnackBar('Please enter your physical address');
          return false;
        }
        if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
          _showSnackBar('Please enter a valid email');
          return false;
        }
        if (_phoneController.text.isEmpty) {
          _showSnackBar('Please enter your phone number');
          return false;
        }
        break;

      case 3: // Bank Information
        if (_accountNumberController.text.isEmpty) {
          _showSnackBar('Please enter your account number');
          return false;
        }
        if (_bankController.selectedBank == null) {
          _showSnackBar('Please select your bank');
          return false;
        }
        break;

    // ✅ case 4: Initial investment is now optional — no mandatory check

      case 6: // Final Details
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
      final Map<String, dynamic> requestBody = {
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
        "InvestmentPurpose": "",
        "IncomeSource": _fundsSourceController.text,
        "InvestmentAccountType": _selectedInvestmentAccountType,
        "InvestorType": _selectedInvestorType,
        "Disclosure": _isPoliticallyExposed
            ? "Politically exposed person"
            : "No conflicts of interest",
        "PositionHeld": _isPoliticallyExposed ? _positionController.text.trim() : "N/A",
        "BankType": _selectedBankType,
        "BankAccountNumber": _accountNumberController.text,
        "BankAccountName": _accountHolderNameController.text,
        "BankName": _bankNameController.text,
        "BankBranch": _branchController.text,
        "BankSwiftCode": _swiftCodeController.text,
        "BankAddress": _physicalAddressController.text,
        "InitialAmountInvested":
        _initialAmountController.text.isEmpty ? "0" : _initialAmountController.text,
        "AmountSuppliedIn": _selectedAmountCurrency,
        "ServiceRequired": "",
        "InvestmentPeriod": "",
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
          setState(() {
            _cdsNumber = responseData['data']['CDSNumber'];
          });
          if (_cdsNumber != null) await _saveCDSNumber(_cdsNumber!);
          _showSuccessDialog();
        } else {
          _showSnackBar('API Error: ${responseData['statusDesc']}');
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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 60),
              const SizedBox(height: 16),
              const Text(
                "Application Submitted!",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Your individual account application has been submitted successfully.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (_cdsNumber != null)
                Text(
                  "CDS Number: $_cdsNumber",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 8),
              const Text(
                "Your CDS number has been saved and can be accessed later.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text("Continue to Login",
                    style: TextStyle(color: Colors.white)),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ...options.map((option) {
                return ListTile(
                  title: Text(option),
                  trailing: currentValue == option
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    onSelected(option);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  // ─── Step Router ────────────────────────────────────────────────────────────

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: return _buildPersonalInformationStep();
      case 1: return _buildIdentificationStep();
      case 2: return _buildAddressInformationStep();
      case 3: return _buildBankInformationStep();
      case 4: return _buildInvestmentMandateStep();
      case 5: return _buildInvestmentPreferencesStep();
      case 6: return _buildFinalDetailsStep();
      default: return Container();
    }
  }

  // ─── Step 0: Personal Information ───────────────────────────────────────────

  Widget _buildPersonalInformationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _showDropdownPicker(
            'Select Title', _titles, _titleController.text,
                (value) => setState(() => _titleController.text = value),
          ),
          child: _buildDropdownField(_titleController.text),
        ),
        const SizedBox(height: 16),
        _buildTextField(controller: _firstNameController, hintText: 'First Name'),
        const SizedBox(height: 16),
        // ✅ Changed: Middle Name (was Other Names)
        _buildTextField(controller: _middleNameController, hintText: 'Middle Name'),
        const SizedBox(height: 16),
        // ✅ Changed: Last Name (was Surname)
        _buildTextField(controller: _lastNameController, hintText: 'Last Name'),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => _selectDate(_dateOfBirthController),
          child: _buildTextField(
            controller: _dateOfBirthController,
            hintText: 'Date of Birth (YYYY-MM-DD)',
            enabled: false,
            suffixIcon: Icons.calendar_today,
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField(
            controller: _placeOfBirthController,
            hintText: 'Place of Birth/Registration'),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => _showDropdownPicker(
            'Select Gender', _genders, _selectedGender,
                (value) => setState(() => _selectedGender = value),
          ),
          child: _buildDropdownField(_selectedGender),
        ),
        const SizedBox(height: 16),
        _buildTextField(
            controller: _occupationController, hintText: 'Occupation/Objective'),
      ],
    );
  }

  // ─── Step 1: Identification ──────────────────────────────────────────────────

  Widget _buildIdentificationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
            controller: _nationalityController, hintText: 'Nationality'),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => _showDropdownPicker(
            'Select Identification Type',
            _identificationTypes,
            _selectedIdType,
                (value) => setState(() => _selectedIdType = value),
          ),
          child: _buildDropdownField(_selectedIdType),
        ),
        const SizedBox(height: 16),
        _buildTextField(
            controller: _identificationNumberController,
            hintText: 'Identification Number'),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => _selectDate(_validityDateController),
          child: _buildTextField(
            controller: _validityDateController,
            hintText: 'Validity/Expiry Date (YYYY-MM-DD)',
            enabled: false,
            suffixIcon: Icons.calendar_today,
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField(
            controller: _issuingAuthorityController,
            hintText: 'Issuing Authority and Country'),
        const SizedBox(height: 24),

        // ✅ ID Upload Section
        Text(
          'Upload ID Document',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Upload a photo or PDF of your identification document (optional)',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
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
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.blue.withOpacity(0.4),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.upload_file_rounded, size: 40, color: Colors.blue[400]),
            const SizedBox(height: 8),
            const Text(
              'Tap to upload',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: Colors.blue),
            ),
            const SizedBox(height: 4),
            Text(
              'JPG, PNG or PDF supported',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadedFileCard() {
    final bool isImage =
        _idFileExtension == 'jpg' || _idFileExtension == 'jpeg' || _idFileExtension == 'png';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green.withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        children: [
          // Preview for images
          if (isImage)
            ClipRRect(
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(13)),
              child: Image.file(
                _idFile!,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  isImage ? Icons.image_rounded : Icons.picture_as_pdf_rounded,
                  color: isImage ? Colors.blue : Colors.red[700],
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _idFileName ?? 'Uploaded file',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: _removeIdFile,
                  icon: const Icon(Icons.close_rounded, color: Colors.red),
                  tooltip: 'Remove file',
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 12),
            child: TextButton.icon(
              onPressed: _pickIdFile,
              icon: const Icon(Icons.swap_horiz_rounded, size: 18),
              label: const Text('Replace file'),
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 2: Address Information ────────────────────────────────────────────

  Widget _buildAddressInformationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(controller: _cityController, hintText: 'City'),
        const SizedBox(height: 16),
        _buildTextField(
            controller: _physicalAddressController,
            hintText: 'Physical Address',
            maxLines: 2),
        const SizedBox(height: 16),
        _buildTextField(controller: _countryController, hintText: 'Country'),
        const SizedBox(height: 16),
        _buildTextField(
            controller: _emailController,
            hintText: 'Email',
            keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 16),
        _buildTextField(
            controller: _phoneController,
            hintText: 'Phone Number',
            keyboardType: TextInputType.phone),
      ],
    );
  }

  // ─── Step 3: Bank Information ────────────────────────────────────────────────

  Widget _buildBankInformationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _showDropdownPicker(
            'Select Bank Type', _bankTypes, _selectedBankType,
                (value) => setState(() => _selectedBankType = value),
          ),
          child: _buildDropdownField(_selectedBankType),
        ),
        const SizedBox(height: 16),
        _buildTextField(
            controller: _accountNumberController, hintText: 'Account Number'),
        const SizedBox(height: 16),
        _buildTextField(
            controller: _accountHolderNameController,
            hintText: 'Account Holder Name'),
        const SizedBox(height: 16),
        _buildBankDropdown(),
        const SizedBox(height: 16),
        _buildTextField(controller: _branchController, hintText: 'Branch'),
        const SizedBox(height: 16),
        _buildTextField(
            controller: _swiftCodeController, hintText: 'Swift Code'),
      ],
    );
  }

  Widget _buildBankDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonFormField<String>(
          value: _bankController.selectedBank,
          decoration: InputDecoration(
            labelText: 'Bank Name',
            border: InputBorder.none,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            labelStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
            suffixIcon: _bankController.isLoading
                ? const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : null,
          ),
          items: _bankController.banks.map((bank) {
            return DropdownMenuItem<String>(
              value: bank.bankName,
              child: Text(bank.bankName,
                  style: const TextStyle(fontSize: 16),
                  overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (String? value) {
            setState(() {
              _bankController.selectBank(value);
              _bankNameController.text = value ?? '';
            });
          },
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          hint: _bankController.isLoading
              ? const Text('Loading banks...')
              : const Text('Select Bank'),
        ),
      ),
    );
  }

  // ─── Step 4: Investment Mandate ──────────────────────────────────────────────

  Widget _buildInvestmentMandateStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Initial investment is now optional — no asterisk, no mandatory validation
        _buildTextField(
          controller: _initialAmountController,
          hintText: 'Initial Amount Invested (optional)',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => _showDropdownPicker(
            'Select Currency', _currencies, _selectedAmountCurrency,
                (value) => setState(() => _selectedAmountCurrency = value),
          ),
          child: _buildDropdownField(_selectedAmountCurrency),
        ),
        const SizedBox(height: 24),
        Text(
          'Payment Method',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87),
        ),
        const SizedBox(height: 16),
        Column(
          children: _paymentMethods.map((method) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(10),
                border: _selectedPaymentMethod == method
                    ? Border.all(color: Colors.blue, width: 2)
                    : null,
              ),
              child: Row(
                children: [
                  Radio<String>(
                    value: method,
                    groupValue: _selectedPaymentMethod,
                    onChanged: (value) =>
                        setState(() => _selectedPaymentMethod = value!),
                    activeColor: Colors.blue,
                  ),
                  Text(method, style: const TextStyle(fontSize: 16)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── Step 5: Investment Preferences (risk tolerance only) ────────────────────

  Widget _buildInvestmentPreferencesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Time Horizon removed — only Risk Tolerance remains
        const Text(
          'Risk Tolerance Level',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Text(
          'Please indicate your tolerance to short-term fluctuations in prices:',
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
        const SizedBox(height: 16),
        Column(
          children: _riskToleranceLevels.map((level) {
            String description = '';
            switch (level) {
              case 'Low':
                description = 'Little or some tolerance of price fluctuations';
                break;
              case 'Medium':
                description = 'Some tolerance of price fluctuations';
                break;
              case 'High':
                description = 'Significant price fluctuations';
                break;
            }
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(15),
                border: _selectedRiskTolerance == level
                    ? Border.all(color: Colors.blue, width: 2)
                    : null,
              ),
              child: Row(
                children: [
                  Radio<String>(
                    value: level,
                    groupValue: _selectedRiskTolerance,
                    onChanged: (value) =>
                        setState(() => _selectedRiskTolerance = value!),
                    activeColor: Colors.blue,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(level,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(description,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── Step 6: Final Details ───────────────────────────────────────────────────

  Widget _buildFinalDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Purpose of investment removed; only source of funds remains
        const Text(
          'Source of Funds',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _fundsSourceController,
          hintText: 'Source of funds (sale of asset, savings, inheritance, etc)',
          maxLines: 3,
        ),
        const SizedBox(height: 24),
        const Text(
          'Political Exposure Disclosure',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you immediately or indirectly related to a senior member of the Tanzanian or a foreign government, member of the executive council of government or member of a legislature; deputy minister or the equivalent rank; ambassador or attaché or counselor of an ambassador; military officer with a rank of general or above; president of a state-owned company or a state-owned bank; head of a government agency; judge of a supreme court, constitutional court or other court of last resort; or a political party representative in a legislature?',
                style: TextStyle(
                    fontSize: 13, color: Colors.grey[700], height: 1.4),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Radio<bool>(
                    value: true,
                    groupValue: _isPoliticallyExposed,
                    onChanged: (value) =>
                        setState(() => _isPoliticallyExposed = value!),
                    activeColor: Colors.blue,
                  ),
                  const Text('Yes'),
                  const SizedBox(width: 30),
                  Radio<bool>(
                    value: false,
                    groupValue: _isPoliticallyExposed,
                    onChanged: (value) =>
                        setState(() => _isPoliticallyExposed = value!),
                    activeColor: Colors.blue,
                  ),
                  const Text('No'),
                ],
              ),
              if (_isPoliticallyExposed) ...[
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _positionController,
                  hintText: 'Please specify the position held',
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ─── Shared Widgets ──────────────────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    bool enabled = true,
    IconData? suffixIcon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        enabled: enabled,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
          suffixIcon: suffixIcon != null
              ? Icon(suffixIcon, color: Colors.grey[600])
              : null,
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildDropdownField(String value) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(value,
                  style: const TextStyle(fontSize: 16, color: Colors.black87)),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  // ─── Scaffold ────────────────────────────────────────────────────────────────

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
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (_currentStep == 0) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const LoginScreen()),
                              );
                            } else {
                              _previousStep();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.arrow_back,
                                color: Colors.black87, size: 24),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              const Text(
                                'Individual Account',
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87),
                              ),
                              Text(
                                _stepTitles[_currentStep],
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${_currentStep + 1}/${_stepTitles.length}',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    LinearProgressIndicator(
                      value: (_currentStep + 1) / _stepTitles.length,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ],
                ),
              ),

              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildCurrentStep(),
                ),
              ),

              // Navigation Buttons
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _previousStep,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.blue, width: 2),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Previous',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue),
                          ),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _nextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                            : Text(
                          _currentStep == _stepTitles.length - 1
                              ? 'Submit Application'
                              : 'Next',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
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
    _accountNumberController.dispose();
    _accountHolderNameController.dispose();
    _bankNameController.dispose();
    _branchController.dispose();
    _swiftCodeController.dispose();
    _initialAmountController.dispose();
    super.dispose();
  }
}