import 'package:flutter/material.dart';
import '../models/transaksi.dart';
import '../utils/format_rupiah.dart';

class ItemTransaksi extends StatelessWidget {
  final Transaksi transaksi;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool tampilkanNama;

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
    final color =
        isSetor ? const Color(0xFF66BB6A) : const Color(0xFFEF5350);

    return Dismissible(
      key: Key('transaksi_${transaksi.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEF5350).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFFEF5350).withValues(alpha: 0.3)),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete_outline_rounded,
                color: Color(0xFFEF5350), size: 26),
            const SizedBox(height: 4),
            const Text('Hapus',
                style: TextStyle(
                    color: Color(0xFFEF5350),
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF1A2840),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text('Hapus Transaksi',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            content: const Text(
                'Transaksi ini akan dihapus permanen.',
                style: TextStyle(color: Color(0xFF8899BB))),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal',
                    style: TextStyle(color: Color(0xFF8899BB))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF5350),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Hapus'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2840),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: color.withValues(alpha: 0.15), width: 1),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isSetor ? Icons.south_rounded : Icons.north_rounded,
              color: color,
              size: 20,
            ),
          ),
          title: tampilkanNama && transaksi.namaPenabung != null
              ? Row(
                  children: [
                    Flexible(
                      child: Text(
                        transaksi.namaPenabung!,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _JenisBadge(isSetor: isSetor, color: color),
                  ],
                )
              : Row(
                  children: [
                    Text(
                      isSetor ? 'Setoran' : 'Penarikan',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                    ),
                    const SizedBox(width: 6),
                    _JenisBadge(isSetor: isSetor, color: color),
                  ],
                ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 3),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 11, color: Color(0xFF8899BB)),
                  const SizedBox(width: 4),
                  Text(
                    formatTanggal(transaksi.tanggal),
                    style: const TextStyle(
                        color: Color(0xFF8899BB), fontSize: 11),
                  ),
                ],
              ),
              if (transaksi.catatan.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  transaksi.catatan,
                  style: const TextStyle(
                      color: Color(0xFF6677AA), fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isSetor ? '+' : '-'}${formatRupiah(transaksi.nominal)}',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 13),
                  ),
                ],
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert,
                    color: Color(0xFF8899BB), size: 18),
                color: const Color(0xFF1A2840),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'hapus') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      Icon(Icons.edit_outlined,
                          color: Colors.blueAccent, size: 16),
                      SizedBox(width: 10),
                      Text('Edit',
                          style: TextStyle(color: Colors.white, fontSize: 14)),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'hapus',
                    child: Row(children: [
                      Icon(Icons.delete_outline,
                          color: Colors.redAccent, size: 16),
                      SizedBox(width: 10),
                      Text('Hapus',
                          style: TextStyle(color: Colors.white, fontSize: 14)),
                    ]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JenisBadge extends StatelessWidget {
  final bool isSetor;
  final Color color;
  const _JenisBadge({required this.isSetor, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isSetor ? 'Setor' : 'Ambil',
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}
