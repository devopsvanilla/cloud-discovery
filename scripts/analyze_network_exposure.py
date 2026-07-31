#!/usr/bin/env python3
"""
Script de análise de rede e exposição de recursos para a Internet.
Extrai IPs Privados, IPs Públicos, Endpoints RDS e regras de Security Groups.
"""

import glob
import json
import os
import sys

def analyze_network(cq_base_dir):
    def get_cq_items(table):
        folder = os.path.join(cq_base_dir, table)
        items = {}
        if not os.path.exists(folder):
            return items
        for file in glob.glob(os.path.join(folder, "*.json")):
            with open(file, 'r', encoding='utf-8') as f:
                for line in f:
                    if line.strip():
                        try:
                            d = json.loads(line)
                            key = d.get('arn') or d.get('id') or d.get('name') or d.get('instance_id') or d.get('_cq_id')
                            items[key] = d
                        except Exception:
                            pass
        return items

    print("=== MAPEAMENTO DE REDE EC2 ===")
    ec2_items = get_cq_items('aws_ec2_instances')
    for k, v in ec2_items.items():
        iid = v.get('instance_id')
        tags = v.get('tags') or {}
        name = tags.get('Name') or tags.get('name') or iid
        priv_ip = v.get('private_ip_address')
        pub_ip = v.get('public_ip_address')
        is_public = bool(pub_ip)
        sgs = [sg.get('GroupId') for sg in v.get('security_groups', [])]
        print(f"EC2 ID: {iid} | Nome: {name}")
        print(f"  IP Privado: {priv_ip}")
        print(f"  IP Público: {pub_ip or 'Nenhum'}")
        print(f"  Exposto à Internet: {'SIM (PÚBLICO)' if is_public else 'NÃO (PRIVADO)'}")
        print(f"  Security Groups: {sgs}")
        print("-" * 50)

    print("\n=== MAPEAMENTO DE REDE RDS ===")
    rds_items = get_cq_items('aws_rds_instances')
    for k, v in rds_items.items():
        db_id = v.get('db_instance_identifier')
        pub_access = v.get('publicly_accessible')
        endpoint = v.get('endpoint') or {}
        address = endpoint.get('address')
        port = endpoint.get('port')
        print(f"RDS ID: {db_id}")
        print(f"  Endpoint Interno: {address}:{port}")
        print(f"  Publicly Accessible: {pub_access}")
        print(f"  Exposto à Internet: {'SIM (PÚBLICO)' if pub_access else 'NÃO (PRIVADO)'}")
        print("-" * 50)

    print("\n=== SECURITY GROUPS E EXPOSIÇÃO INGRESS (0.0.0.0/0) ===")
    sg_items = get_cq_items('aws_ec2_security_groups')
    for k, v in sg_items.items():
        sg_id = v.get('group_id')
        sg_name = v.get('group_name')
        vpc_id = v.get('vpc_id')
        open_rules = []
        for rule in v.get('ip_permissions', []):
            from_port = rule.get('from_port')
            to_port = rule.get('to_port')
            protocol = rule.get('ip_protocol')
            for ip_range in rule.get('ip_ranges', []):
                if ip_range.get('cidr_ip') == '0.0.0.0/0':
                    open_rules.append(f"Protocolo: {protocol}, Portas: {from_port}-{to_port}, CIDR: 0.0.0.0/0")
        if open_rules:
            print(f"SG ID: {sg_id} ({sg_name}) | VPC: {vpc_id}")
            for r in open_rules:
                print(f"  ⚠️ Regra de Entrada Aberta: {r}")
            print("-" * 50)

if __name__ == "__main__":
    base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    cq_dir = os.path.join(base_dir, "reports", "cloudquery")
    analyze_network(cq_dir)
