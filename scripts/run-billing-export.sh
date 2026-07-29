#!/usr/bin/env bash
set -euo pipefail

TIMESTAMP=$(date -u +"%Y%m%dT%H%M%SZ")
NATIVE_DIR="/app/reports/billing-native"
FOCUS_DIR="/app/reports/billing-focus"
LOG_FILE="/app/logs/billing-export-${TIMESTAMP}.log"

mkdir -p "${NATIVE_DIR}" "${FOCUS_DIR}" /app/logs

echo "=== [AWS BILLING & DATA EXPORTS] Consultando e gerenciando exportações de custos ===" | tee -a "${LOG_FILE}"
echo "Timestamp: ${TIMESTAMP}" | tee -a "${LOG_FILE}"
echo "Perfil AWS: ${AWS_PROFILE:-default}" | tee -a "${LOG_FILE}"
echo "Região AWS: ${AWS_DEFAULT_REGION:-us-east-1}" | tee -a "${LOG_FILE}"

# 1. Registrar status do formato FOCUS (Cancelado a pedido do usuário)
cat <<EOF > "${FOCUS_DIR}/billing-focus-${TIMESTAMP}.json"
{
  "timestamp": "${TIMESTAMP}",
  "status": "CANCELLED_BY_USER_REQUEST",
  "format": "FOCUS_1.0",
  "message": "Exportação em formato FOCUS 1.0 desabilitada por instrução do usuário. Utilizando o padrão atual nativo AWS Data Exports (CUR)."
}
EOF
echo "ℹ️  Exportação FOCUS desabilitada. Status registrado em ${FOCUS_DIR}/billing-focus-${TIMESTAMP}.json" | tee -a "${LOG_FILE}"

# 2. Verificar e Listar AWS Data Exports Nativos (Standard Cost & Usage Reports)
echo "🔍 Consultando exportações ativas via AWS BCM Data Exports API..." | tee -a "${LOG_FILE}"

EXPORTS_JSON="${NATIVE_DIR}/billing-native-exports-${TIMESTAMP}.json"
SUMMARY_TXT="${NATIVE_DIR}/billing-native-summary-${TIMESTAMP}.txt"

if aws bcm-data-exports list-exports --profile "${AWS_PROFILE:-default}" --region "${AWS_DEFAULT_REGION:-us-east-1}" --output json > "${EXPORTS_JSON}" 2>>"${LOG_FILE}"; then
    echo "✅ Consulta de AWS Data Exports concluída com sucesso." | tee -a "${LOG_FILE}"
else
    echo "⚠️  Não foi possível consultar 'aws bcm-data-exports list-exports'. Testando fallback via 'aws cur describe-report-definitions'..." | tee -a "${LOG_FILE}"
    if aws cur describe-report-definitions --profile "${AWS_PROFILE:-default}" --region "${AWS_DEFAULT_REGION:-us-east-1}" --output json > "${EXPORTS_JSON}" 2>>"${LOG_FILE}"; then
        echo "✅ Consulta de relatórios CUR legados concluída com sucesso." | tee -a "${LOG_FILE}"
    else
        echo "❌ Falha ao consultar APIs de Billing Data Exports. Verifique se o perfil possui a permissão 'bcm-data-exports:ListExports' ou 'cur:DescribeReportDefinitions'." | tee -a "${LOG_FILE}"
        cat <<EOF > "${EXPORTS_JSON}"
{
  "timestamp": "${TIMESTAMP}",
  "status": "PERMISSION_OR_API_ERROR",
  "error": "Não foi possível listar exportações. Certifique-se de que a conta possui o AWS Data Exports habilitado e a role possui permissões bcm-data-exports:* ou cur:*."
}
EOF
    fi
fi

# 3. Gerar resumo da operação
cat <<EOF > "${SUMMARY_TXT}"
=== RESUMO DE BILLING DATA EXPORTS ===
Data de Execução: ${TIMESTAMP}
Perfil AWS: ${AWS_PROFILE:-default}
Região: ${AWS_DEFAULT_REGION:-us-east-1}
Formato Nativo: AWS Data Exports (Standard CUR)
Formato FOCUS: Desabilitado (Conforme instrução de projeto)
Bucket S3 Alvo Configurado em .env: ${AWS_BILLING_S3_BUCKET:-N/A}
Nome da Exportação Alvo em .env: ${AWS_BILLING_EXPORT_NAME:-standard-cur-export}

Arquivo de Metadados: ${EXPORTS_JSON}
EOF

echo "📄 Resumo de Billing gravado em ${SUMMARY_TXT}" | tee -a "${LOG_FILE}"
echo "=== [AWS BILLING & DATA EXPORTS] Operação finalizada! ===" | tee -a "${LOG_FILE}"
