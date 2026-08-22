import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/app_database.dart';
import '../models/sales_hdr.dart';
import 'invoice_form.dart';
import 'settings_screen.dart';

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
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
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
      appBar: AppBar(
        title: const Text('DLJB — Invoices'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Tax Rate Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _invoices.isEmpty
              ? const Center(child: Text('No invoices yet. Tap + to create one.'))
              : ListView.separated(
                  itemCount: _invoices.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final inv = _invoices[i];
                    final dt = inv.invDt != null
                        ? DateFormat('dd/MM/yyyy').format(inv.invDt!)
                        : '—';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        child: Text('${i + 1}'),
                      ),
                      title: Text(inv.invNo.isEmpty ? '(No Invoice No)' : inv.invNo,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${inv.rName}  •  $dt'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('₹${inv.taxAt.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _delete(inv),
                          ),
                        ],
                      ),
                      onTap: () async {
                        await Navigator.push(context,
                            MaterialPageRoute(builder: (_) => InvoiceForm(hdrId: inv.id)));
                        _load();
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const InvoiceForm()));
          _load();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
