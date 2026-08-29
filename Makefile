.DEFAULT_GOAL := help

.PHONY: help setup deps run dev docker-up docker-down docker-logs docker-clean \
        localstack-up localstack-down localstack-init aws-smoke db-migrate db-seed db-reset \
        test test-js test-verbose lint lint-fix console clean install

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

setup: deps .env docker-up install db-migrate db-setup localstack-init ## First-time project setup (system deps + Docker + gems + DB + AWS resources)
	@echo ">>> Setup complete. Run 'make dev' to start."

deps: ## Install system dependencies (libvips for image processing)
	@echo ">>> Checking system dependencies..."
	@if ! brew list vips &>/dev/null; then \
		echo ">>> Installing libvips (required for image processing)..."; \
		brew install vips; \
	else \
		echo ">>> libvips already installed."; \
	fi

run: docker-up ## Start all services and the Rails server
	@echo ">>> Starting Rails server..."
	bin/rails server -b 0.0.0.0

dev: docker-up ## Start dev environment with Foreman (hot reload)
	@echo ">>> Starting dev environment..."
	bin/dev

install: ## Install Ruby + JavaScript dependencies
	@echo ">>> Installing gems..."
	bundle install
	@echo ">>> Installing JS dependencies (Stimulus tests)..."
	npm install

db-setup: ## Create, migrate, and seed the database
	@echo ">>> Setting up database..."
	bin/rails db:prepare
	bin/rails db:seed

db-migrate: ## Run pending migrations
	bin/rails db:migrate

db-seed: ## Seed the database
	bin/rails db:seed

db-reset: ## Reset and reseed the database
	bin/rails db:reset

docker-up: ## Start Docker services (postgres, localstack)
	@echo ">>> Starting Docker services (postgres, localstack)..."
	docker compose up -d --remove-orphans postgres localstack
	@echo ">>> Waiting for PostgreSQL..."
	@i=0; until docker compose exec postgres pg_isready -U $$(grep POSTGRES_USER .env 2>/dev/null | cut -d= -f2 || echo "tovitu") 2>/dev/null; do i=$$((i+1)); [ $$i -ge 30 ] && break; sleep 1; done
	@echo ">>> Waiting for LocalStack services..."
	@i=0; until (curl -s http://localhost:4566/_localstack/health | python3 -c "import json,sys; d=json.load(sys.stdin); s=d.get(\"services\",{}); [exit(1) for k in [\"s3\",\"sqs\",\"sns\",\"ses\",\"secretsmanager\",\"logs\",\"events\",\"scheduler\"] if s.get(k) not in (\"available\",\"running\",\"starting\")]" && curl -s http://localhost:4566/_localstack/init/ready | python3 -c "import json,sys; d=json.load(sys.stdin); sys.exit(0 if d.get('completed') is True else 1)") >/dev/null 2>&1; do i=$$((i+1)); [ $$i -ge 60 ] && break; sleep 2; done
	@echo ">>> Core services ready."

docker-down: ## Stop all Docker services
	@echo ">>> Stopping Docker services..."
	docker compose down --remove-orphans

docker-logs: ## View Docker service logs
	docker compose logs -f

docker-clean: ## Remove retired MinIO/Redis containers + volumes (run once post-migration)
	@echo ">>> Removing orphan containers..."
	docker compose down --remove-orphans
	@echo ">>> Removing retired MinIO/Redis volumes..."
	docker volume rm tovitu_minio_data tovitu_redis_data 2>/dev/null || echo "  (volumes already gone)"
	@echo ">>> Done. Start the new stack with 'make docker-up'."

localstack-up: ## Start LocalStack (full AWS emulation for dev)
	@echo ">>> Starting LocalStack..."
	docker compose up -d --remove-orphans localstack
	@echo ">>> Waiting for LocalStack services..."
	@i=0; until (curl -s http://localhost:4566/_localstack/health | python3 -c "import json,sys; d=json.load(sys.stdin); s=d.get(\"services\",{}); [exit(1) for k in [\"s3\",\"sqs\",\"sns\",\"ses\",\"secretsmanager\",\"logs\",\"events\",\"scheduler\"] if s.get(k) not in (\"available\",\"running\",\"starting\")]" && curl -s http://localhost:4566/_localstack/init/ready | python3 -c "import json,sys; d=json.load(sys.stdin); sys.exit(0 if d.get('completed') is True else 1)") >/dev/null 2>&1; do i=$$((i+1)); [ $$i -ge 60 ] && break; sleep 2; done
	@echo ">>> LocalStack ready."

localstack-down: ## Stop LocalStack
	docker compose stop localstack

localstack-init: ## Re-run LocalStack init hooks (provisions queues, buckets, topics, secrets, ...) on the running container
	@echo ">>> Re-running LocalStack init hooks..."
	@docker compose exec -T localstack bash -c 'for f in /etc/localstack/init/ready.d/*.sh; do echo "  -> $$(basename $$f)"; bash "$$f"; done'
	@echo ">>> LocalStack resources provisioned (idempotent)."

aws-smoke: ## Run the AWS smoke check (verify LocalStack footprint)
	bin/rails aws:smoke

test: ## Run the test suite (Ruby + JavaScript)
	bundle exec rspec
	npm test

test-js: ## Run the JavaScript (Stimulus) test suite
	npm test

test-verbose: ## Run tests with verbose output
	bundle exec rspec --format documentation

lint: ## Run RuboCop linter
	bundle exec rubocop

lint-fix: ## Auto-fix lint issues
	bundle exec rubocop -a

console: ## Open Rails console
	bin/rails console

clean: ## Clean temporary files
	@echo ">>> Cleaning up..."
	bin/rails log:clear tmp:clear
	rm -rf app/assets/builds/*
	@echo ">>> Done."

.env: ## Create .env from .env.example if missing
	@if [ ! -f .env ]; then cp .env.example .env; echo ">>> Created .env from .env.example"; fi
