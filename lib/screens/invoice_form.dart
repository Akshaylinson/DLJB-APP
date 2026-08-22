import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/app_database.dart';
import '../db/settings_db.dart';
import '../models/sales_hdr.dart';
import '../models/sales_ln.dart';
import '../widgets/line_item_row.dart';

class InvoiceForm extends StatefulWidget {
  final int? hdrId;
  const InvoiceForm({super.key, this.hdrId});

  @override
  State<InvoiceForm> createState() => _InvoiceFormState();
}

class _InvoiceFormState extends State<InvoiceForm> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = true;
  bool _saving = false;

  // Header controllers
  final _invNo = TextEditingController();
  DateTime? _invDt;
  DateTime? _dtSup;
  final _state = TextEditingController();
  final _staCd = TextEditingController();
  final _traMd = TextEditingController();
  final _vehNo = TextEditingController();
  final _plSup = TextEditingController();
  final _rName = TextEditingController();
  final _rAdd = TextEditingController();
  final _rGst = TextEditingController();
  final _rPh = TextEditingController();
  final _rStat = TextEditingController();
  final _rSCd = TextEditingController();
  final _sName = TextEditingController();
  final _sAdd = TextEditingController();
  final _sGst = TextEditingController();
  final _sPh = TextEditingController();
  final _sStat = TextEditingController();
  final _ssCd = TextEditingController();
  final _bDet = TextEditingController();
  final _termc = TextEditingController();
  bool _revCg = false;

  List<SalesLn> _lines = [];
  Map<String, double> _defaultRates = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _defaultRates = await AppDatabase.getDefaultRates();
    if (widget.hdrId != null) {
      final hdr = await AppDatabase.getHdr(widget.hdrId!);
      if (hdr != null) _populateHdr(hdr);
      _lines = await AppDatabase.getLinesForHdr(widget.hdrId!);
    } else {
      _lines = [_emptyLine(1)];
    }
    setState(() => _loading = false);
  }

  void _populateHdr(SalesHdr h) {
    _invNo.text = h.invNo;
    _invDt = h.invDt;
    _dtSup = h.dtSup;
    _state.text = h.state;
    _staCd.text = h.staCd;
    _traMd.text = h.traMd;
    _vehNo.text = h.vehNo;
    _plSup.text = h.plSup;
    _rName.text = h.rName;
    _rAdd.text = h.rAdd;
    _rGst.text = h.rGst;
    _rPh.text = h.rPh;
    _rStat.text = h.rStat;
    _rSCd.text = h.rSCd;
    _sName.text = h.sName;
    _sAdd.text = h.sAdd;
    _sGst.text = h.sGst;
    _sPh.text = h.sPh;
    _sStat.text = h.sStat;
    _ssCd.text = h.ssCd;
    _bDet.text = h.bDet;
    _termc.text = h.termc;
    _revCg = h.revCg == 1;
  }

  SalesLn _emptyLine(int slNo) => SalesLn(
        hdrId: 0,
        slNo: slNo,
        cgstR: _defaultRates[SettingsDb.keyCgstR] ?? 9.0,
        sgstR: _defaultRates[SettingsDb.keySgstR] ?? 9.0,
        igstR: _defaultRates[SettingsDb.keyIgstR] ?? 0.0,
        cessR: _defaultRates[SettingsDb.keyCessR] ?? 0.0,
      );

  void _recalcTotals() => setState(() {});

  double get _amtBt => _lines.fold(0, (s, l) => s + l.amt);
  double get _totalCgst => _lines.fold(0, (s, l) => s + l.cgstA);
  double get _totalSgst => _lines.fold(0, (s, l) => s + l.sgstA);
  double get _totalIgst => _lines.fold(0, (s, l) => s + l.igstA);
  double get _totalCess => _lines.fold(0, (s, l) => s + l.cessA);
  double get _grandTotal => _lines.fold(0, (s, l) => s + l.total);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final hdr = SalesHdr(
      id: widget.hdrId,
      invNo: _invNo.text.trim(),
      invDt: _invDt,
      revCg: _revCg ? 1 : 0,
      state: _state.text.trim(),
      staCd: _staCd.text.trim(),
      traMd: _traMd.text.trim(),
      vehNo: _vehNo.text.trim(),
      dtSup: _dtSup,
      plSup: _plSup.text.trim(),
      rName: _rName.text.trim(),
      rAdd: _rAdd.text.trim(),
      rGst: _rGst.text.trim(),
      rPh: _rPh.text.trim(),
      rStat: _rStat.text.trim(),
      rSCd: _rSCd.text.trim(),
      sName: _sName.text.trim(),
      sAdd: _sAdd.text.trim(),
      sGst: _sGst.text.trim(),
      sPh: _sPh.text.trim(),
      sStat: _sStat.text.trim(),
      ssCd: _ssCd.text.trim(),
      bDet: _bDet.text.trim(),
      termc: _termc.text.trim(),
      amtBt: _amtBt,
      cgst: _totalCgst,
      sgst: _totalSgst,
      igst: _totalIgst,
      txgst: _totalCgst + _totalSgst + _totalIgst,
      taxAt: _grandTotal,
      cess: _totalCess,
    );

    int hdrId;
    if (widget.hdrId == null) {
      hdrId = await AppDatabase.insertHdr(hdr);
    } else {
      await AppDatabase.updateHdr(hdr);
      hdrId = widget.hdrId!;
    }
    await AppDatabase.replaceLinesForHdr(hdrId, _lines);

    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickDate(bool isInvDt) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isInvDt ? _invDt : _dtSup) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => isInvDt ? _invDt = picked : _dtSup = picked);
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 20, 0, 8),
        child: Text(title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
      );

  Widget _field(String label, TextEditingController ctrl,
      {bool required = false, int maxLines = 1, TextInputType? keyboardType}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
        ),
      );

  Widget _datePicker(String label, DateTime? value, bool isInvDt) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () => _pickDate(isInvDt),
          child: InputDecorator(
            decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
            child: Text(value != null ? DateFormat('dd/MM/yyyy').format(value) : 'Select date',
                style: TextStyle(color: value != null ? Colors.black87 : Colors.grey)),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.hdrId == null ? 'New Invoice' : 'Edit Invoice'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          if (_saving)
            const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
          else
            TextButton(
              onPressed: _save,
              child: const Text('SAVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Invoice Info ---
                    _section('Invoice Details'),
                    Row(children: [
                      Expanded(child: _field('Invoice No', _invNo, required: true)),
                      const SizedBox(width: 12),
                      Expanded(child: _datePicker('Invoice Date', _invDt, true)),
                    ]),
                    Row(children: [
                      Expanded(child: _datePicker('Date of Supply', _dtSup, false)),
                      const SizedBox(width: 12),
                      Expanded(child: _field('Place of Supply', _plSup)),
                    ]),
                    Row(children: [
                      Expanded(child: _field('State', _state)),
                      const SizedBox(width: 12),
                      Expanded(child: _field('State Code', _staCd)),
                    ]),
                    Row(children: [
                      Expanded(child: _field('Transport Mode', _traMd)),
                      const SizedBox(width: 12),
                      Expanded(child: _field('Vehicle No', _vehNo)),
                    ]),
                    SwitchListTile(
                      title: const Text('Reverse Charge'),
                      value: _revCg,
                      onChanged: (v) => setState(() => _revCg = v),
                      contentPadding: EdgeInsets.zero,
                    ),

                    // --- Receiver ---
                    _section('Receiver (Bill To)'),
                    _field('Name', _rName, required: true),
                    _field('Address', _rAdd, maxLines: 3),
                    Row(children: [
                      Expanded(child: _field('GST No', _rGst)),
                      const SizedBox(width: 12),
                      Expanded(child: _field('Phone', _rPh, keyboardType: TextInputType.phone)),
                    ]),
                    Row(children: [
                      Expanded(child: _field('State', _rStat)),
                      const SizedBox(width: 12),
                      Expanded(child: _field('State Code', _rSCd)),
                    ]),

                    // --- Supplier ---
                    _section('Supplier (Bill From)'),
                    _field('Name', _sName, required: true),
                    _field('Address', _sAdd, maxLines: 3),
                    Row(children: [
                      Expanded(child: _field('GST No', _sGst)),
                      const SizedBox(width: 12),
                      Expanded(child: _field('Phone', _sPh, keyboardType: TextInputType.phone)),
                    ]),
                    Row(children: [
                      Expanded(child: _field('State', _sStat)),
                      const SizedBox(width: 12),
                      Expanded(child: _field('State Code', _ssCd)),
                    ]),

                    // --- Line Items ---
                    _section('Items'),
                    ..._lines.asMap().entries.map((e) => LineItemRow(
                          key: ValueKey(e.key),
                          line: e.value,
                          index: e.key,
                          onChanged: (updated) {
                            _lines[e.key] = updated;
                            _recalcTotals();
                          },
                          onRemove: _lines.length > 1
                              ? () => setState(() {
                                    _lines.removeAt(e.key);
                                    for (int i = 0; i < _lines.length; i++) {
                                      _lines[i] = _lines[i].copyWith(slNo: i + 1);
                                    }
                                  })
                              : null,
                        )),
                    TextButton.icon(
                      onPressed: () => setState(() => _lines.add(_emptyLine(_lines.length + 1))),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Item'),
                    ),

                    // --- Totals ---
                    _section('Totals'),
                    _totalRow('Amount Before Tax', _amtBt),
                    _totalRow('CGST', _totalCgst),
                    _totalRow('SGST', _totalSgst),
                    _totalRow('IGST', _totalIgst),
                    _totalRow('CESS', _totalCess),
                    const Divider(),
                    _totalRow('Grand Total', _grandTotal, bold: true),

                    // --- Bank & Terms ---
                    _section('Bank Details'),
                    _field('Bank Details', _bDet, maxLines: 3),
                    _section('Terms & Conditions'),
                    _field('Terms & Conditions', _termc, maxLines: 4),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _totalRow(String label, double value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
            Text('₹${value.toStringAsFixed(2)}',
                style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      );

  @override
  void dispose() {
    for (final c in [_invNo, _state, _staCd, _traMd, _vehNo, _plSup, _rName, _rAdd, _rGst, _rPh, _rStat, _rSCd, _sName, _sAdd, _sGst, _sPh, _sStat, _ssCd, _bDet, _termc]) {
      c.dispose();
    }
    super.dispose();
  }
}
