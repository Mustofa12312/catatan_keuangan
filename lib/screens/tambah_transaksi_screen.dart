import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database_helper.dart';
import '../models/transaksi.dart';
import '../utils/rupiah_formatter.dart';
import '../utils/format_rupiah.dart';

class TambahTransaksiScreen extends StatefulWidget {
  final int penabungId;
  final String namaPenabung;
  final String jenisAwal;
  final int saldoSaatIni;
  final Transaksi? transaksi;

  const TambahTransaksiScreen({
    super.key,
    required this.penabungId,
    required this.namaPenabung,
    this.jenisAwal = 'setor',
    this.saldoSaatIni = 0,
    this.transaksi,
  });

  @override
  State<TambahTransaksiScreen> createState() =>
      _TambahTransaksiScreenState();
}

class _TambahTransaksiScreenState
    extends State<TambahTransaksiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseHelper.instance;
  late String _jenis;
  late TextEditingController _nominalCtrl;
  late TextEditingController _catatanCtrl;
  late DateTime _tanggal;
  bool _loading = false;
  bool _melebihiSaldo = false;

  @override
  void initState() {
    super.initState();
    final t = widget.transaksi;
    _jenis = t?.jenis ?? widget.jenisAwal;
    // Format nominal ke ribuan jika edit
    final nominalStr = t != null
        ? RupiahInputFormatter()
            .formatEditUpdate(
              const TextEditingValue(text: ''),
              TextEditingValue(text: t.nominal.toString()),
            )
            .text
        : '';
    _nominalCtrl = TextEditingController(text: nominalStr);
    _catatanCtrl = TextEditingController(text: t?.catatan ?? '');
    _tanggal =
        t != null ? DateTime.parse(t.tanggal) : DateTime.now();

    _nominalCtrl.addListener(_cekSaldo);
  }

  @override
  void dispose() {
    _nominalCtrl.removeListener(_cekSaldo);
    _nominalCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  void _cekSaldo() {
    if (_jenis == 'ambil') {
      final nominal = RupiahInputFormatter.toInt(_nominalCtrl.text);
      setState(() => _melebihiSaldo = nominal > widget.saldoSaatIni);
    }
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
            primary: Color(0xFF4F8EF7),
            surface: Color(0xFF1A2840),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _tanggal = picked);
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;

    final nominal = RupiahInputFormatter.toInt(_nominalCtrl.text);

    // Validasi saldo ambil
    if (_jenis == 'ambil' && nominal > widget.saldoSaatIni) {
      final lanjut = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1A2840),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFFFA726), size: 22),
              SizedBox(width: 8),
              Text('Saldo Tidak Cukup',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16)),
            ],
          ),
          content: Text(
            'Nominal ambil (${formatRupiah(nominal)}) melebihi saldo tabungan (${formatRupiah(widget.saldoSaatIni)}).\n\nTetap simpan?',
            style: const TextStyle(
                color: Color(0xFF8899BB), fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal',
                  style: TextStyle(color: Color(0xFF8899BB))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA726),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Tetap Simpan',
                  style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      );
      if (lanjut != true) return;
    }

    setState(() => _loading = true);
    final t = Transaksi(
      id: widget.transaksi?.id,
      penabungId: widget.penabungId,
      jenis: _jenis,
      nominal: nominal,
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
    final colorJenis = isSetor
        ? const Color(0xFF66BB6A)
        : const Color(0xFFEF5350);

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1628),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit ? 'Edit Transaksi' : 'Transaksi Baru',
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
            Text(widget.namaPenabung,
                style: GoogleFonts.poppins(
                    color: const Color(0xFF8899BB), fontSize: 12)),
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
                color: const Color(0xFF1A2840),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _ToggleBtn(
                    label: 'Setor',
                    sublabel: 'Titipkan uang',
                    icon: Icons.south_rounded,
                    aktif: isSetor,
                    color: const Color(0xFF66BB6A),
                    onTap: () {
                      setState(() {
                        _jenis = 'setor';
                        _melebihiSaldo = false;
                      });
                    },
                  ),
                  _ToggleBtn(
                    label: 'Ambil',
                    sublabel: 'Tarik tabungan',
                    icon: Icons.north_rounded,
                    aktif: !isSetor,
                    color: const Color(0xFFEF5350),
                    onTap: () {
                      setState(() => _jenis = 'ambil');
                      _cekSaldo();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Info saldo saat ini (saat ambil)
            if (!isSetor) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _melebihiSaldo
                      ? const Color(0xFFEF5350).withValues(alpha: 0.08)
                      : const Color(0xFF66BB6A).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _melebihiSaldo
                        ? const Color(0xFFEF5350).withValues(alpha: 0.3)
                        : const Color(0xFF66BB6A).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _melebihiSaldo
                          ? Icons.warning_amber_rounded
                          : Icons.account_balance_wallet_outlined,
                      color: _melebihiSaldo
                          ? const Color(0xFFFFA726)
                          : const Color(0xFF66BB6A),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _melebihiSaldo
                          ? 'Melebihi saldo! Saldo: ${formatRupiah(widget.saldoSaatIni)}'
                          : 'Saldo tersedia: ${formatRupiah(widget.saldoSaatIni)}',
                      style: TextStyle(
                        color: _melebihiSaldo
                            ? const Color(0xFFFFA726)
                            : const Color(0xFF66BB6A),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Nominal
            const _Label('Nominal (Rp)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nominalCtrl,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
              keyboardType: TextInputType.number,
              inputFormatters: [RupiahInputFormatter()],
              decoration: _inputDecor(
                hint: '0',
                prefix: const Text('Rp ',
                    style: TextStyle(
                        color: Color(0xFF8899BB),
                        fontSize: 16,
                        fontWeight: FontWeight.w500)),
                icon: null,
              ).copyWith(
                prefixIcon: null,
                prefix: const Text('Rp ',
                    style: TextStyle(
                        color: Color(0xFF8899BB),
                        fontSize: 16,
                        fontWeight: FontWeight.w500)),
                suffixIcon: _melebihiSaldo
                    ? const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFFFA726))
                    : null,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _melebihiSaldo
                        ? const Color(0xFFFFA726)
                        : colorJenis,
                    width: 1.5,
                  ),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Nominal wajib diisi';
                final n = RupiahInputFormatter.toInt(v);
                if (n <= 0) return 'Masukkan nominal yang valid';
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
                  color: const Color(0xFF1A2840),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A3A50)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: Color(0xFF8899BB), size: 16),
                    const SizedBox(width: 10),
                    Text(
                      '${_tanggal.day.toString().padLeft(2, '0')}/${_tanggal.month.toString().padLeft(2, '0')}/${_tanggal.year}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14),
                    ),
                    const Spacer(),
                    const Icon(Icons.edit_calendar_outlined,
                        color: Color(0xFF4F8EF7), size: 16),
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
                color: const Color(0xFF1A2840),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A3A50)),
              ),
              child: TextFormField(
                controller: _catatanCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Keterangan tambahan...',
                  hintStyle: TextStyle(color: Color(0xFF8899BB)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(14),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Tombol simpan
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorJenis,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: _loading ? null : _simpan,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isSetor
                                ? Icons.south_rounded
                                : Icons.north_rounded,
                            size: 20),
                          const SizedBox(width: 8),
                          Text(
                            isEdit
                                ? 'Simpan Perubahan'
                                : (isSetor
                                    ? 'Simpan Setoran'
                                    : 'Simpan Penarikan'),
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Colors.white),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecor(
      {required String hint,
      required IconData? icon,
      Widget? prefix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF8899BB)),
      prefixIcon: icon != null
          ? Icon(icon, color: const Color(0xFF8899BB), size: 20)
          : null,
      prefix: prefix,
      filled: true,
      fillColor: const Color(0xFF1A2840),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2A3A50))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2A3A50))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF4F8EF7), width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
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
            color: aktif
                ? color.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: aktif
                ? Border.all(color: color.withValues(alpha: 0.4))
                : null,
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: aktif ? color : const Color(0xFF8899BB),
                  size: 20),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      color: aktif ? color : const Color(0xFF8899BB),
                      fontWeight: aktif
                          ? FontWeight.w700
                          : FontWeight.w400,
                      fontSize: 14)),
              Text(sublabel,
                  style: TextStyle(
                      color: aktif
                          ? color.withValues(alpha: 0.7)
                          : const Color(0xFF6677AA),
                      fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
