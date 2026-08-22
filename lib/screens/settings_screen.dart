import 'package:flutter/material.dart';
import '../db/app_database.dart';
import '../db/settings_db.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _cgstR  = TextEditingController();
  final _sgstR  = TextEditingController();
  final _igstR  = TextEditingController();
  final _cessR  = TextEditingController();
  final _bankDet = TextEditingController();
  final _termc   = TextEditingController();
  bool _loading = true;
  bool _saving  = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rates   = await AppDatabase.getDefaultRates();
    final strings = await AppDatabase.getDefaultStrings();
    _cgstR.text   = (rates[SettingsDb.keyCgstR]  ?? 9.0).toString();
    _sgstR.text   = (rates[SettingsDb.keySgstR]  ?? 9.0).toString();
    _igstR.text   = (rates[SettingsDb.keyIgstR]  ?? 0.0).toString();
    _cessR.text   = (rates[SettingsDb.keyCessR]  ?? 0.0).toString();
    _bankDet.text = strings[SettingsDb.keyBankDet] ?? '';
    _termc.text   = strings[SettingsDb.keyTermsc]  ?? '';
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await AppDatabase.saveRate(SettingsDb.keyCgstR, double.tryParse(_cgstR.text) ?? 0);
    await AppDatabase.saveRate(SettingsDb.keySgstR, double.tryParse(_sgstR.text) ?? 0);
    await AppDatabase.saveRate(SettingsDb.keyIgstR, double.tryParse(_igstR.text) ?? 0);
    await AppDatabase.saveRate(SettingsDb.keyCessR, double.tryParse(_cessR.text) ?? 0);
    await AppDatabase.saveSetting(SettingsDb.keyBankDet, _bankDet.text.trim());
    await AppDatabase.saveSetting(SettingsDb.keyTermsc,  _termc.text.trim());
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF2B2B2B),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader('Default Tax Rates'),
                  const SizedBox(height: 4),
                  const Text(
                    'Pre-filled on every new line item. Can be overridden per item.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    _rateField('CGST %', _cgstR),
                    const SizedBox(width: 12),
                    _rateField('SGST %', _sgstR),
                    const SizedBox(width: 12),
                    _rateField('IGST %', _igstR),
                    const SizedBox(width: 12),
                    _rateField('CESS %', _cessR),
                  ]),
                  const SizedBox(height: 20),
                  _sectionHeader('Bank Details'),
                  const SizedBox(height: 4),
                  const Text(
                    'Auto-filled on every new invoice. Editable per invoice if needed.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  _textArea(_bankDet, 5),
                  const SizedBox(height: 20),
                  _sectionHeader('Terms & Conditions'),
                  const SizedBox(height: 4),
                  const Text(
                    'Auto-filled on every new invoice. Editable per invoice if needed.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  _textArea(_termc, 6),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _sectionHeader(String title) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: const BoxDecoration(
          color: Color(0xFF2B2B2B),
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
        child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      );

  Widget _rateField(String label, TextEditingController ctrl) => Expanded(
        child: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: label,
            suffixText: '%',
            filled: true,
            fillColor: Colors.white,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
      );

  Widget _textArea(TextEditingController ctrl, int lines) => TextField(
        controller: ctrl,
        maxLines: lines,
        decoration: const InputDecoration(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(),
          isDense: true,
        ),
      );

  @override
  void dispose() {
    for (final c in [_cgstR, _sgstR, _igstR, _cessR, _bankDet, _termc]) {
      c.dispose();
    }
    super.dispose();
  }
}
