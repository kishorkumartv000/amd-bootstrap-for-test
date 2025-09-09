#!/bin/bash
# Apple Music Downloader Installer (User-local Go install with source toggle + fallback + build fix + go.mod upgrade)
set -e

echo "=== Apple Music Downloader Installation ==="
echo "This script installs dependencies for downloading Apple Music tracks in ALAC, Atmos, and AAC formats with cloud sync support."

# Configuration
USE_OFFICIAL_GO=true  # Set to false to use custom GitHub mirror
GO_VERSION="1.25.1"
ALAC_DIR="$HOME/Music/Apple Music/alac"
ATMOS_DIR="$HOME/Music/Apple Music/atmos"
AAC_DIR="$HOME/Music/Apple Music/aac"
GO_DIR="$HOME/go-sdk"
GO_BIN="$GO_DIR/go/bin"

# Step 1: Install Go
echo "Step 1/5: Installing Go language to $GO_DIR..."

rm -rf "$GO_DIR"

ARCH=$(uname -m)
if [ "$ARCH" != "x86_64" ]; then
    echo "❌ This custom Go build is only for amd64 (x86_64). Detected: $ARCH"
    exit 1
fi

mkdir -p "$GO_DIR"

if [ "$USE_OFFICIAL_GO" = true ]; then
    echo "Downloading Go $GO_VERSION from official source..."
    wget -q --show-progress "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -O /tmp/go.tar.gz
else
    echo "Downloading Go $GO_VERSION from custom GitHub mirror..."
    wget -q --show-progress "https://github.com/kishorkumartv000/amd-bootstrap-for-test/releases/download/v0.1/go${GO_VERSION}.linux-amd64.tar.gz" -O /tmp/go.tar.gz
fi

tar -C "$GO_DIR" -xzf /tmp/go.tar.gz
rm /tmp/go.tar.gz

echo "export PATH=\$PATH:$GO_BIN" >> ~/.bashrc
export PATH=$PATH:$GO_BIN
echo "✅ Go $GO_VERSION installed to $GO_BIN"

# Optional fallback symlink
if [ ! -x "/usr/local/go/bin/go" ] && [ -x "$GO_BIN/go" ]; then
    echo "Creating fallback symlink for global access..."
    sudo ln -sf "$GO_BIN/go" /usr/local/bin/go
fi

# Verify Go installation
if ! command -v go >/dev/null 2>&1; then
    echo "❌ Go installation failed or PATH not updated. Please restart your shell or source ~/.bashrc"
    exit 1
fi

# Step 2: Setup Project
echo "Step 2/5: Setting up downloader project..."
if [ ! -d "$HOME/amalac" ]; then
    echo "Cloning repository from Bitbucket..."
    git clone https://tvkishorkumarofficial-admin@bitbucket.org/tvkishorkumarofficial/apple-music-downloader.git "$HOME/amalac"
else
    echo "Updating existing repository..."
    cd "$HOME/amalac"
    if git ls-files -u | grep -q go.mod; then
        echo "❌ Merge conflict detected in go.mod. Please resolve it manually before continuing."
        exit 1
    fi
    git stash push -m "installer-temp-fix" || true
    git pull origin main
    git stash pop || true
    cd ..
fi

mkdir -p "$ALAC_DIR" "$ATMOS_DIR" "$AAC_DIR"

cd "$HOME/amalac"
if [ -f "config.yaml" ]; then
    sed -i "s|alac-save-folder: .*|alac-save-folder: $ALAC_DIR|" config.yaml
    sed -i "s|atmos-save-folder: .*|atmos-save-folder: $ATMOS_DIR|" config.yaml
    if grep -q "^aac-save-folder:" config.yaml; then
        sed -i "s|aac-save-folder: .*|aac-save-folder: $AAC_DIR|" config.yaml
    else
        echo "aac-save-folder: $AAC_DIR" >> config.yaml
    fi
    echo "✅ Updated config.yaml with local paths"
else
    echo "alac-save-folder: $ALAC_DIR" > config.yaml
    echo "atmos-save-folder: $ATMOS_DIR" >> config.yaml
    echo "aac-save-folder: $AAC_DIR" >> config.yaml
    echo "✅ Created config.yaml with local paths"
fi

# Step 3: Sanitize and Upgrade go.mod
echo "Step 3/5: Sanitizing and upgrading go.mod..."
cd "$HOME/amalac"

# Remove any invalid 'go get' lines
sed -i '/^go get /d' go.mod

# Upgrade go version directive to match installed version
INSTALLED_GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
if grep -q "^go " go.mod; then
    sed -i "s/^go .*/go ${INSTALLED_GO_VERSION}/" go.mod
    echo "✅ Updated go.mod to use Go ${INSTALLED_GO_VERSION}"
else
    echo "go ${INSTALLED_GO_VERSION}" >> go.mod
    echo "✅ Added go version directive to go.mod"
fi

# Step 4: Build Project
echo "Step 4/5: Building application..."
go clean -modcache
go get -u ./...
go mod tidy

# Step 5: Final Check
echo "Step 5/5: Verifying build..."
if [ ! -f "main.go" ]; then
    echo "❌ main.go not found in $HOME/amalac. Cannot build."
    exit 1
fi

if go build -o am_downloader .; then
    echo "✅ Build successful! Executable created: am_downloader"
else
    echo "❌ Build failed. Please check go.mod and dependencies."
    exit 1
fi

echo "=== Installation Complete! ==="
echo "Your Apple Music downloader is ready to use."
