USE shop;

-- Основная таблица на движке MergeTree
-- Одна строка = одна позиция заказа (денормализованная структура)
DROP TABLE IF EXISTS orders_flat;

CREATE TABLE orders_flat (
    order_date       Date,
    order_datetime   DateTime,
    order_id         UInt64,
    customer_id      UInt64,
    customer_name    String,
    customer_email   LowCardinality(String),
    region           LowCardinality(String),
    product_id       UInt64,
    product_name     String,
    category         LowCardinality(String),
    quantity         UInt32,
    price            Decimal(12,2),
    line_total       Decimal(12,2),
    order_status     LowCardinality(String)
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(order_date)
ORDER BY (category, toStartOfHour(order_datetime), order_status)
SETTINGS index_granularity = 8192;

-- Комментарий: ORDER BY выбран для оптимизации типичных аналитических запросов:
-- - фильтрация по категории
-- - временные агрегации по часам
-- - фильтрация по статусу заказа