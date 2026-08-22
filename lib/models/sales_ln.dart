class SalesLn {
  final int? id;
  final int hdrId;
  final int slNo;
  final String prod;
  final String hsn;
  final String uom;
  final double qty;
  final double rate;
  final double amt;
  final double dis;
  final double tax;
  final double cgstR;
  final double cgstA;
  final double sgstR;
  final double sgstA;
  final double igstR;
  final double igstA;
  final double total;
  final double cessR;
  final double cessA;
  final DateTime? dtUpdt;

  SalesLn({
    this.id,
    required this.hdrId,
    this.slNo = 1,
    this.prod = '',
    this.hsn = '',
    this.uom = '',
    this.qty = 0,
    this.rate = 0,
    this.amt = 0,
    this.dis = 0,
    this.tax = 0,
    this.cgstR = 0,
    this.cgstA = 0,
    this.sgstR = 0,
    this.sgstA = 0,
    this.igstR = 0,
    this.igstA = 0,
    this.total = 0,
    this.cessR = 0,
    this.cessA = 0,
    this.dtUpdt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'hdr_id': hdrId,
        'sl_no': slNo,
        'prod': prod,
        'hsn': hsn,
        'uom': uom,
        'qty': qty,
        'rate': rate,
        'amt': amt,
        'dis': dis,
        'tax': tax,
        'cgst_r': cgstR,
        'cgst_a': cgstA,
        'sgst_r': sgstR,
        'sgst_a': sgstA,
        'igst_r': igstR,
        'igst_a': igstA,
        'total': total,
        'cess_r': cessR,
        'cess_a': cessA,
        'dt_updt': dtUpdt?.toIso8601String(),
      };

  factory SalesLn.fromMap(Map<String, dynamic> m) => SalesLn(
        id: m['id'],
        hdrId: m['hdr_id'] ?? 0,
        slNo: m['sl_no'] ?? 1,
        prod: m['prod'] ?? '',
        hsn: m['hsn'] ?? '',
        uom: m['uom'] ?? '',
        qty: (m['qty'] ?? 0).toDouble(),
        rate: (m['rate'] ?? 0).toDouble(),
        amt: (m['amt'] ?? 0).toDouble(),
        dis: (m['dis'] ?? 0).toDouble(),
        tax: (m['tax'] ?? 0).toDouble(),
        cgstR: (m['cgst_r'] ?? 0).toDouble(),
        cgstA: (m['cgst_a'] ?? 0).toDouble(),
        sgstR: (m['sgst_r'] ?? 0).toDouble(),
        sgstA: (m['sgst_a'] ?? 0).toDouble(),
        igstR: (m['igst_r'] ?? 0).toDouble(),
        igstA: (m['igst_a'] ?? 0).toDouble(),
        total: (m['total'] ?? 0).toDouble(),
        cessR: (m['cess_r'] ?? 0).toDouble(),
        cessA: (m['cess_a'] ?? 0).toDouble(),
        dtUpdt: m['dt_updt'] != null ? DateTime.tryParse(m['dt_updt']) : null,
      );

  SalesLn copyWith({
    int? id,
    int? hdrId,
    int? slNo,
    String? prod,
    String? hsn,
    String? uom,
    double? qty,
    double? rate,
    double? amt,
    double? dis,
    double? tax,
    double? cgstR,
    double? cgstA,
    double? sgstR,
    double? sgstA,
    double? igstR,
    double? igstA,
    double? total,
    double? cessR,
    double? cessA,
    DateTime? dtUpdt,
  }) =>
      SalesLn(
        id: id ?? this.id,
        hdrId: hdrId ?? this.hdrId,
        slNo: slNo ?? this.slNo,
        prod: prod ?? this.prod,
        hsn: hsn ?? this.hsn,
        uom: uom ?? this.uom,
        qty: qty ?? this.qty,
        rate: rate ?? this.rate,
        amt: amt ?? this.amt,
        dis: dis ?? this.dis,
        tax: tax ?? this.tax,
        cgstR: cgstR ?? this.cgstR,
        cgstA: cgstA ?? this.cgstA,
        sgstR: sgstR ?? this.sgstR,
        sgstA: sgstA ?? this.sgstA,
        igstR: igstR ?? this.igstR,
        igstA: igstA ?? this.igstA,
        total: total ?? this.total,
        cessR: cessR ?? this.cessR,
        cessA: cessA ?? this.cessA,
        dtUpdt: dtUpdt ?? this.dtUpdt,
      );
}
