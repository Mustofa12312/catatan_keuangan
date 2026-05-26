import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database_helper.dart';
import '../models/transaksi.dart';
import '../widgets/item_transaksi.dart';
import 'tambah_transaksi_screen.dart';
import 'detail_penabung_screen.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  final _db = DatabaseHelper.instance;
  final _searchCtrl = TextEditingController();
  List<Transaksi> _transaksi = [];
  String _filter = 'semua';
  bool _loading = true;
  int _totalSetor = 0;
  int _totalAmbil = 0;

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
    setState(() => _loading = true);
    final keyword = _searchCtrl.text.trim();
    final List<Transaksi> data = keyword.isEmpty
        ? await _db.getAllTransaksi()
        : await _db.searchTransaksi(keyword);
    final filtered = _filter == 'semua'
        ? data
        : data.where((t) => t.jenis == _filter).toList();

    setState(() {
      _transaksi = filtered;
      _totalSetor = filtered
          .where((t) => t.jenis == 'setor')
          .fold(0, (s, t) => s + t.nominal);
      _totalAmbil = filtered
          .where((t) => t.jenis == 'ambil')
          .fold(0, (s, t) => s + t.nominal);
      _loading = false;
    });
  }

  Future<void> _editTransaksi(Transaksi t) async {
    // Ambil saldo penabung untuk validasi
    final saldo = await _db.getSaldoPenabung(t.penabungId);
    if (!mounted) return;
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context3, anim, widget2) => TambahTransaksiScreen(
          penabungId: t.penabungId,
          namaPenabung: t.namaPenabung ?? '',
          transaksi: t,
          saldoSaatIni: saldo,
        ),
        transitionsBuilder: (ctx2, anim2, secAnim, child) => SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(
                  parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
    if (result == true) _loadData();
  }

  Future<void> _hapusTransaksi(int id) async {
    await _db.deleteTransaksi(id);
    _loadData();
  }

  void _bukaDetail(Transaksi t) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context3, anim, widget2) => DetailPenabungScreen(
          penabungId: t.penabungId,
          namaPenabung: t.namaPenabung ?? '',
        ),
        transitionsBuilder: (ctx2, anim2, secAnim, child) => SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(
                  parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Semua Transaksi',
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700)),
                        Text('${_transaksi.length} transaksi tercatat',
                            style: GoogleFonts.poppins(
                                color: const Color(0xFF8899BB),
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded,
                        color: Color(0xFF8899BB)),
                    onPressed: _loadData,
                  ),
                ],
              ),
            ),

            // ── Mini Summary ─────────────────────────────────────────
            if (!_loading && _transaksi.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        label: 'Total Setor',
                        value: _totalSetor,
                        color: const Color(0xFF66BB6A),
                        icon: Icons.south_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniStat(
                        label: 'Total Ambil',
                        value: _totalAmbil,
                        color: const Color(0xFFEF9A9A),
                        icon: Icons.north_rounded,
                      ),
                    ),
                  ],
                ),
              ),

            // ── Search ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: Colors.white),
                onChanged: (_) => _loadData(),
                decoration: InputDecoration(
                  hintText: 'Cari nama penabung atau catatan...',
                  hintStyle: const TextStyle(
                      color: Color(0xFF8899BB), fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: Color(0xFF8899BB), size: 20),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded,
                              color: Color(0xFF8899BB), size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            _loadData();
                          })
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF1A2840),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
            ),

            // ── Filter Chips ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Semua',
                    aktif: _filter == 'semua',
                    onTap: () {
                      setState(() => _filter = 'semua');
                      _loadData();
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Setor',
                    aktif: _filter == 'setor',
                    color: const Color(0xFF66BB6A),
                    onTap: () {
                      setState(() => _filter = 'setor');
                      _loadData();
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Ambil',
                    aktif: _filter == 'ambil',
                    color: const Color(0xFFEF9A9A),
                    onTap: () {
                      setState(() => _filter = 'ambil');
                      _loadData();
                    },
                  ),
                  const Spacer(),
                  Text(
                    '← geser hapus',
                    style: const TextStyle(
                        color: Color(0xFF4A5A6A), fontSize: 10),
                  ),
                ],
              ),
            ),

            // ── List ─────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF4F8EF7)))
                  : _transaksi.isEmpty
                      ? _buildEmpty()
                      : ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(20, 0, 20, 80),
                          itemCount: _transaksi.length,
                          itemBuilder: (ctx, i) {
                            final t = _transaksi[i];
                            return GestureDetector(
                              onLongPress: () => _bukaDetail(t),
                              child: ItemTransaksi(
                                transaksi: t,
                                tampilkanNama: true,
                                onEdit: () => _editTransaksi(t),
                                onDelete: () =>
                                    _hapusTransaksi(t.id!),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF1A2840),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.receipt_long_outlined,
                color: Color(0xFF4F8EF7), size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            _searchCtrl.text.isNotEmpty
                ? 'Tidak ada hasil pencarian'
                : 'Belum ada transaksi',
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            _searchCtrl.text.isNotEmpty
                ? 'Coba kata kunci lain'
                : 'Mulai catat setoran atau penarikan\ndi halaman Penabung',
            style: GoogleFonts.poppins(
                color: const Color(0xFF8899BB), fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _MiniStat(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: color.withValues(alpha: 0.7),
                        fontSize: 10)),
                Text(
                  'Rp ${(value / 1000).toStringAsFixed(0)}rb',
                  style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w700),
                ),
              ],
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
    this.color = const Color(0xFF4F8EF7),
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: aktif
              ? color.withValues(alpha: 0.15)
              : const Color(0xFF1A2840),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: aktif
                  ? color.withValues(alpha: 0.5)
                  : const Color(0xFF2A3A50)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: aktif ? color : const Color(0xFF8899BB),
            fontSize: 12,
            fontWeight: aktif ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
