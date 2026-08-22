import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/sales_hdr.dart';
import '../models/sales_ln.dart';
import 'settings_db.dart';

class AppDatabase {
  static Database? _db;

  static Future<Database> get db async {
    _db ??= await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final path = join(await getDatabasesPath(), 'dljb.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) => SettingsDb.ensureTable(db),
    );
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await SettingsDb.ensureTable(db);
  }

  static Future<void> _onCreate(Database db, int version) async {
    await SettingsDb.ensureTable(db);
    await db.execute('''
      CREATE TABLE sales_hdr (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        inv_no TEXT, inv_dt TEXT, rev_cg REAL, state TEXT, sta_cd TEXT,
        tra_md TEXT, veh_no TEXT, dt_sup TEXT, pl_sup TEXT,
        r_name TEXT, r_add TEXT, r_gst TEXT, r_ph TEXT, r_stat TEXT, r_s_cd TEXT,
        s_name TEXT, s_add TEXT, s_gst TEXT, s_ph TEXT, s_stat TEXT, s_s_cd TEXT,
        w_amt TEXT, b_det TEXT, termc TEXT,
        amt_bt REAL, cgst REAL, sgst REAL, igst REAL, txgst REAL,
        tax_at REAL, gst_rv REAL, cess REAL, dt_updt TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE sales_ln (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hdr_id INTEGER, sl_no INTEGER, prod TEXT, hsn TEXT, uom TEXT,
        qty REAL, rate REAL, amt REAL, dis REAL, tax REAL,
        cgst_r REAL, cgst_a REAL, sgst_r REAL, sgst_a REAL,
        igst_r REAL, igst_a REAL, total REAL,
        cess_r REAL, cess_a REAL, dt_updt TEXT,
        FOREIGN KEY (hdr_id) REFERENCES sales_hdr(id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<Map<String, double>> getDefaultRates() async {
    return SettingsDb.loadRates(await db);
  }

  static Future<Map<String, String>> getDefaultStrings() async {
    return SettingsDb.loadStrings(await db);
  }

  static Future<void> saveRate(String key, double value) async {
    await SettingsDb.saveRate(await db, key, value);
  }

  static Future<void> saveSetting(String key, String value) async {
    await SettingsDb.saveValue(await db, key, value);
  }

  // --- Sales Header CRUD ---
  static Future<int> insertHdr(SalesHdr hdr) async {
    final d = await db;
    final map = hdr.toMap()..remove('id');
    map['dt_updt'] = DateTime.now().toIso8601String();
    return d.insert('sales_hdr', map);
  }

  static Future<void> updateHdr(SalesHdr hdr) async {
    final d = await db;
    final map = hdr.toMap();
    map['dt_updt'] = DateTime.now().toIso8601String();
    await d.update('sales_hdr', map, where: 'id = ?', whereArgs: [hdr.id]);
  }

  static Future<void> deleteHdr(int id) async {
    final d = await db;
    await d.delete('sales_hdr', where: 'id = ?', whereArgs: [id]);
    await d.delete('sales_ln', where: 'hdr_id = ?', whereArgs: [id]);
  }

  static Future<List<SalesHdr>> getAllHdr() async {
    final d = await db;
    final rows = await d.query('sales_hdr', orderBy: 'id DESC');
    return rows.map(SalesHdr.fromMap).toList();
  }

  static Future<List<int>> getAllHdrIds() async {
    final d = await db;
    final rows = await d.query('sales_hdr', columns: ['id'], orderBy: 'id DESC');
    return rows.map((r) => r['id'] as int).toList();
  }

  static Future<SalesHdr?> getHdr(int id) async {
    final d = await db;
    final rows = await d.query('sales_hdr', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : SalesHdr.fromMap(rows.first);
  }

  // --- Sales Line CRUD ---
  static Future<int> insertLn(SalesLn ln) async {
    final d = await db;
    final map = ln.toMap()..remove('id');
    map['dt_updt'] = DateTime.now().toIso8601String();
    return d.insert('sales_ln', map);
  }

  static Future<void> updateLn(SalesLn ln) async {
    final d = await db;
    final map = ln.toMap();
    map['dt_updt'] = DateTime.now().toIso8601String();
    await d.update('sales_ln', map, where: 'id = ?', whereArgs: [ln.id]);
  }

  static Future<void> deleteLn(int id) async {
    final d = await db;
    await d.delete('sales_ln', where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<SalesLn>> getLinesForHdr(int hdrId) async {
    final d = await db;
    final rows = await d.query('sales_ln',
        where: 'hdr_id = ?', whereArgs: [hdrId], orderBy: 'sl_no');
    return rows.map(SalesLn.fromMap).toList();
  }

  static Future<void> replaceLinesForHdr(int hdrId, List<SalesLn> lines) async {
    final d = await db;
    await d.delete('sales_ln', where: 'hdr_id = ?', whereArgs: [hdrId]);
    for (final ln in lines) {
      final map = ln.copyWith(hdrId: hdrId).toMap()..remove('id');
      map['dt_updt'] = DateTime.now().toIso8601String();
      await d.insert('sales_ln', map);
    }
  }
}
