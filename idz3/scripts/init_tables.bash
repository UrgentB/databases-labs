
checker="$1"
echo "" > "$checker/tables_created.txt"


docker exec clickhouse1 clickhouse-client --multiquery "CREATE TABLE events ON CLUSTER test_cluster (
    event_time DateTime,
    event_type LowCardinality(String),
    user_id    UInt64,
    payload    String
) ENGINE = ReplicatedMergeTree(
    '/clickhouse/tables/{shard}/events',
    '{replica}'
)
ORDER BY (event_type, event_time)
PARTITION BY toYYYYMM(event_time);"


for var in $(seq 1 3); do
    echo "clickhouse$var \n" >> "$checker/tables_created.txt"
    docker exec clickhouse$var clickhouse-client --query "SHOW TABLES ON CLUSTER test_cluster" >> "$checker/tables_created.txt"
    echo "" >> "$checker/tables_created.txt"
done