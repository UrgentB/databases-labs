-- =====================================================
-- ЗАПРОС 6: Статистика таблиц и сжатия
-- =====================================================
-- Цель: Показать размеры таблиц и эффективность сжатия
-- =====================================================

-- Статистика таблиц
SELECT
    'orders_flat' AS table_name,
    formatReadableQuantity(count()) AS rows,
    formatReadableQuantity(count(DISTINCT order_id)) AS orders,
    formatReadableQuantity(count(DISTINCT customer_id)) AS customers,
    formatReadableQuantity(count(DISTINCT product_id)) AS products,
    formatReadableSize(sum(bytes)) AS total_size,
    round(sum(bytes) / count(), 2) AS bytes_per_row
FROM orders_flat
CROSS JOIN (SELECT sum(bytes) AS bytes FROM system.parts WHERE table = 'orders_flat' AND active = 1)

UNION ALL

SELECT
    'monthly_sales' AS table_name,
    formatReadableQuantity(count()),
    formatReadableQuantity(0),
    formatReadableQuantity(0),
    formatReadableQuantity(count(DISTINCT category)),
    formatReadableSize(sum(bytes)),
    0
FROM monthly_sales
CROSS JOIN (SELECT sum(bytes) AS bytes FROM system.parts WHERE table = 'monthly_sales' AND active = 1)

UNION ALL

SELECT
    'orders_ttl' AS table_name,
    formatReadableQuantity(count()),
    formatReadableQuantity(count(DISTINCT order_id)),
    formatReadableQuantity(count(DISTINCT customer_id)),
    formatReadableQuantity(count(DISTINCT product_id)),
    formatReadableSize(sum(bytes)),
    0
FROM orders_ttl
CROSS JOIN (SELECT sum(bytes) AS bytes FROM system.parts WHERE table = 'orders_ttl' AND active = 1);

-- Статистика сжатия по колонкам
SELECT
    'orders_flat compression' AS metric,
    column,
    type,
    formatReadableSize(sum(column_data_compressed_bytes)) AS compressed,
    formatReadableSize(sum(column_data_uncompressed_bytes)) AS uncompressed,
    round(sum(column_data_uncompressed_bytes) / sum(column_data_compressed_bytes), 2) AS ratio
FROM system.parts_columns
WHERE table = 'orders_flat' AND active
GROUP BY column, type
ORDER BY sum(column_data_uncompressed_bytes) DESC
LIMIT 10;