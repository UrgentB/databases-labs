import os
import xml.etree.ElementTree as ET
import subprocess

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CLUSTER_CONFIG = os.path.join(SCRIPT_DIR, '../config/clickhouse/cluster.xml')

with open(CLUSTER_CONFIG, 'r') as f:
    cluster_config = ET.parse(f)

replicas = cluster_config.find('.//cluster_2x2').findall('.//host')
query = "SELECT hostName() AS host, count() AS rows FROM events_local"
destination = os.path.join(SCRIPT_DIR, '../checks/data_distribution.txt')

for replica in replicas:
    result = subprocess.run(
        ['docker', 'exec', replica.text, 'clickhouse-client', '--query', query],
        capture_output=True,
        text=True
    )
        
    with open(destination, 'a') as f:
        f.write(f"--- {replica.text} ---\n")
        f.write(result.stdout)
        if result.stderr:
            f.write(f"ERROR: {result.stderr}\n")
        f.write("\n")