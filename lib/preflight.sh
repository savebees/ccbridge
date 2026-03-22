#!/usr/bin/env bash
# CCBridge — preflight dependency checks

check_macfuse() {
    if [ -d "/Library/Filesystems/macfuse.fs" ] || kextstat 2>/dev/null | grep -q macfuse; then
        return 0
    fi
    echo "⚠️  macFUSE is not installed."
    echo "   Please download and install from: https://macfuse.github.io/"
    echo "   After installation, allow the kernel extension in System Settings"
    echo "   and REBOOT your Mac (required for the extension to load)."
    return 1
}

check_sshfs() {
    if command -v sshfs &>/dev/null; then
        return 0
    fi
    echo "⚠️  sshfs is not installed. Install with one of:"
    echo "   brew install macfuse  # if not already installed"
    echo "   brew install gromgit/fuse/sshfs-mac"
    echo "   Or download from: https://macfuse.github.io/"
    return 1
}

check_ssh() {
    if command -v ssh &>/dev/null; then
        return 0
    fi
    echo "⚠️  ssh client not found. This should be included with macOS."
    return 1
}

check_claude() {
    if command -v claude &>/dev/null; then
        return 0
    fi
    echo "⚠️  Claude Code CLI not found (optional)."
    echo "   Install: npm install -g @anthropic-ai/claude-code"
    echo "   CCBridge will work without it, but won't auto-launch Claude Code."
    return 0  # non-blocking
}

run_preflight() {
    local failed=0
    check_macfuse || failed=1
    check_sshfs   || failed=1
    check_ssh     || failed=1
    check_claude
    if [ "$failed" -eq 1 ]; then
        echo ""
        echo "❌ Required dependencies missing. Please install them and try again."
        return 1
    fi
    return 0
}
