#!/bin/bash
# run_queries.sh - Скрипт для запуска внутри контейнера ClickHouse
# Выполняет все запросы и сохраняет результаты с временем выполнения

set -e

# =====================================================
# Настройки
# =====================================================

DATABASE="shop"
QUERIES_DIR="/sql/05_queries"
RESULTS_DIR="/results"

# Создаём директорию для результатов
mkdir -p "$RESULTS_DIR"

# Имя файла с результатами
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RESULT_FILE="$RESULTS_DIR/queries_result_${TIMESTAMP}.txt"
TIMING_FILE="$RESULTS_DIR/timing_${TIMESTAMP}.csv"
SUMMARY_FILE="$RESULTS_DIR/summary_${TIMESTAMP}.txt"

# =====================================================
# Цвета для вывода (если терминал поддерживает)
# =====================================================

if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }

# =====================================================
# Функции
# =====================================================

# Функция выполнения одного запроса
run_query() {
    local query_num=$1
    local query_name=$2
    local query_file=$3
    
    log_step "Выполнение $query_num: $query_name..."
    
    local output_section="$RESULTS_DIR/${query_num}_${query_name}.txt"
    local start_time end_time duration_ms
    
    # Проверка существования файла
    if [ ! -f "$query_file" ]; then
        log_error "Файл $query_file не найден"
        return 1
    fi
    
    # Замер времени выполнения
    start_time=$(date +%s%N)
    
    # Выполнение запроса и сохранение результата
    {
        echo "================================================================================"
        echo "ЗАПРОС $query_num: $query_name"
        echo "================================================================================"
        echo "Дата выполнения: $(date)"
        echo "Файл: $query_file"
        echo "================================================================================"
        echo ""
        echo "--- SQL ---"
        cat "$query_file"
        echo ""
        echo "--- РЕЗУЛЬТАТ ---"
        echo ""
        
        # Выполняем запрос с форматированием
        clickhouse-client --database "$DATABASE" --format PrettyCompact --multiquery < "$query_file"
        
        echo ""
        echo "================================================================================"
        
    } > "$output_section" 2>&1
    
    end_time=$(date +%s%N)
    duration_ms=$(( ($end_time - $start_time) / 1000000 ))
    
    # Записываем время выполнения в CSV
    echo "${query_num},${query_name},${duration_ms}" >> "$TIMING_FILE"
    
    # Добавляем время в секцию результата
    {
        echo ""
        echo "--- ВРЕМЯ ВЫПОЛНЕНИЯ ---"
        echo "Execution time: ${duration_ms} ms (${duration_ms}000 µs)"
        echo "================================================================================"
    } >> "$output_section"
    
    log_success "$query_name выполнен за ${duration_ms} ms"
    
    return 0
}

# Функция проверки подключения к ClickHouse
check_connection() {
    log_step "Проверка подключения к ClickHouse..."
    
    if clickhouse-client --query "SELECT 1" > /dev/null 2>&1; then
        log_success "Подключение установлено"
        return 0
    else
        log_error "Не удалось подключиться к ClickHouse"
        exit 1
    fi
}

# =====================================================
# Основная часть
# =====================================================

echo ""
echo "================================================================================"
echo "CLICKHOUSE QUERY EXECUTOR"
echo "================================================================================"
echo "База данных: $DATABASE"
echo "Директория запросов: $QUERIES_DIR"
echo "Результаты будут сохранены в: $RESULTS_DIR"
echo "================================================================================"
echo ""

# Проверка подключения
check_connection

# Заголовок основного файла результатов
{
    echo "================================================================================"
    echo "CLICKHOUSE QUERY RESULTS"
    echo "================================================================================"
    echo "Дата выполнения: $(date)"
    echo "База данных: $DATABASE"
    echo "================================================================================"
    echo ""
} > "$RESULT_FILE"

# Заголовок CSV файла с временем
echo "query_id,query_name,duration_ms" > "$TIMING_FILE"

# Инициализация файла со сводкой
{
    echo "================================================================================"
    echo "CLICKHOUSE QUERY EXECUTION SUMMARY"
    echo "================================================================================"
    echo "Дата выполнения: $(date)"
    echo "================================================================================"
    echo ""
    printf "%-5s %-40s %15s\n" "#" "Query Name" "Time (ms)"
    echo "--------------------------------------------------------------------------------"
} > "$SUMMARY_FILE"

# Список запросов
queries=(
    "01|Top 10 Products|$QUERIES_DIR/01_top_10_products.sql"
    "02|Monthly Dynamics|$QUERIES_DIR/02_monthly_dynamics.sql"
    "03|Percentiles|$QUERIES_DIR/03_percentiles.sql"
    "04|Customer Search|$QUERIES_DIR/04_customer_search.sql"
    "05|Raw vs Aggregate|$QUERIES_DIR/05_raw_vs_aggregate.sql"
    "06|Table Statistics|$QUERIES_DIR/06_table_stats.sql"
)

# Выполнение запросов
total_start_time=$(date +%s%N)

for query in "${queries[@]}"; do
    IFS='|' read -r num name file <<< "$query"
    
    run_query "$num" "$name" "$file"
    
    # Добавляем результат в сводку
    duration=$(grep "^${num}," "$TIMING_FILE" | cut -d',' -f3)
    printf "%-5s %-40s %15s\n" "$num" "$name" "$duration" >> "$SUMMARY_FILE"
    
    # Добавляем секцию в общий файл результатов
    {
        echo ""
        echo "================================================================================"
        echo "ЗАПРОС $num: $name"
        echo "================================================================================"
        echo ""
        cat "$RESULTS_DIR/${num}_${name}.txt"
        echo ""
    } >> "$RESULT_FILE"
    
    echo ""
done

total_end_time=$(date +%s%N)
total_duration_ms=$(( ($total_end_time - $total_start_time) / 1000000 ))

# Добавляем итоговую статистику в сводку
{
    echo "--------------------------------------------------------------------------------"
    printf "%-5s %-40s %15s\n" "" "TOTAL" "$total_duration_ms"
    echo "================================================================================"
    echo ""
    echo "Детальные результаты сохранены в: $RESULT_FILE"
    echo "Время выполнения запросов: $TIMING_FILE"
} >> "$SUMMARY_FILE"

# Вывод результатов
echo ""
echo "================================================================================"
echo "ВЫПОЛНЕНИЕ ЗАВЕРШЕНО"
echo "================================================================================"
echo ""
echo "Результаты сохранены в:"
echo "  - Полный отчёт: $RESULT_FILE"
echo "  - Сводка: $SUMMARY_FILE"
echo "  - Время выполнения: $TIMING_FILE"
echo ""

# Показать сводку
echo "=== Сводка по времени выполнения ==="
cat "$SUMMARY_FILE"
echo ""

log_success "Готово!"