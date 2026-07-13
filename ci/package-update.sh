#!/bin/bash
set -euo pipefail

KERNEL_VERSION="${KERNEL_VERSION:?缺少 KERNEL_VERSION}"
OUTPUT_DIR="${OUTPUT_DIR:-dist}"
UPDATE_DIR="cepheus-update-v${KERNEL_VERSION}"

required_files=(
  linux-image-xiaomi-cepheus.deb
  linux-headers-xiaomi-cepheus.deb
  firmware-xiaomi-cepheus.deb
  alsa-xiaomi-cepheus.deb
)

for filename in "${required_files[@]}"; do
  if [ ! -f "$filename" ]; then
    echo "缺少增量更新文件: $filename" >&2
    exit 1
  fi
done

rm -rf "$UPDATE_DIR"
mkdir -p "$UPDATE_DIR/debs" "$OUTPUT_DIR"
cp "${required_files[@]}" "$UPDATE_DIR/debs/"
cp scripts/install-update.sh "$UPDATE_DIR/install.sh"
chmod +x "$UPDATE_DIR/install.sh"

cd "$UPDATE_DIR/debs"
apt-get download \
  grub-common:arm64 \
  grub2-common:arm64 \
  grub-efi-arm64-bin:arm64 \
  grub-efi-arm64:arm64
cd ../..

tar --sort=name --owner=0 --group=0 --numeric-owner \
  -cJf "$OUTPUT_DIR/${UPDATE_DIR}.tar.xz" "$UPDATE_DIR"
(
  cd "$OUTPUT_DIR"
  sha256sum "${UPDATE_DIR}.tar.xz" > "${UPDATE_DIR}.tar.xz.sha256"
)

printf '%s\n' "$OUTPUT_DIR/${UPDATE_DIR}.tar.xz"