#!/usr/bin/env bash
# validate-gate-progression.sh
# PreToolUse hook for ring:dev-cycle — enforces gate ordering and completion
# evidence before allowing state file progression.
#
# Receives Claude Code PreToolUse JSON on stdin.
# Returns permissionDecision: "deny" if gate progression is invalid.
# Returns exit 0 (allow) if progression is valid or file is not a cycle state file.
#
# Note: Gate 9 (Validation) requires explicit user approval per SKILL.md
# and cannot be programmatically validated — intentionally omitted.
#
# Install: add to hooks.json under PreToolUse with matcher "Write"
# and if condition "Write(*current-cycle.json)"

set -euo pipefail

# Read the PreToolUse input from stdin
INPUT=$(cat)

# Extract the file path and content from tool_input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty')
CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // empty')

# Only validate current-cycle.json writes
if [[ "$FILE_PATH" != *"current-cycle.json" ]]; then
  exit 0
fi

# If no content, allow (might be a read or other operation)
if [[ -z "$CONTENT" ]]; then
  exit 0
fi

# Parse the new state being written
NEW_STATE="$CONTENT"

# Validate JSON
if ! echo "$NEW_STATE" | jq empty 2>/dev/null; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "Invalid JSON in current-cycle.json write"
    }
  }'
  exit 0
fi

# ─── Gate ordering map ───
# Maps gate index to the gate_progress field name and required evidence checks
# Gate order: 0 → 0.5 → 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9

# Extract current task being progressed
CURRENT_TASK_INDEX=$(echo "$NEW_STATE" | jq -r '.current_task_index // 0')
TARGET_GATE=$(echo "$NEW_STATE" | jq -r '.current_gate // 0')

# Get the task's gate_progress
TASK_GATES=$(echo "$NEW_STATE" | jq -c ".tasks[$CURRENT_TASK_INDEX].gate_progress // empty")

if [[ -z "$TASK_GATES" ]]; then
  exit 0  # No gate_progress yet, allow initial writes
fi

TASK_ID=$(echo "$NEW_STATE" | jq -r ".tasks[$CURRENT_TASK_INDEX].id // \"T-???\"")

# ─── Validation functions ───

errors=()

validate_gate_0() {
  local tdd_red tdd_green
  tdd_red=$(echo "$TASK_GATES" | jq -r '.implementation.tdd_red.status // "pending"')
  tdd_green=$(echo "$TASK_GATES" | jq -r '.implementation.tdd_green.status // "pending"')

  if [[ "$tdd_red" != "completed" ]]; then
    errors+=("Gate 0: TDD-RED not completed (status: $tdd_red)")
  fi
  if [[ "$tdd_green" != "completed" ]]; then
    errors+=("Gate 0: TDD-GREEN not completed (status: $tdd_green)")
  fi
}

validate_gate_05() {
  local status total delivered
  status=$(echo "$TASK_GATES" | jq -r '.delivery_verification.status // "pending"')
  total=$(echo "$TASK_GATES" | jq -r '.delivery_verification.requirements_total // 0')
  delivered=$(echo "$TASK_GATES" | jq -r '.delivery_verification.requirements_delivered // 0')

  if [[ "$status" != "completed" ]]; then
    errors+=("Gate 0.5: Delivery verification not completed (status: $status)")
  elif [[ "$total" -gt 0 && "$delivered" -lt "$total" ]]; then
    errors+=("Gate 0.5: Requirements gap — delivered $delivered/$total")
  fi
}

validate_gate_1() {
  local status
  status=$(echo "$TASK_GATES" | jq -r '.devops.status // "pending"')
  if [[ "$status" != "completed" ]]; then
    errors+=("Gate 1 (DevOps): not completed (status: $status)")
  fi
}

validate_gate_2() {
  local status
  status=$(echo "$TASK_GATES" | jq -r '.sre.status // "pending"')
  if [[ "$status" != "completed" ]]; then
    errors+=("Gate 2 (SRE): not completed (status: $status)")
  fi
}

