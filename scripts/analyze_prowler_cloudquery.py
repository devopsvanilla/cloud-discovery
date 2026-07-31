#!/usr/bin/env python3
"""
Script de análise de relatórios Prowler e CloudQuery.
Gera estatísticas agrupadas de falhas por severidade/Check ID e inventário de recursos.
"""

import csv
import glob
import json
import os
import sys

def parse_prowler_csv(prowler_csv_path):
    stats = {}
    check_summary = {}
    
    if not os.path.exists(prowler_csv_path):
        print(f"Erro: Arquivo Prowler não encontrado em {prowler_csv_path}")
        return stats, check_summary

    with open(prowler_csv_path, mode='r', encoding='utf-8') as f:
        reader = csv.DictReader(f, delimiter=';')
        for row in reader:
            status = row.get('STATUS', '')
            severity = row.get('SEVERITY', '')
            service = row.get('SERVICE_NAME', '')
            check_id = row.get('CHECK_ID', '')
            check_title = row.get('CHECK_TITLE', '')
            resource_id = row.get('RESOURCE_ARN', row.get('RESOURCE_ID', ''))
            status_extended = row.get('STATUS_EXTENDED', '')

            key = (status, severity)
            stats[key] = stats.get(key, 0) + 1

            if status == 'FAIL' and severity in ['critical', 'high', 'medium']:
                if check_id not in check_summary:
                    check_summary[check_id] = {
                        'severity': severity,
                        'service': service,
                        'title': check_title,
                        'count': 0,
                        'examples': []
                    }
                check_summary[check_id]['count'] += 1
                if len(check_summary[check_id]['examples']) < 3:
                    check_summary[check_id]['examples'].append((resource_id, status_extended))

    return stats, check_summary

def parse_cloudquery_inventory(cq_base_dir):
    inventory = {}
    if not os.path.exists(cq_base_dir):
        print(f"Erro: Diretório CloudQuery não encontrado em {cq_base_dir}")
        return inventory

    cq_dirs = [d for d in os.listdir(cq_base_dir) if os.path.isdir(os.path.join(cq_base_dir, d))]
    for d in sorted(cq_dirs):
        dir_path = os.path.join(cq_base_dir, d)
        files = glob.glob(os.path.join(dir_path, "*.json"))
        items = {}
        for file in files:
            with open(file, 'r', encoding='utf-8') as jf:
                for line in jf:
                    if line.strip():
                        try:
                            data = json.loads(line)
                            key = data.get('arn') or data.get('id') or data.get('name') or data.get('instance_id') or data.get('_cq_id')
                            items[key] = data
                        except Exception:
                            pass
        inventory[d] = items
    return inventory

if __name__ == "__main__":
    base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    reports_dir = os.path.join(base_dir, "reports")
    prowler_dir = os.path.join(reports_dir, "prowler")
    cq_dir = os.path.join(reports_dir, "cloudquery")

    prowler_files = glob.glob(os.path.join(prowler_dir, "*.csv"))
    if prowler_files:
        latest_prowler = max(prowler_files, key=os.path.getmtime)
        print(f"Analisando Prowler CSV: {latest_prowler}")
        stats, summary = parse_prowler_csv(latest_prowler)
        print("\n=== ESTATÍSTICAS PROWLER ===")
        for k, v in sorted(stats.items()):
            print(f"Status: {k[0]}, Severidade: {k[1]} -> Total: {v}")
    
    print("\n=== INVENTÁRIO CLOUDQUERY ===")
    inventory = parse_cloudquery_inventory(cq_dir)
    for service, items in inventory.items():
        print(f"Serviço: {service} -> Total Recursos: {len(items)}")
