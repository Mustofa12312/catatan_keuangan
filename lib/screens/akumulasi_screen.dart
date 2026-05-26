import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database_helper.dart';
import '../models/transaksi.dart';
import '../widgets/kartu_akumulasi.dart';
import '../utils/format_rupiah.dart';
import '../widgets/item_transaksi.dart';
import 'tambah_transaksi_screen.dart';

class AkumulasiScreen extends StatefulWidget {
  const AkumulasiScreen({super.key});

  @override
  State<AkumulasiScreen> createState() => _AkumulasiScreenState();
}

class _AkumulasiScreenState extends State<AkumulasiScreen> {
  final _db = DatabaseHelper.instance;
  List<Map<String, dynamic>> _akumulasi = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _db.getAkumulasiPerOrang();
    setState(() {
      _akumulasi = data;
      _loading = false;
    });
  }

  void _lihatDetail(String nama) async {
    final semua = await _db.getAllTransaksi();
    final detail = semua.where((t) => t.nama == nama).toList();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2A3A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (_) => _DetailNama(nama: nama, transaksi: detail, onRefresh: _loadData),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('Akumulasi Per Orang', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: Color(0xFF8899AA)), onPressed: _loadData),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)))
          : _akumulasi.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people_outline_rounded, color: Colors.white24, size: 60),
                      const SizedBox(height: 12),
                      Text('Belum ada data', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 14)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: _akumulasi.length,
                  itemBuilder: (ctx, i) {
                    final item = _akumulasi[i];
                    return KartuAkumulasi(
                      nama: item['nama'] as String,
                      totalMasuk: (item['total_masuk'] as num).toInt(),
                      totalKeluar: (item['total_keluar'] as num).toInt(),
                      net: (item['net'] as num).toInt(),
                      onTap: () => _lihatDetail(item['nama'] as String),
                    );
                  },
                ),
    );
  }
}

class _DetailNama extends StatelessWidget {
  final String nama;
  final List<Transaksi> transaksi;
  final VoidCallback onRefresh;

  const _DetailNama({required this.nama, required this.transaksi, required this.onRefresh});

  int get totalMasuk => transaksi.where((t) => t.jenis == 'masuk').fold(0, (s, t) => s + t.nominal);
  int get totalKeluar => transaksi.where((t) => t.jenis == 'keluar').fold(0, (s, t) => s + t.nominal);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (ctx, scrollCtrl) => Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Text(nama, style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _InfoKotak(label: 'Total Masuk', value: formatRupiah(totalMasuk), color: const Color(0xFF4CAF50))),
                    const SizedBox(width: 8),
                    Expanded(child: _InfoKotak(label: 'Total Keluar', value: formatRupiah(totalKeluar), color: const Color(0xFFE53935))),
                    const SizedBox(width: 8),
                    Expanded(child: _InfoKotak(label: 'Net', value: formatRupiah(totalMasuk - totalKeluar), color: const Color(0xFF1565C0))),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFF2A3A4A)),
                const SizedBox(height: 8),
              ],
            ),
          ),
          // List transaksi
          Expanded(
            child: ListView.builder(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              itemCount: transaksi.length,
              itemBuilder: (ctx, i) {
                final t = transaksi[i];
                return ItemTransaksi(
                  transaksi: t,
                  onEdit: () async {
                    Navigator.pop(ctx);
                    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => TambahTransaksiScreen(transaksi: t)));
                    if (result == true) onRefresh();
                  },
                  onDelete: () async {
                    Navigator.pop(ctx);
                    await DatabaseHelper.instance.deleteTransaksi(t.id!);
                    onRefresh();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoKotak extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _InfoKotak({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF8899AA), fontSize: 10)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
