# PRD — Aplikasi Catatan Keuangan Keluarga Offline Android

## Nama Sementara

**Kas Keluarga Offline**

---

# 1. Latar Belakang

Aplikasi ini dibuat untuk membantu pencatatan keuangan keluarga secara sederhana dan transparan.

Pengguna utama adalah satu orang pencatat keuangan keluarga yang menerima transfer uang dari beberapa saudara, lalu mendistribusikan uang tersebut untuk berbagai kebutuhan keluarga seperti:

* kebutuhan ibu
* kebutuhan rumah
* acara keluarga
* kebutuhan darurat
* pengeluaran lainnya

Aplikasi berjalan secara offline di Android menggunakan Flutter sehingga mudah digunakan tanpa internet.

---

# 2. Tujuan Aplikasi

Tujuan utama aplikasi:

* mencatat uang masuk dan keluar
* menghitung saldo otomatis
* menghitung akumulasi transaksi per orang
* mempermudah pelacakan distribusi uang keluarga
* menyediakan riwayat transaksi yang rapi
* meminimalisir kesalahan pencatatan manual

---

# 3. Platform

| Item             | Teknologi                 |
| ---------------- | ------------------------- |
| Platform         | Android                   |
| Framework        | Flutter                   |
| Database Offline | SQLite / Hive             |
| Mode             | Offline                   |
| Target Pengguna  | Personal / keluarga kecil |

---

# 4. Target Pengguna

Pengguna utama:

* satu orang bendahara keluarga
* pencatat distribusi uang keluarga

Pengguna tidak membutuhkan:

* login multi user
* internet
* sinkronisasi cloud
* pembayaran online

---

# 5. Fitur Utama

## 5.1 Dashboard

Menampilkan:

* total pemasukan
* total pengeluaran
* saldo saat ini
* ringkasan transaksi terbaru
* akumulasi per orang

---

## 5.2 Pencatatan Pemasukan

Pengguna dapat mencatat:

* nama pengirim
* nominal
* tanggal
* kategori
* catatan tambahan

Contoh:

* Saudara A transfer Rp500.000

---

## 5.3 Pencatatan Pengeluaran

Pengguna dapat mencatat:

* penerima uang
* nominal
* tanggal
* kategori
* catatan

Contoh:

* Untuk ibu Rp200.000

---

## 5.4 Riwayat Transaksi

Menampilkan seluruh transaksi:

* pemasukan
* pengeluaran

Fitur:

* urut terbaru
* edit transaksi
* hapus transaksi
* pencarian sederhana

---

## 5.5 Akumulasi Per Orang

Aplikasi menghitung otomatis:

* total uang masuk per orang
* total uang keluar per orang
* saldo / net transaksi

Contoh:

| Nama      |   Masuk |  Keluar |      Net |
| --------- | ------: | ------: | -------: |
| Saudara A | 500.000 |       0 |  500.000 |
| Ibu       |       0 | 200.000 | -200.000 |

---

## 5.6 Kategori Transaksi

Kategori default:

* Ibu
* Rumah
* Darurat
* Acara
* Lainnya

Kategori dapat:

* ditambah
* diedit
* dihapus

---

# 6. Alur Penggunaan

## Alur Pemasukan

1. Pengguna membuka aplikasi
2. Pilih tambah pemasukan
3. Isi data transaksi
4. Simpan
5. Saldo otomatis bertambah

---

## Alur Pengeluaran

1. Pengguna pilih tambah pengeluaran
2. Isi data
3. Simpan
4. Saldo otomatis berkurang

---

# 7. Struktur Data

## Tabel transaksi

| Field    | Tipe     |
| -------- | -------- |
| id       | integer  |
| nama     | text     |
| jenis    | text     |
| nominal  | integer  |
| kategori | text     |
| catatan  | text     |
| tanggal  | datetime |

---

## Jenis Transaksi

* masuk
* keluar

---

# 8. Perhitungan Sistem

## Total Saldo

```text
Saldo = Total Pemasukan - Total Pengeluaran
```

## Akumulasi Per Orang

```text
Net = Total Masuk - Total Keluar
```

---

# 9. Desain UI

## Tema

* sederhana
* ringan
* mudah dibaca
* fokus pada pencatatan cepat

---

## Warna

* hijau = pemasukan
* merah = pengeluaran
* biru = saldo

---

# 10. Halaman Aplikasi

## Halaman Dashboard

Isi:

* saldo
* total masuk
* total keluar
* transaksi terbaru

---

## Halaman Tambah Transaksi

Form:

* nama
* nominal
* jenis transaksi
* kategori
* tanggal
* catatan

---

## Halaman Riwayat

Menampilkan:

* daftar transaksi
* filter
* edit
* hapus

---

## Halaman Akumulasi

Menampilkan:

* total per orang
* detail transaksi orang tersebut

---

# 11. Penyimpanan Data

Versi awal:

* offline penuh
* data disimpan di perangkat Android

Teknologi:

* Hive atau SQLite

---

# 12. Keunggulan Aplikasi

* ringan
* cepat
* offline
* mudah digunakan
* cocok untuk pencatatan keluarga
* tidak membutuhkan internet

---

# 13. Pengembangan Masa Depan

Fitur yang bisa ditambahkan:

* backup data
* export PDF
* export Excel
* grafik bulanan
* sinkronisasi cloud
* login multi user
* upload bukti transfer

---

# 14. Kesimpulan

Aplikasi ini merupakan sistem pencatatan keuangan keluarga berbasis Android Flutter yang fokus pada:

* pencatatan pemasukan
* pencatatan pengeluaran
* penghitungan saldo otomatis
* akumulasi transaksi per orang

Dengan sistem offline sederhana, aplikasi diharapkan membantu pengguna mengelola distribusi uang keluarga dengan lebih rapi, transparan, dan mudah dipahami.
