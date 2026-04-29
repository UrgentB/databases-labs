## Конфигурация таблицы

```sql
CREATE TABLE orders_raw (
    order_id        INTEGER,
    order_date      DATE,
    customer_name   TEXT,          -- "Иванов Иван Иванович"
    customer_email  TEXT,
    customer_phone  TEXT,
    delivery_address TEXT,
    product_names   TEXT,          -- "Ноутбук, Мышь, Коврик"
    product_prices  TEXT,          -- "85000, 1500, 500"
    product_quantities TEXT,       -- "1, 1, 2"
    total_amount    NUMERIC,
    status          TEXT           -- "delivered"
);
```

### Часть 1. Ненормализованная таблица (UNF)

## Скрипт заполнения данных

```sql
-- Вставка 1000 случайных заказов
INSERT INTO orders_raw (order_id, order_date, customer_name, customer_email, customer_phone, delivery_address, product_names, product_prices, product_quantities, total_amount, status)
SELECT
    generate_series(1, 1000) AS order_id,
    -- Случайная дата за последние 2 года
    CURRENT_DATE - (random() * 730)::INTEGER AS order_date,
    -- Русские имена
    (ARRAY['Иванов Иван', 'Петров Петр', 'Сидоров Алексей', 'Козлова Мария', 'Смирнова Екатерина', 'Васильев Дмитрий', 'Новикова Анна', 'Морозов Сергей', 'Волкова Татьяна', 'Кузнецов Андрей'])[floor(random() * 10) + 1] || 
    ' ' || (ARRAY['Иванович', 'Петрович', 'Сергеевич', 'Алексеевна', 'Дмитриевна'])[floor(random() * 5) + 1] AS customer_name,
    -- Email
    lower(replace((ARRAY['ivanov', 'petrov', 'sidorov', 'kozlov', 'smirnov', 'vasiliev', 'novikov', 'morozov', 'volkov', 'kuznetsov'])[floor(random() * 10) + 1], ' ', '')) 
    || floor(random() * 1000)::TEXT || '@mail.ru' AS customer_email,
    -- Телефон
    '+7' || floor(9000000000 + random() * 999999999)::TEXT AS customer_phone,
    -- Адрес
    (ARRAY['Москва, ул. Тверская, ', 'СПб, Невский пр., ', 'Новосибирск, Красный пр., ', 'Екатеринбург, Ленина, ', 'Казань, Баумана, '])[floor(random() * 5) + 1]
    || floor(random() * 100)::TEXT || ', кв.' || floor(random() * 200)::TEXT AS delivery_address,
    
    -- Товары (случайный набор)
    CASE floor(random() * 8)::INTEGER
        WHEN 0 THEN 'Ноутбук'
        WHEN 1 THEN 'Мышь, Коврик'
        WHEN 2 THEN 'Клавиатура, Мышь'
        WHEN 3 THEN 'Ноутбук, Мышь, Коврик'
        WHEN 4 THEN 'Монитор, Клавиатура'
        WHEN 5 THEN 'Наушники, Микрофон'
        WHEN 6 THEN 'Смартфон, Чехол'
        WHEN 7 THEN 'Планшет, Стилус, Чехол'
    END AS product_names,
    
    -- Цены (соответственно количеству товаров)
    CASE floor(random() * 8)::INTEGER
        WHEN 0 THEN '50000'
        WHEN 1 THEN '1500, 500'
        WHEN 2 THEN '3000, 1500'
        WHEN 3 THEN '85000, 1500, 500'
        WHEN 4 THEN '25000, 3000'
        WHEN 5 THEN '5000, 3000'
        WHEN 6 THEN '40000, 1500'
        WHEN 7 THEN '35000, 2000, 1500'
    END AS product_prices,
    
    -- Количество
    CASE floor(random() * 8)::INTEGER
        WHEN 0 THEN '1'
        WHEN 1 THEN '2, 1'
        WHEN 2 THEN '1, 2'
        WHEN 3 THEN '1, 1, 2'
        WHEN 4 THEN '1, 1'
        WHEN 5 THEN '1, 1'
        WHEN 6 THEN '1, 1'
        WHEN 7 THEN '1, 1, 1'
    END AS product_quantities,
    
    -- Сумма (случайная, но реалистичная для выбранных товаров)
    (random() * 100000)::NUMERIC(10,2) AS total_amount,
    
    -- Статус заказа
    (ARRAY['pending', 'processing', 'shipped', 'delivered', 'cancelled'])[floor(random() * 5) + 1] AS status;
```

```sql
-- Проверка количества записей
SELECT COUNT(*) AS total_rows FROM orders_raw;

-- Просмотр первых 10 записей
SELECT * FROM orders_raw LIMIT 10;
```

Аномалии:

1) Вставки. Нельзя добавить информацию о товаре и покупателе без заказа.
2) Обновления. При изменении инф. или покупателе непонятно откуда её брать и где менять. Измениние цены товара - можно обновить изменить цену при добавлении нового заказа и остальное не трогать, но не понятно где держать инф. о том, что цена поменялась без нового заказа. C пользаком ещё хуже. Придётся менять все записи где он упомянут.
3) При удалении последний записи с товром n и пользаком m, теряется вся инфа об этих сущностях.

### Часть 2. Нормализация до 3NF

#### 1NF

