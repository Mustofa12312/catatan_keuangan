import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/backup_helper.dart';

class PengaturanScreen extends StatefulWidget {
  const PengaturanScreen({super.key});

  @override
  State<PengaturanScreen> createState() => _PengaturanScreenState();
}

class _PengaturanScreenState extends State<PengaturanScreen> {
  bool _loading = false;

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
                const Text('Data & Keamanan',
                    style: TextStyle(
                        color: Color(0xFF4F8EF7),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                _MenuTile(
                  icon: Icons.cloud_upload_outlined,
                  color: const Color(0xFF66BB6A),
                  title: 'Backup Data (Ekspor)',
                  subtitle: 'Simpan semua data penabung ke file JSON ringan.',
                  onTap: _backup,
                ),
                const SizedBox(height: 12),
                _MenuTile(
                  icon: Icons.cloud_download_outlined,
                  color: const Color(0xFFFFA726),
                  title: 'Pulihkan Data (Impor)',
                  subtitle: 'Kembalikan data dari file backup yang tersimpan.',
                  onTap: _restore,
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
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Color(0xFF8899BB), fontSize: 12)),
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
