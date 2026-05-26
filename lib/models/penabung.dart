class Penabung {
  final int? id;
  final String nama;
  final String catatan;
  final String dibuatPada;

  const Penabung({
    this.id,
    required this.nama,
    this.catatan = '',
    required this.dibuatPada,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'nama': nama,
        'catatan': catatan,
        'dibuat_pada': dibuatPada,
      };

  static Penabung fromMap(Map<String, dynamic> map) => Penabung(
        id: map['id'] as int?,
        nama: map['nama'] as String,
        catatan: (map['catatan'] as String?) ?? '',
        dibuatPada: map['dibuat_pada'] as String,
      );

  Penabung copyWith({int? id, String? nama, String? catatan, String? dibuatPada}) =>
      Penabung(
        id: id ?? this.id,
        nama: nama ?? this.nama,
        catatan: catatan ?? this.catatan,
        dibuatPada: dibuatPada ?? this.dibuatPada,
      );
}