```sql
-- Переход к 1NF: разбиваем повторяющиеся группы
DROP TABLE IF EXISTS orders_1nf CASCADE;

CREATE TABLE orders_1nf (
    order_id        INTEGER,
    order_date      DATE,
    customer_name   TEXT,
    customer_email  TEXT,
    customer_phone  TEXT,
    delivery_address TEXT,
    product_name    TEXT,
    product_price   NUMERIC(10, 2),
    product_quantity INTEGER,
    total_amount    NUMERIC(10, 2),
    status          TEXT
);

-- Разворачиваем списки товаров в отдельные строки
INSERT INTO orders_1nf
SELECT 
    o.order_id,
    o.order_date,
    o.customer_name,
    o.customer_email,
    o.customer_phone,
    o.delivery_address,
    TRIM(UNNEST(string_to_array(o.product_names, ','))) AS product_name,
    TRIM(UNNEST(string_to_array(o.product_prices, ',')))::NUMERIC AS product_price,
    TRIM(UNNEST(string_to_array(o.product_quantities, ',')))::INTEGER AS product_quantity,
    o.total_amount,
    o.status
FROM orders_raw o;
```

#### 2NF

```sql
-- 2NF: Убираем частичные зависимости
-- Создаём отдельные сущности

-- 1. Таблица customers
DROP TABLE IF EXISTS customers CASCADE;
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT
);

INSERT INTO customers (name, email, phone)
SELECT DISTINCT 
    customer_name,
    customer_email,
    customer_phone
FROM orders_1nf
ON CONFLICT (email) DO NOTHING;

-- 2. Таблица addresses
DROP TABLE IF EXISTS addresses CASCADE;
CREATE TABLE addresses (
    address_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(customer_id),
    address TEXT NOT NULL
);

INSERT INTO addresses (customer_id, address)
SELECT DISTINCT
    c.customer_id,
    o.delivery_address
FROM orders_1nf o
JOIN customers c ON c.email = o.customer_email;

-- 3. Таблица products
DROP TABLE IF EXISTS products CASCADE;
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    name TEXT UNIQUE,
    current_price NUMERIC(10, 2)
);

INSERT INTO products (name, current_price)
SELECT DISTINCT
    product_name,
    AVG(product_price) -- Берем среднюю цену как текущую
FROM orders_1nf
GROUP BY product_name;

-- 4. Таблица orders (без товаров)
DROP TABLE IF EXISTS orders CASCADE;
CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(customer_id),
    address_id INTEGER REFERENCES addresses(address_id),
    order_date DATE NOT NULL,
    status TEXT,
    total_amount NUMERIC(10, 2)
);

INSERT INTO orders (order_id, customer_id, address_id, order_date, status, total_amount)
SELECT DISTINCT
    o.order_id,
    c.customer_id,
    a.address_id,
    o.order_date,
    o.status,
    o.total_amount
FROM orders_1nf o
JOIN customers c ON c.email = o.customer_email
JOIN addresses a ON a.address = o.delivery_address AND a.customer_id = c.customer_id;

-- 5. Таблица order_items (связь многие-ко-многим)
DROP TABLE IF EXISTS order_items CASCADE;
CREATE TABLE order_items (
    order_id INTEGER REFERENCES orders(order_id),
    product_id INTEGER REFERENCES products(product_id),
    quantity INTEGER NOT NULL,
    price_at_order NUMERIC(10, 2) NOT NULL,
    PRIMARY KEY (order_id, product_id)
);

INSERT INTO order_items (order_id, product_id, quantity, price_at_order)
SELECT 
    o.order_id,
    p.product_id,
    o_1nf.product_quantity,
    o_1nf.product_price
FROM orders_1nf o_1nf
JOIN products p ON p.name = o_1nf.product_name
JOIN orders o ON o.order_id = o_1nf.order_id;

-- Дропаем промежуточную таблицу
DROP TABLE IF EXISTS orders_1nf;
```

#### 3NF

```sql
-- 3NF: Убираем транзитивные зависимости
-- Выделяем категории товаров

-- 1. Таблица categories
DROP TABLE IF EXISTS categories CASCADE;
CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    name TEXT UNIQUE
);

-- Предопределённые категории
INSERT INTO categories (name) VALUES
    ('Электроника'),
    ('Одежда'),
    ('Книги'),
    ('Дом и сад'),
    ('Спорт'),
    ('Игрушки'),
    ('Косметика'),
    ('Автотовары'),
    ('Продукты'),
    ('Мебель');

-- 2. Обновляем products: добавляем category_id
ALTER TABLE products ADD COLUMN category_id INTEGER;

-- Обновляем категории для товаров (на основе названия)
UPDATE products SET category_id = c.category_id
FROM categories c
WHERE 
    (c.name = 'Электроника' AND products.name IN ('Ноутбук', 'Смартфон', 'Наушники')) OR
    (c.name = 'Одежда' AND products.name IN ('Футболка', 'Джинсы', 'Куртка')) OR
    (c.name = 'Книги' AND products.name IN ('Python для начинающих', 'SQL за 10 минут')) OR
    (c.name = 'Дом и сад' AND products.name IN ('Диван', 'Стул')) OR
    (c.name = 'Спорт' AND products.name IN ('Велосипед', 'Мяч')) OR
    (c.name = 'Игрушки' AND products.name IN ('Кукла', 'Конструктор')) OR
    (c.name = 'Косметика' AND products.name IN ('Шампунь', 'Духи')) OR
    (c.name = 'Автотовары' AND products.name IN ('Шины', 'Масло моторное')) OR
    (c.name = 'Продукты' AND products.name IN ('Хлеб', 'Молоко')) OR
    (c.name = 'Мебель' AND products.name IN ('Кровать', 'Шкаф'));

ALTER TABLE products 
    ADD CONSTRAINT fk_products_category 
    FOREIGN KEY (category_id) REFERENCES categories(category_id);

-- Добавляем индексы для внешних ключей
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_address_id ON orders(address_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_products_category_id ON products(category_id);
```

### Часть 3. OLTP-нагрузка на нормализованной схеме


