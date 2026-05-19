# UMIRA Mobile Makefile
# Flutter

.PHONY: help setup analyze test build-apk build-apk-release build-ios build-web clean \
        build-web-dev build-web-staging build-web-prod build-apk-staging build-apk-prod

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ──────────────────────────────────────────────
# Setup
# ──────────────────────────────────────────────

setup: ## Install Flutter dependencies
	flutter pub get

# ──────────────────────────────────────────────
# Analysis & Testing
# ──────────────────────────────────────────────

analyze: ## Run Flutter analyzer
	flutter analyze

test: ## Run Flutter tests
	flutter test

# ──────────────────────────────────────────────
# Build — Development (defaults)
# ──────────────────────────────────────────────

build-apk: ## Build Android APK (debug, development env)
	flutter build apk --debug

build-web: ## Build web (development env)
	flutter build web

build-ios: ## Build iOS dev (requires macOS + Xcode)
	flutter build ios --no-codesign

# ──────────────────────────────────────────────
# Build — Staging
# ──────────────────────────────────────────────

build-web-staging: ## Build web for staging
	flutter build web --release \
		--dart-define=ENVIRONMENT=staging \
		--dart-define=UMIRA_API_URL=https://staging.api.umira.app/v1

build-apk-staging: ## Build Android APK for staging
	flutter build apk --release \
		--dart-define=ENVIRONMENT=staging \
		--dart-define=UMIRA_API_URL=https://staging.api.umira.app/v1

# ──────────────────────────────────────────────
# Build — Production
# ──────────────────────────────────────────────

build-web-prod: ## Build web for production (with Sentry)
	flutter build web --release \
		--dart-define=ENVIRONMENT=production \
		--dart-define=UMIRA_API_URL=https://api.umira.app/v1 \
		--dart-define=SENTRY_DSN=$(SENTRY_DSN)

build-apk-prod: ## Build Android APK for production (with Sentry)
	flutter build apk --release \
		--dart-define=ENVIRONMENT=production \
		--dart-define=UMIRA_API_URL=https://api.umira.app/v1 \
		--dart-define=SENTRY_DSN=$(SENTRY_DSN)

# ──────────────────────────────────────────────
# Utilities
# ──────────────────────────────────────────────

format: ## Format Dart source code
	dart format lib/

# ──────────────────────────────────────────────
# Housekeeping
# ──────────────────────────────────────────────

clean: ## Clean Flutter build artifacts
	flutter clean
	rm -rf .dart_tool/
