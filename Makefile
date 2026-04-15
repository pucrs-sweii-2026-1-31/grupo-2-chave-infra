.PHONY: setup up down logs reset tf-init tf-apply

COMPOSE       = docker compose
MINISTACK_URL = http://localhost:4566/_localstack/health
TF_DIR        = terraform

# Aguarda o Ministack estar saudável antes de prosseguir
wait-ministack:
	@echo "[make] Aguardando Ministack ficar disponível..."
	@for i in $$(seq 1 30); do \
		STATUS=$$(curl -sf $(MINISTACK_URL) | python3 -c "import sys,json; d=json.load(sys.stdin); svcs=d.get('services',{}); print('running' if svcs else 'not-ready')" 2>/dev/null || echo "not-ready"); \
		echo "[make]   status: $$STATUS (tentativa $$i/30)"; \
		if [ "$$STATUS" = "running" ]; then echo "[make] Ministack pronto."; break; fi; \
		if [ "$$i" = "30" ]; then echo "[make] ERRO: Ministack não ficou disponível a tempo." && exit 1; fi; \
		sleep 5; \
	done

# Inicializa os providers do Terraform
tf-init:
	@echo "[make] Inicializando Terraform..."
	terraform -chdir=$(TF_DIR) init

# Provisiona os recursos no Ministack via Terraform
tf-apply:
	@echo "[make] Provisionando recursos via Terraform..."
	TF_VAR_db_name=$${DB_NAME:-chave_auth} \
	TF_VAR_db_user=$${DB_USER:-chave} \
	TF_VAR_db_password=$${DB_PASSWORD:-chave_secret} \
	TF_VAR_ms_auth_port=$${MS_AUTH_PORT:-3001} \
	terraform -chdir=$(TF_DIR) apply -auto-approve

# Sobe o Ministack, aguarda, provisiona via Terraform e depois sobe todos os serviços
setup: .env tf-init
	@echo "[make] Iniciando setup completo..."
	$(COMPOSE) up -d ministack
	@$(MAKE) wait-ministack
	@$(MAKE) tf-apply
	@echo "[make] Subindo todos os serviços..."
	$(COMPOSE) up -d
	@echo "[make] Setup concluído."

# Sobe todos os serviços em modo detached
up: .env
	$(COMPOSE) up -d

# Para e remove os containers
down:
	$(COMPOSE) down

# Acompanha os logs de todos os serviços
logs:
	$(COMPOSE) logs -f

# Derruba tudo, remove volumes e refaz o setup do zero
reset:
	@echo "[make] Derrubando todos os serviços e removendo volumes..."
	$(COMPOSE) down -v --remove-orphans
	@echo "[make] Reiniciando setup..."
	@$(MAKE) setup

# Garante que o .env exista antes de qualquer comando que precise dele
.env:
	@if [ ! -f .env ]; then \
		echo "[make] Arquivo .env não encontrado. Copiando .env.example..."; \
		cp .env.example .env; \
		echo "[make] Edite o arquivo .env com suas configurações e rode make setup novamente."; \
		exit 1; \
	fi
