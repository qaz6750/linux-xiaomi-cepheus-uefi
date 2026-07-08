#!/bin/bash
set -e

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [02] $*"; }

UBUNTU_VERSION="${UBUNTU_VERSION:-noble}"
UBUNTU_MIRROR="${UBUNTU_MIRROR:-https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/}"
DEBOOTSTRAP_CACHE_DIR="${DEBOOTSTRAP_CACHE_DIR:-}"

log "🚀 安装基础系统 (Ubuntu ${UBUNTU_VERSION}) 🦁"

log "  └─ 开始 debootstrap (这可能需要几分钟...)"
debootstrap_args=(--arch=arm64)
if [ -n "$DEBOOTSTRAP_CACHE_DIR" ]; then
	if debootstrap --help 2>&1 | grep -q -- '--cache-dir'; then
		mkdir -p "$DEBOOTSTRAP_CACHE_DIR"
		debootstrap_args+=(--cache-dir="$DEBOOTSTRAP_CACHE_DIR")
		log "  └─ 使用 debootstrap 缓存: $DEBOOTSTRAP_CACHE_DIR"
	else
		log "  └─ 当前 debootstrap 不支持 --cache-dir，跳过下载缓存"
	fi
fi
debootstrap "${debootstrap_args[@]}" "${UBUNTU_VERSION}" rootdir "${UBUNTU_MIRROR}"

log "✅ 基础系统安装完成"
