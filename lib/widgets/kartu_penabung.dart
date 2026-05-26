import 'package:flutter/material.dart';
import '../utils/format_rupiah.dart';

class KartuPenabung extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  final VoidCallback onSetor;
  final VoidCallback onAmbil;

  const KartuPenabung({
    super.key,
    required this.item,
    required this.onTap,
    required this.onSetor,
    required this.onAmbil,
  });

  @override
  Widget build(BuildContext context) {
    final nama = item['nama'] as String;
    final catatan = (item['catatan'] as String?) ?? '';
    final saldo = (item['saldo'] as num).toInt();
    final totalSetor = (item['total_setor'] as num).toInt();
    final totalAmbil = (item['total_ambil'] as num).toInt();
    final jumlahTrx = (item['jumlah_transaksi'] as num? ?? 0).toInt();

    final saldoColor = saldo > 0
        ? const Color(0xFF66BB6A)
        : (saldo == 0 ? const Color(0xFF8899BB) : const Color(0xFFEF5350));
    final persentase =
        totalSetor > 0 ? (saldo / totalSetor).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2840),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: saldoColor.withValues(alpha: 0.15), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Top row ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 10),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          saldoColor.withValues(alpha: 0.25),
                          saldoColor.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        nama.isNotEmpty ? nama[0].toUpperCase() : '?',
                        style: TextStyle(
                            color: saldoColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nama,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                        const SizedBox(height: 2),
                        if (catatan.isNotEmpty)
                          Text(catatan,
                              style: const TextStyle(
                                  color: Color(0xFF8899BB), fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)
                        else
                          Text('$jumlahTrx transaksi',
                              style: const TextStyle(
                                  color: Color(0xFF6677AA), fontSize: 11)),
                      ],
                    ),
                  ),
                  // Saldo
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(formatRupiah(saldo),
                          style: TextStyle(
                              color: saldoColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 14)),
                      const Text('saldo',
                          style: TextStyle(
                              color: Color(0xFF8899BB), fontSize: 10)),
                    ],
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFF4A5A6A), size: 18),
                ],
              ),
            ),

            // ── Progress bar ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Setor: ${formatRupiah(totalSetor)}',
                          style: const TextStyle(
                              color: Color(0xFF66BB6A), fontSize: 10)),
                      Text('Ambil: ${formatRupiah(totalAmbil)}',
                          style: const TextStyle(
                              color: Color(0xFFEF9A9A), fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: persentase.toDouble(),
                      backgroundColor:
                          const Color(0xFFEF5350).withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation(saldoColor),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),

            // ── Divider + Tombol ────────────────────────────────
            const SizedBox(height: 10),
            const Divider(color: Color(0xFF243550), height: 1),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _AksiBtn(
                      label: 'Setor',
                      icon: Icons.south_rounded,
                      color: const Color(0xFF66BB6A),
                      onTap: onSetor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _AksiBtn(
                      label: 'Ambil',
                      icon: Icons.north_rounded,
                      color: const Color(0xFFEF9A9A),
                      onTap: onAmbil,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF243550),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Detail',
                          style: TextStyle(
                              color: Color(0xFF8899BB),
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AksiBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AksiBtn(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
