#!/bin/bash
set -e

# 小米 Cepheus (Mi 9) Linux UEFI 系统镜像构建编排器
# 用法: sudo ./build.sh <system_type> <kernel_version> [desktop_env]
#   system_type : ubuntu-server | ubuntu-gnome | ubuntu-desktop
#   kernel_version : 内核版本号 (用于定位 xiaomi-cepheus-debs_<ver> 目录)
#   desktop_env : 仅 ubuntu-desktop(Phosh) 生效 (phosh-core/phosh-full/phosh-phone)

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"; }

# 必须 root
if [ "$(id -u)" -ne 0 ]; then
  log "❌ 错误: 需要 root 权限运行 (sudo ./build.sh ...)"
  exit 1
fi

# 解析参数
SYSTEM_TYPE="${1:?请指定系统类型 (ubuntu-server|ubuntu-gnome|ubuntu-desktop)}"
KERNEL_VERSION="${2:?请指定内核版本号}"
DESKTOP_ENV_ARG="${3:-phosh-full}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 加载集中配置
. "$SCRIPT_DIR/config/build-config.sh"

# 加载系统配置 (镜像大小/版本/桌面环境)
TMP_CONF=$(mktemp)
system_config "$SYSTEM_TYPE" "$DESKTOP_ENV_ARG" > "$TMP_CONF"
while IFS= read -r line; do export "$line"; done < "$TMP_CONF"
rm -f "$TMP_CONF"

# 加载镜像源配置
TMP_SRC=$(mktemp)
sources_config "$SYSTEM_TYPE" > "$TMP_SRC"
while IFS= read -r line; do export "$line"; done < "$TMP_SRC"
rm -f "$TMP_SRC"

# 导出通用变量供各阶段脚本使用
export SCRIPT_DIR
export SYSTEM_TYPE
export KERNEL_VERSION
export DESKTOP_ENV
export DEVICE="cepheus"
export IMAGE_NAME="rootfs.img"
export HOSTNAME="xiaomi-cepheus"
export KERNEL_DEBS_DIR="${KERNEL_DEBS_DIR:-xiaomi-cepheus-debs_$KERNEL_VERSION}"
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"
export DEBIAN_FRONTEND="noninteractive"

# 打印构建信息
log "========================================== 🎉"
log "小米 Cepheus (Mi 9) UEFI 系统镜像构建"
log "========================================== 🎉"
log "系统类型:   $SYSTEM_TYPE 🖥️"
log "内核版本:   $KERNEL_VERSION 🧠"
log "Ubuntu 版本: $UBUNTU_VERSION 🦁"
log "镜像大小:   $IMAGE_SIZE 💾"
if [ "$IS_DESKTOP" = "true" ]; then
  log "桌面环境:   $DESKTOP_ENV 🎨"
fi
log "内核包目录: $KERNEL_DEBS_DIR 📦"
log "========================================== 🎉"

# 校验内核包目录
if [ ! -d "$KERNEL_DEBS_DIR" ]; then
  log "❌ 错误: 内核包目录 $KERNEL_DEBS_DIR 不存在"
  exit 1
fi

chmod +x "$SCRIPT_DIR/scripts"/*.sh

# 按阶段执行
log "========================================== 🚀 开始构建 =========================================="
"$SCRIPT_DIR/scripts/01-create-image.sh"
"$SCRIPT_DIR/scripts/02-bootstrap.sh"
"$SCRIPT_DIR/scripts/03-mount-dev.sh"
"$SCRIPT_DIR/scripts/04-config-network.sh"
"$SCRIPT_DIR/scripts/05-apt-setup.sh"
"$SCRIPT_DIR/scripts/06-install-all-packages.sh"
"$SCRIPT_DIR/scripts/07-config-locale.sh"
"$SCRIPT_DIR/scripts/08-add-screen-commands.sh"
"$SCRIPT_DIR/scripts/09-install-kernel.sh"
"$SCRIPT_DIR/scripts/10-config-ncm.sh"
"$SCRIPT_DIR/scripts/11-config-fstab.sh"
"$SCRIPT_DIR/scripts/12-create-users.sh"
"$SCRIPT_DIR/scripts/13-config-efi.sh"
"$SCRIPT_DIR/scripts/14-config-power.sh"
"$SCRIPT_DIR/scripts/15-cleanup.sh"
"$SCRIPT_DIR/scripts/16-finalize.sh"
log "========================================== 🎉 构建完成 🎉 =========================================="

echo ""
log "📦 产物文件:"
ls -lh rootfs.img 2>/dev/null || true
ls -lh rootfs.7z 2>/dev/null || true
log "✅ 构建成功完成!"
