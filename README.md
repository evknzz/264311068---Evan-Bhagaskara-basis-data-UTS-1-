# Pengembangan Basis Data: Monitoring Transaksi Keuangan Mencurigakan

Repo ini melanjutkan `Soal 1.sql`, `Soal 2.sql`, dan `Soal 3.sql`. Sistem lamanya mencatat nasabah, transaksi, dan Laporan Transaksi Mencurigakan (LTM) dalam tiga tabel: `tb_nasabah`, `tb_transaksi`, dan `tb_laporan`. Sekarang bisnisnya kedatangan tiga proses baru, dan semuanya diselesaikan dengan menambah empat tabel. Tiga tabel lama dibiarkan apa adanya.

| File | Isi |
|---|---|
| `README.md` | Dokumen ini: tantangan bisnis, aturan bisnis, normalisasi, skema relasional |
| `[UTS - SCPMK0320703] ERD.png` | Gambar ERD (pemodelan konseptual) |
| `uts.sql` | DDL, data contoh, dan query verifikasi (pemodelan fisik) |
| `[UTS - SCPMK0320703] gambar.pdf` | Screenshot hasil menjalankan SQL di DBeaver |

---

## 1. Tantangan Bisnis dan Tiga Proses Baru

### Tantangan

Begitu sebuah laporan masuk ke `tb_laporan`, sistem berhenti mencatat. Siapa yang memeriksanya? Apa hasilnya? Nasabah yang terlibat diapakan? Sudah dikirim ke PPATK atau belum? Database tidak punya jawabannya. Kolom `Status_Laporan` hanya menyimpan satu teks, jadi kejadian-kejadian sebelum status itu tidak bisa dilacak.

### Tiga proses baru

| No | Proses | Tabel baru | Yang dicatat |
|---|---|---|---|
| 1 | Pemeriksaan laporan | `tb_petugas`, `tb_pemeriksaan` | Petugas yang ditugaskan, tanggal penugasan dan selesai, hasil pemeriksaan |
| 2 | Tindak lanjut ke nasabah | `tb_tindak_lanjut` | Jenis tindakan (klarifikasi, pemantauan ketat, pemblokiran sementara, pembekuan rekening) dan statusnya |
| 3 | Pelaporan ke PPATK | `tb_pelaporan_ppatk` | Tanggal kirim, nomor referensi, status pengiriman |

Solusinya sengaja ringan. Tabel baru menempel ke tabel lama lewat Foreign Key, dan tidak ada satu kolom pun di `tb_nasabah`, `tb_laporan`, atau `tb_transaksi` yang diubah.

---

## 2. Aturan Bisnis

| Kode | Aturan | Ditegakkan lewat |
|---|---|---|
| BR1 | Satu laporan boleh diperiksa beberapa petugas, misalnya analis lalu supervisor. Petugas yang sama tidak boleh ditugaskan dua kali ke laporan yang sama. | `UNIQUE (No_Laporan, ID_Petugas)` |
| BR2 | Tanggal selesai tidak boleh mendahului tanggal penugasan. | `CHECK` |
| BR3 | Hasil "Terbukti" atau "Tidak terbukti" baru sah setelah tanggal selesai terisi. | `CHECK` |
| BR4 | Satu laporan bisa memicu beberapa tindakan ke beberapa nasabah; satu tindakan selalu terikat pada tepat satu laporan dan satu nasabah. | `FOREIGN KEY` |
| BR5 | Jenis dan status tindakan hanya boleh berisi nilai dari daftar yang sudah ditetapkan. | `CHECK` |
| BR6 | Satu laporan paling banyak dikirim sekali ke PPATK, dan nomor referensi PPATK tidak boleh kembar. | `UNIQUE` |
| BR7 | Hanya laporan yang terbukti yang boleh dikirim ke PPATK. | Belum ditegakkan di DDL karena aturannya melibatkan dua tabel. Query verifikasi C memantaunya, dan trigger bisa menambahnya kalau perlu. |
| BR8 | Riwayat pemeriksaan, tindakan, dan pengiriman tidak boleh ikut hilang saat laporan, nasabah, atau petugasnya dihapus. | `ON DELETE RESTRICT` |

### Relasi dan kardinalitas

| Relasi | Kardinalitas |
|---|---|
| `tb_laporan` – `tb_pemeriksaan` | 1 : N |
| `tb_petugas` – `tb_pemeriksaan` | 1 : N |
| `tb_laporan` – `tb_petugas` (lewat `tb_pemeriksaan`) | M : N |
| `tb_laporan` – `tb_tindak_lanjut` | 1 : N |
| `tb_nasabah` – `tb_tindak_lanjut` | 1 : N |
| `tb_laporan` – `tb_nasabah` (lewat `tb_tindak_lanjut`) | M : N |
| `tb_laporan` – `tb_pelaporan_ppatk` | 1 : 0..1 |

