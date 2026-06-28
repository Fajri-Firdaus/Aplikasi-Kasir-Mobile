flowchart LR

    Admin["Admin / Owner"]

    subgraph POS["APLIKASI MOBILE POS"]
        direction TB

        Pengaturan["Kelola Pengaturan"]
        Laporan["Kelola Laporan"]
        Pengguna["Kelola Pengguna"]
        Logout["Logout"]
        Stok["Kelola Stok"]
        Produk["Kelola Produk"]
        Dashboard["Dashboard"]
        Login["Login"]

        Transaksi["Melakukan Transaksi"]

        CariProduk["Cari Produk"]
        Keranjang["Kelola Keranjang"]
        Pembayaran["Proses Pembayaran"]

        Transaksi -.-> CariProduk
        Transaksi -.-> Keranjang
        Transaksi -.-> Pembayaran
    end

    Kasir["Kasir"]

    Admin --> Pengaturan
    Admin --> Laporan
    Admin --> Pengguna
    Admin --> Logout
    Admin --> Stok
    Admin --> Produk
    Admin --> Dashboard
    Admin --> Login
    Admin --> Transaksi

    Kasir --> Logout
    Kasir --> Dashboard
    Kasir --> Login
    Kasir --> Transaksi