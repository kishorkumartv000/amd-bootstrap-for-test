#!/bin/bash
# Apple Music Downloader Installer (Minimal Version)
set -e

echo "=== Apple Music Downloader Installation ==="
echo "This script will install all required dependencies for downloading"
echo "Apple Music tracks in ALAC and Atmos formats with cloud sync capability"

# Configuration
ALAC_DIR="$HOME/Music/Apple Music/alac"
ATMOS_DIR="$HOME/Music/Apple Music/atmos"
AAC_DIR="$HOME/Music/Apple Music/aac"

# 1. Install Go 1.25.0
echo "Step 1/5: Installing Go language..."
sudo rm -rf /usr/local/go /usr/lib/go-* 2>/dev/null || true

ARCH=$(uname -m)
case $ARCH in
    x86_64) GO_ARCH="amd64" ;;
    aarch64) GO_ARCH="arm64" ;;
    armv7l) GO_ARCH="armv6l" ;;
    i686) GO_ARCH="386" ;;
    *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

echo "Downloading Go 1.25.0 for $ARCH..."
wget -q --show-progress "https://go.dev/dl/go1.25.0.linux-${GO_ARCH}.tar.gz" -O /tmp/go.tar.gz
sudo tar -C /usr/local -xzf /tmp/go.tar.gz
rm /tmp/go.tar.gz

echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc
echo "Go 1.25.0 installed to /usr/local/go"

# 2. Setup Project
echo "Step 2/5: Setting up downloader project..."
if [ ! -d "$HOME/amalac" ]; then
    echo "Cloning repository..."
    git clone https://github.com/zhaarey/apple-music-alac-atmos-downloader.git "$HOME/amalac"
else
    echo "Updating existing repository..."
    cd "$HOME/amalac"
    git pull origin master
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
    echo "Updated config.yaml with local paths"
else
    echo "alac-save-folder: $ALAC_DIR" > config.yaml
    echo "atmos-save-folder: $ATMOS_DIR" >> config.yaml
    echo "aac-save-folder: $AAC_DIR" >> config.yaml
    echo "Created config.yaml with local paths"
fi

# 3. Build Project
echo "Step 3/5: Building application..."
cd "$HOME/amalac"
/usr/local/go/bin/go clean -modcache
/usr/local/go/bin/go get -u ./...
/usr/local/go/bin/go mod tidy
echo "Application built successfully!"

# 4. Create default config for downloader
CONFIG_FILE="$HOME/amalac/am_downloader.conf"
if [ ! -f "$CONFIG_FILE" ]; then
    cat > "$CONFIG_FILE" <<EOL
# Cloud Storage Configuration
# Available remotes: (run 'rclone listremotes' to see options)
ACTIVE_REMOTES=("your_remote_name")
CLOUD_BASE_PATH="AppleMusic"

# Local Directories
MUSIC_BASE_DIR="$HOME/Music/Apple Music"
ALAC_DIR="$MUSIC_BASE_DIR/alac"
ATMOS_DIR="$MUSIC_BASE_DIR/atmos"

# Sync Options
DELETE_AFTER_SYNC=true
SYNC_CONCURRENCY=4
LOG_FILE="$HOME/amalac/sync.log"

# Rclone Configuration Path
# RCLONE_CONFIG_PATH="$HOME/.config/rclone/rclone.conf"
EOL
    echo "Created default configuration: $CONFIG_FILE"
fi

# 5. Finalize installation
echo "Step 5/5: Finalizing installation..."


echo "=== Installation Complete! ==="
echo "Your Apple Music downloader is ready to use."
