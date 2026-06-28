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