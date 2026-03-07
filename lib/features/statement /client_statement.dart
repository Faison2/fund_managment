import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../provider/locale_provider.dart';
import '../../provider/theme_provider.dart';
import '../funds/model/model.dart';
import '../funds/repository/repository.dart';

class _Txn {
  final String id, description, rawDate;
  final double units, price, amount;
  final bool isDeposit;
  _Txn({required this.id,required this.description,required this.rawDate,
    required this.units,required this.price,required this.amount,required this.isDeposit});
  DateTime get date {
    try { return DateFormat('dd-MMM-yyyy HH:mm').parse(rawDate); }
    catch (_) { return DateTime.now(); }
  }
  factory _Txn.fromJson(Map<String, dynamic> j) {
    final desc  = j['Description'] as String? ?? '';
    final lower = desc.toLowerCase();
    return _Txn(
      id: j['TrxnID']?.toString() ?? '', description: desc,
      rawDate: j['TrxnDate'] as String? ?? '',
      units:  double.tryParse(j['Units']?.toString()  ?? '0') ?? 0,
      price:  double.tryParse(j['Price']?.toString()  ?? '0') ?? 0,
      amount: double.tryParse(j['amount']?.toString() ?? '0') ?? 0,
      isDeposit: lower.contains('deposit') || lower.contains('credit') ||
          lower.contains('purchase') || lower.contains('buy'),
    );
  }
}

enum _Filter { both, deposits, withdrawals }

class ClientStatementPage extends StatefulWidget {
  const ClientStatementPage({Key? key}) : super(key: key);
  @override
  State<ClientStatementPage> createState() => _ClientStatementPageState();
}

