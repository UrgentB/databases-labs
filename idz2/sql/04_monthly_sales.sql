USE shop;

-- Агрегирующая таблица на SummingMergeTree
DROP TABLE IF EXISTS monthly_sales;

CREATE TABLE monthly_sales (
    month          Date,
    category       LowCardinality(String),
    region         LowCardinality(String),
    total_quantity AggregateFunction(sum, UInt64),
    total_revenue  AggregateFunction(sum, Decimal(12,2)),
    order_count    AggregateFunction(count, UInt64)
) ENGINE = SummingMergeTree()
ORDER BY (month, category, region);

-- Материализованное представление для автоматического обновления агрегатов
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