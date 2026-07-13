#!/bin/bash
set -euo pipefail

ARTIFACTS_DIR="${ARTIFACTS_DIR:-artifacts}"
RELEASE_DIR="${RELEASE_DIR:-release-files}"
RELEASE_BODY="${RELEASE_BODY:-release-body.md}"
SIZE_LIMIT="${SIZE_LIMIT:-2147483648}"

mkdir -p "$RELEASE_DIR"
mapfile -t metadata_files < <(find "$ARTIFACTS_DIR" -type f -name 'rootfs-*.json' -print | sort)

if [ "${#metadata_files[@]}" -eq 0 ]; then
    echo "没有找到可发布的 rootfs 元数据" >&2
    exit 1
fi

{
    echo "## 小米 Cepheus (Mi 9) UEFI 系统镜像"
    echo
    echo "| 镜像 | 系统 | Ubuntu | 桌面 | 内核包版本 | UUID |"
    echo "| --- | --- | --- | --- | --- | --- |"
} > "$RELEASE_BODY"

large_files=()
for metadata_file in "${metadata_files[@]}"; do
    artifact_dir="$(dirname "$metadata_file")"
    filename="$(jq -r '.filename' "$metadata_file")"
    image_file="$artifact_dir/$filename"

    if [ ! -f "$image_file" ]; then
        echo "元数据对应的镜像不存在: $image_file" >&2
        exit 1
    fi

    system_type="$(jq -r '.system_type' "$metadata_file")"
    ubuntu_version="$(jq -r '.ubuntu_version' "$metadata_file")"
    desktop_env="$(jq -r '.desktop_env | if length == 0 then "-" else . end' "$metadata_file")"
    kernel_package_version="$(jq -r '.kernel_package_version' "$metadata_file")"
    rootfs_uuid="$(jq -r '.rootfs_uuid' "$metadata_file")"
    sha256="$(jq -r '.sha256' "$metadata_file")"
    file_size="$(stat -c '%s' "$image_file")"

    printf '| `%s` | `%s` | `%s` | `%s` | `%s` | `%s` |\n' \
        "$filename" "$system_type" "$ubuntu_version" "$desktop_env" \
        "$kernel_package_version" "$rootfs_uuid" >> "$RELEASE_BODY"

    if [ "$file_size" -le "$SIZE_LIMIT" ]; then
        cp "$image_file" "$RELEASE_DIR/$filename"
        printf '%s  %s\n' "$sha256" "$filename" > "$RELEASE_DIR/${filename%.7z}.sha256"
    else
        large_files+=("$filename")
    fi
done

{
    echo
    echo "### SHA256"
    echo '```text'
    jq -r '"\(.sha256)  \(.filename)"' "${metadata_files[@]}"
    echo '```'
    echo
    echo "默认账户：\`user\` / \`1234\`，\`root\` / \`1234\`。USB NCM 地址：\`172.16.42.1\`。"
    if [ "${#large_files[@]}" -gt 0 ]; then
        echo
        echo "### 大文件"
        echo "以下镜像超过 GitHub Release 的 2 GiB 单文件限制，请从本次 Actions Artifacts 下载："
        printf -- '- `%s`\n' "${large_files[@]}"
    fi
} >> "$RELEASE_BODY"