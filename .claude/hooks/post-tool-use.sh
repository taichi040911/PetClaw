#!/bin/bash
# PetClaw Post-Tool-Use Hook
# Runs after Edit/Write tools complete on .gd files
# Performs cross-reference validation

FILE_PATH="$1"
OPERATION="$2"
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LOG_FILE="$PROJECT_ROOT/.claude/hooks/hook_log.txt"

# Only check .gd files
if [[ ! "$FILE_PATH" == *.gd ]]; then
    exit 0
fi

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
echo "[$TIMESTAMP] Post-hook: $OPERATION on $FILE_PATH" >> "$LOG_FILE"

# Check GameManager.instance references
GM_REFS=$(grep -oP 'GameManager\.instance\.\K\w+' "$FILE_PATH" 2>/dev/null | sort -u)
GM_FILE="$PROJECT_ROOT/godot_project/scripts/core/game_manager.gd"

if [[ -n "$GM_REFS" && -f "$GM_FILE" ]]; then
    for ref in $GM_REFS; do
        if ! grep -q "var $ref" "$GM_FILE"; then
            echo "[$TIMESTAMP] WARN: $FILE_PATH references GameManager.instance.$ref but not found in game_manager.gd" >> "$LOG_FILE"
            echo "HOOK WARN: Reference to GameManager.instance.$ref — verify this property exists"
        fi
    done
fi

# Check signal emissions have matching declarations
EMITTED=$(grep -oP '(\w+)\.emit\(' "$FILE_PATH" 2>/dev/null | sed 's/\.emit(//' | sort -u)
for sig in $EMITTED; do
    if ! grep -q "signal $sig" "$FILE_PATH"; then
        echo "[$TIMESTAMP] INFO: $FILE_PATH emits '$sig' — declared externally" >> "$LOG_FILE"
    fi
done

echo "[$TIMESTAMP] Post-hook complete: $FILE_PATH" >> "$LOG_FILE"
exit 0
