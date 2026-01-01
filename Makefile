# darwin-dyld-build Makefile
#
# Usage:
#   make build             - Build dyld tools (interactive version selection)
#   MACOS=26.1 make build  - Build for specific macOS version
#   make clean             - Clean build artifacts
#   make install           - Install to /usr/local/bin

MACOS ?=
BUILD_DIR ?= build
DIST_DIR ?= dist
INSTALL_DIR ?= /usr/local/bin

.PHONY: all build clean install test release help

all: build

help:
	@echo "darwin-dyld-build"
	@echo ""
	@echo "Usage:"
	@echo "  make build              Build dyld_info and dyld_shared_cache_util"
	@echo "  make clean              Remove build artifacts"
	@echo "  make install            Install binaries to $(INSTALL_DIR)"
	@echo "  make test               Verify built binaries work"
	@echo "  make release            Create release archive"
	@echo ""
	@echo "Variables:"
	@echo "  MACOS          macOS version to build (e.g., 26.1)"
	@echo "  BUILD_DIR      Build directory (default: $(BUILD_DIR))"
	@echo "  DIST_DIR       Output directory (default: $(DIST_DIR))"
	@echo "  INSTALL_DIR    Install directory (default: $(INSTALL_DIR))"
	@echo ""
	@echo "Examples:"
	@echo "  make build                    # Interactive version selection"
	@echo "  MACOS=26.1 make build         # Build for macOS 26.1"

build:
	@MACOS=$(MACOS) BUILD_DIR=$(BUILD_DIR) DIST_DIR=$(DIST_DIR) ./build.sh

clean:
	@./build.sh --clean

install: build
	@echo " > Installing to $(INSTALL_DIR)..."
	@install -d $(INSTALL_DIR)
	@install -m 755 $(DIST_DIR)/dyld_info $(INSTALL_DIR)/
	@install -m 755 $(DIST_DIR)/dyld_shared_cache_util $(INSTALL_DIR)/
	@echo " ✓ Installed dyld_info and dyld_shared_cache_util to $(INSTALL_DIR)"

test: build
	@echo " > Testing binaries..."
	@$(DIST_DIR)/dyld_shared_cache_util 2>&1 | grep -q "Usage:" && echo " ✓ dyld_shared_cache_util: OK" || echo " ✗ dyld_shared_cache_util: FAIL"
	@file $(DIST_DIR)/dyld_info | grep -q "Mach-O" && echo " ✓ dyld_info: OK" || echo " ✗ dyld_info: FAIL"

release: build
	@echo " > Creating release archive..."
	@mkdir -p release
	@ARCH=$$(uname -m) && cd $(DIST_DIR) && tar -czvf ../release/dyld-tools-$$ARCH.tar.gz * && cd ..
	@ARCH=$$(uname -m) && echo " ✓ Created release/dyld-tools-$$ARCH.tar.gz"
	@ARCH=$$(uname -m) && shasum -a 256 release/dyld-tools-$$ARCH.tar.gz

.DEFAULT_GOAL := build
