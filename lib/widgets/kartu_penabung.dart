import 'package:flutter/material.dart';
import '../utils/format_rupiah.dart';

class KartuPenabung extends StatelessWidget {
  final String nama;
  final String catatan;
  final int saldo;
  final int totalSetor;
  final int totalAmbil;
  final VoidCallback onTap;
  final VoidCallback onSetor;
  final VoidCallback onAmbil;

  const KartuPenabung({
    super.key,
    required this.nama,
    required this.catatan,
    required this.saldo,
    required this.totalSetor,
    required this.totalAmbil,
    required this.onTap,
    required this.onSetor,
    required this.onAmbil,
  });

  Color get _saldoColor =>
      saldo > 0 ? const Color(0xFF4CAF50) : (saldo == 0 ? const Color(0xFF8899AA) : const Color(0xFFE53935));

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2A3A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _saldoColor.withValues(alpha: 0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _saldoColor.withValues(alpha: 0.3),
                          _saldoColor.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        nama.isNotEmpty ? nama[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: _saldoColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nama,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        if (catatan.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            catatan,
                            style: const TextStyle(
                              color: Color(0xFF8899AA),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Saldo
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatRupiah(saldo),
                        style: TextStyle(
                          color: _saldoColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const Text(
                        'Saldo',
                        style: TextStyle(color: Color(0xFF8899AA), fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Divider
            const Divider(color: Color(0xFF2A3A4A), height: 1),

            // Footer: setor, ambil, detail
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      label: 'Total Setor',
                      value: formatRupiah(totalSetor),
                      color: const Color(0xFF4CAF50),
                      icon: Icons.south_rounded,
                    ),
                  ),
                  Expanded(
                    child: _MiniStat(
                      label: 'Total Ambil',
                      value: formatRupiah(totalAmbil),
                      color: const Color(0xFFE53935),
                      icon: Icons.north_rounded,
                    ),
                  ),
                  Row(
                    children: [
                      _AksiBtn(
                        label: 'Setor',
                        color: const Color(0xFF4CAF50),
                        onTap: onSetor,
                      ),
                      const SizedBox(width: 6),
                      _AksiBtn(
                        label: 'Ambil',
                        color: const Color(0xFFE57373),
                        onTap: onAmbil,
                      ),
                    ],
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

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MiniStat({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 4),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Color(0xFF8899AA), fontSize: 10)),
              Text(value, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

class _AksiBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AksiBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
