flowchart LR

    DEVELOPMENT --> LOGIN
    DEVELOPMENT --> HOME
    DEVELOPMENT --> TRANSAKSI
    DEVELOPMENT --> PRODUK
    DEVELOPMENT --> LAPORAN
    DEVELOPMENT --> PENGATURAN

    LOGIN --> LoginForm["Login"]
    LOGIN --> SignUpForm["Sign Up"]

    LoginForm --> Username1["Username"]
    LoginForm --> Password1["Password"]
    LoginForm --> ForgotPassword["Forgot Password"]

    SignUpForm --> Username2["Username"]
    SignUpForm --> Password2["Password"]
    SignUpForm --> ConfirmPassword["Confirm Password"]
    SignUpForm --> Terms["Terms and Conditions"]

    HOME --> MulaiTransaksi["Mulai Transaksi"]
    HOME --> RingkasanPerforma["Ringkasan Performa"]
    HOME --> JalanPintas["Jalan Pintas"]
    HOME --> TrenPenjualan["Tren Penjualan Hari Ini (Grafik)"]
    HOME --> ProdukTerlaris["Produk Terlaris"]
    HOME --> StokMenipis["Peringatan Stok Menipis"]
    HOME --> StatusShift["Status Shift"]

    JalanPintas --> TambahProdukShortcut["Tambah Produk"]
    JalanPintas --> CetakLaporanShortcut["Cetak Laporan"]

    RingkasanPerforma --> PenjualanHariIni["Penjualan Hari Ini"]
    RingkasanPerforma --> TotalTransaksi["Total Transaksi"]
    RingkasanPerforma --> LabaBersih["Laba Bersih"]

    TrenPenjualan --> GrafikJam["Grafik Penjualan Berdasarkan Jam"]

    ProdukTerlaris --> Top5Produk["5 Produk Terlaris Hari Ini"]

    StokMenipis --> Top3Stok["3 Stok Mulai Menipis"]
    StokMenipis --> LihatSemuaProduk["Lihat Semua Produk"]

    StatusShift --> MemulaiShift["Memulai Shift"]

    TRANSAKSI --> CariProduk["Pencarian Produk"]
    TRANSAKSI --> FilterKategori["Filter Berdasarkan Kategori"]
    TRANSAKSI --> Keranjang
    TRANSAKSI --> KosongkanKeranjang["Kosongkan Keranjang"]

    CariProduk --> CariSKU["Berdasarkan Teks & SKU"]
    FilterKategori --> SortStok["Sort Berdasarkan Stok"]

    Keranjang --> Pembayaran
    Keranjang --> TambahQty["Tambah Quantity"]
    Keranjang --> HapusBarang["Hapus Barang"]
    Keranjang --> HapusKeranjang["Hapus Isi Keranjang"]
    Keranjang --> TotalBelanja["Total Belanja"]
    Keranjang --> MetodePembayaran["Metode Pembayaran"]
    Keranjang --> UangDiterima["Uang Diterima"]

    PRODUK --> PencarianProduk["Pencarian"]
    PRODUK --> FilterProduk["Filter Berdasarkan Kategori"]
    PRODUK --> TambahProduk

    PencarianProduk --> CariProdukSKU["Berdasarkan Teks & SKU"]
    FilterProduk --> SortProdukStok["Sort Berdasarkan Stok"]

    TambahProduk --> Nama["Nama"]
    TambahProduk --> Kategori["Kategori"]
    TambahProduk --> HargaBeli["Harga Beli"]
    TambahProduk --> HargaJual["Harga Jual"]
    TambahProduk --> Stok["Stok"]
    TambahProduk --> Gambar["Gambar"]

    LAPORAN --> FilterWaktu["Filter Berdasarkan Waktu"]
    LAPORAN --> Export

    LAPORAN --> Keuangan["Tab Keuangan"]
    LAPORAN --> ProdukTab["Tab Produk"]
    LAPORAN --> Inventaris["Tab Inventaris"]
    LAPORAN --> SDM["Tab SDM"]
    LAPORAN --> Pelanggan["Tab Pelanggan"]
    LAPORAN --> XZReport["Tab X/Z Report"]

    Keuangan --> Pendapatan["Total Pendapatan"]
    Keuangan --> HPP["Total HPP"]
    Keuangan --> Keuntungan["Total Keuntungan"]

    ProdukTab --> PerformaProduk["Performa Produk"]
    Inventaris --> StokLaporan["Stok"]

    SDM --> KinerjaKasir["Kinerja Operasional Kasir"]

    Pelanggan --> TotalPelanggan["Total Pelanggan"]
    Pelanggan --> PelangganBaru["Pelanggan Baru"]
    Pelanggan --> RataTransaksi["Rata-rata Transaksi"]

    XZReport --> LaporanXZ["Laporan X & Z Report"]

    PENGATURAN --> ProfilPengguna["Profil Pengguna"]
    PENGATURAN --> ManajemenUser["Manajemen User"]
    PENGATURAN --> PengaturanToko["Pengaturan Toko"]
    PENGATURAN --> PrinterHardware["Printer & Hardware"]
    PENGATURAN --> TentangAplikasi["Tentang Aplikasi"]
    PENGATURAN --> Logout