class _ClientStatementPageState extends State<ClientStatementPage>
    with TickerProviderStateMixin {

  String _cdsNumber = '', _userName = '';
  List<Fund> _funds = []; Fund? _selectedFund;
  bool _loadingFunds = true; String _fundsError = '';
  List<_Txn> _allTxns = [];
  bool _loadingTxns = false; String? _txnsError; bool _hasFetched = false;
  _Filter _filter = _Filter.both;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // Colour + string shortcuts
  bool  get _dark   => context.watch<ThemeProvider>().isDark;
  _CS   get _s      => context.watch<LocaleProvider>().isSwahili ? _sw : _en;
  Color get _bg     => _dark ? TSLColors.darkBg      : const Color(0xFFF0FBF5);
  Color get _card   => _dark ? TSLColors.darkCard     : Colors.white;
  Color get _card2  => _dark ? TSLColors.darkCard2    : Colors.white;
  Color get _border => _dark ? TSLColors.darkBorder   : Colors.grey.shade200;
  Color get _txtP   => _dark ? TSLColors.darkTextPrim : const Color(0xFF111827);
  Color get _txtS   => _dark ? TSLColors.darkTextSec  : Colors.grey.shade500;
  Color get _accent => _dark ? TSLColors.green500     : const Color(0xFF1B5E20);

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _init();
  }
  @override
  void dispose() { _fadeCtrl.dispose(); super.dispose(); }

  Future<void> _init() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _cdsNumber = p.getString('cdsNumber')     ?? '';
      _userName  = p.getString('user_fullname') ?? 'Investor';
    });
    _loadFunds();
  }

  Future<void> _loadFunds() async {
    setState(() { _loadingFunds = true; _fundsError = ''; });
    try {
      final funds = await FundsRepository().fetchFunds();
      setState(() { _funds = funds; _selectedFund = funds.isNotEmpty ? funds.first : null; _loadingFunds = false; });
    } catch (_) { setState(() { _fundsError = _s.failedFunds; _loadingFunds = false; }); }
  }

  Future<void> _fetchTransactions() async {
    if (_selectedFund == null) return;
    setState(() { _loadingTxns = true; _txnsError = null; _hasFetched = false; });
    try {
      final response = await http.post(
        Uri.parse('https://portaluat.tsl.co.tz/FMSAPI/home/GetTransactions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'APIUsername': 'User2', 'APIPassword': 'CBZ1234#2',
          'cdsNumber': _cdsNumber, 'Fund': _selectedFund!.fundingName ?? '',
        }),
      ).timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        final raw = (data['data']['trans'] as List<dynamic>?) ?? [];
        setState(() {
          _allTxns = raw.map((j) => _Txn.fromJson(j)).toList()
            ..sort((a, b) => b.date.compareTo(a.date));
          _loadingTxns = false; _hasFetched = true;
        });
        _fadeCtrl..reset()..forward();
      } else {
        setState(() { _txnsError = data['statusDesc'] ?? _s.failedTxns; _loadingTxns = false; _hasFetched = true; });
      }
    } catch (_) {
      setState(() { _txnsError = _s.connError; _loadingTxns = false; _hasFetched = true; });
    }
  }

  List<_Txn> get _filtered {
    switch (_filter) {
      case _Filter.deposits:    return _allTxns.where((t) =>  t.isDeposit).toList();
      case _Filter.withdrawals: return _allTxns.where((t) => !t.isDeposit).toList();
      case _Filter.both:        return _allTxns;
    }
  }
  double get _totalDeposits    => _allTxns.where((t) =>  t.isDeposit).fold(0.0, (s,t)=>s+t.amount);
  double get _totalWithdrawals => _allTxns.where((t) => !t.isDeposit).fold(0.0, (s,t)=>s+t.amount);
  double get _netFlow          => _totalDeposits - _totalWithdrawals;

  String _fmt(double v) {
    final s = v.toStringAsFixed(2).split('.');
    return '${s[0].replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'),(m)=>'${m[1]},')}.\${s[1]}';
  }

  Future<void> _downloadPDF() async {
    final pdf = pw.Document();
    final txns = _filtered;
    final fundName = _selectedFund?.fundingName ?? 'Fund';
    final now  = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => [
        pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('#1B5E20'),
              borderRadius: pw.BorderRadius.circular(12)),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('TSL Investment',
                style: pw.TextStyle(color: PdfColors.white, fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(_s.clientStatement, style: pw.TextStyle(color: PdfColors.white, fontSize: 13)),
          ]),
        ),
        pw.SizedBox(height: 20),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            _pdfLbl('${_s.cdsNumber}:', _cdsNumber),
            pw.SizedBox(height:6), _pdfLbl('${_s.fund}:', fundName),
            pw.SizedBox(height:6), _pdfLbl('${_s.generated}:', now),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            _pdfLbl('${_s.totalDeposits}:', 'TZS ${_fmt(_totalDeposits)}'),
            pw.SizedBox(height:6), _pdfLbl('${_s.totalWithdrawals}:', 'TZS ${_fmt(_totalWithdrawals)}'),
            pw.SizedBox(height:6), _pdfLbl('${_s.netFlow}:', 'TZS ${_fmt(_netFlow)}'),
          ]),
        ]),
        pw.SizedBox(height: 24),
        pw.Table(
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1.5),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(2)
          },
          children: [
            // Header row
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColor.fromHex('#E8F5E9')),
              children: [_s.description, _s.units, _s.date, _s.amountTZS]
                  .map((h) => pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: pw.Text(h,
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 10,
                                color: PdfColor.fromHex('#1B5E20'))),
                      ))
                  .toList(),
            ),

            // Data rows
            ...txns.asMap().entries.map((e) {
              final t = e.value;
              final odd = e.key.isOdd;
              return pw.TableRow(
                decoration: pw.BoxDecoration(color: odd ? PdfColors.grey100 : PdfColors.white),
                children: [
                  t.description,
                  _fmt(t.units),
                  DateFormat('dd MMM yy').format(t.date),
                  '${t.isDeposit ? '+' : '-'} ${_fmt(t.amount)}',
                ]
                    .map((cell) => pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: pw.Text(cell,
                              style: pw.TextStyle(
                                  fontSize: 9,
                                  color: cell.startsWith('+')
                                      ? PdfColors.green800
                                      : cell.startsWith('-')
                                          ? PdfColors.red800
                                          : PdfColors.black)),
                        ))
                    .toList(),
              );
            }).toList(),
          ],
        ),
        pw.SizedBox(height:20), pw.Divider(), pw.SizedBox(height:8),
        pw.Text(_s.pdfFooter, style: const pw.TextStyle(fontSize:8,color:PdfColors.grey600)),
      ],
    ));
    await Printing.layoutPdf(
      onLayout: (fmt) => pdf.save(),
      name: 'TSL_Statement_${fundName.replaceAll(' ','_')}.pdf',
    );
  }

  pw.Widget _pdfLbl(String label, String value) => pw.RichText(text: pw.TextSpan(children: [
    pw.TextSpan(text: '$label ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize:10, color:PdfColors.grey700)),
    pw.TextSpan(text: value,    style: const pw.TextStyle(fontSize:10, color:PdfColors.black)),
  ]));

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    context.watch<LocaleProvider>();
    return Scaffold(
      backgroundColor: _bg,
      body: Column(children: [_buildHeader(), Expanded(child: _buildBody())]),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: _dark
            ? const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,
            colors:[Color(0xFF0B1A0C),Color(0xFF132013),Color(0xFF09100A)])
            : const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,
            colors:[Color(0xFF1B5E20),Color(0xFF2E7D32),Color(0xFF388E3C)]),
      ),
      child: SafeArea(bottom: false, child: Padding(
        padding: const EdgeInsets.fromLTRB(20,12,20,24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
              ),
            ),
            const Spacer(),
            if (_hasFetched && _filtered.isNotEmpty)
              GestureDetector(
                onTap: _downloadPDF,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal:14, vertical:8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.4))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.picture_as_pdf, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(_s.downloadPDF, style: const TextStyle(
                        color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
          ]),
          const SizedBox(height: 18),
          Text(_s.clientStatement, style: const TextStyle(color: Colors.white,
              fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(_s.statementSubtitle,
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
        ]),
      )),
    );
  }

  Widget _buildBody() {
    return Container(
      decoration: BoxDecoration(color: _bg,
          borderRadius: const BorderRadius.only(topLeft:Radius.circular(28),topRight:Radius.circular(28))),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(topLeft:Radius.circular(28),topRight:Radius.circular(28)),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20,24,20,40),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildFundPicker(), const SizedBox(height:20),
              _buildFilterChips(), const SizedBox(height:20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_loadingFunds||_loadingTxns) ? null : _fetchTransactions,
                  icon: _loadingTxns
                      ? const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white))
                      : const Icon(Icons.search_rounded, size:20),
                  label: Text(_loadingTxns ? _s.loading : _s.loadTransactions,
                      style: const TextStyle(fontSize:15,fontWeight:FontWeight.w700)),
                  style: ElevatedButton.styleFrom(backgroundColor:_accent,foregroundColor:Colors.white,
                      padding:const EdgeInsets.symmetric(vertical:15),
                      shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16)),elevation:0),
                ),
              ),
              const SizedBox(height:24),
              if (_hasFetched) ...[
                if (_txnsError != null) _buildError()
                else ...[ _buildSummaryCards(), const SizedBox(height:20), _buildTransactionList() ],
              ],
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildFundPicker() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_s.selectFund, style: TextStyle(fontSize:13,fontWeight:FontWeight.w700,
          color:_accent,letterSpacing:0.3)),
      const SizedBox(height:10),
      if (_loadingFunds)
        Container(height:58,
          decoration:BoxDecoration(color:_card,borderRadius:BorderRadius.circular(16),
              border:Border.all(color:_border),
              boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.06),blurRadius:12,offset:const Offset(0,4))]),
          child:Center(child:SizedBox(width:18,height:18,
              child:CircularProgressIndicator(strokeWidth:2,color:_accent))),)
      else if (_fundsError.isNotEmpty)
        GestureDetector(onTap:_loadFunds,child:Container(
          padding:const EdgeInsets.symmetric(horizontal:16,vertical:14),
          decoration:BoxDecoration(
              color:_dark?const Color(0xFF2D0A0A):Colors.red.shade50,
              borderRadius:BorderRadius.circular(16),
              border:Border.all(color:_dark?const Color(0xFF5C1A1A):Colors.red.shade200)),
          child:Row(children:[
            const Icon(Icons.error_outline,color:Colors.red,size:18),const SizedBox(width:10),
            Expanded(child:Text(_fundsError,style:TextStyle(color:_dark?Colors.red.shade300:Colors.red))),
            Text(_s.retry,style:TextStyle(color:Colors.red.shade400,fontWeight:FontWeight.w600)),
          ]),
        ))
      else
        Container(
          padding:const EdgeInsets.symmetric(horizontal:16,vertical:4),
          decoration:BoxDecoration(color:_card,borderRadius:BorderRadius.circular(16),
              border:Border.all(color:_border),
              boxShadow:[BoxShadow(color:Colors.black.withOpacity(_dark?0.2:0.06),blurRadius:12,offset:const Offset(0,4))]),
          child:DropdownButtonHideUnderline(child:DropdownButton<Fund>(
            value:_selectedFund,isExpanded:true,dropdownColor:_card,
            icon:Icon(Icons.keyboard_arrow_down,color:_accent),
            items:_funds.map((fund){
              final isActive = fund.status?.toLowerCase()=='active';
              return DropdownMenuItem<Fund>(value:fund,child:Row(children:[
                Container(width:10,height:10,decoration:BoxDecoration(
                    color:isActive?Colors.green:Colors.orange,shape:BoxShape.circle)),
                const SizedBox(width:10),
                Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[
                  Text(fund.fundingName??'Unknown Fund',
                      style:TextStyle(fontWeight:FontWeight.w700,fontSize:14,color:_txtP),
                      overflow:TextOverflow.ellipsis),
                  if(fund.issuer!=null) Text(fund.issuer!,style:TextStyle(fontSize:11,color:_txtS)),
                ])),
              ]));
            }).toList(),
            onChanged:(f)=>setState((){_selectedFund=f;_hasFetched=false;_allTxns=[];}),
          )),
        ),
    ]);
  }

  Widget _buildFilterChips() {
    return Row(children:[
      _chip(_Filter.both,        _s.all,         Icons.swap_vert_rounded,      const Color(0xFF1565C0)),
      const SizedBox(width:10),
      _chip(_Filter.deposits,    _s.deposits,    Icons.arrow_downward_rounded, const Color(0xFF2E7D32)),
      const SizedBox(width:10),
      _chip(_Filter.withdrawals, _s.withdrawals, Icons.arrow_upward_rounded,   const Color(0xFFC62828)),
    ]);
  }

  Widget _chip(_Filter filter, String label, IconData icon, Color activeColor) {
    final active = _filter == filter;
    final bg  = _dark ? TSLColors.darkCard   : Colors.white;
    final bd  = _dark ? TSLColors.darkBorder : Colors.grey.shade300;
    final txt = _dark ? TSLColors.darkTextSec: Colors.grey.shade600;
    return Expanded(child:GestureDetector(
      onTap:()=>setState(()=>_filter=filter),
      child:AnimatedContainer(
        duration:const Duration(milliseconds:200),
        padding:const EdgeInsets.symmetric(horizontal:10,vertical:9),
        decoration:BoxDecoration(
          color:active?activeColor:bg,
          borderRadius:BorderRadius.circular(24),
          border:Border.all(color:active?activeColor:bd,width:1.5),
          boxShadow:active?[BoxShadow(color:activeColor.withOpacity(0.3),blurRadius:10,offset:const Offset(0,4))]:[],
        ),
        child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[
          Icon(icon,size:13,color:active?Colors.white:txt),
          const SizedBox(width:5),
          Flexible(child:Text(label,overflow:TextOverflow.ellipsis,
              style:TextStyle(fontSize:12,fontWeight:active?FontWeight.w700:FontWeight.w500,
                  color:active?Colors.white:txt))),
        ]),
      ),
    ));
  }

  Widget _buildSummaryCards() {
    final txns = _filtered;
    final deps = txns.where((t)=>t.isDeposit).fold(0.0,(s,t)=>s+t.amount);
    final wds  = txns.where((t)=>!t.isDeposit).fold(0.0,(s,t)=>s+t.amount);
    return Row(children:[
      Expanded(child:_summaryCard(label:_s.deposits,value:'TZS ${_fmt(deps)}',
          icon:Icons.arrow_downward_rounded,color:const Color(0xFF2E7D32),
          bg:_dark?const Color(0xFF0A2010):const Color(0xFFE8F5E9),
          count:txns.where((t)=>t.isDeposit).length)),
      const SizedBox(width:12),
      Expanded(child:_summaryCard(label:_s.withdrawals,value:'TZS ${_fmt(wds)}',
          icon:Icons.arrow_upward_rounded,color:const Color(0xFFC62828),
          bg:_dark?const Color(0xFF2D0A0A):const Color(0xFFFFEBEE),
          count:txns.where((t)=>!t.isDeposit).length)),
    ]);
  }

  Widget _summaryCard({required String label,required String value,required IconData icon,
    required Color color,required Color bg,required int count}) {
    return Container(
      padding:const EdgeInsets.all(16),
      decoration:BoxDecoration(color:_card,borderRadius:BorderRadius.circular(18),
          border:Border.all(color:_border),
          boxShadow:[BoxShadow(color:color.withOpacity(_dark?0.15:0.1),blurRadius:16,offset:const Offset(0,6))]),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[
          Container(padding:const EdgeInsets.all(7),
              decoration:BoxDecoration(color:bg,borderRadius:BorderRadius.circular(10)),
              child:Icon(icon,color:color,size:16)),
          const Spacer(),
          Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:3),
              decoration:BoxDecoration(color:bg,borderRadius:BorderRadius.circular(20)),
              child:Text('$count ${_s.txns}',style:TextStyle(fontSize:10,fontWeight:FontWeight.w700,color:color))),
        ]),
        const SizedBox(height:12),
        Text(label,style:TextStyle(fontSize:11,color:_txtS,fontWeight:FontWeight.w500)),
        const SizedBox(height:4),
        Text(value,overflow:TextOverflow.ellipsis,
            style:TextStyle(fontSize:14,fontWeight:FontWeight.w900,color:color,letterSpacing:-0.3)),
      ]),
    );
  }

  Widget _buildTransactionList() {
    final txns = _filtered;
    if (txns.isEmpty) {
      return Center(child:Padding(padding:const EdgeInsets.symmetric(vertical:40),
          child:Column(children:[
            Icon(Icons.receipt_long_outlined,size:52,color:_dark?TSLColors.darkBorder:Colors.grey.shade300),
            const SizedBox(height:14),
            Text(_s.noTxns,style:TextStyle(fontSize:16,fontWeight:FontWeight.w600,color:_txtS)),
            const SizedBox(height:6),
            Text(_s.tryFilter,style:TextStyle(fontSize:13,color:_txtS)),
          ])));
    }
    return FadeTransition(opacity:_fadeAnim,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
        Text(_s.transactionCount(txns.length),style:TextStyle(fontSize:15,fontWeight:FontWeight.w800,color:_txtP)),
        Text(_selectedFund?.fundingName??'',style:TextStyle(fontSize:12,color:_txtS)),
      ]),
      const SizedBox(height:14),
      ListView.separated(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),
          itemCount:txns.length,separatorBuilder:(_,__)=>const SizedBox(height:10),
          itemBuilder:(_,i)=>_buildTxnCard(txns[i])),
    ]));
  }

  Widget _buildTxnCard(_Txn t) {
    final color   = t.isDeposit?const Color(0xFF2E7D32):const Color(0xFFC62828);
    final bgColor = t.isDeposit
        ?(_dark?const Color(0xFF0A2010):const Color(0xFFE8F5E9))
        :(_dark?const Color(0xFF2D0A0A):const Color(0xFFFFEBEE));
    final icon = t.isDeposit?Icons.arrow_downward_rounded:Icons.arrow_upward_rounded;
    return Container(
      padding:const EdgeInsets.all(16),
      decoration:BoxDecoration(color:_card,borderRadius:BorderRadius.circular(18),
          border:Border.all(color:_border),
          boxShadow:[BoxShadow(color:Colors.black.withOpacity(_dark?0.2:0.05),blurRadius:12,offset:const Offset(0,4))]),
      child:Row(children:[
        Container(width:46,height:46,decoration:BoxDecoration(color:bgColor,shape:BoxShape.circle),
            child:Icon(icon,color:color,size:20)),
        const SizedBox(width:14),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(t.description,overflow:TextOverflow.ellipsis,
              style:TextStyle(fontSize:13,fontWeight:FontWeight.w700,color:_txtP)),
          const SizedBox(height:4),
          Row(children:[
            Icon(Icons.access_time_rounded,size:11,color:_txtS),
            const SizedBox(width:4),
            Text(DateFormat('dd MMM yyyy \u2022 HH:mm').format(t.date),
                style:TextStyle(fontSize:11,color:_txtS)),
          ]),
          const SizedBox(height:4),
          Row(children:[
            _pill('ID: ${t.id}',_dark?TSLColors.darkCard2:Colors.grey.shade100,_txtS),
            const SizedBox(width:6),
            _pill('${_fmt(t.units)} ${_s.units}',bgColor,color),
          ]),
        ])),
        const SizedBox(width:12),
        Column(crossAxisAlignment:CrossAxisAlignment.end,children:[
          Text('${t.isDeposit?'+':'-'} TZS',style:TextStyle(fontSize:10,color:color.withOpacity(0.7),fontWeight:FontWeight.w600)),
          Text(_fmt(t.amount),style:TextStyle(fontSize:15,fontWeight:FontWeight.w900,color:color)),
          const SizedBox(height:4),
          Text('@${_fmt(t.price)}',style:TextStyle(fontSize:10,color:_txtS)),
        ]),
      ]),
    );
  }

  Widget _pill(String label,Color bg,Color fg)=>Container(
      padding:const EdgeInsets.symmetric(horizontal:7,vertical:2),
      decoration:BoxDecoration(color:bg,borderRadius:BorderRadius.circular(20)),
      child:Text(label,style:TextStyle(fontSize:10,color:fg,fontWeight:FontWeight.w600)));

  Widget _buildError() {
    return Center(child:Padding(padding:const EdgeInsets.symmetric(vertical:40),
        child:Column(children:[
          Container(padding:const EdgeInsets.all(16),
              decoration:BoxDecoration(color:_dark?const Color(0xFF2D0A0A):Colors.red.shade50,shape:BoxShape.circle),
              child:Icon(Icons.cloud_off_outlined,color:Colors.red.shade400,size:32)),
          const SizedBox(height:14),
          Text(_txnsError!,textAlign:TextAlign.center,style:TextStyle(color:Colors.red.shade400,fontSize:14)),
          const SizedBox(height:16),
          ElevatedButton(onPressed:_fetchTransactions,
              style:ElevatedButton.styleFrom(backgroundColor:_accent,foregroundColor:Colors.white,
                  shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12)),elevation:0),
              child:Text(_s.tryAgain)),
        ])));
  }
}

