#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/../config"

. "$CONFIG_DIR/build-config.sh"

SYSTEM_TYPE="${SYSTEM_TYPE:-ubuntu-server}"
DESKTOP_ENV="${DESKTOP_ENV:-}"
UBUNTU_VERSION="${UBUNTU_VERSION:-noble}"

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [06] $*"; }

log "📦 安装软件包"

export DEBIAN_FRONTEND=noninteractive

log "  └─ 更新系统包..."
chroot rootdir apt-get upgrade -y

ALL_PACKAGES="$(get_packages "$SYSTEM_TYPE" "$DESKTOP_ENV")"

log "  └─ 软件包列表: $(echo "$ALL_PACKAGES" | tr -s ' ' | sed 's/^ //' | tr ' ' ',')"
log "  └─ 开始安装（这可能需要几分钟...）"
chroot rootdir apt-get install -y $ALL_PACKAGES

# 安装设备特定软件包
log "  └─ 安装设备包: rmtfs protection-domain-mapper tqftpserv"
chroot rootdir apt-get install -y rmtfs protection-domain-mapper tqftpserv

# 桌面版 GNOME 自动登录
if [ "$DESKTOP_ENV" = "gnome" ]; then
    log "  └─ 配置 GDM 自动登录"
    mkdir -p rootdir/etc/gdm3
    cat > rootdir/etc/gdm3/custom.conf << 'EOF'
[daemon]
AutomaticLoginEnable=true
AutomaticLogin=user
EOF
fi

log "✅ 软件包安装完成"
