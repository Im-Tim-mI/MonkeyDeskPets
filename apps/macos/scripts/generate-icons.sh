#!/bin/bash
set -euo pipefail

macos_dir="$(cd "$(dirname "$0")/.." && pwd)"
repository_root="$(cd "$macos_dir/../.." && pwd)"
source_icon="$repository_root/shared/assets/app-icon-1024.png"
output_dir="$macos_dir/.build/icon-generation"
output_icon="$output_dir/MonkeyDeskPets.icns"

if [[ ! -f "$source_icon" ]]; then
    echo "錯誤：找不到猴子主圖示 $source_icon" >&2
    exit 1
fi

mkdir -p "$output_dir"
temporary_dir="$(mktemp -d)"
trap 'rm -rf "$temporary_dir"' EXIT
iconset="$temporary_dir/MonkeyDeskPets.iconset"
mkdir -p "$iconset"

make_icon() {
    local pixels="$1"
    local filename="$2"
    sips -z "$pixels" "$pixels" "$source_icon" \
        --out "$iconset/$filename" >/dev/null
}

make_icon 16 "icon_16x16.png"
make_icon 32 "icon_16x16@2x.png"
make_icon 32 "icon_32x32.png"
make_icon 64 "icon_32x32@2x.png"
make_icon 128 "icon_128x128.png"
make_icon 256 "icon_128x128@2x.png"
make_icon 256 "icon_256x256.png"
make_icon 512 "icon_256x256@2x.png"
make_icon 512 "icon_512x512.png"
make_icon 1024 "icon_512x512@2x.png"

iconutil -c icns "$iconset" -o "$output_icon"
echo "完成：$output_icon"
