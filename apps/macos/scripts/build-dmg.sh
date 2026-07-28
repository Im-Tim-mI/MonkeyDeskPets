#!/bin/bash
set -euo pipefail

macos_dir="$(cd "$(dirname "$0")/.." && pwd)"
repository_root="$(cd "$macos_dir/../.." && pwd)"
version="$(tr -d '[:space:]' < "$repository_root/VERSION")"
release_dir="$repository_root/release"
app_path="$macos_dir/dist/MonkeyDeskPets.app"
icon_path="$macos_dir/.build/icon-generation/MonkeyDeskPets.icns"
background_path="$macos_dir/.build/dmg-background/installer-background.png"
dmg_path="$release_dir/MonkeyDeskPets-macOS-v${version}.dmg"

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

osascript <<'APPLESCRIPT'
tell application "Finder"
    tell disk "MonkeyDeskPets"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set pathbar visible of container window to false
        set bounds of container window to {120, 120, 760, 520}
        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 96
        set text size of theViewOptions to 14
        set background picture of theViewOptions to file ".background:installer-background.png"
        set position of item "MonkeyDeskPets.app" of container window to {160, 220}
        set position of item "Applications" of container window to {480, 220}
        update without registering applications
        delay 2
        close
    end tell
end tell
APPLESCRIPT

sync
hdiutil detach "$mounted_device"
mounted_device=""

hdiutil convert \
    "$readwrite_dmg" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -ov \
    -o "$dmg_path"

shasum -a 256 "$dmg_path" > "$release_dir/SHA256SUMS.txt"
echo "完成：$dmg_path"
echo "完成：$release_dir/SHA256SUMS.txt"
