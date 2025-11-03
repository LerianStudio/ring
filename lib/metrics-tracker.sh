#!/usr/bin/env bash
#
# Metrics Tracker
# Tracks skill and agent usage, compliance, and effectiveness
#
# Usage: ./lib/metrics-tracker.sh <type> <name> [event-data]
#
# Examples:
#   ./lib/metrics-tracker.sh skill test-driven-development used
#   ./lib/metrics-tracker.sh skill test-driven-development violation "test_before_code"
#   ./lib/metrics-tracker.sh agent code-reviewer verdict "PASS"
#
# Exit codes:
#   0 - Success
#   2 - Invalid usage

set -euo pipefail

if [ $# -lt 3 ]; then
    echo "Usage: $0 <type> <name> <event> [data]"
    echo "Types: skill, agent"
    echo "Events: used, violation, verdict"
    exit 2
fi

TYPE="$1"      # skill or agent
NAME="$2"      # skill/agent name
EVENT="$3"     # used, violation, verdict
DATA="${4:-}"  # Additional data

METRICS_DIR="${METRICS_DIR:-.ring}"
METRICS_FILE="$METRICS_DIR/metrics.json"

# Create metrics directory if needed
mkdir -p "$METRICS_DIR"

# Initialize metrics file if doesn't exist
if [ ! -f "$METRICS_FILE" ]; then
    cat > "$METRICS_FILE" <<'EOF'
{
  "version": "1.0.0",
  "last_updated": "",
  "skills": {},
  "agents": {}
}
EOF
fi

# Update timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
jq --arg ts "$TIMESTAMP" '.last_updated = $ts' "$METRICS_FILE" > "$METRICS_FILE.tmp" && mv "$METRICS_FILE.tmp" "$METRICS_FILE"

# Track based on type and event
case "$TYPE:$EVENT" in
    skill:used)
        # Increment usage count
        jq --arg name "$NAME" --arg ts "$TIMESTAMP" \
            '.skills[$name].usage_count = (.skills[$name].usage_count // 0) + 1 |
             .skills[$name].last_used = $ts' \
            "$METRICS_FILE" > "$METRICS_FILE.tmp" && mv "$METRICS_FILE.tmp" "$METRICS_FILE"
        ;;

    skill:violation)
        # Record compliance violation
        jq --arg name "$NAME" --arg vid "$DATA" --arg ts "$TIMESTAMP" \
            '.skills[$name].violations[$vid].count = (.skills[$name].violations[$vid].count // 0) + 1 |
             .skills[$name].violations[$vid].last_occurred = $ts' \
            "$METRICS_FILE" > "$METRICS_FILE.tmp" && mv "$METRICS_FILE.tmp" "$METRICS_FILE"
        ;;

    agent:verdict)
        # Record agent verdict
        jq --arg name "$NAME" --arg verdict "$DATA" \
            '.agents[$name].invocations = (.agents[$name].invocations // 0) + 1 |
             .agents[$name].verdicts[$verdict] = (.agents[$name].verdicts[$verdict] // 0) + 1' \
            "$METRICS_FILE" > "$METRICS_FILE.tmp" && mv "$METRICS_FILE.tmp" "$METRICS_FILE"
        ;;

    *)
        echo "Unknown type:event combination: $TYPE:$EVENT"
        exit 2
        ;;
esac

echo "✓ Metrics updated: $TYPE/$NAME - $EVENT"
exit 0
