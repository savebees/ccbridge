#!/usr/bin/env bash
set -euo pipefail

# CCBridge installer

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="/usr/local/bin"
LINK_NAME="ccbridge"

echo ""
echo "🔗 CCBridge Installer"
echo ""

# Make main script executable
chmod +x "${SCRIPT_DIR}/ccbridge"

# Create symlink
if [ -L "${INSTALL_DIR}/${LINK_NAME}" ]; then
    echo "  Updating existing symlink..."
    rm -f "${INSTALL_DIR}/${LINK_NAME}"
fi

if ln -sf "${SCRIPT_DIR}/ccbridge" "${INSTALL_DIR}/${LINK_NAME}" 2>/dev/null; then
    echo "✓ Installed: ${INSTALL_DIR}/${LINK_NAME} → ${SCRIPT_DIR}/ccbridge"
else
    echo "⚠️  Cannot write to ${INSTALL_DIR}. Trying with sudo..."
    sudo ln -sf "${SCRIPT_DIR}/ccbridge" "${INSTALL_DIR}/${LINK_NAME}"
    echo "✓ Installed: ${INSTALL_DIR}/${LINK_NAME} → ${SCRIPT_DIR}/ccbridge"
fi

# Check dependencies
echo ""
echo "── Checking dependencies..."
source "${SCRIPT_DIR}/lib/preflight.sh"

local_failed=0
check_macfuse || local_failed=1
check_sshfs   || local_failed=1
check_ssh     || local_failed=1
check_claude

if [ "$local_failed" -eq 0 ]; then
    echo ""
    echo "✅ All dependencies satisfied."
else
    echo ""
    echo "⚠️  Some dependencies are missing. Install them before using ccbridge."
fi

echo ""
echo "✅ Installation complete!"
echo ""
echo "Usage:"
echo "  ccbridge user@host:/path/to/project"
echo "  ccbridge help"
echo ""
