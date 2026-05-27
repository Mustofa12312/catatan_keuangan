import 'dart:convert';
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../database/database_helper.dart';

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

class GoogleDriveHelper {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  static Future<drive.DriveApi?> _getDriveApi() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return null;

      final headers = await account.authHeaders;
      final client = GoogleAuthClient(headers);
      return drive.DriveApi(client);
    } catch (e) {
      print("Google SignIn Error: $e");
      return null;
    }
  }

  static Future<bool> backupToDrive() async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return false;

      // 1. Siapkan data backup
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
      
      // 2. Simpan ke temporary file
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/backup_kas_keluarga.json');
      await file.writeAsString(jsonStr);

      // 3. Cek apakah sudah ada file backup sebelumnya di Drive
      final fileList = await driveApi.files.list(
        q: "name = 'backup_kas_keluarga.json' and trashed = false",
        spaces: 'drive',
      );

      final media = drive.Media(file.openRead(), file.lengthSync());

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        // Update file existing
        final existingFileId = fileList.files!.first.id!;
        final driveFile = drive.File();
        await driveApi.files.update(driveFile, existingFileId, uploadMedia: media);
      } else {
        // Buat file baru
        final driveFile = drive.File()
          ..name = 'backup_kas_keluarga.json'
          ..mimeType = 'application/json';
        await driveApi.files.create(driveFile, uploadMedia: media);
      }

      return true;
    } catch (e) {
      print("Backup to Drive Error: $e");
      return false;
    }
  }

  static Future<bool> restoreFromDrive() async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return false;

      // 1. Cari file backup
      final fileList = await driveApi.files.list(
        q: "name = 'backup_kas_keluarga.json' and trashed = false",
        spaces: 'drive',
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        return false; // Tidak ada file backup
      }

      final fileId = fileList.files!.first.id!;

      // 2. Download file
      final drive.Media media = await driveApi.files.get(fileId, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
      
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/restore_kas_keluarga.json');
      
      final sink = file.openWrite();
      await media.stream.pipe(sink);
      await sink.flush();
      await sink.close();

      // 3. Baca dan verifikasi data
      final jsonStr = await file.readAsString();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      
      if (!data.containsKey('penabung') || !data.containsKey('transaksi')) {
        return false;
      }

      // 4. Restore ke database
      final db = DatabaseHelper.instance;
      await db.clearSemuaData();
      
      for (var pMap in (data['penabung'] as List)) {
        await db.insertPenabungRaw(pMap as Map<String, dynamic>);
      }
      for (var tMap in (data['transaksi'] as List)) {
        await db.insertTransaksiRaw(tMap as Map<String, dynamic>);
      }
      
      return true;
    } catch (e) {
      print("Restore from Drive Error: $e");
      return false;
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
