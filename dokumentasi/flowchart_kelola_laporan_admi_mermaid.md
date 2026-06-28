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