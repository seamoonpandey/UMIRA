# UMIRA Monorepo Makefile
# Orchestrates backend (Node.js/Fastify/Prisma) and mobile (Flutter)

.PHONY: help setup dev build test lint clean docker-up docker-down docker-up-all \
        db-migrate db-seed db-reset check

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ──────────────────────────────────────────────
# Setup
# ──────────────────────────────────────────────

setup: ## Install all dependencies and prepare the project
	@if [ ! -f backend/.env ]; then \
		cp backend/.env.example backend/.env; \
		echo "Created backend/.env from .env.example — edit secrets as needed"; \
	fi
	$(MAKE) -C backend install
	$(MAKE) -C mobile setup
	$(MAKE) db-migrate

# ──────────────────────────────────────────────
# Development
# ──────────────────────────────────────────────

dev: ## Start full dev environment (Docker + backend)
	$(MAKE) docker-up
	$(MAKE) -C backend dev

dev-backend: ## Start backend in dev mode only
	$(MAKE) -C backend dev

# ──────────────────────────────────────────────
# Build
# ──────────────────────────────────────────────

build: ## Build backend (for mobile, use build-android / build-ios separately)
	$(MAKE) -C backend build

build-android: ## Build Flutter Android APK
	$(MAKE) -C mobile build-android

build-ios: ## Build Flutter iOS bundle
	$(MAKE) -C mobile build-ios

# ──────────────────────────────────────────────
# Testing & Linting
# ──────────────────────────────────────────────

test: ## Run all tests
	$(MAKE) -C backend test
	$(MAKE) -C mobile test

lint: ## Run all linters
	$(MAKE) -C backend lint
	$(MAKE) -C mobile analyze

check: lint test ## Run linters + tests (CI entry point)

# ──────────────────────────────────────────────
# Database
# ──────────────────────────────────────────────

db-migrate: ## Run Prisma migrations
	$(MAKE) -C backend db-migrate

db-seed: ## Seed the database with demo data
	$(MAKE) -C backend db-seed

db-reset: ## Reset database (drops data, re-runs migrations, re-seeds)
	$(MAKE) -C backend db-reset

# ──────────────────────────────────────────────
# Docker
# ──────────────────────────────────────────────

docker-up: ## Start Docker services (postgres + redis)
	docker compose up -d postgres redis

docker-down: ## Stop Docker services
	docker compose down

docker-build: ## Build production Docker image for backend
	docker compose build backend

docker-up-all: ## Start full production stack (all docker-compose services)
	docker compose up -d

docker-logs: ## Tail Docker logs
	docker compose logs -f

# ──────────────────────────────────────────────
# Housekeeping
# ──────────────────────────────────────────────

clean: ## Clean all build artifacts and dependencies
	$(MAKE) -C backend clean
	$(MAKE) -C mobile clean
