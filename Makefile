.DEFAULT_GOAL := help

.PHONY: help setup run dev docker-up docker-down docker-logs \
        localstack-up localstack-down db-migrate db-seed db-reset \
        test test-verbose lint lint-fix console clean install

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

setup: .env docker-up install db-setup ## First-time project setup (Docker + gems + DB)
	@echo ">>> Setup complete. Run 'make dev' to start."

run: docker-up ## Start all services and the Rails server
	@echo ">>> Starting Rails server..."
	bin/rails server -b 0.0.0.0

dev: docker-up ## Start dev environment with Foreman (hot reload)
	@echo ">>> Starting dev environment..."
	bin/dev

install: ## Install Ruby dependencies
	@echo ">>> Installing gems..."
	bundle install

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

docker-up: ## Start Docker services (postgres, redis)
	@echo ">>> Starting Docker services..."
	docker compose up -d postgres redis
	@echo ">>> Waiting for PostgreSQL..."
	@timeout 30 sh -c 'until docker compose exec postgres pg_isready -U $$(grep POSTGRES_USER .env 2>/dev/null | cut -d= -f2 || echo "tovitu") 2>/dev/null; do sleep 1; done' || true
	@echo ">>> Core services ready."

docker-down: ## Stop all Docker services
	@echo ">>> Stopping Docker services..."
	docker compose down

docker-logs: ## View Docker service logs
	docker compose logs -f

localstack-up: ## Start LocalStack (S3-compatible storage for dev)
	@echo ">>> Starting LocalStack..."
	docker compose up -d localstack
	@echo ">>> Waiting for LocalStack..."
	@timeout 30 sh -c 'until curl -s http://localhost:4566/_localstack/health | grep -q "\"s3\": \"running\"" 2>/dev/null; do sleep 1; done' || true
	@echo ">>> LocalStack ready."

localstack-down: ## Stop LocalStack
	docker compose stop localstack

test: ## Run the test suite
	bundle exec rspec

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
