#!/usr/bin/env bash
# validate-gate-progression.sh
# PreToolUse hook for the lean backend ring:running-dev-cycle.
# Phased rolling-wave model (state v2.0.0): epics[] iterate, tasks[] are the Gate 0 unit.
# Active backend gates:
#   Gate 0: implementation-owned TDD, coverage, local runtime, delivery verification (per task T-X.Y.Z)
#   Gate 8: epic-level review (per epic E-X.Y)
#   Gate 9: user validation (not programmatically checked)
# Also guards: an epic in an un-elaborated phase MUST NOT enter Gate 0.

set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty')
CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // empty')

deny() {
  local reason="$1"
  jq -n --arg reason "$reason" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}

if [[ "$FILE_PATH" != *"current-cycle.json" ]]; then
  exit 0
fi

if [[ -z "$CONTENT" ]]; then
  deny "Empty content is not allowed for current-cycle.json"
fi

if ! echo "$CONTENT" | jq empty 2>/dev/null; then
  deny "Invalid JSON in current-cycle.json write"
fi

STATE="$CONTENT"
CURRENT_EPIC_INDEX=$(echo "$STATE" | jq -r '.current_epic_index // 0')
TARGET_GATE=$(echo "$STATE" | jq -r '.current_gate // 0')
EPIC_COUNT=$(echo "$STATE" | jq -r '(.epics // []) | length')

if ! [[ "$CURRENT_EPIC_INDEX" =~ ^[0-9]+$ ]]; then
  deny "Invalid current_epic_index: $CURRENT_EPIC_INDEX"
fi

if [[ "$CURRENT_EPIC_INDEX" -ge "$EPIC_COUNT" ]]; then
  deny "current_epic_index out of range: $CURRENT_EPIC_INDEX (epics: $EPIC_COUNT)"
fi

EPIC_GATES=$(echo "$STATE" | jq -c ".epics[$CURRENT_EPIC_INDEX].gate_progress // {}")

errors=()

gate_to_num() {
  case "$1" in
    0) echo 0 ;;
    8) echo 8 ;;
    9) echo 9 ;;
    *) echo -1 ;;
  esac
}

validate_gate_0_for_task() {
  local idx="$1"
  local task_id tdd_red tdd_green delivery coverage threshold runtime_verified

  task_id=$(echo "$STATE" | jq -r ".epics[$CURRENT_EPIC_INDEX].tasks[$idx].id // \"T-???\"")

  tdd_red=$(echo "$STATE" | jq -r ".epics[$CURRENT_EPIC_INDEX].tasks[$idx].gate_progress.implementation.tdd_red.status // \"pending\"")
  tdd_green=$(echo "$STATE" | jq -r ".epics[$CURRENT_EPIC_INDEX].tasks[$idx].gate_progress.implementation.tdd_green.status // \"pending\"")
  delivery=$(echo "$STATE" | jq -r ".epics[$CURRENT_EPIC_INDEX].tasks[$idx].gate_progress.implementation.delivery_verified // false")
  coverage=$(echo "$STATE" | jq -r ".epics[$CURRENT_EPIC_INDEX].tasks[$idx].gate_progress.implementation.coverage_actual // 0")
  threshold=$(echo "$STATE" | jq -r ".epics[$CURRENT_EPIC_INDEX].tasks[$idx].gate_progress.implementation.coverage_threshold // 85")
  runtime_verified=$(echo "$STATE" | jq -r ".epics[$CURRENT_EPIC_INDEX].tasks[$idx].gate_progress.implementation.local_runtime_verified // false")

  [[ "$tdd_red" == "completed" ]] || errors+=("Gate 0 ($task_id): TDD-RED not completed")
  [[ "$tdd_green" == "completed" ]] || errors+=("Gate 0 ($task_id): TDD-GREEN not completed")
  [[ "$delivery" == "true" ]] || errors+=("Gate 0 ($task_id): delivery verification missing")

  if ! [[ "$coverage" =~ ^[0-9]+\.?[0-9]*$ ]] || ! [[ "$threshold" =~ ^[0-9]+\.?[0-9]*$ ]]; then
    errors+=("Gate 0 ($task_id): invalid coverage data")
  elif awk "BEGIN {exit !($coverage < $threshold)}"; then
    errors+=("Gate 0 ($task_id): coverage $coverage% < threshold $threshold%")
  fi

  if [[ "$runtime_verified" != "true" ]]; then
    errors+=("Gate 0 ($task_id): local runtime verification missing or explicitly false")
  fi
}

# Phase guard: an epic whose phase is not detailed/in_progress is not elaborated
# and MUST NOT enter Gate 0 (its tasks[] is empty until its phase boundary runs).
validate_phase_elaborated() {
  local epic_phase phase_status
  epic_phase=$(echo "$STATE" | jq -r ".epics[$CURRENT_EPIC_INDEX].phase // empty")
  # No phase field (legacy/flat fallback without phases[]) → skip guard.
  if [[ -z "$epic_phase" ]]; then
    return
  fi
  phase_status=$(echo "$STATE" | jq -r "(.phases // []) | map(select(.phase == ($epic_phase | tonumber))) | .[0].status // empty")
  # No phases[] entry to look up → skip guard (don't block on missing metadata).
  if [[ -z "$phase_status" ]]; then
    return
  fi
  if [[ "$phase_status" != "detailed" && "$phase_status" != "in_progress" ]]; then
    errors+=("Gate 0: phase not elaborated (epic phase $epic_phase has status '$phase_status'; expected 'detailed' or 'in_progress')")
  fi
}

