![DevOpsVanilla](../images/devopsvanilla-banner.png)

# 📜 Automações e Scripts de Auditoria AWS (`scripts/`)

Este diretório contém os scripts utilitários em **Bash** (para orquestração e execução de varreduras via Docker Compose) e em **Python** (para parsing, análise de rede/exposição IP e compilação do relatório consolidado final).

---

## 📁 Conteúdo do Diretório

### 🛠️ 1. Scripts Bash (Coleta e Orquestração)

| Script | Descrição | Saída Gerada |
| :--- | :--- | :--- |
| `preflight.sh` | Valida credenciais AWS (`aws sts get-caller-identity`), perfil ativo e permissões nos diretórios de relatórios. | `reports/preflight/preflight-*.json` |
| `run-prowler.sh` | Executa o assessment de segurança e compliance (CIS Benchmark, SOC2, PCI-DSS) via Prowler CLI. | `reports/prowler/prowler-*.csv/.json/.html` |
| `run-cloudquery.sh` | Executa o discovery relacional de ativos AWS via CloudQuery e exporta a base em JSON/SQLite. | `reports/cloudquery/<servico>/` |
| `run-custodian.sh` | Aplica as políticas de governança, tags ausentes e busca de recursos órfãos via Cloud Custodian. | `reports/cloud-custodian/*.json` |
| `run-steampipe.sh` | Executa consultas SQL declarativas de compliance de segurança via Turbot Steampipe. | `reports/steampipe/steampipe-audit-*.csv` |
| `run-billing-export.sh` | Interage com a API `bcm-data-exports` para validar o status da exportação nativa do AWS Standard CUR. | `reports/billing-native/*.json` |

---

### 🐍 2. Scripts Python (Análise e Compilação)

| Script | Descrição | Saída Gerada |
| :--- | :--- | :--- |
| `generate_summary_report.py` | **Compilador Principal:** Lê os artefatos de `reports/`, analisa o inventário, vulnerabilidades e exposição de rede e **gera o relatório consolidado final em Markdown**. | `reports/summary-report.md` |
| `analyze_prowler_cloudquery.py` | Faz o parsing dos arquivos CSV do Prowler agrupando falhas por severidade/Check ID e contabiliza os ativos mapeados pelo CloudQuery. | Saída no Terminal |
| `analyze_network_exposure.py` | Processa o inventário de rede do CloudQuery para extrair IPs Privados, IPs Públicos, Endpoints RDS e regras Ingress abertas (`0.0.0.0/0`) nos Security Groups. | Saída no Terminal |

---

## ⚙️ Pré-requisitos para Execução

### Para os Scripts Bash (via Docker Compose / Makefile):
1. **Docker** e **Docker Compose** instalados no host.
2. Credenciais AWS configuradas em `~/.aws/credentials` ou sessão ativa via **AWS SSO** (`aws sso login`).
3. Arquivo `.env` configurado na raiz do projeto com as variáveis `AWS_PROFILE` e `AWS_DEFAULT_REGION`.

### Para os Scripts Python:
1. **Python 3.8+** instalado (utiliza apenas bibliotecas padrão da linguagem: `json`, `csv`, `os`, `glob`, `sys`, `datetime`).
2. Existência prévia de relatórios gerados dentro do diretório `reports/`.

---

## 🚀 Como Executar os Scripts

### 1. Compilação Automática do Relatório Consolidado (Recomendado)

Para gerar/atualizar o relatório final consolidado em `reports/summary-report.md`:

```bash
python3 scripts/generate_summary_report.py
```

---

### 2. Execução das Ferramentas de Coleta (via Makefile)

```bash
# Validação de credenciais e perfil AWS
make preflight

# Execução individual de coletores
make run-prowler
make run-cloudquery
make run-custodian
make run-steampipe
make run-billing-export

# Execução completa em sequência de toda a stack
make run-all
```

---

### 3. Execução dos Scripts Utilitários Python (Análise no Terminal)

```bash
# Análise de Segurança Prowler e Inventário CloudQuery
python3 scripts/analyze_prowler_cloudquery.py

# Análise de Endereçamento IP e Exposição à Internet
python3 scripts/analyze_network_exposure.py
```

---

## 📌 Boas Práticas e Regras Operacionais

1. **Permissões de Execução:** Certifique-se de que os scripts Bash possuem permissão de execução (`chmod +x scripts/*.sh`).
2. **Relatório Consolidado:** O relatório compilado é salvo em [reports/summary-report.md](../reports/summary-report.md).
3. **Novos Scripts:** Qualquer novo script de análise criado para processar os relatórios **deve ser obrigatoriamente salvo neste diretório (`./scripts/`)** e documentado neste README conforme especificado em [AGENTS.md](../AGENTS.md).