`tb_pemeriksaan` dan `tb_tindak_lanjut` memang menghubungkan relasi M:N, tetapi keduanya juga menyimpan atribut sendiri (tanggal, hasil, jenis tindakan, status). Karena itu keduanya tidak bisa dipangkas menjadi sekadar pasangan kunci.

### ERD

![ERD](%5BUTS%20-%20SCPMK0320703%5D%20ERD.png)

Empat tabel baru: `tb_petugas`, `tb_pemeriksaan`, `tb_tindak_lanjut`, dan `tb_pelaporan_ppatk`. Sisanya (`tb_nasabah`, `tb_transaksi`, `tb_laporan`) adalah tabel lama.

---

## 3. Normalisasi

Prosesnya dimulai dari satu formulir yang menggabungkan data ketiga proses baru, yaitu lembar penanganan laporan.

### Bentuk tidak normal (UNF)

Tanda `{ }` menandai kelompok atribut yang bisa berulang.

```
PENANGANAN(No_Laporan, Status_Laporan,
    { ID_Petugas, Nama_Petugas, Jabatan, Email,
      Tgl_Penugasan, Tgl_Selesai, Hasil, Catatan },
    { ID_Tindakan, ID_Nasabah, Nama_Nasabah, Jenis_Tindakan,
      Tgl_Tindakan, Status_Tindakan, Keterangan },
    No_Ref_PPATK, Tgl_Kirim, Status_Pengiriman)
```

Ambil LTM-003 dari data contoh: laporan ini punya dua petugas (PTG001 dan PTG002) dan dua tindakan (TDK002 dan TDK003). Kalau semuanya ditaruh dalam satu baris, kolom petugas dan kolom tindakan masing-masing berisi lebih dari satu nilai, jadi bentuknya belum atomik.

### 1NF: pecah kelompok berulang

Setiap kelompok berulang menjadi relasi sendiri.

| Relasi | Atribut (kunci dicetak tebal) |
|---|---|
| R1 `LAPORAN_KIRIM` | **No_Laporan**, Status_Laporan, No_Ref_PPATK, Tgl_Kirim, Status_Pengiriman |
| R2 `PEMERIKSAAN` | **No_Laporan, ID_Petugas**, Nama_Petugas, Jabatan, Email, Tgl_Penugasan, Tgl_Selesai, Hasil, Catatan |
| R3 `TINDAKAN` | **No_Laporan, ID_Tindakan**, ID_Nasabah, Nama_Nasabah, Jenis_Tindakan, Tgl_Tindakan, Status_Tindakan, Keterangan |

### 2NF: singkirkan ketergantungan parsial

- R1 langsung lolos karena kuncinya tunggal.
- R2 berkunci (No_Laporan, ID_Petugas), tetapi `Nama_Petugas`, `Jabatan`, dan `Email` hanya bergantung pada `ID_Petugas`. Ketiganya pindah ke relasi `PETUGAS`. Tanggal, hasil, dan catatan tetap di `PEMERIKSAAN` karena baru bermakna kalau laporan dan petugasnya diketahui bersamaan.
- Di R3, `ID_Tindakan` saja sudah menentukan semua atribut lain, termasuk `No_Laporan`. Kuncinya menyusut menjadi `ID_Tindakan`.

Di tabel fisik, `tb_pemeriksaan` memakai kunci pengganti `ID_Pemeriksaan` agar mudah dirujuk, sementara pasangan (No_Laporan, ID_Petugas) tetap dijaga unik.

### 3NF: singkirkan ketergantungan transitif

| Ketergantungan | Perbaikan |
|---|---|
| `ID_Tindakan → ID_Nasabah → Nama_Nasabah` pada R3 | `Nama_Nasabah` dibuang dari tindakan. Namanya diambil dari `tb_nasabah` lewat FK `ID_Nasabah`. |
| `Status_Laporan` pada R1 sudah ada di `tb_laporan` | Tidak diulang |
| `No_Ref_PPATK`, `Tgl_Kirim`, `Status_Pengiriman` hanya terisi pada sebagian laporan | Dipindah ke relasi `PELAPORAN_PPATK` supaya tidak penuh NULL. Ini keputusan desain, bukan pelanggaran 3NF. |

Tiga tabel lama juga dicek. Kunci utamanya tunggal, jadi tidak ada ketergantungan parsial, dan tidak ada ketergantungan transitif di dalamnya.

