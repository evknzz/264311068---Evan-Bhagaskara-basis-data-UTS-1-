# Membuat 3 tabel dari proyek kelompok Saya yang saling berelasi

## tb_nasabah
CREATE TABLE tb_nasabah (
    ID_Nasabah     INT PRIMARY KEY,
    Nama_Nasabah   VARCHAR(100) NOT NULL,
    Jenis_Rekening VARCHAR(20)  NOT NULL,
    Status_Nasabah VARCHAR(20)  NOT NULL
);

## tb_laporan
CREATE TABLE tb_laporan (
    No_Laporan          VARCHAR(20) PRIMARY KEY,
    Tanggal_Pemeriksaan DATE NOT NULL,
    Status_Laporan      VARCHAR(100) NOT NULL
);

## tb_transaksi
CREATE TABLE tb_transaksi (
    ID_Transaksi       VARCHAR(10) PRIMARY KEY,
    Tanggal_Pengiriman DATE NOT NULL,
    ID_Pengirim        INT NOT NULL,
    ID_Penerima        INT NOT NULL,
    Nominal            DECIMAL(15,2) NOT NULL,
    Jenis_Transaksi    VARCHAR(30) NOT NULL,
    No_Laporan         VARCHAR(20),
    Indikasi           VARCHAR(100),

    CONSTRAINT fk_pengirim FOREIGN KEY (ID_Pengirim)
        REFERENCES tb_nasabah (ID_Nasabah),
    CONSTRAINT fk_penerima FOREIGN KEY (ID_Penerima)
        REFERENCES tb_nasabah (ID_Nasabah),
    CONSTRAINT fk_laporan_trx FOREIGN KEY (No_Laporan)
        REFERENCES tb_laporan (No_Laporan)
);
