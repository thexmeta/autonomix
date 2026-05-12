# Autonomix Makefile
# Centralized command aliases for Flutter build and Debian packaging

.PHONY: dev build build-deb bump-build bump-patch help

# Default target
all: help

## Development
dev:
	flutter run -d linux

## Build
build:
	flutter build linux --release

## Debian Packaging
# Bumps the build number (Y) only after a successful build
build-deb:
	./scripts/create-debian-package.sh
	@$(MAKE) bump-build

## Version Management
bump-build:
	@./scripts/bump-version.sh --build

bump-patch:
	@./scripts/bump-version.sh --patch

## Help
help:
	@echo "Autonomix Build System"
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  dev          - Run the application in development mode (Linux)"
	@echo "  build        - Build the Flutter Linux release bundle"
	@echo "  build-deb    - Build the Debian package and increment build number (Y)"
	@echo "  bump-build   - Manually increment build number (0.3.X-bY -> 0.3.X-bY+1)"
	@echo "  bump-patch   - Manually increment patch version (0.3.X -> 0.3.X+1, reset bY=1)"
	@echo "  help         - Show this help message"
