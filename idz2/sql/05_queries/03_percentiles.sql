-- =====================================================
-- ЗАПРОС 3: Процентили стоимости заказа (p50, p95, p99)
-- =====================================================
-- Цель: Анализ распределения стоимости заказов
-- =====================================================

WITH order_totals AS (
    SELECT
        order_id,
        sum(line_total) AS order_total
    FROM orders_flat
    GROUP BY order_id
)
SELECT
    round(quantile(0.5)(order_total), 2) AS p50_median,
    round(quantile(0.95)(order_total), 2) AS p95,
    round(quantile(0.99)(order_total), 2) AS p99,
    round(min(order_total), 2) AS min_order,
    round(max(order_total), 2) AS max_order,
    round(avg(order_total), 2) AS avg_order,
    count(order_id) AS total_orders
FROM order_totals;