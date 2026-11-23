#!/usr/bin/env bash
set -euo pipefail

: "${CONNECTIQ_KEY:?Set CONNECTIQ_KEY to your developer key path}"
mkdir -p build
monkeyc -t -d fr255 -f monkey.jungle -o build/drum-workout-tests.prg -y "$CONNECTIQ_KEY"
output=$(mktemp)
trap 'rm -f "$output"' EXIT
set +e
monkeydo build/drum-workout-tests.prg fr255 -t 2>&1 | tee "$output"
status=${PIPESTATUS[0]}
set -e

# SDK 9.3's runner can return 1 even when every test passed.
if (( status > 1 )) || ! grep -Eq '^PASSED \(passed=[1-9][0-9]*, failed=0, errors=0\)$' "$output"; then
    exit 1
fi
