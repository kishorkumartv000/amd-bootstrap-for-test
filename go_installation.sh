#!/bin/bash
set -e

echo "=== Installing Go 1.24.1 ==="
sudo rm -rf /usr/local/go /usr/lib/go-* 2>/dev/null || true

ARCH=$(uname -m)
case $ARCH in
    x86_64) GO_ARCH="amd64" ;;
    aarch64) GO_ARCH="arm64" ;;
    armv7l) GO_ARCH="armv6l" ;;
    i686) GO_ARCH="386" ;;
    *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

echo "Downloading Go 1.24.1 for $ARCH..."
wget -q --show-progress "https://go.dev/dl/go1.24.1.linux-${GO_ARCH}.tar.gz" -O /tmp/go.tar.gz
sudo tar -C /usr/local -xzf /tmp/go.tar.gz
rm /tmp/go.tar.gz

echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc
echo "Go 1.24.1 installed to /usr/local/go"
