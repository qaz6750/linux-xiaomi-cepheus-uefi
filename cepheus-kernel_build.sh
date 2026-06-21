set -e
# 浅克隆带一定深度，便于导出最近的 commit 历史用于 release 变更说明
git clone https://github.com/qaz6750/linux-downstream.git --branch linux-xiaomi-$1.y --depth 30 linux

# 在打补丁/提交之前，导出上游真实 commit 信息到工作区根目录
# (脚本结尾会删除 linux 目录，需提前导出；这些文件供 CI 注入 release)
git -C linux rev-parse --short HEAD > kernel-commit.txt
git -C linux log --pretty=format:'- %s (%h)' -20 > kernel-commits.txt

patch linux/scripts/package/builddeb < builddeb.patch
cd linux
git add .
# 用内联身份提交，避免 CI runner 未配置 git user 时报 "empty ident name"
git -c user.name="cepheus-ci" -c user.email="ci@localhost" commit -m "builddeb: Add Xiaomi Cepheus DTBs to boot partition"

# 统一的内核 make 封装：
# - 始终使用 LLVM=-22 工具链 (clang-22 / ld.lld-22 等)
# - 若环境中存在 ccache，则用 ccache 包裹 clang-22 加速重复编译 (CI 缓存命中时显著提速)
# - 本地无 ccache 时自动回退到普通编译
kmake() {
  if command -v ccache >/dev/null 2>&1; then
    make -j"$(nproc)" ARCH=arm64 LLVM=-22 CC="ccache clang-22" HOSTCC="ccache clang-22" "$@"
  else
    make -j"$(nproc)" ARCH=arm64 LLVM=-22 "$@"
  fi
}

kmake cepheus_defconfig
kmake deb-pkg
cd ..

IMAGE_DEB=$(ls -1 linux-image-*.deb 2>/dev/null | grep -v '\-dbg_' | head -n1)
HEADERS_DEB=$(ls -1 linux-headers-*.deb 2>/dev/null | head -n1)

if [ -n "$IMAGE_DEB" ]; then
  mv "$IMAGE_DEB" linux-image-xiaomi-cepheus.deb
fi
if [ -n "$HEADERS_DEB" ]; then
  mv "$HEADERS_DEB" linux-headers-xiaomi-cepheus.deb
fi

cp linux/arch/arm64/boot/Image.gz .
cp linux/arch/arm64/boot/dts/qcom/sm8150-xiaomi-cepheus.dtb .

rm -rf linux

# 用内核版本号更新 firmware/alsa 包版本，确保每次构建都产生新版本
KVER=$(dpkg-deb -f linux-image-xiaomi-cepheus.deb Version | cut -d- -f1)
sed -i "s/^Version: .*/Version: $KVER/" firmware-xiaomi-cepheus/DEBIAN/control
sed -i "s/^Version: .*/Version: $KVER/" alsa-xiaomi-cepheus/DEBIAN/control

dpkg-deb --build --root-owner-group firmware-xiaomi-cepheus
dpkg-deb --build --root-owner-group alsa-xiaomi-cepheus
