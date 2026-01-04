#!/bin/bash

# Get the root directory of the repo (one level up from scripts/systemd)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
SERVICE_NAME="apollo-supply.service"
SOURCE_SERVICE_FILE="$SCRIPT_DIR/$SERVICE_NAME"
TARGET_SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME"

echo "Configuring Systemd persistence for Apollo Supply..."
echo "Repository Root: $REPO_ROOT"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo)."
  exit 1
fi

# 1. Update the service file with the correct path
# We create a temporary file to avoid modifying the git-tracked file directly if possible, 
# but for simplicity here we will generate the final file in /etc/systemd/system directly.

echo "Generating service file at $TARGET_SERVICE_FILE..."
rm -f "$TARGET_SERVICE_FILE"
cp "$SOURCE_SERVICE_FILE" "$TARGET_SERVICE_FILE"

# Replace placeholder with actual path
sed -i "s|%INSTALL_DIR%|$REPO_ROOT|g" "$TARGET_SERVICE_FILE"

# 2. Make scripts executable
chmod +x "$SCRIPT_DIR/restore.sh"

# 3. Enable Service
echo "Enabling service..."
systemctl daemon-reload
systemctl enable $SERVICE_NAME
systemctl restart $SERVICE_NAME

echo "Success! The stack will now auto-resume on boot."
