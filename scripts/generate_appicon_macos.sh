#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <source-1024-png> [appiconset-dir]"
  echo "Example: $0 ./icon-1024.png ./InkNoMi/Assets.xcassets/AppIcon.appiconset"
  exit 1
fi

SOURCE_ICON="$1"
APPICONSET_DIR="${2:-./InkNoMi/Assets.xcassets/AppIcon.appiconset}"

if [[ ! -f "$SOURCE_ICON" ]]; then
  echo "Source icon not found: $SOURCE_ICON" >&2
  exit 1
fi

if [[ ! -d "$APPICONSET_DIR" ]]; then
  echo "AppIcon set directory not found: $APPICONSET_DIR" >&2
  exit 1
fi

declare -a ICON_SPECS=(
  "16 appicon_16x16.png"
  "32 appicon_16x16@2x.png"
  "32 appicon_32x32.png"
  "64 appicon_32x32@2x.png"
  "128 appicon_128x128.png"
  "256 appicon_128x128@2x.png"
  "256 appicon_256x256.png"
  "512 appicon_256x256@2x.png"
  "512 appicon_512x512.png"
  "1024 appicon_512x512@2x.png"
)

for spec in "${ICON_SPECS[@]}"; do
  size="$(echo "$spec" | awk '{print $1}')"
  filename="$(echo "$spec" | awk '{print $2}')"
  destination="$APPICONSET_DIR/$filename"
  sips -s format png -z "$size" "$size" "$SOURCE_ICON" --out "$destination" >/dev/null
  echo "Generated ${filename} (${size}x${size})"
done

echo "macOS AppIcon generation complete at: $APPICONSET_DIR"
