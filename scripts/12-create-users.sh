#!/bin/bash
set -e

ROOT_PASS="${ROOT_PASS:-1234}"
USER_NAME="${USER_NAME:-user}"
USER_PASS="${USER_PASS:-1234}"

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [12] $*"; }

log "👤 创建用户和配置 SSH"
log "  └─ 创建用户: ${USER_NAME}"

echo "root:${ROOT_PASS}" | chroot rootdir chpasswd
chroot rootdir useradd -m -G sudo -s /bin/bash ${USER_NAME}
echo "${USER_NAME}:${USER_PASS}" | chroot rootdir chpasswd

log "  └─ 启用 SSH root/密码登录"
echo "PermitRootLogin yes" >> rootdir/etc/ssh/sshd_config
echo "PasswordAuthentication yes" >> rootdir/etc/ssh/sshd_config

log "✅ 用户和 SSH 配置完成"
