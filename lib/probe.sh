#!/usr/bin/env bash
# CCBridge — remote environment probe

probe_remote() {
    local ssh_target="$1"
    local remote_path="$2"
    local ssh_port="${3:-22}"
    local ssh_key="${4:-}"
    local timeout="${PROBE_TIMEOUT:-10}"

    local ssh_opts=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout="$timeout" -p "$ssh_port")
    if [ -n "$ssh_key" ]; then
        ssh_opts+=(-i "$ssh_key")
    fi

    local ssh_cmd=()
    if [ -n "${SSH_PASS:-}" ] && command -v sshpass &>/dev/null; then
        ssh_cmd=(sshpass -p "$SSH_PASS" ssh)
    else
        ssh_cmd=(ssh)
    fi

    "${ssh_cmd[@]}" "${ssh_opts[@]}" "$ssh_target" bash <<PROBE_SCRIPT
set -e

echo "OS_INFO=\$(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d= -f2 | tr -d '\"' || echo 'Unknown')"
echo "KERNEL=\$(uname -r 2>/dev/null || echo 'Unknown')"
echo "ARCH=\$(uname -m 2>/dev/null || echo 'Unknown')"
echo "REMOTE_SHELL=\${SHELL:-/bin/sh}"
echo "HOSTNAME=\$(hostname 2>/dev/null || echo 'Unknown')"
echo "CPU_CORES=\$(nproc 2>/dev/null || echo 'Unknown')"
echo "MEMORY=\$(free -h 2>/dev/null | awk '/^Mem:/{print \$2}' || echo 'Unknown')"

echo "PYTHON_VER=\$(python3 --version 2>/dev/null || python --version 2>/dev/null || echo 'not installed')"
echo "NODE_VER=\$(node --version 2>/dev/null || echo 'not installed')"
echo "GO_VER=\$(go version 2>/dev/null || echo 'not installed')"
echo "RUST_VER=\$(rustc --version 2>/dev/null || echo 'not installed')"
if command -v java &>/dev/null; then echo "JAVA_VER=\$(java -version 2>&1 | head -1)"; else echo "JAVA_VER=not installed"; fi
echo "GCC_VER=\$(gcc --version 2>/dev/null | head -1 || echo 'not installed')"

PKG_LIST=""
command -v apt &>/dev/null && PKG_LIST="\${PKG_LIST}apt, "
command -v yum &>/dev/null && PKG_LIST="\${PKG_LIST}yum, "
command -v dnf &>/dev/null && PKG_LIST="\${PKG_LIST}dnf, "
command -v pacman &>/dev/null && PKG_LIST="\${PKG_LIST}pacman, "
command -v pip3 &>/dev/null && PKG_LIST="\${PKG_LIST}pip3, "
command -v npm &>/dev/null && PKG_LIST="\${PKG_LIST}npm, "
command -v conda &>/dev/null && PKG_LIST="\${PKG_LIST}conda, "
echo "PKG_MANAGERS=\${PKG_LIST%, }"

echo "DOCKER_VER=\$(docker --version 2>/dev/null || echo 'not installed')"
echo "GIT_VER=\$(git --version 2>/dev/null || echo 'not installed')"

if [ -d "${remote_path}" ]; then
    cd "${remote_path}" 2>/dev/null
    echo "PROJECT_FILES=\$(ls -1 2>/dev/null | head -30 | tr '\n' ', ')"

    PROJECT_TYPE=""
    [ -f "package.json" ] && PROJECT_TYPE="\${PROJECT_TYPE}Node.js, "
    { [ -f "requirements.txt" ] || [ -f "setup.py" ] || [ -f "pyproject.toml" ]; } && PROJECT_TYPE="\${PROJECT_TYPE}Python, "
    [ -f "go.mod" ] && PROJECT_TYPE="\${PROJECT_TYPE}Go, "
    [ -f "Cargo.toml" ] && PROJECT_TYPE="\${PROJECT_TYPE}Rust, "
    { [ -f "pom.xml" ] || [ -f "build.gradle" ]; } && PROJECT_TYPE="\${PROJECT_TYPE}Java, "
    { [ -f "Dockerfile" ] || [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ]; } && PROJECT_TYPE="\${PROJECT_TYPE}Docker, "
    [ -f "Makefile" ] && PROJECT_TYPE="\${PROJECT_TYPE}Make, "
    [ -d ".git" ] && PROJECT_TYPE="\${PROJECT_TYPE}Git, "
    echo "PROJECT_TYPE=\${PROJECT_TYPE%, }"

    if [ -d ".git" ]; then
        echo "GIT_BRANCH=\$(git branch --show-current 2>/dev/null || echo 'unknown')"
        echo "GIT_REMOTE=\$(git remote get-url origin 2>/dev/null || echo 'none')"
    fi

    echo "DISK_USAGE=\$(du -sh '${remote_path}' 2>/dev/null | awk '{print \$1}' || echo 'Unknown')"
else
    echo "PROJECT_FILES="
    echo "PROJECT_TYPE="
    echo "DISK_USAGE=Unknown"
fi

SERVICES=""
if command -v systemctl &>/dev/null; then
    SERVICES="\$(systemctl list-units --type=service --state=running 2>/dev/null | grep -E 'nginx|apache|httpd|docker|postgres|mysql|mariadb|redis|mongo|node|python|java|tomcat|pm2' | awk '{print \$1}' | tr '\n' ', ')"
fi
echo "SERVICES=\${SERVICES%, }"
PROBE_SCRIPT
}

parse_probe_output() {
    local probe_output="$1"
    while IFS= read -r line; do
        if [[ "$line" =~ ^[A-Z_]+=.* ]]; then
            echo "$line"
        fi
    done <<< "$probe_output"
}
