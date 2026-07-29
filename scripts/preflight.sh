#!/usr/bin/env bash
set -euo pipefail

TIMESTAMP=$(date -u +"%Y%m%dT%H%M%SZ")
PREFLIGHT_DIR="/app/reports/preflight"
LOG_FILE="/app/logs/preflight-${TIMESTAMP}.log"
JSON_OUT="${PREFLIGHT_DIR}/preflight-${TIMESTAMP}.json"

mkdir -p "${PREFLIGHT_DIR}" /app/logs
mkdir -p /app/reports/prowler /app/reports/cloudquery /app/reports/cloud-custodian /app/reports/steampipe /app/reports/billing-native /app/reports/billing-focus

echo "=== [PREFLIGHT CHECK] Iniciando validação do ambiente AWS ===" | tee -a "${LOG_FILE}"
echo "Timestamp UTC: ${TIMESTAMP}" | tee -a "${LOG_FILE}"
echo "Perfil AWS informado: ${AWS_PROFILE:-default}" | tee -a "${LOG_FILE}"
echo "Região AWS informada: ${AWS_DEFAULT_REGION:-us-east-1}" | tee -a "${LOG_FILE}"

# 1. Validar presença dos arquivos de credenciais e configuração AWS
if [ ! -f "/root/.aws/credentials" ] && [ ! -f "/root/.aws/config" ]; then
    echo "❌ [ERRO CRÍTICO] Arquivos de credenciais/configuração ~/.aws não encontrados no container!" | tee -a "${LOG_FILE}"
    exit 1
fi
echo "✅ Arquivos ~/.aws/config e/ou ~/.aws/credentials montados corretamente." | tee -a "${LOG_FILE}"

if [ -d "/root/.aws/sso/cache" ]; then
    echo "ℹ️  Diretório de cache do AWS SSO (~/.aws/sso/cache) detectado e disponível." | tee -a "${LOG_FILE}"
fi

# 2. Testar autenticação AWS STS Caller Identity
echo "🔍 Validando credenciais via STS Caller Identity..." | tee -a "${LOG_FILE}"
if ! CALLER_IDENTITY=$(aws sts get-caller-identity --profile "${AWS_PROFILE:-default}" --region "${AWS_DEFAULT_REGION:-us-east-1}" --output json 2>>"${LOG_FILE}"); then
    echo "❌ [ERRO] Falha ao autenticar com a AWS API usando o perfil '${AWS_PROFILE:-default}'!" | tee -a "${LOG_FILE}"
    echo "Verifique se o token de sessão expirou ou se as chaves em ~/.aws/credentials estão válidas." | tee -a "${LOG_FILE}"
    exit 1
fi

ACCOUNT_ID=$(echo "${CALLER_IDENTITY}" | grep -o '"Account": "[^"]*' | grep -o '[^"]*$')
ARN=$(echo "${CALLER_IDENTITY}" | grep -o '"Arn": "[^"]*' | grep -o '[^"]*$')
USER_ID=$(echo "${CALLER_IDENTITY}" | grep -o '"UserId": "[^"]*' | grep -o '[^"]*$')

echo "✅ Autenticação AWS bem-sucedida!" | tee -a "${LOG_FILE}"
echo "   - Conta AWS ID: ${ACCOUNT_ID}" | tee -a "${LOG_FILE}"
echo "   - ARN do Usuário/Role: ${ARN}" | tee -a "${LOG_FILE}"
echo "   - User ID: ${USER_ID}" | tee -a "${LOG_FILE}"

# 3. Validar permissões de escrita nos diretórios de saída
echo "🔍 Testando permissões de escrita nos diretórios de relatórios..." | tee -a "${LOG_FILE}"
DIRS=(
    "/app/reports/preflight"
    "/app/reports/prowler"
    "/app/reports/cloudquery"
    "/app/reports/cloud-custodian"
    "/app/reports/steampipe"
    "/app/reports/billing-native"
    "/app/reports/billing-focus"
    "/app/logs"
)

for d in "${DIRS[@]}"; do
    if [ ! -w "$d" ]; then
        echo "❌ [ERRO] Diretório $d não possui permissão de escrita!" | tee -a "${LOG_FILE}"
        exit 1
    fi
done
echo "✅ Todos os diretórios de relatórios e logs possuem permissão de escrita." | tee -a "${LOG_FILE}"

# 4. Salvar resultado JSON estruturado
cat <<EOF > "${JSON_OUT}"
{
  "timestamp": "${TIMESTAMP}",
  "status": "SUCCESS",
  "aws_profile": "${AWS_PROFILE:-default}",
  "aws_region": "${AWS_DEFAULT_REGION:-us-east-1}",
  "account_id": "${ACCOUNT_ID}",
  "arn": "${ARN}",
  "user_id": "${USER_ID}",
  "directories_validated": true
}
EOF

echo "📄 Relatório preflight gerado em: ${JSON_OUT}" | tee -a "${LOG_FILE}"
echo "=== [PREFLIGHT CHECK] Concluído com sucesso! ===" | tee -a "${LOG_FILE}"
