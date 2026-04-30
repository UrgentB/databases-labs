-- =====================================================
-- ЗАПРОС 4: Поиск клиента по подстроке email
-- =====================================================
-- Цель: Демонстрация поиска с LIKE (до индекса)
-- =====================================================

SELECT
    customer_id,
    customer_name,
    customer_email,
    count(DISTINCT order_id) AS order_count,
    round(sum(line_total), 2) AS total_spent,
    round(avg(line_total), 2) AS avg_order_value
FROM orders_flat
WHERE customer_email LIKE '%gmail%'
GROUP BY customer_id, customer_name, customer_email
ORDER BY total_spent DESC
LIMIT 20;