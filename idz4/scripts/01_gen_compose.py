import os
import yaml
import xml.etree.ElementTree as ET

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CLUSTER_CONFIG = os.path.join(SCRIPT_DIR, '../config/clickhouse/cluster.xml')
DOCKER_COMPOSE_FILE = os.path.join(SCRIPT_DIR, '../docker-compose.yml')

COMPOSE_CONTENT = {
        "services": {
            "keeper1": {
                "image": "clickhouse/clickhouse-server:23.8-alpine",
                "hostname": "keeper1",
                "container_name": "keeper1",
                "ports": ["9181:9181"],
                "volumes": [
                    "./config/keeper/keeper1.xml:/etc/clickhouse-server/config.d/keeper.xml",
                    "keeper1_data:/var/lib/clickhouse",
                    "keeper1_logs:/var/log/clickhouse-server"
                ],
                "networks": ["ch_network"],
                "user": "101:101"
            },
            "keeper2": {
                "image": "clickhouse/clickhouse-server:23.8-alpine",
                "hostname": "keeper2",
                "container_name": "keeper2",
                "ports": ["9182:9181"],
                "volumes": [
                    "./config/keeper/keeper2.xml:/etc/clickhouse-server/config.d/keeper.xml",
                    "keeper2_data:/var/lib/clickhouse",
                    "keeper2_logs:/var/log/clickhouse-server"
                ],
                "networks": ["ch_network"],
                "user": "101:101"
            },
            "keeper3": {
                "image": "clickhouse/clickhouse-server:23.8-alpine",
                "hostname": "keeper3",
                "container_name": "keeper3",
                "ports": ["9183:9181"],
                "volumes": [
                    "./config/keeper/keeper3.xml:/etc/clickhouse-server/config.d/keeper.xml",
                    "keeper3_data:/var/lib/clickhouse",
                    "keeper3_logs:/var/log/clickhouse-server"
                ],
                "networks": ["ch_network"],
                "user": "101:101"
            }
        }
    }

COMPOSE_CONTENT['networks'] = {"ch_network": {"driver": "bridge"}}
COMPOSE_CONTENT['volumes'] = {
    "keeper1_data": None,
    "keeper1_logs": None,
    "keeper2_data": None,
    "keeper2_logs": None,
    "keeper3_data": None,
    "keeper3_logs": None,
}

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

    COMPOSE_CONTENT['services'][name] = {
        "image": "clickhouse/clickhouse-server:23.8-alpine",
        "hostname": name,
        "container_name": name,
        "ports": [f"{8120 + int(name[-1])}:8123", f"{9000 + int(name[-1])}:9000"],
        "volumes": [
            f"./config/clickhouse/{name}_macros.xml:/etc/clickhouse-server/config.d/macros.xml",
            f"./config/clickhouse/{name}_cluster.xml:/etc/clickhouse-server/config.d/cluster.xml",
            f"./sql:/sql",
            f"{name}_data:/var/lib/clickhouse"
        ],
        "networks": ["ch_network"],
        "user": "101:101"
    }

    COMPOSE_CONTENT['volumes'][f"{name}_data"] = None
    COMPOSE_CONTENT['volumes'][f"{name}_logs"] = None

with open(DOCKER_COMPOSE_FILE, 'w') as f:
    yaml.dump(COMPOSE_CONTENT, f, default_flow_style=False)




        



    
    
    
    