class _CS {
  final String clientStatement,statementSubtitle,downloadPDF,selectFund,
      failedFunds,all,deposits,withdrawals,loadTransactions,loading,
      noTxns,tryFilter,txns,units,totalDeposits,totalWithdrawals,
      netFlow,cdsNumber,fund,generated,description,date,amountTZS,
      pdfFooter,retry,tryAgain,connError,failedTxns;
  final String Function(int) transactionCount;
  const _CS({required this.clientStatement,required this.statementSubtitle,
    required this.downloadPDF,required this.selectFund,required this.failedFunds,
    required this.all,required this.deposits,required this.withdrawals,
    required this.loadTransactions,required this.loading,required this.noTxns,
    required this.tryFilter,required this.txns,required this.units,
    required this.totalDeposits,required this.totalWithdrawals,required this.netFlow,
    required this.cdsNumber,required this.fund,required this.generated,
    required this.description,required this.date,required this.amountTZS,
    required this.pdfFooter,required this.retry,required this.tryAgain,
    required this.connError,required this.failedTxns,required this.transactionCount});
}

const _en = _CS(
  clientStatement:'Client Statement', statementSubtitle:'View your deposits & withdrawals per fund',
  downloadPDF:'Download PDF',         selectFund:'Select Fund',
  failedFunds:'Failed to load funds', all:'All',
  deposits:'Deposits',                withdrawals:'Withdrawals',
  loadTransactions:'Load Transactions',loading:'Loading…',
  noTxns:'No transactions found',     tryFilter:'Try changing the filter above',
  txns:'txns',                        units:'units',
  totalDeposits:'Total Deposits',     totalWithdrawals:'Total Withdrawals',
  netFlow:'Net Flow',                 cdsNumber:'CDS Number',
  fund:'Fund',                        generated:'Generated',
  description:'Description',          date:'Date',
  amountTZS:'Amount (TZS)',
  pdfFooter:'This statement is generated electronically and is valid without a signature.',
  retry:'Retry',                      tryAgain:'Try Again',
  connError:'Connection error. Please try again.',
  failedTxns:'Failed to retrieve transactions',
  transactionCount:_enCount,
);
String _enCount(int n) => '$n Transaction${n==1?'':'s'}';