validate_gate_3() {
  local status coverage
  status=$(echo "$TASK_GATES" | jq -r '.unit_testing.status // "pending"')
  coverage=$(echo "$TASK_GATES" | jq -r '
    .unit_testing.coverage_actual //
    (if .unit_testing.status == "completed" then 85 else 0 end)
  ')

  # Ensure coverage is numeric (guards against null/malformed values)
  if ! [[ "$coverage" =~ ^[0-9]+\.?[0-9]*$ ]]; then
    errors+=("Gate 3 (Unit Testing): invalid coverage value: $coverage")
    return
  fi

  if [[ "$status" != "completed" ]]; then
    errors+=("Gate 3 (Unit Testing): not completed (status: $status)")
  else
    # Compare coverage using awk for float comparison
    if awk "BEGIN {exit !($coverage < 85)}"; then
      errors+=("Gate 3 (Unit Testing): coverage $coverage% < 85% threshold")
    fi
  fi
}

validate_gate_4() {
  local status corpus
  status=$(echo "$TASK_GATES" | jq -r '.fuzz_testing.status // "pending"')
  corpus=$(echo "$TASK_GATES" | jq -r '.fuzz_testing.corpus_entries // 0')

  if [[ "$status" != "completed" ]]; then
    errors+=("Gate 4 (Fuzz Testing): not completed (status: $status)")
  elif [[ "$corpus" -lt 5 ]]; then
    errors+=("Gate 4 (Fuzz Testing): corpus_entries=$corpus < 5 minimum")
  fi
}

validate_gate_5() {
  local status props
  status=$(echo "$TASK_GATES" | jq -r '.property_testing.status // "pending"')
  props=$(echo "$TASK_GATES" | jq -r '.property_testing.properties_tested // 0')

  if [[ "$status" != "completed" ]]; then
    errors+=("Gate 5 (Property Testing): not completed (status: $status)")
  elif [[ "$props" -lt 1 ]]; then
    errors+=("Gate 5 (Property Testing): properties_tested=$props < 1 minimum")
  fi
}

validate_gate_6() {
  local status
  status=$(echo "$TASK_GATES" | jq -r '.integration_testing.status // "pending"')
  if [[ "$status" != "completed" ]]; then
    errors+=("Gate 6 (Integration Testing): not completed (status: $status)")
  fi
}

validate_gate_7() {
  local status
  status=$(echo "$TASK_GATES" | jq -r '.chaos_testing.status // "pending"')
  if [[ "$status" != "completed" ]]; then
    errors+=("Gate 7 (Chaos Testing): not completed (status: $status)")
  fi
}

validate_gate_8() {
  local status
  status=$(echo "$TASK_GATES" | jq -r '.review.status // "pending"')
  if [[ "$status" != "completed" ]]; then
    errors+=("Gate 8 (Review): not completed (status: $status)")
  fi

  # Check all 8 reviewers have verdicts
  local reviewers=("code_reviewer" "business_logic_reviewer" "security_reviewer"
                   "nil_safety_reviewer" "test_reviewer" "consequences_reviewer"
                   "dead_code_reviewer" "performance_reviewer")

  local reviewer_count=0
  for reviewer in "${reviewers[@]}"; do
    local verdict
    verdict=$(echo "$TASK_GATES" | jq -r ".review.$reviewer.verdict // empty")
    if [[ -n "$verdict" ]]; then
      ((reviewer_count++))
    fi
  done

  if [[ "$reviewer_count" -lt 8 && "$status" == "completed" ]]; then
    errors+=("Gate 8 (Review): only $reviewer_count/8 reviewers have verdicts — all 8 required")
  fi
}

# ─── Gate numeric mapping ───
# Convert current_gate to a comparable number (0.5 → 05 for ordering)
gate_to_num() {
  local g="$1"
  case "$g" in
    0)   echo 0 ;;
    0.5) echo 1 ;;
    1)   echo 2 ;;
    2)   echo 3 ;;
    3)   echo 4 ;;
    4)   echo 5 ;;
    5)   echo 6 ;;
    6)   echo 7 ;;
    7)   echo 8 ;;
    8)   echo 9 ;;
    9)   echo 10 ;;
    *)   echo -1 ;;
  esac
}

TARGET_NUM=$(gate_to_num "$TARGET_GATE")

# Reject unrecognized gate values
if [[ "$TARGET_NUM" -eq -1 ]]; then
  jq -n --arg gate "$TARGET_GATE" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: ("Invalid gate value: " + $gate + ". Expected: 0, 0.5, 1-9.")
    }
  }'
  exit 0
fi

