import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import '../database/database_helper.dart';
import '../models/penabung.dart';
import '../models/transaksi.dart';
import '../utils/format_rupiah.dart';
import '../utils/pdf_helper.dart';
import '../widgets/item_transaksi.dart';
import 'tambah_transaksi_screen.dart';
import 'tambah_penabung_screen.dart';
import 'transfer_screen.dart';

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
  List<Map<String, dynamic>> _chartData = [];
  int _saldo = 0;
  int _totalSetor = 0;
  int _totalAmbil = 0;
  bool _loading = true;
  DateTimeRange? _filterRange;

  List<Transaksi> get _filteredTransaksi {
    if (_filterRange == null) return _transaksi;
    return _transaksi.where((t) {
      final tgl = DateTime.parse(t.tanggal);
      final start = DateTime(_filterRange!.start.year, _filterRange!.start.month, _filterRange!.start.day);
      final end = DateTime(_filterRange!.end.year, _filterRange!.end.month, _filterRange!.end.day, 23, 59, 59);
      return tgl.isAfter(start.subtract(const Duration(seconds: 1))) && tgl.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();
  }

  Future<void> _pilihFilterTanggal() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _filterRange,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF4F8EF7),
            surface: Color(0xFF1A2840),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _filterRange = picked;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final p = await _db.getPenabungById(widget.penabungId);
    final list = await _db.getTransaksiByPenabung(widget.penabungId);
    final saldo = await _db.getSaldoPenabung(widget.penabungId);
    final chart = await _db.getChartData(widget.penabungId);
    final setor =
        list.where((t) => t.jenis == 'setor').fold(0, (s, t) => s + t.nominal);
    final ambil =
        list.where((t) => t.jenis == 'ambil').fold(0, (s, t) => s + t.nominal);

    if (mounted) {
      setState(() {
        _penabung = p;
        _transaksi = list;
        _saldo = saldo;
        _totalSetor = setor;
        _totalAmbil = ambil;
        _chartData = chart;
        _loading = false;
      });
    }
  }

  Future<void> _tambahTransaksi(String jenis) async {
    final result = await Navigator.push(
      context,
      _slideRoute(TambahTransaksiScreen(
        penabungId: widget.penabungId,
        namaPenabung: _penabung?.nama ?? widget.namaPenabung,
        jenisAwal: jenis,
        saldoSaatIni: _saldo,
      )),
    );
    if (result == true) _loadData();
  }

  Future<void> _editTransaksi(Transaksi t) async {
    final result = await Navigator.push(
      context,
      _slideRoute(TambahTransaksiScreen(
        penabungId: widget.penabungId,
        namaPenabung: _penabung?.nama ?? widget.namaPenabung,
        transaksi: t,
        saldoSaatIni: _saldo,
      )),
    );
    if (result == true) _loadData();
  }

  Future<void> _transferTransaksi() async {
    final result = await Navigator.push(
      context,
      _slideRoute(TransferScreen(
        senderId: widget.penabungId,
        senderName: _penabung?.nama ?? widget.namaPenabung,
        senderSaldo: _saldo,
      )),
    );
    if (result == true) _loadData();
  }

  Future<void> _hapusTransaksi(int id) async {
    await _db.deleteTransaksi(id);
    _loadData();
  }

  Future<void> _editPenabung() async {
    final result = await Navigator.push(
      context,
      _slideRoute(TambahPenabungScreen(penabung: _penabung)),
    );
    if (result == true) _loadData();
  }

  Future<void> _hapusPenabung() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A2840),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Penabung',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        content: const Text(
            'Penabung beserta seluruh riwayat transaksinya akan dihapus permanen.',
            style: TextStyle(color: Color(0xFF8899BB))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal',
                style: TextStyle(color: Color(0xFF8899BB))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF5350),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _db.deletePenabung(widget.penabungId);
      if (mounted) Navigator.pop(context, true);
    }
  }

  Future<void> _exportToPDF() async {
    if (_penabung == null) return;
    
    setState(() => _loading = true);
    try {
      final listToExport = _filteredTransaksi;
      final setor = listToExport.where((t) => t.jenis == 'setor').fold(0, (s, t) => s + t.nominal);
      final ambil = listToExport.where((t) => t.jenis == 'ambil').fold(0, (s, t) => s + t.nominal);
      final saldo = setor - ambil;

      final file = await PdfHelper.generateStatement(
        penabung: _penabung!,
        transaksiList: listToExport,
        saldoAkhir: saldo,
        totalSetor: setor,
        totalAmbil: ambil,
      );

      if (mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Laporan Rekening Koran Tabungan Titipan: ${_penabung!.nama}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengekspor PDF: $e')),
        );
      }
    }
    setState(() => _loading = false);
  }

  PageRoute _slideRoute(Widget page) => PageRouteBuilder(
        pageBuilder: (context3, anim, widget2) => page,
        transitionsBuilder: (ctx2, anim2, secAnim, child) => SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(
            CurvedAnimation(parent: anim2, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 300),
      );

  Color get _saldoColor => _saldo > 0
      ? const Color(0xFF66BB6A)
      : (_saldo == 0 ? const Color(0xFF8899BB) : const Color(0xFFEF5350));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4F8EF7)))
          : CustomScrollView(
              slivers: [
                // ── App Bar ─────────────────────────────────────────
                SliverAppBar(
                  pinned: true,
                  backgroundColor: const Color(0xFF0A1628),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      color: const Color(0xFF1A2840),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      onSelected: (v) {
                        if (v == 'ekspor') _exportToPDF();
                        if (v == 'edit') _editPenabung();
                        if (v == 'hapus') _hapusPenabung();
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'ekspor',
                          child: Row(children: [
                            Icon(Icons.picture_as_pdf_outlined,
                                color: Color(0xFF4F8EF7), size: 16),
                            SizedBox(width: 10),
                            Text('Ekspor PDF Laporan',
                                style: TextStyle(color: Colors.white, fontSize: 14)),
                          ]),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [
                            Icon(Icons.edit_outlined,
                                color: Colors.blueAccent, size: 16),
                            SizedBox(width: 10),
                            Text('Edit Penabung',
                                style: TextStyle(color: Colors.white, fontSize: 14)),
                          ]),
                        ),
                        const PopupMenuItem(
                          value: 'hapus',
                          child: Row(children: [
                            Icon(Icons.delete_outline,
                                color: Colors.redAccent, size: 16),
                            SizedBox(width: 10),
                            Text('Hapus Penabung',
                                style: TextStyle(color: Colors.white, fontSize: 14)),
                          ]),
                        ),
                      ],
                    ),
                  ],
                ),

                // ── Header (Aman dari Overflow) ─────────────────────
                SliverToBoxAdapter(
                  child: _buildHeader(),
                ),

                // ── Tombol Aksi ─────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: _TombolAksi(
                            label: 'Setor',
                            icon: Icons.south_rounded,
                            color: const Color(0xFF66BB6A),
                            onTap: () => _tambahTransaksi('setor'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _TombolAksi(
                            label: 'Ambil',
                            icon: Icons.north_rounded,
                            color: const Color(0xFFEF9A9A),
                            onTap: () => _tambahTransaksi('ambil'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _TombolAksi(
                            label: 'Kirim',
                            icon: Icons.send_rounded,
                            color: const Color(0xFFFFA726),
                            onTap: _transferTransaksi,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Chart ────────────────────────────────────────────
                if (_chartData.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _MiniChart(chartData: _chartData),
                    ),
                  ),

                // ── Header riwayat ───────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Riwayat (${_filteredTransaksi.length})',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                _filterRange == null ? Icons.calendar_month_outlined : Icons.filter_alt_off_outlined,
                                color: _filterRange == null ? const Color(0xFF4F8EF7) : const Color(0xFFEF5350),
                                size: 22,
                              ),
                              onPressed: () {
                                if (_filterRange != null) {
                                  setState(() => _filterRange = null);
                                } else {
                                  _pilihFilterTanggal();
                                }
                              },
                              tooltip: 'Filter Tanggal',
                            ),
                            const Text('← Geser untuk hapus',
                                style: TextStyle(
                                    color: Color(0xFF6677AA), fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Active Filter Chip ───────────────────────────────
                if (_filterRange != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F8EF7).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF4F8EF7).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Rentang: ${_filterRange!.start.day}/${_filterRange!.start.month}/${_filterRange!.start.year} - ${_filterRange!.end.day}/${_filterRange!.end.month}/${_filterRange!.end.year}',
                              style: const TextStyle(color: Color(0xFF4F8EF7), fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _filterRange = null),
                              child: const Icon(Icons.close_rounded, color: Color(0xFF4F8EF7), size: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // ── List Transaksi ───────────────────────────────────
                if (_filteredTransaksi.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Column(
                        children: [
                          const Icon(Icons.receipt_long_outlined,
                              color: Color(0xFF2A3A50), size: 50),
                          const SizedBox(height: 12),
                          Text(
                              _filterRange == null
                                  ? 'Belum ada transaksi'
                                  : 'Tidak ada transaksi pada tanggal ini',
                              style: GoogleFonts.poppins(
                                  color: const Color(0xFF8899BB),
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final t = _filteredTransaksi[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: ItemTransaksi(
                            transaksi: t,
                            onEdit: () => _editTransaksi(t),
                            onDelete: () => _hapusTransaksi(t.id!),
                          ),
                        );
                      },
                      childCount: _filteredTransaksi.length,
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 30)),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: const Color(0xFF0A1628),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Avatar + nama
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _saldoColor.withValues(alpha: 0.3),
                          _saldoColor.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: _saldoColor.withValues(alpha: 0.3), width: 1),
                    ),
                    child: Center(
                      child: Text(
                        (_penabung?.nama ?? widget.namaPenabung)
                            .isNotEmpty
                            ? (_penabung?.nama ?? widget.namaPenabung)[0]
                                .toUpperCase()
                            : '?',
                        style: TextStyle(
                            color: _saldoColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 26),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _penabung?.nama ?? widget.namaPenabung,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700),
                        ),
                        if ((_penabung?.catatan ?? '').isNotEmpty)
                          Text(
                            _penabung!.catatan,
                            style: const TextStyle(
                                color: Color(0xFF8899BB), fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Kartu saldo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2840),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: _saldoColor.withValues(alpha: 0.25), width: 1),
                ),
                child: Column(
                  children: [
                    Text('Saldo Tabungan',
                        style: const TextStyle(
                            color: Color(0xFF8899BB), fontSize: 12)),
                    const SizedBox(height: 6),
                    Text(
                      formatRupiah(_saldo),
                      style: TextStyle(
                          color: _saldoColor,
                          fontSize: 26,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatItem(
                              label: 'Total Setor',
                              value: formatRupiah(_totalSetor),
                              color: const Color(0xFF66BB6A)),
                        ),
                        Container(
                            width: 1,
                            height: 30,
                            color: const Color(0xFF2A3A50)),
                        Expanded(
                          child: _StatItem(
                              label: 'Total Ambil',
                              value: formatRupiah(_totalAmbil),
                              color: const Color(0xFFEF9A9A)),
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

// ── Mini Bar Chart ─────────────────────────────────────────────────────────

class _MiniChart extends StatelessWidget {
  final List<Map<String, dynamic>> chartData;

  const _MiniChart({required this.chartData});

  @override
  Widget build(BuildContext context) {
    final maxVal = chartData.fold(0.0, (m, d) {
      final s = (d['setor'] as num).toDouble();
      final a = (d['ambil'] as num).toDouble();
      final localMax = s > a ? s : a;
      return m > localMax ? m : localMax;
    });
    if (maxVal == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2840),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A3A50), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tren 6 Bulan',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              Row(
                children: [
                  _LegendDot(color: const Color(0xFF66BB6A), label: 'Setor'),
                  const SizedBox(width: 10),
                  _LegendDot(
                      color: const Color(0xFFEF9A9A), label: 'Ambil'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal * 1.2,
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(
                      color: Color(0xFF2A3A50), strokeWidth: 0.5),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (x, _) {
                        final i = x.toInt();
                        if (i >= chartData.length) {
                          return const SizedBox.shrink();
                        }
                        final bulan =
                            (chartData[i]['bulan'] as String).substring(5);
                        return Text(
                          bulan,
                          style: const TextStyle(
                              color: Color(0xFF8899BB), fontSize: 10),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: chartData.asMap().entries.map((e) {
                  final i = e.key;
                  final d = e.value;
                  final setor = (d['setor'] as num).toDouble();
                  final ambil = (d['ambil'] as num).toDouble();
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: setor,
                        color: const Color(0xFF66BB6A),
                        width: 8,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      BarChartRodData(
                        toY: ambil,
                        color: const Color(0xFFEF9A9A),
                        width: 8,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                    barsSpace: 3,
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(color: Color(0xFF8899BB), fontSize: 10)),
      ],
    );
  }
}

// ── Helper Widgets ──────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style:
                const TextStyle(color: Color(0xFF8899BB), fontSize: 11)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700)),
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
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
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
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
