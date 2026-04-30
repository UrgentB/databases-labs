-- Генерация категорий
INSERT INTO categories (name)
SELECT unnest(ARRAY[
    'Электроника', 'Одежда', 'Книги', 'Спорт', 'Игрушки', 
    'Мебель', 'Косметика', 'Продукты', 'Автотовары', 'Инструменты'
]);

-- Генерация продуктов (1000 уникальных)
INSERT INTO products (name, category_id, current_price)
SELECT 
    'Product_' || i,
    (random() * 9 + 1)::INT,
    (random() * 10000 + 100)::NUMERIC(10,2)
FROM generate_series(1, 1000) AS i;

-- Генерация клиентов (100k)
INSERT INTO customers (name, email, phone)
SELECT 
    'Customer_' || i,
    'customer_' || i || '@example.com',
    '+7' || LPAD((random() * 9999999999)::TEXT, 10, '0')
FROM generate_series(1, 100000) AS i;

-- Генерация адресов (по 1-3 на клиента)
INSERT INTO addresses (customer_id, address)
SELECT 
    c.customer_id,
    'Address_' || generate_series(1, (random() * 2 + 1)::INT) || '_for_customer_' || c.customer_id
FROM customers c;

-- Генерация заказов (1M строк)
INSERT INTO orders (order_id, customer_id, address_id, order_date, status, total_amount)
SELECT 
    i,
    (random() * 99999 + 1)::INT,
    b.address_id,
    CURRENT_DATE - (random() * 1095)::INT, -- за 3 года
    (ARRAY['pending', 'completed', 'cancelled', 'shipped'])[(random() * 3 + 1)::INT],
    0 -- временно
FROM generate_series(1, 1000000) AS i
CROSS JOIN LATERAL (
    SELECT address_id 
    FROM addresses 
    WHERE customer_id = (random() * 99999 + 1)::INT 
    LIMIT 1
) b;

-- Генерация позиций заказов (в среднем 3-5 на заказ)
INSERT INTO order_items (order_id, product_id, quantity, price_at_order)
SELECT 
    o.order_id,
    (random() * 999 + 1)::INT,
    (random() * 10 + 1)::INT,
    p.current_price
FROM orders o
CROSS JOIN LATERAL generate_series(1, (random() * 5 + 1)::INT) AS items
JOIN products p ON p.product_id = (random() * 999 + 1)::INT;

-- Обновление total_amount в orders
UPDATE orders o
SET total_amount = (
    SELECT SUM(quantity * price_at_order)
    FROM order_items oi
    WHERE oi.order_id = o.order_id
);