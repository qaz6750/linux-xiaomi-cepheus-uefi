#!/bin/bash
set -e

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [02] $*"; }

UBUNTU_VERSION="${UBUNTU_VERSION:-noble}"
UBUNTU_MIRROR="${UBUNTU_MIRROR:-https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/}"

log "🚀 安装基础系统 (Ubuntu ${UBUNTU_VERSION}) 🦁"

log "  └─ 开始 debootstrap (这可能需要几分钟...)"
debootstrap --arch=arm64 "${UBUNTU_VERSION}" rootdir "${UBUNTU_MIRROR}"

log "✅ 基础系统安装完成"
