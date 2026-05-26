import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database_helper.dart';
import '../utils/format_rupiah.dart';
import '../widgets/kartu_penabung.dart';
import 'detail_penabung_screen.dart';
import 'tambah_penabung_screen.dart';
import 'tambah_transaksi_screen.dart';
import 'pengaturan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final _db = DatabaseHelper.instance;
  List<Map<String, dynamic>> _penabungList = [];
  Map<String, int> _summary = {'setor': 0, 'ambil': 0, 'total': 0};
  bool _loading = true;
  String _sortBy = 'saldo'; // 'saldo' | 'nama' | 'terbaru'
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _loadData();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final penabung =
        await _db.getPenabungDenganSaldoSorted(sortBy: _sortBy);
    final summary = await _db.getSummary();
    if (mounted) {
      setState(() {
        _penabungList = penabung;
        _summary = summary;
        _loading = false;
      });
      _animCtrl.forward(from: 0);
    }
  }

  Future<void> _tambahPenabung() async {
    final result = await Navigator.push(
      context,
      _slideRoute(const TambahPenabungScreen()),
    );
    if (result == true) _loadData();
  }

  Future<void> _buka(Map<String, dynamic> item) async {
    await Navigator.push(
      context,
      _slideRoute(DetailPenabungScreen(
        penabungId: item['id'] as int,
        namaPenabung: item['nama'] as String,
      )),
    );
    _loadData();
  }

  Future<void> _transaksi(Map<String, dynamic> item, String jenis) async {
    final result = await Navigator.push(
      context,
      _slideRoute(TambahTransaksiScreen(
        penabungId: item['id'] as int,
        namaPenabung: item['nama'] as String,
        saldoSaatIni: (item['saldo'] as num).toInt(),
        jenisAwal: jenis,
      )),
    );
    if (result == true) _loadData();
  }

  PageRoute _slideRoute(Widget page) => PageRouteBuilder(
        pageBuilder: (context3, anim, widget2) => page,
        transitionsBuilder: (ctx2, anim2, secAnim, child) => SlideTransition(
          position:
              Tween(begin: const Offset(1, 0), end: Offset.zero).animate(
            CurvedAnimation(parent: anim2, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 300),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFF4F8EF7),
          backgroundColor: const Color(0xFF1A2840),
          child: CustomScrollView(
            slivers: [
              // ── Header ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAppBar(),
                      const SizedBox(height: 20),
                      _KartuTotalPremium(
                        total: _summary['total'] ?? 0,
                        totalSetor: _summary['setor'] ?? 0,
                        totalAmbil: _summary['ambil'] ?? 0,
                        jumlahPenabung: _penabungList.length,
                      ),
                      const SizedBox(height: 24),
                      _buildListHeader(),
                      const SizedBox(height: 4),
                      _buildSortChips(),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // ── List Penabung ────────────────────────────────────
              if (_loading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF4F8EF7))),
                  ),
                )
              else if (_penabungList.isEmpty)
                SliverToBoxAdapter(child: _buildEmptyState())
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final item = _penabungList[i];
                      return AnimatedBuilder(
                        animation: _animCtrl,
                        builder: (_, child) {
                          final delay = (i * 0.1).clamp(0.0, 0.8);
                          final start = delay;
                          final end = (delay + 0.4).clamp(0.0, 1.0);
                          final anim = CurvedAnimation(
                            parent: _animCtrl,
                            curve: Interval(start, end,
                                curve: Curves.easeOutBack),
                          );
                          return FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween(
                                begin: const Offset(0, 0.3),
                                end: Offset.zero,
                              ).animate(anim),
                              child: child,
                            ),
                          );
                        },
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          child: KartuPenabung(
                            item: item,
                            onTap: () => _buka(item),
                            onSetor: () => _transaksi(item, 'setor'),
                            onAmbil: () => _transaksi(item, 'ambil'),
                          ),
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

  Widget _buildAppBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tabungan Titipan',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700)),
            Text('Kelola titipan tabungan',
                style: GoogleFonts.poppins(
                    color: const Color(0xFF8899BB), fontSize: 12)),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () async {
                final reload = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PengaturanScreen()),
                );
                if (reload == true) _loadData();
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2840),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF2A3A50)),
                ),
                child: const Icon(Icons.settings_outlined,
                    color: Color(0xFF8899BB), size: 20),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _tambahPenabung,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F8EF7), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF4F8EF7).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: const Icon(Icons.person_add_alt_1_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildListHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Daftar Penabung (${_penabungList.length})',
          style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildSortChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _SortChip(
              label: 'Saldo Tertinggi',
              icon: Icons.arrow_downward_rounded,
              aktif: _sortBy == 'saldo',
              onTap: () {
                setState(() => _sortBy = 'saldo');
                _loadData();
              }),
          const SizedBox(width: 8),
          _SortChip(
              label: 'Nama A-Z',
              icon: Icons.sort_by_alpha_rounded,
              aktif: _sortBy == 'nama',
              onTap: () {
                setState(() => _sortBy = 'nama');
                _loadData();
              }),
          const SizedBox(width: 8),
          _SortChip(
              label: 'Terbaru',
              icon: Icons.access_time_rounded,
              aktif: _sortBy == 'terbaru',
              onTap: () {
                setState(() => _sortBy = 'terbaru');
                _loadData();
              }),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF1A2840),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(Icons.people_outline_rounded,
                color: Color(0xFF4F8EF7), size: 48),
          ),
          const SizedBox(height: 20),
          Text('Belum ada penabung',
              style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Tambahkan orang yang menitipkan\ntabungan kepada Anda',
              style: GoogleFonts.poppins(
                  color: const Color(0xFF8899BB), fontSize: 13),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F8EF7),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _tambahPenabung,
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
            label: Text('Tambah Penabung Pertama',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Kartu Total Premium ────────────────────────────────────────────────────

class _KartuTotalPremium extends StatelessWidget {
  final int total;
  final int totalSetor;
  final int totalAmbil;
  final int jumlahPenabung;

  const _KartuTotalPremium({
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
          colors: [Color(0xFF1E3A5F), Color(0xFF0F2040)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: const Color(0xFF4F8EF7).withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F8EF7).withValues(alpha: 0.15),
            blurRadius: 24,
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
                  color: const Color(0xFF4F8EF7).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    color: Color(0xFF4F8EF7), size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Uang Dipegang',
                      style: TextStyle(
                          color: Color(0xFF8899BB), fontSize: 11)),
                  Text('dari $jumlahPenabung penabung',
                      style: const TextStyle(
                          color: Color(0xFF6677AA), fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            formatRupiah(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          // Progress bar setor vs ambil
          if (totalSetor > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Diterima',
                    style: TextStyle(
                        color: Color(0xFF8899BB), fontSize: 10)),
                const Text('Dikembalikan',
                    style: TextStyle(
                        color: Color(0xFF8899BB), fontSize: 10)),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: totalSetor > 0
                    ? (totalSetor - totalAmbil) / totalSetor
                    : 0,
                backgroundColor: const Color(0xFFE57373).withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF66BB6A)),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: 'Masuk',
                  value: formatRupiah(totalSetor),
                  icon: Icons.south_rounded,
                  color: const Color(0xFF66BB6A),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatBox(
                  label: 'Keluar',
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

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: color.withValues(alpha: 0.7), fontSize: 10)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool aktif;
  final VoidCallback onTap;

  const _SortChip(
      {required this.label,
      required this.icon,
      required this.aktif,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: aktif
              ? const Color(0xFF4F8EF7).withValues(alpha: 0.15)
              : const Color(0xFF1A2840),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: aktif
                ? const Color(0xFF4F8EF7).withValues(alpha: 0.6)
                : const Color(0xFF2A3A50),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: aktif
                    ? const Color(0xFF4F8EF7)
                    : const Color(0xFF8899BB),
                size: 13),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: aktif
                    ? const Color(0xFF4F8EF7)
                    : const Color(0xFF8899BB),
                fontSize: 12,
                fontWeight:
                    aktif ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
