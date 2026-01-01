# Contributing

## How to Contribute

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Adding Support for New macOS Versions

1. Create a new patch directory: `patches/<version>/`
2. Add the case to `choose_dyld()` in `build.sh`
3. Test the build
4. Submit a PR

## Requirements

- macOS 13+ (Ventura or later)
- Xcode 15+ with Command Line Tools
- Git
- [jq](https://jqlang.github.io/jq/) (for JSON parsing, auto-installed via brew)
- [gum](https://github.com/charmbracelet/gum) (for interactive UI, auto-installed via brew)

## Build Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MACOS` | (interactive) | macOS version to build for (e.g., 26.1) |
| `BUILD_DIR` | `build` | Build directory |
| `DIST_DIR` | `dist` | Output directory for binaries |

### Using Make

```bash
# Interactive version selection
make build

# Build for specific version
MACOS=26.1 make build

# Install to /usr/local/bin
sudo make install

# Clean build artifacts
make clean
```

## Project Structure

```
.
├── patches/
│   └── 26.1/
│       └── 001-public-sdk-compatibility.patch
├── .github/
│   └── workflows/
│       ├── build.yml
│       └── homebrew.yml
├── build.sh
├── Makefile
├── LICENSE
└── README.md
```
