-- =====================================================
-- ЗАПРОС 1: Топ-10 товаров по выручке
-- =====================================================
-- Цель: Определить самые продаваемые товары для анализа ассортимента
-- =====================================================

SELECT
    product_name,
    category,
    sum(quantity) AS total_quantity,
    round(sum(line_total), 2) AS total_revenue,
    round(avg(price), 2) AS avg_price,
    count(DISTINCT order_id) AS order_count
FROM orders_flat
GROUP BY product_name, category
ORDER BY total_revenue DESC
LIMIT 10;