import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database_helper.dart';
import '../models/penabung.dart';
import '../models/transaksi.dart';
import '../utils/format_rupiah.dart';

class TransferScreen extends StatefulWidget {
  final int senderId;
  final String senderName;
  final int senderSaldo;

  const TransferScreen({
    super.key,
    required this.senderId,
    required this.senderName,
    required this.senderSaldo,
  });

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _db = DatabaseHelper.instance;
  final _nominalCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();
  final _namaLuarCtrl = TextEditingController();

  List<Penabung> _penabungList = [];
  Penabung? _selectedTarget;
  bool _isOrangLuar = false;
  bool _loading = false;
  String _rawNominal = '';
  DateTime _tanggal = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadPenabung();
  }

  Future<void> _loadPenabung() async {
    final list = await _db.getAllPenabung();
    setState(() {
      // Exclude sender
      _penabungList = list.where((p) => p.id != widget.senderId).toList();
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
            primary: Color(0xFF4F8EF7),
            surface: Color(0xFF1A2840),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _tanggal = picked);
  }

  void _onNominalChanged(String value) {
    final numericString = value.replaceAll(RegExp(r'[^0-9]'), '');
    setState(() {
      _rawNominal = numericString;
    });

    if (numericString.isEmpty) {
      _nominalCtrl.value = const TextEditingValue(text: '');
      return;
    }

    final val = int.parse(numericString);
    final formatted = formatRupiah(val);

    _nominalCtrl.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  Future<void> _simpan() async {
    if (_rawNominal.isEmpty) {
      _showSnack('Masukkan nominal!');
      return;
    }
    
    final nominal = int.parse(_rawNominal);
    if (nominal <= 0) {
      _showSnack('Nominal harus lebih dari 0');
      return;
    }

    if (nominal > widget.senderSaldo) {
      _showSnack('Saldo tidak cukup! Saldo saat ini: ${formatRupiah(widget.senderSaldo)}');
      return;
    }

    if (_isOrangLuar && _namaLuarCtrl.text.trim().isEmpty) {
      _showSnack('Masukkan nama orang yang meminjam');
      return;
    }

    if (!_isOrangLuar && _selectedTarget == null) {
      _showSnack('Pilih penabung yang meminjam');
      return;
    }

    setState(() => _loading = true);

    try {
      final tgl = _tanggal.toIso8601String();
      final catatan = _catatanCtrl.text.trim();
      
      if (_isOrangLuar) {
        final namaLuar = _namaLuarCtrl.text.trim();
        final textCatatan = catatan.isNotEmpty ? ' | $catatan' : '';
        await _db.insertTransaksi(Transaksi(
          penabungId: widget.senderId,
          jenis: 'ambil',
          nominal: nominal,
          catatan: 'Dihutangkan ke: $namaLuar$textCatatan',
          tanggal: tgl,
        ));
      } else {
        final textCatatan = catatan.isNotEmpty ? ' | $catatan' : '';
        // 1. Ambil dari sender
        await _db.insertTransaksi(Transaksi(
          penabungId: widget.senderId,
          jenis: 'ambil',
          nominal: nominal,
          catatan: 'Dihutangkan ke: ${_selectedTarget!.nama}$textCatatan',
          tanggal: tgl,
        ));
        
        // 2. Setor ke target
        await _db.insertTransaksi(Transaksi(
          penabungId: _selectedTarget!.id!,
          jenis: 'setor',
          nominal: nominal,
          catatan: 'Hutang dari: ${widget.senderName}$textCatatan',
          tanggal: tgl,
        ));
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnack('Terjadi kesalahan: $e');
      setState(() => _loading = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFFEF5350)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1628),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Pinjamkan / Transfer',
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saldo Pengirim Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2840),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF4F8EF7).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Saldo Tersedia', style: TextStyle(color: Color(0xFF8899BB), fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(formatRupiah(widget.senderSaldo),
                      style: const TextStyle(color: Color(0xFF4F8EF7), fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('Tujuan Pinjaman / Transfer',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            
            // Toggle Tujuan
            Row(
              children: [
                Expanded(
                  child: _OptionButton(
                    label: 'Sesama Penabung',
                    aktif: !_isOrangLuar,
                    onTap: () => setState(() => _isOrangLuar = false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _OptionButton(
                    label: 'Orang Luar',
                    aktif: _isOrangLuar,
                    onTap: () => setState(() => _isOrangLuar = true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Input Tujuan
            if (_isOrangLuar)
              _buildInput(
                controller: _namaLuarCtrl,
                label: 'Nama Orang Luar',
                hint: 'Masukkan nama peminjam',
                icon: Icons.person_outline_rounded,
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2840),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Penabung>(
                    value: _selectedTarget,
                    hint: const Text('Pilih Penabung', style: TextStyle(color: Color(0xFF8899BB))),
                    isExpanded: true,
                    dropdownColor: const Color(0xFF2A3A50),
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF8899BB)),
                    items: _penabungList.map((p) {
                      return DropdownMenuItem<Penabung>(
                        value: p,
                        child: Text(p.nama),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedTarget = val);
                    },
                  ),
                ),
              ),

             const SizedBox(height: 24),
             _buildInput(
               controller: _nominalCtrl,
               label: 'Nominal',
               hint: 'Rp 0',
               icon: Icons.attach_money_rounded,
               isNumber: true,
               onChanged: _onNominalChanged,
             ),
             const SizedBox(height: 24),
             const Text('Tanggal', style: TextStyle(color: Color(0xFF8899BB), fontSize: 13, fontWeight: FontWeight.w500)),
             const SizedBox(height: 8),
             GestureDetector(
               onTap: _pilihTanggal,
               child: Container(
                 padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                 decoration: BoxDecoration(
                   color: const Color(0xFF1A2840),
                   borderRadius: BorderRadius.circular(16),
                   border: Border.all(color: const Color(0xFF2A3A50).withValues(alpha: 0.5)),
                 ),
                 child: Row(
                   children: [
                     const Icon(Icons.calendar_today_outlined, color: Color(0xFF8899BB), size: 18),
                     const SizedBox(width: 10),
                     Text(
                       '${_tanggal.day.toString().padLeft(2, '0')}/${_tanggal.month.toString().padLeft(2, '0')}/${_tanggal.year}',
                       style: const TextStyle(color: Colors.white, fontSize: 14),
                     ),
                     const Spacer(),
                     const Icon(Icons.edit_calendar_outlined, color: Color(0xFF4F8EF7), size: 16),
                   ],
                 ),
               ),
             ),
             const SizedBox(height: 24),
             _buildInput(
               controller: _catatanCtrl,
               label: 'Catatan (Opsional)',
               hint: 'Tulis alasan pinjaman',
               icon: Icons.notes_rounded,
             ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F8EF7),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _loading ? null : _simpan,
                child: _loading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Kirim / Pinjamkan',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isNumber = false,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF8899BB), fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF4A5A6A)),
            prefixIcon: Icon(icon, color: const Color(0xFF8899BB), size: 20),
            filled: true,
            fillColor: const Color(0xFF1A2840),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}

class _OptionButton extends StatelessWidget {
  final String label;
  final bool aktif;
  final VoidCallback onTap;

  const _OptionButton({required this.label, required this.aktif, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: aktif ? const Color(0xFF4F8EF7).withValues(alpha: 0.15) : const Color(0xFF1A2840),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: aktif ? const Color(0xFF4F8EF7) : Colors.transparent),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: aktif ? const Color(0xFF4F8EF7) : const Color(0xFF8899BB),
            fontWeight: aktif ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
