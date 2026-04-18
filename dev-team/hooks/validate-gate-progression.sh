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
# Gate order: 0 → 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9
# Note: Delivery Verification is an inline exit check for Gate 0, tracked per-subtask
# at state.tasks[i].subtasks[j].gate_progress.implementation.delivery_verified
# and validated by validate_delivery_verification() alongside Gate 0.

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

# Gate 0 — TDD RED/GREEN completion check.
# Iterates subtasks[] because tdd_red/tdd_green are subtask-cadence gates per state
# schema (see dev-cycle/SKILL.md state schema declaration, lines 693–757). Task-only
# fallback preserved for cycles without subtask decomposition.
#
# A subtask is exempt from this check if its current_gate < 1 (hasn't reached Gate 0
# yet — don't require TDD complete for future subtasks).
validate_gate_0() {
  local subtask_count i subtask_id current_gate tdd_red tdd_green

  subtask_count=$(echo "$NEW_STATE" | jq -r ".tasks[$CURRENT_TASK_INDEX].subtasks | length // 0")

  if [[ "$subtask_count" -eq 0 ]]; then
    # Task-only fallback (no subtask decomposition) — read from task scope
    tdd_red=$(echo "$TASK_GATES" | jq -r '.implementation.tdd_red.status // "pending"')
    tdd_green=$(echo "$TASK_GATES" | jq -r '.implementation.tdd_green.status // "pending"')

    # Frontend-cycle safety: empty implementation on an empty task → no-op
    if [[ "$tdd_red" == "pending" && "$tdd_green" == "pending" ]]; then
      local impl_present
      impl_present=$(echo "$TASK_GATES" | jq -r 'has("implementation")')
      if [[ "$impl_present" != "true" ]]; then
        return
      fi
    fi

    if [[ "$tdd_red" != "completed" ]]; then
      errors+=("Gate 0: TDD-RED not completed (status: $tdd_red)")
    fi
    if [[ "$tdd_green" != "completed" ]]; then
      errors+=("Gate 0: TDD-GREEN not completed (status: $tdd_green)")
    fi
    return
  fi

  # Subtask-scoped validation
  local any_impl_present=false
  for ((i=0; i<subtask_count; i++)); do
    subtask_id=$(echo "$NEW_STATE" | jq -r ".tasks[$CURRENT_TASK_INDEX].subtasks[$i].id // \"S-???\"")
    current_gate=$(echo "$NEW_STATE" | jq -r ".tasks[$CURRENT_TASK_INDEX].subtasks[$i].current_gate // 0")
    tdd_red=$(echo "$NEW_STATE" | jq -r ".tasks[$CURRENT_TASK_INDEX].subtasks[$i].gate_progress.implementation.tdd_red.status // \"pending\"")
    tdd_green=$(echo "$NEW_STATE" | jq -r ".tasks[$CURRENT_TASK_INDEX].subtasks[$i].gate_progress.implementation.tdd_green.status // \"pending\"")

    local impl_present
    impl_present=$(echo "$NEW_STATE" | jq -r ".tasks[$CURRENT_TASK_INDEX].subtasks[$i].gate_progress | has(\"implementation\")")
    if [[ "$impl_present" == "true" ]]; then
      any_impl_present=true
    fi

    # Exempt subtasks that haven't reached Gate 0 yet
    if ! [[ "$current_gate" =~ ^[0-9]+$ ]] || [[ "$current_gate" -lt 1 ]]; then
      continue
    fi

    if [[ "$tdd_red" != "completed" ]]; then
      errors+=("Gate 0 (Subtask $subtask_id): TDD-RED not completed (status: $tdd_red)")
    fi
    if [[ "$tdd_green" != "completed" ]]; then
      errors+=("Gate 0 (Subtask $subtask_id): TDD-GREEN not completed (status: $tdd_green)")
    fi
  done

  # Frontend-cycle safety: if no subtask has implementation scope at all, short-circuit
  if [[ "$any_impl_present" == "false" ]]; then
    # Clear any errors emitted for subtasks past Gate 0 with absent implementation
    # (shouldn't happen in practice since current_gate < 1 exempts them, but be explicit)
    return
  fi
}

