# 小米 Cepheus 设备 Linux UEFI 系统镜像构建项目

本项目提供用于小米 Cepheus 设备（小米9（Mi 9））的 Ubuntu Linux UEFI 系统镜像构建脚本和自动化工作流，支持桌面环境和服务器版本。

## 📋 项目概述

本项目包含完整的构建工具链，可用于构建适用于小米 Cepheus 设备的 Linux UEFI 系统镜像，包括：

- **内核编译工作流** - 自动化编译定制的 Linux 内核
- **Ubuntu Phosh** - 带 Phosh 移动桌面的 Ubuntu 系统
- **Ubuntu GNOME** - 带 GNOME 桌面环境的 Ubuntu 系统
- **Ubuntu Server** - 无图形界面的 Ubuntu 服务器系统

## �️ 项目结构

系统镜像构建采用模块化设计，便于维护和扩展：

```
build.sh                      # 构建编排器（入口）
config/build-config.sh        # 集中配置：系统类型 → 镜像大小/版本/软件包映射
ci/                           # CI 矩阵、产物元数据与 Release 汇总逻辑
   package-update.sh           #   打包设备 deb + GRUB 增量更新包
.github/workflows/
    build-system.yml            # prepare → matrix build → release 流水线
    编译kernel.yml              # 内核编译与 kernel-v* Release
scripts/                      # 按阶段拆分的构建脚本（带时间戳日志）
  01-create-image.sh          #   创建并挂载 ext4 镜像
  02-bootstrap.sh             #   debootstrap 安装基础系统
  03-mount-dev.sh             #   绑定挂载 /dev /proc /sys
  04-config-network.sh        #   主机名与 DNS
  05-apt-setup.sh             #   配置清华 apt 源
  06-install-all-packages.sh  #   安装基础/桌面/设备软件包
  07-config-locale.sh         #   时区与中文语言环境
  08-add-screen-commands.sh   #   server 屏幕命令与自动熄屏
  09-install-kernel.sh        #   安装内核/固件/ALSA deb
  10-config-ncm.sh            #   USB NCM 网络共享
  11-config-fstab.sh          #   UEFI fstab (esp + linux 分区)
  12-create-users.sh          #   创建用户与 SSH 配置
  13-config-efi.sh            #   grub-efi-arm64 引导配置
  14-config-power.sh          #   电源管理（禁用 WiFi 省电）
  15-cleanup.sh               #   清理 apt 缓存与监管证书
  16-finalize.sh              #   卸载并打包 rootfs.7z
   install-update.sh           #   已安装系统的增量更新器
cepheus-kernel_build.sh       # 内核编译脚本
firmware-xiaomi-cepheus/      # 设备固件包
alsa-xiaomi-cepheus/          # ALSA UCM 音频配置包
```

本地构建（需 root）：

```bash
# 先准备内核包目录 xiaomi-cepheus-debs_<内核版本>/，放入 *-xiaomi-cepheus.deb
sudo ./build.sh ubuntu-gnome 7.1            # GNOME 桌面版
sudo ./build.sh ubuntu-server 7.1           # 服务器版
sudo ./build.sh ubuntu-phosh 7.1 phosh-full # Phosh 移动桌面版
```

系统类型统一按用途/桌面命名为 `ubuntu-server`、`ubuntu-gnome` 和 `ubuntu-phosh`。旧的 `ubuntu-desktop` 参数仍可用于本地构建，但会映射到 `ubuntu-phosh`。

构建阶段仍使用配置中的预分配空间，打包前会自动将 ext4 和 `rootfs.img` 收缩到已用空间并默认保留 512 MiB。刷入更大的 `mindowswin` 分区后，`x-systemd.growfs` 会在启动时自动扩展根文件系统。可按需调整余量：

```bash
sudo ROOTFS_FREE_SPACE_MIB=1024 ./build.sh ubuntu-gnome 7.1
```

## �📋 目前工作

- ✅ Wi-Fi (2.4Ghz，5Ghz)
- ✅ 蓝牙 (文件传输，音频)
- ✅ USB (ssh，OTG)
- ✅ 电池
- ✅ 实时时钟
- ✅ 显示
- ✅ 触摸
- ✅ 手电筒 (LED及强度调节)
- ✅ GPU
- ✅ FDE

## 🚀 快速开始

### 使用 GitHub Actions 自动化构建

1. **Fork 本仓库**到你的 GitHub 账户

2. **构建内核**：
   - 进入仓库的 Actions 页面
   - 选择 "内核编译" 工作流
   - 点击 "Run workflow"
   - 输入内核版本号（如 `6.18`）
   - 等待构建完成，产物将自动发布到 Releases

3. **构建系统镜像**：
   - 选择 "构建系统镜像" 工作流
   - 点击 "Run workflow"
   - `system_types`：填写 `ubuntu-server`、`ubuntu-gnome`、`ubuntu-phosh`，可用逗号批量选择
   - `kernel_versions`：填写已有 `kernel-v*` Release 的版本，可用逗号批量选择
   - `phosh_variants`：仅 `ubuntu-phosh` 使用，支持 `phosh-core`、`phosh-full`、`phosh-phone`
   - `kernel_repository`：留空使用当前仓库，也可指定提供内核 Release 的其他仓库
   - 工作流先生成矩阵，再并行构建所有组合；全部成功后更新 `rootfs-latest` 统一 Release

