#!/bin/bash
set -e

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [01] $*"; }

IMAGE_SIZE="${IMAGE_SIZE:-3G}"
IMAGE_NAME="${IMAGE_NAME:-rootfs.img}"

log "📦 创建根文件系统镜像 (${IMAGE_SIZE})"

truncate -s "${IMAGE_SIZE}" "${IMAGE_NAME}"
mkfs.ext4 "${IMAGE_NAME}"
mkdir -p rootdir
mount -o loop "${IMAGE_NAME}" rootdir

log "✅ 根文件系统镜像创建完成"
