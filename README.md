<div align="center">

# CCBridge

### Claude Code Remote Development Bridge

One command to connect your local Claude Code to any remote Linux server.<br>Zero server-side installation. Pure SSH + SSHFS.

[![Version](https://img.shields.io/badge/version-0.1.0-blue.svg)](https://github.com/savebees/ccbridge/releases) [![Platform](https://img.shields.io/badge/platform-macOS-lightgrey.svg)](https://github.com/savebees/ccbridge) [![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE) [![Shell](https://img.shields.io/badge/built%20with-Bash-89e051.svg)](https://github.com/savebees/ccbridge)

**English** | [中文](docs/README_ZH.md) | [Changelog](docs/CHANGELOG.md)

</div>

## Why CCBridge?

You want to use Claude Code on a remote server, but:

1. The server can't log in to Claude Code (network restrictions, corporate firewalls, air-gapped environments)
2. Your local Claude Code can't access the remote server's filesystem

**CCBridge** solves this with two layers:

| Layer | How | Effect |
|---|---|---|
| File System | SSHFS mounts remote directory locally | Claude Code reads/writes remote files natively |
| Commands | `.claude/rules/` auto-injection | All shell commands transparently run via SSH on remote |
| Environment | Probes remote OS, languages, services | Claude Code understands the remote environment |

No agents, no daemons, no server-side dependencies. Just SSH.

## Quick Start

### Prerequisites

1. **macOS** with [macFUSE](https://github.com/osxfuse/osxfuse) installed
2. **sshfs**: `brew install gromgit/fuse/sshfs-mac`
3. **SSH access** to your remote server

> **Note**: After installing macFUSE, allow the kernel extension in System Settings and **reboot** your Mac. This is a one-time setup.

### Install

```bash
git clone https://github.com/savebees/ccbridge.git
cd ccbridge
./install.sh
```

### Connect

```bash
# One-line connect: mounts, probes, generates rules, launches Claude Code
ccbridge user@server:/path/to/project

# With custom SSH port
ccbridge user@server:/project -p 2222

# With SSH key
ccbridge user@server:/project -i ~/.ssh/id_ed25519

# Mount only (don't start Claude Code)
ccbridge user@server:/project --mount-only

# Interactive mode
ccbridge
```

### What Happens

```
  ┌─────────────────────────────────────────────────────────┐
  │  1. SSHFS mount   →  ~/ccbridge/<server>/<project>/     │
  │  2. SSH probe      →  detect OS, languages, services    │
  │  3. Generate rules →  .claude/rules/ccbridge-remote.md  │
  │  4. Launch Claude  →  claude (auto)                     │
  └─────────────────────────────────────────────────────────┘
```

### Disconnect

```bash
ccbridge down              # Unmount all connections
ccbridge down server       # Unmount specific server
ccbridge down --force      # Force unmount (for stale/busy mounts)
```

### Other Commands

```bash
ccbridge status            # Show active connections with health status
ccbridge refresh           # Re-probe remote environment and update rules
ccbridge help              # Show help
```

## How It Works

**File system**: SSHFS transparently mounts the remote project directory. Claude Code sees it as a local folder, all file reads, edits, and searches work natively.

**Command execution**: CCBridge generates a `.claude/rules/ccbridge-remote.md` file that instructs Claude Code to wrap all shell commands with SSH. This uses Claude Code's built-in rules mechanism, no hacks, no CLAUDE.md modifications.

**Environment awareness**: On connect, CCBridge probes the remote server and detects: OS version, installed languages (Python, Node, Go, Rust, Java, GCC), package managers, Docker, running services, and project structure. All info goes into the rules file.

## Password Authentication

For servers using password auth:

```bash
SSH_PASS='yourpassword' ccbridge user@server:/path -p 2222
```

Requires `sshpass` (`brew install sshpass`). SSH key auth is recommended.

## Project Structure

```
ccbridge/
├── ccbridge                # Main CLI entry point
├── install.sh              # Installer (symlinks to /usr/local/bin)
├── uninstall.sh            # Uninstaller
├── lib/
│   ├── config.sh           # Configuration & connection management
│   ├── mount.sh            # SSHFS mount/unmount
│   ├── preflight.sh        # Dependency checks
│   ├── probe.sh            # Remote environment detection
│   └── rules.sh            # .claude/rules/ generation
├── templates/
│   └── ccbridge-remote.md.tpl
└── tests/
    └── test_all.sh         # Test suite (31 tests)
```

## Acknowledgments

[osxfuse](https://github.com/osxfuse/osxfuse) for macFUSE, the macOS FUSE implementation.<br>
[libfuse](https://github.com/libfuse/sshfs) for SSHFS, the SSH filesystem client.<br>
[sshpass](https://sourceforge.net/projects/sshpass/) for non-interactive SSH password authentication.
