# Test Fixtures

These fixtures intentionally use various formats (including legacy `ring:` shorthand)
to test the adapter transformation logic for different AI platforms.

**Important:** Do NOT normalize these to production format. They exist to verify that
transformers correctly convert different input patterns to platform-specific formats.

## Fixture Files

- `skills/sample-skill/SKILL.md` - Tests skill transformation (uses ring: shorthand)
- `agents/sample-agent.md` - Tests agent transformation
- `commands/sample-command.md` - Tests command transformation

See `installer/ring_installer/adapters/` for transformation implementation.
