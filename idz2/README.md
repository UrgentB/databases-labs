# Решение

- Почему нет JOIN-ов на лету?

```text
В условия колоночного хранилища это слишком дорого по ресурсам. Если JOIN в OLTP в большенсве случаев будет представлять лишь подномножество отношения, элементы для которого юыстро ищутся через B-tree индекс, то в OLAP это неизбежно будет полной отношение между.
```

- избыточность данных компенсируется сжатием;

```text
наличие избыточности в принципе позволяет использовать сжатие.
Типы сжатий: RLE(сжатие дублирующихся данных - Саша, Саша, Петя -> Саша2, Петя1), Словарное кодирование, Дельта кодирование (для данных с монотонным ростом), 
```

- `LowCardinality` заменяет справочные таблицы.

```text
упомянутое выше словарное кодирование в Clickhouse реализовано через тип LowCardinality, который автоматически создаёт словарь для колонки. Эффективно применять для колонок с небольшим кол-вом значений.
```

## Бизнес запросы

sql скрипты запросов в директории sql/05_queries
результаты выполнения - /resluts

## Демонстрация TTL

TTL (Time To Live) — это механизм автоматического управления жизненным циклом данных в ClickHouse. Позволяет автоматически удалять или перемещать данные по истечении заданного времени.

скрипт - 03_orders_ttl.sql
результат - demo_ttl.txt

## Системные таблицы и сжатие

- сжимаются лучше всего колонки с большим колличеством избыточных данных
- `LowCardinality` влияет на сжатие позитивно, если кол-во возможных значений в столбце мало.
- `ORDER BY` сортирует дынные, из чего следует что рядом оказываются близкие значения из чего следует, что алгоритмы сжатия RLE (для нечисловых данных) и Дельта (для числовых) будут работать эффективнее

## Сравнение с PostgreSQL

| Запрос / Операция | PostgreSQL (3NF) | ClickHouse (flat) | Вывод |
|-------------------|------------------|--------------------|-------|
| Вставка 1 строки | 0.547 мс | 1 мс | ... |
| Топ-10 товаров (1M строк) | 20337.376 мс | 116 мс | есть версия что такой большой разницы быть не должно и я накосячил с вставкой данных |
| JOIN 4 таблиц | 4.759 мс | не нужен | ... |
| Обновление статуса | 12.677 мс | не поддерживается нативно | ... |
| Размер на диске (1M строк) | 169,4 MB | 1,28 gb | ... |
| Поиск по подстроке | 8.761 мс | 80 мс | ... |

Вставка 1 строки

**Postgres**

```sql
INSERT INTO orders (order_id, customer_id, address_id, order_date, status) 
VALUES (2000002, 1, 1, CURRENT_DATE, 'pending');
```

**Clickhouse**

```sql
INSERT INTO orders_flat (order_id, customer_id, customer_name, product_id, product_name, quantity, price, 
order_date, customer_email) 
VALUES (2000001, 1, 'Test CH', 1, 'Product', 1, 100, 
        today(), 'test@ch.com')
```

Топ-10 товаров (1M строк) 

**Postgres**

```sql
SELECT 
    p.product_id,
    p.name AS product_name,
    cat.name AS category_name,
    p.current_price AS current_price,
    COUNT(DISTINCT oi.order_id) AS number_of_orders,
    SUM(oi.quantity) AS total_quantity_sold,
    SUM(oi.quantity * oi.price_at_order) AS total_revenue,
    ROUND(AVG(oi.quantity * oi.price_at_order), 2) AS avg_order_value
FROM products p                                          
JOIN order_items oi ON p.product_id = oi.product_id
JOIN categories cat ON p.category_id = cat.category_id
GROUP BY p.product_id, p.name, cat.name, p.current_price
ORDER BY total_quantity_sold DESC
LIMIT 10;
```

**Clickhouse**

01_top_10_products.sql

JOIN 4 таблиц

**Postgres**

```sql
SELECT 
    o.order_id,
    o.order_date,
    c.customer_name,
    ct.city_name,
    cn.country_name                                 
FROM orders o                               
INNER JOIN customers c ON o.customer_id = c.customer_id
INNER JOIN cities ct ON c.city_id = ct.city_id
INNER JOIN countries cn ON ct.country_id = cn.country_id;
```


Обновление статуса

**Postgres**

```sql
UPDATE orders 
SET status = 'completed' 
WHERE order_id = 123;
```

Поиск по подстроке

**Postgres**

```sql

```

**Clickhouse**

```sql

```
