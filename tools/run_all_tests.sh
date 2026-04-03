#!/usr/bin/env bash
## run_all_tests.sh — PetClaw headless test runner
## Runs all test_*.gd files in godot_project/tests/ and prints a summary.
## Usage: ./tools/run_all_tests.sh
## Exit code: 0 if all tests pass, 1 if any fail.

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# Resolve paths
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../godot_project" && pwd)"

# Find godot binary
GODOT="${GODOT_BIN:-godot}"
if ! command -v "$GODOT" &>/dev/null; then
    echo -e "${RED}Error: godot not found in PATH. Set GODOT_BIN to override.${RESET}"
    exit 2
fi

# Collect test files (sorted for stable ordering)
TEST_FILES=()
while IFS= read -r f; do
    TEST_FILES+=("$f")
done < <(find "$PROJECT_DIR/tests" -maxdepth 1 -name 'test_*.gd' -type f | sort)

if [[ ${#TEST_FILES[@]} -eq 0 ]]; then
    echo -e "${RED}No test files found in $PROJECT_DIR/tests/${RESET}"
    exit 2
fi

# Counters
total_files=0
passed_files=0
failed_files=0
errored_files=0
total_pass=0
total_fail=0

# Track failed test names
declare -a failed_names=()

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║   PetClaw Test Runner (Shell)            ║${RESET}"
echo -e "${BOLD}║   ${#TEST_FILES[@]} test files found                    ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${RESET}"
echo ""

for test_file in "${TEST_FILES[@]}"; do
    test_name="$(basename "$test_file")"
    total_files=$((total_files + 1))

    echo -e "${CYAN}── Running: ${test_name} ──${RESET}"

    # Run test, capture output and exit code
    set +e
    output=$("$GODOT" --headless --path "$PROJECT_DIR" --script "tests/$test_name" 2>&1)
    exit_code=$?
    set -e

    # Count PASS/FAIL lines in output
    file_pass=$(echo "$output" | grep -c -i 'PASS' || true)
    file_fail=$(echo "$output" | grep -c -i 'FAIL' || true)

    total_pass=$((total_pass + file_pass))
    total_fail=$((total_fail + file_fail))

    # Print test output (indented)
    while IFS= read -r line; do
        if echo "$line" | grep -qi 'FAIL'; then
            echo -e "   ${RED}${line}${RESET}"
        elif echo "$line" | grep -qi 'PASS'; then
            echo -e "   ${GREEN}${line}${RESET}"
        else
            echo "   $line"
        fi
    done <<< "$output"

    # Determine file-level result
    if [[ $exit_code -ne 0 ]]; then
        if [[ $file_fail -gt 0 ]]; then
            echo -e "   ${RED}=> FAILED (exit code $exit_code, $file_pass passed, $file_fail failed)${RESET}"
            failed_files=$((failed_files + 1))
            failed_names+=("$test_name")
        else
            echo -e "   ${RED}=> ERROR (exit code $exit_code, possibly crashed)${RESET}"
            errored_files=$((errored_files + 1))
            failed_names+=("$test_name [ERROR]")
        fi
    else
        echo -e "   ${GREEN}=> OK ($file_pass passed)${RESET}"
        passed_files=$((passed_files + 1))
    fi

    echo ""
done

# Summary
echo -e "${BOLD}╔══════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║               SUMMARY                    ║${RESET}"
echo -e "${BOLD}╠══════════════════════════════════════════╣${RESET}"
echo -e "${BOLD}║  Files run:    ${total_files}                           ${RESET}"
echo -e "${BOLD}║  ${GREEN}Files OK:    ${passed_files}${RESET}${BOLD}                           ${RESET}"

if [[ $failed_files -gt 0 ]]; then
    echo -e "${BOLD}║  ${RED}Files FAIL:  ${failed_files}${RESET}${BOLD}                           ${RESET}"
fi
if [[ $errored_files -gt 0 ]]; then
    echo -e "${BOLD}║  ${RED}Files ERROR: ${errored_files}${RESET}${BOLD}                           ${RESET}"
fi

echo -e "${BOLD}╠══════════════════════════════════════════╣${RESET}"
echo -e "${BOLD}║  ${GREEN}Total PASS:  ${total_pass}${RESET}${BOLD}                           ${RESET}"
echo -e "${BOLD}║  ${RED}Total FAIL:  ${total_fail}${RESET}${BOLD}                           ${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${RESET}"

if [[ ${#failed_names[@]} -gt 0 ]]; then
    echo ""
    echo -e "${RED}Failed/errored tests:${RESET}"
    for name in "${failed_names[@]}"; do
        echo -e "  ${RED}- ${name}${RESET}"
    done
fi

echo ""
if [[ $failed_files -eq 0 && $errored_files -eq 0 ]]; then
    echo -e "${GREEN}${BOLD}All ${total_files} test files passed.${RESET}"
    exit 0
else
    echo -e "${RED}${BOLD}Some tests failed or errored.${RESET}"
    exit 1
fi
