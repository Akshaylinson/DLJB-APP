import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../db/app_database.dart';
import '../db/settings_db.dart';
import '../models/sales_hdr.dart';
import '../models/sales_ln.dart';
import '../utils/amount_words.dart';

const _kBlue   = PdfColor.fromInt(0xFF1A3A6B);
const _kLight  = PdfColor.fromInt(0xFFF0F4FA);
const _kBorder = PdfColor.fromInt(0xFFBBBBBB);
const _kAlt    = PdfColor.fromInt(0xFFF7F9FC);
const _kOrange = PdfColor.fromInt(0xFFD4622A);

class InvoicePdf {
  static const _minBodyH = 110.0; // constant table body height

  static Future<pw.Document> build(SalesHdr hdr, List<SalesLn> lines) async {
    final strings = await AppDatabase.getDefaultStrings();
    final companyName = (strings[SettingsDb.keyCoName] ?? '').trim();
    final doc = pw.Document();
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      build: (_) => _page(hdr, lines, companyName),
    ));
    return doc;
  }

  // ── Page ──────────────────────────────────────────────────────────────────
  static pw.Widget _page(SalesHdr hdr, List<SalesLn> lines, String companyName) =>
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
        _header(hdr),
        pw.SizedBox(height: 5),
        _infoRow(hdr),
        pw.SizedBox(height: 4),
        _partyRow(hdr),
        pw.SizedBox(height: 4),
        _table(lines),
        pw.SizedBox(height: 4),
        _bottom(hdr, lines, companyName),
        pw.SizedBox(height: 6),
        _footer(),
        pw.SizedBox(height: 2),
        pw.Container(height: 0.7, color: _kBlue),
      ]);

  // ── 1. Header ─────────────────────────────────────────────────────────────
  static pw.Widget _header(SalesHdr hdr) {
    final company = hdr.sName.isNotEmpty ? hdr.sName.toUpperCase() : 'D.L.J.B INDUSTRIES';
    final address = hdr.sAdd.isNotEmpty  ? hdr.sAdd  : '';
    final phone   = hdr.sPh.isNotEmpty   ? 'Phone : ${hdr.sPh}' : '';
    final gstin   = hdr.sGst.isNotEmpty  ? 'GSTIN : ${hdr.sGst}' : '';

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Left spacer equal to copy boxes width so company stays centered
        pw.SizedBox(width: 196),
        // Centered company block
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(company,
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: _kBlue),
                  textAlign: pw.TextAlign.center),
              pw.Container(
                width: 120, height: 2,
                margin: const pw.EdgeInsets.symmetric(vertical: 3),
                color: _kOrange,
              ),
              // Address + Phone on ONE line, GSTIN below
              if (address.isNotEmpty || phone.isNotEmpty)
                pw.Text(
                  [if (address.isNotEmpty) address, if (phone.isNotEmpty) phone].join('     '),
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                  textAlign: pw.TextAlign.center,
                ),
              if (gstin.isNotEmpty)
                pw.Text(gstin,
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                    textAlign: pw.TextAlign.center),
              pw.SizedBox(height: 5),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: _kBlue,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                ),
                child: pw.Text('TAX INVOICE',
                    style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white)),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 8),
        // Copy boxes pinned right
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _copyBox('Original For Recipient'),
            pw.SizedBox(height: 3),
            _copyBox('Duplicate for Supplier/Transporter'),
            pw.SizedBox(height: 3),
            _copyBox('Triplicate for Supplier'),
          ],
        ),
      ],
    );
  }

  static pw.Widget _copyBox(String label) => pw.Container(
        width: 190, height: 22,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _kBorder, width: 0.8),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
        ),
        padding: const pw.EdgeInsets.symmetric(horizontal: 6),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
          pw.Container(
            width: 10, height: 10,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _kBlue, width: 1),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(1)),
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
        ]),
      );

  // ── 2. Invoice info row ───────────────────────────────────────────────────
  static pw.Widget _infoRow(SalesHdr hdr) {
    final invDt = hdr.invDt != null ? _fd(hdr.invDt!) : '';
    final dtSup = hdr.dtSup != null ? _fd(hdr.dtSup!) : '';
    final cells = [
      ('Invoice No',       hdr.invNo),
      ('Invoice Date',     invDt),
      ('Reverse Charge',   hdr.revCg == 1 ? 'Yes' : 'No'),
      ('State',            hdr.state),
      ('State Code',       hdr.staCd),
      ('Transport Mode',   hdr.traMd),
      ('Vehicle Number',   hdr.vehNo),
      ('Date of Supply',   dtSup),
      ('Place of Supply',  hdr.plSup),
    ];

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _kBorder, width: 0.6),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
        color: _kLight,
      ),
      child: pw.Row(children: [
        for (int i = 0; i < cells.length; i++) ...[
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text(cells[i].$1,
                    style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: _kBlue)),
                pw.SizedBox(height: 2),
                pw.Text(cells[i].$2, style: const pw.TextStyle(fontSize: 8.5)),
              ]),
            ),
          ),
          if (i < cells.length - 1)
            pw.Container(width: 0.5, height: 36, color: _kBorder),
        ],
      ]),
    );
  }

  // ── 3. Party row ──────────────────────────────────────────────────────────
  static pw.Widget _partyRow(SalesHdr hdr) => pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(child: _partyBox('Details of Receiver (Billed to)',
              hdr.rName, hdr.rAdd, hdr.rPh, hdr.rGst, hdr.rStat, hdr.rSCd)),
          pw.SizedBox(width: 5),
          pw.Expanded(child: _partyBox('Details of Consignee (Shipped to)',
              hdr.sName, hdr.sAdd, hdr.sPh, hdr.sGst, hdr.sStat, hdr.ssCd)),
        ],
      );

  static pw.Widget _partyBox(String title, String name, String addr,
      String phone, String gstin, String state, String stateCode) =>
      pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _kBorder, width: 0.6),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
        ),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: const pw.BoxDecoration(
              color: _kBlue,
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(3), topRight: pw.Radius.circular(3)),
            ),
            child: pw.Text(title,
                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              _pl('Name',       name),
              _pl('Address',    addr),
              pw.Row(children: [
                pw.Expanded(child: _pl('Phone', phone)),
                pw.SizedBox(width: 8),
                pw.Expanded(child: _pl('GSTIN', gstin)),
              ]),
              pw.Row(children: [
                pw.Expanded(child: _pl('State', state)),
                pw.SizedBox(width: 8),
                pw.Expanded(child: _pl('State Code', stateCode)),
              ]),
            ]),
          ),
        ]),
      );

  static pw.Widget _pl(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.SizedBox(
            width: 52,
            child: pw.Text(label,
                style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: _kBlue)),
          ),
          pw.Text(': ', style: const pw.TextStyle(fontSize: 7.5)),
          pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 7.5))),
        ]),
      );

  // ── 4. Items table ────────────────────────────────────────────────────────
  static pw.Widget _table(List<SalesLn> lines) {
    // columns: (header, width, isNumeric)
    // Total landscape content width = 297mm - 48mm margins = 249mm ≈ 706pt
    // Distribute all 706pt across 18 columns so nothing overflows
    final cols = [
      ('Sl\nNo',                    24.0,  false),
      ('Name of Product\n/ Service',118.0, false),
      ('HSN\nACS',                  32.0,  false),
      ('UOM',                       24.0,  false),
      ('Qty',                       26.0,  true),
      ('Rate',                      42.0,  true),
      ('Amount',                    46.0,  true),
      ('Less\nDisc.',               34.0,  true),
      ('Taxable\nValue',            46.0,  true),
      ('CGST\nRate%',               31.0,  true),
      ('CGST\nAmt',                 35.0,  true),
      ('SGST\nRate%',               31.0,  true),
      ('SGST\nAmt',                 35.0,  true),
      ('IGST\nRate%',               31.0,  true),
      ('IGST\nAmt',                 35.0,  true),
      ('CESS\nRate%',               31.0,  true),
      ('CESS\nAmt',                 35.0,  true),
      ('Total',                     50.0,  true),
    ];

    final totalTableW = cols.fold(0.0, (s, c) => s + c.$2);

    // Header
    final header = pw.Container(
      color: _kBlue,
      child: pw.Row(children: cols.map((c) => pw.Container(
            width: c.$2, height: 28,
            alignment: pw.Alignment.center,
            padding: const pw.EdgeInsets.symmetric(horizontal: 2),
            child: pw.Text(c.$1,
                style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white),
                textAlign: pw.TextAlign.center),
          )).toList()),
    );

    // Data rows — only real rows, no empty bordered rows
    final dataRows = <pw.Widget>[];
    for (int i = 0; i < lines.length; i++) {
      final l = lines[i];
      final vals = [
        '${l.slNo}', l.prod, l.hsn, l.uom,
        l.qty.toStringAsFixed(0), _n(l.rate), _n(l.amt),
        _n(l.dis), _n(l.amt),
        _n(l.cgstR), _n(l.cgstA),
        _n(l.sgstR), _n(l.sgstA),
        _n(l.igstR), _n(l.igstA),
        _n(l.cessR), _n(l.cessA),
        _n(l.total),
      ];
      dataRows.add(pw.Container(
        decoration: pw.BoxDecoration(
          color: i.isEven ? PdfColors.white : _kAlt,
          border: const pw.Border(
            bottom: pw.BorderSide(color: _kBorder, width: 0.4),
          ),
        ),
        child: pw.Row(children: [
          for (int c = 0; c < cols.length; c++)
            pw.Container(
              width: cols[c].$2, height: 16,
              alignment: cols[c].$3 ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
              padding: const pw.EdgeInsets.symmetric(horizontal: 3),
              child: pw.Text(vals[c], style: const pw.TextStyle(fontSize: 7.5)),
            ),
        ]),
      ));
    }

    // Blank spacer (constant height)
    final usedH = lines.length * 16.0;
    final spacerH = (_minBodyH - usedH).clamp(0.0, _minBodyH);

    // Totals row — full width
    final grandTotal = lines.fold(0.0, (s, l) => s + l.total);
    final totRow = pw.Container(
      width: totalTableW,
      decoration: const pw.BoxDecoration(
        color: _kLight,
        border: pw.Border(top: pw.BorderSide(color: _kBlue, width: 1)),
      ),
      child: pw.Row(children: [
        // "Total" label spanning first cols
        pw.Container(
          width: totalTableW - 40,
          height: 18,
          alignment: pw.Alignment.centerRight,
          padding: const pw.EdgeInsets.only(right: 6),
          child: pw.Text('Total',
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Container(
          width: 40, height: 18,
          alignment: pw.Alignment.centerRight,
          padding: const pw.EdgeInsets.only(right: 3),
          child: pw.Text(_n(grandTotal),
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ),
      ]),
    );

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _kBorder, width: 0.6),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
      ),
      child: pw.ClipRRect(
        horizontalRadius: 3, verticalRadius: 3,
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
          header,
          ...dataRows,
          if (spacerH > 0) pw.SizedBox(height: spacerH),
          totRow,
        ]),
      ),
    );
  }

  // ── 5. Bottom section ─────────────────────────────────────────────────────
  static pw.Widget _bottom(SalesHdr hdr, List<SalesLn> lines, String companyName) {
    final grandTotal = lines.fold(0.0, (s, l) => s + l.total);
    final cgst  = lines.fold(0.0, (s, l) => s + l.cgstA);
    final sgst  = lines.fold(0.0, (s, l) => s + l.sgstA);
    final igst  = lines.fold(0.0, (s, l) => s + l.igstA);
    final cess  = lines.fold(0.0, (s, l) => s + l.cessA);
    final amtBt = lines.fold(0.0, (s, l) => s + l.amt);
    final taxGst = cgst + sgst + igst;
    final company = companyName.isNotEmpty
        ? companyName.toUpperCase()
        : (hdr.sName.isNotEmpty ? hdr.sName.toUpperCase() : 'D.L.J.B INDUSTRIES');

    return pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      // Left column: words + bank + terms + common seal
      pw.Expanded(
        flex: 3,
        child: pw.Container(
          height: 168,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _kBorder, width: 0.6),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
          ),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            _bottomSection('Total Invoice Amount in Words :',
                AmountWords.convert(grandTotal)),
            pw.Container(height: 0.5, color: _kBorder),
            _bottomSection('Bank Details :', hdr.bDet),
            pw.Container(height: 0.5, color: _kBorder),
            _bottomSection('Terms and Conditions :', hdr.termc),
            pw.Container(height: 0.5, color: _kBorder),
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.fromLTRB(8, 4, 8, 8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text('(Common Seal)',
                        style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                    pw.SizedBox(height: 52),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
      pw.SizedBox(width: 5),
      pw.Expanded(
        flex: 2,
        child: pw.Container(
          height: 168,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _kBorder, width: 0.6),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
          ),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
            _sumRow('Total Amount Before Tax', _n(amtBt)),
            _sumRow('Add : CGST',              _n(cgst)),
            _sumRow('Add : SGST',              _n(sgst)),
            _sumRow('Add : IGST',              _n(igst)),
            _sumRow('Add : CESS',              _n(cess)),
            _sumRow('Tax Amount : GST',        _n(taxGst)),
            pw.Container(height: 1, color: _kBlue),
            _sumRow('Total Amount After Tax',  _n(grandTotal), bold: true, highlight: true),
            _sumRow('GST Payable on Reverse charge', _n(hdr.gstRv)),
            pw.Container(height: 0.5, color: _kBorder),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              child: pw.Text(
                'Certified that the particulars given above are true and correct',
                style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text('FOR $company',
                style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: _kBlue),
                textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 30),
            pw.Text('Authorised Signatory',
                style: const pw.TextStyle(fontSize: 7),
                textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 8),
          ]),
        ),
      ),
    ]);
  }

  static pw.Widget _bottomSection(String title, String content) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(title,
              style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: _kBlue)),
          pw.SizedBox(height: 2),
          pw.Text(content.isNotEmpty ? content : '',
              style: const pw.TextStyle(fontSize: 7.5)),
        ]),
      );

  static pw.Widget _sumRow(String label, String value,
      {bool bold = false, bool highlight = false}) =>
      pw.Container(
        color: highlight ? _kLight : PdfColors.white,
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 1.5),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label,
                style: pw.TextStyle(
                    fontSize: 7.5,
                    fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                    color: bold ? _kBlue : PdfColors.black)),
            pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 7.5,
                    fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          ],
        ),
      );

  // ── Footer ────────────────────────────────────────────────────────────────
  static pw.Widget _footer() => pw.Row(
        children: [
          pw.Expanded(
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('This is a computer generated invoice.',
                    style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey500)),
                pw.Text('E & OE',
                    style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey500)),
              ],
            ),
          ),
        ],
      );

  static String _n(double v) => v.toStringAsFixed(2);
  static String _fd(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
}
