import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tsl/constants/secure_storage.dart';

class AppColors {
  static const Color blue = Color(0xFF329AD6);
  static const Color teal = Color(0xFF00A79D);
  static const Color grey = Color(0xFF939598);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF231F20);
  static const Color lightGrey = Color(0xFFF5F6F7);
  static const Color errorRed = Color(0xFFD32F2F);
}

enum ClientType { INDIVIDUAL, DIASPORA, INSTITUTION, GROUP }

class DseOpenAccountPage extends StatefulWidget {
  const DseOpenAccountPage({super.key});

  @override
  State<DseOpenAccountPage> createState() => _DseOpenAccountPageState();
}

class _DseOpenAccountPageState extends State<DseOpenAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // fmsID — sourced from NIDA value stored in SharedPreferences, not user-editable
  String _fmsID = '';

  // Client Type
  ClientType _clientType = ClientType.INDIVIDUAL;

  // Controllers — Personal
  final _firstNameCtrl = TextEditingController();
  final _middleNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _otherNamesCtrl = TextEditingController();
  String _gender = 'MALE';
  final _nationalityCtrl = TextEditingController();
  final _nidaCtrl = TextEditingController();
  DateTime? _dob;
  final _placeOfBirthCtrl = TextEditingController();
  final _birthDistrictCtrl = TextEditingController();
  final _birthWardCtrl = TextEditingController();

  // Controllers — Contact
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // Controllers — Address
  final _countryCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();
  final _residentRegionCtrl = TextEditingController();
  final _residentDistrictCtrl = TextEditingController();
  final _residentVillageCtrl = TextEditingController();
  final _houseNoCtrl = TextEditingController();
  final _postCodeCtrl = TextEditingController();
  final _physicalAddressCtrl = TextEditingController();

  // Controllers — Bank
  final _bankAccountCtrl = TextEditingController();
  final _branchNameCtrl = TextEditingController();
  final _bicCtrl = TextEditingController();

  static const String _brokerRef = 'ae35edd7904c4f04907671520faf6df7';

  bool get _needsLastMiddleName =>
      _clientType == ClientType.INDIVIDUAL || _clientType == ClientType.DIASPORA;

  bool get _needsOtherNames =>
      _clientType == ClientType.INSTITUTION || _clientType == ClientType.GROUP;

  final List<String> _stepTitles = [
    'Account Type',
    'Personal Info',
    'Contact & Address',
    'Bank Details',
  ];

  @override
  void initState() {
    super.initState();
    _loadFmsID();
  }

  Future<void> _loadFmsID() async {
    final nida = await SecureStorage.read('nida_number') ??
        await SecureStorage.read('userNIDA') ??
        '';
    setState(() => _fmsID = nida);
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in [
      _firstNameCtrl, _middleNameCtrl, _lastNameCtrl, _otherNamesCtrl,
      _nationalityCtrl, _nidaCtrl, _placeOfBirthCtrl, _birthDistrictCtrl,
      _birthWardCtrl, _emailCtrl, _phoneCtrl, _countryCtrl, _regionCtrl,
      _residentRegionCtrl, _residentDistrictCtrl, _residentVillageCtrl,
      _houseNoCtrl, _postCodeCtrl, _physicalAddressCtrl, _bankAccountCtrl,
      _branchNameCtrl, _bicCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.teal,
            onPrimary: AppColors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      _showSnack('Please select your date of birth.');
      return;
    }

    setState(() => _isLoading = true);

    final payload = {
      'fmsID': _fmsID,
      'clientType': _clientType.name,
      'brokerRef': _brokerRef,
      'firstName': _firstNameCtrl.text.trim(),
      'middleName': _needsLastMiddleName ? _middleNameCtrl.text.trim() : '',
      'lastName': _needsLastMiddleName ? _lastNameCtrl.text.trim() : '',
      'otherNames': _needsOtherNames ? _otherNamesCtrl.text.trim() : '',
      'gender': _gender,
      'nationality': _nationalityCtrl.text.trim(),
      'nidaNumber': _nidaCtrl.text.trim(),
      'dob': '${_dob!.year.toString().padLeft(4, '0')}-'
          '${_dob!.month.toString().padLeft(2, '0')}-'
          '${_dob!.day.toString().padLeft(2, '0')}',
      'email': _emailCtrl.text.trim(),
      'phoneNumber': _phoneCtrl.text.trim(),
      'country': _countryCtrl.text.trim(),
      'region': _regionCtrl.text.trim(),
      'placeOfBirth': _placeOfBirthCtrl.text.trim(),
      'birthDistrict': _birthDistrictCtrl.text.trim(),
      'birthWard': _birthWardCtrl.text.trim(),
      'residentRegion': _residentRegionCtrl.text.trim(),
      'residentDistrict': _residentDistrictCtrl.text.trim(),
      'residentVillage': _residentVillageCtrl.text.trim(),
      'residentHouseNo': _houseNoCtrl.text.trim(),
      'residentPostCode': _postCodeCtrl.text.trim(),
      'physicalAddress': _physicalAddressCtrl.text.trim(),
      'bankAccountNo': _bankAccountCtrl.text.trim(),
      'branchName': _branchNameCtrl.text.trim(),
      'bic': _bicCtrl.text.trim(),
    };

    try {
      final response = await http.post(
        Uri.parse('https://portaluat.tsl.co.tz/DSEAPI/Home/CreateAccount'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'payload': payload, 'signature': ''}),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _showSuccessDialog(data);
      } else {
        _showSnack('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Network error: $e');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.black,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessDialog(dynamic data) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.teal.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: AppColors.teal),
            ),
            const SizedBox(width: 12),
            const Text('Account Created',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
        content: Text(
          data['message'] ?? 'Your DSE account has been successfully created.',
          style: const TextStyle(color: AppColors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context)
              ..pop()
              ..pop(),
            child: const Text('Done', style: TextStyle(color: AppColors.teal)),
          ),
        ],
      ),
    );
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool obscure = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(color: AppColors.black, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: AppColors.grey, fontSize: 14),
          hintStyle:
          TextStyle(color: AppColors.grey.withOpacity(0.6), fontSize: 14),
          filled: true,
          fillColor: AppColors.lightGrey,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
            BorderSide(color: AppColors.grey.withOpacity(0.2), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
            const BorderSide(color: AppColors.errorRed, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
            const BorderSide(color: AppColors.errorRed, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 12),
    child: Text(
      label,
      style: const TextStyle(
        color: AppColors.teal,
        fontWeight: FontWeight.w600,
        fontSize: 13,
        letterSpacing: 0.5,
      ),
    ),
  );

  // ── Step 0: Account Type ───────────────────────────────────────────────────

  Widget _buildStepAccountType() {
    return _StepWrapper(
      title: 'Select Account Type',
      subtitle: 'Choose the type of account you want to open',
      child: Column(
        children: ClientType.values.map((type) {
          final selected = _clientType == type;
          return GestureDetector(
            onTap: () => setState(() => _clientType = type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: selected ? AppColors.teal.withOpacity(0.08) : AppColors.lightGrey,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? AppColors.teal : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? AppColors.teal : AppColors.grey,
                        width: 2,
                      ),
                      color: selected ? AppColors.teal : Colors.transparent,
                    ),
                    child: selected
                        ? const Icon(Icons.check,
                        size: 12, color: AppColors.white)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: selected ? AppColors.teal : AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _clientTypeDesc(type),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _clientTypeDesc(ClientType t) {
    switch (t) {
      case ClientType.INDIVIDUAL:
        return 'Local individual investor';
      case ClientType.DIASPORA:
        return 'Tanzanian living abroad';
      case ClientType.INSTITUTION:
        return 'Company or organization';
      case ClientType.GROUP:
        return 'Investment group or SACCOS';
    }
  }

  // ── Step 1: Personal Info ─────────────────────────────────────────────────

  Widget _buildStepPersonal() {
    return _StepWrapper(
      title: 'Personal Information',
      subtitle: 'Fill in your personal details as they appear on your ID',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('NAME DETAILS'),
          _buildTextField(
            controller: _firstNameCtrl,
            label: 'First Name *',
            hint: 'e.g. John',
            validator: (v) =>
            v == null || v.trim().isEmpty ? 'First name is required' : null,
          ),
          if (_needsLastMiddleName) ...[
            _buildTextField(
              controller: _middleNameCtrl,
              label: 'Middle Name *',
              hint: 'e.g. Chris',
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Middle name is required'
                  : null,
            ),
            _buildTextField(
              controller: _lastNameCtrl,
              label: 'Last Name *',
              hint: 'e.g. Doe',
              validator: (v) =>
              v == null || v.trim().isEmpty ? 'Last name is required' : null,
            ),
          ],
          if (_needsOtherNames)
            _buildTextField(
              controller: _otherNamesCtrl,
              label: 'Other Names / Organization Name *',
              hint: 'e.g. ABC Investment Group',
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Other names are required'
                  : null,
            ),
          _buildSectionLabel('IDENTITY'),
          // Gender
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: DropdownButtonFormField<String>(
              value: _gender,
              decoration: InputDecoration(
                labelText: 'Gender *',
                labelStyle:
                const TextStyle(color: AppColors.grey, fontSize: 14),
                filled: true,
                fillColor: AppColors.lightGrey,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: AppColors.grey.withOpacity(0.2), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                  const BorderSide(color: AppColors.teal, width: 1.5),
                ),
              ),
              items: ['MALE', 'FEMALE']
                  .map((g) =>
                  DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) => setState(() => _gender = v!),
            ),
          ),
          _buildTextField(
            controller: _nationalityCtrl,
            label: 'Nationality *',
            hint: 'e.g. Tanzanian',
            validator: (v) =>
            v == null || v.trim().isEmpty ? 'Nationality is required' : null,
          ),
          _buildTextField(
            controller: _nidaCtrl,
            label: 'NIDA Number *',
            hint: '20-digit NIDA number',
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'NIDA number is required';
              if (v.trim().length != 20) return 'NIDA must be 20 digits';
              return null;
            },
          ),
          // DOB
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GestureDetector(
              onTap: _pickDob,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.grey.withOpacity(0.2), width: 1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _dob == null
                            ? 'Date of Birth *'
                            : '${_dob!.year}-'
                            '${_dob!.month.toString().padLeft(2, '0')}-'
                            '${_dob!.day.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: _dob == null
                              ? AppColors.grey
                              : AppColors.black,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const Icon(Icons.calendar_today,
                        size: 18, color: AppColors.grey),
                  ],
                ),
              ),
            ),
          ),
          _buildSectionLabel('BIRTH DETAILS'),
          _buildTextField(
            controller: _placeOfBirthCtrl,
            label: 'Place of Birth *',
            hint: 'e.g. Dar es Salaam',
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Place of birth is required'
                : null,
          ),
          _buildTextField(
            controller: _birthDistrictCtrl,
            label: 'Birth District *',
            hint: 'e.g. Ilala',
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Birth district is required'
                : null,
          ),
          _buildTextField(
            controller: _birthWardCtrl,
            label: 'Birth Ward *',
            hint: 'e.g. Kariakoo',
            validator: (v) =>
            v == null || v.trim().isEmpty ? 'Birth ward is required' : null,
          ),
        ],
      ),
    );
  }

  // ── Step 2: Contact & Address ─────────────────────────────────────────────

  Widget _buildStepContact() {
    return _StepWrapper(
      title: 'Contact & Address',
      subtitle: 'Provide your contact and residential information',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('CONTACT'),
          _buildTextField(
            controller: _emailCtrl,
            label: 'Email Address *',
            hint: 'e.g. john@example.com',
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          _buildTextField(
            controller: _phoneCtrl,
            label: 'Phone Number *',
            hint: 'e.g. +255712345678',
            keyboardType: TextInputType.phone,
            validator: (v) =>
            v == null || v.trim().isEmpty ? 'Phone number is required' : null,
          ),
          _buildSectionLabel('COUNTRY'),
          _buildTextField(
            controller: _countryCtrl,
            label: 'Country *',
            hint: 'e.g. Tanzania',
            validator: (v) =>
            v == null || v.trim().isEmpty ? 'Country is required' : null,
          ),
          _buildTextField(
            controller: _regionCtrl,
            label: 'Region *',
            hint: 'e.g. Dar es Salaam',
            validator: (v) =>
            v == null || v.trim().isEmpty ? 'Region is required' : null,
          ),
          _buildSectionLabel('RESIDENTIAL ADDRESS'),
          _buildTextField(
            controller: _residentRegionCtrl,
            label: 'Resident Region *',
            hint: 'e.g. Dar es Salaam',
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Resident region is required'
                : null,
          ),
          _buildTextField(
            controller: _residentDistrictCtrl,
            label: 'Resident District *',
            hint: 'e.g. Kinondoni',
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Resident district is required'
                : null,
          ),
          _buildTextField(
            controller: _residentVillageCtrl,
            label: 'Resident Village / Mtaa *',
            hint: 'e.g. Masaki',
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Resident village is required'
                : null,
          ),
          _buildTextField(
            controller: _houseNoCtrl,
            label: 'House No. *',
            hint: 'e.g. 123',
            validator: (v) =>
            v == null || v.trim().isEmpty ? 'House number is required' : null,
          ),
          _buildTextField(
            controller: _postCodeCtrl,
            label: 'Post Code *',
            hint: 'e.g. 00101',
            keyboardType: TextInputType.number,
            validator: (v) =>
            v == null || v.trim().isEmpty ? 'Post code is required' : null,
          ),
          _buildTextField(
            controller: _physicalAddressCtrl,
            label: 'Physical Address *',
            hint: 'Full street address',
            maxLines: 2,
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Physical address is required'
                : null,
          ),
        ],
      ),
    );
  }

  // ── Step 3: Bank Details ──────────────────────────────────────────────────

  Widget _buildStepBank() {
    return _StepWrapper(
      title: 'Bank Details',
      subtitle: 'Enter your bank account information for settlements',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('BANK ACCOUNT'),
          _buildTextField(
            controller: _bankAccountCtrl,
            label: 'Bank Account Number *',
            hint: 'e.g. 1234567890',
            keyboardType: TextInputType.number,
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Bank account number is required'
                : null,
          ),
          _buildTextField(
            controller: _branchNameCtrl,
            label: 'Branch Name *',
            hint: 'e.g. Main Branch',
            validator: (v) =>
            v == null || v.trim().isEmpty ? 'Branch name is required' : null,
          ),
          _buildTextField(
            controller: _bicCtrl,
            label: 'BIC / SWIFT Code *',
            hint: 'e.g. BARBTZTZ',
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'BIC code is required';
              if (v.trim().length < 8 || v.trim().length > 11) {
                return 'BIC must be 8–11 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.blue.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.blue.withOpacity(0.2), width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline,
                    size: 18, color: AppColors.blue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your bank details will be used for dividend payments and trade settlements on the DSE.',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.blue.withOpacity(0.85),
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Step Indicator ────────────────────────────────────────────────────────

  Widget _buildStepIndicator() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: List.generate(_stepTitles.length, (i) {
          final isActive = i == _currentStep;
          final isDone = i < _currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 3,
                        decoration: BoxDecoration(
                          color: isDone || isActive
                              ? AppColors.teal
                              : AppColors.grey.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _stepTitles[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: isActive
                              ? AppColors.teal
                              : isDone
                              ? AppColors.grey
                              : AppColors.grey.withOpacity(0.5),
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < _stepTitles.length - 1) const SizedBox(width: 4),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Navigation Buttons ────────────────────────────────────────────────────

  Widget _buildNavButtons() {
    final isLast = _currentStep == _stepTitles.length - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => _goToStep(_currentStep - 1),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.teal,
                  side: const BorderSide(color: AppColors.teal, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Back',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                if (isLast) {
                  if (_formKey.currentState!.validate()) _submit();
                } else {
                  _goToStep(_currentStep + 1);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: AppColors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.white),
              )
                  : Text(
                isLast ? 'Open Account' : 'Continue',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.teal, AppColors.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(Icons.account_balance,
                  size: 16, color: AppColors.white),
            ),
            const SizedBox(width: 10),
            const Text(
              'Open DSE Account',
              style: TextStyle(
                color: AppColors.black,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildStepIndicator(),
            // TEMP DEBUG — remove once fmsID is confirmed working
            Container(
              width: double.infinity,
              color: AppColors.teal.withOpacity(0.08),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'fmsID: $_fmsID',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.teal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStepAccountType(),
                  _buildStepPersonal(),
                  _buildStepContact(),
                  _buildStepBank(),
                ],
              ),
            ),
            _buildNavButtons(),
          ],
        ),
      ),
    );
  }
}

// ── Shared Step Wrapper ────────────────────────────────────────────────────

class _StepWrapper extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _StepWrapper({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.black,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
                color: AppColors.grey, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}