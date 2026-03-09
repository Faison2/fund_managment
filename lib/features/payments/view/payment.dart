import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../provider/locale_provider.dart';
import '../../../../provider/theme_provider.dart';

// ── Localised strings ─────────────────────────────────────────────────────────
class _BS {
  final String bankingDetails, subtitle,
      bank, accountNo, accountName, branch,
      notSet, editDetails, saveChanges, cancel,
      editComingSoon, refreshed, noDetails,
      names, email, mobile, address;
  const _BS({
    required this.bankingDetails,  required this.subtitle,
    required this.bank,            required this.accountNo,
    required this.accountName,     required this.branch,
    required this.notSet,          required this.editDetails,
    required this.saveChanges,     required this.cancel,
    required this.editComingSoon,  required this.refreshed,
    required this.noDetails,       required this.names,
    required this.email,           required this.mobile,
    required this.address,
  });
}

const _bsEn = _BS(
  bankingDetails: 'Banking Details',
  subtitle:       'Your linked bank account information',
  bank:           'Bank',
  accountNo:      'Account Number',
  accountName:    'Account Name',
  branch:         'Branch',
  notSet:         'Not set',
  editDetails:    'Edit Details',
  saveChanges:    'Save Changes',
  cancel:         'Cancel',
  editComingSoon: 'Edit functionality coming soon.',
  refreshed:      'Details refreshed',
  noDetails:      'No banking details found.\nComplete your profile to add banking info.',
  names:          'Full Name',
  email:          'Email',
  mobile:         'Mobile',
  address:        'Address',
);

const _bsSw = _BS(
  bankingDetails: 'Maelezo ya Benki',
  subtitle:       'Taarifa za akaunti yako ya benki iliyounganishwa',
  bank:           'Benki',
  accountNo:      'Nambari ya Akaunti',
  accountName:    'Jina la Akaunti',
  branch:         'Tawi',
  notSet:         'Haijawekwa',
  editDetails:    'Hariri Maelezo',
  saveChanges:    'Hifadhi Mabadiliko',
  cancel:         'Ghairi',
  editComingSoon: 'Utendaji wa uhariri unakuja hivi karibuni.',
  refreshed:      'Maelezo yamesasishwa',
  noDetails:      'Hakuna maelezo ya benki.\nKamilisha wasifu wako kuongeza taarifa za benki.',
  names:          'Jina Kamili',
  email:          'Barua pepe',
  mobile:         'Simu',
  address:        'Anwani',
);

// ── BankingDetailsPage ────────────────────────────────────────────────────────
class BankingDetailsPage extends StatefulWidget {
  const BankingDetailsPage({Key? key}) : super(key: key);

  @override
  State<BankingDetailsPage> createState() => _BankingDetailsPageState();
}

class _BankingDetailsPageState extends State<BankingDetailsPage> {
  // ── Data from SharedPreferences ────────────────────────────────────────────
  String _names       = '';
  String _email       = '';
  String _mobile      = '';
  String _address     = '';
  String _bank        = '';
  String _accountNo   = '';
  String _accountName = '';
  String _branch      = '';
  bool   _loading     = true;

  bool get _dark => context.watch<ThemeProvider>().isDark;
  _BS  get _s    => context.watch<LocaleProvider>().isSwahili ? _bsSw : _bsEn;

  @override
  void initState() {
    super.initState();
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    setState(() => _loading = true);
    final p = await SharedPreferences.getInstance();
    setState(() {
      _names       = p.getString('user_names')       ?? '';
      _email       = p.getString('user_email')       ?? '';
      _mobile      = p.getString('user_mobile')      ?? '';
      _address     = p.getString('user_address')     ?? '';
      _bank        = p.getString('user_bank')        ?? '';
      _accountNo   = p.getString('user_accountNo')   ?? '';
      _accountName = p.getString('user_accountName') ?? '';
      _branch      = p.getString('user_branch')      ?? '';
      _loading     = false;
    });
  }

  bool get _hasAnyData =>
      _bank.isNotEmpty || _accountNo.isNotEmpty ||
          _accountName.isNotEmpty || _branch.isNotEmpty;

