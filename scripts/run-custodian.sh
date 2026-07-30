#!/usr/bin/env bash
set -euo pipefail

TIMESTAMP=$(date -u +"%Y%m%dT%H%M%SZ")
OUTPUT_DIR="/app/reports/cloud-custodian"
RUN_OUTPUT_DIR="${OUTPUT_DIR}/run-${TIMESTAMP}"
LOG_FILE="/app/logs/custodian-${TIMESTAMP}.log"

mkdir -p "${RUN_OUTPUT_DIR}" /app/logs

# Copiar credenciais AWS do mount read-only para local gravável
# Necessário porque o AWS SSO SDK precisa gravar no sso/cache para refresh de tokens
AWS_DIR="/root/.aws"
mkdir -p "${AWS_DIR}"
cp -r /tmp/.aws-host/* "${AWS_DIR}/" 2>/dev/null || true
cp -r /tmp/.aws-host/.* "${AWS_DIR}/" 2>/dev/null || true

echo "=== [CLOUD CUSTODIAN] Iniciando execução das políticas de governança ===" | tee -a "${LOG_FILE}"
echo "Timestamp: ${TIMESTAMP}" | tee -a "${LOG_FILE}"

# Executa as políticas declaradas
custodian run \
    -s "${RUN_OUTPUT_DIR}" \
    -r "${AWS_DEFAULT_REGION:-us-east-1}" \
    /app/policies/custodian-governance.yml 2>&1 | tee -a "${LOG_FILE}" || true

# Gera relatório consolidado em CSV para cada política executada
echo "🔍 Gerando relatórios tabulares em CSV..." | tee -a "${LOG_FILE}"
for policy_dir in "${RUN_OUTPUT_DIR}"/*/; do
    policy_name=$(basename "${policy_dir}")
    if [ -f "${policy_dir}/resources.json" ]; then
        cp "${policy_dir}/resources.json" "${OUTPUT_DIR}/${policy_name}-${TIMESTAMP}.json" 2>/dev/null || true
    fi
done

custodian report \
    -s "${RUN_OUTPUT_DIR}" \
    --format csv \
    /app/policies/custodian-governance.yml > "${OUTPUT_DIR}/custodian-report-${TIMESTAMP}.csv" 2>>"${LOG_FILE}" || true

echo "✅ Execução do Cloud Custodian concluída. Artefatos gravados em ${RUN_OUTPUT_DIR}" | tee -a "${LOG_FILE}"
