#!/bin/bash
# build.sh - Build Tailscale for MikroTik Container

set -eu

# Configuration
PLATFORM=${1:-"linux/arm64"} # Default to arm64 (common for CRS3xx/CRS5xx)
TAILSCALE_VERSION="1.80.0"
OUTPUT_FILE="tailscale.tar"

echo "Building Tailscale for $PLATFORM..."

# Clone Tailscale if not present
if [ ! -d "tailscale" ]; then
    echo "Cloning Tailscale v$TAILSCALE_VERSION..."
    git clone --depth 1 --branch "v$TAILSCALE_VERSION" https://github.com/tailscale/tailscale.git
fi

# Determine build arguments
cd tailscale
# Try to get version info from Tailscale's own build scripts if possible, 
# otherwise use defaults.
VERSION_LONG=$(git describe --tags --always --dirty || echo "v$TAILSCALE_VERSION")
VERSION_SHORT=$(git describe --tags --always || echo "$TAILSCALE_VERSION")
VERSION_GIT_HASH=$(git rev-parse HEAD || echo "unknown")
cd ..

# Build the container image
echo "Running Docker build..."
docker build \
  --build-arg VERSION_LONG="$VERSION_LONG" \
  --build-arg VERSION_SHORT="$VERSION_SHORT" \
  --build-arg VERSION_GIT_HASH="$VERSION_GIT_HASH" \
  --platform "$PLATFORM" \
  -t tailscale-mikrotik:latest .

# Save the image to a tarball
echo "Saving image to $OUTPUT_FILE..."
docker save tailscale-mikrotik:latest -o "$OUTPUT_FILE"

echo "Build complete: $OUTPUT_FILE"
