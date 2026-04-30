-- =====================================================
-- ЗАПРОС 2: Ежемесячная динамика продаж по категориям
-- =====================================================
-- Цель: Анализ сезонности и трендов по категориям
-- =====================================================

SELECT
    toStartOfMonth(order_date) AS month,
    category,
    sum(quantity) AS total_quantity,
    round(sum(line_total), 2) AS total_revenue,
    count(DISTINCT order_id) AS order_count,
    round(avg(line_total), 2) AS avg_order_value
FROM orders_flat
GROUP BY month, category
ORDER BY month DESC, total_revenue DESC
LIMIT 20;