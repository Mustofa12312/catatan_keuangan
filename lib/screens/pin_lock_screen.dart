import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PinLockMode { validate, setup, disable }

class PinLockScreen extends StatefulWidget {
  final PinLockMode mode;
  final Function(bool)? onSuccess;

  const PinLockScreen({
    super.key,
    required this.mode,
    this.onSuccess,
  });

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String _pin = '';
  String _firstPin = ''; // Untuk konfirmasi saat setup
  String _message = '';
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    _initMessage();
  }

  void _initMessage() {
    if (widget.mode == PinLockMode.validate) {
      _message = 'Masukkan PIN untuk Masuk';
    } else if (widget.mode == PinLockMode.setup) {
      _message = 'Buat PIN 4-Digit Baru';
    } else {
      _message = 'Masukkan PIN Saat Ini untuk Menonaktifkan';
    }
  }

  Future<void> _handleKeyPress(String value) async {
    if (_pin.length >= 4) return;

    setState(() {
      _pin += value;
    });

    if (_pin.length == 4) {
      await Future.delayed(const Duration(milliseconds: 200));
      _processPin();
    }
  }

  void _handleDelete() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  Future<void> _processPin() async {
    final prefs = await SharedPreferences.getInstance();

    if (widget.mode == PinLockMode.validate) {
      final savedPin = prefs.getString('app_pin') ?? '';
      if (_pin == savedPin) {
        if (widget.onSuccess != null) {
          widget.onSuccess!(true);
        } else {
          Navigator.pop(context, true);
        }
      } else {
        setState(() {
          _pin = '';
          _message = 'PIN Salah! Coba Lagi';
        });
      }
    } else if (widget.mode == PinLockMode.setup) {
      if (!_isConfirming) {
        // Simpan pin pertama, minta konfirmasi
        setState(() {
          _firstPin = _pin;
          _pin = '';
          _isConfirming = true;
          _message = 'Konfirmasi PIN Anda';
        });
      } else {
        if (_pin == _firstPin) {
          await prefs.setString('app_pin', _pin);
          await prefs.setBool('app_lock_enabled', true);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PIN Keamanan Berhasil Diaktifkan!'), backgroundColor: Color(0xFF66BB6A)),
            );
            Navigator.pop(context, true);
          }
        } else {
          setState(() {
            _pin = '';
            _firstPin = '';
            _isConfirming = false;
            _message = 'PIN tidak cocok! Buat ulang PIN';
          });
        }
      }
    } else if (widget.mode == PinLockMode.disable) {
      final savedPin = prefs.getString('app_pin') ?? '';
      if (_pin == savedPin) {
        await prefs.setBool('app_lock_enabled', false);
        await prefs.remove('app_pin');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PIN Keamanan Dinonaktifkan'), backgroundColor: Color(0xFFEF5350)),
          );
          Navigator.pop(context, true);
        }
      } else {
        setState(() {
          _pin = '';
          _message = 'PIN Salah! Menonaktifkan Batal';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Layar penuh, tidak ada tombol back jika mode validate
    final isValidate = widget.mode == PinLockMode.validate;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: isValidate
          ? null
          : AppBar(
              backgroundColor: const Color(0xFF0A1628),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context, false),
              ),
            ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // Logo / Ikon Kunci
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A5F).withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF4F8EF7).withValues(alpha: 0.15), width: 2),
              ),
              child: const Icon(Icons.lock_rounded, color: Color(0xFF4F8EF7), size: 44),
            ),
            const SizedBox(height: 30),

            // Judul Aplikasi
            Text(
              'Keamanan Aplikasi',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Pesan Panduan
            Text(
              _message,
              style: GoogleFonts.poppins(color: const Color(0xFF8899BB), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Titik Indikator PIN (4 dot)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final filled = _pin.length > index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: filled ? const Color(0xFF4F8EF7) : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: filled ? const Color(0xFF4F8EF7) : const Color(0xFF4A5A6A),
                      width: 2,
                    ),
                    boxShadow: filled
                        ? [BoxShadow(color: const Color(0xFF4F8EF7).withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 1)]
                        : [],
                  ),
                );
              }),
            ),
            const Spacer(),

            // Keyboard Angka (Numpad)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['1', '2', '3'].map((n) => _buildNumButton(n)).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['4', '5', '6'].map((n) => _buildNumButton(n)).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['7', '8', '9'].map((n) => _buildNumButton(n)).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 70, height: 70), // Spacer kosong di kiri bawah
                      _buildNumButton('0'),
                      _buildDeleteButton(),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNumButton(String num) {
    return GestureDetector(
      onTap: () => _handleKeyPress(num),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFF1A2840),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF2A3A50).withValues(alpha: 0.5)),
        ),
        alignment: Alignment.center,
        child: Text(
          num,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return GestureDetector(
      onTap: _handleDelete,
      child: Container(
        width: 70,
        height: 70,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.backspace_outlined, color: Color(0xFF8899BB), size: 24),
      ),
    );
  }
}
