#!/bin/bash
set -e

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [15] $*"; }

log "🧹 清理临时文件"

export DEBIAN_FRONTEND=noninteractive

log "  └─ 清理 apt 缓存"
chroot rootdir apt-get -q clean

log "  └─ 删除 WiFi 监管证书 (reg*)"
rm -f rootdir/lib/firmware/reg* 2>/dev/null || true

log "✅ 清理完成"
