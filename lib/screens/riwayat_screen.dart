import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database_helper.dart';
import '../models/transaksi.dart';
import '../widgets/item_transaksi.dart';
import 'tambah_transaksi_screen.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  final _db = DatabaseHelper.instance;
  final _searchCtrl = TextEditingController();
  List<Transaksi> _transaksi = [];
  String _filter = 'semua'; // semua | masuk | keluar
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final keyword = _searchCtrl.text.trim();
    final List<Transaksi> data = keyword.isEmpty
        ? await _db.getAllTransaksi()
        : await _db.searchTransaksi(keyword);

    setState(() {
      _transaksi = _filter == 'semua'
          ? data
          : data.where((t) => t.jenis == _filter).toList();
      _loading = false;
    });
  }

  Future<void> _editTransaksi(Transaksi t) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TambahTransaksiScreen(transaksi: t)),
    );
    if (result == true) _loadData();
  }

  Future<void> _hapusTransaksi(int id) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E2A3A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Transaksi', style: TextStyle(color: Colors.white)),
        content: const Text('Yakin ingin menghapus transaksi ini?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal', style: TextStyle(color: Color(0xFF8899AA)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('Riwayat Transaksi', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              onChanged: (_) => _loadData(),
              decoration: InputDecoration(
                hintText: 'Cari nama, kategori, catatan...',
                hintStyle: const TextStyle(color: Color(0xFF8899AA), fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF8899AA), size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear_rounded, color: Color(0xFF8899AA), size: 18), onPressed: () { _searchCtrl.clear(); _loadData(); })
                    : null,
                filled: true,
                fillColor: const Color(0xFF1E2A3A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),

          // Filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                _FilterChip(label: 'Semua', aktif: _filter == 'semua', onTap: () { setState(() => _filter = 'semua'); _loadData(); }),
                const SizedBox(width: 8),
                _FilterChip(label: 'Masuk', aktif: _filter == 'masuk', color: const Color(0xFF4CAF50), onTap: () { setState(() => _filter = 'masuk'); _loadData(); }),
                const SizedBox(width: 8),
                _FilterChip(label: 'Keluar', aktif: _filter == 'keluar', color: const Color(0xFFE53935), onTap: () { setState(() => _filter = 'keluar'); _loadData(); }),
              ],
            ),
          ),

          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)))
                : _transaksi.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.receipt_long_outlined, color: Colors.white24, size: 60),
                            const SizedBox(height: 12),
                            Text('Tidak ada transaksi', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 14)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        itemCount: _transaksi.length,
                        itemBuilder: (ctx, i) {
                          final t = _transaksi[i];
                          return ItemTransaksi(
                            transaksi: t,
                            onEdit: () => _editTransaksi(t),
                            onDelete: () => _hapusTransaksi(t.id!),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool aktif;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.aktif,
    this.color = const Color(0xFF1565C0),
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: aktif ? color.withValues(alpha: 0.15) : const Color(0xFF1E2A3A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: aktif ? color.withValues(alpha: 0.5) : const Color(0xFF2A3A4A)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: aktif ? color : const Color(0xFF8899AA),
            fontSize: 12,
            fontWeight: aktif ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