### Hasil akhir normalisasi

| Hasil normalisasi | Tabel fisik |
|---|---|
| `PETUGAS` | `tb_petugas` (baru) |
| `PEMERIKSAAN` | `tb_pemeriksaan` (baru) |
| `TINDAKAN` (tanpa Nama_Nasabah) | `tb_tindak_lanjut` (baru) |
| `PELAPORAN_PPATK` | `tb_pelaporan_ppatk` (baru) |
| Data laporan dan nasabah | `tb_laporan`, `tb_nasabah` (lama) |

---

## 4. Skema Relasional Akhir (3NF)

**PK** dicetak tebal, *FK* dicetak miring.

**Tabel lama (tidak diubah)**

```
tb_nasabah   (ID_Nasabah, Nama_Nasabah, Jenis_Rekening, Status_Nasabah)
tb_laporan   (No_Laporan, Tanggal_Pemeriksaan, Status_Laporan)
tb_transaksi (ID_Transaksi, Tanggal_Pengiriman, ID_Pengirim, ID_Penerima,
              Nominal, Jenis_Transaksi, No_Laporan, Indikasi)
```

**Tabel baru**

| Relasi | Atribut |
|---|---|
| `tb_petugas` | **ID_Petugas**, Nama_Petugas, Jabatan, Email *(unique)* |
| `tb_pemeriksaan` | **ID_Pemeriksaan**, *No_Laporan*, *ID_Petugas*, Tanggal_Penugasan, Tanggal_Selesai, Hasil_Pemeriksaan, Catatan |
| `tb_tindak_lanjut` | **ID_Tindakan**, *No_Laporan*, *ID_Nasabah*, Jenis_Tindakan, Tanggal_Tindakan, Status_Tindakan, Keterangan |
| `tb_pelaporan_ppatk` | **ID_Pelaporan**, *No_Laporan* *(unique)*, No_Referensi_PPATK *(unique)*, Tanggal_Kirim, Status_Pengiriman |

### Foreign Key

| Kolom | Merujuk ke | ON UPDATE | ON DELETE |
|---|---|---|---|
| `tb_pemeriksaan.No_Laporan` | `tb_laporan.No_Laporan` | CASCADE | RESTRICT |
| `tb_pemeriksaan.ID_Petugas` | `tb_petugas.ID_Petugas` | CASCADE | RESTRICT |
| `tb_tindak_lanjut.No_Laporan` | `tb_laporan.No_Laporan` | CASCADE | RESTRICT |
| `tb_tindak_lanjut.ID_Nasabah` | `tb_nasabah.ID_Nasabah` | RESTRICT | RESTRICT |
| `tb_pelaporan_ppatk.No_Laporan` | `tb_laporan.No_Laporan` | CASCADE | RESTRICT |

---

## Bukti Pengujian

Screenshot lengkapnya ada di [`[UTS - SCPMK0320703] gambar.pdf`](%5BUTS%20-%20SCPMK0320703%5D%20gambar.pdf). Isinya daftar tabel, constraint dan Foreign Key yang terpasang, isi keempat tabel baru, query verifikasi A sampai C, dan tiga pengujian validasi di bawah ini.

Ketiga `INSERT` ini sengaja melanggar aturan bisnis. Di tiap perintah hanya satu kolom yang salah; kolom lainnya valid, jadi penolakannya pasti berasal dari constraint yang sedang diuji.

| Pengujian | Aturan | Hasil |
|---|---|---|
| Hasil "Terbukti" tanpa tanggal selesai di `tb_pemeriksaan` | BR3 | Ditolak: `Error 3819, Check constraint 'ck_pemeriksaan_final' is violated` |
| LTM-003 dikirim ke PPATK untuk kedua kalinya | BR6 | Ditolak: `Error 1062, Duplicate entry 'LTM-003' for key 'uq_pelaporan_laporan'` |
| Tindak lanjut untuk laporan LTM-999 yang tidak ada | BR4 | Ditolak: `Error 1452, foreign key constraint fails (fk_tindak_laporan)` |

---

## Cara menjalankan

Pakai MySQL 8.0.16 atau lebih baru; versi di bawah itu menerima sintaks `CHECK` tetapi tidak menegakkannya. Urutannya:

1. `Soal 1.sql` membuat tiga tabel lama.
2. `Soal 2.sql` mengisi data lama.
3. `uts.sql` membuat empat tabel baru, mengisi data contoh, lalu menjalankan query verifikasi di bagian akhir file.

Data petugas dan data lain di `uts.sql` hanya contoh untuk pengujian.
