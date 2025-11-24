# CLAUDE.md Auto-Bootstrap Hook

## Purpose

Automatically generates `CLAUDE.md` documentation for git repositories that lack them. This hook runs on SessionStart (before session-start.sh) to ensure repositories have proper Claude Code guidance documentation.

## How It Works

### Trigger Conditions

The bootstrap process runs when ALL conditions are met:
1. **SessionStart event** with `startup` or `resume` matcher
2. **Git repository** detected (`.git/` directory exists)
3. **No CLAUDE.md** file in project root

If any condition is false, the hook exits silently without action.

### Generation Process

**Phase 1: Layer Discovery (~15-20s)**
- Analyzes repository structure to identify architectural layers
- Discovers API, business logic, data, frontend, infrastructure layers
- Identifies cross-cutting concerns (auth, logging, config, testing)
- Falls back to monolithic structure if discovery fails

**Phase 2: Parallel Layer Analysis (~20-30s)**
- Dispatches parallel analysis for each discovered layer
- Examines key files, patterns, technologies in each layer
- Aggregates findings for synthesis phase
- Continues with partial results if some analyses timeout

**Phase 3: Content Synthesis (~10-15s)**
- Combines all findings into structured CLAUDE.md
- Generates repository overview, architecture breakdown
- Includes common commands, workflows, patterns
- Enforces 500-line maximum for token efficiency

**Phase 4: Validation & Write (~1s)**
- Validates generated content structure
- Enforces line limit (truncates if needed)
- Writes CLAUDE.md to project root
- Falls back to minimal template on error

**Total time:** ~45-65 seconds typical, 90 seconds maximum

### Generated Content Structure

```markdown
# CLAUDE.md

## Repository Overview
[2-3 sentences about the repository]

## Architecture
### Core Components
- Layer descriptions with directories
- Key files and patterns
- Technologies used

### Cross-Cutting Concerns
- Authentication, logging, config locations

## Common Commands
- Git operations
- Build/test/deploy commands
- Package manager commands

## Key Workflows
- How to work in this repository
- Adding new features
- Testing procedures

## Important Patterns
- Code organization
- Naming conventions
- Anti-patterns to avoid
```

### Integration with Other Hooks

**Execution Order:**
1. `claude-md-bootstrap.sh` - Generates CLAUDE.md if missing
2. `session-start.sh` - Loads skills and generated CLAUDE.md
3. Session begins with full context available

The bootstrap runs **before** session-start.sh to ensure the generated CLAUDE.md is immediately available for context injection.

## Configuration

### File Locations

- **Bootstrap script:** `hooks/claude-md-bootstrap.sh`
- **Python orchestrator:** `hooks/claude-md-bootstrap.py`
- **Hook configuration:** `hooks/hooks.json`
- **Generated file:** `${CLAUDE_PROJECT_DIR}/CLAUDE.md`

### Environment Variables

- `CLAUDE_PROJECT_DIR`: Project directory path (defaults to current directory)
- `CLAUDE_PLUGIN_ROOT`: Plugin installation directory (auto-detected)
- `CLAUDE_SESSION_ID`: Session identifier for isolation

### Customization

To customize the generation process, modify `hooks/claude-md-bootstrap.py`:

```python
# Adjust maximum lines (default 500)
MAX_LINES = 500

# Adjust timeout for layer analysis (default 120 seconds)
MAX_LAYER_ANALYSIS_TIME = 120

# Modify layer discovery patterns
patterns = {
    'Your Layer': ['your/', 'directories/'],
    # Add more patterns...
}
```

## Error Handling

### Graceful Degradation

The bootstrap implements multiple fallback strategies:

1. **Layer discovery fails** → Uses monolithic structure
2. **Layer analysis timeouts** → Continues with partial results
3. **Synthesis fails** → Creates minimal template
4. **Write permission denied** → Logs error, continues session

### Fallback Template

If generation fails completely, a minimal template is created:

```markdown
# CLAUDE.md

[Auto-generated - bootstrap process encountered errors]

## Architecture
[Analysis incomplete - delete this file to trigger regeneration]

## Common Commands
- git status
- git log --oneline -10

## Notes
Delete this file to trigger regeneration on next session.
```

