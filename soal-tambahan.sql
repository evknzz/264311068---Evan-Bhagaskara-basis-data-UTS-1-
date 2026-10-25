-- 1. membuat tabel induk baru tapi tanpa FK.

CREATE TABLE tb_petugas (
    ID_Petugas    VARCHAR(10)  NOT NULL,
    Nama_Petugas  VARCHAR(100) NOT NULL,
    Jabatan       VARCHAR(30)  NOT NULL,
    Email         VARCHAR(100) NOT NULL,
    CONSTRAINT pk_petugas         PRIMARY KEY (ID_Petugas),
    CONSTRAINT uq_petugas_email   UNIQUE (Email),
    CONSTRAINT ck_petugas_jabatan CHECK (Jabatan IN
        ('Analis','Supervisor','Compliance Officer'))
);


-- 2. tb_pemeriksaan  (penghubung M:N tb_laporan <-> tb_petugas)
--  Satu laporan bisa diperiksa beberapa petugas (mis. analis lalu supervisor), satu petugas memeriksa banyak laporan.

CREATE TABLE tb_pemeriksaan (
    ID_Pemeriksaan     VARCHAR(10)  NOT NULL,
    No_Laporan         VARCHAR(20)  NOT NULL,
    ID_Petugas         VARCHAR(10)  NOT NULL,
    Tanggal_Penugasan  DATE         NOT NULL,
    Tanggal_Selesai    DATE         NULL,
    Hasil_Pemeriksaan  VARCHAR(20)  NOT NULL DEFAULT 'Belum ada',
    Catatan            VARCHAR(255),
    CONSTRAINT pk_pemeriksaan PRIMARY KEY (ID_Pemeriksaan),
    CONSTRAINT uq_pemeriksaan_laporan_petugas UNIQUE (No_Laporan, ID_Petugas),
    CONSTRAINT fk_pemeriksaan_laporan FOREIGN KEY (No_Laporan)
        REFERENCES tb_laporan (No_Laporan)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_pemeriksaan_petugas FOREIGN KEY (ID_Petugas)
        REFERENCES tb_petugas (ID_Petugas)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_pemeriksaan_hasil CHECK (Hasil_Pemeriksaan IN
        ('Belum ada','Terbukti','Tidak terbukti')),
    CONSTRAINT ck_pemeriksaan_tanggal CHECK
        (Tanggal_Selesai IS NULL OR Tanggal_Selesai >= Tanggal_Penugasan),
    CONSTRAINT ck_pemeriksaan_final CHECK
        (Hasil_Pemeriksaan = 'Belum ada' OR Tanggal_Selesai IS NOT NULL)
);


-- 3. tb_tindak_lanjut  (penghubung M:N tb_laporan <-> tb_nasabah, membawa atribut jenis & status tindakan)

CREATE TABLE tb_tindak_lanjut (
    ID_Tindakan      VARCHAR(10)  NOT NULL,
    No_Laporan       VARCHAR(20)  NOT NULL,
    ID_Nasabah       INT          NOT NULL,
    Jenis_Tindakan   VARCHAR(30)  NOT NULL,
    Tanggal_Tindakan DATE         NOT NULL,
    Status_Tindakan  VARCHAR(20)  NOT NULL DEFAULT 'Direncanakan',
    Keterangan       VARCHAR(255),
    CONSTRAINT pk_tindak_lanjut PRIMARY KEY (ID_Tindakan),
    CONSTRAINT fk_tindak_laporan FOREIGN KEY (No_Laporan)
        REFERENCES tb_laporan (No_Laporan)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_tindak_nasabah FOREIGN KEY (ID_Nasabah)
        REFERENCES tb_nasabah (ID_Nasabah)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_tindak_jenis CHECK (Jenis_Tindakan IN
        ('Permintaan Klarifikasi','Pemantauan Ketat',
         'Pemblokiran Sementara','Pembekuan Rekening')),
    CONSTRAINT ck_tindak_status CHECK (Status_Tindakan IN
        ('Direncanakan','Berjalan','Selesai','Dibatalkan'))
);


-- 4. tb_pelaporan_ppatk  (relasi 1 : 0..1 dengan tb_laporan), UNIQUE pada No_Laporan => satu laporan maksimal sekali dikirim.

