#!/bin/bash
set -e

SYSTEM_TYPE="${SYSTEM_TYPE:-ubuntu-server}"

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [08] $*"; }

log "🖥️ 添加屏幕管理命令"

# 屏幕管理命令仅对 server 版提供（桌面版由桌面环境管理电源）
if [[ "$SYSTEM_TYPE" != *"server"* ]]; then
    log "  └─ 桌面版跳过屏幕命令"
    log "✅ 屏幕命令配置完成"
    exit 0
fi

# 添加 leijun(熄屏) / jinfan(亮屏) 命令到全局 bash 配置
log "  └─ 添加 leijun / jinfan 命令"
cat >> rootdir/etc/bash.bashrc << 'EOF'
# 屏幕管理命令
leijun() {
    if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_TTY" ]; then
        sudo sh -c 'TERM=linux setterm --blank force </dev/tty1'
    else
        setterm --blank force --term linux </dev/tty1
    fi
    echo "屏幕已关闭"
}

jinfan() {
    if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_TTY" ]; then
        sudo sh -c 'TERM=linux setterm --blank poke </dev/tty1'
    else
        setterm --blank poke --term linux </dev/tty1
    fi
    echo "屏幕已开启"
}
EOF

# 配置开机 15 秒后自动熄屏的 systemd 服务
log "  └─ 配置开机 15 秒自动熄屏服务"
cat > rootdir/etc/systemd/system/blank_screen.service << 'EOF'
[Unit]
Description=Auto-blank screen after 15s
After=multi-user.target

[Service]
Type=simple
ExecStartPre=/bin/bash -c "/usr/bin/sleep 15"
ExecStart=sh -c 'TERM=linux setterm --blank force </dev/tty1'
User=root
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
chroot rootdir systemctl enable blank_screen.service

log "✅ 屏幕命令配置完成"
