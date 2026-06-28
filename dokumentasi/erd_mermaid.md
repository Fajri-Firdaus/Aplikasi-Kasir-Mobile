erDiagram

    USERS {
        INTEGER id PK
        TEXT full_name
        TEXT email
        TEXT username
        TEXT password
        TEXT role
        TIMESTAMP created_at
    }

    CATEGORIES {
        INTEGER id PK
        TEXT name
    }

    PRODUCTS {
        INTEGER id PK
        TEXT sku
        TEXT name
        INTEGER category_id FK
        REAL buy_price
        REAL sell_price
        INTEGER stock
        TEXT image_path
        INTEGER is_active
    }

    CUSTOMERS {
        INTEGER id PK
        TEXT name
        TEXT phone
        TIMESTAMP created_at
    }

    STORE_SETTINGS {
        INTEGER id PK
        TEXT store_name
        TEXT store_address
        TEXT store_phone
        TEXT receipt_footer
        TIMESTAMP updated_at
    }

    SHIFTS {
        INTEGER id PK
        INTEGER user_id FK
        TIMESTAMP start_time
        TIMESTAMP end_time
        REAL starting_cash
        REAL ending_cash
        TEXT status
    }

    TRANSACTIONS {
        INTEGER id PK
        INTEGER shift_id FK
        INTEGER customer_id FK
        REAL total_amount
        TEXT payment_method
        REAL cash_received
        TEXT status
        TIMESTAMP created_at
    }

    TRANSACTION_DETAILS {
        INTEGER id PK
        INTEGER transaction_id FK
        INTEGER product_id FK
        INTEGER quantity
        REAL buy_price_at_sale
        REAL sell_price_at_sale
    }

    USERS ||--o{ SHIFTS : manages

    SHIFTS ||--o{ TRANSACTIONS : contains

    CUSTOMERS ||--o{ TRANSACTIONS : makes

    CATEGORIES ||--o{ PRODUCTS : categorizes

    TRANSACTIONS ||--o{ TRANSACTION_DETAILS : has

    PRODUCTS ||--o{ TRANSACTION_DETAILS : sold_in