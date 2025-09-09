#!/bin/bash
echo "=== Uninstalling Go and Apple Music Downloader ==="

# Remove Go installation directory
sudo rm -rf /usr/local/go

# Remove any Go-related symlinks or binaries (if manually linked)
sudo rm -f /usr/bin/go /usr/bin/gofmt

# Remove Go workspace cache and mod cache
rm -rf ~/go/pkg/mod
rm -rf ~/go/bin
rm -rf ~/go/src

# Remove Go path from shell config
sed -i '/\/usr\/local\/go\/bin/d' ~/.bashrc
sed -i '/\/usr\/local\/go\/bin/d' ~/.zshrc

# Reload shell config
source ~/.bashrc 2>/dev/null || source ~/.zshrc 2>/dev/null

# Remove Apple Music Downloader project
rm -rf ~/amalac

# Remove Apple Music output directories
rm -rf "$HOME/Music/Apple Music/alac"
rm -rf "$HOME/Music/Apple Music/atmos"
rm -rf "$HOME/Music/Apple Music/aac"

echo "✅ Go and Apple Music Downloader have been fully removed from your system."
