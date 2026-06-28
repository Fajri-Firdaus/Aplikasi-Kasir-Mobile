flowchart TD

    A([Mulai])

    B[Login]

    C{Login Valid?}

    D[Dashboard]

    E{Pilih Menu}

    F[Melakukan Transaksi]

    G[Logout]

    H([Selesai])

    A --> B

    B --> C

    C -- Tidak --> B

    C -- Ya --> D

    D --> E

    E --> F

    F --> D

    D --> G

    G --> H