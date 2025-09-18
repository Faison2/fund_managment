import 'package:flutter/material.dart';
import '../auth/login/login.dart';

class IndividualAccountScreen extends StatefulWidget {
  const IndividualAccountScreen({Key? key}) : super(key: key);

  @override
  State<IndividualAccountScreen> createState() => _IndividualAccountScreenState();
}

class _IndividualAccountScreenState extends State<IndividualAccountScreen> {
  // Controllers for all form fields
  final TextEditingController _fullNameController = TextEditingController();
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
  final TextEditingController _investmentPurposeController = TextEditingController();
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
  final TextEditingController _cashEquivalentController = TextEditingController();
  final TextEditingController _callAccountController = TextEditingController();
  final TextEditingController _collectiveInvestmentController = TextEditingController();
  final TextEditingController _othersController = TextEditingController();
  final TextEditingController _feePercentageController = TextEditingController();

  // Form state
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isPoliticallyExposed = false;
  String _selectedIdType = 'National ID';
  String _selectedPaymentMethod = 'Cash';
  String _selectedServiceCategory = 'Discretionary Portfolio Services';
  String _selectedTimeHorizon = 'Short time (Less than 1 Year)';
  String _selectedRiskTolerance = 'Low';

  final List<String> _identificationTypes = [
    'National ID',
    'Passport',
    'Driver\'s License',
    'Voter\'s ID',
  ];

  final List<String> _paymentMethods = [
    'Cash',
    'Cheque',
    'Direct Fund Transfer',
  ];

  final List<String> _serviceCategories = [
    'Discretionary Portfolio Services',
    'Managed Portfolio Services',
    'Non-Managed/Execution Only Services',
  ];

  final List<String> _timeHorizons = [
    'Short time (Less than 1 Year)',
    'Medium (1-3 Years)',
    'Long time (Over 3 Years)',
    'Open-ended',
  ];

  final List<String> _riskToleranceLevels = [
    'Low',
    'Medium',
    'High',
  ];

