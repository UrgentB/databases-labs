SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

docker compose down -v
docker compose up -d
sleep 5
docker exec ch-s1-r1 clickhouse client --queries-file "sql/init_tables.sql"
docker exec ch-s1-r1 clickhouse client --queries-file "sql/2m_rows_gen.sql"

source "$SCRIPT_DIR/../.venv/bin/activate"
python "$SCRIPT_DIR/../scripts/02_dist_rows.py"

