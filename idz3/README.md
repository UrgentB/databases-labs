# Отчёт

## Часть 1. ClickHouse Keeper / ZooKeeper

Сначала нужно установить netcat внутрь контейнера.

```bash
docker exec keeper${NODE_ID} bash -c "apt-get update && apt-get install -y netcat-openbsd"
```

Затем была запущена следущая команда.
По не известной причине не было ответа при обращении по имени keeeper. Возсожно это дпст проблемы в дальнейшем.

```bash
docker exec keeper${NODE_ID} bash -c "echo mntr | nc localhost 9181" >> checks/keeper_health.txt
```

docker exec keeper1 bash -c "echo mntr | nc keeper2 9181"

## Часть 2. Реплицированные таблицы.

Написал bash скрипт который сначал создаёт таблицу в однолй реплике, а потом. обращается к каждой реплике и смотрить какие таблицы она имеет. 

- Скрипт: scripts/init_tables.bash;
- Результат: checks/tables_created.txt

## Часть 3. Проверка репликации.


