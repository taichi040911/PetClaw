#!/bin/bash
# PetClaw — itch.io upload script
# Usage: ./tools/upload_itch.sh [version]
# First time: run "butler login" in terminal first!
set -e

VERSION="${1:-0.6.0}"
BUTLER=~/bin/butler
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
EXPORT_DIR="$PROJECT_DIR/godot_project/export/web"
ITCH_TARGET="taichi040911/petclaw:html5"

echo "=== PetClaw itch.io Upload v${VERSION} ==="

# Check butler
if [ ! -f "$BUTLER" ]; then
    echo "ERROR: butler not found at $BUTLER"
    echo "Install: curl -L -o /tmp/butler.zip 'https://broth.itch.zone/butler/darwin-amd64/LATEST/archive/default' && unzip /tmp/butler.zip -d ~/bin/ && chmod +x ~/bin/butler"
    exit 1
fi

# Check login
if ! $BUTLER login --check 2>/dev/null; then
    echo "ERROR: Not logged in to itch.io"
    echo "Run: butler login"
    echo "(This opens a browser for one-time authentication)"
    exit 1
fi

# Check export directory exists
if [ ! -d "$EXPORT_DIR" ]; then
    echo "ERROR: Export directory not found at $EXPORT_DIR"
    echo ""
    echo "To create the web export, either:"
    echo "  1. Open Godot → Project → Export → Web (HTML5) → Export Project"
    echo "  2. Run: mkdir -p \"$EXPORT_DIR\" && /Applications/Godot.app/Contents/MacOS/Godot --headless --path \"$PROJECT_DIR/godot_project\" --export-release \"Web (HTML5)\" \"$EXPORT_DIR/index.html\""
    exit 1
fi

# Check index.html exists inside export directory
if [ ! -f "$EXPORT_DIR/index.html" ]; then
    echo "WARNING: index.html not found in $EXPORT_DIR"
    echo "The export directory exists but may be incomplete."
    echo ""
    read -p "Build Web export now? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Building Web export..."
        /Applications/Godot.app/Contents/MacOS/Godot --headless --path "$PROJECT_DIR/godot_project" --export-release "Web (HTML5)" "$EXPORT_DIR/index.html"
    else
        echo "Aborting. Export the project first, then re-run this script."
        exit 1
    fi
fi

echo "Export directory: $EXPORT_DIR"
echo "Files: $(ls "$EXPORT_DIR" | wc -l)"
du -sh "$EXPORT_DIR"

# Upload directly (butler handles compression)
echo ""
echo "Uploading to itch.io ($ITCH_TARGET)..."
$BUTLER push "$EXPORT_DIR" "$ITCH_TARGET" --userversion "$VERSION"

echo ""
echo "=== Upload Complete ==="
echo "View at: https://taichi040911.itch.io/petclaw"
$BUTLER status taichi040911/petclaw
