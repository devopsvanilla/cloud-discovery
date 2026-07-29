#!/usr/bin/env bash
set -euo pipefail

TIMESTAMP=$(date -u +"%Y%m%dT%H%M%SZ")
OUTPUT_DIR="/app/reports/cloud-custodian"
RUN_OUTPUT_DIR="${OUTPUT_DIR}/run-${TIMESTAMP}"
LOG_FILE="/app/logs/custodian-${TIMESTAMP}.log"

mkdir -p "${RUN_OUTPUT_DIR}" /app/logs

echo "=== [CLOUD CUSTODIAN] Iniciando execução das políticas de governança ===" | tee -a "${LOG_FILE}"
echo "Timestamp: ${TIMESTAMP}" | tee -a "${LOG_FILE}"

# Executa as políticas declaradas
custodian run \
    --config /app/policies/custodian-governance.yml \
    --output-dir "${RUN_OUTPUT_DIR}" \
    --profile "${AWS_PROFILE:-default}" \
    --region "${AWS_DEFAULT_REGION:-us-east-1}" 2>&1 | tee -a "${LOG_FILE}"

# Gera relatório consolidado em CSV para cada política executada
echo "🔍 Gerando relatórios tabulares em CSV..." | tee -a "${LOG_FILE}"
custodian report \
    --config /app/policies/custodian-governance.yml \
    --output-dir "${RUN_OUTPUT_DIR}" \
    --format csv > "${OUTPUT_DIR}/custodian-report-${TIMESTAMP}.csv" 2>>"${LOG_FILE}" || true

echo "✅ Execução do Cloud Custodian concluída. Artefatos gravados em ${RUN_OUTPUT_DIR}" | tee -a "${LOG_FILE}"
