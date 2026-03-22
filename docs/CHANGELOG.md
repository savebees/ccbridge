# Changelog

All notable changes to this project will be documented in this file.

## v0.1.0

> Initial release.

- SSHFS mount/unmount with auto-reconnect and health checks
- Remote environment auto-detection (OS, languages, services, project structure)
- Auto-generate `.claude/rules/ccbridge-remote.md` with SSH execution rules
- Password auth support via `sshpass` + `SSH_PASS`
- CLI subcommands: `connect`, `down`, `status`, `refresh`
- Interactive mode with guided prompts
- Preflight dependency checks with install guidance
- Install / uninstall scripts