validate_gate_0() {
  local task_count
  task_count=$(echo "$STATE" | jq -r ".epics[$CURRENT_EPIC_INDEX].tasks | length // 0")

  validate_phase_elaborated

  if [[ "$task_count" -eq 0 ]]; then
    local tdd_red tdd_green delivery coverage threshold runtime_verified
    tdd_red=$(echo "$EPIC_GATES" | jq -r '.implementation.tdd_red.status // "pending"')
    tdd_green=$(echo "$EPIC_GATES" | jq -r '.implementation.tdd_green.status // "pending"')
    delivery=$(echo "$EPIC_GATES" | jq -r '.implementation.delivery_verified // false')
    coverage=$(echo "$EPIC_GATES" | jq -r '.implementation.coverage_actual // 0')
    threshold=$(echo "$EPIC_GATES" | jq -r '.implementation.coverage_threshold // 85')
    runtime_verified=$(echo "$EPIC_GATES" | jq -r '.implementation.local_runtime_verified // false')

    [[ "$tdd_red" == "completed" ]] || errors+=("Gate 0: TDD-RED not completed")
    [[ "$tdd_green" == "completed" ]] || errors+=("Gate 0: TDD-GREEN not completed")
    [[ "$delivery" == "true" ]] || errors+=("Gate 0: delivery verification missing")
    if ! [[ "$coverage" =~ ^[0-9]+\.?[0-9]*$ ]] || ! [[ "$threshold" =~ ^[0-9]+\.?[0-9]*$ ]]; then
      errors+=("Gate 0: invalid coverage data")
    elif awk "BEGIN {exit !($coverage < $threshold)}"; then
      errors+=("Gate 0: coverage $coverage% < threshold $threshold%")
    fi
    [[ "$runtime_verified" == "true" ]] || errors+=("Gate 0: local runtime verification missing or explicitly false")
    return
  fi

  for ((i=0; i<task_count; i++)); do
    validate_gate_0_for_task "$i"
  done
}

validate_gate_8() {
  local status default_failures optional_failures
  status=$(echo "$EPIC_GATES" | jq -r '.review.status // "pending"')
  [[ "$status" == "completed" ]] || errors+=("Gate 8 (Review): not completed")

  default_failures=$(echo "$STATE" | jq -r --argjson idx "$CURRENT_EPIC_INDEX" '
    [
      {name: "code_reviewer", verdict: .epics[$idx].agent_outputs.review.code_reviewer.verdict},
      {name: "logic_reviewer", verdict: .epics[$idx].agent_outputs.review.logic_reviewer.verdict},
      {name: "security_reviewer", verdict: .epics[$idx].agent_outputs.review.security_reviewer.verdict},
      {name: "nil_reviewer", verdict: .epics[$idx].agent_outputs.review.nil_reviewer.verdict},
      {name: "test_reviewer", verdict: .epics[$idx].agent_outputs.review.test_reviewer.verdict},
      {name: "dead_code_reviewer", verdict: .epics[$idx].agent_outputs.review.dead_code_reviewer.verdict},
      {name: "perf_reviewer", verdict: .epics[$idx].agent_outputs.review.perf_reviewer.verdict},
      {name: "tenancy_reviewer", verdict: .epics[$idx].agent_outputs.review.tenancy_reviewer.verdict},
      {name: "commons_reviewer", verdict: .epics[$idx].agent_outputs.review.commons_reviewer.verdict}
    ]
    | map(select(.verdict != "PASS"))
    | map(.name + "=" + (.verdict // "missing"))
    | join(", ")
  ')

  optional_failures=$(echo "$STATE" | jq -r --argjson idx "$CURRENT_EPIC_INDEX" '
    [
      {name: "obs_reviewer", verdict: .epics[$idx].agent_outputs.review.obs_reviewer.verdict},
      {name: "systemplane_reviewer", verdict: .epics[$idx].agent_outputs.review.systemplane_reviewer.verdict},
      {name: "streaming_reviewer", verdict: .epics[$idx].agent_outputs.review.streaming_reviewer.verdict}
    ]
    | map(select(.verdict != null and .verdict != "PASS"))
    | map(.name + "=" + .verdict)
    | join(", ")
  ')

  if [[ "$status" == "completed" && -n "$default_failures" ]]; then
    errors+=("Gate 8 (Review): expected 9 default PASS verdicts; failures: $default_failures")
  fi

  if [[ "$status" == "completed" && -n "$optional_failures" ]]; then
    errors+=("Gate 8 (Review): triggered conditional specialist reviewers must PASS; failures: $optional_failures")
  fi
}

TARGET_NUM=$(gate_to_num "$TARGET_GATE")
if [[ "$TARGET_NUM" -eq -1 ]]; then
  jq -n --arg gate "$TARGET_GATE" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: ("Invalid backend dev-cycle gate value: " + $gate + ". Expected active gates: 0, 8, 9.")
    }
  }'
  exit 0
fi

if [[ "$TARGET_NUM" -ge 8 ]]; then
  validate_gate_0
fi

if [[ "$TARGET_NUM" -ge 9 ]]; then
  validate_gate_8
fi

if [[ ${#errors[@]} -gt 0 ]]; then
  ERROR_JSON_ARRAY=$(printf '%s\n' "${errors[@]}" | jq -R . | jq -sc .)
  jq -n --argjson errors "$ERROR_JSON_ARRAY" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: ("Lean backend dev-cycle progression blocked:\n" + ($errors | map("- " + .) | join("\n")) + "\n\nRecovery: complete Gate 0 (per task T-X.Y.Z) via ring:implementing-tasks for every task of the current epic, then run Gate 8 (per epic) via ring:reviewing-code before Gate 9 validation. On a phase-not-elaborated error: run the phase boundary (Step 11.5, gates/phase-boundary.md) to elaborate the epic phase before entering Gate 0.")
    }
  }'
  exit 0
fi

exit 0
