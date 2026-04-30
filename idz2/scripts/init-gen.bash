#!/bin/bash

# setup_clickhouse.sh - Скрипт для инициализации ClickHouse

echo "=== Начало настройки ClickHouse ==="

# Выполнение init.sql
echo "1. Выполнение init.sql..."
clickhouse-client --database shop --multiquery < /scripts/init.sql
echo "   ✓ init.sql выполнен"
в
# Выполнение gen.sql
echo "2. Выполнение gen.sql (генерация данных)..."
clickhouse-client --database shop --multiquery < /scripts/gen.sql
echo "   ✓ gen.sql выполнен"

echo "=== Настройка ClickHouse завершена ==="