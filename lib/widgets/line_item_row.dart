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
    _qty   = TextEditingController(text: l.qty   == 0 ? '' : l.qty.toString());
    _rate  = TextEditingController(text: l.rate  == 0 ? '' : l.rate.toString());
    _dis   = TextEditingController(text: l.dis   == 0 ? '' : l.dis.toString());
    _cgstR = TextEditingController(text: l.cgstR.toString());
    _sgstR = TextEditingController(text: l.sgstR.toString());
    _igstR = TextEditingController(text: l.igstR.toString());
    _cessR = TextEditingController(text: l.cessR.toString());

    for (final c in [_qty, _rate, _dis, _cgstR, _sgstR, _igstR, _cessR]) {
      c.addListener(_recalc);
    }
    _prod.addListener(_notifyText);
    _hsn.addListener(_notifyText);
    _uom.addListener(_notifyText);
  }

  void _notifyText() => _notify(_buildLine());

  void _recalc() {
    final ln = _buildLine();
    final amt    = ln.qty * ln.rate;
    final cgstA  = amt * ln.cgstR / 100;
    final sgstA  = amt * ln.sgstR / 100;
    final igstA  = amt * ln.igstR / 100;
    final cessA  = amt * ln.cessR / 100;
    final total  = amt + cgstA + sgstA + igstA + cessA - ln.dis;
    _notify(ln.copyWith(
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

  void _notify(SalesLn ln) => widget.onChanged(ln);

  Widget _f(String label, TextEditingController ctrl, {TextInputType? type, int flex = 1}) =>
      Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 10),
          child: TextField(
            controller: ctrl,
            keyboardType: type,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
      );

  Widget _rateAmtPair(String rateLabel, TextEditingController rateCtrl, double amount) =>
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: rateCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: rateLabel,
                  suffixText: '%',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  '₹${amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l = widget.line;
    final num = const TextInputType.numberWithOptions(decimal: true);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(children: [
              Text('Item ${widget.index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
              const Spacer(),
              if (widget.onRemove != null)
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: widget.onRemove,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ]),
            const SizedBox(height: 8),

            // Product & HSN
            Row(children: [_f('Product / Description', _prod, flex: 2), _f('HSN Code', _hsn)]),

            // UOM, Qty, Rate
            Row(children: [_f('UOM', _uom), _f('Qty', _qty, type: num), _f('Rate (₹)', _rate, type: num)]),

            // Discount
            Row(children: [_f('Discount (₹)', _dis, type: num), const Expanded(child: SizedBox()), const Expanded(child: SizedBox())]),

            // Tax rates with auto-calculated amounts shown below each
            const Text('Tax Rates  (editable per item)',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            Row(children: [
              _rateAmtPair('CGST %', _cgstR, l.cgstA),
              _rateAmtPair('SGST %', _sgstR, l.sgstA),
              _rateAmtPair('IGST %', _igstR, l.igstA),
              _rateAmtPair('CESS %', _cessR, l.cessA),
            ]),

            // Line total summary
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Taxable: ₹${l.amt.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
                Text('Line Total: ₹${l.total.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ],
        ),
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
