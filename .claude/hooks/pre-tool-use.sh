#!/bin/bash
# PetClaw Pre-Tool-Use Hook
# Validates GDScript files before write operations
# Runs before Edit/Write tools on .gd files

FILE_PATH="$1"
OPERATION="$2"  # "write" or "edit"

# Only check .gd files
if [[ ! "$FILE_PATH" == *.gd ]]; then
    exit 0
fi

# For write operations, check the content being written
if [[ "$OPERATION" == "write" ]]; then
    CONTENT="$3"
    
    # Check for class_name (required by PetClaw convention)
    if ! echo "$CONTENT" | grep -q "^class_name"; then
        echo "HOOK FAIL: GDScript file missing 'class_name' declaration (PetClaw convention)"
        echo "Add 'class_name YourClassName' near the top of the file"
        exit 1
    fi
    
    # Check for type annotations on func parameters  
    if echo "$CONTENT" | grep -qP "^func \w+\([^)]*\b\w+\s*[,)]" | grep -vP ":\s*\w+"; then
        echo "HOOK WARN: Some function parameters may be missing type annotations"
        # Don't block, just warn
    fi
fi

exit 0
