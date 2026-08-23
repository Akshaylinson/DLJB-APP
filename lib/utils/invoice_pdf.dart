import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/sales_hdr.dart';
import '../models/sales_ln.dart';
import '../utils/amount_words.dart';

class InvoicePdf {
  static Future<pw.Document> build(SalesHdr hdr, List<SalesLn> lines) async {
    final doc = pw.Document();
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (ctx) => _buildPage(ctx, hdr, lines),
    ));
    return doc;
  }

  static pw.Widget _buildPage(pw.Context ctx, SalesHdr hdr, List<SalesLn> lines) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _header(hdr),
        pw.SizedBox(height: 6),
        _invoiceInfoRow(hdr),
        pw.SizedBox(height: 4),
        _partyRow(hdr),
        pw.SizedBox(height: 4),
        _itemsTable(lines),
        pw.SizedBox(height: 4),
        _bottomSection(hdr, lines),
        pw.SizedBox(height: 4),
        _footer(hdr),
      ],
    );
  }

  // ── Company header ────────────────────────────────────────────────────────
  static pw.Widget _header(SalesHdr hdr) {
    final companyName = hdr.sName.isNotEmpty ? hdr.sName.toUpperCase() : 'D.L.J.B INDUSTRIES';
    final address     = hdr.sAdd.isNotEmpty  ? hdr.sAdd  : 'ALOOR - 680 683';
    final phone       = hdr.sPh.isNotEmpty   ? hdr.sPh   : '';
    final gstin       = hdr.sGst.isNotEmpty  ? hdr.sGst  : '';

    return pw.Column(children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
              pw.Text(companyName,
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center),
              if (address.isNotEmpty)
                pw.Text('$address${phone.isNotEmpty ? '  Phone : $phone' : ''}',
                    style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.center),
              if (gstin.isNotEmpty)
                pw.Text('GSTIN : $gstin',
                    style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.center),
              pw.SizedBox(height: 4),
              pw.Text('INVOICE',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center),
            ]),
          ),
          pw.SizedBox(width: 8),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            _copyBox('Original For Receipient'),
            pw.SizedBox(height: 2),
            _copyBox('Duplicate for Supplier/Transporter'),
            pw.SizedBox(height: 2),
            _copyBox('Triplicate for Supplier'),
          ]),
        ],
      ),
    ]);
  }

  static pw.Widget _copyBox(String label) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
        child: pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
      );

  // ── Invoice info row ──────────────────────────────────────────────────────
  static pw.Widget _invoiceInfoRow(SalesHdr hdr) {
    final invDt  = hdr.invDt  != null ? _fmtDate(hdr.invDt!)  : '';
    final dtSup  = hdr.dtSup  != null ? _fmtDate(hdr.dtSup!)  : '';
    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
      padding: const pw.EdgeInsets.all(4),
      child: pw.Column(children: [
        pw.Row(children: [
          _infoCell('Reverse Charge :', hdr.revCg == 1 ? 'Yes' : 'No', 100),
          _infoCell('Invoice No :', hdr.invNo, 100),
          pw.Spacer(),
          _infoCell('Transportation Mode :', hdr.traMd, 120),
          _infoCell('Vehicle Number :', hdr.vehNo, 120),
        ]),
        pw.SizedBox(height: 3),
        pw.Row(children: [
          _infoCell('Invoice Date :', invDt, 100),
          _infoCell('State :', hdr.state, 80),
          _infoCell('State Code :', hdr.staCd, 80),
          _infoCell('Date of Supply :', dtSup, 100),
          _infoCell('Place of Supply :', hdr.plSup, 120),
        ]),
      ]),
    );
  }

  static pw.Widget _infoCell(String label, String value, double w) =>
      pw.SizedBox(
        width: w,
        child: pw.RichText(
          text: pw.TextSpan(children: [
            pw.TextSpan(text: '$label ', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
            pw.TextSpan(text: value,     style: const pw.TextStyle(fontSize: 8)),
          ]),
        ),
      );

  // ── Receiver / Consignee ──────────────────────────────────────────────────
  static pw.Widget _partyRow(SalesHdr hdr) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: _partyBox('Details of Receiver (Billed to)',
            hdr.rName, hdr.rAdd, hdr.rPh, hdr.rGst, hdr.rStat, hdr.rSCd)),
        pw.SizedBox(width: 4),
        pw.Expanded(child: _partyBox('Details of Consignee (Shipped to)',
            hdr.sName, hdr.sAdd, hdr.sPh, hdr.sGst, hdr.sStat, hdr.ssCd)),
      ],
    );
  }

  static pw.Widget _partyBox(String title, String name, String addr,
      String phone, String gstin, String state, String stateCode) =>
      pw.Container(
        decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
        padding: const pw.EdgeInsets.all(5),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center),
          pw.Divider(height: 4, thickness: 0.5),
          _partyLine('Name', name),
          _partyLine('Address', addr),
          _partyLine('Phone', phone),
          _partyLine('GSTIN', gstin),
          pw.Row(children: [
            pw.Expanded(child: _partyLine('State', state)),
            pw.SizedBox(width: 8),
            pw.Expanded(child: _partyLine('State Code', stateCode)),
          ]),
        ]),
      );

  static pw.Widget _partyLine(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.SizedBox(
            width: 48,
            child: pw.Text(label, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Text(' : ', style: const pw.TextStyle(fontSize: 8)),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 8)),
          ),
        ]),
      );

  // ── Items table ───────────────────────────────────────────────────────────
  static pw.Widget _itemsTable(List<SalesLn> lines) {
    final headers = ['Sl\nNo', 'Name of Product / Service', 'HSN\nACS', 'UOM', 'Qty', 'Rate', 'Amount',
      'Less\nDisc.', 'Taxable\nValue', 'CGST\nRate%', 'CGST\nAmt', 'SGST\nRate%', 'SGST\nAmt',
      'IGST\nRate%', 'IGST\nAmt', 'CESS\nRate%', 'CESS\nAmt', 'Total'];

    final rows = lines.map((l) => [
      '${l.slNo}', l.prod, l.hsn, l.uom,
      l.qty.toStringAsFixed(0), _n(l.rate), _n(l.amt),
      _n(l.dis), _n(l.amt),
      _n(l.cgstR), _n(l.cgstA), _n(l.sgstR), _n(l.sgstA),
      _n(l.igstR), _n(l.igstA), _n(l.cessR), _n(l.cessA),
      _n(l.total),
    ]).toList();

    // totals row
    final totals = ['', 'Total', '', '', '', '', '', '', '',
      '', '', '', '', '', '', '', '',
      _n(lines.fold(0.0, (s, l) => s + l.total))];

    final colWidths = [18.0, 90.0, 28.0, 22.0, 18.0, 32.0, 36.0,
      28.0, 36.0, 28.0, 28.0, 28.0, 28.0, 28.0, 28.0, 28.0, 28.0, 36.0];

    pw.Widget headerCell(String t, double w) => pw.Container(
          width: w, height: 28,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            color: PdfColors.grey300,
            border: pw.Border.all(width: 0.3),
          ),
          child: pw.Text(t, style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center),
        );

    pw.Widget dataCell(String t, double w, {bool bold = false, bool right = false}) =>
        pw.Container(
          width: w, height: 18,
          alignment: right ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
          padding: const pw.EdgeInsets.symmetric(horizontal: 2),
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.3)),
          child: pw.Text(t, style: pw.TextStyle(fontSize: 7, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        );

    final numCols = {4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17};

    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      // header row
      pw.Row(children: [
        for (int i = 0; i < headers.length; i++)
          headerCell(headers[i], colWidths[i]),
      ]),
      // data rows (min 8 rows for blank lines)
      for (int r = 0; r < (rows.length < 8 ? 8 : rows.length); r++)
        pw.Row(children: [
          for (int c = 0; c < headers.length; c++)
            dataCell(r < rows.length ? rows[r][c] : '', colWidths[c],
                right: numCols.contains(c)),
        ]),
      // totals row
      pw.Row(children: [
        for (int c = 0; c < headers.length; c++)
          dataCell(totals[c], colWidths[c],
              bold: c == 1 || c == 17, right: c == 17),
      ]),
    ]);
  }

  // ── Bottom section ────────────────────────────────────────────────────────
  static pw.Widget _bottomSection(SalesHdr hdr, List<SalesLn> lines) {
    final grandTotal = lines.fold(0.0, (s, l) => s + l.total);
    final cgst  = lines.fold(0.0, (s, l) => s + l.cgstA);
    final sgst  = lines.fold(0.0, (s, l) => s + l.sgstA);
    final igst  = lines.fold(0.0, (s, l) => s + l.igstA);
    final cess  = lines.fold(0.0, (s, l) => s + l.cessA);
    final amtBt = lines.fold(0.0, (s, l) => s + l.amt);
    final taxGst = cgst + sgst + igst;

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // left: words + bank + terms
        pw.Expanded(
          flex: 3,
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Container(
              decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
              padding: const pw.EdgeInsets.all(5),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Total Invoice Amount in Words :',
                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 3),
                pw.Text(AmountWords.convert(grandTotal),
                    style: const pw.TextStyle(fontSize: 8)),
              ]),
            ),
            pw.SizedBox(height: 4),
            pw.Container(
              decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
              padding: const pw.EdgeInsets.all(5),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Bank Details :',
                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 3),
                pw.Text(hdr.bDet, style: const pw.TextStyle(fontSize: 8)),
              ]),
            ),
            pw.SizedBox(height: 4),
            pw.Container(
              decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
              padding: const pw.EdgeInsets.all(5),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Terms and Conditions :',
                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 3),
                pw.Text(hdr.termc, style: const pw.TextStyle(fontSize: 8)),
              ]),
            ),
          ]),
        ),
        pw.SizedBox(width: 4),
        // right: totals
        pw.Expanded(
          flex: 2,
          child: pw.Container(
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
            child: pw.Column(children: [
              _totLine('Total Amount Before Tax', _n(amtBt)),
              _totLine('Add : CGST', _n(cgst)),
              _totLine('Add : SGST', _n(sgst)),
              _totLine('Add : IGST', _n(igst)),
              _totLine('Add : CESS', _n(cess)),
              _totLine('Tax Amount : GST', _n(taxGst)),
              pw.Divider(height: 1, thickness: 0.8),
              _totLine('Total Amount After Tax', _n(grandTotal), bold: true),
              _totLine('GST Payable on Reverse charge', _n(hdr.gstRv)),
              pw.Divider(height: 1, thickness: 0.5),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(
                  'Certified that the particulars given above are true and correct',
                  style: const pw.TextStyle(fontSize: 7),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Text(
                'FOR ${hdr.sName.isNotEmpty ? hdr.sName.toUpperCase() : "D.L.J.B INDUSTRIES"}',
                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 20),
              pw.Text('Authorised Signatory',
                  style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center),
            ]),
          ),
        ),
      ],
    );
  }

  static pw.Widget _totLine(String label, String value, {bool bold = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label, style: pw.TextStyle(fontSize: 8, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
            pw.Text(value, style: pw.TextStyle(fontSize: 8, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          ],
        ),
      );

  // ── Footer ────────────────────────────────────────────────────────────────
  static pw.Widget _footer(SalesHdr hdr) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text('E & OE', style: const pw.TextStyle(fontSize: 7)),
        ],
      );

  static String _n(double v) => v.toStringAsFixed(2);
  static String _fmtDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
}
