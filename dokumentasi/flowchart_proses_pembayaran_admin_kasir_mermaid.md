flowchart TD

    A([Mulai])

    B[Tampilkan Total Belanja]

    C[Pilih Metode Pembayaran]

    D[Input Uang Diterima]

    E{Pembayaran Cukup?}

    F[Hitung Kembalian]

    G[Simpan Transaksi]

    H[Cetak Struk]

    I([Selesai])

    A --> B

    B --> C

    C --> D

    D --> E

    E -- Tidak --> D

    E -- Ya --> F

    F --> G

    G --> H

    H --> I