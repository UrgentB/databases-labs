-- =====================================================
-- Инициализация базы данных ClickHouse
-- =====================================================

-- 1. Создание базы данных
CREATE DATABASE IF NOT EXISTS shop;
USE shop;

-- 2. Создание основной таблицы
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
    quantity         UInt32,                    -- ← UInt32
    price            Decimal(12,2),
    line_total       Decimal(12,2),
    order_status     LowCardinality(String)
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(order_date)
ORDER BY (category, toStartOfHour(order_datetime), order_status);

-- 3. Создание таблицы с TTL
DROP TABLE IF EXISTS orders_ttl;

CREATE TABLE orders_ttl AS orders_flat
ENGINE = MergeTree()
PARTITION BY toYYYYMM(order_date)
ORDER BY (category, toStartOfHour(order_datetime), order_status)
TTL order_date + INTERVAL 90 DAY DELETE;

-- 4. Создание SummingMergeTree таблицы (исправленные типы)
DROP TABLE IF EXISTS monthly_sales;

CREATE TABLE monthly_sales (
    month          Date,
    category       LowCardinality(String),
    region         LowCardinality(String),
    total_quantity AggregateFunction(sum, UInt32),     -- ← UInt32, соответствует quantity
    total_revenue  AggregateFunction(sum, Decimal(12,2)),
    order_count    AggregateFunction(count, UInt64)
) ENGINE = SummingMergeTree()
ORDER BY (month, category, region);

-- 5. Создание материализованного представления
DROP TABLE IF EXISTS monthly_sales_mv;

CREATE MATERIALIZED VIEW monthly_sales_mv
TO monthly_sales
AS SELECT
    toStartOfMonth(order_date) AS month,
    category,
    region,
    sumState(quantity) AS total_quantity,
    sumState(line_total) AS total_revenue,
    countState(order_id) AS order_count
FROM orders_flat
GROUP BY month, category, region;

-- 6. Проверка создания
SELECT 
    'Database initialized!' AS status,
    (SELECT count() FROM system.tables WHERE database = 'shop') AS tables_count;

SHOW TABLES;