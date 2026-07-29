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

rm -rf "$app_dir"
mkdir -p "$contents_dir/MacOS" "$contents_dir/Resources"
cp "$binary_dir/MonkeyDeskPets" "$contents_dir/MacOS/MonkeyDeskPets"
cp "Sources/MonkeyDeskPets/Info.plist" "$contents_dir/Info.plist"
cp -R "$binary_dir/MonkeyDeskPets_MonkeyDeskPets.bundle" "$contents_dir/Resources/"
cp "$project_dir/.build/icon-generation/MonkeyDeskPets.icns" \
    "$contents_dir/Resources/MonkeyDeskPets.icns"
chmod +x "$contents_dir/MacOS/MonkeyDeskPets"

echo "完成：$app_dir"
