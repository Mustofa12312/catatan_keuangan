import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database_helper.dart';
import '../models/penabung.dart';

class TambahPenabungScreen extends StatefulWidget {
  final Penabung? penabung; // null = tambah baru

  const TambahPenabungScreen({super.key, this.penabung});

  @override
  State<TambahPenabungScreen> createState() => _TambahPenabungScreenState();
}

class _TambahPenabungScreenState extends State<TambahPenabungScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseHelper.instance;
  late TextEditingController _namaCtrl;
  late TextEditingController _catatanCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _namaCtrl = TextEditingController(text: widget.penabung?.nama ?? '');
    _catatanCtrl = TextEditingController(text: widget.penabung?.catatan ?? '');
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final p = Penabung(
      id: widget.penabung?.id,
      nama: _namaCtrl.text.trim(),
      catatan: _catatanCtrl.text.trim(),
      dibuatPada: widget.penabung?.dibuatPada ?? DateTime.now().toIso8601String(),
    );

    if (widget.penabung == null) {
      await _db.insertPenabung(p);
    } else {
      await _db.updatePenabung(p);
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.penabung != null;
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
          isEdit ? 'Edit Penabung' : 'Tambah Penabung',
          style: GoogleFonts.poppins(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 8),
            // Avatar preview
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Center(
                  child: ValueListenableBuilder(
                    valueListenable: _namaCtrl,
                    builder: (context2, v, child2) => Text(
                      (v.text.isNotEmpty ? v.text[0] : '?').toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Nama
            const _Label('Nama Penabung'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _namaCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              decoration: _inputDecoration(
                  hint: 'Contoh: Saudara A', icon: Icons.person_outline_rounded),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 18),

            // Catatan
            const _Label('Catatan (opsional)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _catatanCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              maxLines: 3,
              decoration: _inputDecoration(
                      hint: 'Nomor HP, hubungan, dll.', icon: Icons.notes_rounded)
                  .copyWith(contentPadding: const EdgeInsets.all(14)),
            ),
            const SizedBox(height: 32),

            // Simpan
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
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
                    : Icon(isEdit ? Icons.save_outlined : Icons.person_add_alt_1_rounded,
                        size: 20),
                label: Text(
                  isEdit ? 'Simpan Perubahan' : 'Tambah Penabung',
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

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
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
          color: Color(0xFFB0C4D4), fontSize: 13, fontWeight: FontWeight.w500));
}
