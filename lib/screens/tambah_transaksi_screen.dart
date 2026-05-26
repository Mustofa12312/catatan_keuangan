import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database_helper.dart';
import '../models/transaksi.dart';

class TambahTransaksiScreen extends StatefulWidget {
  final Transaksi? transaksi;
  final String? jenisAwal;
  const TambahTransaksiScreen({super.key, this.transaksi, this.jenisAwal});

  @override
  State<TambahTransaksiScreen> createState() => _TambahTransaksiScreenState();
}

class _TambahTransaksiScreenState extends State<TambahTransaksiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseHelper.instance;
  late String _jenis;
  late TextEditingController _namaCtrl;
  late TextEditingController _nominalCtrl;
  late TextEditingController _catatanCtrl;
  late DateTime _tanggal;
  String? _kategoriTerpilih;
  List<String> _kategoriList = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final t = widget.transaksi;
    _jenis = t?.jenis ?? widget.jenisAwal ?? 'masuk';
    _namaCtrl = TextEditingController(text: t?.nama ?? '');
    _nominalCtrl = TextEditingController(text: t != null ? t.nominal.toString() : '');
    _catatanCtrl = TextEditingController(text: t?.catatan ?? '');
    _tanggal = t != null ? DateTime.parse(t.tanggal) : DateTime.now();
    _kategoriTerpilih = t?.kategori;
    _loadKategori();
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _nominalCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadKategori() async {
    final list = await _db.getKategori();
    setState(() {
      _kategoriList = list;
      if (_kategoriTerpilih == null && list.isNotEmpty) {
        _kategoriTerpilih = list.first;
      }
    });
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
      nama: _namaCtrl.text.trim(),
      jenis: _jenis,
      nominal: int.parse(_nominalCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')),
      kategori: _kategoriTerpilih ?? 'Lainnya',
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
    final colorJenis = _jenis == 'masuk' ? const Color(0xFF4CAF50) : const Color(0xFFE53935);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEdit ? 'Edit Transaksi' : 'Tambah Transaksi',
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Toggle jenis
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: const Color(0xFF1E2A3A), borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  _ToggleBtn(label: 'Pemasukan', icon: Icons.arrow_downward_rounded, aktif: _jenis == 'masuk', color: const Color(0xFF4CAF50), onTap: () => setState(() => _jenis = 'masuk')),
                  _ToggleBtn(label: 'Pengeluaran', icon: Icons.arrow_upward_rounded, aktif: _jenis == 'keluar', color: const Color(0xFFE53935), onTap: () => setState(() => _jenis = 'keluar')),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const _Label('Nama'),
            const SizedBox(height: 8),
            _InputField(
              controller: _namaCtrl,
              hint: _jenis == 'masuk' ? 'Nama pengirim' : 'Nama penerima',
              icon: Icons.person_outline_rounded,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            const _Label('Nominal (Rp)'),
            const SizedBox(height: 8),
            _InputField(
              controller: _nominalCtrl,
              hint: 'Contoh: 500000',
              icon: Icons.payments_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Nominal wajib diisi';
                final n = int.tryParse(v);
                if (n == null || n <= 0) return 'Masukkan nominal valid';
                return null;
              },
            ),
            const SizedBox(height: 16),
            const _Label('Kategori'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF1E2A3A), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF2A3A4A))),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _kategoriTerpilih,
                  dropdownColor: const Color(0xFF1E2A3A),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  icon: const Icon(Icons.expand_more_rounded, color: Color(0xFF8899AA)),
                  isExpanded: true,
                  hint: const Text('Pilih kategori', style: TextStyle(color: Color(0xFF8899AA))),
                  items: _kategoriList.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                  onChanged: (v) => setState(() => _kategoriTerpilih = v),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const _Label('Tanggal'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pilihTanggal,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(color: const Color(0xFF1E2A3A), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF2A3A4A))),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, color: Color(0xFF8899AA), size: 18),
                    const SizedBox(width: 10),
                    Text(
                      '${_tanggal.day.toString().padLeft(2, '0')}/${_tanggal.month.toString().padLeft(2, '0')}/${_tanggal.year}',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const Spacer(),
                    const Icon(Icons.edit_calendar_outlined, color: Color(0xFF8899AA), size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const _Label('Catatan (opsional)'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: const Color(0xFF1E2A3A), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF2A3A4A))),
              child: TextFormField(
                controller: _catatanCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Tambahkan catatan...',
                  hintStyle: TextStyle(color: Color(0xFF8899AA)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(14),
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: colorJenis, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                onPressed: _loading ? null : _simpan,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(isEdit ? Icons.save_outlined : Icons.add_circle_outline_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            isEdit ? 'Simpan Perubahan' : 'Simpan Transaksi',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(color: Color(0xFFB0C4D4), fontSize: 13, fontWeight: FontWeight.w500));
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  const _InputField({required this.controller, required this.hint, required this.icon, this.keyboardType, this.inputFormatters, this.validator});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF8899AA)),
        prefixIcon: Icon(icon, color: const Color(0xFF8899AA), size: 20),
        filled: true,
        fillColor: const Color(0xFF1E2A3A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2A3A4A))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2A3A4A))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool aktif;
  final Color color;
  final VoidCallback onTap;
  const _ToggleBtn({required this.label, required this.icon, required this.aktif, required this.color, required this.onTap});

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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: aktif ? color : const Color(0xFF8899AA), size: 18),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: aktif ? color : const Color(0xFF8899AA), fontWeight: aktif ? FontWeight.w600 : FontWeight.w400, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
