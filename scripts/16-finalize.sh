#!/bin/bash
set -e

IMAGE_NAME="${IMAGE_NAME:-rootfs.img}"
BUILD_JOBS="${BUILD_JOBS:-$(nproc)}"
ROOTFS_FREE_SPACE_MIB="${ROOTFS_FREE_SPACE_MIB:-512}"
SEVENZIP_ARGS="${SEVENZIP_ARGS:--mmt=${BUILD_JOBS}}"

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

if ! [[ "$ROOTFS_FREE_SPACE_MIB" =~ ^[0-9]+$ ]]; then
	log "❌ ROOTFS_FREE_SPACE_MIB 必须是非负整数"
	exit 1
fi

log "  └─ 收缩 ext4 镜像（保留 ${ROOTFS_FREE_SPACE_MIB} MiB 空闲空间）..."
e2fsck -fy "${IMAGE_NAME}"
block_size=$(dumpe2fs -h "${IMAGE_NAME}" 2>/dev/null | awk -F: '/Block size:/ {gsub(/ /, "", $2); print $2}')
current_blocks=$(dumpe2fs -h "${IMAGE_NAME}" 2>/dev/null | awk -F: '/Block count:/ {gsub(/ /, "", $2); print $2}')
minimum_blocks=$(resize2fs -P "${IMAGE_NAME}" 2>/dev/null | awk -F: '{gsub(/ /, "", $2); print $2}')
reserve_blocks=$((ROOTFS_FREE_SPACE_MIB * 1024 * 1024 / block_size))
target_blocks=$((minimum_blocks + reserve_blocks))
if [ "$target_blocks" -lt "$current_blocks" ]; then
	resize2fs "${IMAGE_NAME}" "${target_blocks}"
else
	log "  └─ 已用空间接近镜像上限，保持当前文件系统大小"
fi
filesystem_blocks=$(dumpe2fs -h "${IMAGE_NAME}" 2>/dev/null | awk -F: '/Block count:/ {gsub(/ /, "", $2); print $2}')
truncate -s "$((filesystem_blocks * block_size))" "${IMAGE_NAME}"
e2fsck -fy "${IMAGE_NAME}"
log "  └─ 收缩后镜像大小: $(du -h "${IMAGE_NAME}" | awk '{print $1}')"

log "  └─ 压缩 rootfs 镜像 (7z)..."
rm -f rootfs.7z
read -r -a sevenzip_args <<< "$SEVENZIP_ARGS"
7z a "${sevenzip_args[@]}" rootfs.7z "${IMAGE_NAME}"

log "✅ 镜像打包完成: rootfs.7z"
