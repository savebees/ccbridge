#!/usr/bin/env bash
# CCBridge — configuration management

CONFIG_DIR="${HOME}/.config/ccbridge"
CONFIG_FILE="${CONFIG_DIR}/config"
CONNECTIONS_DIR="${CONFIG_DIR}/connections"

DEFAULT_MOUNT_BASE="${HOME}/ccbridge"
DEFAULT_AUTO_LAUNCH_CLAUDE="true"
DEFAULT_PROBE_TIMEOUT="10"

load_config() {
    mkdir -p "$CONFIG_DIR" "$CONNECTIONS_DIR"
    MOUNT_BASE="$DEFAULT_MOUNT_BASE"
    AUTO_LAUNCH_CLAUDE="$DEFAULT_AUTO_LAUNCH_CLAUDE"
    PROBE_TIMEOUT="$DEFAULT_PROBE_TIMEOUT"
    if [ -f "$CONFIG_FILE" ]; then
        # shellcheck source=/dev/null
        source "$CONFIG_FILE"
    fi
}

connection_id() {
    local ssh_target="$1"
    local remote_path="$2"
    echo "${ssh_target}:${remote_path}" | tr '/:@' '___'
}

save_connection() {
    local ssh_target="$1"
    local remote_path="$2"
    local local_mount="$3"
    local ssh_port="${4:-22}"
    local ssh_key="${5:-}"
    local conn_id
    conn_id=$(connection_id "$ssh_target" "$remote_path")
    cat > "${CONNECTIONS_DIR}/${conn_id}.json" <<EOF
{
  "ssh_target": "${ssh_target}",
  "remote_path": "${remote_path}",
  "local_mount": "${local_mount}",
  "ssh_port": ${ssh_port},
  "ssh_key": "${ssh_key}",
  "connected_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "pid": $$
}
EOF
}

remove_connection() {
    local ssh_target="$1"
    local remote_path="$2"
    local conn_id
    conn_id=$(connection_id "$ssh_target" "$remote_path")
    rm -f "${CONNECTIONS_DIR}/${conn_id}.json"
}

list_connections() {
    if [ -d "$CONNECTIONS_DIR" ]; then
        find "$CONNECTIONS_DIR" -name '*.json' -type f 2>/dev/null
    fi
}

parse_json_field() {
    local file="$1"
    local field="$2"
    # Match "field": "value" or "field": number — extract value
    local line
    line=$(grep "\"${field}\"" "$file" 2>/dev/null | head -1)
    [ -z "$line" ] && return
    # Remove everything up to the first ': '
    local val="${line#*: }"
    # Remove trailing comma and whitespace
    val="${val%,}"
    val="${val## }"
    val="${val%% }"
    # Remove surrounding quotes
    val="${val#\"}"
    val="${val%\"}"
    echo "$val"
}
