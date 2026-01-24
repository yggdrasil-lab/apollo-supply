#!/bin/bash
# setup_host.sh for Apollo Supply

# Configures the host machine (Muspelheim) for the apollo-supply stack.
# Creates necessary directories and installs the systemd persistence service.

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root (sudo)."
    exit 1
fi

echo "Setting up Apollo Supply Host Configuration..."

# 1. Create Directories
DIRS=(
    "/opt/apollo-supply/gluetun"
    "/opt/apollo-supply/qbittorrent"
    "/opt/apollo-supply/sabnzbd"
    "/mnt/storage/downloads"
)

for dir in "${DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        echo "Creating directory: $dir"
        mkdir -p "$dir"
        # Set ownership to the default PUID/PGID (usually 1000:1000)
        chown -R 1000:1000 "$dir"
    else
        echo "Directory exists: $dir"
    fi
done

# 2. Install Systemd Service
echo "Installing Systemd persistence service..."
# Execute the specific systemd setup script
./scripts/systemd/setup.sh

echo "Setup complete!"
