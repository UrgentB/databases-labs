import os
import yaml
import xml.etree.ElementTree as ET

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CLUSTER_CONFIG = os.path.join(SCRIPT_DIR, '../config/clickhouse/cluster.xml')
DOCKER_COMPOSE_FILE = os.path.join(SCRIPT_DIR, '../docker-compose.yml')
COMPOSE_CONTENT = {"services":{}, "volumes":{}}

for i in range(1, 4):
    COMPOSE_CONTENT["services"][f"keeper{i}_idz4"] = {
        "image": "clickhouse/clickhouse-server:23.8-alpine",
        "hostname": f"keeper{i}_idz4",
        "container_name": f"keeper{i}_idz4",
        "ports": [f"918{i}:9181", f"{9234 + i}:9234"],
        "volumes": [
            f"./config/keeper/keeper{i}.xml:/etc/clickhouse-server/config.d/keeper.xml",
            f"keeper{i}_idz4_data:/var/lib/clickhouse",
            f"keeper{i}_idz4_logs:/var/log/clickhouse-server"
        ],
        "networks": ["ch_network_idz4"],
        "user": "101:101"
    }
    COMPOSE_CONTENT["volumes"][f"keeper{i}_idz4_data"] = None
    COMPOSE_CONTENT["volumes"][f"keeper{i}_idz4_logs"] = None

COMPOSE_CONTENT["networks"] = {"ch_network_idz4": {"driver": "bridge"}}

with open(CLUSTER_CONFIG, 'r') as f:
    cluster_config = ET.parse(f)

replicas = cluster_config.find('.//cluster_2x2').findall('.//host')
replica_number = 1
for replica in replicas:
    name = replica.text

    with open(os.path.join(SCRIPT_DIR, f'../config/clickhouse/{name}_macros.xml'), 'wb') as f:
        macros_content = ET.Element('clickhouse')
        macros = ET.SubElement(macros_content, 'macros')
        ET.SubElement(macros, 'replica').text = name + str(replica_number)
        ET.SubElement(macros, 'shard').text = str(replica_number)
        ET.SubElement(macros, 'cluster').text = 'cluster_2x2'
        tree = ET.ElementTree(macros_content)
        tree.write(f, encoding='utf-8', xml_declaration=True)

    COMPOSE_CONTENT["services"][name] = {
        "image": "clickhouse/clickhouse-server:23.8-alpine",
        "hostname": name,
        "container_name": name,
        "ports": [f"{8120 + replica_number}:8123"],
        "volumes": [
            f"./config/clickhouse/{name}_macros.xml:/etc/clickhouse-server/config.d/macros.xml",
            f"./config/clickhouse/cluster.xml:/etc/clickhouse-server/config.d/cluster.xml",
            f"./sql:/sql",
            f"{name}_data:/var/lib/clickhouse"
        ],
        "networks": ["ch_network_idz4"],
        "user": "101:101"
    }

    COMPOSE_CONTENT["volumes"][f"{name}_data"] = None
    COMPOSE_CONTENT["volumes"][f"{name}_logs"] = None
    replica_number += 1

with open(DOCKER_COMPOSE_FILE, 'w') as f:
    yaml.dump(COMPOSE_CONTENT, f, default_flow_style=False)




        



    
    
    
    


