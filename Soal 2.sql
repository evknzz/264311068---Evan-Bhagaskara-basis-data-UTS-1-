-- [CREATE]
INSERT INTO tb_nasabah VALUES
(1001, 'Andi Pratama',  'Perorangan', 'Aktif'),
(1002, 'Budi Santoso',  'Perorangan', 'Aktif'),
(1003, 'Citra Mandiri', 'Perusahaan', 'Aktif'),
(1004, 'Dimas Jaya',    'Perorangan', 'Aktif'),
(1005, 'Eka Wijaya',    'Perorangan', 'Aktif'),
(1006, 'Fajar Abadi',   'Perorangan', 'Aktif');

INSERT INTO tb_laporan VALUES
('LTM-001', '2026-09-16', 'Perlu pemeriksaan lebih lanjut'),
('LTM-002', '2026-09-17', 'Sedang diperiksa'),
('LTM-003', '2026-09-18', 'Selesai diperiksa');

INSERT INTO tb_transaksi VALUES
('TRX001', '2026-09-15', 1001, 1002, 50000000, 'Transfer', 'LTM-001', 'Transaksi berantai'),
('TRX002', '2026-09-15', 1002, 1003, 48000000, 'Transfer', 'LTM-001', 'Transaksi berantai'),
('TRX003', '2026-09-15', 1003, 1004, 45000000, 'Transfer', 'LTM-002', 'Transaksi berantai'),
('TRX004', '2026-09-15', 1004, 1001, 40000000, 'Transfer', 'LTM-003', 'Membentuk siklus'),
('TRX005', '2026-09-16', 1001, 1005, 10000000, 'Transfer', NULL, NULL),
('TRX006', '2026-09-16', 1005, 1006,  9000000, 'Transfer', NULL, NULL);


-- [READ]
SELECT * FROM tb_nasabah;


-- [UPDATE]
--- cek hasil sebelum di UPDATE
SELECT * FROM tb_transaksi WHERE ID_Transaksi = 'TRX005';

--- ngeupdate nominal uang menjadi 12jt pada TRX005
UPDATE tb_transaksi
SET Nominal = 12000000
WHERE ID_Transaksi = 'TRX005';

--- cek hasil setelah di update nominal uangnya
SELECT * FROM tb_transaksi WHERE ID_Transaksi = 'TRX005';


-- [DELETE]
--- Membuat data dummy
INSERT INTO tb_transaksi VALUES
('TRX007', '2026-09-17', 1002, 1005, 5000000, 'Transfer', NULL, NULL);

--- eksekusi delete ke dummy data
DELETE FROM tb_transaksi
WHERE ID_Transaksi = 'TRX007';