#!/bin/bash
set -e

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [11] $*"; }

log "🗂️ 配置 fstab (UEFI: linux 根分区 + esp 引导分区)"

mkdir -p rootdir/boot/efi

echo "PARTLABEL=linux / ext4 errors=remount-ro,x-systemd.growfs 0 1
PARTLABEL=esp /boot/efi vfat umask=0077 0 1" > rootdir/etc/fstab

log "✅ fstab 配置完成"
