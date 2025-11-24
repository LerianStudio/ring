#!/usr/bin/env bash
#
# Metrics Tracker
# Tracks skill and agent usage, compliance, and effectiveness
#
# Usage: ./lib/metrics-tracker.sh <type> <name> <event> [data] [event-id]
#
# Examples:
#   ./lib/metrics-tracker.sh skill test-driven-development used "" "evt-123"
#   ./lib/metrics-tracker.sh skill test-driven-development violation "test_before_code" "evt-456"
#   ./lib/metrics-tracker.sh agent code-reviewer verdict "PASS" "evt-789"
#
# Exit codes:
#   0 - Success (including duplicate events)
#   2 - Invalid usage

set -euo pipefail

if [ $# -lt 3 ]; then
    echo "Usage: $0 <type> <name> <event> [data] [event-id]"
    echo "Types: skill, agent"
    echo "Events: used, violation, verdict"
    echo "Event-id: Optional unique identifier for idempotency"
    exit 2
fi

TYPE="$1"      # skill or agent
NAME="$2"      # skill/agent name
EVENT="$3"     # used, violation, verdict
DATA="${4:-}"  # Additional data
EVENT_ID="${5:-}"  # Optional event ID for deduplication

# Input validation
validate_inputs() {
    # Validate TYPE
    case "$TYPE" in
        skill|agent)
            ;;
        *)
            echo "Error: Invalid type '$TYPE' (must be 'skill' or 'agent')"
            exit 2
            ;;
    esac

    # Validate NAME format (alphanumeric, hyphens, underscores)
    if ! echo "$NAME" | grep -qE '^[a-zA-Z0-9_-]+$'; then
        echo "Error: Invalid name format (use alphanumeric, hyphens, underscores)"
        exit 2
    fi

    # Validate EVENT
    case "$EVENT" in
        used|violation|verdict)
            ;;
        *)
            echo "Error: Invalid event '$EVENT' (must be 'used', 'violation', or 'verdict')"
            exit 2
            ;;
    esac

    # Validate DATA if provided
    if [ -n "$DATA" ]; then
        local data_len=${#DATA}
        if [ "$data_len" -gt 200 ]; then
            echo "Error: Event data too long (max 200 chars)"
            exit 2
        fi
    fi

    # Validate EVENT_ID if provided
    if [ -n "$EVENT_ID" ]; then
        if ! echo "$EVENT_ID" | grep -qE '^[a-zA-Z0-9_-]+$'; then
            echo "Error: Invalid event-id format (use alphanumeric, hyphens, underscores)"
            exit 2
        fi
        local id_len=${#EVENT_ID}
        if [ "$id_len" -gt 100 ]; then
            echo "Error: Event-id too long (max 100 chars)"
            exit 2
        fi
    fi
}

validate_inputs

METRICS_DIR="${METRICS_DIR:-.ring}"
METRICS_FILE="$METRICS_DIR/metrics.json"
LOCK_FILE="$METRICS_DIR/metrics.lock"

# Check for required dependencies
if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required for metrics tracking"
    echo "Install with: brew install jq (macOS) or apt-get install jq (Linux)"
    exit 2
fi

# Create metrics directory if needed
mkdir -p "$METRICS_DIR"

# Acquire lock with timeout (wait up to 5 seconds)
acquire_lock() {
    local max_wait=50  # 50 * 0.1 = 5 seconds
    local count=0

    while [ $count -lt $max_wait ]; do
        if mkdir "$LOCK_FILE" 2>/dev/null; then
            # Got the lock
            trap "rm -rf \"$LOCK_FILE\"" EXIT INT TERM
            return 0
        fi
        sleep 0.1
        count=$((count + 1))
    done

    echo "Error: Could not acquire lock after 5 seconds"
    exit 2
}

# Acquire lock before proceeding
acquire_lock

# Initialize metrics file if doesn't exist
if [ ! -f "$METRICS_FILE" ]; then
    cat > "$METRICS_FILE" <<'EOF'
{
  "version": "1.0.0",
  "last_updated": "",
  "skills": {},
  "agents": {},
  "event_ids": {}
}
EOF
fi

# Check for duplicate event-id (idempotency)
if [ -n "$EVENT_ID" ]; then
    if jq -e --arg eid "$EVENT_ID" '.event_ids[$eid] != null' "$METRICS_FILE" >/dev/null 2>&1; then
        echo "✓ Metrics already recorded for event-id: $EVENT_ID (idempotent)"
        exit 0
    fi
fi

# Update timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Track based on type and event
# Use separate temp file and verify updates succeeded
TEMP_FILE="$METRICS_FILE.tmp.$$"

case "$TYPE:$EVENT" in
    skill:used)
        # Increment usage count and record event_id if provided
        if [ -n "$EVENT_ID" ]; then
            if ! jq --arg name "$NAME" --arg ts "$TIMESTAMP" --arg eid "$EVENT_ID" \
                '.skills[$name].usage_count = (.skills[$name].usage_count // 0) + 1 |
                 .skills[$name].last_used = $ts |
                 .event_ids[$eid] = $ts' \
                "$METRICS_FILE" > "$TEMP_FILE"; then
                echo "Error: Failed to update metrics (jq failed)"
                rm -f "$TEMP_FILE"
                exit 2
            fi
        else
            if ! jq --arg name "$NAME" --arg ts "$TIMESTAMP" \
                '.skills[$name].usage_count = (.skills[$name].usage_count // 0) + 1 |
                 .skills[$name].last_used = $ts' \
                "$METRICS_FILE" > "$TEMP_FILE"; then
                echo "Error: Failed to update metrics (jq failed)"
                rm -f "$TEMP_FILE"
                exit 2
            fi
        fi
        ;;

    skill:violation)
        # Record compliance violation and event_id if provided
        if [ -n "$EVENT_ID" ]; then
            if ! jq --arg name "$NAME" --arg vid "$DATA" --arg ts "$TIMESTAMP" --arg eid "$EVENT_ID" \
                '.skills[$name].violations[$vid].count = (.skills[$name].violations[$vid].count // 0) + 1 |
                 .skills[$name].violations[$vid].last_occurred = $ts |
                 .event_ids[$eid] = $ts' \
                "$METRICS_FILE" > "$TEMP_FILE"; then
                echo "Error: Failed to update metrics (jq failed)"
                rm -f "$TEMP_FILE"
                exit 2
            fi
        else
            if ! jq --arg name "$NAME" --arg vid "$DATA" --arg ts "$TIMESTAMP" \
                '.skills[$name].violations[$vid].count = (.skills[$name].violations[$vid].count // 0) + 1 |
                 .skills[$name].violations[$vid].last_occurred = $ts' \
                "$METRICS_FILE" > "$TEMP_FILE"; then
                echo "Error: Failed to update metrics (jq failed)"
                rm -f "$TEMP_FILE"
                exit 2
            fi
        fi
        ;;

    agent:verdict)
        # Record agent verdict and event_id if provided
        if [ -n "$EVENT_ID" ]; then
            if ! jq --arg name "$NAME" --arg verdict "$DATA" --arg ts "$TIMESTAMP" --arg eid "$EVENT_ID" \
                '.agents[$name].invocations = (.agents[$name].invocations // 0) + 1 |
                 .agents[$name].verdicts[$verdict] = (.agents[$name].verdicts[$verdict] // 0) + 1 |
                 .event_ids[$eid] = $ts' \
                "$METRICS_FILE" > "$TEMP_FILE"; then
                echo "Error: Failed to update metrics (jq failed)"
                rm -f "$TEMP_FILE"
                exit 2
            fi
        else
            if ! jq --arg name "$NAME" --arg verdict "$DATA" \
                '.agents[$name].invocations = (.agents[$name].invocations // 0) + 1 |
                 .agents[$name].verdicts[$verdict] = (.agents[$name].verdicts[$verdict] // 0) + 1' \
                "$METRICS_FILE" > "$TEMP_FILE"; then
                echo "Error: Failed to update metrics (jq failed)"
                rm -f "$TEMP_FILE"
                exit 2
            fi
        fi
        ;;

    *)
        echo "Error: Unknown type:event combination: $TYPE:$EVENT"
        rm -f "$TEMP_FILE"
        exit 2
        ;;
esac

# Verify temp file has valid JSON before replacing
if ! jq empty "$TEMP_FILE" 2>/dev/null; then
    echo "Error: Generated invalid JSON, not updating metrics"
    rm -f "$TEMP_FILE"
    exit 2
fi

# Atomically replace metrics file
if ! mv "$TEMP_FILE" "$METRICS_FILE"; then
    echo "Error: Failed to update metrics file"
    rm -f "$TEMP_FILE"
    exit 2
fi

echo "✓ Metrics updated: $TYPE/$NAME - $EVENT"
exit 0