# ─── Read existing state to detect regression (allowed) vs progression ───
# Normalize FILE_PATH to absolute (tool_input may provide relative paths)
if [[ "$FILE_PATH" != /* ]]; then
  FILE_PATH="${PWD}/${FILE_PATH}"
fi

# If the state file exists, check if this is a regression (going back) — always allow
if [[ -f "$FILE_PATH" ]]; then
  EXISTING_GATE=$(jq -r '.current_gate // 0' "$FILE_PATH" 2>/dev/null || echo "0")
  EXISTING_NUM=$(gate_to_num "$EXISTING_GATE")

  if [[ "$TARGET_NUM" -le "$EXISTING_NUM" ]]; then
    # Regression or same gate — always allowed (e.g., going back to fix)
    exit 0
  fi
fi

# ─── Progressive validation ───
# Validate all gates that should be completed before TARGET_GATE

if [[ "$TARGET_NUM" -ge 1 ]]; then
  validate_gate_0
fi

if [[ "$TARGET_NUM" -ge 2 ]]; then
  validate_gate_05
fi

if [[ "$TARGET_NUM" -ge 3 ]]; then
  validate_gate_1
fi

if [[ "$TARGET_NUM" -ge 4 ]]; then
  validate_gate_2
fi

if [[ "$TARGET_NUM" -ge 5 ]]; then
  validate_gate_3
fi

if [[ "$TARGET_NUM" -ge 6 ]]; then
  validate_gate_4
fi

if [[ "$TARGET_NUM" -ge 7 ]]; then
  validate_gate_5
fi

if [[ "$TARGET_NUM" -ge 8 ]]; then
  validate_gate_6
fi

if [[ "$TARGET_NUM" -ge 9 ]]; then
  validate_gate_7
fi

if [[ "$TARGET_NUM" -ge 10 ]]; then
  validate_gate_8
fi

# Note: Gate 9 (Validation) is user approval — cannot be automated

# ─── Decision ───

if [[ ${#errors[@]} -gt 0 ]]; then
  # Build error list as JSON array
  ERROR_JSON_ARRAY=$(printf '%s\n' "${errors[@]}" | jq -R . | jq -sc .)

  # Build recovery instructions based on which gates failed
  recovery_steps=()
  for err in "${errors[@]}"; do
    case "$err" in
      *"Gate 0:"*)   recovery_steps+=("Gate 0: Load Skill(ring:dev-implementation), dispatch backend-engineer agent with TDD cycle") ;;
      *"Gate 0.5:"*) recovery_steps+=("Gate 0.5: Load Skill(ring:dev-delivery-verification), verify all requirements delivered") ;;
      *"Gate 1"*)    recovery_steps+=("Gate 1: Load Skill(ring:dev-devops), dispatch ring:devops-engineer") ;;
      *"Gate 2"*)    recovery_steps+=("Gate 2: Load Skill(ring:dev-sre), dispatch ring:sre") ;;
      *"Gate 3"*)    recovery_steps+=("Gate 3: Load Skill(ring:dev-unit-testing), dispatch ring:qa-analyst (test_mode=unit, coverage >= 85%)") ;;
      *"Gate 4"*)    recovery_steps+=("Gate 4: Load Skill(ring:dev-fuzz-testing), dispatch ring:qa-analyst (test_mode=fuzz, corpus >= 5)") ;;
      *"Gate 5"*)    recovery_steps+=("Gate 5: Load Skill(ring:dev-property-testing), dispatch ring:qa-analyst (test_mode=property)") ;;
      *"Gate 6"*)    recovery_steps+=("Gate 6: Load Skill(ring:dev-integration-testing), dispatch ring:qa-analyst (test_mode=integration, write only)") ;;
      *"Gate 7"*)    recovery_steps+=("Gate 7: Load Skill(ring:dev-chaos-testing), dispatch ring:qa-analyst (test_mode=chaos, write only)") ;;
      *"Gate 8"*)    recovery_steps+=("Gate 8: Load Skill(ring:codereview), dispatch ALL 8 reviewers in parallel") ;;
    esac
  done

  # Deduplicate recovery steps
  RECOVERY_JSON_ARRAY=$(printf '%s\n' "${recovery_steps[@]}" | sort -u | jq -R . | jq -sc .)

  # Extract task context for recovery instructions
  TASK_TITLE=$(echo "$NEW_STATE" | jq -r ".tasks[$CURRENT_TASK_INDEX].title // empty")
  TASK_FILE=$(echo "$NEW_STATE" | jq -r ".tasks[$CURRENT_TASK_INDEX].subtasks[0].file // .source_file // empty")
  LAST_COMPLETED_GATE=$(echo "$TASK_GATES" | jq -r '[
    if .implementation.tdd_green.status == "completed" then "0" else empty end,
    if .delivery_verification.status == "completed" then "0.5" else empty end,
    if .devops.status == "completed" then "1" else empty end,
    if .sre.status == "completed" then "2" else empty end,
    if .unit_testing.status == "completed" then "3" else empty end,
    if .fuzz_testing.status == "completed" then "4" else empty end,
    if .property_testing.status == "completed" then "5" else empty end,
    if .integration_testing.status == "completed" then "6" else empty end,
    if .chaos_testing.status == "completed" then "7" else empty end,
    if .review.status == "completed" then "8" else empty end
  ] | last // "none"')

  jq -n \
    --arg task "$TASK_ID" \
    --arg title "$TASK_TITLE" \
    --arg gate "$TARGET_GATE" \
    --arg lastGate "$LAST_COMPLETED_GATE" \
    --argjson errs "$ERROR_JSON_ARRAY" \
    --argjson recovery "$RECOVERY_JSON_ARRAY" \
    '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: (
          "GATE PROGRESSION BLOCKED for " + $task +
          (if $title != "" then " (" + $title + ")" else "" end) +
          " — target: Gate " + $gate + ", last completed: Gate " + $lastGate + ". " +
          "Issues: " + ($errs | join("; ")) + ". " +
          "RECOVERY for " + $task + " — Resume from Gate " + $lastGate + ", execute in order: " +
          ($recovery | join("; "))
        )
      }
    }'
  exit 0
fi

# All validations passed — allow the write
exit 0
