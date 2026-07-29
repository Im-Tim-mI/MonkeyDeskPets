#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
configuration="${1:-release}"
version="$(tr -d '[:space:]' < "$project_dir/VERSION")"
app_dir="$project_dir/dist/MonkeyDeskPets.app"
contents_dir="$app_dir/Contents"

echo "建置平台：macOS"
echo "建置版本：$version"

"$project_dir/scripts/sync-shared-resources.sh"
"$project_dir/scripts/generate-icons.sh"

cd "$project_dir"
swift build -c "$configuration"
binary_dir="$(swift build -c "$configuration" --show-bin-path)"
resource_bundle="$binary_dir/MonkeyDeskPets_MonkeyDeskPets.bundle"
default_sprite="$project_dir/Sources/MonkeyDeskPets/person-sprites.png"

if [[ ! -d "$resource_bundle" ]]; then
    echo "錯誤：SwiftPM 資源包不存在：$resource_bundle" >&2
    exit 1
fi

if [[ ! -s "$resource_bundle/person-sprites.png" ]]; then
    echo "錯誤：SwiftPM 資源包缺少預設精靈圖。" >&2
    exit 1
fi

if [[ ! -s "$default_sprite" ]]; then
    echo "錯誤：來源目錄缺少預設精靈圖：$default_sprite" >&2
    exit 1
fi

rm -rf "$app_dir"
mkdir -p "$contents_dir/MacOS" "$contents_dir/Resources"
cp "$binary_dir/MonkeyDeskPets" "$contents_dir/MacOS/MonkeyDeskPets"
cp "Sources/MonkeyDeskPets/Info.plist" "$contents_dir/Info.plist"
cp -R "$resource_bundle" "$contents_dir/Resources/"
# 額外直放一份不可由使用者資料覆蓋的預設圖，供 App bundle 路徑回退使用。
cp "$default_sprite" "$contents_dir/Resources/person-sprites.png"
cp "$project_dir/.build/icon-generation/MonkeyDeskPets.icns" \
    "$contents_dir/Resources/MonkeyDeskPets.icns"
chmod +x "$contents_dir/MacOS/MonkeyDeskPets"

if [[ ! -s "$contents_dir/Resources/person-sprites.png"
    || ! -s "$contents_dir/Resources/MonkeyDeskPets_MonkeyDeskPets.bundle/person-sprites.png" ]]; then
    echo "錯誤：組裝完成的 App 缺少預設精靈圖備份。" >&2
    exit 1
fi

if command -v sips >/dev/null 2>&1; then
    sprite_width="$(sips -g pixelWidth "$contents_dir/Resources/person-sprites.png" \
        | awk '/pixelWidth/ { print $2; exit }')"
    sprite_height="$(sips -g pixelHeight "$contents_dir/Resources/person-sprites.png" \
        | awk '/pixelHeight/ { print $2; exit }')"
    if [[ -z "$sprite_width" || -z "$sprite_height"
        || "$sprite_width" -lt 4 || "$sprite_height" -lt 2 ]]; then
        echo "錯誤：App 內預設精靈圖無效。" >&2
        exit 1
    fi
fi

# 清除從下載壓縮檔繼承的隔離與 Finder 延伸屬性，再對最終 App 完整簽章。
xattr -cr "$app_dir"
signing_identity="${MACOS_SIGNING_IDENTITY:--}"
if [[ "$signing_identity" == "-" ]]; then
    codesign --force --deep --sign - --timestamp=none "$app_dir"
    echo "提示：目前使用臨時簽章。公開散布仍建議使用 Developer ID 並完成公證。"
else
    codesign --force --deep --options runtime --timestamp \
        --sign "$signing_identity" "$app_dir"
fi
codesign --verify --deep --strict --verbose=2 "$app_dir"

echo "完成：$app_dir"
