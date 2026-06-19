# 小米 Cepheus (Mi 9) Linux UEFI 镜像构建 - 集中配置
# 被 build.sh 加载，提供系统类型 -> 基础设置/软件源/软件包 的映射

# 支持的系统类型（仅 Ubuntu，UEFI + grub 启动）
SYSTEM_TYPES="
  ubuntu-server
  ubuntu-gnome
  ubuntu-desktop
"

# 系统类型 -> 基础设置映射
# 用法: system_config <system_type> <desktop_env>
# 输出 KEY=VALUE，由 build.sh 导入环境
system_config() {
  case "$1" in
    "ubuntu-server")
      echo "UBUNTU_VERSION=${UBUNTU_VERSION:-noble}"
      echo "IMAGE_SIZE=3G"
      echo "IS_DESKTOP=false"
      echo "DESKTOP_ENV="
      ;;
    "ubuntu-gnome")
      echo "UBUNTU_VERSION=${UBUNTU_VERSION:-noble}"
      echo "IMAGE_SIZE=8G"
      echo "IS_DESKTOP=true"
      echo "DESKTOP_ENV=gnome"
      ;;
    "ubuntu-desktop")
      # Phosh 移动桌面，桌面变体由第二参数决定 (phosh-core/full/phone)
      echo "UBUNTU_VERSION=${UBUNTU_VERSION:-noble}"
      echo "IMAGE_SIZE=6G"
      echo "IS_DESKTOP=true"
      echo "DESKTOP_ENV=${2:-phosh-full}"
      ;;
    *)
      echo "UBUNTU_VERSION=${UBUNTU_VERSION:-noble}"
      echo "IMAGE_SIZE=3G"
      echo "IS_DESKTOP=false"
      echo "DESKTOP_ENV="
      ;;
  esac
}

# 镜像源配置（清华大学 Ubuntu Ports 镜像）
# 用法: sources_config <system_type>
sources_config() {
  echo "UBUNTU_MIRROR=https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/"
  echo "UBUNTU_SECURITY_MIRROR=http://ports.ubuntu.com/ubuntu-ports/"
}

# 软件包配置
# 用法: get_packages <system_type> <desktop_env>
get_packages() {
  local system_type="$1"
  local desktop_env="$2"

  # 基础包（UEFI 路线使用 systemd-boot/grub-efi，iptables 做 NCM NAT）
  local base_packages="bash-completion sudo apt-utils ssh openssh-server nano \
network-manager systemd-boot initramfs-tools chrony curl wget locales tzdata \
language-pack-zh-hans dnsmasq iptables iproute2"

  if [[ "$system_type" == *"server"* ]]; then
    echo "$base_packages"
    return
  fi

  case "$desktop_env" in
    "gnome")
      echo "$base_packages gnome-core gdm3"
      ;;
    "phosh-core")
      echo "$base_packages phosh-core"
      ;;
    "phosh-full")
      echo "$base_packages phosh"
      ;;
    "phosh-phone")
      echo "$base_packages phosh phosh-mobile-tweaks"
      ;;
    *)
      echo "$base_packages"
      ;;
  esac
}
