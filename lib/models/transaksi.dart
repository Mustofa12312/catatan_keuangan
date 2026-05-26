class Transaksi {
  final int? id;
  final int penabungId;
  final String jenis; // 'setor' | 'ambil'
  final int nominal;
  final String catatan;
  final String tanggal; // ISO 8601

  // field computed (join), tidak disimpan di DB
  final String? namaPenabung;

  const Transaksi({
    this.id,
    required this.penabungId,
    required this.jenis,
    required this.nominal,
    this.catatan = '',
    required this.tanggal,
    this.namaPenabung,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'penabung_id': penabungId,
        'jenis': jenis,
        'nominal': nominal,
        'catatan': catatan,
        'tanggal': tanggal,
      };

  static Transaksi fromMap(Map<String, dynamic> map) => Transaksi(
        id: map['id'] as int?,
        penabungId: (map['penabung_id'] as num).toInt(),
        jenis: map['jenis'] as String,
        nominal: (map['nominal'] as num).toInt(),
        catatan: (map['catatan'] as String?) ?? '',
        tanggal: map['tanggal'] as String,
        namaPenabung: map['nama_penabung'] as String?,
      );

  Transaksi copyWith({
    int? id,
    int? penabungId,
    String? jenis,
    int? nominal,
    String? catatan,
    String? tanggal,
    String? namaPenabung,
  }) =>
      Transaksi(
        id: id ?? this.id,
        penabungId: penabungId ?? this.penabungId,
        jenis: jenis ?? this.jenis,
        nominal: nominal ?? this.nominal,
        catatan: catatan ?? this.catatan,
        tanggal: tanggal ?? this.tanggal,
        namaPenabung: namaPenabung ?? this.namaPenabung,
      );
}
