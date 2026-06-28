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

    K[Logout]

    L([Selesai])

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

    F --> D
    G --> D
    H --> D
    I --> D
    J --> D

    D --> K

    K --> L