### Error Recovery

To retry generation after a failure:
1. Delete the existing CLAUDE.md: `rm CLAUDE.md`
2. Start a new Claude Code session
3. Bootstrap will automatically retry

## Performance Characteristics

### Typical Metrics

- **Small repos (<100 files):** ~30-45 seconds
- **Medium repos (100-1000 files):** ~45-60 seconds
- **Large repos (>1000 files):** ~60-90 seconds
- **Monorepos:** May reach 90-second timeout

### Resource Usage

- **CPU:** Moderate (parallel analysis phases)
- **Memory:** ~50-100MB Python process
- **Disk I/O:** Read-only repository analysis
- **Network:** None (fully local operation)

### Optimization

The bootstrap is optimized for:
- **Token efficiency:** 500-line maximum output
- **Parallel execution:** Layer analyses run concurrently
- **Fast failure:** Early exit for non-applicable contexts
- **Partial results:** Continues despite individual failures

## Troubleshooting

### Bootstrap Doesn't Run

Check prerequisites:
```bash
# Verify git repository
ls -la .git/

# Check CLAUDE.md doesn't exist
ls -la CLAUDE.md

# Test hook directly
CLAUDE_PROJECT_DIR=$(pwd) ./hooks/claude-md-bootstrap.sh
```

### Generation Fails

Check error output:
```bash
# Run with verbose output
CLAUDE_PROJECT_DIR=$(pwd) python3 hooks/claude-md-bootstrap.py

# Check Python version
python3 --version  # Requires 3.8+

# Verify write permissions
touch CLAUDE.md && rm CLAUDE.md
```

### Content Quality Issues

If generated content is poor:
1. Ensure repository has clear structure
2. Add README.md with project description
3. Organize code into logical directories
4. Consider manual editing after generation

### Manual Regeneration

To force regeneration:
```bash
# Remove existing file
rm CLAUDE.md

# Run bootstrap manually
CLAUDE_PROJECT_DIR=$(pwd) ./hooks/claude-md-bootstrap.sh
```

## Limitations

### Current Limitations

1. **Agent integration pending:** Currently uses static analysis instead of AI agent delegation
2. **Language detection basic:** Relies on file extensions and common patterns
3. **No incremental updates:** Full regeneration only (no updates)
4. **Single file output:** Doesn't generate modular documentation
5. **English only:** No multi-language support

### Future Enhancements

Planned improvements:
- Full agent integration for intelligent analysis
- Incremental updates based on git changes
- Template library for common frameworks
- Multi-file documentation support
- Language detection via GitHub Linguist

## Examples

### Example: Node.js Application

For a typical Node.js project:
```
project/
├── src/
│   ├── api/
│   ├── services/
│   └── models/
├── tests/
├── config/
└── package.json
```

Generates:
- Identifies API, Business Logic, Data layers
- Includes npm commands
- Documents test structure
- ~300-400 lines typical

### Example: Python Monorepo

For a Python monorepo:
```
project/
├── services/
│   ├── api/
│   └── worker/
├── packages/
│   └── shared/
├── tests/
└── pyproject.toml
```

Generates:
- Identifies multiple service layers
- Includes pip/poetry commands
- Documents service boundaries
- ~400-500 lines typical

### Example: Simple Script Repository

For a simple scripts repository:
```
project/
├── scripts/
├── README.md
└── .git/
```

Generates:
- Single monolithic layer
- Basic git commands
- Minimal workflows section
- ~150-200 lines typical

## Integration with CI/CD

While primarily for interactive sessions, the bootstrap can be used in CI:

```bash
# CI validation that CLAUDE.md can be generated
./hooks/claude-md-bootstrap.sh
test -f CLAUDE.md || exit 1
```

This ensures all repositories maintain generatable documentation.

## Support

For issues or questions:
1. Check this documentation
2. Review error messages carefully
3. Try manual regeneration
4. Consider manual editing for specific needs

Remember: The auto-generated CLAUDE.md is a starting point. Manual refinement is encouraged for optimal results.
