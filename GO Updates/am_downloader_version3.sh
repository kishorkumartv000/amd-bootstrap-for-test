#!/bin/bash
# Apple Music Downloader - Resilient Version with Go Fallback
set -e

# Fallback paths
CUSTOM_GO_BIN="$HOME/go-sdk/go/bin"
SYSTEM_GO_BIN="/usr/local/go/bin"

# Check if Go exists in custom path
if [ -x "$CUSTOM_GO_BIN/go" ]; then
    export PATH="$PATH:$CUSTOM_GO_BIN"
    echo "Using Go from custom path: $CUSTOM_GO_BIN"
elif [ -x "$SYSTEM_GO_BIN/go" ]; then
    export PATH="$PATH:$SYSTEM_GO_BIN"
    echo "Using Go from system path: $SYSTEM_GO_BIN"
elif command -v go >/dev/null 2>&1; then
    echo "Using Go from system environment: $(command -v go)"
else
    echo "❌ Go compiler not found in custom or system paths."
    echo "Please run the installer script to set up Go correctly."
    exit 1
fi

# Change to Go project directory
cd "$HOME/amalac"

# Build the download command
cmd=(
    go run main.go
    "$@"
)

# Execute download
echo "Starting Apple Music download..."
"${cmd[@]}"

# Output success message
echo "✅ Download completed successfully!"