# Delivery Verification — Gate 0 exit criterion. Iterates subtasks of the current
# task and verifies each past-Gate-0 subtask has implementation.delivery_verified == true.
validate_delivery_verification() {
  local subtask_count i subtask_id current_gate delivery_verified

  subtask_count=$(echo "$NEW_STATE" | jq -r ".tasks[$CURRENT_TASK_INDEX].subtasks | length // 0")

  if [[ "$subtask_count" -eq 0 ]]; then
    # No subtasks defined — nothing to verify at subtask level
    return
  fi

  for ((i=0; i<subtask_count; i++)); do
    subtask_id=$(echo "$NEW_STATE" | jq -r ".tasks[$CURRENT_TASK_INDEX].subtasks[$i].id // \"S-???\"")
    current_gate=$(echo "$NEW_STATE" | jq -r ".tasks[$CURRENT_TASK_INDEX].subtasks[$i].current_gate // 0")
    delivery_verified=$(echo "$NEW_STATE" | jq -r ".tasks[$CURRENT_TASK_INDEX].subtasks[$i].gate_progress.implementation.delivery_verified // false")

    # Only flag subtasks that are PAST Gate 0 (i.e., have progressed beyond implementation)
    # If current_gate is non-numeric or "0", skip; otherwise require delivery_verified == true
    if [[ "$current_gate" =~ ^[0-9]+$ ]] && [[ "$current_gate" -ge 1 ]]; then
      if [[ "$delivery_verified" != "true" ]]; then
        errors+=("Gate 0 exit criteria: subtask $subtask_id has not passed delivery verification (implementation.delivery_verified != true)")
      fi
    fi
  done
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

# Gate 3 — Unit testing completion and coverage check.
# Iterates subtasks[] because unit_testing is a subtask-cadence gate per state schema
# (see dev-cycle/SKILL.md state schema declaration, lines 693–757). Task-only fallback
# preserved for cycles without subtask decomposition.
#
# A subtask is exempt from this check if its current_gate < 4 (hasn't reached Gate 3 yet).
validate_gate_3() {
  local subtask_count i subtask_id current_gate status coverage

  subtask_count=$(echo "$NEW_STATE" | jq -r ".tasks[$CURRENT_TASK_INDEX].subtasks | length // 0")

  if [[ "$subtask_count" -eq 0 ]]; then
    # Task-only fallback
    status=$(echo "$TASK_GATES" | jq -r '.unit_testing.status // "pending"')
    coverage=$(echo "$TASK_GATES" | jq -r '
      .unit_testing.coverage_actual //
      (if .unit_testing.status == "completed" then 85 else 0 end)
    ')

    # Frontend-cycle safety: no unit_testing scope at all → no-op
    local ut_present
    ut_present=$(echo "$TASK_GATES" | jq -r 'has("unit_testing")')
    if [[ "$ut_present" != "true" && "$status" == "pending" ]]; then
      return
    fi

    if ! [[ "$coverage" =~ ^[0-9]+\.?[0-9]*$ ]]; then
      errors+=("Gate 3 (Unit Testing): invalid coverage value: $coverage")
      return
    fi

    if [[ "$status" != "completed" ]]; then
      errors+=("Gate 3 (Unit Testing): not completed (status: $status)")
    else
      if awk "BEGIN {exit !($coverage < 85)}"; then
        errors+=("Gate 3 (Unit Testing): coverage $coverage% < 85% threshold")
      fi
    fi
    return
  fi

  # Subtask-scoped validation
  local any_ut_present=false
  for ((i=0; i<subtask_count; i++)); do
    subtask_id=$(echo "$NEW_STATE" | jq -r ".tasks[$CURRENT_TASK_INDEX].subtasks[$i].id // \"S-???\"")
    current_gate=$(echo "$NEW_STATE" | jq -r ".tasks[$CURRENT_TASK_INDEX].subtasks[$i].current_gate // 0")
    status=$(echo "$NEW_STATE" | jq -r ".tasks[$CURRENT_TASK_INDEX].subtasks[$i].gate_progress.unit_testing.status // \"pending\"")
    coverage=$(echo "$NEW_STATE" | jq -r "
      .tasks[$CURRENT_TASK_INDEX].subtasks[$i].gate_progress.unit_testing.coverage_actual //
      (if .tasks[$CURRENT_TASK_INDEX].subtasks[$i].gate_progress.unit_testing.status == \"completed\" then 85 else 0 end)
    ")

    local ut_present
    ut_present=$(echo "$NEW_STATE" | jq -r ".tasks[$CURRENT_TASK_INDEX].subtasks[$i].gate_progress | has(\"unit_testing\")")
    if [[ "$ut_present" == "true" ]]; then
      any_ut_present=true
    fi

    # Exempt subtasks that haven't reached Gate 3 yet
    if ! [[ "$current_gate" =~ ^[0-9]+$ ]] || [[ "$current_gate" -lt 4 ]]; then
      continue
    fi

    if ! [[ "$coverage" =~ ^[0-9]+\.?[0-9]*$ ]]; then
      errors+=("Gate 3 (Subtask $subtask_id): invalid coverage value: $coverage")
      continue
    fi

    if [[ "$status" != "completed" ]]; then
      errors+=("Gate 3 (Subtask $subtask_id): not completed (status: $status)")
    else
      if awk "BEGIN {exit !($coverage < 85)}"; then
        errors+=("Gate 3 (Subtask $subtask_id): coverage $coverage below threshold 85")
      fi
    fi
  done

  # Frontend-cycle safety: if no subtask has unit_testing scope at all, short-circuit
  if [[ "$any_ut_present" == "false" ]]; then
    return
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
# Convert current_gate to a comparable number.
# Delivery verification is a Gate 0 exit criterion checked inline.
gate_to_num() {
  local g="$1"
  case "$g" in
    0) echo 0 ;;
    1) echo 1 ;;
    2) echo 2 ;;
    3) echo 3 ;;
    4) echo 4 ;;
    5) echo 5 ;;
    6) echo 6 ;;
    7) echo 7 ;;
    8) echo 8 ;;
    9) echo 9 ;;
    *) echo -1 ;;
  esac
}

