flowchart TD

    A([Mulai])

    B[Buka Keranjang]

    C{Pilih Aksi}

    D[Tambah Quantity]

    E[Kurangi Quantity]

    F[Hapus Produk]

    G[Kosongkan Keranjang]

    H[Update Total Belanja]

    I{Lanjut Pembayaran?}

    J[Proses Pembayaran]

    K([Selesai])

    A --> B

    B --> C

    C --> D
    C --> E
    C --> F
    C --> G

    D --> H
    E --> H
    F --> H
    G --> H

    H --> I

    I -- Tidak --> C

    I -- Ya --> J

    J --> K