set -e
git clone https://github.com/qaz6750/linux-downstream.git --branch linux-xiaomi-$1.y --depth 1 linux
patch linux/scripts/package/builddeb < builddeb.patch
cd linux
git add .
git commit -m "builddeb: Add Xiaomi Cepheus DTBs to boot partition"
make -j$(nproc) ARCH=arm64 LLVM=-22 cepheus_defconfig
make -j$(nproc) ARCH=arm64 LLVM=-22 deb-pkg
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

dpkg-deb --build --root-owner-group firmware-xiaomi-cepheus
dpkg-deb --build --root-owner-group alsa-xiaomi-cepheus
