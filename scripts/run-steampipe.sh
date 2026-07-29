#!/usr/bin/env bash
set -euo pipefail

TIMESTAMP=$(date -u +"%Y%m%dT%H%M%SZ")
OUTPUT_DIR="/app/reports/steampipe"
LOG_FILE="/app/logs/steampipe-${TIMESTAMP}.log"

mkdir -p "${OUTPUT_DIR}" /app/logs

echo "=== [STEAMPIPE] Iniciando execução de consultas SQL e benchmarks ===" | tee -a "${LOG_FILE}"
echo "Timestamp: ${TIMESTAMP}" | tee -a "${LOG_FILE}"

# Instalar/Atualizar plugin AWS no Steampipe
echo "🔌 Verificando plugin AWS do Steampipe..." | tee -a "${LOG_FILE}"
steampipe plugin install aws 2>&1 | tee -a "${LOG_FILE}" || true

# Configurar conexão
mkdir -p ~/.steampipe/config
cp /app/config/steampipe-config.spc ~/.steampipe/config/aws.spc || true

# Executa consulta SQL customizada e exporta resultados em CSV e JSON
echo "🔍 Executando queries de auditoria..." | tee -a "${LOG_FILE}"
steampipe query /app/queries/steampipe-audit.sql --output csv > "${OUTPUT_DIR}/steampipe-audit-${TIMESTAMP}.csv" 2>>"${LOG_FILE}" || true
steampipe query /app/queries/steampipe-audit.sql --output json > "${OUTPUT_DIR}/steampipe-audit-${TIMESTAMP}.json" 2>>"${LOG_FILE}" || true

echo "✅ Consultas do Steampipe concluídas. Artefatos gravados em ${OUTPUT_DIR}" | tee -a "${LOG_FILE}"
