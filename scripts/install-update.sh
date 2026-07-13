#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEB_DIR="${1:-$SCRIPT_DIR/debs}"
ESP_MOUNTPOINT="${ESP_MOUNTPOINT:-/boot/efi}"
GRUB_VENDOR_DIRECTORY="$ESP_MOUNTPOINT/EFI/ubuntu"
GRUB_FALLBACK_DIRECTORY="$ESP_MOUNTPOINT/EFI/BOOT"
GRUB_EFI_SOURCE="${GRUB_EFI_SOURCE:-/usr/lib/grub/arm64-efi/monolithic/grubaa64.efi}"

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [update] $*"; }

if [ "$(id -u)" -ne 0 ]; then
  log "错误: 请使用 sudo 运行此脚本"
  exit 1
fi

if [ "$(dpkg --print-architecture)" != "arm64" ]; then
  log "错误: 增量包只能安装到 arm64 系统"
  exit 1
fi

if [ ! -d "$DEB_DIR" ]; then
  log "错误: deb 目录不存在: $DEB_DIR"
  exit 1
fi

required_files=(
  linux-image-xiaomi-cepheus.deb
  linux-headers-xiaomi-cepheus.deb
  firmware-xiaomi-cepheus.deb
  alsa-xiaomi-cepheus.deb
)

for filename in "${required_files[@]}"; do
  if [ ! -f "$DEB_DIR/$filename" ]; then
    log "错误: 缺少软件包文件 $filename"
    exit 1
  fi
done

required_grub_packages=(
  grub-common
  grub2-common
  grub-efi-arm64-bin
  grub-efi-arm64
)

declare -A available_packages=()
while IFS= read -r -d '' deb; do
  package="$(dpkg-deb -f "$deb" Package)"
  architecture="$(dpkg-deb -f "$deb" Architecture)"
  if [ "$architecture" != "arm64" ] && [ "$architecture" != "all" ]; then
    log "错误: $(basename "$deb") 的架构是 $architecture，不是 arm64"
    exit 1
  fi
  available_packages["$package"]=1
done < <(find "$DEB_DIR" -maxdepth 1 -type f -name '*.deb' -print0)

for package in "${required_grub_packages[@]}"; do
  if [ -z "${available_packages[$package]+present}" ]; then
    log "错误: 缺少软件包 $package"
    exit 1
  fi
done

if ! mountpoint -q "$ESP_MOUNTPOINT"; then
  log "错误: $ESP_MOUNTPOINT 未挂载，请先挂载 ESP 分区"
  exit 1
fi

mapfile -d '' debs < <(find "$DEB_DIR" -maxdepth 1 -type f -name '*.deb' -print0 | sort -z)
log "安装 ${#debs[@]} 个增量软件包"
apt-get install -y "${debs[@]}"

log "更新 initramfs"
update-initramfs -u -k all

if [ ! -f "$GRUB_EFI_SOURCE" ]; then
  log "错误: GRUB EFI 文件不存在: $GRUB_EFI_SOURCE"
  exit 1
fi

backup_directory="/var/backups/cepheus-esp-grub-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup_directory/EFI/ubuntu" "$backup_directory/EFI/BOOT"
if [ -d "$GRUB_VENDOR_DIRECTORY" ]; then
  log "备份 ESP 中的 EFI/ubuntu 到 $backup_directory"
  cp -a "$GRUB_VENDOR_DIRECTORY/." "$backup_directory/EFI/ubuntu/"
fi
if [ -f "$GRUB_FALLBACK_DIRECTORY/BOOTAA64.EFI" ]; then
  cp -a "$GRUB_FALLBACK_DIRECTORY/BOOTAA64.EFI" "$backup_directory/EFI/BOOT/"
fi

log "更新 ESP 中的 GRUB EFI 文件"
mkdir -p "$GRUB_VENDOR_DIRECTORY" "$GRUB_FALLBACK_DIRECTORY"
install -m 0644 "$GRUB_EFI_SOURCE" "$GRUB_VENDOR_DIRECTORY/grubaa64.efi"
install -m 0644 "$GRUB_EFI_SOURCE" "$GRUB_FALLBACK_DIRECTORY/BOOTAA64.EFI"

log "生成 ESP 中的 GRUB 配置"
grub-mkconfig -o "$GRUB_VENDOR_DIRECTORY/grub.cfg"

sync
log "增量更新完成，重启后使用新内核"