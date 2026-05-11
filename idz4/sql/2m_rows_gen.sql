TRUNCATE TABLE events_distributed;

INSERT INTO events_distributed (
                                event_date, 
                                event_time, 
                                user_id, 
                                session_id, 
                                event_type, 
                                page_url, 
                                duration_ms)
SELECT
    toDate('2024-01-01') + (rand() % 365) as event_date,
    event_date + INTERVAL (rand() % 86400) SECOND as event_time,
    (number % 1_000_000) + 1 AS user_id,
    toString(number+rand()) as session_id,
    CASE
        WHEN rand()%3=0 THEN 'похороны'
        WHEN rand()%3=1 THEN 'свадьба'
        ELSE 'день рождения'
    END as event_type,
    concat('https://example.com/page/', toString(number % 1000 + 1)) as page_url,
    rand() % 5000 as duration_ms
FROM numbers(2_000_000);