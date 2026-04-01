#!/bin/bash
# PetClaw — itch.io upload script
# Usage: ./tools/upload_itch.sh
set -e

BUTLER=~/bin/butler
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
EXPORT_DIR="$PROJECT_DIR/godot_project/export/web"
ZIP_FILE="$PROJECT_DIR/exports/petclaw-web.zip"
ITCH_TARGET="taichi040911/petclaw:html5"

echo "=== PetClaw itch.io Upload ==="

# Check butler
if [ ! -f "$BUTLER" ]; then
    echo "ERROR: butler not found at $BUTLER"
    echo "Install: curl -L -o /tmp/butler.zip 'https://broth.itch.zone/butler/darwin-amd64/LATEST/archive/default' && unzip /tmp/butler.zip -d ~/bin/"
    exit 1
fi

# Check export exists
if [ ! -f "$EXPORT_DIR/index.html" ]; then
    echo "Building Web export..."
    mkdir -p "$EXPORT_DIR"
    /Applications/Godot.app/Contents/MacOS/Godot --headless --path "$PROJECT_DIR/godot_project" --export-release "Web (HTML5)" "$EXPORT_DIR/index.html"
fi

# Create zip
echo "Creating upload zip..."
cd "$EXPORT_DIR"
zip -r "$ZIP_FILE" .

# Upload
echo "Uploading to itch.io ($ITCH_TARGET)..."
$BUTLER push "$ZIP_FILE" "$ITCH_TARGET"

echo ""
echo "=== Upload Complete ==="
$BUTLER status taichi040911/petclaw
