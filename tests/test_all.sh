#!/usr/bin/env bash
set -euo pipefail

# CCBridge test suite
# Runs basic tests for each module

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PASS=0
FAIL=0

green() { echo -e "\033[32m$1\033[0m"; }
red()   { echo -e "\033[31m$1\033[0m"; }

assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [ "$expected" = "$actual" ]; then
        green "  ✓ $desc"
        PASS=$((PASS + 1))
    else
        red   "  ✗ $desc"
        echo  "    Expected: $expected"
        echo  "    Actual:   $actual"
        FAIL=$((FAIL + 1))
    fi
}

assert_ok() {
    local desc="$1"
    shift
    if "$@" &>/dev/null; then
        green "  ✓ $desc"
        PASS=$((PASS + 1))
    else
        red   "  ✗ $desc"
        FAIL=$((FAIL + 1))
    fi
}

assert_fail() {
    local desc="$1"
    shift
    if ! "$@" &>/dev/null; then
        green "  ✓ $desc"
        PASS=$((PASS + 1))
    else
        red   "  ✗ $desc"
        FAIL=$((FAIL + 1))
    fi
}

assert_contains() {
    local desc="$1" expected="$2" actual="$3"
    if echo "$actual" | grep -q "$expected"; then
        green "  ✓ $desc"
        PASS=$((PASS + 1))
    else
        red   "  ✗ $desc"
        echo  "    Expected to contain: $expected"
        FAIL=$((FAIL + 1))
    fi
}

# ── config.sh tests ───────────────────────────────────────

echo ""
echo "═══ lib/config.sh ═══"

source "$PROJECT_DIR/lib/config.sh"

# Test connection_id
cid=$(connection_id "user@host" "/path/to/project")
assert_eq "connection_id sanitizes special chars" "user_host__path_to_project" "$cid"

# Test load_config defaults
load_config
assert_eq "MOUNT_BASE has default" "$HOME/ccbridge" "$MOUNT_BASE"
assert_eq "AUTO_LAUNCH_CLAUDE default is true" "true" "$AUTO_LAUNCH_CLAUDE"

# Test save/list/remove connection
save_connection "test@host" "/test/path" "/tmp/test-mount" 22 ""
conn_files=$(list_connections)
assert_contains "save_connection creates file" "test_host" "$conn_files"

# Test parse_json_field
conn_file=$(list_connections | head -1)
if [ -n "$conn_file" ]; then
    val=$(parse_json_field "$conn_file" "ssh_target")
    assert_eq "parse_json_field reads ssh_target" "test@host" "$val"
    val=$(parse_json_field "$conn_file" "remote_path")
    assert_eq "parse_json_field reads remote_path" "/test/path" "$val"
fi

remove_connection "test@host" "/test/path"
remaining=$(list_connections | grep "test_host" || true)
assert_eq "remove_connection deletes file" "" "$remaining"

# ── preflight.sh tests ───────────────────────────────────

echo ""
echo "═══ lib/preflight.sh ═══"

source "$PROJECT_DIR/lib/preflight.sh"
assert_ok "check_ssh finds ssh" check_ssh

# ── parse_target tests (in main script) ──────────────────

echo ""
echo "═══ ccbridge parse_target ═══"

# We can't source the main script (it has main "$@"), so test parse logic inline
test_parse() {
    local target="$1"
    if [[ "$target" =~ ^([^:]+):(.+)$ ]]; then
        local userhost="${BASH_REMATCH[1]}"
        local path="${BASH_REMATCH[2]}"
        if [[ "$userhost" =~ ^(.+)@(.+)$ ]]; then
            echo "user=${BASH_REMATCH[1]} host=${BASH_REMATCH[2]} path=$path"
        else
            echo "user=$(whoami) host=$userhost path=$path"
        fi
    else
        echo "INVALID"
    fi
}

r=$(test_parse "user@host:/path")
assert_contains "parse user@host:/path" "user=user host=host path=/path" "$r"

r=$(test_parse "deploy@prod.example.com:/home/deploy/myapp")
assert_contains "parse full target" "user=deploy host=prod.example.com path=/home/deploy/myapp" "$r"

r=$(test_parse "myserver:/project")
assert_contains "parse host-only target" "host=myserver path=/project" "$r"

