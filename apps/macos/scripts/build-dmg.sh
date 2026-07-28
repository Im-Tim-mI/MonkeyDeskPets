#!/bin/bash
set -euo pipefail

macos_dir="$(cd "$(dirname "$0")/.." && pwd)"
repository_root="$(cd "$macos_dir/../.." && pwd)"
version="$(tr -d '[:space:]' < "$macos_dir/VERSION")"
release_dir="$repository_root/release"
app_path="$macos_dir/dist/MonkeyDeskPets.app"
icon_path="$macos_dir/.build/icon-generation/MonkeyDeskPets.icns"
background_path="$macos_dir/.build/dmg-background/installer-background.png"
dmg_path="$release_dir/MonkeyDeskPets-macOS-v${version}.dmg"

echo "安裝程式平台：macOS"
echo "安裝程式版本：$version"

"$macos_dir/scripts/build-app.sh" release
swift "$macos_dir/scripts/generate-dmg-background.swift" "$background_path"

mkdir -p "$release_dir"
staging_dir="$(mktemp -d)"
working_dir="$(mktemp -d)"
mounted_device=""
mount_point=""

cleanup() {
    if [[ -n "$mounted_device" ]]; then
        hdiutil detach "$mounted_device" >/dev/null 2>&1 || true
    elif [[ -n "$mount_point" ]]; then
        hdiutil detach "$mount_point" >/dev/null 2>&1 || true
    fi
    rm -rf "$staging_dir" "$working_dir"
}
trap cleanup EXIT

ditto "$app_path" "$staging_dir/MonkeyDeskPets.app"
ln -s /Applications "$staging_dir/Applications"
cp "$icon_path" "$staging_dir/.VolumeIcon.icns"
mkdir -p "$staging_dir/.background"
cp "$background_path" "$staging_dir/.background/installer-background.png"

if xcrun --find SetFile >/dev/null 2>&1; then
    xcrun SetFile -a C "$staging_dir"
else
    echo "警告：找不到 SetFile，DMG 仍會建立，但掛載磁碟可能顯示系統預設圖示。" >&2
fi

readwrite_dmg="$working_dir/MonkeyDeskPets-readwrite.dmg"
hdiutil create \
    -volname "MonkeyDeskPets" \
    -srcfolder "$staging_dir" \
    -ov \
    -format UDRW \
    "$readwrite_dmg"

attach_output="$(hdiutil attach -readwrite -noverify -noautoopen "$readwrite_dmg")"
mounted_device="$(printf '%s\n' "$attach_output" | awk '$1 ~ "^/dev/" { print $1; exit }')"
mount_point="$(printf '%s\n' "$attach_output" | awk -F '\t' 'index($0, "/Volumes/") { print $NF; exit }')"

if [[ -z "$mounted_device" || -z "$mount_point" ]]; then
    echo "錯誤：無法取得 DMG 掛載資訊。" >&2
    exit 1
fi

background_file="$mount_point/.background/installer-background.png"
if [[ ! -f "$background_file" ]]; then
    echo "錯誤：DMG 掛載後找不到安裝背景：$background_file" >&2
    exit 1
fi

osascript <<APPLESCRIPT
set dmgFolder to POSIX file "$mount_point" as alias
set backgroundFile to POSIX file "$background_file" as alias

tell application "Finder"
    open dmgFolder
    delay 1
    set dmgWindow to container window of dmgFolder
    set current view of dmgWindow to icon view
    set toolbar visible of dmgWindow to false
    set statusbar visible of dmgWindow to false
    set pathbar visible of dmgWindow to false
    set bounds of dmgWindow to {120, 120, 760, 520}
    set theViewOptions to the icon view options of dmgWindow
    set arrangement of theViewOptions to not arranged
    set icon size of theViewOptions to 96
    set text size of theViewOptions to 14
    set background picture of theViewOptions to backgroundFile
    set position of item "MonkeyDeskPets.app" of dmgFolder to {160, 220}
    set position of item "Applications" of dmgFolder to {480, 220}
    update dmgFolder without registering applications
    delay 5
    close dmgWindow
end tell
APPLESCRIPT

sync

hdiutil detach "$mounted_device"
mounted_device=""
mount_point=""

# Finder 可能直到磁碟卸載時才把版面寫回 .DS_Store，因此卸載後重新掛載驗證。
verify_output="$(hdiutil attach -readonly -noverify -noautoopen "$readwrite_dmg")"
mounted_device="$(printf '%s\n' "$verify_output" | awk '$1 ~ "^/dev/" { print $1; exit }')"
mount_point="$(printf '%s\n' "$verify_output" | awk -F '\t' 'index($0, "/Volumes/") { print $NF; exit }')"

if [[ -z "$mounted_device" || -z "$mount_point" ]]; then
    echo "錯誤：無法重新掛載 DMG 以驗證 Finder 版面。" >&2
    exit 1
fi

if [[ ! -f "$mount_point/.DS_Store" ]]; then
    echo "錯誤：DMG 卸載後仍找不到 Finder 版面設定（.DS_Store）。已停止建立。" >&2
    exit 1
fi

if [[ ! -f "$mount_point/.background/installer-background.png" ]]; then
    echo "錯誤：DMG 驗證時找不到雙語安裝背景。" >&2
    exit 1
fi

hdiutil detach "$mounted_device"
mounted_device=""
mount_point=""

hdiutil convert \
    "$readwrite_dmg" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -ov \
    -o "$dmg_path"

shasum -a 256 "$dmg_path" > "$release_dir/SHA256SUMS.txt"
echo "完成：$dmg_path"
echo "完成：$release_dir/SHA256SUMS.txt"
