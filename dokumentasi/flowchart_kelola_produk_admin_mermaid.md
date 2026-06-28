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