#!/bin/bash
echo "=== Uninstalling Go and Apple Music Downloader ==="

# Configuration
CUSTOM_BINARY_NAME=am_downloader
GO_BIN="$HOME/go-sdk/go/bin"

# Remove system-wide Go installation
sudo rm -rf /usr/local/go

# Remove local Go installation
rm -rf "$HOME/go-sdk"

# Remove Go-related symlinks (fallback and manual)
sudo rm -f /usr/bin/go /usr/bin/gofmt
sudo rm -f /usr/local/bin/go /usr/local/bin/gofmt

# Remove custom binary if installed globally
sudo rm -f /usr/local/bin/$CUSTOM_BINARY_NAME

# Remove Go workspace cache and mod cache
rm -rf ~/go/pkg/mod
rm -rf ~/go/bin
rm -rf ~/go/src

# Remove Go path from shell config
sed -i '/\/usr\/local\/go\/bin/d' ~/.bashrc
sed -i '/\/usr\/local\/go\/bin/d' ~/.zshrc
sed -i "\|$GO_BIN|d" ~/.bashrc
sed -i "\|$GO_BIN|d" ~/.zshrc

# Reload shell config
source ~/.bashrc 2>/dev/null || source ~/.zshrc 2>/dev/null

# Remove Apple Music Downloader project
rm -rf ~/amalac

# Remove Apple Music output directories
rm -rf "$HOME/Music/Apple Music/alac"
rm -rf "$HOME/Music/Apple Music/atmos"
rm -rf "$HOME/Music/Apple Music/aac"

echo "✅ Go and Apple Music Downloader have been fully removed from your system."
