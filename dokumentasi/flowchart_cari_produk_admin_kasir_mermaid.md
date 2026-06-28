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