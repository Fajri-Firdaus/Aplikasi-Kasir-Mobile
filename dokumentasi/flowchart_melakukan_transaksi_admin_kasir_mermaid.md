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