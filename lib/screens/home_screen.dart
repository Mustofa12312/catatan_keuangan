import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database_helper.dart';
import '../utils/format_rupiah.dart';
import '../widgets/kartu_penabung.dart';
import 'detail_penabung_screen.dart';
import 'tambah_penabung_screen.dart';
import 'tambah_transaksi_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _db = DatabaseHelper.instance;
  List<Map<String, dynamic>> _penabungList = [];
  Map<String, int> _summary = {'setor': 0, 'ambil': 0, 'total': 0};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final penabung = await _db.getPenabungDenganSaldo();
    final summary = await _db.getSummary();
    if (mounted) {
      setState(() {
        _penabungList = penabung;
        _summary = summary;
        _loading = false;
      });
    }
  }

  Future<void> _tambahPenabung() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TambahPenabungScreen()),
    );
    if (result == true) _loadData();
  }

  Future<void> _buka(Map<String, dynamic> item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailPenabungScreen(
          penabungId: item['id'] as int,
          namaPenabung: item['nama'] as String,
        ),
      ),
    );
    _loadData();
  }

  Future<void> _setor(Map<String, dynamic> item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TambahTransaksiScreen(
          penabungId: item['id'] as int,
          namaPenabung: item['nama'] as String,
          jenisAwal: 'setor',
        ),
      ),
    );
    if (result == true) _loadData();
  }

  Future<void> _ambil(Map<String, dynamic> item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TambahTransaksiScreen(
          penabungId: item['id'] as int,
          namaPenabung: item['nama'] as String,
          jenisAwal: 'ambil',
        ),
      ),
    );
    if (result == true) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)))
            : RefreshIndicator(
                onRefresh: _loadData,
                color: const Color(0xFF1565C0),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // App Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tabungan Titipan',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      'Kelola titipan tabungan bersama',
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
                                  child: const Icon(Icons.savings_rounded,
                                      color: Color(0xFF1565C0), size: 22),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),

                            // Kartu Total
                            _KartuTotal(
                              total: _summary['total'] ?? 0,
                              totalSetor: _summary['setor'] ?? 0,
                              totalAmbil: _summary['ambil'] ?? 0,
                              jumlahPenabung: _penabungList.length,
                            ),
                            const SizedBox(height: 24),

                            // Header daftar
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Daftar Penabung',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _tambahPenabung,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1565C0).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFF1565C0).withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.person_add_alt_1_rounded,
                                            color: Color(0xFF1565C0), size: 16),
                                        SizedBox(width: 6),
                                        Text(
                                          'Tambah',
                                          style: TextStyle(
                                            color: Color(0xFF1565C0),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),

                    // List Penabung
                    if (_penabungList.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 60),
                          child: Column(
                            children: [
                              const Icon(Icons.people_outline_rounded,
                                  color: Colors.white24, size: 64),
                              const SizedBox(height: 14),
                              Text(
                                'Belum ada penabung',
                                style: GoogleFonts.poppins(
                                    color: Colors.white38, fontSize: 15),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Tap tombol "Tambah" untuk menambah penabung',
                                style: GoogleFonts.poppins(
                                    color: Colors.white24, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1565C0),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: _tambahPenabung,
                                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                                label: const Text('Tambah Penabung Pertama'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            final item = _penabungList[i];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: KartuPenabung(
                                nama: item['nama'] as String,
                                catatan: (item['catatan'] as String?) ?? '',
                                saldo: (item['saldo'] as num).toInt(),
                                totalSetor: (item['total_setor'] as num).toInt(),
                                totalAmbil: (item['total_ambil'] as num).toInt(),
                                onTap: () => _buka(item),
                                onSetor: () => _setor(item),
                                onAmbil: () => _ambil(item),
                              ),
                            );
                          },
                          childCount: _penabungList.length,
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 30)),
                  ],
                ),
              ),
      ),
    );
  }
}

class _KartuTotal extends StatelessWidget {
  final int total;
  final int totalSetor;
  final int totalAmbil;
  final int jumlahPenabung;

  const _KartuTotal({
    required this.total,
    required this.totalSetor,
    required this.totalAmbil,
    required this.jumlahPenabung,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Uang yang Anda Pegang',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(
                    '$jumlahPenabung orang menitipkan',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            formatRupiah(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _InfoBox(
                  label: 'Total Diterima',
                  value: formatRupiah(totalSetor),
                  icon: Icons.south_rounded,
                  color: const Color(0xFF81C784),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoBox(
                  label: 'Total Dikembalikan',
                  value: formatRupiah(totalAmbil),
                  icon: Icons.north_rounded,
                  color: const Color(0xFFEF9A9A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoBox({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
