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