import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/penabung.dart';
import '../models/transaksi.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'tabungan.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE penabung (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nama TEXT NOT NULL,
            catatan TEXT,
            dibuat_pada TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE transaksi (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            penabung_id INTEGER NOT NULL,
            jenis TEXT NOT NULL,
            nominal INTEGER NOT NULL,
            catatan TEXT,
            tanggal TEXT NOT NULL,
            FOREIGN KEY (penabung_id) REFERENCES penabung(id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  // ─── PENABUNG ─────────────────────────────────────────────────

  Future<int> insertPenabung(Penabung p) async {
    final db = await database;
    return await db.insert('penabung', p.toMap());
  }

  Future<List<Penabung>> getAllPenabung() async {
    final db = await database;
    final maps = await db.query('penabung', orderBy: 'nama ASC');
    return maps.map(Penabung.fromMap).toList();
  }

  Future<Penabung?> getPenabungById(int id) async {
    final db = await database;
    final maps =
        await db.query('penabung', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return Penabung.fromMap(maps.first);
  }

  Future<int> updatePenabung(Penabung p) async {
    final db = await database;
    return await db
        .update('penabung', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
  }

  Future<int> deletePenabung(int id) async {
    final db = await database;
    // transaksi terhapus otomatis via ON DELETE CASCADE
    return await db.delete('penabung', where: 'id = ?', whereArgs: [id]);
  }

  /// Saldo tabungan per penabung: total setor - total ambil
  Future<int> getSaldoPenabung(int penabungId) async {
    final db = await database;
    final res = await db.rawQuery('''
      SELECT
        COALESCE(SUM(CASE WHEN jenis='setor' THEN nominal ELSE 0 END), 0)
        - COALESCE(SUM(CASE WHEN jenis='ambil' THEN nominal ELSE 0 END), 0)
        AS saldo
      FROM transaksi
      WHERE penabung_id = ?
    ''', [penabungId]);
    return (res.first['saldo'] as num).toInt();
  }

  /// Semua penabung beserta saldo masing-masing
  Future<List<Map<String, dynamic>>> getPenabungDenganSaldo() async {
    final db = await database;
    final res = await db.rawQuery('''
      SELECT
        p.id,
        p.nama,
        p.catatan,
        p.dibuat_pada,
        COALESCE(SUM(CASE WHEN t.jenis='setor' THEN t.nominal ELSE 0 END), 0)
        - COALESCE(SUM(CASE WHEN t.jenis='ambil' THEN t.nominal ELSE 0 END), 0)
        AS saldo,
        COALESCE(SUM(CASE WHEN t.jenis='setor' THEN t.nominal ELSE 0 END), 0) AS total_setor,
        COALESCE(SUM(CASE WHEN t.jenis='ambil' THEN t.nominal ELSE 0 END), 0) AS total_ambil
      FROM penabung p
      LEFT JOIN transaksi t ON t.penabung_id = p.id
      GROUP BY p.id
      ORDER BY p.nama ASC
    ''');
    return res;
  }

  /// Total semua uang yang Anda pegang saat ini
  Future<int> getTotalUangDipegang() async {
    final db = await database;
    final res = await db.rawQuery('''
      SELECT
        COALESCE(SUM(CASE WHEN jenis='setor' THEN nominal ELSE 0 END), 0)
        - COALESCE(SUM(CASE WHEN jenis='ambil' THEN nominal ELSE 0 END), 0)
        AS total
      FROM transaksi
    ''');
    return (res.first['total'] as num).toInt();
  }

  /// Ringkasan: total setor & ambil
  Future<Map<String, int>> getSummary() async {
    final db = await database;
    final res = await db.rawQuery('''
      SELECT
        COALESCE(SUM(CASE WHEN jenis='setor' THEN nominal ELSE 0 END), 0) AS total_setor,
        COALESCE(SUM(CASE WHEN jenis='ambil' THEN nominal ELSE 0 END), 0) AS total_ambil
      FROM transaksi
    ''');
    final setor = (res.first['total_setor'] as num).toInt();
    final ambil = (res.first['total_ambil'] as num).toInt();
    return {'setor': setor, 'ambil': ambil, 'total': setor - ambil};
  }

  // ─── TRANSAKSI ────────────────────────────────────────────────

  Future<int> insertTransaksi(Transaksi t) async {
    final db = await database;
    return await db.insert('transaksi', t.toMap());
  }

  Future<List<Transaksi>> getTransaksiByPenabung(int penabungId) async {
    final db = await database;
    final maps = await db.query(
      'transaksi',
      where: 'penabung_id = ?',
      whereArgs: [penabungId],
      orderBy: 'tanggal DESC',
    );
    return maps.map(Transaksi.fromMap).toList();
  }

  /// Semua transaksi semua penabung (dengan nama penabung via JOIN)
  Future<List<Transaksi>> getAllTransaksi() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT t.*, p.nama AS nama_penabung
      FROM transaksi t
      JOIN penabung p ON p.id = t.penabung_id
      ORDER BY t.tanggal DESC
    ''');
    return maps.map(Transaksi.fromMap).toList();
  }

  Future<List<Transaksi>> searchTransaksi(String keyword) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT t.*, p.nama AS nama_penabung
      FROM transaksi t
      JOIN penabung p ON p.id = t.penabung_id
      WHERE p.nama LIKE ? OR t.catatan LIKE ?
      ORDER BY t.tanggal DESC
    ''', ['%$keyword%', '%$keyword%']);
    return maps.map(Transaksi.fromMap).toList();
  }

  Future<int> updateTransaksi(Transaksi t) async {
    final db = await database;
    return await db.update(
      'transaksi',
      t.toMap(),
      where: 'id = ?',
      whereArgs: [t.id],
    );
  }

  Future<int> deleteTransaksi(int id) async {
    final db = await database;
    return await db.delete('transaksi', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Transaksi>> getTransaksiTerbaru({int limit = 5}) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT t.*, p.nama AS nama_penabung
      FROM transaksi t
      JOIN penabung p ON p.id = t.penabung_id
      ORDER BY t.tanggal DESC
      LIMIT ?
    ''', [limit]);
    return maps.map(Transaksi.fromMap).toList();
  }

  /// Data grafik 6 bulan terakhir per penabung
  /// Returns list of {bulan, setor, ambil}
  Future<List<Map<String, dynamic>>> getChartData(int penabungId) async {
    final db = await database;
    final res = await db.rawQuery('''
      SELECT
        strftime('%Y-%m', tanggal) AS bulan,
        COALESCE(SUM(CASE WHEN jenis='setor' THEN nominal ELSE 0 END), 0) AS setor,
        COALESCE(SUM(CASE WHEN jenis='ambil' THEN nominal ELSE 0 END), 0) AS ambil
      FROM transaksi
      WHERE penabung_id = ?
        AND tanggal >= date('now', '-6 months')
      GROUP BY bulan
      ORDER BY bulan ASC
    ''', [penabungId]);
    return res;
  }

  /// Penabung diurutkan berdasarkan saldo tertinggi
  Future<List<Map<String, dynamic>>> getPenabungDenganSaldoSorted({
    String sortBy = 'saldo', // 'saldo' | 'nama' | 'terbaru'
  }) async {
    final db = await database;
    final orderClause = switch (sortBy) {
      'nama' => 'p.nama ASC',
      'terbaru' => 'p.dibuat_pada DESC',
      _ => 'saldo DESC',
    };
    final res = await db.rawQuery('''
      SELECT
        p.id,
        p.nama,
        p.catatan,
        p.dibuat_pada,
        COALESCE(SUM(CASE WHEN t.jenis='setor' THEN t.nominal ELSE 0 END), 0)
        - COALESCE(SUM(CASE WHEN t.jenis='ambil' THEN t.nominal ELSE 0 END), 0)
        AS saldo,
        COALESCE(SUM(CASE WHEN t.jenis='setor' THEN t.nominal ELSE 0 END), 0) AS total_setor,
        COALESCE(SUM(CASE WHEN t.jenis='ambil' THEN t.nominal ELSE 0 END), 0) AS total_ambil,
        COUNT(t.id) AS jumlah_transaksi
      FROM penabung p
      LEFT JOIN transaksi t ON t.penabung_id = p.id
      GROUP BY p.id
      ORDER BY $orderClause
    ''');
    return res;
  }

  // ─── BACKUP & RESTORE ───────────────────────────────────────

  Future<void> clearSemuaData() async {
    final db = await database;
    await db.execute('DELETE FROM transaksi');
    await db.execute('DELETE FROM penabung');
  }

  Future<void> insertPenabungRaw(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('penabung', data);
  }

  Future<void> insertTransaksiRaw(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('transaksi', data);
  }
}

