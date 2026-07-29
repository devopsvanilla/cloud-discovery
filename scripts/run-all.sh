#!/usr/bin/env bash
set -euo pipefail

TIMESTAMP=$(date -u +"%Y%m%dT%H%M%SZ")
LOG_FILE="/app/logs/run-all-${TIMESTAMP}.log"

mkdir -p /app/logs

echo "=================================================================" | tee -a "${LOG_FILE}"
echo "🚀 INICIANDO SUÍTE COMPLETA DE AUDITORIA AWS" | tee -a "${LOG_FILE}"
echo "Timestamp Inicio: ${TIMESTAMP}" | tee -a "${LOG_FILE}"
echo "=================================================================" | tee -a "${LOG_FILE}"

# Step 1: Preflight
echo "👉 [1/6] Executando Preflight Check..." | tee -a "${LOG_FILE}"
bash /app/scripts/preflight.sh 2>&1 | tee -a "${LOG_FILE}"

# Step 2: Prowler
echo "👉 [2/6] Executando Prowler Security Assessment..." | tee -a "${LOG_FILE}"
bash /app/scripts/run-prowler.sh 2>&1 | tee -a "${LOG_FILE}" || echo "⚠️ Aviso: Prowler finalizou com alertas." | tee -a "${LOG_FILE}"

# Step 3: CloudQuery
echo "👉 [3/6] Executando CloudQuery Inventory..." | tee -a "${LOG_FILE}"
bash /app/scripts/run-cloudquery.sh 2>&1 | tee -a "${LOG_FILE}" || echo "⚠️ Aviso: CloudQuery finalizou com erros em alguns recursos." | tee -a "${LOG_FILE}"

# Step 4: Cloud Custodian
echo "👉 [4/6] Executando Cloud Custodian Governance Policies..." | tee -a "${LOG_FILE}"
bash /app/scripts/run-custodian.sh 2>&1 | tee -a "${LOG_FILE}" || echo "⚠️ Aviso: Cloud Custodian finalizou com avisos." | tee -a "${LOG_FILE}"

# Step 5: Steampipe
echo "👉 [5/6] Executando Steampipe SQL Audit..." | tee -a "${LOG_FILE}"
bash /app/scripts/run-steampipe.sh 2>&1 | tee -a "${LOG_FILE}" || echo "⚠️ Aviso: Steampipe finalizou com erros pontuais." | tee -a "${LOG_FILE}"

# Step 6: Billing Export
echo "👉 [6/6] Executando AWS Billing Data Exports Check..." | tee -a "${LOG_FILE}"
bash /app/scripts/run-billing-export.sh 2>&1 | tee -a "${LOG_FILE}"

echo "=================================================================" | tee -a "${LOG_FILE}"
echo "✅ SUÍTE COMPLETA DE AUDITORIA FINALIZADA COM SUCESSO!" | tee -a "${LOG_FILE}"
echo "Consulte a pasta 'reports/' para visualizar todos os relatórios." | tee -a "${LOG_FILE}"
echo "=================================================================" | tee -a "${LOG_FILE}"
