import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database_helper.dart';
import '../models/transaksi.dart';

class TambahTransaksiScreen extends StatefulWidget {
  final int penabungId;
  final String namaPenabung;
  final String jenisAwal;
  final Transaksi? transaksi; // null = tambah baru, non-null = edit

  const TambahTransaksiScreen({
    super.key,
    required this.penabungId,
    required this.namaPenabung,
    this.jenisAwal = 'setor',
    this.transaksi,
  });

  @override
  State<TambahTransaksiScreen> createState() => _TambahTransaksiScreenState();
}

class _TambahTransaksiScreenState extends State<TambahTransaksiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseHelper.instance;
  late String _jenis;
  late TextEditingController _nominalCtrl;
  late TextEditingController _catatanCtrl;
  late DateTime _tanggal;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final t = widget.transaksi;
    _jenis = t?.jenis ?? widget.jenisAwal;
    _nominalCtrl =
        TextEditingController(text: t != null ? t.nominal.toString() : '');
    _catatanCtrl = TextEditingController(text: t?.catatan ?? '');
    _tanggal = t != null ? DateTime.parse(t.tanggal) : DateTime.now();
  }

  @override
  void dispose() {
    _nominalCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF1565C0),
            surface: Color(0xFF1E2A3A),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _tanggal = picked);
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final t = Transaksi(
      id: widget.transaksi?.id,
      penabungId: widget.penabungId,
      jenis: _jenis,
      nominal:
          int.parse(_nominalCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')),
      catatan: _catatanCtrl.text.trim(),
      tanggal: _tanggal.toIso8601String(),
    );

    if (widget.transaksi == null) {
      await _db.insertTransaksi(t);
    } else {
      await _db.updateTransaksi(t);
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.transaksi != null;
    final isSetor = _jenis == 'setor';
    final colorJenis =
        isSetor ? const Color(0xFF4CAF50) : const Color(0xFFE57373);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit ? 'Edit Transaksi' : 'Transaksi Baru',
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600),
            ),
            Text(
              widget.namaPenabung,
              style: GoogleFonts.poppins(
                  color: const Color(0xFF8899AA), fontSize: 12),
            ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Toggle setor / ambil
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2A3A),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _ToggleBtn(
                    label: 'Setor',
                    sublabel: 'Titipkan uang',
                    icon: Icons.south_rounded,
                    aktif: isSetor,
                    color: const Color(0xFF4CAF50),
                    onTap: () => setState(() => _jenis = 'setor'),
                  ),
                  _ToggleBtn(
                    label: 'Ambil',
                    sublabel: 'Tarik tabungan',
                    icon: Icons.north_rounded,
                    aktif: !isSetor,
                    color: const Color(0xFFE57373),
                    onTap: () => setState(() => _jenis = 'ambil'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Nominal
            const _Label('Nominal (Rp)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nominalCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _inputDecoration(
                hint: 'Contoh: 200000',
                icon: Icons.payments_outlined,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Nominal wajib diisi';
                final n = int.tryParse(v);
                if (n == null || n <= 0) return 'Masukkan nominal yang valid';
                return null;
              },
            ),
            const SizedBox(height: 18),

            // Tanggal
            const _Label('Tanggal'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pilihTanggal,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 15),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2A3A),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: const Color(0xFF2A3A4A), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: Color(0xFF8899AA), size: 18),
                    const SizedBox(width: 10),
                    Text(
                      '${_tanggal.day.toString().padLeft(2, '0')}/${_tanggal.month.toString().padLeft(2, '0')}/${_tanggal.year}',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const Spacer(),
                    const Icon(Icons.edit_calendar_outlined,
                        color: Color(0xFF8899AA), size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Catatan
            const _Label('Catatan (opsional)'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E2A3A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A3A4A)),
              ),
              child: TextFormField(
                controller: _catatanCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Tambahkan keterangan...',
                  hintStyle: TextStyle(color: Color(0xFF8899AA)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(14),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Tombol simpan
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorJenis,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: _loading ? null : _simpan,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Icon(
                        isSetor ? Icons.south_rounded : Icons.north_rounded,
                        size: 20),
                label: Text(
                  isEdit
                      ? 'Simpan Perubahan'
                      : (isSetor ? 'Simpan Setoran' : 'Simpan Pengambilan'),
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
      {required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF8899AA)),
      prefixIcon: Icon(icon, color: const Color(0xFF8899AA), size: 20),
      filled: true,
      fillColor: const Color(0xFF1E2A3A),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2A3A4A))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2A3A4A))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          color: Color(0xFFB0C4D4),
          fontSize: 13,
          fontWeight: FontWeight.w500));
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final bool aktif;
  final Color color;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.aktif,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: aktif ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: aktif ? Border.all(color: color.withValues(alpha: 0.4)) : null,
          ),
          child: Column(
            children: [
              Icon(icon, color: aktif ? color : const Color(0xFF8899AA), size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                    color: aktif ? color : const Color(0xFF8899AA),
                    fontWeight: aktif ? FontWeight.w700 : FontWeight.w400,
                    fontSize: 14),
              ),
              Text(
                sublabel,
                style: TextStyle(
                    color: aktif
                        ? color.withValues(alpha: 0.7)
                        : const Color(0xFF6677AA),
                    fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
