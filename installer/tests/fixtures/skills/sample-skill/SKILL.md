<!--
NOTE: This fixture intentionally uses ambiguous ring: shorthand to test the adapter
transformation logic. DO NOT change to ring-default: format.
See installer/ring_installer/adapters/factory.py for transformation tests.
-->
---
name: sample-skill
description: |
  A sample skill for testing the Ring multi-platform installer.
  This skill demonstrates the full frontmatter structure.

trigger: |
  - When testing transformer functionality
  - When validating platform-specific conversions
  - When running integration tests

skip_when: |
  - Production deployments
  - When using mock data instead

sequence:
  after: [prerequisite-skill]
  before: [following-skill]

related:
  similar: [other-sample-skill]
  complementary: [helper-skill, utility-skill]
---

# Sample Skill

This is a sample skill used for testing the Ring installer.

## Purpose

This skill demonstrates:
- YAML frontmatter parsing
- Content body transformation
- Platform-specific terminology changes

## Usage

Use the `ring:sample-skill` skill when you need to:

1. Test the installation process
2. Validate transformer output
3. Check platform compatibility

## Technical Details

The skill uses the Task tool to dispatch subagents:

```python
# Example subagent dispatch
Task.dispatch("ring:helper-agent", prompt="Process data")
```

## References

- Related skill: `ring:related-skill`
- Agent reference: "ring:sample-agent"
