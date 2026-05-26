import 'package:flutter/material.dart';
import '../models/transaksi.dart';
import '../utils/format_rupiah.dart';

class ItemTransaksi extends StatelessWidget {
  final Transaksi transaksi;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool tampilkanNama; // false jika di halaman detail per penabung

  const ItemTransaksi({
    super.key,
    required this.transaksi,
    required this.onEdit,
    required this.onDelete,
    this.tampilkanNama = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSetor = transaksi.jenis == 'setor';
    final color = isSetor ? const Color(0xFF4CAF50) : const Color(0xFFE57373);
    final bgColor = isSetor
        ? const Color(0xFF4CAF50).withValues(alpha: 0.08)
        : const Color(0xFFE57373).withValues(alpha: 0.08);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2A3A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isSetor ? Icons.south_rounded : Icons.north_rounded,
            color: color,
            size: 22,
          ),
        ),
        title: tampilkanNama && transaksi.namaPenabung != null
            ? Text(
                transaksi.namaPenabung!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              )
            : Text(
                isSetor ? 'Setor Tabungan' : 'Ambil Tabungan',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isSetor ? 'Setor' : 'Ambil',
                    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatTanggal(transaksi.tanggal),
                  style: const TextStyle(color: Color(0xFF8899AA), fontSize: 11),
                ),
              ],
            ),
            if (transaksi.catatan.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                transaksi.catatan,
                style: const TextStyle(color: Color(0xFF6677AA), fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${isSetor ? '+' : '-'}${formatRupiah(transaksi.nominal)}',
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF8899AA), size: 18),
              color: const Color(0xFF1E2A3A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'hapus') onDelete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 18),
                      SizedBox(width: 10),
                      Text('Edit', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'hapus',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                      SizedBox(width: 10),
                      Text('Hapus', style: TextStyle(color: Colors.white)),
                    ],
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
