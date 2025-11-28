#!/usr/bin/env bash
# shellcheck disable=SC2034  # Unused variables OK for exported config
# Bisection script to find which test creates unwanted files/state
# Usage: ./find-polluter.sh <file_or_dir_to_check> <test_pattern>
# Example: ./find-polluter.sh '.git' 'src/**/*.test.ts'

set -euo pipefail

if [ $# -ne 2 ]; then
  echo "Usage: $0 <file_to_check> <test_pattern>"
  echo "Example: $0 '.git' 'src/**/*.test.ts'"
  exit 1
fi

POLLUTION_CHECK="$1"
TEST_PATTERN="$2"

echo "🔍 Searching for test that creates: $POLLUTION_CHECK"
echo "Test pattern: $TEST_PATTERN"
echo ""

# Get list of test files
# Extract filename pattern from glob (e.g., "src/**/*.test.ts" -> "*.test.ts")
# Note: -name only matches the filename, not full path. For complex path patterns,
# consider using: find . -type f -name "*.test.ts" | grep -E "src/.*"
FILENAME_PATTERN="${TEST_PATTERN##*/}"
TEST_FILES=$(find . -type f -name "$FILENAME_PATTERN" 2>/dev/null | sort)

if [ -z "$TEST_FILES" ]; then
  echo "No test files found matching pattern: $TEST_PATTERN"
  echo "Filename pattern extracted: $FILENAME_PATTERN"
  exit 1
fi

TOTAL=$(echo "$TEST_FILES" | wc -l | tr -d ' ')

echo "Found $TOTAL test files"
echo ""

COUNT=0
while IFS= read -r TEST_FILE; do
  COUNT=$((COUNT + 1))

  # Skip if pollution already exists
  if [ -e "$POLLUTION_CHECK" ]; then
    echo "⚠️  Pollution already exists before test $COUNT/$TOTAL"
    echo "   Skipping: $TEST_FILE"
    continue
  fi

  echo "[$COUNT/$TOTAL] Testing: $TEST_FILE"

  # Run test with 60-second timeout to prevent hanging on stuck tests
  # 60s allows slow integration tests to complete while catching infinite loops
  # On macOS without coreutils, install timeout via: brew install coreutils
  if command -v timeout &>/dev/null; then
      timeout 60 npm test "$TEST_FILE" > /dev/null 2>&1 || true
  else
      # Fallback: run without timeout (may hang on stuck tests)
      npm test "$TEST_FILE" > /dev/null 2>&1 || true
  fi

  # Check if pollution appeared
  if [ -e "$POLLUTION_CHECK" ]; then
    echo ""
    echo "🎯 FOUND POLLUTER!"
    echo "   Test: $TEST_FILE"
    echo "   Created: $POLLUTION_CHECK"
    echo ""
    echo "Pollution details:"
    ls -la "$POLLUTION_CHECK"
    echo ""
    echo "To investigate:"
    echo "  npm test $TEST_FILE    # Run just this test"
    echo "  cat $TEST_FILE         # Review test code"
    exit 1
  fi
done <<< "$TEST_FILES"

echo ""
echo "✅ No polluter found - all tests clean!"
exit 0
