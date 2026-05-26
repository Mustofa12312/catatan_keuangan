import 'package:intl/intl.dart';

final _rupiah = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp',
  decimalDigits: 0,
);

final _tanggal = DateFormat('dd MMM yyyy', 'id_ID');
final _tanggalPanjang = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');

String formatRupiah(int nominal) => _rupiah.format(nominal);

String formatTanggal(String isoDate) {
  try {
    final dt = DateTime.parse(isoDate);
    return _tanggal.format(dt);
  } catch (_) {
    return isoDate;
  }
}

String formatTanggalPanjang(String isoDate) {
  try {
    final dt = DateTime.parse(isoDate);
    return _tanggalPanjang.format(dt);
  } catch (_) {
    return isoDate;
  }
}
