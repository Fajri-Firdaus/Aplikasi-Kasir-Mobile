# SQLite Database Schema - Mobile POS (Improved)

Dokumen ini adalah versi terbaru yang diselaraskan dengan fitur pada mindmap dan implementasi `database.sql`. Database mencakup manajemen Shift, User, Pelanggan, Kategori, dan Pengaturan Toko.

## Database Name: `mobile_pos.db`
**Version:** 1

---

## 1. Tabel Master Data

### 1.1 `users`
Data kasir/admin aplikasi. Digunakan untuk login dan manajemen profil.
| Kolom | Tipe Data | Constraint | Deskripsi |
|-------|-----------|------------|-----------|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | |
| `full_name` | TEXT | | Nama lengkap pengguna |
| `email` | TEXT | UNIQUE | Untuk fitur *Forgot Password* |
| `username` | TEXT | NOT NULL UNIQUE | |
| `password` | TEXT | NOT NULL | Hashed password |
| `role` | TEXT | NOT NULL DEFAULT 'cashier' | 'admin' atau 'cashier' |
| `admin_id` | INTEGER | FK -> `users(id)` | Parent admin ID (Inheritance) |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |

### 1.2 `categories`
Katalog kategori produk.
| Kolom | Tipe Data | Constraint | Deskripsi |
|-------|-----------|------------|-----------|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | |
| `name` | TEXT | NOT NULL UNIQUE | |

### 1.3 `products`
Katalog produk. Mendukung fitur pencarian SKU dan teks.
| Kolom | Tipe Data | Constraint | Deskripsi |
|-------|-----------|------------|-----------|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | |
| `sku` | TEXT | UNIQUE | Kode unik/Barcode |
| `name` | TEXT | NOT NULL | |
| `category_id` | INTEGER | FK -> `categories(id)` | |
| `buy_price` | REAL | NOT NULL DEFAULT 0.0 | Modal saat ini |
| `sell_price` | REAL | NOT NULL DEFAULT 0.0 | Harga jual saat ini |
| `stock` | INTEGER | DEFAULT 0 | |
| `image_path` | TEXT | | Lokasi file gambar lokal |
| `is_active` | INTEGER | DEFAULT 1 | 1=Aktif, 0=Nonaktif (*Soft Delete*) |

### 1.4 `customers`
Data pelanggan tetap untuk analisis loyalitas.
| Kolom | Tipe Data | Constraint | Deskripsi |
|-------|-----------|------------|-----------|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | |
| `name` | TEXT | NOT NULL | |
| `phone` | TEXT | | |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |

### 1.5 `store_settings`
Menyimpan informasi identitas toko untuk pengaturan dan struk.
| Kolom | Tipe Data | Constraint | Deskripsi |
|-------|-----------|------------|-----------|
| `id` | INTEGER | PRIMARY KEY CHECK (id=1) | Singleton (Hanya 1 baris) |
| `store_name` | TEXT | NOT NULL | |
| `store_address` | TEXT | | |
| `store_phone` | TEXT | | |
| `receipt_footer`| TEXT | | Pesan di bawah struk |
| `updated_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |

---

## 2. Tabel Operasional (Shift & Transaksi)

### 2.1 `shifts`
Mencatat sesi kasir untuk audit saldo laci (Laporan X/Z).
| Kolom | Tipe Data | Constraint | Deskripsi |
|-------|-----------|------------|-----------|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | |
| `user_id` | INTEGER | FK -> `users(id)` | |
| `start_time` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |
| `end_time` | TIMESTAMP | | |
| `starting_cash`| REAL | DEFAULT 0.0 | Saldo awal laci |
| `ending_cash` | REAL | DEFAULT 0.0 | Saldo akhir laci |
| `status` | TEXT | CHECK IN ('open','closed') | DEFAULT 'open' |

### 2.2 `transactions`
Header transaksi. Mendukung pembatalan (*void*).
| Kolom | Tipe Data | Constraint | Deskripsi |
|-------|-----------|------------|-----------|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | |
| `shift_id` | INTEGER | FK -> `shifts(id)` | Kasir yang bertugas |
| `customer_id` | INTEGER | FK -> `customers(id)` | Bisa NULL |
| `total_amount` | REAL | NOT NULL | Total akhir |
| `payment_method`| TEXT | NOT NULL | 'cash', 'qris', dll |
| `cash_received` | REAL | DEFAULT 0.0 | Uang yang diterima kasir |
| `status` | TEXT | CHECK IN ('completed','void')| DEFAULT 'completed' |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |

### 2.3 `transaction_details`
Item detail transaksi. Digunakan untuk perhitungan HPP dan Laba.
| Kolom | Tipe Data | Constraint | Deskripsi |
|-------|-----------|------------|-----------|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | |
| `transaction_id`| INTEGER | FK -> `transactions(id)` | |
| `product_id` | INTEGER | FK -> `products(id)` | |
| `quantity` | INTEGER | NOT NULL | |
| `buy_price_at_sale` | REAL | NOT NULL | Modal saat transaksi |
| `sell_price_at_sale`| REAL | NOT NULL | Harga jual saat transaksi |

---


## 3. Draf Kueri Lengkap (Dari database.sql)

### 3.1. Modul Home (Halaman Utama)

**A. Ringkasan Performa Hari Ini**
Mengambil total transaksi, total omzet penjualan, dan laba bersih hari ini.
```sql
SELECT 
    COUNT(t.id) AS total_transaksi,
    COALESCE(SUM(t.total_amount), 0.0) AS penjualan_hari_ini,
    COALESCE(SUM(td.quantity * (td.sell_price_at_sale - td.buy_price_at_sale)), 0.0) AS laba_bersih
