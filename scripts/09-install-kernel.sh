#!/bin/bash
set -e

SYSTEM_TYPE="${SYSTEM_TYPE:-ubuntu-server}"
KERNEL_DEBS_DIR="${KERNEL_DEBS_DIR:-.}"

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [09] $*"; }

log "🧠 安装内核"
log "  └─ 内核包目录: ${KERNEL_DEBS_DIR}"

cp ${KERNEL_DEBS_DIR}/*-xiaomi-cepheus.deb rootdir/tmp/

log "  └─ 安装 linux-image..."
chroot rootdir dpkg -i /tmp/linux-image-xiaomi-cepheus.deb

log "  └─ 安装 linux-headers..."
chroot rootdir dpkg -i /tmp/linux-headers-xiaomi-cepheus.deb

log "  └─ 安装 firmware..."
chroot rootdir dpkg -i /tmp/firmware-xiaomi-cepheus.deb

# 桌面版安装 ALSA UCM 配置（音频）
if [[ "$SYSTEM_TYPE" != *"server"* ]]; then
    if [ -f rootdir/tmp/alsa-xiaomi-cepheus.deb ]; then
        log "  └─ 安装 ALSA UCM 配置..."
        chroot rootdir dpkg -i /tmp/alsa-xiaomi-cepheus.deb
    fi
fi

rm -f rootdir/tmp/*-xiaomi-cepheus.deb

# 修改 pd-mapper 服务（移除内核版本条件限制）
sed -i '/ConditionKernelVersion/d' rootdir/lib/systemd/system/pd-mapper.service 2>/dev/null || true

log "✅ 内核安装完成"
