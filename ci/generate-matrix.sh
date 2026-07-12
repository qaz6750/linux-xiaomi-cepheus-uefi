#!/bin/bash
set -euo pipefail

SYSTEM_TYPES="${SYSTEM_TYPES:-ubuntu-server,ubuntu-gnome,ubuntu-phosh}"
KERNEL_VERSIONS="${KERNEL_VERSIONS:-7.1}"
DESKTOP_ENVIRONMENTS="${DESKTOP_ENVIRONMENTS:-phosh-full}"

trim() {
    local value="$1"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    printf '%s' "$value"
}

append_entry() {
    local system_type="$1"
    local kernel_version="$2"
    local desktop_env="$3"

    jq -cn \
        --arg system_type "$system_type" \
        --arg kernel_version "$kernel_version" \
        --arg desktop_env "$desktop_env" \
        '{system_type: $system_type, kernel_version: $kernel_version, desktop_env: $desktop_env}'
}

entries=()
IFS=',' read -r -a system_types <<< "$SYSTEM_TYPES"
IFS=',' read -r -a kernel_versions <<< "$KERNEL_VERSIONS"
IFS=',' read -r -a desktop_environments <<< "$DESKTOP_ENVIRONMENTS"

for raw_system_type in "${system_types[@]}"; do
    system_type="$(trim "$raw_system_type")"
    case "$system_type" in
        ubuntu-server|ubuntu-gnome|ubuntu-phosh) ;;
        *)
            echo "不支持的系统类型: $system_type" >&2
            exit 1
            ;;
    esac

    for raw_kernel_version in "${kernel_versions[@]}"; do
        kernel_version="$(trim "$raw_kernel_version")"
        if [ -z "$kernel_version" ]; then
            echo "内核版本不能为空" >&2
            exit 1
        fi

        if [ "$system_type" = "ubuntu-phosh" ]; then
            for raw_desktop_env in "${desktop_environments[@]}"; do
                desktop_env="$(trim "$raw_desktop_env")"
                case "$desktop_env" in
                    phosh-core|phosh-full|phosh-phone) ;;
                    *)
                        echo "不支持的 Phosh 变体: $desktop_env" >&2
                        exit 1
                        ;;
                esac
                entries+=("$(append_entry "$system_type" "$kernel_version" "$desktop_env")")
            done
        else
            entries+=("$(append_entry "$system_type" "$kernel_version" "")")
        fi
    done
done

if [ "${#entries[@]}" -eq 0 ]; then
    echo "构建矩阵为空" >&2
    exit 1
fi

printf '%s\n' "${entries[@]}" | jq -sc '{include: .}'