FROM transactions t
LEFT JOIN transaction_details td ON t.id = td.transaction_id
WHERE DATE(t.created_at) = DATE('now', 'localtime');
```

**B. Tren Penjualan Hari Ini (Grafik Berdasarkan Jam)**
Mengelompokkan total penjualan per jam untuk visualisasi.
```sql
SELECT 
    STRFTIME('%H:00', t.created_at) AS jam,
    SUM(t.total_amount) AS total_omzet
FROM transactions t
WHERE DATE(t.created_at) = DATE('now', 'localtime')
GROUP BY jam
ORDER BY jam ASC;
```

**C. Menampilkan 5 Produk Terlaris Hari Ini**
Mengidentifikasi 5 produk dengan akumulasi penjualan tertinggi khusus hari ini.
```sql
SELECT 
    p.name,
    SUM(td.quantity) AS total_terjual
FROM transaction_details td
JOIN products p ON td.product_id = p.id
JOIN transactions t ON td.transaction_id = t.id
WHERE DATE(t.created_at) = DATE('now', 'localtime')
GROUP BY p.id
ORDER BY total_terjual DESC
LIMIT 5;
```

**D. Peringatan Stok Menipis (Widget Summary)**
Mengambil 3 produk dengan stok paling sedikit.
```sql
SELECT name, stock 
FROM products 
ORDER BY stock ASC 
LIMIT 3;
```

**E. Aksi "Lihat Semua Produk" dari Alert Stok**
```sql
SELECT id, sku, name, stock, buy_price, sell_price, image_path 
FROM products 
ORDER BY stock ASC;
```

### 3.2. Modul Transaksi (Layar Kasir & Keranjang)

**A. Pencarian Produk Berdasarkan Teks & SKU**
```sql
SELECT * FROM products 
WHERE sku = ? OR name LIKE ? 
LIMIT 20;
```

**B. Filter Berdasarkan Kategori**
```sql
SELECT p.* FROM products p
JOIN categories c ON p.category_id = c.id
WHERE c.name = ? 
ORDER BY p.name ASC;
```

### 3.3. Modul Laporan & Analitik

**A. Tab Keuangan (Filter Berdasarkan Waktu)**
```sql
SELECT 
    COALESCE(SUM(t.total_amount), 0.0) AS total_pendapatan,
    COALESCE(SUM(td.quantity * td.buy_price_at_sale), 0.0) AS total_hpp,
    COALESCE(SUM(td.quantity * (td.sell_price_at_sale - td.buy_price_at_sale)), 0.0) AS total_keuntungan
FROM transactions t
JOIN transaction_details td ON t.id = td.transaction_id
WHERE t.created_at BETWEEN ? AND ?;
```

**B. Tab SDM (Kinerja Operasional Kasir)**
```sql
SELECT 
    u.username,
    COUNT(t.id) AS total_transaksi_ditangani,
    SUM(t.total_amount) AS total_nominal_penjualan
FROM transactions t
JOIN shifts s ON t.shift_id = s.id
JOIN users u ON s.user_id = u.id
GROUP BY u.id
ORDER BY total_nominal_penjualan DESC;
```

**C. Tab Pelanggan**
```sql
SELECT 
    (SELECT COUNT(*) FROM customers) AS total_pelanggan,
    COALESCE(AVG(total_amount), 0.0) AS rata_rata_transaksi
FROM transactions;
```

**D. Tab X/Z Report (Validasi Saldo Sebelum Tutup Shift)**
```sql
SELECT 
    s.starting_cash,
    COALESCE(SUM(t.total_amount), 0.0) AS total_penjualan_tunai,
    (s.starting_cash + COALESCE(SUM(t.total_amount), 0.0)) AS ekspektasi_uang_fisik
FROM shifts s
LEFT JOIN transactions t ON t.shift_id = s.id AND t.payment_method = 'cash'
WHERE s.id = ? AND s.status = 'open';
```

---

## Sinkronisasi Data & Integritas
1. **Soft Delete**: Produk menggunakan `is_active = 0` alih-alih dihapus permanen agar riwayat transaksi tetap valid.
2. **Transaction Void**: Transaksi yang dibatalkan hanya berubah status menjadi `void`, saldo tidak dihitung dalam laporan keuangan namun tetap ada dalam riwayat audit.
3. **Singleton Store Settings**: Tabel `store_settings` hanya diizinkan memiliki 1 baris untuk konsistensi identitas toko di seluruh aplikasi.
