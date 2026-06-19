#!/bin/bash
set -e

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [14] $*"; }

SYSTEM_TYPE="${SYSTEM_TYPE:-ubuntu-server}"

log "🔋 配置电源管理"

# 禁用 WiFi 省电模式（解决连 WiFi 后跳 ping 问题）
log "  └─ 禁用 WiFi 省电模式"
mkdir -p rootdir/etc/NetworkManager/conf.d
cat > rootdir/etc/NetworkManager/conf.d/wifi-powersave.conf << 'EOF'
[connection]
wifi.powersave = 2
EOF

# 桌面版：禁用睡眠/挂起（设备无法从挂起恢复）
if [[ "$SYSTEM_TYPE" != *"server"* ]]; then
  log "  └─ 屏蔽睡眠/挂起目标"
  chroot rootdir systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target 2>/dev/null || true
fi

log "✅ 电源管理配置完成"
