#!/bin/bash
set -e

IMAGE_NAME="${IMAGE_NAME:-rootfs.img}"

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [16] $*"; }

log "📦 卸载并打包镜像"

log "  └─ 卸载挂载点..."
umount rootdir/sys 2>/dev/null || true
umount rootdir/proc 2>/dev/null || true
umount rootdir/dev/pts 2>/dev/null || true
umount rootdir/dev 2>/dev/null || true
umount rootdir 2>/dev/null || true
rm -d rootdir 2>/dev/null || true

log "  └─ Legacy boot cmdline: root=PARTLABEL=linux"

log "  └─ 压缩 rootfs 镜像 (7z)..."
rm -f rootfs.7z
7z a rootfs.7z "${IMAGE_NAME}"

log "✅ 镜像打包完成: rootfs.7z"
