#!/usr/bin/env bash
set -euo pipefail

TIMESTAMP=$(date -u +"%Y%m%dT%H%M%SZ")
OUTPUT_DIR="/app/reports/prowler"
LOG_FILE="/app/logs/prowler-${TIMESTAMP}.log"

mkdir -p "${OUTPUT_DIR}" /app/logs

echo "=== [PROWLER] Iniciando assessment de segurança e compliance AWS ===" | tee -a "${LOG_FILE}"
echo "Timestamp: ${TIMESTAMP}" | tee -a "${LOG_FILE}"

# Executa o prowler gerando relatórios em JSON, CSV e HTML
prowler aws \
    --profile "${AWS_PROFILE:-default}" \
    -f "${AWS_DEFAULT_REGION:-us-east-1}" \
    -M json csv html \
    -output-directory "${OUTPUT_DIR}" \
    -output-filename "prowler-${TIMESTAMP}" 2>&1 | tee -a "${LOG_FILE}"

echo "✅ Assessment do Prowler concluído. Artefatos gravados em ${OUTPUT_DIR}" | tee -a "${LOG_FILE}"
