![DevOpsVanilla](./images/devopsvanilla-banner.png)

# AGENTS.md - Diretrizes para Agentes de IA & Automação

Este arquivo define convenções, diretrizes de segurança e regras operacionais para qualquer agente de IA (como Antigravity, Claude, ChatGPT, etc.) ou script automatizado que interaja com este repositório de auditoria AWS.

---

## 1. Convenções de Diretórios & Arquivos

- `config/`: Armazena os arquivos de configuração declarativos das ferramentas (`cloudquery.yml`, `steampipe-config.spc`).
- `policies/`: Contém arquivos de regras e políticas do Cloud Custodian (ex.: `custodian-governance.yml`).
- `queries/`: Contém consultas SQL estruturadas para o Steampipe.
- `scripts/`: Contém os wrappers Bash executáveis (`set -euo pipefail`) e **scripts Python de compilação/análise de relatórios**:
  - `scripts/preflight.sh`, `run-prowler.sh`, `run-cloudquery.sh`, `run-custodian.sh`, `run-steampipe.sh`, `run-billing-export.sh`
  - `scripts/generate_summary_report.py`: Compilador principal que processa os relatórios e salva em `reports/summary-report.md`.
  - `scripts/analyze_prowler_cloudquery.py`: Análise e agrupamento de achados do Prowler e contagem de inventário do CloudQuery.
  - `scripts/analyze_network_exposure.py`: Análise de IPs privados, IPs públicos, endpoints RDS e exposição à Internet.
- `reports/`: Diretório de saída final dos relatórios. **NUNCA altere a estrutura dos subdiretórios**:
  - `reports/summary-report.md` (Relatório consolidado final gerado)
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
- O relatório consolidado compilado final em Markdown deve ser salvo obrigatoriamente em `reports/summary-report.md`.
- Todo arquivo gerado em `reports/` deve conter timestamp no nome ou no conteúdo para permitir rastreabilidade histórica.
- Não apague relatórios anteriores a menos que o comando `make clean` seja explicitamente invocado.

---

## 4. Comandos Padrão de Validação

Antes de considerar qualquer alteração concluída, execute:
- `docker compose config` (Validação do compose)
- `make preflight` (Validação de credenciais e ambiente)
- `bash -n scripts/*.sh` (Validação de sintaxe dos scripts Bash)
- `python3 scripts/generate_summary_report.py` (Compilação do relatório em `reports/summary-report.md`)

---

## 5. Instruções para Consolidação por IA e Scripts Auxiliares

1. **Persistência de Scripts em `./scripts/` e Relatório em `./reports/summary-report.md`:** Qualquer script Python ou automação desenvolvida pelo agente de IA para parsear ou compilar relatórios **DEVE ser salvo em `./scripts/`** e o relatório consolidado final gerado deve ser salvo em `./reports/summary-report.md`.
2. **Documentação de Guia de IA:** O guia detalhado de consolidação por IA com prompts de agregação, análise cruzada e priorização de riscos está em `docs/ai-consolidation-guide.md`.
3. **Mapeamento Obrigatório de Rede & Exposição IP:** Em todas as consolidações de relatório, a IA deve mapear explicitamente:
   - IP Privado de cada recurso computacional ou de banco de dados.
   - IP Público / Elastic IP / Endpoint associado.
   - Indicador claro de **Exposição Direta à Internet (SIM / NÃO)**, avaliando `PubliclyAccessible`, atribuição automática de IP público em subnets e regras Ingress `0.0.0.0/0` em Security Groups.
