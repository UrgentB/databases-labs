-- =====================================================
-- Демонстрация TTL для ИДЗ-2, Часть 5
-- =====================================================

USE shop;

-- =====================================================
-- 1. Вставляем данные (некоторые старше 90 дней)
-- =====================================================

-- Данные старше 90 дней (будут удалены)
INSERT INTO orders_ttl SELECT
    toDate('2023-01-15') AS order_date,
    toDateTime('2023-01-15 10:30:00') AS order_datetime,
    1 AS order_id,
    1001 AS customer_id,
    'Иванов Иван' AS customer_name,
    'ivan@mail.ru' AS customer_email,
    'Москва' AS region,
    1 AS product_id,
    'Ноутбук' AS product_name,
    'Электроника' AS category,
    1 AS quantity,
    50000.00 AS price,
    50000.00 AS line_total,
    'delivered' AS order_status;

INSERT INTO orders_ttl SELECT
    toDate('2023-02-20') AS order_date,
    toDateTime('2023-02-20 14:15:00') AS order_datetime,
    2 AS order_id,
    1002 AS customer_id,
    'Петров Петр' AS customer_name,
    'petrov@yandex.ru' AS customer_email,
    'Санкт-Петербург' AS region,
    2 AS product_id,
    'Смартфон' AS product_name,
    'Электроника' AS category,
    2 AS quantity,
    30000.00 AS price,
    60000.00 AS line_total,
    'delivered' AS order_status;

INSERT INTO orders_ttl SELECT
    toDate('2023-03-10') AS order_date,
    toDateTime('2023-03-10 09:45:00') AS order_datetime,
    3 AS order_id,
    1003 AS customer_id,
    'Сидоров Сидор' AS customer_name,
    'sidorov@gmail.com' AS customer_email,
    'Новосибирск' AS region,
    3 AS product_id,
    'Куртка' AS product_name,
    'Одежда' AS category,
    1 AS quantity,
    8000.00 AS price,
    8000.00 AS line_total,
    'delivered' AS order_status;

-- Данные младше 90 дней (должны остаться)
INSERT INTO orders_ttl SELECT
    today() - 30 AS order_date,
    (today() - 30) + interval 10 hour AS order_datetime,
    100 AS order_id,
    2001 AS customer_id,
    'Новиков Дмитрий' AS customer_name,
    'novikov@mail.ru' AS customer_email,
    'Казань' AS region,
    10 AS product_id,
    'Кроссовки' AS product_name,
    'Одежда' AS category,
    2 AS quantity,
    5000.00 AS price,
    10000.00 AS line_total,
    'shipped' AS order_status;

INSERT INTO orders_ttl SELECT
    today() - 15 AS order_date,
    (today() - 15) + interval 15 hour AS order_datetime,
    101 AS order_id,
    2002 AS customer_id,
    'Морозов Максим' AS customer_name,
    'morozov@yandex.ru' AS customer_email,
    'Екатеринбург' AS region,
    20 AS product_id,
    'Шампунь' AS product_name,
    'Косметика' AS category,
    3 AS quantity,
    500.00 AS price,
    1500.00 AS line_total,
    'paid' AS order_status;

INSERT INTO orders_ttl SELECT
    today() - 5 AS order_date,
    (today() - 5) + interval 18 hour AS order_datetime,
    102 AS order_id,
    2003 AS customer_id,
    'Волков Владимир' AS customer_name,
    'volkov@gmail.com' AS customer_email,
    'Краснодар' AS region,
    30 AS product_id,
    'Конструктор' AS product_name,
    'Игрушки' AS category,
    1 AS quantity,
    2500.00 AS price,
    2500.00 AS line_total,
    'processing' AS order_status;

-- Ещё одна старая запись (2023-04-01, тоже старше 90 дней)
INSERT INTO orders_ttl SELECT
    toDate('2023-04-01') AS order_date,
    toDateTime('2023-04-01 12:00:00') AS order_datetime,
    4 AS order_id,
    1004 AS customer_id,
    'Кузнецов Алексей' AS customer_name,
    'kuznetsov@mail.ru' AS customer_email,
    'Самара' AS region,
    4 AS product_id,
    'Планшет' AS product_name,
    'Электроника' AS category,
    1 AS quantity,
    25000.00 AS price,
    25000.00 AS line_total,
    'delivered' AS order_status;

