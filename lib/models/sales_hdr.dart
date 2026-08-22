class SalesHdr {
  final int? id;
  final String invNo;
  final DateTime? invDt;
  final double revCg;
  final String state;
  final String staCd;
  final String traMd;
  final String vehNo;
  final DateTime? dtSup;
  final String plSup;
  final String rName;
  final String rAdd;
  final String rGst;
  final String rPh;
  final String rStat;
  final String rSCd;
  final String sName;
  final String sAdd;
  final String sGst;
  final String sPh;
  final String sStat;
  final String ssCd;
  final String wAmt;
  final String bDet;
  final String termc;
  final double amtBt;
  final double cgst;
  final double sgst;
  final double igst;
  final double txgst;
  final double taxAt;
  final double gstRv;
  final double cess;
  final DateTime? dtUpdt;

  SalesHdr({
    this.id,
    this.invNo = '',
    this.invDt,
    this.revCg = 0,
    this.state = '',
    this.staCd = '',
    this.traMd = '',
    this.vehNo = '',
    this.dtSup,
    this.plSup = '',
    this.rName = '',
    this.rAdd = '',
    this.rGst = '',
    this.rPh = '',
    this.rStat = '',
    this.rSCd = '',
    this.sName = '',
    this.sAdd = '',
    this.sGst = '',
    this.sPh = '',
    this.sStat = '',
    this.ssCd = '',
    this.wAmt = '',
    this.bDet = '',
    this.termc = '',
    this.amtBt = 0,
    this.cgst = 0,
    this.sgst = 0,
    this.igst = 0,
    this.txgst = 0,
    this.taxAt = 0,
    this.gstRv = 0,
    this.cess = 0,
    this.dtUpdt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'inv_no': invNo,
        'inv_dt': invDt?.toIso8601String(),
        'rev_cg': revCg,
        'state': state,
        'sta_cd': staCd,
        'tra_md': traMd,
        'veh_no': vehNo,
        'dt_sup': dtSup?.toIso8601String(),
        'pl_sup': plSup,
        'r_name': rName,
        'r_add': rAdd,
        'r_gst': rGst,
        'r_ph': rPh,
        'r_stat': rStat,
        'r_s_cd': rSCd,
        's_name': sName,
        's_add': sAdd,
        's_gst': sGst,
        's_ph': sPh,
        's_stat': sStat,
        's_s_cd': ssCd,
        'w_amt': wAmt,
        'b_det': bDet,
        'termc': termc,
        'amt_bt': amtBt,
        'cgst': cgst,
        'sgst': sgst,
        'igst': igst,
        'txgst': txgst,
        'tax_at': taxAt,
        'gst_rv': gstRv,
        'cess': cess,
        'dt_updt': dtUpdt?.toIso8601String(),
      };

  factory SalesHdr.fromMap(Map<String, dynamic> m) => SalesHdr(
        id: m['id'],
        invNo: m['inv_no'] ?? '',
        invDt: m['inv_dt'] != null ? DateTime.tryParse(m['inv_dt']) : null,
        revCg: (m['rev_cg'] ?? 0).toDouble(),
        state: m['state'] ?? '',
        staCd: m['sta_cd'] ?? '',
        traMd: m['tra_md'] ?? '',
        vehNo: m['veh_no'] ?? '',
        dtSup: m['dt_sup'] != null ? DateTime.tryParse(m['dt_sup']) : null,
        plSup: m['pl_sup'] ?? '',
        rName: m['r_name'] ?? '',
        rAdd: m['r_add'] ?? '',
        rGst: m['r_gst'] ?? '',
        rPh: m['r_ph'] ?? '',
        rStat: m['r_stat'] ?? '',
        rSCd: m['r_s_cd'] ?? '',
        sName: m['s_name'] ?? '',
        sAdd: m['s_add'] ?? '',
        sGst: m['s_gst'] ?? '',
        sPh: m['s_ph'] ?? '',
        sStat: m['s_stat'] ?? '',
        ssCd: m['s_s_cd'] ?? '',
        wAmt: m['w_amt'] ?? '',
        bDet: m['b_det'] ?? '',
        termc: m['termc'] ?? '',
        amtBt: (m['amt_bt'] ?? 0).toDouble(),
        cgst: (m['cgst'] ?? 0).toDouble(),
        sgst: (m['sgst'] ?? 0).toDouble(),
        igst: (m['igst'] ?? 0).toDouble(),
        txgst: (m['txgst'] ?? 0).toDouble(),
        taxAt: (m['tax_at'] ?? 0).toDouble(),
        gstRv: (m['gst_rv'] ?? 0).toDouble(),
        cess: (m['cess'] ?? 0).toDouble(),
        dtUpdt: m['dt_updt'] != null ? DateTime.tryParse(m['dt_updt']) : null,
      );

  SalesHdr copyWith({
    int? id,
    String? invNo,
    DateTime? invDt,
    double? revCg,
    String? state,
    String? staCd,
    String? traMd,
    String? vehNo,
    DateTime? dtSup,
    String? plSup,
    String? rName,
    String? rAdd,
    String? rGst,
    String? rPh,
    String? rStat,
    String? rSCd,
    String? sName,
    String? sAdd,
    String? sGst,
    String? sPh,
    String? sStat,
    String? ssCd,
    String? wAmt,
    String? bDet,
    String? termc,
    double? amtBt,
    double? cgst,
    double? sgst,
    double? igst,
    double? txgst,
    double? taxAt,
    double? gstRv,
    double? cess,
    DateTime? dtUpdt,
  }) =>
      SalesHdr(
        id: id ?? this.id,
        invNo: invNo ?? this.invNo,
        invDt: invDt ?? this.invDt,
        revCg: revCg ?? this.revCg,
        state: state ?? this.state,
        staCd: staCd ?? this.staCd,
        traMd: traMd ?? this.traMd,
        vehNo: vehNo ?? this.vehNo,
        dtSup: dtSup ?? this.dtSup,
        plSup: plSup ?? this.plSup,
        rName: rName ?? this.rName,
        rAdd: rAdd ?? this.rAdd,
        rGst: rGst ?? this.rGst,
        rPh: rPh ?? this.rPh,
        rStat: rStat ?? this.rStat,
        rSCd: rSCd ?? this.rSCd,
        sName: sName ?? this.sName,
        sAdd: sAdd ?? this.sAdd,
        sGst: sGst ?? this.sGst,
        sPh: sPh ?? this.sPh,
        sStat: sStat ?? this.sStat,
        ssCd: ssCd ?? this.ssCd,
        wAmt: wAmt ?? this.wAmt,
        bDet: bDet ?? this.bDet,
        termc: termc ?? this.termc,
        amtBt: amtBt ?? this.amtBt,
        cgst: cgst ?? this.cgst,
        sgst: sgst ?? this.sgst,
        igst: igst ?? this.igst,
        txgst: txgst ?? this.txgst,
        taxAt: taxAt ?? this.taxAt,
        gstRv: gstRv ?? this.gstRv,
        cess: cess ?? this.cess,
        dtUpdt: dtUpdt ?? this.dtUpdt,
      );
}
