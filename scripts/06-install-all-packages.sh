#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/../config"

. "$CONFIG_DIR/build-config.sh"

SYSTEM_TYPE="${SYSTEM_TYPE:-ubuntu-server}"
DESKTOP_ENV="${DESKTOP_ENV:-}"
UBUNTU_VERSION="${UBUNTU_VERSION:-noble}"
APT_RETRIES="${APT_RETRIES:-3}"
APT_UPGRADE="${APT_UPGRADE:-true}"

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [06] $*"; }

log "📦 安装软件包"

export DEBIAN_FRONTEND=noninteractive

apt_options=(
    -o "Acquire::Retries=${APT_RETRIES}"
    -o "Dpkg::Use-Pty=0"
    -o "Dpkg::Options::=--force-confdef"
    -o "Dpkg::Options::=--force-confold"
)

if [ "$APT_UPGRADE" = "true" ]; then
    log "  └─ 更新系统包..."
    chroot rootdir apt-get "${apt_options[@]}" upgrade -y
else
    log "  └─ 跳过 apt upgrade (APT_UPGRADE=$APT_UPGRADE)"
fi

DEVICE_PACKAGES="rmtfs protection-domain-mapper tqftpserv"
ALL_PACKAGES="$(get_packages "$SYSTEM_TYPE" "$DESKTOP_ENV") $DEVICE_PACKAGES"
read -r -a package_list <<< "$ALL_PACKAGES"

log "  └─ 软件包列表: $(echo "$ALL_PACKAGES" | tr -s ' ' | sed 's/^ //' | tr ' ' ',')"
log "  └─ 开始安装（这可能需要几分钟...）"
chroot rootdir apt-get "${apt_options[@]}" install -y "${package_list[@]}"

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