TARGET_NUM=$(gate_to_num "$TARGET_GATE")

# Reject unrecognized gate values
if [[ "$TARGET_NUM" -eq -1 ]]; then
  jq -n --arg gate "$TARGET_GATE" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: ("Invalid gate value: " + $gate + ". Expected: 0-9.")
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

# Gate 0 completion (TDD RED/GREEN) AND its inline delivery verification exit
# criterion are both required before progressing to Gate 1.
if [[ "$TARGET_NUM" -ge 1 ]]; then
  validate_gate_0
  validate_delivery_verification
fi

if [[ "$TARGET_NUM" -ge 2 ]]; then
  validate_gate_1
fi

if [[ "$TARGET_NUM" -ge 3 ]]; then
  validate_gate_2
fi

if [[ "$TARGET_NUM" -ge 4 ]]; then
  validate_gate_3
fi

if [[ "$TARGET_NUM" -ge 5 ]]; then
  validate_gate_4
fi

if [[ "$TARGET_NUM" -ge 6 ]]; then
  validate_gate_5
fi

if [[ "$TARGET_NUM" -ge 7 ]]; then
  validate_gate_6
fi

if [[ "$TARGET_NUM" -ge 8 ]]; then
  validate_gate_7
fi

if [[ "$TARGET_NUM" -ge 9 ]]; then
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
      *"Gate 0 exit criteria:"*) recovery_steps+=("Gate 0 exit criteria: Re-dispatch ring:dev-implementation for the affected subtask; it runs delivery verification inline at Step 7 (Delivery Verification Exit Check). Do NOT dispatch ring:dev-delivery-verification — deprecated.") ;;
      *"Gate 0:"*)              recovery_steps+=("Gate 0: Load Skill(ring:dev-implementation), dispatch backend-engineer agent with TDD cycle") ;;
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

  # Deduplicate recovery steps (preserve gate order — sort -u would reorder)
  RECOVERY_JSON_ARRAY=$(printf '%s\n' "${recovery_steps[@]}" | awk '!seen[$0]++' | jq -R . | jq -sc .)

  # Extract task context for recovery instructions
  TASK_TITLE=$(echo "$NEW_STATE" | jq -r ".tasks[$CURRENT_TASK_INDEX].title // empty")
  # Derive last contiguously valid gate using the SAME predicates as the validators
  # (not just status == completed — also checks evidence thresholds)
  # Delivery verification is tracked per-subtask at
  # tasks[i].subtasks[j].gate_progress.implementation.delivery_verified and
  # enforced as a Gate 0 exit criterion (see validate_delivery_verification).
  # Determine if any past-Gate-0 subtask lacks delivery verification.
  DELIVERY_VERIFIED_ALL=$(echo "$NEW_STATE" | jq -r --argjson ti "$CURRENT_TASK_INDEX" '
    (.tasks[$ti].subtasks // [])
    | map(select((.current_gate // 0) >= 1))
    | if length == 0 then "true"
      else (map(.gate_progress.implementation.delivery_verified // false) | all) | tostring
      end
  ')

  # Aggregate subtask-cadence gates (TDD, unit_testing) across subtasks[].
  # A task has "completed Gate N" (for subtask-cadence N) when ALL its subtasks past
  # that gate satisfy the predicate. Subtasks with current_gate < N are exempt.
  # Falls back to task-scope if no subtasks exist.
  TDD_COMPLETED_ALL=$(echo "$NEW_STATE" | jq -r --argjson ti "$CURRENT_TASK_INDEX" '
    (.tasks[$ti].subtasks // []) as $subs
    | if ($subs | length) == 0 then
        ((.tasks[$ti].gate_progress.implementation.tdd_red.status == "completed") and
         (.tasks[$ti].gate_progress.implementation.tdd_green.status == "completed")) | tostring
      else
        ($subs
         | map(select((.current_gate // 0) >= 1))
         | if length == 0 then "true"
           else (map(
             (.gate_progress.implementation.tdd_red.status == "completed") and
             (.gate_progress.implementation.tdd_green.status == "completed")
           ) | all) | tostring
           end)
      end
  ')

  UNIT_TESTING_COMPLETED_ALL=$(echo "$NEW_STATE" | jq -r --argjson ti "$CURRENT_TASK_INDEX" '
    (.tasks[$ti].subtasks // []) as $subs
    | if ($subs | length) == 0 then
        ((.tasks[$ti].gate_progress.unit_testing.status == "completed") and
         ((.tasks[$ti].gate_progress.unit_testing.coverage_actual // 0) >= 85)) | tostring
      else
        ($subs
         | map(select((.current_gate // 0) >= 4))
         | if length == 0 then "true"
           else (map(
             (.gate_progress.unit_testing.status == "completed") and
             ((.gate_progress.unit_testing.coverage_actual // 0) >= 85)
           ) | all) | tostring
           end)
      end
  ')

  LAST_COMPLETED_GATE=$(echo "$TASK_GATES" | jq -r \
    --arg dv "$DELIVERY_VERIFIED_ALL" \
    --arg tdd "$TDD_COMPLETED_ALL" \
    --arg ut "$UNIT_TESTING_COMPLETED_ALL" '
    if $tdd != "true" then "none"
    elif $dv != "true" then "0"
    elif .devops.status != "completed" then "0"
    elif .sre.status != "completed" then "1"
    elif $ut != "true" then "2"
    elif .fuzz_testing.status != "completed" then "3"
    elif (.fuzz_testing.corpus_entries // 0) < 5 then "3"
    elif .property_testing.status != "completed" then "4"
    elif (.property_testing.properties_tested // 0) < 1 then "4"
    elif .integration_testing.status != "completed" then "5"
    elif .chaos_testing.status != "completed" then "6"
    elif .review.status != "completed" then "7"
    else "8"
    end
  ')

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