r=$(test_parse "invalid-no-colon")
assert_eq "reject invalid target" "INVALID" "$r"

# ── rules.sh tests ───────────────────────────────────────

echo ""
echo "═══ lib/rules.sh ═══"

source "$PROJECT_DIR/lib/rules.sh"

# Test rules generation with mock probe data
MOCK_PROBE="OS_INFO=Ubuntu 22.04
KERNEL=5.15.0
ARCH=x86_64
REMOTE_SHELL=/bin/bash
HOSTNAME=testserver
CPU_CORES=4
MEMORY=8Gi
PYTHON_VER=Python 3.10.6
NODE_VER=v18.12.0
GO_VER=not installed
RUST_VER=not installed
JAVA_VER=not installed
GCC_VER=not installed
PKG_MANAGERS=apt, pip3
DOCKER_VER=Docker version 24.0.5
GIT_VER=git version 2.34.1
PROJECT_FILES=src,package.json,README.md,
PROJECT_TYPE=Node.js, Git
GIT_BRANCH=main
GIT_REMOTE=https://github.com/test/repo.git
SERVICES=
DISK_USAGE=1.2G"

TEST_MOUNT="/tmp/ccbridge-test-rules"
rm -rf "$TEST_MOUNT"
mkdir -p "$TEST_MOUNT"
export SSH_PORT=22
generate_rules "$TEST_MOUNT" "deploy@prod" "/home/deploy/app" "$MOCK_PROBE" >/dev/null

RULES_FILE="$TEST_MOUNT/.claude/rules/ccbridge-remote.md"
assert_ok "rules file created" test -f "$RULES_FILE"

rules_content=$(cat "$RULES_FILE")
assert_contains "rules contain SSH target" "deploy@prod" "$rules_content"
assert_contains "rules contain remote path" "/home/deploy/app" "$rules_content"
assert_contains "rules contain OS info" "Ubuntu 22.04" "$rules_content"
assert_contains "rules contain Python version" "Python 3.10.6" "$rules_content"
assert_contains "rules contain Node version" "v18.12.0" "$rules_content"
assert_contains "rules contain Docker version" "Docker version 24.0.5" "$rules_content"
assert_contains "rules contain git branch" "main" "$rules_content"
assert_contains "rules contain project type" "Node.js" "$rules_content"
assert_contains "rules contain CRITICAL header" "CRITICAL" "$rules_content"
assert_contains "rules have Do NOT section" "Do NOT" "$rules_content"

# Test .gitignore update
touch "$TEST_MOUNT/.gitignore"
update_gitignore "$TEST_MOUNT"
gi_content=$(cat "$TEST_MOUNT/.gitignore")
assert_contains ".gitignore updated" "ccbridge-remote.md" "$gi_content"

# Test idempotent .gitignore update
update_gitignore "$TEST_MOUNT"
count=$(grep -c "ccbridge-remote.md" "$TEST_MOUNT/.gitignore")
assert_eq ".gitignore not duplicated" "1" "$count"

# Test cleanup
cleanup_rules "$TEST_MOUNT" >/dev/null
assert_fail "rules file removed after cleanup" test -f "$RULES_FILE"

rm -rf "$TEST_MOUNT"

# ── CLI subcommands ───────────────────────────────────────

echo ""
echo "═══ ccbridge CLI ═══"

help_output=$("$PROJECT_DIR/ccbridge" help 2>&1)
assert_contains "help shows usage" "Usage" "$help_output"
assert_contains "help shows version" "CCBridge" "$help_output"

version_output=$("$PROJECT_DIR/ccbridge" --version 2>&1)
assert_eq "version output" "CCBridge v0.1.0" "$version_output"

status_output=$("$PROJECT_DIR/ccbridge" status 2>&1)
assert_contains "status works with no connections" "No active connections" "$status_output"

down_output=$("$PROJECT_DIR/ccbridge" down 2>&1)
assert_contains "down works with no connections" "No active connections" "$down_output"

# ── Summary ───────────────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
total=$((PASS + FAIL))
if [ "$FAIL" -eq 0 ]; then
    green "All $total tests passed!"
else
    red "$FAIL of $total tests failed"
fi
echo ""

exit "$FAIL"
