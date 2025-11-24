# Ring Infrastructure Library

Utility scripts for skills/agents orchestration, validation, and metrics.

## Components

- `compliance-validator.sh` - Validates skill adherence to compliance rules
- `output-validator.sh` - Validates agent output against schema
- `preflight-checker.sh` - Runs prerequisite checks before skills
- `skill-matcher.sh` - Maps tasks to relevant skills
- `skill-composer.sh` - Suggests next skill based on context
- `metrics-tracker.sh` - Tracks skill/agent usage and effectiveness

## Usage

All scripts are invoked by orchestrators, commands, or skills. Not intended for direct CLI use.

## Testing

See `testing/test-lib-*.md` for test cases.
