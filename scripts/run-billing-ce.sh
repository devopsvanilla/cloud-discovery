#!/usr/bin/env bash
set -euo pipefail

TIMESTAMP=$(date -u +"%Y%m%dT%H%M%SZ")
CE_DIR="/app/reports/billing-cost-explorer"
LOG_FILE="/app/logs/billing-ce-${TIMESTAMP}.log"

mkdir -p "${CE_DIR}" /app/logs

echo "=== [AWS COST EXPLORER] Extração de custos detalhados (Último Trimestre) ===" | tee -a "${LOG_FILE}"
echo "Timestamp: ${TIMESTAMP}" | tee -a "${LOG_FILE}"
echo "Perfil AWS: ${AWS_PROFILE:-default}" | tee -a "${LOG_FILE}"
echo "Região AWS: ${AWS_DEFAULT_REGION:-us-east-1}" | tee -a "${LOG_FILE}"

# Cálculo dinâmico do período (últimos 90 dias / 3 meses retroativos até hoje)
if date -u -d "3 months ago" +"%Y-%m-01" >/dev/null 2>&1; then
    START_DATE=$(date -u -d "3 months ago" +"%Y-%m-01")
    END_DATE=$(date -u +"%Y-%m-%d")
else
    # Fallback para macOS/BSD date se aplicável
    START_DATE=$(date -u -j -v-3m +"%Y-%m-01" 2>/dev/null || date -u +"%Y-%m-01")
    END_DATE=$(date -u +"%Y-%m-%d")
fi

echo "📅 Período de consulta: de ${START_DATE} até ${END_DATE}" | tee -a "${LOG_FILE}"

SUMMARY_TXT="${CE_DIR}/ce-summary-${TIMESTAMP}.txt"
MONTHLY_SERVICE_JSON="${CE_DIR}/ce-monthly-by-service-${TIMESTAMP}.json"
MONTHLY_USAGETYPE_JSON="${CE_DIR}/ce-monthly-by-usagetype-${TIMESTAMP}.json"
MONTHLY_REGION_JSON="${CE_DIR}/ce-monthly-by-region-${TIMESTAMP}.json"
DAILY_SERVICE_JSON="${CE_DIR}/ce-daily-by-service-${TIMESTAMP}.json"

echo "🔍 1/4 Extraindo custos mensais por Serviço..." | tee -a "${LOG_FILE}"
if aws ce get-cost-and-usage \
    --profile "${AWS_PROFILE:-default}" \
    --region "${AWS_DEFAULT_REGION:-us-east-1}" \
    --time-period "Start=${START_DATE},End=${END_DATE}" \
    --granularity MONTHLY \
    --metrics "UnblendedCost" "UsageQuantity" \
    --group-by Type=DIMENSION,Key=SERVICE \
    --output json > "${MONTHLY_SERVICE_JSON}" 2>>"${LOG_FILE}"; then
    echo "✅ Custos por Serviço extraídos com sucesso." | tee -a "${LOG_FILE}"
else
    echo "❌ Falha ao consultar Cost Explorer por Serviço." | tee -a "${LOG_FILE}"
fi

echo "🔍 2/4 Extraindo custos mensais detalhados por Serviço + Tipo de Uso (UsageType)..." | tee -a "${LOG_FILE}"
aws ce get-cost-and-usage \
    --profile "${AWS_PROFILE:-default}" \
    --region "${AWS_DEFAULT_REGION:-us-east-1}" \
    --time-period "Start=${START_DATE},End=${END_DATE}" \
    --granularity MONTHLY \
    --metrics "UnblendedCost" \
    --group-by Type=DIMENSION,Key=SERVICE Type=DIMENSION,Key=USAGE_TYPE \
    --output json > "${MONTHLY_USAGETYPE_JSON}" 2>>"${LOG_FILE}" || true

echo "🔍 3/4 Extraindo custos mensais por Serviço + Região..." | tee -a "${LOG_FILE}"
aws ce get-cost-and-usage \
    --profile "${AWS_PROFILE:-default}" \
    --region "${AWS_DEFAULT_REGION:-us-east-1}" \
    --time-period "Start=${START_DATE},End=${END_DATE}" \
    --granularity MONTHLY \
    --metrics "UnblendedCost" \
    --group-by Type=DIMENSION,Key=SERVICE Type=DIMENSION,Key=REGION \
    --output json > "${MONTHLY_REGION_JSON}" 2>>"${LOG_FILE}" || true

echo "🔍 4/4 Extraindo tendência diária dos últimos 90 dias por Serviço..." | tee -a "${LOG_FILE}"
aws ce get-cost-and-usage \
    --profile "${AWS_PROFILE:-default}" \
    --region "${AWS_DEFAULT_REGION:-us-east-1}" \
    --time-period "Start=${START_DATE},End=${END_DATE}" \
    --granularity DAILY \
    --metrics "UnblendedCost" \
    --group-by Type=DIMENSION,Key=SERVICE \
    --output json > "${DAILY_SERVICE_JSON}" 2>>"${LOG_FILE}" || true

# Gerar relatório resumido executivo
cat <<EOF > "${SUMMARY_TXT}"
=== RESUMO DE EXTRAÇÃO - AWS COST EXPLORER ===
Data da Execução: ${TIMESTAMP}
Perfil AWS: ${AWS_PROFILE:-default}
Região AWS: ${AWS_DEFAULT_REGION:-us-east-1}
Período Auditado: ${START_DATE} até ${END_DATE}

Arquivos Gerados:
- Faturamento Mensal por Serviço: ${MONTHLY_SERVICE_JSON}
- Faturamento Mensal por Serviço + UsageType: ${MONTHLY_USAGETYPE_JSON}
- Faturamento Mensal por Serviço + Região: ${MONTHLY_REGION_JSON}
- Faturamento Diário por Serviço (Últimos 90 dias): ${DAILY_SERVICE_JSON}

Logs de Execução: ${LOG_FILE}
EOF

echo "📄 Resumo consolidado salvo em: ${SUMMARY_TXT}" | tee -a "${LOG_FILE}"
echo "=== [AWS COST EXPLORER] Extração finalizada! ===" | tee -a "${LOG_FILE}"
