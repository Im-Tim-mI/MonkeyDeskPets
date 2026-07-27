#!/bin/bash
set -euo pipefail

macos_dir="$(cd "$(dirname "$0")/.." && pwd)"
repository_root="$(cd "$macos_dir/../.." && pwd)"
target_dir="$macos_dir/Sources/MonkeyDeskPets"
shared_assets="$repository_root/shared/assets"

required_assets=(
    "person-sprites.png"
    "author-avatar.png"
    "logitech-ad.jpeg"
)

for asset in "${required_assets[@]}"; do
    source_path="$shared_assets/$asset"
    if [[ ! -f "$source_path" ]]; then
        echo "錯誤：找不到共用素材 $source_path" >&2
        exit 1
    fi
    cp "$source_path" "$target_dir/$asset"
done

cp "$repository_root/LICENSE" \
    "$target_dir/MonkeyDeskPets-Noncommercial-License-1.0.txt"
cp "$repository_root/NOTICE" "$target_dir/NOTICE.txt"
cp "$repository_root/POLYFORM-NONCOMMERCIAL-1.0.0.txt" \
    "$target_dir/PolyForm-Noncommercial-1.0.0.txt"
cp "$repository_root/ADDITIONAL-TERMS-zh-TW.txt" \
    "$target_dir/ADDITIONAL-TERMS-zh-TW.txt"
cp "$repository_root/ADDITIONAL-TERMS-en.txt" \
    "$target_dir/ADDITIONAL-TERMS-en.txt"

echo "完成：已同步共用素材與授權文件"
