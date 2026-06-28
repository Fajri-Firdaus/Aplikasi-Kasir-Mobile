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