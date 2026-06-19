#!/bin/bash
set -e

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [04] $*"; }

HOSTNAME="${HOSTNAME:-xiaomi-cepheus}"
NAMESERVER="${NAMESERVER:-1.1.1.1}"

log "🌐 配置网络和主机名"
log "  └─ 主机名: ${HOSTNAME}"
log "  └─ DNS: ${NAMESERVER}"

echo "nameserver ${NAMESERVER}" > rootdir/etc/resolv.conf
echo "${HOSTNAME}" > rootdir/etc/hostname
echo "127.0.0.1 localhost
127.0.1.1 ${HOSTNAME}" > rootdir/etc/hosts

log "✅ 网络配置完成"
