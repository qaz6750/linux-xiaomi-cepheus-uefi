#!/bin/bash
set -e

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [13] $*"; }

log "🔌 配置 UEFI/GRUB 引导"

log "  └─ 安装 grub-efi-arm64"
chroot rootdir apt-get install -y grub-efi-arm64

# 启用 os-prober 并清空默认 cmdline（quiet splash 不适用于该设备）
sed --in-place 's/^#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' rootdir/etc/default/grub
sed --in-place 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/GRUB_CMDLINE_LINUX_DEFAULT=""/' rootdir/etc/default/grub

# 预留 EFI 挂载点（grub-install 在设备首启时执行）
mkdir -p rootdir/boot/efi

log "  └─ grub-install / grub-mkconfig 在设备首次启动时执行"
log "✅ UEFI/GRUB 配置完成"
