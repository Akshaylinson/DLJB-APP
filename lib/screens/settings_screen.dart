import 'package:flutter/material.dart';
import '../db/app_database.dart';
import '../db/settings_db.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _cgstR = TextEditingController();
  final _sgstR = TextEditingController();
  final _igstR = TextEditingController();
  final _cessR = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rates = await AppDatabase.getDefaultRates();
    _cgstR.text = (rates[SettingsDb.keyCgstR] ?? 9.0).toString();
    _sgstR.text = (rates[SettingsDb.keySgstR] ?? 9.0).toString();
    _igstR.text = (rates[SettingsDb.keyIgstR] ?? 0.0).toString();
    _cessR.text = (rates[SettingsDb.keyCessR] ?? 0.0).toString();
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await AppDatabase.saveRate(SettingsDb.keyCgstR, double.tryParse(_cgstR.text) ?? 0);
    await AppDatabase.saveRate(SettingsDb.keySgstR, double.tryParse(_sgstR.text) ?? 0);
    await AppDatabase.saveRate(SettingsDb.keyIgstR, double.tryParse(_igstR.text) ?? 0);
    await AppDatabase.saveRate(SettingsDb.keyCessR, double.tryParse(_cessR.text) ?? 0);
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Default tax rates saved'), backgroundColor: Colors.green),
      );
    }
  }

  Widget _rateField(String label, TextEditingController ctrl, String hint) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextFormField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            suffixText: '%',
            border: const OutlineInputBorder(),
            helperText: 'Applied by default to all new line items',
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tax Rate Settings'),
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Default Tax Rates',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'These rates are pre-filled when you add a new line item. You can still override them per item on the invoice.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  _rateField('CGST Rate', _cgstR, 'e.g. 9'),
                  _rateField('SGST Rate', _sgstR, 'e.g. 9'),
                  _rateField('IGST Rate', _igstR, 'e.g. 0 (for intra-state, keep 0)'),
                  _rateField('CESS Rate', _cessR, 'e.g. 0'),
                  const Divider(height: 32),
                  const Text(
                    'How it works',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _infoRow('AMT', 'QTY × RATE'),
                  _infoRow('CGST Amount', 'AMT × CGST Rate / 100'),
                  _infoRow('SGST Amount', 'AMT × SGST Rate / 100'),
                  _infoRow('IGST Amount', 'AMT × IGST Rate / 100'),
                  _infoRow('CESS Amount', 'AMT × CESS Rate / 100'),
                  _infoRow('Line Total', 'AMT + CGST + SGST + IGST + CESS − Discount'),
                ],
              ),
            ),
    );
  }

  Widget _infoRow(String label, String formula) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            SizedBox(width: 120, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
            Text('= $formula', style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );

  @override
  void dispose() {
    for (final c in [_cgstR, _sgstR, _igstR, _cessR]) {
      c.dispose();
    }
    super.dispose();
  }
}
