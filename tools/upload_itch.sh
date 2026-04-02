#!/bin/bash
# PetClaw — itch.io upload script
# Usage: ./tools/upload_itch.sh [version]
# First time: run "butler login" in terminal first!
set -e

VERSION="${1:-1.0.0}"
BUTLER=~/bin/butler
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
EXPORT_DIR="$PROJECT_DIR/exports/web"
GODOT_PROJECT="$PROJECT_DIR/godot_project"
ITCH_TARGET="taichi040911/petclaw:html5"
ITCH_URL="https://taichi040911.itch.io/petclaw"

echo "=== PetClaw itch.io Upload v${VERSION} ==="
echo ""

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

# --- Pre-upload build verification ---

echo "--- Pre-Upload Verification ---"

# Check that Godot project exists
if [ ! -f "$GODOT_PROJECT/project.godot" ]; then
    echo "ERROR: project.godot not found at $GODOT_PROJECT"
    exit 1
fi
echo "[OK] project.godot found"

# Check export presets exist
if [ ! -f "$GODOT_PROJECT/export_presets.cfg" ]; then
    echo "ERROR: export_presets.cfg not found"
    echo "Open Godot and configure Web (HTML5) export preset first."
    exit 1
fi
echo "[OK] export_presets.cfg found"

# Check that Web export preset exists in config
if ! grep -q 'name="Web (HTML5)"' "$GODOT_PROJECT/export_presets.cfg"; then
    echo "ERROR: No 'Web (HTML5)' preset found in export_presets.cfg"
    echo "Open Godot → Project → Export → Add → Web (HTML5)"
    exit 1
fi
echo "[OK] Web (HTML5) export preset configured"

# Check export directory and index.html
if [ ! -d "$EXPORT_DIR" ] || [ ! -f "$EXPORT_DIR/index.html" ]; then
    echo ""
    echo "Web export not found at $EXPORT_DIR/index.html"
    echo ""
    read -p "Build Web export now? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Building Web export..."
        mkdir -p "$EXPORT_DIR"
        /Applications/Godot.app/Contents/MacOS/Godot --headless --path "$GODOT_PROJECT" --export-release "Web (HTML5)" "$EXPORT_DIR/index.html"
        echo ""
        if [ ! -f "$EXPORT_DIR/index.html" ]; then
            echo "ERROR: Build failed -- index.html was not created"
            exit 1
        fi
        echo "[OK] Web export built successfully"
    else
        echo "Aborting. Export the project first, then re-run this script."
        exit 1
    fi
else
    echo "[OK] index.html found in export directory"
fi

# Verify export contents
FILE_COUNT=$(ls "$EXPORT_DIR" | wc -l | tr -d ' ')
if [ "$FILE_COUNT" -lt 3 ]; then
    echo "WARNING: Export directory has only $FILE_COUNT file(s). Expected at least 3 (index.html, .js, .wasm)."
    echo "The export may be incomplete. Consider re-exporting."
    read -p "Continue anyway? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""
echo "--- Export Summary ---"
echo "Export directory: $EXPORT_DIR"
echo "Files: $FILE_COUNT"
du -sh "$EXPORT_DIR"

# Upload (butler handles compression)
echo ""
echo "Uploading to itch.io ($ITCH_TARGET)..."
$BUTLER push "$EXPORT_DIR" "$ITCH_TARGET" --userversion "$VERSION"

echo ""
echo "=== Upload Complete ==="
echo ""
echo "Page URL: $ITCH_URL"
echo "Edit URL: https://itch.io/dashboard/game/petclaw"
echo ""
$BUTLER status taichi040911/petclaw
