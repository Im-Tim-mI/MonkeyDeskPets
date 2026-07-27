#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
configuration="${1:-release}"
app_dir="$project_dir/dist/MonkeyDeskPets.app"
contents_dir="$app_dir/Contents"

"$project_dir/scripts/sync-shared-resources.sh"

cd "$project_dir"
swift build -c "$configuration"
binary_dir="$(swift build -c "$configuration" --show-bin-path)"

rm -rf "$app_dir"
mkdir -p "$contents_dir/MacOS" "$contents_dir/Resources"
cp "$binary_dir/MonkeyDeskPets" "$contents_dir/MacOS/MonkeyDeskPets"
cp "Sources/MonkeyDeskPets/Info.plist" "$contents_dir/Info.plist"
cp -R "$binary_dir/MonkeyDeskPets_MonkeyDeskPets.bundle" "$contents_dir/Resources/"
chmod +x "$contents_dir/MacOS/MonkeyDeskPets"

echo "完成：$app_dir"
