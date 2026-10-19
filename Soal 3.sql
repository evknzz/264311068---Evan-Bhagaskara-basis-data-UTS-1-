SELECT l.No_Laporan,
       l.Status_Laporan,
       SUM(t.Nominal) AS total_nominal
FROM tb_transaksi t
JOIN tb_laporan l ON t.No_Laporan = l.No_Laporan
WHERE t.Nominal >= 40000000
GROUP BY l.No_Laporan, l.Status_Laporan;


-- line 1 & 2, No laporan dan Status Laporan pada select adalah nama kolom yang akan aku gunain
-- line 3, SUM itu fungsi agregat buat jumlahin nilai dan AS untuk kata penghubung buat kasih nama baru
-- line 4, kasih nama alias ke tb transaksi
-- line 5, gabungin tabel kedua ke yang utama. ON buat mencocokkan
-- line 6, WHERE buat nyaring barisnya, lalu kolom diperiksa. jika nominalnya kurang dari 40juta, maka dibuang
-- line 7, GROUP BY buat mengelompokkan baris yg nilainya sama