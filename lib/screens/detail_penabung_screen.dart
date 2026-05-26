import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database_helper.dart';
import '../models/penabung.dart';
import '../models/transaksi.dart';
import '../utils/format_rupiah.dart';
import '../widgets/item_transaksi.dart';
import 'tambah_transaksi_screen.dart';
import 'tambah_penabung_screen.dart';

class DetailPenabungScreen extends StatefulWidget {
  final int penabungId;
  final String namaPenabung;

  const DetailPenabungScreen({
    super.key,
    required this.penabungId,
    required this.namaPenabung,
  });

  @override
  State<DetailPenabungScreen> createState() => _DetailPenabungScreenState();
}

class _DetailPenabungScreenState extends State<DetailPenabungScreen> {
  final _db = DatabaseHelper.instance;
  Penabung? _penabung;
  List<Transaksi> _transaksi = [];
  int _saldo = 0;
  int _totalSetor = 0;
  int _totalAmbil = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final p = await _db.getPenabungById(widget.penabungId);
    final list = await _db.getTransaksiByPenabung(widget.penabungId);
    final saldo = await _db.getSaldoPenabung(widget.penabungId);
    final setor = list
        .where((t) => t.jenis == 'setor')
        .fold(0, (s, t) => s + t.nominal);
    final ambil = list
        .where((t) => t.jenis == 'ambil')
        .fold(0, (s, t) => s + t.nominal);

    if (mounted) {
      setState(() {
        _penabung = p;
        _transaksi = list;
        _saldo = saldo;
        _totalSetor = setor;
        _totalAmbil = ambil;
        _loading = false;
      });
    }
  }

  Future<void> _tambahTransaksi(String jenis) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TambahTransaksiScreen(
          penabungId: widget.penabungId,
          namaPenabung: _penabung?.nama ?? widget.namaPenabung,
          jenisAwal: jenis,
        ),
      ),
    );
    if (result == true) _loadData();
  }

  Future<void> _editTransaksi(Transaksi t) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TambahTransaksiScreen(
          penabungId: widget.penabungId,
          namaPenabung: _penabung?.nama ?? widget.namaPenabung,
          transaksi: t,
        ),
      ),
    );
    if (result == true) _loadData();
  }

  Future<void> _hapusTransaksi(int id) async {
    final ok = await _konfirmasi('Hapus transaksi ini?');
    if (ok) {
      await _db.deleteTransaksi(id);
      _loadData();
    }
  }

  Future<void> _editPenabung() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => TambahPenabungScreen(penabung: _penabung)),
    );
    if (result == true) _loadData();
  }

  Future<void> _hapusPenabung() async {
    final ok = await _konfirmasi(
        'Hapus penabung ini beserta seluruh riwayat transaksinya?');
    if (ok) {
      await _db.deletePenabung(widget.penabungId);
      if (mounted) Navigator.pop(context, true);
    }
  }

  Future<bool> _konfirmasi(String pesan) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E2A3A),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi',
            style: TextStyle(color: Colors.white)),
        content:
            Text(pesan, style: const TextStyle(color: Colors.white70)),
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
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Color get _saldoColor =>
      _saldo > 0 ? const Color(0xFF4CAF50) : (_saldo == 0 ? const Color(0xFF8899AA) : const Color(0xFFE57373));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)))
          : CustomScrollView(
              slivers: [
                // App bar
                SliverAppBar(
                  expandedHeight: 220,
                  pinned: true,
                  backgroundColor: const Color(0xFF0D1B2A),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded,
                        color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      color: const Color(0xFF1E2A3A),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      onSelected: (v) {
                        if (v == 'edit') _editPenabung();
                        if (v == 'hapus') _hapusPenabung();
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [
                            Icon(Icons.edit_outlined,
                                color: Colors.blueAccent, size: 18),
                            SizedBox(width: 10),
                            Text('Edit Penabung',
                                style: TextStyle(color: Colors.white)),
                          ]),
                        ),
                        const PopupMenuItem(
                          value: 'hapus',
                          child: Row(children: [
                            Icon(Icons.delete_outline,
                                color: Colors.redAccent, size: 18),
                            SizedBox(width: 10),
                            Text('Hapus Penabung',
                                style: TextStyle(color: Colors.white)),
                          ]),
                        ),
                      ],
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: _HeaderPenabung(
                      nama: _penabung?.nama ?? widget.namaPenabung,
                      catatan: _penabung?.catatan ?? '',
                      saldo: _saldo,
                      totalSetor: _totalSetor,
                      totalAmbil: _totalAmbil,
                      saldoColor: _saldoColor,
                    ),
                  ),
                ),

                // Tombol setor & ambil
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: _TombolAksi(
                            label: 'Setor',
                            icon: Icons.south_rounded,
                            color: const Color(0xFF4CAF50),
                            onTap: () => _tambahTransaksi('setor'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TombolAksi(
                            label: 'Ambil',
                            icon: Icons.north_rounded,
                            color: const Color(0xFFE57373),
                            onTap: () => _tambahTransaksi('ambil'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Header riwayat
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                    child: Text(
                      'Riwayat Transaksi (${_transaksi.length})',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // List transaksi
                if (_transaksi.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Column(
                        children: [
                          const Icon(Icons.receipt_long_outlined,
                              color: Colors.white24, size: 50),
                          const SizedBox(height: 12),
                          Text('Belum ada transaksi',
                              style: GoogleFonts.poppins(
                                  color: Colors.white38, fontSize: 13)),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final t = _transaksi[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: ItemTransaksi(
                            transaksi: t,
                            onEdit: () => _editTransaksi(t),
                            onDelete: () => _hapusTransaksi(t.id!),
                          ),
                        );
                      },
                      childCount: _transaksi.length,
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 30)),
              ],
            ),
    );
  }
}

class _HeaderPenabung extends StatelessWidget {
  final String nama;
  final String catatan;
  final int saldo;
  final int totalSetor;
  final int totalAmbil;
  final Color saldoColor;

  const _HeaderPenabung({
    required this.nama,
    required this.catatan,
    required this.saldo,
    required this.totalSetor,
    required this.totalAmbil,
    required this.saldoColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF0D1B2A)),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          saldoColor.withValues(alpha: 0.3),
                          saldoColor.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Text(
                        nama.isNotEmpty ? nama[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: saldoColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nama,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700)),
                        if (catatan.isNotEmpty)
                          Text(catatan,
                              style: const TextStyle(
                                  color: Color(0xFF8899AA), fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2A3A),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: saldoColor.withValues(alpha: 0.3), width: 1),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Saldo Tabungan',
                            style: const TextStyle(
                                color: Color(0xFF8899AA), fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatRupiah(saldo),
                      style: TextStyle(
                          color: saldoColor,
                          fontSize: 26,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatItem(
                              label: 'Total Setor',
                              value: formatRupiah(totalSetor),
                              color: const Color(0xFF4CAF50)),
                        ),
                        Container(
                            width: 1, height: 30, color: const Color(0xFF2A3A4A)),
                        Expanded(
                          child: _StatItem(
                              label: 'Total Ambil',
                              value: formatRupiah(totalAmbil),
                              color: const Color(0xFFE57373)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: Color(0xFF8899AA), fontSize: 11)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _TombolAksi extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TombolAksi(
      {required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
