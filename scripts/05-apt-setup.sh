#!/bin/bash
set -e

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [05] $*"; }

UBUNTU_VERSION="${UBUNTU_VERSION:-noble}"
UBUNTU_MIRROR="${UBUNTU_MIRROR:-https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/}"
UBUNTU_SECURITY_MIRROR="${UBUNTU_SECURITY_MIRROR:-http://ports.ubuntu.com/ubuntu-ports/}"

log "📡 配置 apt 源并更新缓存"

export DEBIAN_FRONTEND=noninteractive

cp rootdir/etc/apt/sources.list rootdir/etc/apt/sources.list.bak 2>/dev/null || true

log "  └─ 配置 Ubuntu ${UBUNTU_VERSION} 清华源"
cat > rootdir/etc/apt/sources.list << EOF
deb ${UBUNTU_MIRROR} ${UBUNTU_VERSION} main restricted universe multiverse
deb ${UBUNTU_MIRROR} ${UBUNTU_VERSION}-updates main restricted universe multiverse
deb ${UBUNTU_MIRROR} ${UBUNTU_VERSION}-backports main restricted universe multiverse
deb ${UBUNTU_SECURITY_MIRROR} ${UBUNTU_VERSION}-security main restricted universe multiverse
EOF

log "  └─ 执行 apt update..."
chroot rootdir apt-get -q update

log "✅ apt 配置完成"
