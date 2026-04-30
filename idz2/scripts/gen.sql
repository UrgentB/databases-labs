-- =====================================================
-- Генерация данных для ClickHouse
-- =====================================================

USE shop;

-- 1. Создание временной таблицы с продуктами
DROP TABLE IF EXISTS tmp_products;
CREATE TEMPORARY TABLE tmp_products (
    product_id   UInt16,
    product_name String,
    category     String,
    min_price    Decimal(12,2),
    max_price    Decimal(12,2)
);

INSERT INTO tmp_products VALUES
(1, 'Ноутбук', 'Электроника', 35000, 250000),
(2, 'Смартфон', 'Электроника', 15000, 120000),
(3, 'Планшет', 'Электроника', 10000, 80000),
(4, 'Наушники', 'Электроника', 1500, 30000),
(5, 'Клавиатура', 'Электроника', 1000, 15000),
(6, 'Мышь', 'Электроника', 500, 10000),
(7, 'Монитор', 'Электроника', 10000, 80000),
(8, 'Системный блок', 'Электроника', 25000, 200000),
(9, 'Веб-камера', 'Электроника', 1000, 15000),
(10, 'Микрофон', 'Электроника', 1500, 25000),
(11, 'Футболка', 'Одежда', 500, 5000),
(12, 'Джинсы', 'Одежда', 1500, 15000),
(13, 'Куртка', 'Одежда', 3000, 35000),
(14, 'Кроссовки', 'Одежда', 2000, 25000),
(15, 'Свитер', 'Одежда', 1000, 10000),
(16, 'Шапка', 'Одежда', 300, 3000),
(17, 'Шарф', 'Одежда', 200, 2500),
(18, 'Перчатки', 'Одежда', 200, 2000),
(19, 'Сковорода', 'Дом и кухня', 500, 8000),
(20, 'Кастрюля', 'Дом и кухня', 400, 6000),
(21, 'Нож', 'Дом и кухня', 200, 5000),
(22, 'Тарелки', 'Дом и кухня', 500, 3000),
(23, 'Стаканы', 'Дом и кухня', 300, 2000),
(24, 'Чайник', 'Дом и кухня', 500, 8000),
(25, 'Миксер', 'Дом и кухня', 1000, 12000),
(26, 'Блендер', 'Дом и кухня', 800, 10000),
(27, 'Шампунь', 'Косметика', 150, 1500),
(28, 'Гель для душа', 'Косметика', 100, 1000),
(29, 'Крем', 'Косметика', 200, 3000),
(30, 'Помада', 'Косметика', 300, 2000),
(31, 'Тени', 'Косметика', 200, 1500),
(32, 'Тушь', 'Косметика', 250, 2000),
(33, 'Лак', 'Косметика', 150, 1000),
(34, 'Конструктор', 'Игрушки', 500, 15000),
(35, 'Кукла', 'Игрушки', 400, 10000),
(36, 'Машинка', 'Игрушки', 300, 8000),
(37, 'Мягкая игрушка', 'Игрушки', 300, 5000),
(38, 'Настольная игра', 'Игрушки', 500, 6000),
(39, 'Пазл', 'Игрушки', 300, 1500);

-- 2. Очистка существующих таблиц
TRUNCATE TABLE IF EXISTS orders_flat;
TRUNCATE TABLE IF EXISTS orders_ttl;
TRUNCATE TABLE IF EXISTS monthly_sales;

-- 3. Удаление материализованного представления
-- В ClickHouse используется DROP VIEW или DROP TABLE
DROP VIEW IF EXISTS monthly_sales_mv;

-- 4. Генерация данных
INSERT INTO orders_flat
SELECT
    toDate('2023-01-01') + (number % 730) AS order_date,
    toDateTime(order_date) + (number % 86400) AS order_datetime,
    (number % 250000) + 1 AS order_id,
    (number % 50000) + 1 AS customer_id,
    concat(
        arrayElement(['Алексей','Дмитрий','Максим','Владимир','Сергей','Андрей','Иван','Михаил'], (number % 8) + 1),
        ' ',
        arrayElement(['Иванов','Петров','Сидоров','Кузнецов','Смирнов','Васильев','Попов'], (number % 7) + 1)
    ) AS customer_name,
    lower(concat(
        splitByChar(' ', customer_name)[1], '.',
        splitByChar(' ', customer_name)[2], 
        toString(number % 10000), '@',
        arrayElement(['gmail.com','yandex.ru','mail.ru'], (number % 3) + 1)
    )) AS customer_email,
    arrayElement(['Москва','Санкт-Петербург','Новосибирск','Екатеринбург','Казань','Нижний Новгород','Челябинск','Самара','Омск','Ростов-на-Дону'], (number % 10) + 1) AS region,
    (number % 39) + 1 AS product_id,
    (SELECT product_name FROM tmp_products WHERE product_id = (number % 39) + 1) AS product_name,
    (SELECT category FROM tmp_products WHERE product_id = (number % 39) + 1) AS category,
    (number % 5) + 1 AS quantity,
    round(
        (SELECT min_price FROM tmp_products WHERE product_id = (number % 39) + 1) + 
        ((SELECT max_price FROM tmp_products WHERE product_id = (number % 39) + 1) - 
         (SELECT min_price FROM tmp_products WHERE product_id = (number % 39) + 1)) * rand() / 4294967295,
        2
    ) AS price,
    0 AS line_total,
    arrayElement(['pending','processing','paid','shipped','delivered','cancelled'], (number % 6) + 1) AS order_status
FROM numbers(1000000);

-- 5. Обновление line_total
ALTER TABLE orders_flat UPDATE line_total = quantity * price WHERE 1=1;

-- 6. Копирование в TTL таблицу
INSERT INTO orders_ttl SELECT * FROM orders_flat;

-- 7. Создание материализованного представления
CREATE MATERIALIZED VIEW IF NOT EXISTS monthly_sales_mv
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

-- 8. Заполнение monthly_sales
INSERT INTO monthly_sales
SELECT
    toStartOfMonth(order_date) AS month,
    category,
    region,
    sumState(quantity),
    sumState(line_total),
    countState(order_id)
FROM orders_flat
GROUP BY month, category, region;

-- 9. Проверка
SELECT '=== Генерация данных завершена ===' AS status;
SELECT 
    'orders_flat' AS table_name,
    count() AS rows,
    count(DISTINCT order_id) AS orders,
    count(DISTINCT customer_id) AS customers
FROM orders_flat;

SELECT 
    'monthly_sales' AS table_name,
    count() AS rows
FROM monthly_sales;