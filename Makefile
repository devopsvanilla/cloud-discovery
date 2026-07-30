.PHONY: help preflight up run-prowler run-cloudquery run-custodian run-steampipe run-billing-export run-all down clean prepare-dirs

# Variáveis padrão
SHELL := /bin/bash
ENV_FILE ?= .env

ifneq ($(wildcard $(ENV_FILE)),)
    include $(ENV_FILE)
    export
endif

help: ## Exibe a lista de comandos disponíveis
	@echo "=================================================================="
	@echo "  AWS Account Audit Stack - Docker Compose Workflow"
	@echo "=================================================================="
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

prepare-dirs: ## Cria a estrutura de diretórios necessária para os relatórios
	@mkdir -p reports/preflight reports/prowler reports/cloudquery reports/cloud-custodian reports/steampipe reports/billing-native reports/billing-focus logs
	@chmod 777 reports reports/preflight reports/prowler reports/cloudquery reports/cloud-custodian reports/steampipe reports/billing-native reports/billing-focus logs 2>/dev/null || true

preflight: prepare-dirs ## Valida perfil AWS, conectividade STS e permissões
	docker compose run preflight

up: prepare-dirs ## Valida sintaxe do Docker Compose
	docker compose config

run-prowler: prepare-dirs ## Executa assessment de segurança com Prowler
	docker compose run prowler

run-cloudquery: prepare-dirs ## Executa coleta de inventário com CloudQuery
	docker compose run cloudquery

run-custodian: prepare-dirs ## Executa políticas de governança com Cloud Custodian
	docker compose run custodian

run-steampipe: prepare-dirs ## Executa consultas SQL de compliance com Steampipe
	docker compose run steampipe

run-billing-export: prepare-dirs ## Executa verificação e gerenciamento de AWS Data Exports (Nativo)
	docker compose run billing-export

run-all: prepare-dirs preflight ## Executa a suíte completa de auditoria em ordem sequencial
	@echo "🚀 Executando suíte completa de auditoria..."
	@echo "👉 [1/5] Prowler..."
	-docker compose run prowler
	@echo "👉 [2/5] CloudQuery..."
	-docker compose run cloudquery
	@echo "👉 [3/5] Cloud Custodian..."
	-docker compose run custodian
	@echo "👉 [4/5] Steampipe..."
	-docker compose run steampipe
	@echo "👉 [5/5] Billing Export..."
	-docker compose run billing-export
	@echo "✅ Varredura completa finalizada! Verifique a pasta reports/"

down: ## Remove containers e redes residuais
	docker compose down --remove-orphans

clean: ## Limpa relatórios e logs antigos
	@echo "🧹 Limpando relatórios e logs..."
	docker run --rm -v ./reports:/data -v ./logs:/logs alpine sh -c 'rm -rf /data/* /logs/*' 2>/dev/null || rm -rf reports/* logs/*
	@make prepare-dirs
	@echo "✅ Diretórios limpos."
