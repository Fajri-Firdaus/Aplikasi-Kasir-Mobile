# SQLite Database Schema - Mobile POS (Multi-Tenant)

Dokumen ini mencatat skema faktual database SQLite pada aplikasi **Mobile POS Flutter** (`local_database_service.dart`). Database ini menggunakan arsitektur **Shared Database, Shared Schema** berbasis `store_id` (*Multi-Tenancy*) dengan dukungan *Soft Delete* (`is_active`).

## Database Name: `mobile_pos.db`
**Version:** 1

---

## 1. Tabel Master Data

### 1.1 `stores`
Entitas toko/tenant utama. Setiap Admin memiliki 1 unit toko yang terdaftar.
| Kolom | Tipe Data | Constraint | Deskripsi |
|-------|-----------|------------|-----------|
| `id` | TEXT | PRIMARY KEY | ID unik Toko (String UUID / Timestamp) |
| `owner_id` | TEXT | NOT NULL | User ID pemilik toko (Admin) |
| `store_name` | TEXT | NOT NULL | Nama Toko |
| `store_address` | TEXT | | Alamat Toko |
| `store_phone` | TEXT | | Nomor telepon Toko |
| `receipt_footer`| TEXT | | Pesan di bawah struk belanja |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Tanggal pembuatan toko |

### 1.2 `users`
Data kasir dan admin aplikasi per toko.
| Kolom | Tipe Data | Constraint | Deskripsi |
|-------|-----------|------------|-----------|
| `id` | TEXT | PRIMARY KEY | ID unik pengguna |
| `full_name` | TEXT | | Nama lengkap pengguna |
| `email` | TEXT | UNIQUE | Email pengguna (Forgot password / Sign up) |
| `username` | TEXT | NOT NULL UNIQUE | Username login |
| `password` | TEXT | NOT NULL | Password |
| `role` | TEXT | NOT NULL DEFAULT 'cashier' | `'admin'` atau `'cashier'` |
| `admin_id` | TEXT | | ID Admin pengampu (untuk kasir) |
| `store_id` | TEXT | FK -> `stores(id)` | Identifikasi toko tempat user bertugas |
| `is_active` | INTEGER | DEFAULT 1 | 1=Aktif, 0=Dinonaktifkan (*Soft Delete*) |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Waktu pendaftaran |

### 1.3 `categories`
Katalog kategori produk terisolasi per toko.
| Kolom | Tipe Data | Constraint | Deskripsi |
|-------|-----------|------------|-----------|
| `id` | TEXT | PRIMARY KEY | ID unik kategori |
| `store_id` | TEXT | NOT NULL, FK -> `stores(id)` | Mengikat kategori ke toko tertentu |
| `name` | TEXT | NOT NULL | Nama kategori |
| `is_active` | INTEGER | DEFAULT 1 | 1=Aktif, 0=Soft Deleted |
| *Composite* | UNIQUE | `UNIQUE(store_id, name)` | Nama kategori unik di dalam toko yang sama |

### 1.4 `products`
Katalog produk per toko. Mendukung pencarian SKU/barcode dan nama.
| Kolom | Tipe Data | Constraint | Deskripsi |
|-------|-----------|------------|-----------|
| `id` | TEXT | PRIMARY KEY | ID unik produk |
| `store_id` | TEXT | NOT NULL, FK -> `stores(id)` | Mengikat produk ke toko tertentu |
| `sku` | TEXT | | Kode unik SKU / Barcode |
| `name` | TEXT | NOT NULL | Nama produk |
| `category_id` | TEXT | FK -> `categories(id)` | Kategori produk |
| `buy_price` | REAL | NOT NULL DEFAULT 0.0 | Harga modal (HPP) saat ini |
| `sell_price` | REAL | NOT NULL DEFAULT 0.0 | Harga jual saat ini |
| `stock` | INTEGER | DEFAULT 0 | Jumlah stok tersedia |
| `image_path` | TEXT | | Lokasi file gambar produk |
| `is_active` | INTEGER | DEFAULT 1 | 1=Aktif, 0=Soft Deleted |
| *Composite* | UNIQUE | `UNIQUE(store_id, sku)` | SKU unik di dalam toko yang sama |

### 1.5 `customers`
Data pelanggan tetap per toko untuk analisis loyalitas.
| Kolom | Tipe Data | Constraint | Deskripsi |
|-------|-----------|------------|-----------|
| `id` | TEXT | PRIMARY KEY | ID unik pelanggan |
| `store_id` | TEXT | NOT NULL, FK -> `stores(id)` | Toko pemilik pelanggan |
| `name` | TEXT | NOT NULL | Nama pelanggan |
| `phone` | TEXT | | Nomor telepon |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Waktu terdaftar |

