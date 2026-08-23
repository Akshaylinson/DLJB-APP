import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../models/sales_hdr.dart';
import '../models/sales_ln.dart';
import '../utils/invoice_pdf.dart';

class InvoicePreviewScreen extends StatelessWidget {
  final SalesHdr hdr;
  final List<SalesLn> lines;

  const InvoicePreviewScreen({
    super.key,
    required this.hdr,
    required this.lines,
  });

  Future<Uint8List> _buildPdf(PdfPageFormat format) async {
    final doc = await InvoicePdf.build(hdr, lines);
    return doc.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEDED),
      appBar: AppBar(
        title: const Text('Invoice Preview'),
        backgroundColor: const Color(0xFF2B2B2B),
        foregroundColor: Colors.white,
      ),
      body: PdfPreview(
        build: _buildPdf,
        initialPageFormat: PdfPageFormat.a4.landscape,
        allowPrinting: false,
        allowSharing: false,
        canChangePageFormat: false,
        canChangeOrientation: false,
        useActions: false,
        maxPageWidth: 1200,
        pdfFileName: 'invoice_preview.pdf',
        previewPageMargin: const EdgeInsets.all(8),
      ),
    );
  }
}
