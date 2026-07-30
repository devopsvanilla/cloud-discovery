#!/usr/bin/env bash
set -euo pipefail

TIMESTAMP=$(date -u +"%Y%m%dT%H%M%SZ")
OUTPUT_DIR="/app/reports/prowler"
LOG_FILE="/app/logs/prowler-${TIMESTAMP}.log"

mkdir -p "${OUTPUT_DIR}" /app/logs

# Copiar credenciais AWS do mount read-only para local gravável
# Necessário porque o AWS SSO SDK precisa gravar no sso/cache para refresh de tokens
AWS_DIR="/home/prowler/.aws"
mkdir -p "${AWS_DIR}"
cp -r /tmp/.aws-host/* "${AWS_DIR}/" 2>/dev/null || true
cp -r /tmp/.aws-host/.* "${AWS_DIR}/" 2>/dev/null || true

echo "=== [PROWLER] Iniciando assessment de segurança e compliance AWS ===" | tee -a "${LOG_FILE}"
echo "Timestamp: ${TIMESTAMP}" | tee -a "${LOG_FILE}"

# Localizar o binário do Prowler (varia conforme a versão da imagem)
PROWLER_BIN=""
if command -v prowler >/dev/null 2>&1; then
    PROWLER_BIN="prowler"
elif [ -f "/home/prowler/.venv/bin/prowler" ]; then
    PROWLER_BIN="/home/prowler/.venv/bin/prowler"
elif [ -f "/usr/local/bin/prowler" ]; then
    PROWLER_BIN="/usr/local/bin/prowler"
else
    PROWLER_BIN=$(find / -name prowler -type f -executable 2>/dev/null | head -1)
fi

if [ -z "${PROWLER_BIN}" ]; then
    echo "❌ Executável do Prowler não encontrado no container!" | tee -a "${LOG_FILE}"
    exit 1
fi

echo "ℹ️  Binário do Prowler localizado em: ${PROWLER_BIN}" | tee -a "${LOG_FILE}"

# Executa o Prowler gerando relatórios em JSON-OCSF, CSV e HTML
echo "🔍 Executando varredura do Prowler..." | tee -a "${LOG_FILE}"
${PROWLER_BIN} aws \
    --profile "${AWS_PROFILE:-default}" \
    -f "${AWS_DEFAULT_REGION:-us-east-1}" \
    -M json-ocsf csv html \
    -o "${OUTPUT_DIR}" \
    -F "prowler-${TIMESTAMP}" 2>&1 | tee -a "${LOG_FILE}" || true

echo "✅ Assessment do Prowler concluído. Artefatos gravados em ${OUTPUT_DIR}" | tee -a "${LOG_FILE}"
