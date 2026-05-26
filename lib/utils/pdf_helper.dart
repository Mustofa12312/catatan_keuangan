import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/penabung.dart';
import '../models/transaksi.dart';
import 'format_rupiah.dart';

class PdfHelper {
  static Future<File> generateStatement({
    required Penabung penabung,
    required List<Transaksi> transaksiList,
    required int saldoAkhir,
    required int totalSetor,
    required int totalAmbil,
  }) async {
    final pdf = pw.Document();

    // Font untuk tabel
    final fontRegular = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // ── HEADER ───────────────────────────────────────────────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('TABUNGAN TITIPAN',
                        style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 24,
                            color: PdfColors.blue800)),
                    pw.SizedBox(height: 4),
                    pw.Text('Laporan Rekening Koran',
                        style: pw.TextStyle(
                            font: fontRegular,
                            fontSize: 14,
                            color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Tanggal Cetak',
                        style: pw.TextStyle(
                            font: fontRegular,
                            fontSize: 10,
                            color: PdfColors.grey600)),
                    pw.Text(formatTanggal(DateTime.now().toIso8601String()),
                        style: pw.TextStyle(font: fontBold, fontSize: 12)),
                  ],
                ),
              ],
            ),
            pw.Divider(color: PdfColors.grey300, thickness: 2),
            pw.SizedBox(height: 12),

            // ── INFO PENABUNG ───────────────────────────────────────────────
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('NAMA NASABAH',
                          style: pw.TextStyle(
                              font: fontRegular,
                              fontSize: 10,
                              color: PdfColors.grey600)),
                      pw.Text(penabung.nama.toUpperCase(),
                          style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 16,
                              color: PdfColors.black)),
                      if (penabung.catatan.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(penabung.catatan,
                            style: pw.TextStyle(
                                font: fontRegular,
                                fontSize: 11,
                                color: PdfColors.grey700)),
                      ],
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue50,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: PdfColors.blue200),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('SALDO AKHIR',
                            style: pw.TextStyle(
                                font: fontRegular,
                                fontSize: 10,
                                color: PdfColors.grey700)),
                        pw.Text(formatRupiah(saldoAkhir),
                            style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 20,
                                color: PdfColors.blue800)),
                        pw.SizedBox(height: 8),
                        pw.Row(
                          mainAxisAlignment:
                              pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Total Setoran:',
                                style: pw.TextStyle(
                                    font: fontRegular, fontSize: 10)),
                            pw.Text(formatRupiah(totalSetor),
                                style: pw.TextStyle(
                                    font: fontBold,
                                    fontSize: 10,
                                    color: PdfColors.green700)),
                          ],
                        ),
                        pw.SizedBox(height: 2),
                        pw.Row(
                          mainAxisAlignment:
                              pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Total Penarikan:',
                                style: pw.TextStyle(
                                    font: fontRegular, fontSize: 10)),
                            pw.Text(formatRupiah(totalAmbil),
                                style: pw.TextStyle(
                                    font: fontBold,
                                    fontSize: 10,
                                    color: PdfColors.red700)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 24),

            // ── TABEL RIWAYAT ───────────────────────────────────────────────
            pw.Text('RIWAYAT TRANSAKSI',
                style: pw.TextStyle(
                    font: fontBold, fontSize: 14, color: PdfColors.black)),
            pw.SizedBox(height: 8),
            _buildTable(transaksiList, fontRegular, fontBold),
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final name = penabung.nama.replaceAll(' ', '_').toLowerCase();
    final file = File('${output.path}/laporan_$name.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _buildTable(
      List<Transaksi> transaksiList, pw.Font fontRegular, pw.Font fontBold) {
    if (transaksiList.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(20),
        alignment: pw.Alignment.center,
        child: pw.Text('Belum ada riwayat transaksi.',
            style: pw.TextStyle(
                font: fontRegular, fontSize: 12, color: PdfColors.grey600)),
      );
    }

    // Hitung saldo berjalan (harus diurutkan dari yang terlama ke terbaru)
    // Diasumsikan transaksiList dari DB berurut dari yang terbaru (desc),
    // maka kita reverse dulu untuk tabel agar saldo berjalannya benar.
    final listReversed = transaksiList.reversed.toList();
    
    int saldoBerjalan = 0;
    final List<List<String>> tableData = [];

    for (var t in listReversed) {
      if (t.jenis == 'setor') {
        saldoBerjalan += t.nominal;
      } else {
        saldoBerjalan -= t.nominal;
      }

      tableData.add([
        formatTanggal(t.tanggal),
        t.catatan.isEmpty ? (t.jenis == 'setor' ? 'Setoran' : 'Penarikan') : t.catatan,
        t.jenis == 'setor' ? formatRupiah(t.nominal) : '-',
        t.jenis == 'ambil' ? formatRupiah(t.nominal) : '-',
        formatRupiah(saldoBerjalan),
      ]);
    }

    // Kita kembalikan lagi ke descending agar yang terbaru di atas tabel (opsional, tapi standar bank biasanya terbaru di bawah atau di atas, kita buat terbaru di atas agar konsisten dengan aplikasi)
    tableData.insert(0, [
        '-',
        'SALDO AWAL',
        '-',
        '-',
        formatRupiah(0),
    ]);

    return pw.TableHelper.fromTextArray(
      headers: ['TANGGAL', 'KETERANGAN', 'SETOR', 'AMBIL', 'SALDO'],
      data: tableData.reversed.toList(), // Tampilkan yang terbaru di atas
      headerStyle: pw.TextStyle(
          font: fontBold, fontSize: 10, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
      cellStyle: pw.TextStyle(font: fontRegular, fontSize: 10),
      cellHeight: 25,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
      },
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FlexColumnWidth(2),
      },
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 1),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
    );
  }

  static Future<File> generateGlobalStatement({
    required List<Map<String, dynamic>> rekapList,
    required int grandTotalSaldo,
    required int grandTotalSetor,
    required int grandTotalAmbil,
  }) async {
    final pdf = pw.Document();
    final fontRegular = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          final List<List<String>> tableData = [];
          for (var i = 0; i < rekapList.length; i++) {
            final r = rekapList[i];
            tableData.add([
              (i + 1).toString(),
              (r['nama'] as String).toUpperCase(),
              formatRupiah((r['total_setor'] as num).toInt()),
              formatRupiah((r['total_ambil'] as num).toInt()),
              formatRupiah((r['saldo'] as num).toInt()),
              r['jumlah_transaksi'].toString(),
            ]);
          }

          return [
            // ── HEADER ───────────────────────────────────────────────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('TABUNGAN TITIPAN',
                        style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 24,
                            color: PdfColors.blue800)),
                    pw.SizedBox(height: 4),
                    pw.Text('Laporan Rekapitulasi Global',
                        style: pw.TextStyle(
                            font: fontRegular,
                            fontSize: 14,
                            color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Tanggal Cetak',
                        style: pw.TextStyle(
                            font: fontRegular,
                            fontSize: 10,
                            color: PdfColors.grey600)),
                    pw.Text(formatTanggal(DateTime.now().toIso8601String()),
                        style: pw.TextStyle(font: fontBold, fontSize: 12)),
                  ],
                ),
              ],
            ),
            pw.Divider(color: PdfColors.grey300, thickness: 2),
            pw.SizedBox(height: 16),

            // ── RINGKASAN KEUANGAN GLOBAL ────────────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.blue200),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('TOTAL DANA TITIPAN AKTIF',
                      style: pw.TextStyle(
                          font: fontRegular,
                          fontSize: 10,
                          color: PdfColors.grey700)),
                  pw.Text(formatRupiah(grandTotalSaldo),
                      style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 24,
                          color: PdfColors.blue900)),
                  pw.SizedBox(height: 12),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Total Dana Masuk:',
                                style: pw.TextStyle(font: fontRegular, fontSize: 10)),
                            pw.Text(formatRupiah(grandTotalSetor),
                                style: pw.TextStyle(
                                    font: fontBold,
                                    fontSize: 12,
                                    color: PdfColors.green700)),
                          ],
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Total Dana Keluar:',
                                style: pw.TextStyle(font: fontRegular, fontSize: 10)),
                            pw.Text(formatRupiah(grandTotalAmbil),
                                style: pw.TextStyle(
                                    font: fontBold,
                                    fontSize: 12,
                                    color: PdfColors.red700)),
                          ],
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Jumlah Penabung:',
                                style: pw.TextStyle(font: fontRegular, fontSize: 10)),
                            pw.Text('${rekapList.length} Orang',
                                style: pw.TextStyle(
                                    font: fontBold,
                                    fontSize: 12,
                                    color: PdfColors.black)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // ── TABEL DAFTAR PENABUNG ─────────────────────────────────────────
            pw.Text('REKAPITULASI DETAIL PENABUNG',
                style: pw.TextStyle(
                    font: fontBold, fontSize: 13, color: PdfColors.black)),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: ['NO', 'NAMA PENABUNG', 'TOTAL SETOR', 'TOTAL AMBIL', 'SALDO AKHIR', 'TX'],
              data: tableData,
              headerStyle: pw.TextStyle(
                  font: fontBold, fontSize: 9, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
              cellStyle: pw.TextStyle(font: fontRegular, fontSize: 9),
              cellHeight: 22,
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
                5: pw.Alignment.center,
              },
              columnWidths: {
                0: const pw.FlexColumnWidth(0.8),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
                4: const pw.FlexColumnWidth(2),
                5: const pw.FlexColumnWidth(0.8),
              },
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
            ),
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/laporan_rekap_global_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
