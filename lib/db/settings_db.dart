import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Stores key-value settings in a dedicated table
class SettingsDb {
  static const _table = 'settings';

  static const keyCgstR = 'cgst_r';
  static const keySgstR = 'sgst_r';
  static const keyIgstR = 'igst_r';
  static const keyCessR = 'cess_r';

  static Future<void> ensureTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_table (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    // Insert defaults if not present
    final defaults = {keyCgstR: '9.0', keySgstR: '9.0', keyIgstR: '0.0', keyCessR: '0.0'};
    for (final e in defaults.entries) {
      await db.execute(
        'INSERT OR IGNORE INTO $_table (key, value) VALUES (?, ?)',
        [e.key, e.value],
      );
    }
  }

  static Future<Map<String, double>> loadRates(Database db) async {
    final rows = await db.query(_table);
    final map = {for (final r in rows) r['key'] as String: double.tryParse(r['value'] as String) ?? 0.0};
    return {
      keyCgstR: map[keyCgstR] ?? 9.0,
      keySgstR: map[keySgstR] ?? 9.0,
      keyIgstR: map[keyIgstR] ?? 0.0,
      keyCessR: map[keyCessR] ?? 0.0,
    };
  }

  static Future<void> saveRate(Database db, String key, double value) async {
    await db.insert(_table, {'key': key, 'value': value.toString()},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
