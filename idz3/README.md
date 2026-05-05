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

## Часть 2. Реплицированные таблицы.

