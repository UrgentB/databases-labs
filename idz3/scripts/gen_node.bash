
for var in $(seq 1 3); do
    touch config/clickhouse/node${var}_macros.xml
    echo "<clickhouse>
    <macros>
        <shard>0${var}</shard>
        <replica>clickhouse1</replica>
        <cluster>test_cluster</cluster>
    </macros>
</clickhouse>" > config/clickhouse/node${var}_macros.xml
done