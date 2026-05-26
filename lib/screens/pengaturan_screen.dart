import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/backup_helper.dart';
import '../utils/pdf_helper.dart';
import '../database/database_helper.dart';
import 'pin_lock_screen.dart';

class PengaturanScreen extends StatefulWidget {
  const PengaturanScreen({super.key});

  @override
  State<PengaturanScreen> createState() => _PengaturanScreenState();
}

class _PengaturanScreenState extends State<PengaturanScreen> {
  bool _loading = false;
  bool _appLockEnabled = false;
  bool _biometricEnabled = false;
  bool _autoBackupEnabled = false;
  String _autoBackupSchedule = 'Harian'; // Harian | Mingguan

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _appLockEnabled = prefs.getBool('app_lock_enabled') ?? false;
      _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      _autoBackupEnabled = prefs.getBool('auto_backup_enabled') ?? false;
      _autoBackupSchedule = prefs.getString('auto_backup_schedule') ?? 'Harian';
    });
  }

  Future<void> _toggleBiometric(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', enabled);
    setState(() {
      _biometricEnabled = enabled;
    });
    _tampilkanPesan(
      enabled ? 'Biometrik diaktifkan!' : 'Biometrik dinonaktifkan',
      enabled,
    );
  }

  void _tampilkanPesan(String pesan, bool sukses) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan, style: const TextStyle(color: Colors.white)),
        backgroundColor: sukses ? const Color(0xFF66BB6A) : const Color(0xFFEF5350),
      ),
    );
  }

  Future<void> _backup() async {
    setState(() => _loading = true);
    final sukses = await BackupHelper.exportBackup();
    if (sukses) {
      _tampilkanPesan('Berhasil menyiapkan file backup!', true);
    } else {
      _tampilkanPesan('Gagal melakukan backup.', false);
    }
    setState(() => _loading = false);
  }

  Future<void> _restore() async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A2840),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Impor Backup',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        content: const Text(
            'PERINGATAN: Semua data penabung dan transaksi saat ini akan DIHAPUS dan diganti dengan data dari file backup.\n\nLanjutkan?',
            style: TextStyle(color: Color(0xFF8899BB))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF8899BB))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF5350),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Ganti Data', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;

    setState(() => _loading = true);
    final sukses = await BackupHelper.importBackup();
    if (sukses) {
      _tampilkanPesan('Berhasil memulihkan data backup!', true);
    } else {
      _tampilkanPesan('Gagal! File tidak valid atau dibatalkan.', false);
    }
    setState(() => _loading = false);
  }

  Future<void> _exportGlobalPDF() async {
    setState(() => _loading = true);
    try {
      final db = DatabaseHelper.instance;
      final rekapList = await db.getPenabungDenganSaldoSorted(sortBy: 'nama');
      
      int grandTotalSaldo = 0;
      int grandTotalSetor = 0;
      int grandTotalAmbil = 0;

      for (var r in rekapList) {
        grandTotalSaldo += (r['saldo'] as num).toInt();
        grandTotalSetor += (r['total_setor'] as num).toInt();
        grandTotalAmbil += (r['total_ambil'] as num).toInt();
      }

      final file = await PdfHelper.generateGlobalStatement(
        rekapList: rekapList,
        grandTotalSaldo: grandTotalSaldo,
        grandTotalSetor: grandTotalSetor,
        grandTotalAmbil: grandTotalAmbil,
      );

      if (mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Laporan Rekapitulasi Global Tabungan Titipan',
        );
      }
    } catch (e) {
      _tampilkanPesan('Gagal mengekspor Laporan Global: $e', false);
    }
    setState(() => _loading = false);
  }

  Future<void> _toggleAppLock() async {
    final targetMode = _appLockEnabled ? PinLockMode.disable : PinLockMode.setup;
    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PinLockScreen(mode: targetMode)),
    );

    if (success == true) {
      _loadPreferences();
    }
  }

  Future<void> _toggleAutoBackup(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_backup_enabled', enabled);
    setState(() {
      _autoBackupEnabled = enabled;
    });
    _tampilkanPesan(
      enabled ? 'Pencadangan Cloud Otomatis Diaktifkan!' : 'Pencadangan Cloud Otomatis Dinonaktifkan',
      enabled,
    );
  }

  Future<void> _changeAutoBackupSchedule(String? val) async {
    if (val == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auto_backup_schedule', val);
    setState(() {
      _autoBackupSchedule = val;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1628),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Text('Pengaturan',
            style: GoogleFonts.poppins(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F8EF7)))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── KEAMANAN APLIKASI ──────────────────────────────────────────
                const Text('Keamanan',
                    style: TextStyle(
                        color: Color(0xFF4F8EF7),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2840),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2A3A50)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F8EF7).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.lock_outline_rounded, color: Color(0xFF4F8EF7), size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Kunci PIN Keamanan',
                                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(_appLockEnabled ? 'Aktif • PIN 4-Digit dikonfigurasi' : 'Nonaktif • Minta sandi PIN di awal',
                                style: const TextStyle(color: Color(0xFF8899BB), fontSize: 11)),
                          ],
                        ),
                      ),
                      Switch(
                        value: _appLockEnabled,
                        onChanged: (_) => _toggleAppLock(),
                        activeThumbColor: const Color(0xFF4F8EF7),
                        activeTrackColor: const Color(0xFF1A3860),
                        inactiveThumbColor: const Color(0xFF8899BB),
                        inactiveTrackColor: const Color(0xFF1A2840),
                      ),
                    ],
                  ),
                ),
                if (_appLockEnabled) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2840),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2A3A50)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E676).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.fingerprint_rounded, color: Color(0xFF00E676), size: 22),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Sidik Jari / Wajah',
                                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                              SizedBox(height: 2),
                              Text('Masuk aplikasi menggunakan sidik jari atau wajah',
                                  style: TextStyle(color: Color(0xFF8899BB), fontSize: 11)),
                            ],
                          ),
                        ),
                        Switch(
                          value: _biometricEnabled,
                          onChanged: _toggleBiometric,
                          activeThumbColor: const Color(0xFF00E676),
                          activeTrackColor: const Color(0xFF00381C),
                          inactiveThumbColor: const Color(0xFF8899BB),
                          inactiveTrackColor: const Color(0xFF1A2840),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // ── LAPORAN KEUANGAN ──────────────────────────────────────────
                const Text('Laporan & Ekspor',
                    style: TextStyle(
                        color: Color(0xFF4F8EF7),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _MenuTile(
                  icon: Icons.summarize_outlined,
                  color: const Color(0xFF64B5F6),
                  title: 'Rekap Laporan Global PDF',
                  subtitle: 'Unduh rekapitulasi data saldo dari semua penabung.',
                  onTap: _exportGlobalPDF,
                ),
                const SizedBox(height: 24),

                // ── PENCADANGAN (BACKUP) ───────────────────────────────────────
                const Text('Pencadangan Data',
                    style: TextStyle(
                        color: Color(0xFF4F8EF7),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _MenuTile(
                  icon: Icons.cloud_upload_outlined,
                  color: const Color(0xFF66BB6A),
                  title: 'Backup Manual (Ekspor JSON)',
                  subtitle: 'Simpan semua data penabung ke file JSON ringan.',
                  onTap: _backup,
                ),
                const SizedBox(height: 12),
                _MenuTile(
                  icon: Icons.cloud_download_outlined,
                  color: const Color(0xFFFFA726),
                  title: 'Pulihkan Manual (Impor JSON)',
                  subtitle: 'Kembalikan data dari file backup JSON sebelumnya.',
                  onTap: _restore,
                ),
                const SizedBox(height: 12),

                // ── AUTO BACKUP SCHEDULER ─────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2840),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2A3A50)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF9575CD).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.sync_outlined, color: Color(0xFF9575CD), size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Pencadangan Cloud Otomatis',
                                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(_autoBackupEnabled ? 'Aktif • Cadangkan otomatis ke cloud' : 'Nonaktif • Menjaga data aman secara lokal',
                                    style: const TextStyle(color: Color(0xFF8899BB), fontSize: 11)),
                              ],
                            ),
                          ),
                          Switch(
                            value: _autoBackupEnabled,
                            onChanged: _toggleAutoBackup,
                            activeThumbColor: const Color(0xFF9575CD),
                            activeTrackColor: const Color(0xFF2E1A4A),
                            inactiveThumbColor: const Color(0xFF8899BB),
                            inactiveTrackColor: const Color(0xFF1A2840),
                          ),
                        ],
                      ),
                      if (_autoBackupEnabled) ...[
                        const SizedBox(height: 16),
                        const Divider(color: Color(0xFF2A3A50), height: 1),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Frekuensi Cadangan',
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A1628),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _autoBackupSchedule,
                                  dropdownColor: const Color(0xFF1A2840),
                                  style: const TextStyle(color: Color(0xFF9575CD), fontSize: 13, fontWeight: FontWeight.w600),
                                  icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF9575CD)),
                                  items: ['Harian', 'Mingguan'].map((String s) {
                                    return DropdownMenuItem<String>(
                                      value: s,
                                      child: Text(s),
                                    );
                                  }).toList(),
                                  onChanged: _changeAutoBackupSchedule,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 40),
                const Center(
                  child: Text('Tabungan Titipan v2.0',
                      style: TextStyle(color: Color(0xFF6677AA), fontSize: 12)),
                ),
              ],
            ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2840),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A3A50)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Color(0xFF8899BB), fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF4A5A6A)),
          ],
        ),
      ),
    );
  }
}
