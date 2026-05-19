# UMIRA Backend Makefile
# Node.js + Fastify + TypeScript + Prisma

.PHONY: help install dev build start lint test clean \
        db-generate db-migrate db-seed db-reset

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ──────────────────────────────────────────────
# Package Management
# ──────────────────────────────────────────────

install: ## Install npm dependencies
	npm install
	npx prisma generate

# ──────────────────────────────────────────────
# Development
# ──────────────────────────────────────────────

dev: ## Start dev server with hot-reload
	tsx watch src/server.ts

start: ## Start production server
	node dist/server.js

build: ## Compile TypeScript to dist/
	npx prisma generate
	tsc -p tsconfig.json

# ──────────────────────────────────────────────
# Linting & Testing
# ──────────────────────────────────────────────

lint: ## Run ESLint
	eslint src --ext .ts

test: ## Run Vitest tests
	vitest run

test-watch: ## Run Vitest in watch mode
	vitest

# ──────────────────────────────────────────────
# Database (Prisma)
# ──────────────────────────────────────────────

db-generate: ## Generate Prisma client
	npx prisma generate

db-migrate: ## Apply pending migrations
	npx prisma migrate dev

db-seed: ## Seed database with demo data
	tsx prisma/seed.ts

db-reset: ## Reset database (drop, re-migrate, re-seed)
	npx prisma migrate reset --force

db-studio: ## Open Prisma Studio (GUI)
	npx prisma studio

# ──────────────────────────────────────────────
# Housekeeping
# ──────────────────────────────────────────────

clean: ## Remove node_modules and dist/
	rm -rf node_modules dist
