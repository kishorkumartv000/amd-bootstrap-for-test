#!/bin/bash

# Apple Music Downloader - Resilient Version with Go Fallback
set -e

# Configuration
USE_FALLBACK=true
USE_CUSTOM_GO=true
USE_SYSTEM_GO=true

# Fallback paths
CUSTOM_GO_BIN="$HOME/go-sdk/go/bin"
SYSTEM_GO_BIN="/usr/local/go/bin"

# Check if Go exists
if [ "$USE_FALLBACK" = true ]; then
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
else
    if [ "$USE_CUSTOM_GO" = true ] && [ -x "$CUSTOM_GO_BIN/go" ]; then
        export PATH="$PATH:$CUSTOM_GO_BIN"
        echo "Using Go from custom path (forced): $CUSTOM_GO_BIN"
    elif [ "$USE_SYSTEM_GO" = true ] && [ -x "$SYSTEM_GO_BIN/go" ]; then
        export PATH="$PATH:$SYSTEM_GO_BIN"
        echo "Using Go from system path (forced): $SYSTEM_GO_BIN"
    else
        echo "❌ Go compiler not found or no path selected."
        echo "Please check your flags or run the installer script."
        exit 1
    fi
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
