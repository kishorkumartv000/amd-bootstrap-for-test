#!/bin/bash
# Apple Music Downloader Installer (Fixed Version)
set -e

echo "=== Apple Music Downloader Installation ==="
echo "This script will install all required dependencies for downloading"
echo "Apple Music tracks in ALAC and Atmos formats with cloud sync capability"

# Configuration
ALAC_DIR="$HOME/Music/Apple Music/alac"
ATMOS_DIR="$HOME/Music/Apple Music/atmos"
AAC_DIR="$HOME/Music/Apple Music/aac"
RCLONE_CONF_DIR="$HOME/.config/rclone"
RCLONE_CONF="$RCLONE_CONF_DIR/rclone.conf"
BENTO4_TEMP="/tmp/Bento4"
M3U8DL_TEMP="/tmp/N_m3u8DL-RE"

# 1. System Update & Dependencies
echo "Step 1/10: Updating system packages..."
sudo apt update -y
sudo apt upgrade -y
echo "Installing required dependencies..."
sudo apt install -y git ffmpeg build-essential zlib1g-dev wget cmake pkg-config libssl-dev unzip

# 2. Install rclone
echo "Step 2/10: Checking rclone installation..."
if ! command -v rclone &> /dev/null; then
    echo "Installing rclone..."
    sudo apt install -y rclone
else
    echo "rclone already installed."
fi

# Create rclone config directory
mkdir -p "$RCLONE_CONF_DIR"
[ -f "$RCLONE_CONF" ] || touch "$RCLONE_CONF"

# 3. Install N_m3u8DL-RE
echo "Step 3/10: Installing N_m3u8DL-RE..."
mkdir -p "$M3U8DL_TEMP"
cd "$M3U8DL_TEMP"
wget -q --show-progress "https://github.com/nilaoda/N_m3u8DL-RE/releases/download/v0.3.0-beta/N_m3u8DL-RE_v0.3.0-beta_linux-x64_20241203.tar.gz"
tar -xzf N_m3u8DL-RE_v0.3.0-beta_linux-x64_20241203.tar.gz
sudo cp N_m3u8DL-RE /usr/bin/
sudo chmod +x /usr/bin/N_m3u8DL-RE
cd "$HOME"
rm -rf "$M3U8DL_TEMP"
echo "N_m3u8DL-RE installed to /usr/bin/N_m3u8DL-RE"

# 4. Install GPAC/MP4Box
echo "Step 4/10: Installing multimedia tools (MP4Box)..."
install_gpac() {
    if sudo apt install -y gpac 2>/dev/null; then 
        echo "Installed GPAC from repository."
        return 0
    fi
    
    if sudo apt install -y mp4v2-utils 2>/dev/null; then
        echo "Installed mp4v2-utils as MP4Box alternative."
        return 0
    fi
    
    echo "Building GPAC from source (this may take several minutes)..."
    temp_dir=$(mktemp -d)
    cd "$temp_dir"
    git clone https://github.com/gpac/gpac.git
    cd gpac
    ./configure --static-mp4box
    make -j$(nproc)
    sudo make install
    cd
    rm -rf "$temp_dir"
    echo "Successfully built and installed GPAC from source."
}
install_gpac

# 5. Install Bento4 (Fixed with overwrite protection)
echo "Step 5/10: Installing Bento4 tools..."
sudo apt install -y zip unzip libxml2 libxslt1.1
mkdir -p "$BENTO4_TEMP"
cd "$BENTO4_TEMP"
echo "Downloading Bento4 binaries..."
wget -q --show-progress "https://www.bok.net/Bento4/binaries/Bento4-SDK-1-6-0-641.x86_64-unknown-linux.zip"
unzip -o -q Bento4-SDK-1-6-0-641.x86_64-unknown-linux.zip

cd Bento4-SDK-1-6-0-641.x86_64-unknown-linux
echo "Installing Bento4 binaries to /usr/local/bin..."
sudo find bin/ -maxdepth 1 -type f -executable -exec cp {} /usr/local/bin \;
sudo cp -r include /usr/local/include/Bento4
sudo cp -r lib /usr/local/lib/Bento4

cd "$HOME"
rm -rf "$BENTO4_TEMP"
echo "Bento4 tools installed successfully!"

# 6. Install Go 1.23.1
echo "Step 6/10: Installing Go language..."
sudo rm -rf /usr/local/go /usr/lib/go-* 2>/dev/null || true

ARCH=$(uname -m)
case $ARCH in
    x86_64) GO_ARCH="amd64" ;;
    aarch64) GO_ARCH="arm64" ;;
    armv7l) GO_ARCH="armv6l" ;;
    i686) GO_ARCH="386" ;;
    *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

echo "Downloading Go 1.23.1 for $ARCH..."
wget -q --show-progress "https://go.dev/dl/go1.23.1.linux-${GO_ARCH}.tar.gz" -O /tmp/go.tar.gz
sudo tar -C /usr/local -xzf /tmp/go.tar.gz
rm /tmp/go.tar.gz

echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc
echo "Go 1.23.1 installed to /usr/local/go"

# 7. Setup Project
echo "Step 7/10: Setting up downloader project..."
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

# 8. Build Project
echo "Step 8/10: Building application..."
cd "$HOME/amalac"
/usr/local/go/bin/go clean -modcache
/usr/local/go/bin/go get -u ./...
/usr/local/go/bin/go mod tidy
echo "Application built successfully!"

# 9. Create default config for downloader
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

# 10. Finalize installation
echo "Step 10/10: Finalizing installation..."
chmod +x "$HOME/amalac/am_downloader.sh"

echo "=== Installation Complete! ==="
echo "Your Apple Music downloader is ready to use."
echo ""
echo "Next steps:"
echo "1. Edit the configuration file:"
echo "   nano $CONFIG_FILE"
echo "   - Set ACTIVE_REMOTES to your rclone remote name(s)"
echo "   - Adjust other settings as needed"
echo ""
echo "2. Download your first album:"
echo "   bash $HOME/amalac/am_downloader.sh \"https://music.apple.com/...\""
echo ""
echo "3. Advanced options examples:"
echo "   bash $HOME/amalac/am_downloader.sh --all-album \"https://music.apple.com/artist/...\""
echo "   bash $HOME/amalac/am_downloader.sh --atmos --alac-max 256000 \"https://music.apple.com/album/...\""
