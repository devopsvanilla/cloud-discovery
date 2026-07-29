# AGENTS.md - Diretrizes para Agentes de IA & Automação

Este arquivo define convenções, diretrizes de segurança e regras operacionais para qualquer agente de IA (como Antigravity, Claude, ChatGPT, etc.) ou script automatizado que interaja com este repositório de auditoria AWS.

---

## 1. Convenções de Diretórios & Arquivos

- `config/`: Armazena os arquivos de configuração declarativos das ferramentas (`cloudquery.yml`, `steampipe-config.spc`).
- `policies/`: Contém arquivos de regras e políticas do Cloud Custodian (ex.: `custodian-governance.yml`).
- `queries/`: Contém consultas SQL estruturadas para o Steampipe.
- `scripts/`: Contém os wrappers Bash executáveis (`set -euo pipefail`) para cada serviço.
- `reports/`: Diretório de saída final dos relatórios. **NUNCA altere a estrutura dos subdiretórios**:
  - `reports/preflight/`
  - `reports/prowler/`
  - `reports/cloudquery/`
  - `reports/cloud-custodian/`
  - `reports/steampipe/`
  - `reports/billing-native/`
  - `reports/billing-focus/`
- `logs/`: Registra os logs de execução e erros com timestamp.

---

## 2. Política Estrita de Segurança e Credenciais AWS

1. **PROIBIDO embutir credenciais**: Nenhuma chave (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`) deve ser escrita em código, arquivos `.env`, `docker-compose.yml` ou scripts.
2. **Cadeia de Perfil Local & AWS SSO**: Toda autenticação deve utilizar o perfil AWS local informado pela variável `AWS_PROFILE` e o volume montado em `${HOME}/.aws` em modo **somente leitura (`:ro`)**. A montagem completa do diretório `~/.aws` assegura o suporte nativo tanto para credenciais estáticas quanto para sessões do **AWS SSO (IAM Identity Center)** utilizando o cache em `~/.aws/sso/cache/`.
3. **Princípio do Menor Privilégio**: As varreduras devem ser executadas com roles/usuários que possuam permissões de leitura (ex.: `ReadOnlyAccess` + `bcm-data-exports:*`).

---

## 3. Formato dos Artefatos de Relatório

- Priorize formatos estruturados e legíveis por máquina: `json`, `csv`, `parquet` e `sqlite`.
- Todo arquivo gerado em `reports/` deve conter timestamp no nome ou no conteúdo para permitir rastreabilidade histórica.
- Não apague relatórios anteriores a menos que o comando `make clean` seja explicitamente invocado.

---

## 4. Comandos Padrão de Validação

Antes de considerar qualquer alteração concluída, execute:
- `docker compose config` (Validação do compose)
- `make preflight` (Validação de credenciais e ambiente)
- `bash -n scripts/*.sh` (Validação de sintaxe dos scripts Bash)

---

## 5. Instruções para Consolidação por IA

Os relatórios gerados nesta stack são consolidados posteriormente por um agente de IA. O guia completo com os prompts de agregação, análise cruzada e priorização de riscos está localizado em `docs/ai-consolidation-guide.md`.