每个构建组合会上传独立 Artifact，包含镜像、SHA256 和 JSON 元数据。文件名格式为 `rootfs-<system>-<ubuntu>-kernel-<kernel>[-<phosh>].7z`；超过 GitHub Release 2 GiB 限制的镜像只保留在 Actions Artifacts。

每次内核编译 Release 还会生成 `cepheus-update-v<内核版本>.tar.xz`。该增量包包含内核、headers、固件、ALSA UCM、GRUB 2 相关 deb 和自动安装脚本，可直接更新已刷入的系统。

## 📦 镜像特性

### 通用特性
- ✅ 清华大学软件源
- ✅ 简体中文语言环境
- ✅ 中国标准时区
- ✅ 支持NCM（usb连接电脑，ssh示例：`ssh user@172.16.42.1`）
- ✅ 预装 SSH 服务器
- ✅ 允许 root SSH 登录
- ✅ 包含必要的设备驱动和固件
- ✅ 默认用户：`user`（密码：`1234`），`root`（密码：`1234`）
- ✅ dpkg更新内核

### 桌面版额外特性
- ✅ GNOME 桌面环境（`ubuntu-gnome`）
- ✅ Phosh 移动桌面环境（`ubuntu-phosh`）

### 服务器版额外特性
- ✅ 网络管理器
- ✅ 开机15秒后自动熄屏
- ✅ 命令行输入 `leijun` 关闭屏幕，`jinfan` 打开屏幕

## 🔧 安装到设备

### 准备工作
1. **解锁 Bootloader**：确保设备已解锁 Bootloader
2. **安装工具**：安装 `fastboot` 和 `adb`

### 刷机步骤

```bash
教程没有写，会刷的很简单
修改分区创建esp和linux分区

只需要替换grub.cfg的内容
内核版本，UUID，linux分区编号

进recovery挂载esp，推送你修改好的esp分区（或者用Windows的大容量boot更方便）

fastboot flash linux rootfs.img

重启手机进入linux后命令行执行
sudo install -m 0644 /usr/lib/grub/arm64-efi/monolithic/grubaa64.efi /boot/efi/EFI/ubuntu/grubaa64.efi
sudo install -m 0644 /usr/lib/grub/arm64-efi/monolithic/grubaa64.efi /boot/efi/EFI/BOOT/BOOTAA64.EFI
sudo grub-mkconfig -o /boot/efi/EFI/ubuntu/grub.cfg
会生成新的efi配置，自动适配你的分区
```

## ❓ 常见问题解答 (FAQ)

### 如何增量更新内核、固件和 GRUB 2

不需要重新刷写 `rootfs.img`。从对应的 `kernel-v<版本>` Release 下载增量包和校验文件，在手机当前 Linux 系统中执行：

```bash
sha256sum -c cepheus-update-v7.1.tar.xz.sha256
tar -xJf cepheus-update-v7.1.tar.xz
cd cepheus-update-v7.1
sudo ./install.sh
sudo reboot
```

安装器会完成以下操作：

- 校验系统和所有 deb 的架构为 arm64
- 安装内核、headers、设备固件和 ALSA UCM deb
- 更新 `grub-common`、`grub2-common`、`grub-efi-arm64-bin` 和 `grub-efi-arm64`
- 重新生成全部 initramfs
- 将 ESP 中已有的 GRUB 文件备份到 `/var/backups/cepheus-esp-grub-<时间>`
- 更新 ESP 中的 `EFI/ubuntu/grubaa64.efi` 和回退启动文件 `EFI/BOOT/BOOTAA64.EFI`
- 直接生成 ESP 中的 `EFI/ubuntu/grub.cfg`

运行前请确认 ESP 已挂载到 `/boot/efi`。如果挂载点不同，可通过 `ESP_MOUNTPOINT=/实际路径 sudo -E ./install.sh` 指定。安装过程中不要关机；安装成功并重启后才会使用新内核。旧内核包不会由该脚本自动删除，可在确认新内核稳定后手动清理。

- [解决Windows下无法连接使用CDC NCM驱动](https://www.bilibili.com/video/BV1tW4y1A79V/)

- server版怎么连接网络？？？
	- 1.OTG连接网线系统会自动识别
	- 2.OTG连接键盘输入 `nmtui` 连接wifi
	- 3.usb连接电脑安装好NCM驱动后输入 `nmtui` 连接wifi

## 🙏 致谢

- 感谢所有 Linux 内核开发者的辛勤工作
- 感谢 Debian 和 Ubuntu 社区
- 感谢 Phosh 桌面环境开发团队
- 感谢所有贡献者和用户的支持
- [@cuicanmx](https://github.com/cuicanmx) - 提供帮助以及创新思路
- [@map220v](https://github.com/map220v/ubuntu-xiaomi-nabu) - 原项目
- [@Pc1598](https://github.com/Pc1598) - sm8150-mainline 内核维护
- [qaz6750/linux-downstream](https://github.com/qaz6750/linux-downstream) - 内核项目（本项目使用）
- [sm8150-mainline/linux](https://gitlab.com/sm8150-mainline/linux) - 内核项目
- [mu_aloha_platforms](https://github.com/Project-Aloha/mu_aloha_platforms) - 骁龙设备的 Mu UEFI