# darwin-dyld-build

![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/blacktop/darwin-dyld-build/total)
 [![LICENSE](https://img.shields.io/:license-mit-blue.svg)](https://doge.mit-license.org)

Build Apple's `dyld_info` and `dyld_shared_cache_util` tools from open source using the **public macOS SDK**.

## Overview

Apple's [dyld](https://github.com/apple-oss-distributions/dyld) (dynamic linker) is open source, but the official source requires Apple's internal SDK to build. This project provides patches that enable building with the standard public Xcode SDK.

### What's Included

| Tool | Description |
|------|-------------|
| `dyld_info` | Analyze Mach-O binaries - segments, sections, symbols, fixups, etc. |
| `dyld_shared_cache_util` | Inspect and extract from the dyld shared cache |

## Installation

### Homebrew (Recommended)

```bash
brew tap blacktop/tap
brew install dyld-tools
```

### Download Binary

Download pre-built binaries from the [Releases](https://github.com/blacktop/darwin-dyld-build/releases) page.

### Build from Source

```bash
git clone https://github.com/blacktop/darwin-dyld-build.git
cd darwin-dyld-build

# Interactive version selection (requires gum)
./build.sh

# Or specify version directly
MACOS=26.1 ./build.sh
```

Binaries will be in `dist/`.

## Usage

### dyld_info

Analyze Mach-O binaries:

```bash
# Show all info about a binary
dyld_info /usr/lib/libSystem.B.dylib

# Show specific information
dyld_info -segments /usr/bin/ls
dyld_info -exports /usr/lib/libc.dylib
dyld_info -fixups /usr/bin/clang
```

### dyld_shared_cache_util

Inspect and extract from the shared cache:

```bash
# Path to shared cache (macOS 11+)
CACHE="/System/Volumes/Preboot/Cryptexes/OS/System/Library/dyld/dyld_shared_cache_arm64e"

# Show cache info
dyld_shared_cache_util -info $CACHE

# List all images in cache
dyld_shared_cache_util -list $CACHE

# Extract all dylibs
dyld_shared_cache_util -extract /tmp/extracted $CACHE

# Show exports
dyld_shared_cache_util -exports $CACHE

# Generate JSON map
dyld_shared_cache_util -json-map $CACHE > cache-map.json
```

## Supported Versions

| macOS | dyld Version | Status |
|-------|--------------|--------|
| 26.1  | dyld-1330    | ✓ Supported |

*More versions coming soon*

## License

The patches in this repository are provided under the MIT License.

The dyld source code itself is licensed under the [Apple Public Source License 2.0](https://opensource.apple.com/license/apsl/).
