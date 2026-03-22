#!/usr/bin/env bash
set -euo pipefail

# CCBridge uninstaller

INSTALL_DIR="/usr/local/bin"
LINK_NAME="ccbridge"
CONFIG_DIR="${HOME}/.config/ccbridge"

echo ""
echo "🔗 CCBridge Uninstaller"
echo ""

# Remove symlink
if [ -L "${INSTALL_DIR}/${LINK_NAME}" ]; then
    if rm -f "${INSTALL_DIR}/${LINK_NAME}" 2>/dev/null; then
        echo "✓ Removed ${INSTALL_DIR}/${LINK_NAME}"
    else
        sudo rm -f "${INSTALL_DIR}/${LINK_NAME}"
        echo "✓ Removed ${INSTALL_DIR}/${LINK_NAME}"
    fi
else
    echo "  No symlink found at ${INSTALL_DIR}/${LINK_NAME}"
fi

# Ask about config
if [ -d "$CONFIG_DIR" ]; then
    read -rp "  Remove configuration at ${CONFIG_DIR}? [y/N]: " remove_config
    if [[ "$remove_config" =~ ^[Yy]$ ]]; then
        rm -rf "$CONFIG_DIR"
        echo "✓ Removed configuration"
    else
        echo "  Kept configuration"
    fi
fi

echo ""
echo "✅ CCBridge uninstalled."
echo "   Note: macFUSE and sshfs were not removed."
echo ""
