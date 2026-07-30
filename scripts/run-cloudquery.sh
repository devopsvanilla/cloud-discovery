#!/usr/bin/env bash
set -euo pipefail

TIMESTAMP=$(date -u +"%Y%m%dT%H%M%SZ")
OUTPUT_DIR="/app/reports/cloudquery"
LOG_FILE="/app/logs/cloudquery-${TIMESTAMP}.log"

mkdir -p "${OUTPUT_DIR}" /app/logs

# Copiar credenciais AWS do mount read-only para local gravável
AWS_DIR="/root/.aws"
mkdir -p "${AWS_DIR}"
cp -r /tmp/.aws-host/* "${AWS_DIR}/" 2>/dev/null || true
cp -r /tmp/.aws-host/.* "${AWS_DIR}/" 2>/dev/null || true

echo "=== [CLOUDQUERY] Iniciando sincronização do inventário AWS ===" | tee -a "${LOG_FILE}"
echo "Timestamp: ${TIMESTAMP}" | tee -a "${LOG_FILE}"

# Garantir localização do binário do CloudQuery em /app/cloudquery
export PATH="${PATH}:/app"

# Verificar se CLOUDQUERY_API_KEY está configurada
if [ -z "${CLOUDQUERY_API_KEY:-}" ]; then
    echo "⚠️  [AVISO] Variável CLOUDQUERY_API_KEY não definida." | tee -a "${LOG_FILE}"
    echo "   CloudQuery v6+ exige autenticação para baixar plugins do registry." | tee -a "${LOG_FILE}"
    echo "   Para obter uma API key gratuita:" | tee -a "${LOG_FILE}"
    echo "   1. Acesse https://cloud.cloudquery.io e crie uma conta (free tier)" | tee -a "${LOG_FILE}"
    echo "   2. Gere uma API key em Settings > API Keys" | tee -a "${LOG_FILE}"
    echo "   3. Adicione ao .env: CLOUDQUERY_API_KEY=cqk_seu_token_aqui" | tee -a "${LOG_FILE}"
    echo "" | tee -a "${LOG_FILE}"
    echo "   Tentando execução mesmo assim..." | tee -a "${LOG_FILE}"
fi

# Executa o CloudQuery sync com a configuração montada
CQ_BIN=""
if command -v cloudquery >/dev/null 2>&1; then
    CQ_BIN="cloudquery"
elif [ -x "/app/cloudquery" ]; then
    CQ_BIN="/app/cloudquery"
else
    echo "❌ Executável do CloudQuery não encontrado no container!" | tee -a "${LOG_FILE}"
    exit 1
fi

echo "ℹ️  Binário do CloudQuery localizado: ${CQ_BIN}" | tee -a "${LOG_FILE}"
${CQ_BIN} sync /app/config/cloudquery.yml --log-level info 2>&1 | tee -a "${LOG_FILE}" || {
    echo "⚠️  CloudQuery finalizou com erro. Verifique se a CLOUDQUERY_API_KEY está configurada no .env" | tee -a "${LOG_FILE}"
}

echo "📄 Relatórios de inventário JSON gravados em ${OUTPUT_DIR}/" | tee -a "${LOG_FILE}"
echo "✅ Etapa do CloudQuery concluída." | tee -a "${LOG_FILE}"
