#!/bin/bash
# Apple Music Downloader - Simplified Version
set -e

# Explicitly add Go to PATH (corrected)
export PATH="$PATH:$HOME/go-sdk/go/bin"

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
echo "Download completed successfully!"