  // ── Edit bottom sheet (placeholder — API tomorrow) ─────────────────────────
  void _showEditSheet() {
    final dark   = _dark; final s = _s;
    final sheetBg = dark ? const Color(0xFF132013) : Colors.white;
    final border  = dark ? const Color(0xFF1E3320) : const Color(0xFFE5E7EB);
    final txtP    = dark ? const Color(0xFFE8F5E9) : Colors.black87;
    final txtS    = dark ? const Color(0xFF81A884)  : Colors.black54;
    final txtH    = dark ? const Color(0xFF4A7A4D)  : Colors.grey.shade400;
    final green   = dark ? const Color(0xFF4ADE80)  : const Color(0xFF15803D);
    final inputBg = dark ? const Color(0xFF0F1A10)  : const Color(0xFFF9FAFB);

    // Pre-fill controllers with current values
    final bankCtrl        = TextEditingController(text: _bank);
    final accountNoCtrl   = TextEditingController(text: _accountNo);
    final accountNameCtrl = TextEditingController(text: _accountName);
    final branchCtrl      = TextEditingController(text: _branch);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: Column(mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start, children: [

                    // Handle bar
                    Center(child: Container(width: 40, height: 4,
                        decoration: BoxDecoration(
                            color: border, borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 20),

                    Text(s.editDetails, style: TextStyle(fontSize: 20,
                        fontWeight: FontWeight.w900, color: txtP)),
                    const SizedBox(height: 4),
                    Text(s.editComingSoon,
                        style: TextStyle(fontSize: 13, color: txtS)),
                    const SizedBox(height: 24),

                    _editField(s.bank,        bankCtrl,        Icons.account_balance_outlined,  green, txtP, txtH, inputBg, border),
                    const SizedBox(height: 14),
                    _editField(s.accountNo,   accountNoCtrl,   Icons.credit_card_outlined,       green, txtP, txtH, inputBg, border,
                        keyboardType: TextInputType.number),
                    const SizedBox(height: 14),
                    _editField(s.accountName, accountNameCtrl, Icons.badge_outlined,             green, txtP, txtH, inputBg, border),
                    const SizedBox(height: 14),
                    _editField(s.branch,      branchCtrl,      Icons.store_outlined,             green, txtP, txtH, inputBg, border),
                    const SizedBox(height: 28),

                    // Buttons
                    Row(children: [
                      Expanded(child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(height: 50,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: border, width: 1.5)),
                            child: Center(child: Text(s.cancel,
                                style: TextStyle(color: txtS,
                                    fontWeight: FontWeight.w600)))),
                      )),
                      const SizedBox(width: 14),
                      Expanded(child: GestureDetector(
                        // TODO: wire up to API when ready
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(s.editComingSoon),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: dark
                                ? const Color(0xFF132013) : Colors.black87,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ));
                        },
                        child: Container(height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  colors: [green, green.withOpacity(0.75)]),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [BoxShadow(
                                  color: green.withOpacity(0.3),
                                  blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: Center(child: Text(s.saveChanges,
                                style: const TextStyle(color: Colors.white,
                                    fontWeight: FontWeight.w700)))),
                      )),
                    ]),
                  ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _editField(
      String label,
      TextEditingController ctrl,
      IconData icon,
      Color green, Color txtP, Color txtH, Color inputBg, Color border, {
        TextInputType keyboardType = TextInputType.text,
      }) =>
      TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: txtP),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: txtH, fontSize: 13),
          prefixIcon: Icon(icon, color: green, size: 20),
          filled: true, fillColor: inputBg,
          border: OutlineInputBorder(
              borderSide: BorderSide(color: border),
              borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: border),
              borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: green, width: 2),
              borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
        ),
      );

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    context.watch<LocaleProvider>();

    final dark    = _dark; final s = _s;
    final bg      = dark ? const Color(0xFF0B1A0C) : const Color(0xFFB8E6D3);
    final sheet   = dark ? const Color(0xFF111D12) : Colors.white;
    final border  = dark ? const Color(0xFF1E3320) : const Color(0xFFE5E7EB);
    final txtP    = dark ? const Color(0xFFE8F5E9) : Colors.black87;
    final txtS    = dark ? const Color(0xFF81A884)  : Colors.black54;
    final txtH    = dark ? const Color(0xFF4A7A4D)  : Colors.grey.shade400;
    final green   = dark ? const Color(0xFF4ADE80)  : const Color(0xFF15803D);
    final cardBg  = dark ? const Color(0xFF132013)  : const Color(0xFFF9FAFB);
    final infoBg  = dark ? const Color(0xFF0F1A10)  : const Color(0xFFF0FDF4);

    return Scaffold(
      backgroundColor: bg,
      body: Column(children: [

        // ── Gradient header ──────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            gradient: dark
                ? const LinearGradient(begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0B1A0C), Color(0xFF132013), Color(0xFF09100A)])
                : const LinearGradient(begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)]),
          ),
          child: SafeArea(bottom: false, child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 18)),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.bankingDetails, style: const TextStyle(
                    color: Colors.white, fontSize: 22,
                    fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                const SizedBox(height: 2),
                Text(s.subtitle, style: TextStyle(
                    color: Colors.white.withOpacity(0.65), fontSize: 12)),
              ])),
              // Edit button in header
              GestureDetector(
                onTap: _showEditSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.25))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.edit_outlined,
                        color: Colors.white, size: 15),
                    const SizedBox(width: 6),
                    Text(s.editDetails, style: const TextStyle(
                        color: Colors.white, fontSize: 12,
                        fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ]),
          )),
        ),

        // ── Body ─────────────────────────────────────────────────────────────
        Expanded(
          child: Container(color: sheet,
            child: _loading
                ? Center(child: CircularProgressIndicator(
                color: green, strokeWidth: 2.5))
                : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── No data state ───────────────────────────────────────
                    if (!_hasAnyData)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: border)),
                        child: Column(children: [
                          Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                  color: green.withOpacity(0.1),
                                  shape: BoxShape.circle),
                              child: Icon(Icons.account_balance_outlined,
                                  color: green, size: 32)),
                          const SizedBox(height: 16),
                          Text(s.noDetails,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 14, color: txtS, height: 1.6)),
                        ]),
                      ),

                    // ── Banking section ─────────────────────────────────────
                    if (_hasAnyData) ...[
                      _sectionLabel('Banking Information', txtH),
                      const SizedBox(height: 12),
                      _detailCard([
                        _DetailItem(Icons.account_balance_outlined, s.bank,
                            _bank.isNotEmpty ? _bank : s.notSet),
                        _DetailItem(Icons.credit_card_outlined, s.accountNo,
                            _accountNo.isNotEmpty ? _accountNo : s.notSet),
                        _DetailItem(Icons.badge_outlined, s.accountName,
                            _accountName.isNotEmpty ? _accountName : s.notSet),
                        _DetailItem(Icons.store_outlined, s.branch,
                            _branch.isNotEmpty ? _branch : s.notSet),
                      ], green, txtP, txtS, border, infoBg, dark),
                    ],

                    // ── Personal section (always if any data saved) ─────────
                    if (_names.isNotEmpty || _email.isNotEmpty ||
                        _mobile.isNotEmpty || _address.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      _sectionLabel('Account Information', txtH),
                      const SizedBox(height: 12),
                      _detailCard([
                        if (_names.isNotEmpty)
                          _DetailItem(Icons.person_outline, s.names, _names),
                        if (_email.isNotEmpty)
                          _DetailItem(Icons.email_outlined, s.email, _email),
                        if (_mobile.isNotEmpty)
                          _DetailItem(Icons.phone_outlined, s.mobile, _mobile),
                        if (_address.isNotEmpty)
                          _DetailItem(Icons.location_on_outlined, s.address, _address),
                      ], green, txtP, txtS, border, cardBg, dark),
                    ],

                    const SizedBox(height: 32),

                    // ── Edit CTA button ─────────────────────────────────────
                    GestureDetector(
                      onTap: _showEditSheet,
                      child: Container(
                        width: double.infinity, height: 54,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: [green, green.withOpacity(0.75)]),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(
                              color: green.withOpacity(0.3),
                              blurRadius: 14,
                              offset: const Offset(0, 6))],
                        ),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.edit_outlined,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 10),
                              Text(s.editDetails, style: const TextStyle(
                                  color: Colors.white, fontSize: 15,
                                  fontWeight: FontWeight.w700)),
                            ]),
                      ),
                    ),
                  ]),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Section label ──────────────────────────────────────────────────────────
  Widget _sectionLabel(String t, Color c) => Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(t.toUpperCase(), style: TextStyle(fontSize: 11,
          fontWeight: FontWeight.w800, color: c, letterSpacing: 1.2)));

  // ── Detail card ────────────────────────────────────────────────────────────
  Widget _detailCard(
      List<_DetailItem> items,
      Color green, Color txtP, Color txtS, Color border, Color bg, bool dark,
      ) {
    return Container(
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border)),
      child: Column(
        children: items.asMap().entries.map((e) {
          final item  = e.value;
          final last  = e.key == items.length - 1;
          return Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(item.icon, color: green, size: 17),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.label, style: TextStyle(
                      fontSize: 11, color: txtS,
                      fontWeight: FontWeight.w500)),
                  const SizedBox(height: 3),
                  Text(item.value, style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: txtP),
                      overflow: TextOverflow.ellipsis),
                ])),
              ]),
            ),
            if (!last)
              Divider(height: 1,
                  color: border, indent: 16, endIndent: 16),
          ]);
        }).toList(),
      ),
    );
  }
}

// ── Simple data class for detail rows ────────────────────────────────────────
class _DetailItem {
  final IconData icon;
  final String label;
  final String value;
  const _DetailItem(this.icon, this.label, this.value);
}