const _sw = _CS(
  clientStatement:'Taarifa ya Mteja',  statementSubtitle:'Angalia amana na malipo yako kwa kila fedha',
  downloadPDF:'Pakua PDF',              selectFund:'Chagua Fedha',
  failedFunds:'Imeshindwa kupakia fedha',all:'Yote',
  deposits:'Amana',                    withdrawals:'Malipo',
  loadTransactions:'Pakia Miamala',    loading:'Inapakia…',
  noTxns:'Hakuna miamala iliyopatikana',tryFilter:'Jaribu kubadilisha kichujio hapo juu',
  txns:'miamala',                      units:'vitengo',
  totalDeposits:'Jumla ya Amana',      totalWithdrawals:'Jumla ya Malipo',
  netFlow:'Mtiririko Halisi',           cdsNumber:'Nambari ya CDS',
  fund:'Fedha',                        generated:'Imetolewa',
  description:'Maelezo',               date:'Tarehe',
  amountTZS:'Kiasi (TZS)',
  pdfFooter:'Taarifa hii imetolewa kwa njia ya kielektroniki na ni halali bila sahihi.',
  retry:'Jaribu Tena',                 tryAgain:'Jaribu Tena',
  connError:'Hitilafu ya mtandao. Tafadhali jaribu tena.',
  failedTxns:'Imeshindwa kupata miamala',
  transactionCount:_swCount,
);
String _swCount(int n) => 'Miamala $n';