#!/usr/bin/env bash
#
# build.sh - Build dyld_info and dyld_shared_cache_util from Apple's open-source dyld
#
# This script clones Apple's dyld source, applies patches for public SDK compatibility,
# and builds the tools.
#

set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then
    set -o xtrace
fi

# Colors
export ESC_SEQ="\x1b["
export COL_RESET=$ESC_SEQ"39;49;00m"
export COL_RED=$ESC_SEQ"31;01m"
export COL_GREEN=$ESC_SEQ"32;01m"
export COL_YELLOW=$ESC_SEQ"33;01m"
export COL_BLUE=$ESC_SEQ"34;01m"
export COL_MAGENTA=$ESC_SEQ"35;01m"
export COL_CYAN=$ESC_SEQ"36;01m"

function running() {
    echo -e "$COL_MAGENTA ⇒ $COL_RESET""$1"
}

function info() {
    echo -e "$COL_BLUE[info]$COL_RESET $1"
}

function error() {
    echo -e "$COL_RED[error]$COL_RESET $1"
}

function warn() {
    echo -e "$COL_YELLOW[warn]$COL_RESET $1"
}

# Config
: ${MACOS:=""}
: ${BUILD_DIR:="build"}
: ${DIST_DIR:="dist"}

WORK_DIR="$PWD"
DYLD_REPO="https://github.com/apple-oss-distributions/dyld.git"

help() {
    cat << 'EOF'
Usage: build.sh [-h] [--clean]

This script builds Apple's dyld tools (dyld_info, dyld_shared_cache_util)
using the public macOS SDK.

Where:
    -h|--help       show this help text
    -c|--clean      cleans build artifacts and cloned repos

Environment Variables:
    MACOS           macOS version to build for (e.g., 26.1)
                    If not set, interactive menu is shown

Examples:
    ./build.sh                  # Interactive version selection
    MACOS=26.1 ./build.sh       # Build for macOS 26.1
    ./build.sh --clean          # Clean all build artifacts
EOF
    exit 0
}

clean() {
    running "Cleaning build directories..."
    declare -a paths_to_delete=(
        "${BUILD_DIR}"
        "${DIST_DIR}"
    )

    for path in "${paths_to_delete[@]}"; do
        if [ -d "${path}" ]; then
            info "Deleting ${path}"
            rm -rf "${path}"
        fi
    done
    echo "  🧹 Clean complete!"
}

install_deps() {
    if [ ! -x "$(command -v gum)" ]; then
        if [ -z "$MACOS" ]; then
            running "Installing gum for interactive menu..."
            if [ ! -x "$(command -v brew)" ]; then
                error "Please install homebrew - https://brew.sh (or set MACOS env var)"
                exit 1
            fi
            brew install gum
        fi
    fi
    if [ ! -x "$(command -v jq)" ]; then
        running "Installing jq for JSON parsing..."
        if [ ! -x "$(command -v brew)" ]; then
            error "Please install homebrew - https://brew.sh (or install jq manually)"
            exit 1
        fi
        brew install jq
    fi
    if ! command -v xcodebuild &> /dev/null; then
        error "xcodebuild is required but not installed (install Xcode Command Line Tools)"
        exit 1
    fi
}

choose_dyld() {
    if [ -z "$MACOS" ]; then
        gum style --border normal --margin "1" --padding "1 2" --border-foreground 212 \
            "Choose $(gum style --foreground 212 'macOS') version to build dyld tools for:"
        MACOS=$(gum choose "26.1")
    fi

    case ${MACOS} in
    '26.1')
        RELEASE_URL='https://raw.githubusercontent.com/apple-oss-distributions/distribution-macOS/macos-261/release.json'
        PATCH_DIR="${WORK_DIR}/patches/26.1"
        ;;
    *)
        error "Invalid/unsupported macOS version: ${MACOS}"
        error "Supported versions: 26.1"
        exit 1
        ;;
    esac

    # Get dyld version from release manifest
    DYLD_VERSION=$(curl -s "$RELEASE_URL" | jq -r '.projects[] | select(.project=="dyld") | .tag')
    if [ -z "$DYLD_VERSION" ]; then
        error "Failed to get dyld version from release manifest"
        exit 1
    fi

    info "Building dyld tools for macOS ${MACOS} (${DYLD_VERSION})"
}

clone_dyld() {
    if [ -d "${BUILD_DIR}/dyld" ]; then
        cd "${BUILD_DIR}/dyld"
        CURRENT_TAG=$(git describe --tags --exact-match 2>/dev/null || echo "unknown")
        cd "${WORK_DIR}"
        if [ "$CURRENT_TAG" == "$DYLD_VERSION" ]; then
            info "dyld ${DYLD_VERSION} already cloned"
            return
        fi
        warn "Version mismatch (have: $CURRENT_TAG, want: $DYLD_VERSION), re-cloning..."
        rm -rf "${BUILD_DIR}/dyld"
    fi

    running "⬇️ Cloning ${DYLD_VERSION}"
    mkdir -p "${BUILD_DIR}"
    git clone --depth 1 --branch "${DYLD_VERSION}" "${DYLD_REPO}" "${BUILD_DIR}/dyld"
}