CREATE TABLE tb_pelaporan_ppatk (
    ID_Pelaporan        VARCHAR(10) NOT NULL,
    No_Laporan          VARCHAR(20) NOT NULL,
    No_Referensi_PPATK  VARCHAR(30) NULL,
    Tanggal_Kirim       DATE        NOT NULL,
    Status_Pengiriman   VARCHAR(20) NOT NULL DEFAULT 'Terkirim',
    CONSTRAINT pk_pelaporan PRIMARY KEY (ID_Pelaporan),
    CONSTRAINT uq_pelaporan_laporan UNIQUE (No_Laporan),
    CONSTRAINT uq_pelaporan_ref     UNIQUE (No_Referensi_PPATK),
    CONSTRAINT fk_pelaporan_laporan FOREIGN KEY (No_Laporan)
        REFERENCES tb_laporan (No_Laporan)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_pelaporan_status CHECK (Status_Pengiriman IN
        ('Terkirim','Diterima','Ditolak'))
);


-- memasukkan contoh datanya

INSERT INTO tb_petugas VALUES
('PTG001', 'Rina Kusuma',    'Analis',             'rina.kusuma@bank.example'),
('PTG002', 'Hendra Gunawan', 'Supervisor',         'hendra.gunawan@bank.example'),
('PTG003', 'Sari Dewi',      'Compliance Officer', 'sari.dewi@bank.example');

INSERT INTO tb_pemeriksaan VALUES
('PMR001', 'LTM-001', 'PTG001', '2026-09-16', NULL,         'Belum ada', 'Menelusuri aliran dana TRX001-TRX002'),
('PMR002', 'LTM-002', 'PTG001', '2026-09-17', NULL,         'Belum ada', 'Menunggu data pendukung nasabah'),
('PMR003', 'LTM-003', 'PTG001', '2026-09-16', '2026-09-18', 'Terbukti',  'Dana kembali ke pengirim awal (siklus)'),
('PMR004', 'LTM-003', 'PTG002', '2026-09-18', '2026-09-18', 'Terbukti',  'Review supervisor: temuan disetujui');

INSERT INTO tb_tindak_lanjut VALUES
('TDK001', 'LTM-001', 1001, 'Pemantauan Ketat',      '2026-09-17', 'Berjalan', 'Transaksi 1001 dipantau harian'),
('TDK002', 'LTM-003', 1001, 'Pemblokiran Sementara', '2026-09-19', 'Berjalan', 'Diblokir sambil menunggu proses PPATK'),
('TDK003', 'LTM-003', 1004, 'Permintaan Klarifikasi', '2026-09-19', 'Selesai',  'Nasabah sudah dimintai penjelasan');

INSERT INTO tb_pelaporan_ppatk VALUES
('PPT001', 'LTM-003', 'REF-PPATK-2026-0001', '2026-09-20', 'Terkirim');


-- Memverifikasi query yang sudah kubuat

-- A. ringkasan penanganan tiap laporan
SELECT l.No_Laporan, l.Status_Laporan,
       (SELECT COUNT(*) FROM tb_pemeriksaan  p WHERE p.No_Laporan = l.No_Laporan) AS jml_pemeriksaan,
       (SELECT COUNT(*) FROM tb_tindak_lanjut t WHERE t.No_Laporan = l.No_Laporan) AS jml_tindakan,
       pp.Status_Pengiriman AS status_ppatk
FROM tb_laporan l
LEFT JOIN tb_pelaporan_ppatk pp ON pp.No_Laporan = l.No_Laporan;

-- B. beban kerja petugas: pemeriksaan yang belum selesai
SELECT g.Nama_Petugas, COUNT(*) AS pemeriksaan_berjalan
FROM tb_pemeriksaan p
JOIN tb_petugas g ON g.ID_Petugas = p.ID_Petugas
WHERE p.Tanggal_Selesai IS NULL
GROUP BY g.Nama_Petugas;

-- C. laporan terbukti yang belum dikirim ke PPATK (harusnya hanya kosong)
SELECT DISTINCT p.No_Laporan
FROM tb_pemeriksaan p
LEFT JOIN tb_pelaporan_ppatk pp ON pp.No_Laporan = p.No_Laporan
WHERE p.Hasil_Pemeriksaan = 'Terbukti' AND pp.ID_Pelaporan IS NULL;