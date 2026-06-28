# FLOWCHART SISTEM APLIKASI MOBILE POS

---

FLOWCHART SISTEM APLIKASI MOBILE POS

├── A. FLOWCHART ADMIN / OWNER
│   ├── Flowchart Utama Admin
│   ├── Flowchart Kelola Produk
│   ├── Flowchart Kelola Stok
│   ├── Flowchart Kelola Pengguna
│   ├── Flowchart Kelola Laporan
│   ├── Flowchart Kelola Pengaturan
│   ├── Flowchart Melakukan Transaksi
│   ├── Flowchart Cari Produk
│   ├── Flowchart Kelola Keranjang
│   └── Flowchart Proses Pembayaran
│
└── B. FLOWCHART KASIR
    ├── Flowchart Utama Kasir
    ├── Flowchart Melakukan Transaksi
    ├── Flowchart Cari Produk
    ├── Flowchart Kelola Keranjang
    └── Flowchart Proses Pembayaran

---


## Keterangan Hak Akses

### Admin / Owner
Memiliki akses terhadap:
- Dashboard
- Kelola Produk
- Kelola Stok
- Kelola Pengguna
- Kelola Laporan
- Kelola Pengaturan
- Melakukan Transaksi
- Cari Produk
- Kelola Keranjang
- Proses Pembayaran
- Logout

### Kasir
Memiliki akses terhadap:
- Dashboard
- Melakukan Transaksi
- Cari Produk
- Kelola Keranjang
- Proses Pembayaran
- Logout

---


## Keterangan Flowchart Hak Akses

### A. FLOWCHART ADMIN / OWNER
#### 1. Flowchart Utama Admin
#### 2. Flowchart Kelola Produk
#### 3. Flowchart Kelola Stok
#### 4. Flowchart Kelola Pengguna
#### 5. Flowchart Kelola Laporan
#### 6. Flowchart Kelola Pengaturan
#### 7. Flowchart Melakukan Transaksi
#### 8. Flowchart Cari Produk
#### 9. Flowchart Kelola Keranjang
#### 10. Flowchart Proses Pembayaran

### B. FLOWCHART KASIR
#### 1. Flowchart Utama Kasir
#### 2. Flowchart Melakukan Transaksi
#### 3. Flowchart Cari Produk
#### 4. Flowchart Kelola Keranjang
#### 5. Flowchart Proses Pembayaran

---

## 1. Flowchart Utama Admin / Owner

```mermaid
flowchart TD

    A([Mulai])

    B[Login]

    C{Login Valid?}

    D[Dashboard]

    E{Pilih Menu}

    F[Kelola Produk]
    G[Kelola Stok]
    H[Kelola Pengguna]
    I[Kelola Laporan]
    J[Kelola Pengaturan]
    K[Melakukan Transaksi]

    L[Logout]

    M([Selesai])

    A --> B
    B --> C

    C -- Tidak --> B
    C -- Ya --> D

    D --> E

    E --> F
    E --> G
    E --> H
    E --> I
    E --> J
    E --> K

    F --> D
    G --> D
    H --> D
    I --> D
    J --> D
    K --> D

    D --> L

    L --> M
```

---

## 2. Flowchart Kelola Produk

```mermaid
flowchart TD

    A([Mulai])

    B[Masuk Menu Produk]

    C{Pilih Aksi}

    D[Tambah Produk]
    E[Cari Produk]
    F[Edit Produk]
    G[Hapus Produk]

    H[Isi Data Produk]

    I{Data Valid?}

    J[Simpan Produk]

    K[Pilih Produk]

    L[Ubah Data]

    M[Simpan Perubahan]

    N{Yakin Hapus?}

    O[Hapus Produk]

    P([Selesai])

    A --> B

    B --> C

    C --> D
    C --> E
    C --> F
    C --> G

    D --> H
    H --> I

    I -- Tidak --> H
    I -- Ya --> J

    E --> K

    F --> K
    K --> L
    L --> M

    G --> K
    K --> N

    N -- Ya --> O
    N -- Tidak --> B

    J --> P
    M --> P
    O --> P
```

---

## 3. Flowchart Kelola Stok

```mermaid
flowchart TD

    A([Mulai])

    B[Masuk Menu Stok]

    C[Cari Produk]

    D[Pilih Produk]

    E{Pilih Aksi}

    F[Tambah Stok]

    G[Kurangi Stok]

    H[Penyesuaian Stok]

    I[Input Jumlah]

    J[Simpan Perubahan]

    K[Update Stok]

    L([Selesai])

    A --> B
    B --> C
    C --> D

    D --> E

    E --> F
    E --> G
    E --> H

    F --> I
    G --> I
    H --> I

    I --> J
    J --> K

    K --> L
```

---

## 4. Flowchart Kelola Pengguna

