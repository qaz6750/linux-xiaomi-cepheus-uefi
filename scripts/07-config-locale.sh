#!/bin/bash
set -e

SYSTEM_TYPE="${SYSTEM_TYPE:-ubuntu-server}"

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [07] $*"; }

log "🌍 配置时区和语言"

# 设置时区
log "  └─ 时区: Asia/Shanghai"
echo "Asia/Shanghai" > rootdir/etc/timezone
chroot rootdir ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# 桌面版安装完整中文语言包与输入法
if [[ "$SYSTEM_TYPE" != *"server"* ]]; then
    log "  └─ 安装桌面中文语言包与输入法"
    export DEBIAN_FRONTEND=noninteractive
    chroot rootdir apt-get install -y \
        fonts-arphic-uming fonts-arphic-ukai fonts-noto-cjk fonts-noto-cjk-extra \
        language-pack-gnome-zh-hans-base language-pack-zh-hans-base \
        language-pack-zh-hans language-pack-gnome-zh-hans \
        ibus-libpinyin ibus-table ibus-table-wubi || true
fi

# 配置语言环境
log "  └─ 生成 locale (en_US.UTF-8 / zh_CN.UTF-8)"
cat > rootdir/etc/locale.gen << 'EOF'
en_US.UTF-8 UTF-8
zh_CN.UTF-8 UTF-8
EOF
chroot rootdir locale-gen
chroot rootdir update-locale LANG=en_US.UTF-8 LANGUAGE=en_US:en

# 配置动态语言切换（SSH 使用中文，TTY 使用英文，避免 TTY 中文乱码）
log "  └─ 配置 SSH 动态中文语言"
cat > rootdir/etc/profile.d/99-locale-fix.sh << 'EOF'
# 如果是SSH连接，则使用中文
if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_TTY" ]; then
    export LANG=zh_CN.UTF-8
    export LANGUAGE=zh_CN:zh
    export LC_ALL=zh_CN.UTF-8
fi
EOF
chmod +x rootdir/etc/profile.d/99-locale-fix.sh

log "✅ 时区语言配置完成"
