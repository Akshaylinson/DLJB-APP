import 'package:flutter/material.dart';
import '../models/sales_ln.dart';

class LineItemRow extends StatefulWidget {
  final SalesLn line;
  final int index;
  final ValueChanged<SalesLn> onChanged;
  final VoidCallback? onRemove;

  const LineItemRow({
    super.key,
    required this.line,
    required this.index,
    required this.onChanged,
    this.onRemove,
  });

  @override
  State<LineItemRow> createState() => _LineItemRowState();
}

class _LineItemRowState extends State<LineItemRow> {
  late final TextEditingController _prod, _hsn, _uom, _qty, _rate, _dis, _cgstR, _sgstR, _igstR, _cessR;

  @override
  void initState() {
    super.initState();
    final l = widget.line;
    _prod  = TextEditingController(text: l.prod);
    _hsn   = TextEditingController(text: l.hsn);
    _uom   = TextEditingController(text: l.uom);
    _qty   = TextEditingController(text: l.qty   == 0 ? '' : l.qty.toStringAsFixed(0));
    _rate  = TextEditingController(text: l.rate  == 0 ? '' : l.rate.toStringAsFixed(2));
    _dis   = TextEditingController(text: l.dis   == 0 ? '' : l.dis.toStringAsFixed(2));
    _cgstR = TextEditingController(text: l.cgstR.toStringAsFixed(2));
    _sgstR = TextEditingController(text: l.sgstR.toStringAsFixed(2));
    _igstR = TextEditingController(text: l.igstR.toStringAsFixed(2));
    _cessR = TextEditingController(text: l.cessR.toStringAsFixed(2));

    for (final c in [_qty, _rate, _dis, _cgstR, _sgstR, _igstR, _cessR]) {
      c.addListener(_recalc);
    }
    _prod.addListener(_notifyText);
    _hsn.addListener(_notifyText);
    _uom.addListener(_notifyText);
  }

  void _notifyText() => widget.onChanged(_buildLine());

  void _recalc() {
    final ln    = _buildLine();
    final amt   = ln.qty * ln.rate;
    final cgstA = amt * ln.cgstR / 100;
    final sgstA = amt * ln.sgstR / 100;
    final igstA = amt * ln.igstR / 100;
    final cessA = amt * ln.cessR / 100;
    final total = amt + cgstA + sgstA + igstA + cessA - ln.dis;
    widget.onChanged(ln.copyWith(
      amt: amt, cgstA: cgstA, sgstA: sgstA,
      igstA: igstA, cessA: cessA, total: total,
    ));
  }

  SalesLn _buildLine() => widget.line.copyWith(
        prod:  _prod.text,
        hsn:   _hsn.text,
        uom:   _uom.text,
        qty:   double.tryParse(_qty.text)   ?? 0,
        rate:  double.tryParse(_rate.text)  ?? 0,
        dis:   double.tryParse(_dis.text)   ?? 0,
        cgstR: double.tryParse(_cgstR.text) ?? 0,
        sgstR: double.tryParse(_sgstR.text) ?? 0,
        igstR: double.tryParse(_igstR.text) ?? 0,
        cessR: double.tryParse(_cessR.text) ?? 0,
      );

  // fixed-width cell — no Expanded, pure fixed SizedBox
  Widget _cell(TextEditingController ctrl, double w, {TextInputType? type}) => SizedBox(
        width: w,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
          child: TextField(
            controller: ctrl,
            keyboardType: type,
            style: const TextStyle(fontSize: 11),
            decoration: const InputDecoration(
              filled: true,
              fillColor: Color(0xFFFAFAFA),
              border: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFCCCCCC))),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 5),
            ),
          ),
        ),
      );

  Widget _readCell(String val, double w, {bool bold = false}) => SizedBox(
        width: w,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(val,
              style: TextStyle(fontSize: 11, fontWeight: bold ? FontWeight.bold : FontWeight.normal),
              textAlign: TextAlign.right),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l   = widget.line;
    final num = const TextInputType.numberWithOptions(decimal: true);

    return Container(
      decoration: BoxDecoration(
        color: widget.index.isEven ? const Color(0xFFF5F8FF) : Colors.white,
        border: const Border(bottom: BorderSide(color: Color(0xFFDDDDDD))),
      ),
      child: Row(
        children: [
          // Sl No
          SizedBox(
            width: 40,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text('${widget.index + 1}', style: const TextStyle(fontSize: 11), textAlign: TextAlign.center),
            ),
          ),
          _cell(_prod, 180),
          _cell(_hsn,  80),
          _cell(_uom,  60),
          _cell(_qty,  60, type: num),
          _cell(_rate, 80, type: num),
          _readCell(l.amt.toStringAsFixed(2),   90),
          _cell(_dis,  80, type: num),
          _readCell(l.amt.toStringAsFixed(2),  100),   // taxable = amt
          _cell(_cgstR, 80, type: num),
          _readCell(l.cgstA.toStringAsFixed(2), 80),
          _cell(_sgstR, 80, type: num),
          _readCell(l.sgstA.toStringAsFixed(2), 80),
          _cell(_igstR, 80, type: num),
          _readCell(l.igstA.toStringAsFixed(2), 80),
          _cell(_cessR, 80, type: num),
          _readCell(l.cessA.toStringAsFixed(2), 80),
          _readCell(l.total.toStringAsFixed(2), 90, bold: true),
          if (widget.onRemove != null)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 16),
              onPressed: widget.onRemove,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (final c in [_prod, _hsn, _uom, _qty, _rate, _dis, _cgstR, _sgstR, _igstR, _cessR]) {
      c.dispose();
    }
    super.dispose();
  }
}