### 1.6 `store_settings` (Legacy Fallback Singleton)
Digunakan untuk kompatibilitas fallback singleton lokal.
| Kolom | Tipe Data | Constraint | Deskripsi |
|-------|-----------|------------|-----------|
| `id` | INTEGER | PRIMARY KEY CHECK (id=1) | Singleton (Hanya 1 baris) |
| `store_name` | TEXT | NOT NULL | Nama toko fallback |
| `store_address` | TEXT | | Alamat toko fallback |
| `store_phone` | TEXT | | Telepon toko fallback |
| `receipt_footer`| TEXT | | Pesan footer struk fallback |
| `updated_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Waktu pembaruan |

---

## 2. Tabel Operasional (Shift & Transaksi)

### 2.1 `shifts`
Encapsulation sesi kerja kasir untuk audit saldo laci kasir (Laporan X/Z).
| Kolom | Tipe Data | Constraint | Deskripsi |
|-------|-----------|------------|-----------|
| `id` | TEXT | PRIMARY KEY | ID unik shift |
| `store_id` | TEXT | NOT NULL, FK -> `stores(id)` | Toko tempat shift berlangsung |
| `user_id` | TEXT | NOT NULL, FK -> `users(id)` | Kasir yang bertugas |
| `start_time` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Waktu buka shift |
| `end_time` | TIMESTAMP | | Waktu tutup shift |
| `starting_cash`| REAL | DEFAULT 0.0 | Saldo kas awal modal laci |
| `ending_cash` | REAL | DEFAULT 0.0 | Setoran saldo fisik akhir laci |
| `status` | TEXT | CHECK (status IN ('open','closed')) | Status shift (`'open'`/`'closed'`) |
| `shift_number` | INTEGER | DEFAULT 1 | Urutan shift kasir pada hari tersebut |

### 2.2 `transactions`
Header transaksi penjualan. Mendukung pembatalan (*void*).
| Kolom | Tipe Data | Constraint | Deskripsi |
|-------|-----------|------------|-----------|
| `id` | TEXT | PRIMARY KEY | ID unik transaksi |
| `store_id` | TEXT | NOT NULL, FK -> `stores(id)` | Toko tempat transaksi dibuat |
| `shift_id` | TEXT | NOT NULL, FK -> `shifts(id)` | Sesi shift kasir saat transaksi |
| `customer_id` | TEXT | FK -> `customers(id)` | ID Pelanggan (Bisa NULL) |
| `total_amount` | REAL | NOT NULL | Total nominal belanja |
| `payment_method`| TEXT | NOT NULL | `'cash'`, `'qris'`, dll |
| `cash_received` | REAL | DEFAULT 0.0 | Uang tunai yang diterima |
| `status` | TEXT | CHECK (status IN ('completed','void'))| Status transaksi (`'completed'`/`'void'`) |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Waktu transaksi dibuat |

### 2.3 `transaction_details`
Detail item produk yang dibeli per transaksi. Menyimpan snapshot harga saat transaksi.
| Kolom | Tipe Data | Constraint | Deskripsi |
|-------|-----------|------------|-----------|
| `id` | TEXT | PRIMARY KEY | ID detail transaksi |
| `transaction_id`| TEXT | NOT NULL, FK -> `transactions(id)` | Relasi ke header transaksi |
| `product_id` | TEXT | NOT NULL, FK -> `products(id)` | Relasi ke produk |
| `quantity` | INTEGER | NOT NULL | Jumlah item dibeli |
| `buy_price_at_sale` | REAL | NOT NULL | Snapshot HPP/Modal saat penjualan |
| `sell_price_at_sale`| REAL | NOT NULL | Snapshot Harga Jual saat penjualan |

---

## 3. Indeks Database (Indexes)

Untuk menjaga performa query SQLite pada multi-tenant:
- `CREATE INDEX idx_products_store ON products(store_id);`
- `CREATE INDEX idx_transactions_store ON transactions(store_id);`
- `CREATE INDEX idx_shifts_store ON shifts(store_id);`
- `CREATE INDEX idx_users_store ON users(store_id);`

---

## 4. Kueri Produksi SQLite (Faktual Codebase)

### 4.1 Modul Laporan Keuangan (Omzet, HPP, Laba Bersih)
```sql
SELECT 
  t.id,
  t.created_at,
  t.status,
  t.total_amount,
  COALESCE(SUM(td.quantity * td.buy_price_at_sale), 0.0) AS total_hpp
FROM transactions t
LEFT JOIN transaction_details td ON t.id = td.transaction_id
WHERE t.store_id = ? AND t.status != 'void'
GROUP BY t.id;
```

### 4.2 Modul Produk Terlaris (Top Products)
```sql
SELECT 
  p.id AS product_id,
  p.name,
  td.quantity,
  td.sell_price_at_sale,
  t.created_at,
  t.status
FROM products p
LEFT JOIN transaction_details td ON p.id = td.product_id
LEFT JOIN transactions t ON td.transaction_id = t.id
WHERE p.store_id = ? AND p.is_active = 1;
```

### 4.3 Peringatan Stok Menipis (Low Stock Alert)
```sql
SELECT p.name, p.stock, COALESCE(c.name, 'Tanpa Kategori') as category_name
FROM products p
LEFT JOIN categories c ON p.category_id = c.id
WHERE p.store_id = ? AND p.is_active = 1 AND p.stock <= 10
ORDER BY p.stock ASC 
LIMIT 10;
```

### 4.4 Kinerja Kasir (Staff Performance)
```sql
SELECT 
  COALESCE(u.full_name, u.username, 'Kasir') as username,
  COUNT(DISTINCT t.id) as total_txns,
  COALESCE(SUM(t.total_amount), 0.0) as total_sales
FROM transactions t
JOIN shifts s ON t.shift_id = s.id
JOIN users u ON s.user_id = u.id
WHERE t.store_id = ? AND t.status != 'void'
GROUP BY u.id
ORDER BY total_sales DESC;
```

### 4.5 Laporan X/Z Shift Kasir
```sql
SELECT COALESCE(SUM(total_amount), 0.0) AS total
FROM transactions
WHERE shift_id = ? AND payment_method = 'cash' AND status != 'void';
```

---

## 5. Sinkronisasi & Integritas Data Multi-Tenant
1. **Pemisahan `store_id` Mandatori:** Setiap repositori menjamin seluruh pembacaan/penulisan menyertakan filter `store_id`.
2. **Soft Delete Standard:** Penonaktifan produk/kategori/kasir menggunakan `is_active = 0` sehingga relasi transaksi masa lalu tidak rusak (*foreign key integrity*).
3. **Void Restoration:** Pembatalan transaksi (`status = 'void'`) mengembalikan kuantitas stok ke tabel `products` secara otomatis melalui SQLite Transaction.

