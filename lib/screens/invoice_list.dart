import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/app_database.dart';
import '../models/sales_hdr.dart';
import 'invoice_form.dart';
import 'settings_screen.dart';

const _kDark   = Color(0xFF2B2B2B);
const _kOrange = Color(0xFFD4622A);

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});
  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  List<SalesHdr> _invoices = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _invoices = await AppDatabase.getAllHdr();
    setState(() => _loading = false);
  }

  Future<void> _delete(SalesHdr hdr) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: Text('Delete invoice ${hdr.invNo}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AppDatabase.deleteHdr(hdr.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      body: Column(
        children: [
          // title bar
          Container(
            color: _kDark,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Text(':: DLJB',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white, size: 20),
                  tooltip: 'Settings',
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  },
                ),
              ],
            ),
          ),
          // orange sub-bar
          Container(
            color: _kOrange,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: const Row(
              children: [
                Text('Invoices', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          // table header
          Container(
            color: const Color(0xFF3A3A3A),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: const Row(
              children: [
                SizedBox(width: 40, child: Text('#', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Invoice No', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text('Receiver', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Date', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Total (₹)', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                SizedBox(width: 48),
              ],
            ),
          ),
          // list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _invoices.isEmpty
                    ? const Center(child: Text('No invoices yet. Click New to create one.'))
                    : ListView.separated(
                        itemCount: _invoices.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final inv = _invoices[i];
                          final dt = inv.invDt != null
                              ? DateFormat('dd-MM-yyyy').format(inv.invDt!)
                              : '—';
                          return InkWell(
                            onTap: () async {
                              await Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => InvoiceForm(hdrId: inv.id)));
                              _load();
                            },
                            child: Container(
                              color: i.isEven ? const Color(0xFFF5F8FF) : Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  SizedBox(width: 40, child: Text('${i + 1}', style: const TextStyle(fontSize: 12))),
                                  Expanded(flex: 2, child: Text(inv.invNo.isEmpty ? '—' : inv.invNo,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                  Expanded(flex: 3, child: Text(inv.rName, style: const TextStyle(fontSize: 12))),
                                  Expanded(flex: 2, child: Text(dt, style: const TextStyle(fontSize: 12))),
                                  Expanded(
                                    flex: 2,
                                    child: Text('₹${inv.taxAt.toStringAsFixed(2)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        textAlign: TextAlign.right),
                                  ),
                                  SizedBox(
                                    width: 48,
                                    child: IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                      onPressed: () => _delete(inv),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          // bottom bar
          Container(
            color: _kDark,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text('${_invoices.length} record${_invoices.length == 1 ? '' : 's'}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoiceForm()));
                    _load();
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New Invoice'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
