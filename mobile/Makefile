# UMIRA Mobile Makefile
# Flutter

.PHONY: help setup analyze test build-apk build-ios build-web clean

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
# Build
# ──────────────────────────────────────────────

build-apk: ## Build Android APK (debug)
	flutter build apk --debug

build-apk-release: ## Build Android APK (release)
	flutter build apk --release

build-ios: ## Build iOS (requires macOS + Xcode)
	flutter build ios --no-codesign

build-web: ## Build web (experimental)
	flutter build web

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
