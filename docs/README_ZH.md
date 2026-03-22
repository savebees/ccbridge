<div align="center">

# CCBridge

### Claude Code 远程开发桥接器

一条命令，将本地 Claude Code 连接到任意远程 Linux 服务器。<br>像操作本地文件一样浏览和编辑远程文件，远程零安装。

[![Version](https://img.shields.io/badge/version-0.1.0-blue.svg)](https://github.com/savebees/ccbridge/releases) [![Platform](https://img.shields.io/badge/platform-macOS-lightgrey.svg)](https://github.com/savebees/ccbridge) [![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE) [![Shell](https://img.shields.io/badge/built%20with-Bash-89e051.svg)](https://github.com/savebees/ccbridge)

[English](../README.md) | **中文** | [Changelog](CHANGELOG.md)

</div>

## 为什么需要 CCBridge？

你想在远程服务器上使用 Claude Code，但是：

- 服务器无法登录 Claude Code（网络限制、企业防火墙、隔离环境）
- 本地的 Claude Code 无法访问远程服务器的文件系统

**CCBridge** 通过两层桥接解决：

| 层 | 方式 | 效果 |
|---|---|---|
| 文件系统 | SSHFS 挂载远程目录到本地 | Claude Code 原生读写远程文件 |
| 命令执行 | 自动注入 `.claude/rules/` | 所有 shell 命令透明地通过 SSH 在远程执行 |
| 环境感知 | 探测远程 OS、语言、服务 | Claude Code 理解远程环境 |

无代理、无守护进程、远程零依赖，只需 SSH。

## 快速开始

### 前置条件

- **macOS** + [macFUSE](https://github.com/osxfuse/osxfuse)
- **sshfs**: `brew install gromgit/fuse/sshfs-mac`
- 远程服务器的 **SSH 访问权限**

> **提示**：安装 macFUSE 后，需在系统设置中允许内核扩展并**重启 Mac**，仅需一次。

### 安装

```bash
git clone https://github.com/savebees/ccbridge.git
cd ccbridge
./install.sh
```

### 连接

```bash
# 一键连接：挂载、探测、生成规则、启动 Claude Code
ccbridge user@server:/path/to/project

# 自定义端口
ccbridge user@server:/project -p 2222

# 使用 SSH 密钥
ccbridge user@server:/project -i ~/.ssh/id_ed25519

# 密码认证
SSH_PASS='密码' ccbridge user@server:/project -p 2222

# 仅挂载（不启动 Claude Code）
ccbridge user@server:/project --mount-only

# 交互式引导
ccbridge
```

### 连接过程

```
  ┌─────────────────────────────────────────────────────────┐
  │  1. SSHFS 挂载    →  ~/ccbridge/<server>/<project>/     │
  │  2. SSH 探测      →  检测 OS、语言、服务                   │
  │  3. 生成规则      →  .claude/rules/ccbridge-remote.md    │
  │  4. 启动 Claude   →  claude (自动)                       │
  └─────────────────────────────────────────────────────────┘
```

### 断开

```bash
ccbridge down              # 断开所有连接
ccbridge down server       # 断开指定服务器
ccbridge down --force      # 强制断开（挂载被占用时）
```

### 其他命令

```bash
ccbridge status            # 查看连接状态（含健康检测）
ccbridge refresh           # 重新探测远程环境并更新规则
ccbridge help              # 显示帮助
```

## 工作原理

**文件系统**：SSHFS 将远程项目目录透明挂载到本地。Claude Code 将其视为本地目录，文件读取、编辑、搜索全部原生工作。

**命令执行**：CCBridge 生成 `.claude/rules/ccbridge-remote.md` 规则文件，指示 Claude Code 将所有 shell 命令通过 SSH 包装执行。这利用了 Claude Code 内置的 rules 机制，无 hack，不修改 CLAUDE.md。

**环境感知**：连接时，CCBridge 探测远程服务器的：操作系统版本、已安装语言（Python、Node、Go、Rust、Java、GCC）、包管理器、Docker、运行中的服务、项目结构。所有信息写入规则文件。

## 密码认证

```bash
SSH_PASS='你的密码' ccbridge user@server:/path -p 2222
```

需要 `sshpass`（`brew install sshpass`）。推荐使用 SSH 密钥认证。

## 项目结构

```
ccbridge/
├── ccbridge                # 主入口
├── install.sh              # 安装脚本
├── uninstall.sh            # 卸载脚本
├── lib/
│   ├── config.sh           # 配置与连接管理
│   ├── mount.sh            # SSHFS 挂载/卸载
│   ├── preflight.sh        # 依赖检查
│   ├── probe.sh            # 远程环境探测
│   └── rules.sh            # .claude/rules/ 生成
├── templates/
│   └── ccbridge-remote.md.tpl
└── tests/
    └── test_all.sh         # 测试套件（31 个测试）
```

## 致谢

[osxfuse](https://github.com/osxfuse/osxfuse) 提供 macFUSE，macOS FUSE 实现。

[libfuse](https://github.com/libfuse/sshfs) 提供 SSHFS，基于 SSH 的文件系统客户端。

[sshpass](https://sourceforge.net/projects/sshpass/) 提供非交互式 SSH 密码认证。
