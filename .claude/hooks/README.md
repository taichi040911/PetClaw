# PetClaw Hook System

## Overview
This directory contains hook scripts that validate GDScript files and maintain code quality standards for PetClaw's Agent Teams workflow.

## Hooks

### pre-tool-use.sh
Runs BEFORE any file write/edit operation on `.gd` files.

**Validations:**
- Ensures `class_name` declaration exists (PetClaw convention)
- Warns about missing type annotations on function parameters

**Exit codes:**
- `0`: Validation passed, proceed
- `1`: Validation failed, block operation

### post-tool-use.sh
Runs AFTER any file write/edit operation on `.gd` files.

**Validations:**
- Cross-references `GameManager.instance.*` properties
- Verifies signal emissions have matching declarations
- Logs all checks to `hook_log.txt`

**Exit codes:**
- `0`: Always (informational only)

## Hook Log
All post-hook activity is logged to `hook_log.txt` with timestamps for debugging and audit trails.

## Usage
Hooks are automatically invoked by Agent Teams when tools interact with GDScript files. They enforce PetClaw's coding conventions without requiring manual intervention.
