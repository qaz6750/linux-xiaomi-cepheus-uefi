#!/bin/bash
set -euo pipefail

SYSTEM_TYPE="${SYSTEM_TYPE:?缺少 SYSTEM_TYPE}"
KERNEL_VERSION="${KERNEL_VERSION:?缺少 KERNEL_VERSION}"
UBUNTU_VERSION="${UBUNTU_VERSION:?缺少 UBUNTU_VERSION}"
DESKTOP_ENV="${DESKTOP_ENV:-}"
KERNEL_DEBS_DIR="${KERNEL_DEBS_DIR:-xiaomi-cepheus-debs_${KERNEL_VERSION}}"
OUTPUT_DIR="${OUTPUT_DIR:-dist}"

artifact_name="rootfs-${SYSTEM_TYPE}-${UBUNTU_VERSION}-kernel-${KERNEL_VERSION}"
if [ -n "$DESKTOP_ENV" ]; then
    artifact_name="${artifact_name}-${DESKTOP_ENV}"
fi

mkdir -p "$OUTPUT_DIR"
mv rootfs.7z "$OUTPUT_DIR/${artifact_name}.7z"

sha256=$(sha256sum "$OUTPUT_DIR/${artifact_name}.7z" | awk '{print $1}')
rootfs_uuid=$(blkid -s UUID -o value rootfs.img 2>/dev/null || true)
kernel_package=$(dpkg-deb -f "$KERNEL_DEBS_DIR/linux-image-xiaomi-cepheus.deb" Package)
kernel_package_version=$(dpkg-deb -f "$KERNEL_DEBS_DIR/linux-image-xiaomi-cepheus.deb" Version)

printf '%s  %s\n' "$sha256" "${artifact_name}.7z" > "$OUTPUT_DIR/${artifact_name}.sha256"
jq -n \
    --arg filename "${artifact_name}.7z" \
    --arg system_type "$SYSTEM_TYPE" \
    --arg ubuntu_version "$UBUNTU_VERSION" \
    --arg desktop_env "$DESKTOP_ENV" \
    --arg kernel_version "$KERNEL_VERSION" \
    --arg kernel_package "$kernel_package" \
    --arg kernel_package_version "$kernel_package_version" \
    --arg rootfs_uuid "${rootfs_uuid:-unknown}" \
    --arg sha256 "$sha256" \
    '{filename: $filename, system_type: $system_type, ubuntu_version: $ubuntu_version, desktop_env: $desktop_env, kernel_version: $kernel_version, kernel_package: $kernel_package, kernel_package_version: $kernel_package_version, rootfs_uuid: $rootfs_uuid, sha256: $sha256}' \
    > "$OUTPUT_DIR/${artifact_name}.json"

printf '%s\n' "$artifact_name"