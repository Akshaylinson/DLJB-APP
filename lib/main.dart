import 'package:flutter/material.dart';
import 'screens/invoice_list.dart';

void main() {
  runApp(const DLJBApp());
}

class DLJBApp extends StatelessWidget {
  const DLJBApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DLJB',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
      ),
      home: const InvoiceListScreen(),
    );
  }
}
