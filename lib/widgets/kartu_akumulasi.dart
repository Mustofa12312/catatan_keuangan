import 'package:flutter/material.dart';
import '../../utils/format_rupiah.dart';

class KartuAkumulasi extends StatelessWidget {
  final String nama;
  final int totalMasuk;
  final int totalKeluar;
  final int net;
  final VoidCallback? onTap;

  const KartuAkumulasi({
    super.key,
    required this.nama,
    required this.totalMasuk,
    required this.totalKeluar,
    required this.net,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPositif = net >= 0;
    final netColor =
        isPositif ? const Color(0xFF4CAF50) : const Color(0xFFE53935);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2A3A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: netColor.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    netColor.withValues(alpha: 0.3),
                    netColor.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  nama.isNotEmpty ? nama[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: netColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nama,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _MiniInfo(
                        label: 'Masuk',
                        value: formatRupiah(totalMasuk),
                        color: const Color(0xFF4CAF50),
                      ),
                      const SizedBox(width: 12),
                      _MiniInfo(
                        label: 'Keluar',
                        value: formatRupiah(totalKeluar),
                        color: const Color(0xFFE53935),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isPositif ? '+' : ''}${formatRupiah(net)}',
                  style: TextStyle(
                    color: netColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Net',
                  style: const TextStyle(
                    color: Color(0xFF8899AA),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniInfo({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(color: Color(0xFF8899AA), fontSize: 11),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