```mermaid
flowchart TD

    A([Mulai])

    B[Masuk Menu Pengguna]

    C{Pilih Aksi}

    D[Tambah Pengguna]

    E[Edit Pengguna]

    F[Nonaktifkan Pengguna]

    G[Isi Data Pengguna]

    H{Data Valid?}

    I[Simpan Pengguna]

    J[Pilih Pengguna]

    K[Ubah Data]

    L[Simpan Perubahan]

    M{Konfirmasi Nonaktifkan?}

    N[Nonaktifkan Akun]

    O([Selesai])

    A --> B

    B --> C

    C --> D
    C --> E
    C --> F

    D --> G
    G --> H

    H -- Tidak --> G
    H -- Ya --> I

    E --> J
    J --> K
    K --> L

    F --> J
    J --> M

    M -- Ya --> N
    M -- Tidak --> B

    I --> O
    L --> O
    N --> O
```

---

## 5. Flowchart Kelola Laporan

```mermaid
flowchart TD

    A([Mulai])

    B[Masuk Menu Laporan]

    C[Pilih Rentang Tanggal]

    D{Pilih Jenis Laporan}

    E[Keuangan]
    F[Produk]
    G[Inventaris]
    H[SDM]
    I[Pelanggan]
    J[X/Z Report]

    K[Tampilkan Laporan]

    L{Export?}

    M[Export PDF / Excel]

    N([Selesai])

    A --> B
    B --> C
    C --> D

    D --> E
    D --> F
    D --> G
    D --> H
    D --> I
    D --> J

    E --> K
    F --> K
    G --> K
    H --> K
    I --> K
    J --> K

    K --> L

    L -- Ya --> M
    L -- Tidak --> N

    M --> N
```

---

## 6. Flowchart Kelola Pengaturan

```mermaid
flowchart TD

    A([Mulai])

    B[Masuk Menu Pengaturan]

    C{Pilih Pengaturan}

    D[Profil Toko]
    E[Printer]
    F[Perangkat Kasir]
    G[Informasi Aplikasi]

    H[Ubah Konfigurasi]

    I[Simpan Perubahan]

    J([Selesai])

    A --> B

    B --> C

    C --> D
    C --> E
    C --> F
    C --> G

    D --> H
    E --> H
    F --> H

    H --> I

    I --> J

    G --> J
```

---

## 7. Flowchart Melakukan Transaksi

```mermaid
flowchart TD

    A([Mulai])

    B[Masuk Menu Transaksi]

    C[Cari Produk]

    D[Pilih Produk]

    E[Tambah ke Keranjang]

    F{Tambah Produk Lagi?}

    G[Kelola Keranjang]

    H[Proses Pembayaran]

    I([Selesai])

    A --> B

    B --> C

    C --> D

    D --> E

    E --> F

    F -- Ya --> C

    F -- Tidak --> G

    G --> H

    H --> I
```

---

## 8. Flowchart Cari Produk

```mermaid
flowchart TD

    A([Mulai])

    B[Masuk Pencarian Produk]

    C{Metode Pencarian}

    D[Cari Berdasarkan Nama]

    E[Cari Berdasarkan SKU]

    F[Filter Berdasarkan Kategori]

    G[Tampilkan Hasil]

    H[Pilih Produk]

    I([Selesai])

    A --> B

    B --> C

    C --> D
    C --> E
    C --> F

    D --> G
    E --> G
    F --> G

    G --> H

    H --> I
```

---

## 9. Flowchart Kelola Keranjang

```mermaid
flowchart TD

    A([Mulai])

    B[Buka Keranjang]

    C{Pilih Aksi}

    D[Tambah Quantity]

    E[Kurangi Quantity]

    F[Hapus Produk]

    G[Kosongkan Keranjang]

    H[Update Total Belanja]

    I{Lanjut Pembayaran?}

    J[Proses Pembayaran]

    K([Selesai])

    A --> B

    B --> C

    C --> D
    C --> E
    C --> F
    C --> G

    D --> H
    E --> H
    F --> H
    G --> H

    H --> I

    I -- Tidak --> C

    I -- Ya --> J

    J --> K
```

---

## 10. Flowchart Proses Pembayaran

```mermaid
flowchart TD

    A([Mulai])

    B[Tampilkan Total Belanja]

    C[Pilih Metode Pembayaran]

    D[Input Uang Diterima]

    E{Pembayaran Cukup?}

    F[Hitung Kembalian]

    G[Simpan Transaksi]

    H[Cetak Struk]

    I([Selesai])

    A --> B

    B --> C

    C --> D

    D --> E

    E -- Tidak --> D

    E -- Ya --> F

    F --> G

    G --> H

    H --> I
```

---

## 11. Flowchart Utama Kasir
```mermaid
flowchart TD

    A([Mulai])

    B[Login]

    C{Login Valid?}

    D[Dashboard]

    E{Pilih Menu}

    F[Melakukan Transaksi]

    G[Logout]

    H([Selesai])

    A --> B

    B --> C

    C -- Tidak --> B

    C -- Ya --> D

    D --> E

    E --> F

    F --> D

    D --> G

    G --> H
```