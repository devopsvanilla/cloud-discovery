#!/usr/bin/env bash
set -euo pipefail

TIMESTAMP=$(date -u +"%Y%m%dT%H%M%SZ")
OUTPUT_DIR="/app/reports/cloudquery"
LOG_FILE="/app/logs/cloudquery-${TIMESTAMP}.log"

mkdir -p "${OUTPUT_DIR}" /app/logs

echo "=== [CLOUDQUERY] Iniciando sincronização do inventário AWS ===" | tee -a "${LOG_FILE}"
echo "Timestamp: ${TIMESTAMP}" | tee -a "${LOG_FILE}"

# Executa o CloudQuery sync com a configuração montada em /app/config/cloudquery.yml
cloudquery sync /app/config/cloudquery.yml 2>&1 | tee -a "${LOG_FILE}"

echo "✅ Coleta de inventário do CloudQuery concluída." | tee -a "${LOG_FILE}"
echo "📄 Base SQLite de inventário gravada em ${OUTPUT_DIR}/inventory.db" | tee -a "${LOG_FILE}"