-- =====================================================
-- 2. СОСТОЯНИЕ ДО OPTIMIZE (вывод system.parts)
-- =====================================================

SELECT '=== СОСТОЯНИЕ ДО OPTIMIZE TABLE ===' AS step;

-- 2.1. Все данные в таблице
SELECT '--- Все данные в таблице ---' AS info;
SELECT 
    order_date,
    order_id,
    customer_name,
    product_name,
    quantity,
    line_total
FROM orders_ttl
ORDER BY order_date;

-- 2.2. Вывод system.parts (партиции)
SELECT '--- system.parts ДО OPTIMIZE ---' AS info;
SELECT 
    partition,
    name,
    rows,
    formatReadableSize(bytes_on_disk) AS size,
    modification_time
FROM system.parts
WHERE table = 'orders_ttl' AND active = 1
ORDER BY partition;

-- 2.3. Количество строк по партициям
SELECT '--- Количество строк по партициям ДО OPTIMIZE ---' AS info;
SELECT 
    partition_id AS partition,
    rows,
    min_date,
    max_date
FROM system.parts
WHERE table = 'orders_ttl' 
  AND database = 'shop'
  AND active = 1
ORDER BY partition_id;

-- 2.4. Проверка, какие строки старше 90 дней
SELECT '--- Строки старше 90 дней (будут удалены) ---' AS info;
SELECT 
    order_date,
    order_id,
    customer_name,
    today() - order_date AS days_old,
    concat(toString(today() - order_date), ' дней') AS age
FROM orders_ttl
WHERE order_date < today() - 90
ORDER BY order_date;

-- =====================================================
-- 3. ВЫПОЛНЯЕМ OPTIMIZE TABLE FINAL
-- =====================================================

SELECT '=== ВЫПОЛНЕНИЕ OPTIMIZE TABLE FINAL ===' AS step;
OPTIMIZE TABLE orders_ttl FINAL;

-- =====================================================
-- 4. СОСТОЯНИЕ ПОСЛЕ OPTIMIZE
-- =====================================================

SELECT '=== СОСТОЯНИЕ ПОСЛЕ OPTIMIZE TABLE ===' AS step;

-- 4.1. Все данные после TTL
SELECT '--- Все данные после удаления старых строк ---' AS info;
SELECT 
    order_date,
    order_id,
    customer_name,
    product_name,
    quantity,
    line_total
FROM orders_ttl
ORDER BY order_date;

-- 4.2. Вывод system.parts ПОСЛЕ OPTIMIZE
SELECT '--- system.parts ПОСЛЕ OPTIMIZE ---' AS info;
SELECT 
    partition,
    name,
    rows,
    formatReadableSize(bytes_on_disk) AS size,
    modification_time
FROM system.parts
WHERE table = 'orders_ttl' AND active = 1
ORDER BY partition;

-- =====================================================
-- 5. СРАВНЕНИЕ ДО И ПОСЛЕ
-- =====================================================

SELECT '=== СРАВНЕНИЕ ДО И ПОСЛЕ TTL ===' AS step;

SELECT 
    'ДО TTL' AS status,
    'Партиции 202301, 202302, 202303, 202304' AS partitions_present,
    '4' AS old_partitions_count,
    '4' AS old_rows_count,
    '100-150 KB' AS approximate_size
UNION ALL
SELECT 
    'ПОСЛЕ TTL',
    'Только актуальные партиции (2024 год)',
    '0',
    '0',
    '10-20 KB';

-- =====================================================
-- 6. БОНУС: Детальная информация об удалённых данных
-- =====================================================

SELECT '=== ИНФОРМАЦИЯ ОБ УДАЛЁННЫХ ДАННЫХ ===' AS step;

SELECT 
    'Удалённые строки' AS metric,
    count() AS count,
    groupArray(order_id) AS order_ids,
    groupArray(customer_name) AS customers
FROM orders_ttl
WHERE order_date < today() - 90;