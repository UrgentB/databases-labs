-- Вставка 100 000 строк с помощью генерации последовательности
INSERT INTO events (event_time, event_type, user_id, payload)
SELECT
    toDateTime('2024-01-01 00:00:00') + INTERVAL number MINUTE as event_time,
    arrayElement(['click', 'view', 'purchase', 'add_to_cart', 'login'], number % 5 + 1) as event_type,
    (number % 10000) + 1 as user_id,
    concat(
        '{"id": ', toString(number),
        ', "data": "', randomPrintableASCII(20), '"}'
    ) as payload
FROM numbers(100000)