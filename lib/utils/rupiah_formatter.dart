import 'package:flutter/services.dart';

/// TextInputFormatter yang auto-format angka jadi separator ribuan
/// Contoh: 1500000 → 1.500.000
class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Hapus semua non-digit
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return newValue.copyWith(text: '');

    // Format dengan titik sebagai separator ribuan
    final formatted = _formatRibuan(digits);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatRibuan(String digits) {
    final buffer = StringBuffer();
    final len = digits.length;
    for (int i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// Ambil nilai integer dari string terformat
  static int toInt(String formatted) {
    return int.tryParse(formatted.replaceAll('.', '')) ?? 0;
  }
}
