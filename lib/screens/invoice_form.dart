import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../db/app_database.dart';
import '../db/settings_db.dart';
import '../models/sales_hdr.dart';
import '../models/sales_ln.dart';
import '../utils/amount_words.dart';
import '../utils/invoice_pdf.dart';
import '../widgets/line_item_row.dart';

// ── colour constants matching the FoxPro theme ──────────────────────────────
const _kDark   = Color(0xFF2B2B2B);
const _kOrange = Color(0xFFD4622A);
const _kHeaderBg = Color(0xFF3A3A3A);

class InvoiceForm extends StatefulWidget {
  final int? hdrId;
  const InvoiceForm({super.key, this.hdrId});
  @override
  State<InvoiceForm> createState() => _InvoiceFormState();
}

class _InvoiceFormState extends State<InvoiceForm> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = true;
  bool _saving  = false;

  // controllers
  final _invNo  = TextEditingController();
  final _revCgC = TextEditingController(text: '0.00');
  final _state  = TextEditingController();
  final _staCd  = TextEditingController();
  final _traMd  = TextEditingController();
  final _vehNo  = TextEditingController();
  final _plSup  = TextEditingController();
  final _rName  = TextEditingController();
  final _rAdd   = TextEditingController();
  final _rGst   = TextEditingController();
  final _rPh    = TextEditingController();
  final _rStat  = TextEditingController();
  final _rSCd   = TextEditingController();
  final _sName  = TextEditingController();
  final _sAdd   = TextEditingController();
  final _sGst   = TextEditingController();
  final _sPh    = TextEditingController();
  final _sStat  = TextEditingController();
  final _ssCd   = TextEditingController();
  final _bDet   = TextEditingController();
  final _termc  = TextEditingController();

  DateTime? _invDt;
  DateTime? _dtSup;

  List<SalesLn> _lines = [];
  Map<String, double> _defaultRates = {};

  // navigation state
  List<int> _allIds = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      _defaultRates = await AppDatabase.getDefaultRates();
      final strings = await AppDatabase.getDefaultStrings();
      _allIds = await AppDatabase.getAllHdrIds();

      if (widget.hdrId != null) {
        _currentIndex = _allIds.indexOf(widget.hdrId!);
        if (_currentIndex < 0) _currentIndex = 0;
        await _loadRecord(widget.hdrId!);
      } else {
        _bDet.text   = strings[SettingsDb.keyBankDet] ?? '';
        _termc.text  = strings[SettingsDb.keyTermsc]  ?? '';
        _sName.text  = strings[SettingsDb.keyCoName]  ?? '';
        _sAdd.text   = strings[SettingsDb.keyCoAdd]   ?? '';
        _sPh.text    = strings[SettingsDb.keyCoPhone] ?? '';
        _sGst.text   = strings[SettingsDb.keyCoGst]   ?? '';
        _sStat.text  = strings[SettingsDb.keyCoState] ?? '';
        _ssCd.text   = strings[SettingsDb.keyCoStCd]  ?? '';
        _lines = [_emptyLine(1)];
      }
    } catch (e) {
      debugPrint('_loadData error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadRecord(int id) async {
    final hdr = await AppDatabase.getHdr(id);
    if (hdr != null) _populateHdr(hdr);
    _lines = await AppDatabase.getLinesForHdr(id);
    if (_lines.isEmpty) _lines = [_emptyLine(1)];
  }

  void _populateHdr(SalesHdr h) {
    _invNo.text  = h.invNo;
    _revCgC.text = h.revCg.toStringAsFixed(2);
    _invDt  = h.invDt;
    _dtSup  = h.dtSup;
    _state.text  = h.state;
    _staCd.text  = h.staCd;
    _traMd.text  = h.traMd;
    _vehNo.text  = h.vehNo;
    _plSup.text  = h.plSup;
    _rName.text  = h.rName;
    _rAdd.text   = h.rAdd;
    _rGst.text   = h.rGst;
    _rPh.text    = h.rPh;
    _rStat.text  = h.rStat;
    _rSCd.text   = h.rSCd;
    _sName.text  = h.sName;
    _sAdd.text   = h.sAdd;
    _sGst.text   = h.sGst;
    _sPh.text    = h.sPh;
    _sStat.text  = h.sStat;
    _ssCd.text   = h.ssCd;
    _bDet.text   = h.bDet;
    _termc.text  = h.termc;
  }

  SalesLn _emptyLine(int slNo) => SalesLn(
        hdrId: 0, slNo: slNo,
        cgstR: _defaultRates[SettingsDb.keyCgstR] ?? 9.0,
        sgstR: _defaultRates[SettingsDb.keySgstR] ?? 9.0,
        igstR: _defaultRates[SettingsDb.keyIgstR] ?? 0.0,
        cessR: _defaultRates[SettingsDb.keyCessR] ?? 0.0,
      );

  double get _amtBt     => _lines.fold(0, (s, l) => s + l.amt);
  double get _totalCgst => _lines.fold(0, (s, l) => s + l.cgstA);
  double get _totalSgst => _lines.fold(0, (s, l) => s + l.sgstA);
  double get _totalIgst => _lines.fold(0, (s, l) => s + l.igstA);
  double get _totalCess => _lines.fold(0, (s, l) => s + l.cessA);
  double get _taxGst    => _totalCgst + _totalSgst + _totalIgst;
  double get _grandTotal => _lines.fold(0, (s, l) => s + l.total);
  double get _gstRv     => double.tryParse(_revCgC.text) ?? 0;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final hdr = SalesHdr(
      id: widget.hdrId,
      invNo: _invNo.text.trim(),
      invDt: _invDt,
      revCg: double.tryParse(_revCgC.text) ?? 0,
      state: _state.text.trim(),
      staCd: _staCd.text.trim(),
      traMd: _traMd.text.trim(),
      vehNo: _vehNo.text.trim(),
      dtSup: _dtSup,
      plSup: _plSup.text.trim(),
      rName: _rName.text.trim(),
      rAdd:  _rAdd.text.trim(),
      rGst:  _rGst.text.trim(),
      rPh:   _rPh.text.trim(),
      rStat: _rStat.text.trim(),
      rSCd:  _rSCd.text.trim(),
      sName: _sName.text.trim(),
      sAdd:  _sAdd.text.trim(),
      sGst:  _sGst.text.trim(),
      sPh:   _sPh.text.trim(),
      sStat: _sStat.text.trim(),
      ssCd:  _ssCd.text.trim(),
      wAmt:  AmountWords.convert(_grandTotal),
      bDet:  _bDet.text.trim(),
      termc: _termc.text.trim(),
      amtBt: _amtBt,
      cgst:  _totalCgst,
      sgst:  _totalSgst,
      igst:  _totalIgst,
      txgst: _taxGst,
      taxAt: _grandTotal,
      gstRv: _gstRv,
      cess:  _totalCess,
    );
    int hdrId;
    if (widget.hdrId == null) {
      hdrId = await AppDatabase.insertHdr(hdr);
      _allIds.insert(0, hdrId);
      _currentIndex = 0;
    } else {
      await AppDatabase.updateHdr(hdr);
      hdrId = widget.hdrId!;
    }
    await AppDatabase.replaceLinesForHdr(hdrId, _lines);
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice saved'), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
      );
    }
  }

  Future<void> _newRecord() async {
    final strings = await AppDatabase.getDefaultStrings();
    _clearForm();
    _bDet.text   = strings[SettingsDb.keyBankDet] ?? '';
    _termc.text  = strings[SettingsDb.keyTermsc]  ?? '';
    _sName.text  = strings[SettingsDb.keyCoName]  ?? '';
    _sAdd.text   = strings[SettingsDb.keyCoAdd]   ?? '';
    _sPh.text    = strings[SettingsDb.keyCoPhone] ?? '';
    _sGst.text   = strings[SettingsDb.keyCoGst]   ?? '';
    _sStat.text  = strings[SettingsDb.keyCoState] ?? '';
    _ssCd.text   = strings[SettingsDb.keyCoStCd]  ?? '';
    _lines = [_emptyLine(1)];
    setState(() {});
  }

  void _clearForm() {
    for (final c in _allControllers) { c.clear(); }
    _revCgC.text = '0.00';
    _invDt = null;
    _dtSup = null;
    _lines = [];
  }

  Future<void> _navigate(int newIndex) async {
    if (newIndex < 0 || newIndex >= _allIds.length) return;
    setState(() { _loading = true; _currentIndex = newIndex; });
    await _loadRecord(_allIds[newIndex]);
    setState(() => _loading = false);
  }

  Future<void> _printPreview() async {
    try {
      final hdr = _currentHdr();
      final doc = await InvoicePdf.build(hdr, _lines);
      final bytes = await doc.save();
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Preview error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _printDirect() async {
    try {
      final hdr = _currentHdr();
      final doc = await InvoicePdf.build(hdr, _lines);
      final bytes = await doc.save();
      if (!mounted) return;
      final printer = await Printing.pickPrinter(context: context);
      if (printer == null) return;
      await Printing.directPrintPdf(
        printer: printer,
        onLayout: (_) async => bytes,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  SalesHdr _currentHdr() => SalesHdr(
        id: widget.hdrId,
        invNo: _invNo.text.trim(),
        invDt: _invDt,
        revCg: double.tryParse(_revCgC.text) ?? 0,
        state: _state.text.trim(),
        staCd: _staCd.text.trim(),
        traMd: _traMd.text.trim(),
        vehNo: _vehNo.text.trim(),
        dtSup: _dtSup,
        plSup: _plSup.text.trim(),
        rName: _rName.text.trim(),
        rAdd:  _rAdd.text.trim(),
        rGst:  _rGst.text.trim(),
        rPh:   _rPh.text.trim(),
        rStat: _rStat.text.trim(),
        rSCd:  _rSCd.text.trim(),
        sName: _sName.text.trim(),
        sAdd:  _sAdd.text.trim(),
        sGst:  _sGst.text.trim(),
        sPh:   _sPh.text.trim(),
        sStat: _sStat.text.trim(),
        ssCd:  _ssCd.text.trim(),
        wAmt:  AmountWords.convert(_grandTotal),
        bDet:  _bDet.text.trim(),
        termc: _termc.text.trim(),
        amtBt: _amtBt, cgst: _totalCgst, sgst: _totalSgst,
        igst: _totalIgst, txgst: _taxGst, taxAt: _grandTotal,
        gstRv: _gstRv, cess: _totalCess,
      );

  Future<void> _pickDate(bool isInvDt) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isInvDt ? _invDt : _dtSup) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => isInvDt ? _invDt = picked : _dtSup = picked);
  }

  List<TextEditingController> get _allControllers => [
    _invNo, _revCgC, _state, _staCd, _traMd, _vehNo, _plSup,
    _rName, _rAdd, _rGst, _rPh, _rStat, _rSCd,
    _sName, _sAdd, _sGst, _sPh, _sStat, _ssCd,
    _bDet, _termc,
  ];

  // ── build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final recLabel = _allIds.isEmpty
        ? 'New Record'
        : '${_currentIndex + 1} of ${_allIds.length} records';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      body: Column(
        children: [
          _buildTitleBar(),
          _buildOrangeBar(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Form(
                    key: _formKey,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth - 20; // subtract padding(10) each side
                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(10),
                          child: SizedBox(
                            width: w,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTopFields(w),
                                const SizedBox(height: 8),
                                _buildReceiverConsigneeRow(w),
                                const SizedBox(height: 8),
                                _buildItemsTable(),
                                const SizedBox(height: 8),
                                _buildBottomSection(w),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
          _buildNavBar(recLabel),
        ],
      ),
    );
  }

  // ── title bar ────────────────────────────────────────────────────────────
  Widget _buildTitleBar() => Container(
        color: _kDark,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Text(':: DLJB', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Back',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );

  // ── orange sub-bar ───────────────────────────────────────────────────────
  Widget _buildOrangeBar() => Container(
        color: _kOrange,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            const Text('Invoice Form', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const Spacer(),
            if (_saving)
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
          ],
        ),
      );

  // ── top fields row ───────────────────────────────────────────────────────
  Widget _buildTopFields(double w) {
    // container has padding(8) on each side = 16px total, 4 gaps of 8px = 32px
    final inner = w - 16; // subtract container padding
    final c = (inner - 32) / 5; // 5 cols, 4 gaps
    return Container(
      width: w,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300)),
      child: Column(
        children: [
          Row(children: [
            _lf('Invoice No:', _invNo, c, required: true),
            const SizedBox(width: 8),
            _lf('Reverse Charge:', _revCgC, c, keyboardType: TextInputType.number),
            const SizedBox(width: 8),
            _lf('State:', _state, c),
            const SizedBox(width: 8),
            _lf('Transport Mode:', _traMd, c),
            const SizedBox(width: 8),
            _df('Date of Supply:', _dtSup, false, c),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            _df('Invoice Date:', _invDt, true, c),
            const SizedBox(width: 8),
            SizedBox(width: c),
            const SizedBox(width: 8),
            _lf('State Code:', _staCd, c),
            const SizedBox(width: 8),
            _lf('Vehicle Number:', _vehNo, c),
            const SizedBox(width: 8),
            _lf('Place of Supply:', _plSup, c),
          ]),
        ],
      ),
    );
  }

  // ── receiver / consignee ─────────────────────────────────────────────────
  Widget _buildReceiverConsigneeRow(double w) {
    final half = (w - 8) / 2;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPartyPanel('Details of Receiver  (Billed to)', _rName, _rAdd, _rGst, _rPh, _rStat, _rSCd, half),
        const SizedBox(width: 8),
        _buildPartyPanel('Details of Consignee  (Shipped to)', _sName, _sAdd, _sGst, _sPh, _sStat, _ssCd, half),
      ],
    );
  }

  Widget _buildPartyPanel(String title,
      TextEditingController name, TextEditingController add,
      TextEditingController gst, TextEditingController ph,
      TextEditingController stat, TextEditingController scd, double w) {
    // w includes 1px border each side; inner content = w - 2 (borders) - 16 (padding)
    final inner = w - 18;
    final third = (inner - 16) / 3; // 3 cols, 2 gaps of 8
    return SizedBox(
      width: w,
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: w,
              color: _kHeaderBg,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _lf('Name:', name, inner, required: true),
                const SizedBox(height: 6),
                _lf('Address:', add, inner, maxLines: 2),
                const SizedBox(height: 6),
                _lf('GSTIN:', gst, inner),
                const SizedBox(height: 6),
                Row(children: [
                  _lf('Phone:', ph, third, keyboardType: TextInputType.phone),
                  const SizedBox(width: 8),
                  _lf('State:', stat, third),
                  const SizedBox(width: 8),
                  _lf('State Code:', scd, third),
                ]),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  // ── items table ──────────────────────────────────────────────────────────
  Widget _buildItemsTable() => Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400)),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _tableHeader(),
              ..._lines.asMap().entries.map((e) => LineItemRow(
                    key: ValueKey('ln_${e.key}'),
                    line: e.value,
                    index: e.key,
                    onChanged: (updated) => setState(() => _lines[e.key] = updated),
                    onRemove: _lines.length > 1
                        ? () => setState(() {
                              _lines.removeAt(e.key);
                              for (int i = 0; i < _lines.length; i++) {
                                _lines[i] = _lines[i].copyWith(slNo: i + 1);
                              }
                            })
                        : null,
                  )),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: TextButton.icon(
                  onPressed: () => setState(() => _lines.add(_emptyLine(_lines.length + 1))),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Item'),
                  style: TextButton.styleFrom(foregroundColor: _kOrange),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _tableHeader() => Container(
        color: _kHeaderBg,
        child: Row(children: [
          _th('Sl No', 40),
          _th('Name of Product / Service', 180),
          _th('HSN ACS', 80),
          _th('UOM', 60),
          _th('QTY', 60),
          _th('Rate', 80),
          _th('Amount', 90),
          _th('Less Disc.', 80),
          _th('Taxable Value', 100),
          _th('CGST Rate', 80),
          _th('CGST Amt', 80),
          _th('SGST Rate', 80),
          _th('SGST Amt', 80),
          _th('IGST Rate', 80),
          _th('IGST Amt', 80),
          _th('CESS Rate', 80),
          _th('CESS Amt', 80),
          _th('Total', 90),
        ]),
      );

  Widget _th(String label, double w) => SizedBox(
        width: w,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
          child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      );

  // ── bottom section ───────────────────────────────────────────────────────
  Widget _buildBottomSection(double w) {
    final leftW  = (w - 8) * 0.58;
    final rightW = w - 8 - leftW;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLeftBottom(leftW),
        const SizedBox(width: 8),
        _buildTotalsPanel(rightW),
      ],
    );
  }

  Widget _buildLeftBottom(double w) => SizedBox(
        width: w,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Total Invoice Amount in Words:'),
            Container(
              width: w,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade400)),
              child: Text(AmountWords.convert(_grandTotal),
                  style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
            ),
            const SizedBox(height: 8),
            _sectionLabel('Bank Details:'),
            _textArea(_bDet, 5, w),
            const SizedBox(height: 8),
            _sectionLabel('Terms and Conditions:'),
            _textArea(_termc, 5, w),
          ],
        ),
      );

  Widget _buildTotalsPanel(double w) {
    final inner = w - 26; // padding 12 each side + 2px border
    return SizedBox(
      width: w,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDE7),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Column(
          children: [
            _totRow('Total Amount Before Tax:', _amtBt, inner),
            _totRow('Add: CGST:', _totalCgst, inner),
            _totRow('Add: SGST:', _totalSgst, inner),
            _totRow('Add: IGST:', _totalIgst, inner),
            _totRow('Add: CESS:', _totalCess, inner),
            _totRow('Tax Amount GST', _taxGst, inner),
            const Divider(thickness: 1.5),
            _totRow('Tax Amount After Tax:', _grandTotal, inner, bold: true, large: true),
            const Divider(),
            _totRow('GST Payable on Reverse charge:', _gstRv, inner),
          ],
        ),
      ),
    );
  }

  Widget _totRow(String label, double val, double w, {bool bold = false, bool large = false}) {
    final labelW = w * 0.62;
    final valW   = w * 0.38;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: labelW,
            child: Text(label, style: TextStyle(fontSize: large ? 13 : 12, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          ),
          SizedBox(
            width: valW,
            child: Text(val.toStringAsFixed(2), textAlign: TextAlign.right,
                style: TextStyle(fontSize: large ? 15 : 12, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          ),
        ],
      ),
    );
  }

  // ── nav bar ──────────────────────────────────────────────────────────────
  Widget _buildNavBar(String recLabel) => Container(
        color: _kDark,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            _navBtn(Icons.first_page,       'First',    () => _navigate(0)),
            _navBtn(Icons.chevron_left,     'Prev',     () => _navigate(_currentIndex - 1)),
            _navBtn(Icons.chevron_right,    'Next',     () => _navigate(_currentIndex + 1)),
            _navBtn(Icons.last_page,        'Last',     () => _navigate(_allIds.length - 1)),
            const SizedBox(width: 4),
            _navBtn(Icons.add_box_outlined, 'New',      _newRecord),
            _navBtn(Icons.save_outlined,    'Save',     _save),
            const SizedBox(width: 4),
            Container(width: 1, height: 36, color: Colors.white24),
            const SizedBox(width: 4),
            _navBtn(Icons.preview_outlined,  'Preview', _printPreview),
            _navBtn(Icons.print_outlined,    'Print',   _printDirect),
            const Spacer(),
            Text(recLabel, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(width: 8),
          ],
        ),
      );

  Widget _navBtn(IconData icon, String tooltip, VoidCallback onTap) => Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                Text(tooltip, style: const TextStyle(color: Colors.white70, fontSize: 9)),
              ],
            ),
          ),
        ),
      );

  // ── helpers ──────────────────────────────────────────────────────────────
  Widget _sectionLabel(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      );

  // fixed-width label+field — no Expanded anywhere
  Widget _lf(String label, TextEditingController ctrl, double w,
      {bool required = false, int maxLines = 1, TextInputType? keyboardType}) =>
      SizedBox(
        width: w,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF444444))),
            const SizedBox(height: 2),
            TextFormField(
              controller: ctrl,
              maxLines: maxLines,
              keyboardType: keyboardType,
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(), isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              ),
              validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
            ),
          ],
        ),
      );

  Widget _df(String label, DateTime? value, bool isInvDt, double w) => SizedBox(
        width: w,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF444444))),
            const SizedBox(height: 2),
            InkWell(
              onTap: () => _pickDate(isInvDt),
              child: Container(
                width: w,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  value != null ? DateFormat('dd-MM-yyyy').format(value) : '',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _textArea(TextEditingController ctrl, int lines, double w) => SizedBox(
        width: w,
        child: TextField(
          controller: ctrl,
          maxLines: lines,
          decoration: const InputDecoration(
            filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(), isDense: true,
            contentPadding: EdgeInsets.all(8),
          ),
        ),
      );

  @override
  void dispose() {
    for (final c in _allControllers) { c.dispose(); }
    super.dispose();
  }
}
