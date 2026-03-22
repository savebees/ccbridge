#!/usr/bin/env bash
# CCBridge — SSHFS mount/unmount logic

# Helper: check if a path is currently mounted
_is_mounted() {
    mount | grep -qE " on ${1} \(| on ${1}$"
}

mount_remote() {
    local remote="$1"      # user@host:/path
    local mountpoint="$2"
    local ssh_port="${3:-22}"
    local ssh_key="${4:-}"

    mkdir -p "$mountpoint"

    if _is_mounted "$mountpoint"; then
        echo "✓ Already mounted at $mountpoint"
        return 0
    fi

    local sshfs_opts=(
        -o reconnect
        -o ServerAliveInterval=15
        -o ServerAliveCountMax=3
        -o follow_symlinks
        -o cache=yes
        -o kernel_cache
        -o compression=yes
        -o StrictHostKeyChecking=no
        -o UserKnownHostsFile=/dev/null
        -o Port="$ssh_port"
    )

    if [ -n "$ssh_key" ]; then
        sshfs_opts+=(-o IdentityFile="$ssh_key")
    fi

    local exit_code=0
    if [ -n "${SSH_PASS:-}" ]; then
        sshfs_opts+=(-o password_stdin)
        echo "$SSH_PASS" | sshfs "$remote" "$mountpoint" "${sshfs_opts[@]}" || exit_code=$?
    else
        sshfs "$remote" "$mountpoint" "${sshfs_opts[@]}" || exit_code=$?
    fi

    if [ $exit_code -ne 0 ]; then
        echo "❌ SSHFS mount failed (exit code: $exit_code)"
        rmdir "$mountpoint" 2>/dev/null
        return 1
    fi

    # Verify mount
    if ! ls "$mountpoint" &>/dev/null; then
        echo "❌ Mount verification failed"
        unmount_remote "$mountpoint"
        return 1
    fi

    echo "✓ Mounted at $mountpoint"
    return 0
}

unmount_remote() {
    local mountpoint="$1"
    local force="${2:-false}"

    if ! _is_mounted "$mountpoint"; then
        rmdir "$mountpoint" 2>/dev/null
        return 0
    fi

    local exit_code=0
    if [ "$force" = "true" ]; then
        umount "$mountpoint" 2>/dev/null || diskutil unmount force "$mountpoint" 2>/dev/null || exit_code=$?
    else
        umount "$mountpoint" 2>/dev/null || diskutil unmount "$mountpoint" 2>/dev/null || exit_code=$?
    fi
    rmdir "$mountpoint" 2>/dev/null

    if [ $exit_code -eq 0 ]; then
        echo "✓ Unmounted $mountpoint"
    else
        echo "⚠️  Failed to unmount $mountpoint. Try: ccbridge down --force"
    fi
    return $exit_code
}

check_mount_health() {
    local mountpoint="$1"
    if _is_mounted "$mountpoint"; then
        if ls "$mountpoint" &>/dev/null; then
            return 0  # healthy
        else
            return 2  # stale
        fi
    fi
    return 1  # not mounted
}
