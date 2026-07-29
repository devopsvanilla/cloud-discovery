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

preflight: prepare-dirs ## Valida perfil AWS, conectividade STS e permissões
	docker compose run --rm preflight

up: prepare-dirs ## Sobe os serviços em background ou verifica imagens
	docker compose config

run-prowler: prepare-dirs ## Executa assessment de segurança com Prowler
	docker compose run --rm prowler

run-cloudquery: prepare-dirs ## Executa coleta de inventário com CloudQuery
	docker compose run --rm cloudquery

run-custodian: prepare-dirs ## Executa políticas de governança com Cloud Custodian
	docker compose run --rm custodian

run-steampipe: prepare-dirs ## Executa consultas SQL de compliance com Steampipe
	docker compose run --rm steampipe

run-billing-export: prepare-dirs ## Executa verificação e gerenciamento de AWS Data Exports (Nativo)
	docker compose run --rm billing-export

run-all: prepare-dirs preflight ## Executa a suíte completa de auditoria em ordem sequencial
	@echo "🚀 Executando suíte completa de auditoria..."
	docker compose run --rm prowler
	docker compose run --rm cloudquery
	docker compose run --rm custodian
	docker compose run --rm steampipe
	docker compose run --rm billing-export
	@echo "✅ Varredura completa finalizada! Verifique a pasta reports/"

down: ## Remove containers e redes residuais
	docker compose down --remove-orphans

clean: ## Limpa relatórios e logs antigos
	@echo "🧹 Limpando relatórios e logs..."
	rm -rf reports/* logs/*
	@make prepare-dirs
	@echo "✅ Diretórios limpos."
