import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../database/database_helper.dart';

class BackupHelper {
  static Future<bool> exportBackup() async {
    try {
      final db = DatabaseHelper.instance;
      final allPenabung = await db.getAllPenabung();
      final allTransaksi = await db.getAllTransaksi();

      final data = {
        'versi': 1,
        'tanggal': DateTime.now().toIso8601String(),
        'penabung': allPenabung.map((p) => p.toMap()).toList(),
        'transaksi': allTransaksi.map((t) => t.toMap()).toList(),
      };

      final jsonStr = jsonEncode(data);

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/backup_tabungan_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonStr);

      await Share.shareXFiles([XFile(file.path)], text: 'Backup Data Tabungan Titipan (Ringan)');
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> importBackup() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'txt'],
      );

      if (result == null || result.files.single.path == null) return false;

      final file = File(result.files.single.path!);
      final jsonStr = await file.readAsString();
      
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      
      if (!data.containsKey('penabung') || !data.containsKey('transaksi')) {
        return false; // File tidak valid
      }

      final db = DatabaseHelper.instance;
      
      // Hapus semua data lama untuk diganti dengan backup
      await db.clearSemuaData();
      
      for (var pMap in (data['penabung'] as List)) {
        await db.insertPenabungRaw(pMap as Map<String, dynamic>);
      }
      
      for (var tMap in (data['transaksi'] as List)) {
        await db.insertTransaksiRaw(tMap as Map<String, dynamic>);
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
}
