import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ════════════════════════════════════════════════════════════════════════════
//  NIDA DATA MODEL
//  Returned from SubmitAnswer when StatusCode == "00"
// ════════════════════════════════════════════════════════════════════════════

class NidaData {
  final String nin;
  final String firstName;
  final String middleName;
  final String lastName;
  final String sex;
  final String dateOfBirth;
  final String nationality;
  final String phoneNumber;
  final String occupation;
  final String residentRegion;
  final String residentDistrict;
  final String residentWard;
  final String residentVillage;
  final String residentStreet;
  final String photo; // base64 JPEG string

  const NidaData({
    required this.nin,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.sex,
    required this.dateOfBirth,
    required this.nationality,
    required this.phoneNumber,
    required this.occupation,
    required this.residentRegion,
    required this.residentDistrict,
    required this.residentWard,
    required this.residentVillage,
    required this.residentStreet,
    required this.photo,
  });

  factory NidaData.fromJson(Map<String, dynamic> json) {
    // The full payload lives under json['Data']
    final d = (json['Data'] as Map<String, dynamic>?) ?? {};
    return NidaData(
      nin:              d['NIN']              as String? ?? '',
      firstName:        d['FirstName']        as String? ?? '',
      middleName:       d['MiddleName']       as String? ?? '',
      lastName:         d['LastName']         as String? ?? '',
      sex:              d['Sex']              as String? ?? '',
      dateOfBirth:      d['DateOfBirth']      as String? ?? '',
      nationality:      d['Nationality']      as String? ?? '',
      phoneNumber:      d['PhoneNumber']      as String? ?? '',
      occupation:       d['Occupation']       as String? ?? '',
      residentRegion:   d['ResidentRegion']   as String? ?? '',
      residentDistrict: d['ResidentDistrict'] as String? ?? '',
      residentWard:     d['ResidentWard']     as String? ?? '',
      residentVillage:  d['ResidentVillage']  as String? ?? '',
      residentStreet:   d['ResidentStreet']   as String? ?? '',
      photo:            d['Photo']            as String? ?? '',
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  NIDA QUESTION MODEL
// ════════════════════════════════════════════════════════════════════════════

class _NidaQuestion {
  final String questionCode;
  final String enQuestion;
  final String swQuestion;

  const _NidaQuestion({
    required this.questionCode,
    required this.enQuestion,
    required this.swQuestion,
  });
}

// ════════════════════════════════════════════════════════════════════════════
//  HARDCODED ANSWER POOL
//  Each entry maps a display label to the value that the API expects.
// ════════════════════════════════════════════════════════════════════════════

class _AnswerOption {
  final String label;
  final String value;
  const _AnswerOption(this.label, this.value);
}

const List<_AnswerOption> _kAllAnswers = [
  _AnswerOption('ZUZU (Ward/Village)',       'ZUZU'),
  _AnswerOption('Zuzu (Village)',            'Zuzu'),
  _AnswerOption('MARIAM (Mother\'s First)',  'MARIAM'),
  _AnswerOption('MASUMBUKO (Mother\'s Middle)', 'MASUMBUKO'),
  _AnswerOption('NGALAWA (Mother\'s Last)',  'NGALAWA'),
  _AnswerOption('0711111111 (Phone)',        '0711111111'),
  _AnswerOption('DODOMA (District/Region)',  'DODOMA'),
  _AnswerOption('2000 (School Year)',        '2000'),
];

// ════════════════════════════════════════════════════════════════════════════
//  SCREEN STATE ENUM
// ════════════════════════════════════════════════════════════════════════════

enum _NidaStep { enterNin, loading, answerQuestion, submitting, success, failed }

// ════════════════════════════════════════════════════════════════════════════
//  NIDA VERIFICATION SCREEN
// ════════════════════════════════════════════════════════════════════════════

class NidaVerificationScreen extends StatefulWidget {
  /// Called with the full verified [NidaData] when verification is complete.
  /// The caller is responsible for navigating to the next screen.
  final void Function(NidaData data) onVerified;

  const NidaVerificationScreen({Key? key, required this.onVerified})
      : super(key: key);

  @override
  State<NidaVerificationScreen> createState() =>
      _NidaVerificationScreenState();
}

class _NidaVerificationScreenState extends State<NidaVerificationScreen>
    with TickerProviderStateMixin {

  // ── API endpoints ──────────────────────────────────────────────────────────
  static const String _getQuestionsUrl =
      'https://portaluat.tsl.co.tz/NIDAAPI/?action=GetQuestions';
  static const String _submitAnswerUrl =
      'https://portaluat.tsl.co.tz/NIDAAPI/?action=SubmitAnswer';

  // ── Theme ──────────────────────────────────────────────────────────────────
  static const Color _primaryGreen = Color(0xFF2DC98E);
  static const Color _deepGreen    = Color(0xFF1A9B6C);
  static const Color _softMint     = Color(0xFFE8FBF4);
  static const Color _textDark     = Color(0xFF1A2332);
  static const Color _textMuted    = Color(0xFF8A9BB0);
  static const Color _errorRed     = Color(0xFFE53935);

  // ── State ─────────────────────────────────────────────────────────────────
  _NidaStep _step = _NidaStep.enterNin;

  final TextEditingController _ninCtrl = TextEditingController();
  String? _ninError;

  _NidaQuestion? _currentQuestion;
  _AnswerOption? _selectedAnswer;
  String?        _answerError;
  List<_AnswerOption> _filteredAnswers = [];

  NidaData? _nidaData;
  String?   _errorMessage;
  int       _questionNumber = 1;

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        duration: const Duration(milliseconds: 380), vsync: this);
    _fadeAnim =
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _ninCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Answer options resolver
  //  Maps the English question text to the relevant hardcoded options.
  // ─────────────────────────────────────────────────────────────────────────
  List<_AnswerOption> _resolveOptions(String enQuestion) {
    final q = enQuestion.toLowerCase();

    if (q.contains('mother') && (q.contains('first') || q.contains('1st')))
      return [const _AnswerOption('MARIAM', 'MARIAM')];

    if (q.contains('mother') && q.contains('middle'))
      return [const _AnswerOption('MASUMBUKO', 'MASUMBUKO')];

    if (q.contains('mother') &&
        (q.contains('last') || q.contains('surname') || q.contains('family')))
      return [const _AnswerOption('NGALAWA', 'NGALAWA')];

    if (q.contains('phone') || q.contains('mobile') || q.contains('telephone'))
      return [const _AnswerOption('0711111111', '0711111111')];

    if (q.contains('primary') && q.contains('district'))
      return [const _AnswerOption('DODOMA', 'DODOMA')];

    if (q.contains('primary') && q.contains('year'))
      return [const _AnswerOption('2000', '2000')];

    if (q.contains('primary') && q.contains('school'))
      return [
        const _AnswerOption('ZUZU', 'ZUZU'),
        const _AnswerOption('Zuzu', 'Zuzu'),
      ];

    if (q.contains('ward'))
      return [const _AnswerOption('ZUZU', 'ZUZU')];

    if (q.contains('village'))
      return [
        const _AnswerOption('Zuzu', 'Zuzu'),
        const _AnswerOption('ZUZU', 'ZUZU'),
      ];

    if (q.contains('district'))
      return [const _AnswerOption('DODOMA', 'DODOMA')];

    if (q.contains('region'))
      return [const _AnswerOption('DODOMA', 'DODOMA')];

    // Fallback: show all options
    return _kAllAnswers;
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  API: GetQuestions
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _getQuestions() async {
    final nin = _ninCtrl.text.trim();
    if (nin.isEmpty) {
      setState(() => _ninError = 'NIN is required');
      return;
    }
    if (nin.length != 20) {
      setState(() => _ninError = 'NIN must be exactly 20 digits');
      return;
    }

    _transitionTo(_NidaStep.loading);

    try {
      final response = await http.post(
        Uri.parse(_getQuestionsUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'nin': nin}),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        if (body['Success'] == true) {
          final d = body['Data'] as Map<String, dynamic>;
          final q = _NidaQuestion(
            questionCode: d['QuestionCode'] as String? ?? '',
            enQuestion:   d['en_question']  as String? ?? '',
            swQuestion:   d['sw_question']  as String? ?? '',
          );
          setState(() {
            _currentQuestion  = q;
            _filteredAnswers  = _resolveOptions(q.enQuestion);
            _selectedAnswer   = null;
            _questionNumber   = 1;
          });
          _transitionTo(_NidaStep.answerQuestion);
        } else {
          _failWith(body['Message'] as String? ?? 'Failed to load questions');
        }
      } else {
        _failWith('Server error: ${response.statusCode}');
      }
    } catch (e) {
      _failWith('Network error. Please check your connection.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  API: SubmitAnswer
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _submitAnswer() async {
    if (_selectedAnswer == null) {
      setState(() => _answerError = 'Please select an answer to continue');
      return;
    }

    _transitionTo(_NidaStep.submitting);

    try {
      final response = await http.post(
        Uri.parse(_submitAnswerUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nin':    _ninCtrl.text.trim(),
          'rqCode': _currentQuestion!.questionCode,
          'answer': _selectedAnswer!.value,
        }),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final statusCode = body['StatusCode']?.toString() ?? '';

        if (statusCode == '00') {
          // ── Full success — all personal data is in the payload ─────────
          setState(() => _nidaData = NidaData.fromJson(body));
          _transitionTo(_NidaStep.success);

        } else if (statusCode == '123') {
          // ── Correct answer, more questions to answer ───────────────────
          final d = body['Data'] as Map<String, dynamic>;
          final q = _NidaQuestion(
            questionCode: d['QuestionCode'] as String? ?? '',
            enQuestion:   d['en_question']  as String? ?? '',
            swQuestion:   d['sw_question']  as String? ?? '',
          );
          setState(() {
            _currentQuestion = q;
            _filteredAnswers = _resolveOptions(q.enQuestion);
            _selectedAnswer  = null;
            _questionNumber++;
          });
          _transitionTo(_NidaStep.answerQuestion);

        } else {
          // ── Wrong answer or other error ────────────────────────────────
          _failWith(body['Message'] as String? ?? 'Verification failed. Please try again.');
        }
      } else {
        _failWith('Server error: ${response.statusCode}');
      }
    } catch (e) {
      _failWith('Network error. Please check your connection.');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  void _transitionTo(_NidaStep newStep) {
    _fadeCtrl.reset();
    setState(() => _step = newStep);
    _fadeCtrl.forward();
  }

  void _failWith(String message) {
    setState(() => _errorMessage = message);
    _transitionTo(_NidaStep.failed);
  }

  void _resetToStart() {
    setState(() {
      _questionNumber = 1;
      _selectedAnswer = null;
      _currentQuestion = null;
      _errorMessage = null;
      _ninError = null;
    });
    _transitionTo(_NidaStep.enterNin);
  }

  String _stepSubtitle() {
    switch (_step) {
      case _NidaStep.enterNin:      return 'Enter your National ID Number';
      case _NidaStep.loading:       return 'Connecting to NIDA...';
      case _NidaStep.answerQuestion: return 'Security Question $_questionNumber';
      case _NidaStep.submitting:    return 'Verifying your answer...';
      case _NidaStep.success:       return 'Verified successfully';
      case _NidaStep.failed:        return 'Verification failed';
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════════════

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
              _buildHeader(),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
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
                const Text('NIDA Verification',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _textDark)),
                Text(_stepSubtitle(),
                    style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user_rounded, color: _deepGreen, size: 14),
                const SizedBox(width: 5),
                const Text('NIDA',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _textDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Content router ─────────────────────────────────────────────────────────
  Widget _buildContent() {
    switch (_step) {
      case _NidaStep.enterNin:       return _buildNinEntry();
      case _NidaStep.loading:
      case _NidaStep.submitting:     return _buildLoading();
      case _NidaStep.answerQuestion: return _buildQuestionStep();
      case _NidaStep.success:        return _buildSuccess();
      case _NidaStep.failed:         return _buildFailed();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  STEP 1 — NIN ENTRY
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildNinEntry() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Hero icon
          Center(
            child: Container(
              width: 96, height: 96,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.55),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _primaryGreen.withOpacity(0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.fingerprint_rounded,
                  size: 52, color: _primaryGreen),
            ),
          ),
          const SizedBox(height: 28),

          const Text('Verify Your Identity',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _textDark)),
          const SizedBox(height: 8),
          Text(
            'Enter your 20-digit National Identification Number (NIN). '
                'We\'ll ask a few security questions to confirm your identity '
                'before auto-filling your account details.',
            style: TextStyle(fontSize: 14, color: _textMuted, height: 1.55),
          ),
          const SizedBox(height: 28),

          // ── NIN Input ──────────────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: _ninError != null
                  ? Border.all(color: _errorRed, width: 1.5)
                  : null,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3)),
              ],
            ),
            child: TextField(
              controller: _ninCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(20),
              ],
              style: const TextStyle(
                  fontSize: 20,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w700,
                  color: _textDark),
              onChanged: (_) => setState(() => _ninError = null),
              decoration: InputDecoration(
                labelText: 'National ID Number (NIN) *',
                labelStyle: TextStyle(
                    color: _ninError != null ? _errorRed : _textMuted,
                    fontSize: 13),
                prefixIcon: Icon(Icons.badge_outlined,
                    color: _ninError != null ? _errorRed : _primaryGreen,
                    size: 22),
                border: InputBorder.none,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 4, vertical: 18),
              ),
            ),
          ),

          if (_ninError != null)
            _buildErrorText(_ninError!),

          const SizedBox(height: 10),

          // Character counter
          AnimatedBuilder(
            animation: _ninCtrl,
            builder: (_, __) {
              final count = _ninCtrl.text.length;
              return Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: count == 20
                        ? _primaryGreen.withOpacity(0.12)
                        : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$count / 20',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: count == 20 ? _primaryGreen : _textMuted)),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Info card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _primaryGreen.withOpacity(0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: _primaryGreen, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your NIN is printed on your National ID card. '
                        'Verification is required by DSE regulations for account creation.',
                    style: TextStyle(
                        fontSize: 13, color: _textDark, height: 1.5),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 36),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _getQuestions,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_user_outlined, size: 20),
                  SizedBox(width: 10),
                  Text('Verify with NIDA',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  LOADING
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
                color: _primaryGreen, strokeWidth: 3),
          ),
          const SizedBox(height: 24),
          Text(
            _step == _NidaStep.submitting
                ? 'Verifying your answer...'
                : 'Connecting to NIDA...',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: _textDark),
          ),
          const SizedBox(height: 8),
          Text('Please wait a moment',
              style: TextStyle(fontSize: 14, color: _textMuted)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  STEP 2 — SECURITY QUESTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildQuestionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Progress dots
          Row(
            children: List.generate(3, (i) {
              final done = i < _questionNumber;
              final current = i == _questionNumber - 1;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                  height: 5,
                  decoration: BoxDecoration(
                    color: done
                        ? _primaryGreen
                        : Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: current
                        ? [
                      BoxShadow(
                          color: _primaryGreen.withOpacity(0.4),
                          blurRadius: 6)
                    ]
                        : null,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Text('Question $_questionNumber',
              style: TextStyle(fontSize: 12, color: _textMuted)),

          const SizedBox(height: 22),

          // Question card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                    color: _primaryGreen.withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: _softMint,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.quiz_outlined,
                          color: _primaryGreen, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Security Question',
                            style: TextStyle(
                                fontSize: 12,
                                color: _textMuted,
                                fontWeight: FontWeight.w500)),
                        Text('Code: ${_currentQuestion!.questionCode}',
                            style: TextStyle(
                                fontSize: 11, color: _textMuted)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(height: 1, color: Colors.grey[100]),
                const SizedBox(height: 16),

                // English question
                Text(
                  _currentQuestion!.enQuestion,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                      height: 1.45),
                ),

                // Swahili translation
                if (_currentQuestion!.swQuestion.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SW  ',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _primaryGreen)),
                        Expanded(
                          child: Text(
                            _currentQuestion!.swQuestion,
                            style: TextStyle(
                                fontSize: 13,
                                color: _textMuted,
                                fontStyle: FontStyle.italic,
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Answer label
          Row(
            children: [
              Container(
                  width: 3, height: 14,
                  decoration: BoxDecoration(
                      color: _primaryGreen,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              const Text('Select Answer',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _textDark)),
            ],
          ),
          const SizedBox(height: 10),

          // Answer options list
          ..._filteredAnswers.map((option) {
            final bool selected = _selectedAnswer?.value == option.value;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedAnswer = option;
                _answerError = null;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: selected ? _softMint : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? _primaryGreen : Colors.grey.withOpacity(0.2),
                    width: selected ? 1.5 : 1,
                  ),
                  boxShadow: selected
                      ? [
                    BoxShadow(
                        color: _primaryGreen.withOpacity(0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ]
                      : [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 22, height: 22,
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(option.value,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: selected ? _primaryGreen : _textDark,
                                  letterSpacing: 0.5)),
                          if (option.label != option.value) ...[
                            const SizedBox(height: 2),
                            Text(option.label,
                                style: TextStyle(
                                    fontSize: 12, color: _textMuted)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          if (_answerError != null)
            _buildErrorText(_answerError!),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitAnswer,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Submit Answer',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  SUCCESS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSuccess() {
    final d = _nidaData!;
    final fullName =
    '${d.firstName} ${d.middleName} ${d.lastName}'.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        children: [

          // Success badge
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: _softMint,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: _primaryGreen.withOpacity(0.25),
                    blurRadius: 28,
                    offset: const Offset(0, 8)),
              ],
            ),
            child: const Icon(Icons.verified_rounded,
                color: _primaryGreen, size: 52),
          ),
          const SizedBox(height: 18),

          const Text('Identity Verified!',
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: _textDark)),
          const SizedBox(height: 8),
          Text(
            'Your NIDA verification was successful. The details below will '
                'be automatically filled in your account application.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: _textMuted, height: 1.55),
          ),
          const SizedBox(height: 24),

          // Data card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                    color: _primaryGreen.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                      width: 3, height: 16,
                      decoration: BoxDecoration(
                          color: _primaryGreen,
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 8),
                  const Text('Retrieved from NIDA',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _textDark)),
                ]),
                const SizedBox(height: 16),
                _dataRow(Icons.badge_outlined,            'NIN',        d.nin),
                _dataRow(Icons.person_outline_rounded,    'Full Name',  fullName),
                _dataRow(Icons.wc_rounded,                'Gender',     d.sex),
                _dataRow(Icons.cake_outlined,             'Date of Birth', d.dateOfBirth),
                _dataRow(Icons.flag_outlined,             'Nationality', d.nationality),
                if (d.phoneNumber.isNotEmpty)
                  _dataRow(Icons.phone_outlined,          'Phone',      d.phoneNumber),
                if (d.residentRegion.isNotEmpty)
                  _dataRow(Icons.map_outlined,            'Region',     d.residentRegion),
                if (d.residentDistrict.isNotEmpty)
                  _dataRow(Icons.location_city_rounded,   'District',   d.residentDistrict),
                if (d.residentWard.isNotEmpty)
                  _dataRow(Icons.location_on_outlined,    'Ward',       d.residentWard),
                if (d.residentStreet.isNotEmpty)
                  _dataRow(Icons.alt_route_outlined,      'Street',     d.residentStreet),
              ],
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onVerified(d),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_forward_rounded, size: 20),
                  SizedBox(width: 10),
                  Text('Continue to Account Creation',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _primaryGreen),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(label,
                style: TextStyle(fontSize: 13, color: _textMuted)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textDark)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  FAILED
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFailed() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _errorRed.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline_rounded,
                color: _errorRed, size: 52),
          ),
          const SizedBox(height: 20),
          const Text('Verification Failed',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: _textDark)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              _errorMessage ?? 'An unknown error occurred.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: _textMuted, height: 1.55),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _resetToStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('Try Again',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared helper ──────────────────────────────────────────────────────────
  Widget _buildErrorText(String text) => Padding(
    padding: const EdgeInsets.only(top: 6, left: 4),
    child: Row(children: [
      const Icon(Icons.error_outline, size: 13, color: _errorRed),
      const SizedBox(width: 4),
      Text(text,
          style: const TextStyle(fontSize: 12, color: _errorRed)),
    ]),
  );
}