apply_patches() {
    running "🩹 Applying patches from ${PATCH_DIR}"

    if [ ! -d "${PATCH_DIR}" ]; then
        error "Patch directory not found: ${PATCH_DIR}"
        exit 1
    fi

    cd "${BUILD_DIR}/dyld"

    # Run any setup scripts first
    if compgen -G "${PATCH_DIR}"'/*.sh' > /dev/null; then
        for script in "${PATCH_DIR}"/*.sh; do
            running "Running script: $(basename "$script")"
            bash "$script"
        done
    fi

    # Apply patches
    for patch in "${PATCH_DIR}"/*.patch; do
        if [ -f "$patch" ]; then
            PATCH_NAME=$(basename "$patch")
            if git apply --check "$patch" 2>/dev/null; then
                running "Applying: ${PATCH_NAME}"
                git apply "$patch"
            else
                warn "Patch ${PATCH_NAME} already applied or has conflicts, skipping..."
            fi
        fi
    done

    cd "${WORK_DIR}"
    info "All patches applied"
}

build_dyld() {
    running "📦 Building dyld_info and dyld_shared_cache_util (universal)"

    cd "${BUILD_DIR}/dyld"

    xcodebuild \
        -project dyld.xcodeproj \
        -target dyld_info \
        -target dyld_shared_cache_util \
        -arch arm64 -arch x86_64 \
        -configuration Release \
        ONLY_ACTIVE_ARCH=NO \
        2>&1 | while IFS= read -r line; do
            if [[ "$line" == *"error:"* ]]; then
                echo -e "${COL_RED}${line}${COL_RESET}"
            elif [[ "$line" == *"warning:"* ]]; then
                echo -e "${COL_YELLOW}${line}${COL_RESET}"
            elif [[ "$line" == *"BUILD SUCCEEDED"* ]]; then
                echo -e "${COL_GREEN}${line}${COL_RESET}"
            elif [[ "$line" == *"BUILD FAILED"* ]]; then
                echo -e "${COL_RED}${line}${COL_RESET}"
            fi
        done

    # Check if build succeeded
    if [ ! -f "build/Release/dyld_info" ] || [ ! -f "build/Release/dyld_shared_cache_util" ]; then
        error "Build failed - binaries not found"
        exit 1
    fi

    cd "${WORK_DIR}"
    info "Build completed successfully"
}

install_binaries() {
    running "📥 Installing binaries to ${DIST_DIR}"

    mkdir -p "${DIST_DIR}"

    cp "${BUILD_DIR}/dyld/build/Release/dyld_info" "${DIST_DIR}/"
    cp "${BUILD_DIR}/dyld/build/Release/dyld_shared_cache_util" "${DIST_DIR}/"

    # Strip debug symbols for smaller binaries
    strip "${DIST_DIR}/dyld_info" 2>/dev/null || true
    strip "${DIST_DIR}/dyld_shared_cache_util" 2>/dev/null || true

    # Ad-hoc sign binaries to avoid Gatekeeper killing them
    running "Signing binaries with ad-hoc signature..."
    codesign --force --sign - "${DIST_DIR}/dyld_info"
    codesign --force --sign - "${DIST_DIR}/dyld_shared_cache_util"

    # Verify signatures
    codesign --verify --verbose "${DIST_DIR}/dyld_info"
    codesign --verify --verbose "${DIST_DIR}/dyld_shared_cache_util"

    info "Installed binaries:"
    ls -lh "${DIST_DIR}"/dyld_*
}

verify_binaries() {
    running "✅ Verifying binaries"

    # Check dyld_info is universal
    if file "${DIST_DIR}/dyld_info" | grep -q "universal binary"; then
        info "dyld_info: ✓ universal"
        lipo -info "${DIST_DIR}/dyld_info"
    else
        error "dyld_info is not a universal binary"
        file "${DIST_DIR}/dyld_info"
        exit 1
    fi

    # Check dyld_shared_cache_util is universal
    if file "${DIST_DIR}/dyld_shared_cache_util" | grep -q "universal binary"; then
        info "dyld_shared_cache_util: ✓ universal"
        lipo -info "${DIST_DIR}/dyld_shared_cache_util"
    else
        error "dyld_shared_cache_util is not a universal binary"
        file "${DIST_DIR}/dyld_shared_cache_util"
        exit 1
    fi
}

main() {
    # Parse arguments
    while test $# -gt 0; do
        case "$1" in
        -h | --help)
            help
            ;;
        -c | --clean)
            clean
            exit 0
            ;;
        *)
            break
            ;;
        esac
    done

    install_deps
    choose_dyld
    clone_dyld
    apply_patches
    build_dyld
    install_binaries
    verify_binaries

    echo ""
    echo -e "  ${COL_GREEN}🎉 Build complete!${COL_RESET}"
    echo ""
    echo "  Binaries installed to: ${DIST_DIR}/"
    echo ""
    echo "  Usage examples:"
    echo "    ${DIST_DIR}/dyld_info /usr/lib/libSystem.B.dylib"
    echo "    ${DIST_DIR}/dyld_shared_cache_util -info /System/Volumes/Preboot/Cryptexes/OS/System/Library/dyld/dyld_shared_cache_arm64e"
    echo ""
}

main "$@"
