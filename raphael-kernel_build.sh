set -e
git clone https://github.com/GengWei1997/linux.git --branch raphael-$1 --depth 1 linux
patch linux/scripts/package/builddeb < builddeb.patch
cd linux
git add .
git commit -m "builddeb: Add Xiaomi Raphael DTBs to boot partition"
wget -O arch/arm64/configs/raphael.config https://raw.githubusercontent.com/GengWei1997/kernel-deb/refs/heads/main/uefi-raphael.config
make -j$(nproc) ARCH=arm64 LLVM=-22 defconfig raphael.config
make -j$(nproc) ARCH=arm64 LLVM=-22 deb-pkg
cd ..

IMAGE_DEB=$(ls -1 linux-image-*.deb 2>/dev/null | grep -v '\-dbg_' | head -n1)
HEADERS_DEB=$(ls -1 linux-headers-*.deb 2>/dev/null | head -n1)

if [ -n "$IMAGE_DEB" ]; then
  mv "$IMAGE_DEB" linux-image-xiaomi-raphael.deb
fi
if [ -n "$HEADERS_DEB" ]; then
  mv "$HEADERS_DEB" linux-headers-xiaomi-raphael.deb
fi

cp linux/arch/arm64/boot/Image.gz .
cp linux/arch/arm64/boot/dts/qcom/sm8150-xiaomi-raphael.dtb .

rm -rf linux

dpkg-deb --build --root-owner-group firmware-xiaomi-raphael
dpkg-deb --build --root-owner-group alsa-xiaomi-raphael
