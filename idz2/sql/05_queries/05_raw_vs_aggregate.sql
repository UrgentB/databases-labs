-- =====================================================
-- ЗАПРОС 5: Сравнение raw-таблицы и SummingMergeTree
-- =====================================================
-- Цель: Показать разницу в производительности
-- =====================================================

-- Часть 1: Запрос к raw-таблице (orders_flat)
SELECT
    'RAW_TABLE' AS data_source,
    toStartOfMonth(order_date) AS month,
    category,
    region,
    sum(quantity) AS total_quantity,
    round(sum(line_total), 2) AS total_revenue,
    count(DISTINCT order_id) AS order_count
FROM orders_flat
WHERE order_date >= '2024-01-01'
GROUP BY month, category, region
ORDER BY month DESC, total_revenue DESC
LIMIT 10;

-- Часть 2: Запрос к агрегированной таблице (monthly_sales)
SELECT
    'AGGREGATED_TABLE' AS data_source,
    month,
    category,
    region,
    sumMerge(total_quantity) AS total_quantity,
    round(sumMerge(total_revenue), 2) AS total_revenue,
    countMerge(order_count) AS order_count
FROM monthly_sales
WHERE month >= '2024-01-01'
GROUP BY month, category, region
ORDER BY month DESC, total_revenue DESC
LIMIT 10;