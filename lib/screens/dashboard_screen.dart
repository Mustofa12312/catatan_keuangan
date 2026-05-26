import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database_helper.dart';
import '../models/transaksi.dart';
import '../widgets/kartu_saldo.dart';
import '../widgets/item_transaksi.dart';
import 'tambah_transaksi_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _db = DatabaseHelper.instance;
  Map<String, int> _summary = {'masuk': 0, 'keluar': 0, 'saldo': 0};
  List<Transaksi> _transaksiTerbaru = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final summary = await _db.getSummary();
    final terbaru = await _db.getTransaksiTerbaru(limit: 5);
    if (mounted) {
      setState(() {
        _summary = summary;
        _transaksiTerbaru = terbaru;
        _loading = false;
      });
    }
  }

  Future<void> _navigasiTambah({String? jenisAwal}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TambahTransaksiScreen(jenisAwal: jenisAwal),
      ),
    );
    if (result == true) _loadData();
  }

  Future<void> _editTransaksi(Transaksi t) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TambahTransaksiScreen(transaksi: t),
      ),
    );
    if (result == true) _loadData();
  }

  Future<void> _hapusTransaksi(int id) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E2A3A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Transaksi',
            style: TextStyle(color: Colors.white)),
        content: const Text('Yakin ingin menghapus transaksi ini?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal',
                style: TextStyle(color: Color(0xFF8899AA))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (konfirmasi == true) {
      await _db.deleteTransaksi(id);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1565C0)))
            : RefreshIndicator(
                onRefresh: _loadData,
                color: const Color(0xFF1565C0),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Kas Keluarga',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      'Kelola keuangan keluarga dengan mudah',
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFF8899AA),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E2A3A),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.home_rounded,
                                    color: Color(0xFF1565C0),
                                    size: 22,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Kartu Saldo
                            KartuSaldo(
                              saldo: _summary['saldo'] ?? 0,
                              totalMasuk: _summary['masuk'] ?? 0,
                              totalKeluar: _summary['keluar'] ?? 0,
                            ),
                            const SizedBox(height: 20),

                            // Tombol aksi cepat
                            Row(
                              children: [
                                Expanded(
                                  child: _TombolAksi(
                                    label: 'Tambah Masuk',
                                    icon: Icons.add_circle_outline_rounded,
                                    color: const Color(0xFF4CAF50),
                                    onTap: () =>
                                        _navigasiTambah(jenisAwal: 'masuk'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _TombolAksi(
                                    label: 'Tambah Keluar',
                                    icon: Icons.remove_circle_outline_rounded,
                                    color: const Color(0xFFE53935),
                                    onTap: () =>
                                        _navigasiTambah(jenisAwal: 'keluar'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Transaksi terbaru
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Transaksi Terbaru',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                    if (_transaksiTerbaru.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Icon(Icons.receipt_long_outlined,
                                  color: Colors.white24, size: 60),
                              const SizedBox(height: 12),
                              Text(
                                'Belum ada transaksi',
                                style: GoogleFonts.poppins(
                                    color: Colors.white38, fontSize: 14),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Mulai catat pemasukan atau pengeluaran',
                                style: GoogleFonts.poppins(
                                    color: Colors.white24, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            final t = _transaksiTerbaru[i];
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: ItemTransaksi(
                                transaksi: t,
                                onEdit: () => _editTransaksi(t),
                                onDelete: () => _hapusTransaksi(t.id!),
                              ),
                            );
                          },
                          childCount: _transaksiTerbaru.length,
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 80)),
                  ],
                ),
              ),
      ),
    );
  }
}

class _TombolAksi extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TombolAksi({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