  final List<String> _stepTitles = [
    'Personal Information',
    'Identification',
    'Address Information',
    'Bank Information',
    'Investment Mandate',
    'Service Details',
    'Investment Preferences',
    'Asset Allocation',
    'Final Details',
  ];

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      controller.text = "${picked.day}/${picked.month}/${picked.year}";
    }
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      if (_currentStep < _stepTitles.length - 1) {
        setState(() {
          _currentStep++;
        });
      } else {
        _submitApplication();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Personal Information
        if (_fullNameController.text.isEmpty) {
          _showSnackBar('Please enter your full name');
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
        if (_bankNameController.text.isEmpty) {
          _showSnackBar('Please enter your bank name');
          return false;
        }
        break;
      case 4: // Investment Mandate
        if (_initialAmountController.text.isEmpty) {
          _showSnackBar('Please enter initial investment amount');
          return false;
        }
        break;
    }
    return true;
  }

  Future<void> _submitApplication() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(Duration(seconds: 3));

    setState(() {
      _isLoading = false;
    });

    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Column(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 60,
              ),
              SizedBox(height: 16),
              Text(
                "Application Submitted!",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            "Your individual account application has been submitted successfully. You will receive a confirmation email shortly.",
            textAlign: TextAlign.center,
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
                child: Text(
                  "Continue to Login",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showDropdownPicker(String title, List<String> options, String currentValue, Function(String) onSelected) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              ...options.map((option) {
                return ListTile(
                  title: Text(option),
                  trailing: currentValue == option ? Icon(Icons.check, color: Colors.blue) : null,
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
        return _buildServiceDetailsStep();
      case 6:
        return _buildInvestmentPreferencesStep();
      case 7:
        return _buildAssetAllocationStep();
      case 8:
        return _buildFinalDetailsStep();
      default:
        return Container();
    }
  }

  Widget _buildPersonalInformationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: _fullNameController,
          hintText: 'Full Name (state any former or other names)',
        ),
        SizedBox(height: 16),
        GestureDetector(
          onTap: () => _selectDate(_dateOfBirthController),
          child: _buildTextField(
            controller: _dateOfBirthController,
            hintText: 'Date of Birth',
            enabled: false,
            suffixIcon: Icons.calendar_today,
          ),
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _placeOfBirthController,
          hintText: 'Place of Birth/Registration',
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _occupationController,
          hintText: 'Occupation/Objective',
        ),
      ],
    );
  }

  Widget _buildIdentificationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: _nationalityController,
          hintText: 'Nationality',
        ),
        SizedBox(height: 16),
        GestureDetector(
          onTap: () => _showDropdownPicker(
            'Select Identification Type',
            _identificationTypes,
            _selectedIdType,
                (value) => setState(() => _selectedIdType = value),
          ),
          child: _buildDropdownField(_selectedIdType),
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _identificationNumberController,
          hintText: 'Identification Number',
        ),
        SizedBox(height: 16),
        GestureDetector(
          onTap: () => _selectDate(_validityDateController),
          child: _buildTextField(
            controller: _validityDateController,
            hintText: 'Validity/Expiry Date',
            enabled: false,
            suffixIcon: Icons.calendar_today,
          ),
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _issuingAuthorityController,
          hintText: 'Issuing Authority and Country',
        ),
      ],
    );
  }

  Widget _buildAddressInformationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: _cityController,
          hintText: 'City',
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _physicalAddressController,
          hintText: 'Physical Address',
          maxLines: 2,
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _countryController,
          hintText: 'Country',
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _emailController,
          hintText: 'Email',
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _phoneController,
          hintText: 'Phone Number',
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildBankInformationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: _accountNumberController,
          hintText: 'Account Number',
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _accountHolderNameController,
          hintText: 'Account Holder Name',
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _bankNameController,
          hintText: 'Bank Name',
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _branchController,
          hintText: 'Branch',
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _swiftCodeController,
          hintText: 'Swift Code',
        ),
      ],
    );
  }

  Widget _buildInvestmentMandateStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: _initialAmountController,
          hintText: 'Initial Amount Invested',
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: 24),
        Text(
          'Amount supplied in:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16),
        Column(
          children: _paymentMethods.map((method) {
            return Container(
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.all(12),
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
                    onChanged: (value) {
                      setState(() {
                        _selectedPaymentMethod = value!;
                      });
                    },
                    activeColor: Colors.blue,
                  ),
                  Text(
                    method,
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildServiceDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Please select the category of services required:',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16),
        GestureDetector(
          onTap: () => _showDropdownPicker(
            'Select Service Category',
            _serviceCategories,
            _selectedServiceCategory,
                (value) => setState(() => _selectedServiceCategory = value),
          ),
          child: _buildDropdownField(_selectedServiceCategory),
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            _getServiceDescription(_selectedServiceCategory),
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInvestmentPreferencesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time Horizon',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'This is the period over which an investment is made or held; it can range from a few months to several years.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 16),
        GestureDetector(
          onTap: () => _showDropdownPicker(
            'Select Time Horizon',
            _timeHorizons,
            _selectedTimeHorizon,
                (value) => setState(() => _selectedTimeHorizon = value),
          ),
          child: _buildDropdownField(_selectedTimeHorizon),
        ),
        SizedBox(height: 24),
        Text(
          'Risk Tolerance Level',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Please indicate your tolerance to short-term fluctuations in prices:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 16),
        Column(
          children: _riskToleranceLevels.map((level) {
            String description = '';
            switch (level) {
              case 'Low':
                description = 'little or some tolerance of price fluctuations';
                break;
              case 'Medium':
                description = 'some tolerance of price fluctuations';
                break;
              case 'High':
                description = 'significant price fluctuations';
                break;
            }

            return Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(16),
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
                    onChanged: (value) {
                      setState(() {
                        _selectedRiskTolerance = value!;
                      });
                    },
                    activeColor: Colors.blue,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          level,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
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

  Widget _buildAssetAllocationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Asset Allocation',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _cashEquivalentController,
          hintText: 'Cash Equivalent (Fixed Deposits) - Amount',
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _callAccountController,
          hintText: 'Call Account - Amount',
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _collectiveInvestmentController,
          hintText: 'Collective Investment Schemes - Amount',
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _othersController,
          hintText: 'Others - Amount',
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: 24),
        Text(
          'Fees',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'I/We confirm notification of the fee arrangement, charged as',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _feePercentageController,
                hintText: 'Fee percentage',
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(width: 12),
            Text(
              '% per annum',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Text(
          'of the total funds invested. And that, in addition to the fees, I/We further acknowledge that if there are taxes applicable to the Fund, depending on where they are invested, such tax will be paid by the Client.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildFinalDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Investment Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _investmentPurposeController,
          hintText: 'Purpose of your investment',
          maxLines: 3,
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _fundsSourceController,
          hintText: 'Source of funds (sale of asset, savings, inheritance, etc)',
          maxLines: 3,
        ),
        SizedBox(height: 24),
        Text(
          'Political Exposure Disclosure',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(16),
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
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Radio<bool>(
                    value: true,
                    groupValue: _isPoliticallyExposed,
                    onChanged: (value) {
                      setState(() {
                        _isPoliticallyExposed = value!;
                      });
                    },
                    activeColor: Colors.blue,
                  ),
                  Text('Yes'),
                  SizedBox(width: 30),
                  Radio<bool>(
                    value: false,
                    groupValue: _isPoliticallyExposed,
                    onChanged: (value) {
                      setState(() {
                        _isPoliticallyExposed = value!;
                      });
                    },
                    activeColor: Colors.blue,
                  ),
                  Text('No'),
                ],
              ),
              if (_isPoliticallyExposed) ...[
                SizedBox(height: 16),
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

  String _getServiceDescription(String category) {
    switch (category) {
      case 'Discretionary Portfolio Services':
        return 'Under this category, your investment account will be managed on a discretionary basis by TSL. Your investments will be held in your name with TSL acting as your Investment Manager. TSL will be authorized to exercise absolute discretion in making investment decisions on your behalf without prior reference to you.';
      case 'Managed Portfolio Services':
        return 'Under this category, your investment account with TSL will be managed on an advisory basis. TSL accepts responsibility to continue advising on the composition of your portfolio and individual investment therein.';
      case 'Non-Managed/Execution Only Services':
        return 'Under this category, your investment account will be managed on an "execution only basis". TSL will play a brokerage role in executing your investment orders on a best-efforts basis.';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
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
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (_currentStep == 0) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => LoginScreen()),
                              );
                            } else {
                              _previousStep();
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.arrow_back,
                              color: Colors.black87,
                              size: 24,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Individual Account',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                _stepTitles[_currentStep],
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${_currentStep + 1}/${_stepTitles.length}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    // Progress indicator
                    LinearProgressIndicator(
                      value: (_currentStep + 1) / _stepTitles.length,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ],
                ),
              ),

              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: _buildCurrentStep(),
                ),
              ),

              // Navigation Buttons
              Container(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _previousStep,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.blue, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Previous',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                    if (_currentStep > 0) SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _nextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Text(
                          _currentStep == _stepTitles.length - 1
                              ? 'Submit Application'
                              : 'Next',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
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
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 16,
          ),
          suffixIcon: suffixIcon != null
              ? Icon(suffixIcon, color: Colors.grey[600])
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
        style: TextStyle(fontSize: 16),
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
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
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
    _investmentPurposeController.dispose();
    _fundsSourceController.dispose();
    _positionController.dispose();
    _accountNumberController.dispose();
    _accountHolderNameController.dispose();
    _bankNameController.dispose();
    _branchController.dispose();
    _swiftCodeController.dispose();
    _initialAmountController.dispose();
    _cashEquivalentController.dispose();
    _callAccountController.dispose();
    _collectiveInvestmentController.dispose();
    _othersController.dispose();
    _feePercentageController.dispose();
    super.dispose();
  }
}