#!/usr/bin/env bash
set -euo pipefail

# Ring → OpenCode Installer (Monorepo Edition)
#
# Installs Ring skills, agents, commands, and the OpenCode plugin
# from the Ring monorepo into ~/.config/opencode.
#
# Instead of maintaining separate assets/, this installer reads directly
# from the Ring monorepo's canonical directories (default/, dev-team/, etc.)
# and applies necessary transformations for OpenCode compatibility.
#
# Architecture:
# - Reads from Ring monorepo plugin dirs (default/, dev-team/, pm-team/, etc.)
# - Applies frontmatter transforms (type→mode, strip unsupported fields)
# - Normalizes tool names (Bash→bash, Read→read, etc.)
# - Installs the OpenCode plugin runtime (TypeScript)
# - Merges dependencies into package.json
#
# Behavior:
# - Copies (overwrites) only Ring-managed files
# - NEVER deletes unknown files in the target directory
# - Backs up overwritten files to ~/.config/opencode/.ring-backups/<timestamp>/

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RING_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TARGET_ROOT="${OPENCODE_CONFIG_DIR:-"$HOME/.config/opencode"}"

# Ring plugin directories (order matters for conflict resolution — last wins)
RING_PLUGINS=(default dev-team pm-team pmo-team tw-team finops-team)

# Validate TARGET_ROOT
if [[ -z "$TARGET_ROOT" || "$TARGET_ROOT" != /* ]]; then
  echo "ERROR: Cannot determine config directory. HOME is not set or TARGET_ROOT is not absolute." >&2
  exit 1
fi

# Colors
if [[ -t 1 ]] && command -v tput &>/dev/null; then
  GREEN=$(tput setaf 2); YELLOW=$(tput setaf 3); BLUE=$(tput setaf 4); RED=$(tput setaf 1); RESET=$(tput sgr0)
else
  GREEN="" YELLOW="" BLUE="" RED="" RESET=""
fi

echo "${BLUE}================================================${RESET}"
echo "${BLUE}Ring → OpenCode Installer (Monorepo)${RESET}"
echo "${BLUE}================================================${RESET}"
echo ""
echo "Ring root:  $RING_ROOT"
echo "Target:     $TARGET_ROOT"
echo ""

# Node version check
check_node_version() {
  if ! command -v node >/dev/null 2>&1; then
    echo "${YELLOW}WARN: Node.js not found. Will attempt to use bun.${RESET}" >&2
    return 0
  fi
  local node_version
  node_version=$(node -v | sed 's/^v//' | cut -d. -f1)
  if [[ "$node_version" -lt 18 ]]; then
    echo "${RED}ERROR: Node.js $node_version too old. Requires 18+.${RESET}" >&2
    exit 1
  fi
}
check_node_version

mkdir -p "$TARGET_ROOT"

STAMP="$(date -u +"%Y%m%dT%H%M%SZ")"
BACKUP_DIR="$TARGET_ROOT/.ring-backups/$STAMP"
mkdir -p "$BACKUP_DIR"

# ============================================================
# TRANSFORM FUNCTIONS
# ============================================================

# Transform agent frontmatter for OpenCode compatibility
# - type: reviewer/subagent → mode: subagent
# - Strip unsupported fields (version, changelog, last_updated, output_schema, input_schema)
# - Normalize tool names
transform_agent() {
  local input="$1"
  python3 -c "
import sys, re

content = open('$input', 'r').read()

# Split frontmatter and body
if content.startswith('---'):
    end = content.find('---', 3)
    if end != -1:
        fm = content[3:end].strip()
        body = content[end+3:].strip()
    else:
        fm = ''
        body = content
else:
    fm = ''
    body = content

# Parse frontmatter lines
fm_lines = fm.split('\n') if fm else []
new_fm = []
in_multiline = False
multiline_key = ''
skip_keys = {'version', 'changelog', 'last_updated', 'output_schema', 'input_schema',
             'type', 'project_rules_integration'}
keep_keys = {'name', 'description', 'mode', 'model', 'tools', 'color', 'hidden',
             'subtask', 'temperature', 'maxSteps', 'permission'}

has_mode = False
agent_type = None

for line in fm_lines:
    # Detect multiline values (indented continuation)
    if in_multiline:
        if line.startswith('  ') or line.startswith('\t') or line.strip().startswith('- '):
            # Skip multiline content of skipped keys
            if multiline_key in skip_keys:
                continue
            new_fm.append(line)
            continue
        else:
            in_multiline = False

    # Parse key
    colon = line.find(':')
    if colon == -1:
        new_fm.append(line)
        continue

    key = line[:colon].strip()
    value = line[colon+1:].strip()

    if key == 'type':
        agent_type = value.strip('\"').strip(\"'\")
        continue
    if key == 'mode':
        has_mode = True
    if key in skip_keys:
        # Check if multiline
        if value == '' or value == '|' or value == '>':
            in_multiline = True
            multiline_key = key
        continue
    if key in keep_keys:
        new_fm.append(line)
        # Check if multiline
        if value == '' or value == '|' or value == '>':
            in_multiline = True
            multiline_key = key
    # else: strip unknown keys

# Add mode from type if not already present
if not has_mode and agent_type:
    if agent_type in ('reviewer', 'subagent'):
        new_fm.append('mode: subagent')
    elif agent_type == 'primary':
        new_fm.append('mode: primary')
    else:
        new_fm.append('mode: subagent')
elif not has_mode:
    new_fm.append('mode: subagent')

# Strip Model Requirement section from body
body = re.sub(r'## ⚠️ Model Requirement[^\n]*\n.*?\n---\n', '', body, flags=re.DOTALL)
body = re.sub(r'\n{3,}', '\n\n', body).strip()

# Normalize tool references in body
tool_map = {
    'Bash': 'bash', 'Read': 'read', 'Write': 'write', 'Edit': 'edit',
    'List': 'list', 'Glob': 'glob', 'Grep': 'grep', 'WebFetch': 'webfetch',
    'Task': 'task', 'TodoWrite': 'todowrite', 'TodoRead': 'todoread',
    'MultiEdit': 'edit', 'NotebookEdit': 'edit', 'BrowseURL': 'webfetch',
    'FetchURL': 'webfetch',
}
for claude_name, oc_name in tool_map.items():
    body = re.sub(rf'\b{claude_name}\b(?=\s+tool|\s+command)', oc_name, body, flags=re.IGNORECASE)

# Reconstruct
fm_str = '\n'.join(new_fm)
if fm_str.strip():
    print(f'---\n{fm_str}\n---\n\n{body}\n')
else:
    print(f'{body}\n')
"
}

# Transform skill frontmatter for OpenCode compatibility
# - Keep name, description (OpenCode loaders only read these)
# - The body (including trigger, skip_when as prose) is the actual skill content
transform_skill() {
  local input="$1"
  python3 -c "
import sys, re

content = open('$input', 'r').read()

if content.startswith('---'):
    end = content.find('---', 3)
    if end != -1:
        fm = content[3:end].strip()
        body = content[end+3:].strip()
    else:
        fm = ''
        body = content
else:
    fm = ''
    body = content

# Parse and filter frontmatter
fm_lines = fm.split('\n') if fm else []
new_fm = []
in_multiline = False
multiline_key = ''
# OpenCode skill loader only uses: name, description, agent, subtask
# We keep them all since extra fields are harmlessly ignored
# but we reorganize trigger/skip_when into description context
keep_keys = {'name', 'description'}

for line in fm_lines:
    if in_multiline:
        if line.startswith('  ') or line.startswith('\t') or line.strip().startswith('- '):
            if multiline_key in keep_keys:
                new_fm.append(line)
            continue
        else:
            in_multiline = False

    colon = line.find(':')
    if colon == -1:
        continue

    key = line[:colon].strip()
    value = line[colon+1:].strip()

    if key in keep_keys:
        new_fm.append(line)
        if value == '' or value == '|' or value == '>':
            in_multiline = True
            multiline_key = key

# Normalize tool references
tool_map = {
    'Bash': 'bash', 'Read': 'read', 'Write': 'write', 'Edit': 'edit',
    'List': 'list', 'Glob': 'glob', 'Grep': 'grep', 'WebFetch': 'webfetch',
    'Task': 'task', 'TodoWrite': 'todowrite', 'TodoRead': 'todoread',
}
for claude_name, oc_name in tool_map.items():
    body = re.sub(rf'\b{claude_name}\b(?=\s+tool|\s+command)', oc_name, body, flags=re.IGNORECASE)

fm_str = '\n'.join(new_fm)
if fm_str.strip():
    print(f'---\n{fm_str}\n---\n\n{body}\n')
else:
    print(f'{body}\n')
"
}

# Transform command frontmatter for OpenCode compatibility
# - Strip argument-hint (not supported)
# - Keep name, description, agent, subtask
transform_command() {
  local input="$1"
  python3 -c "
import sys, re

content = open('$input', 'r').read()

if content.startswith('---'):
    end = content.find('---', 3)
    if end != -1:
        fm = content[3:end].strip()
        body = content[end+3:].strip()
    else:
        fm = ''
        body = content
else:
    fm = ''
    body = content

fm_lines = fm.split('\n') if fm else []
new_fm = []
keep_keys = {'name', 'description', 'agent', 'subtask', 'model'}

for line in fm_lines:
    colon = line.find(':')
    if colon == -1:
        continue
    key = line[:colon].strip()
    if key in keep_keys:
        new_fm.append(line)

# Normalize tool references
tool_map = {
    'Bash': 'bash', 'Read': 'read', 'Write': 'write', 'Edit': 'edit',
    'List': 'list', 'Glob': 'glob', 'Grep': 'grep', 'WebFetch': 'webfetch',
    'Task': 'task', 'TodoWrite': 'todowrite', 'TodoRead': 'todoread',
}
for claude_name, oc_name in tool_map.items():
    body = re.sub(rf'\b{claude_name}\b(?=\s+tool|\s+command)', oc_name, body, flags=re.IGNORECASE)

# Replace mithril/codereview binary references with just mithril
body = re.sub(r'\\\$BINARY.*?run-all\"?\n?', 'mithril', body)

fm_str = '\n'.join(new_fm)
if fm_str.strip():
    print(f'---\n{fm_str}\n---\n\n{body}\n')
else:
    print(f'{body}\n')
"
}

# Expand {OPENCODE_CONFIG} placeholder
expand_placeholders() {
  local file="$1"
  local config_dir
  config_dir="${OPENCODE_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/opencode}"
  local escaped
  escaped=$(printf '%s\n' "$config_dir" | sed 's/[&/\|]/\\&/g')
  if sed --version >/dev/null 2>&1; then
    sed -i "s|{OPENCODE_CONFIG}|$escaped|g" "$file"
  else
    sed -i '' "s|{OPENCODE_CONFIG}|$escaped|g" "$file"
  fi
}

# ============================================================
# INSTALL AGENTS
# ============================================================
echo "${GREEN}Installing agents...${RESET}"
AGENT_TARGET="$TARGET_ROOT/agent"
mkdir -p "$AGENT_TARGET"

agent_count=0
for plugin in "${RING_PLUGINS[@]}"; do
  agent_dir="$RING_ROOT/$plugin/agents"
  [[ -d "$agent_dir" ]] || continue

  for agent_file in "$agent_dir"/*.md; do
    [[ -f "$agent_file" ]] || continue
    agent_name=$(basename "$agent_file")

    # Backup if exists
    if [[ -f "$AGENT_TARGET/$agent_name" ]]; then
      mkdir -p "$BACKUP_DIR/agent"
      cp "$AGENT_TARGET/$agent_name" "$BACKUP_DIR/agent/$agent_name"
    fi

    transform_agent "$agent_file" > "$AGENT_TARGET/$agent_name"
    ((agent_count++))
  done
done
echo "  Installed $agent_count agents"

# ============================================================
# INSTALL SKILLS
# ============================================================
echo "${GREEN}Installing skills...${RESET}"
SKILL_TARGET="$TARGET_ROOT/skill"
mkdir -p "$SKILL_TARGET"

skill_count=0
for plugin in "${RING_PLUGINS[@]}"; do
  skill_dir="$RING_ROOT/$plugin/skills"
  [[ -d "$skill_dir" ]] || continue

  for skill_path in "$skill_dir"/*/; do
    [[ -d "$skill_path" ]] || continue
    skill_name=$(basename "$skill_path")

    # Skip shared-patterns (they're referenced by skills, not loaded as skills)
    [[ "$skill_name" == "shared-patterns" ]] && continue

    skill_file="$skill_path/SKILL.md"
    [[ -f "$skill_file" ]] || continue

    target_skill_dir="$SKILL_TARGET/$skill_name"
    mkdir -p "$target_skill_dir"

    # Backup if exists
    if [[ -f "$target_skill_dir/SKILL.md" ]]; then
      mkdir -p "$BACKUP_DIR/skill/$skill_name"
      cp "$target_skill_dir/SKILL.md" "$BACKUP_DIR/skill/$skill_name/SKILL.md"
    fi

    transform_skill "$skill_file" > "$target_skill_dir/SKILL.md"

    # Expand placeholders
    if grep -q "{OPENCODE_CONFIG}" "$target_skill_dir/SKILL.md" 2>/dev/null; then
      expand_placeholders "$target_skill_dir/SKILL.md"
    fi

    ((skill_count++))
  done
done

# Install shared-patterns (merged from all plugins)
echo "  Installing shared-patterns..."
SHARED_TARGET="$SKILL_TARGET/shared-patterns"
mkdir -p "$SHARED_TARGET"
shared_count=0
for plugin in "${RING_PLUGINS[@]}"; do
  shared_dir="$RING_ROOT/$plugin/skills/shared-patterns"
  [[ -d "$shared_dir" ]] || continue

  for pattern_file in "$shared_dir"/*.md; do
    [[ -f "$pattern_file" ]] || continue
    pattern_name=$(basename "$pattern_file")

    cp "$pattern_file" "$SHARED_TARGET/$pattern_name"
    ((shared_count++))
  done
done
echo "  Installed $skill_count skills + $shared_count shared patterns"

# ============================================================
# INSTALL COMMANDS
# ============================================================
echo "${GREEN}Installing commands...${RESET}"
CMD_TARGET="$TARGET_ROOT/command"
mkdir -p "$CMD_TARGET"

cmd_count=0
for plugin in "${RING_PLUGINS[@]}"; do
  cmd_dir="$RING_ROOT/$plugin/commands"
  [[ -d "$cmd_dir" ]] || continue

  for cmd_file in "$cmd_dir"/*.md; do
    [[ -f "$cmd_file" ]] || continue
    cmd_name=$(basename "$cmd_file")

    # Backup if exists
    if [[ -f "$CMD_TARGET/$cmd_name" ]]; then
      mkdir -p "$BACKUP_DIR/command"
      cp "$CMD_TARGET/$cmd_name" "$BACKUP_DIR/command/$cmd_name"
    fi

    transform_command "$cmd_file" > "$CMD_TARGET/$cmd_name"
    ((cmd_count++))
  done
done
echo "  Installed $cmd_count commands"

# ============================================================
# INSTALL STANDARDS & TEMPLATES
# ============================================================
echo "${GREEN}Installing standards & templates...${RESET}"

# Standards from dev-team/docs/standards/
STANDARDS_TARGET="$TARGET_ROOT/standards"
mkdir -p "$STANDARDS_TARGET"
if [[ -d "$RING_ROOT/dev-team/docs/standards" ]]; then
  rsync -a --checksum "$RING_ROOT/dev-team/docs/standards/" "$STANDARDS_TARGET/"
  echo "  Installed standards from dev-team/docs/standards/"
fi

# Templates
TEMPLATES_TARGET="$TARGET_ROOT/templates"
mkdir -p "$TEMPLATES_TARGET"
if [[ -d "$SCRIPT_DIR/templates" ]]; then
  rsync -a --checksum "$SCRIPT_DIR/templates/" "$TEMPLATES_TARGET/"
  echo "  Installed templates"
fi

# ============================================================
# INSTALL PLUGIN RUNTIME
# ============================================================
echo "${GREEN}Installing plugin runtime...${RESET}"

# Plugin TypeScript files
if [[ -d "$SCRIPT_DIR/plugin" ]]; then
  mkdir -p "$TARGET_ROOT/plugin"
  rsync -a --checksum "$SCRIPT_DIR/plugin/" "$TARGET_ROOT/plugin/"
  echo "  Installed plugin/"
fi

# Gate progression validator hook (shell script used by plugin)
GATE_VALIDATOR="$RING_ROOT/dev-team/hooks/validate-gate-progression.sh"
if [[ -f "$GATE_VALIDATOR" ]]; then
  mkdir -p "$TARGET_ROOT/hooks"
  if [[ -f "$TARGET_ROOT/hooks/validate-gate-progression.sh" ]]; then
    mkdir -p "$BACKUP_DIR/hooks"
    cp "$TARGET_ROOT/hooks/validate-gate-progression.sh" "$BACKUP_DIR/hooks/validate-gate-progression.sh"
  fi
  cp "$GATE_VALIDATOR" "$TARGET_ROOT/hooks/validate-gate-progression.sh"
  chmod +x "$TARGET_ROOT/hooks/validate-gate-progression.sh"
  echo "  Installed hooks/validate-gate-progression.sh"
fi

# Prompts (session-start, context-injection)
if [[ -d "$SCRIPT_DIR/prompts" ]]; then
  mkdir -p "$TARGET_ROOT/prompts"
  rsync -a --checksum "$SCRIPT_DIR/prompts/" "$TARGET_ROOT/prompts/"
  echo "  Installed prompts/"
fi

# Schema files
for schema in ring-config.schema.json background-tasks.schema.json; do
  if [[ -f "$SCRIPT_DIR/$schema" ]]; then
    cp "$SCRIPT_DIR/$schema" "$TARGET_ROOT/$schema"
    echo "  Installed $schema"
  fi
done

# Ring config
mkdir -p "$TARGET_ROOT/ring"
if [[ -f "$SCRIPT_DIR/ring.jsonc" ]]; then
  # Only copy if target doesn't exist (don't overwrite user config)
  if [[ ! -f "$TARGET_ROOT/ring/config.jsonc" ]]; then
    cp "$SCRIPT_DIR/ring.jsonc" "$TARGET_ROOT/ring/config.jsonc"
    echo "  Installed ring/config.jsonc (default)"
  else
    echo "  ${YELLOW}Skipped ring/config.jsonc (user config exists)${RESET}"
  fi
fi

# Ensure state dir exists
mkdir -p "$TARGET_ROOT/state"

# ============================================================
# INSTALL DEPENDENCIES
# ============================================================
echo "${GREEN}Installing dependencies...${RESET}"

# Merge package.json
REQUIRED_DEPS_JSON='{
  "dependencies": {
    "@opencode-ai/plugin": "1.1.3",
    "better-sqlite3": "12.6.0",
    "zod": "^4.1.8",
    "jsonc-parser": "^3.3.1",
    "@clack/prompts": "^0.11.0",
    "picocolors": "^1.1.1",
    "commander": "^14.0.2"
  },
  "devDependencies": {
    "@types/better-sqlite3": "7.6.13",
    "@types/node": "22.19.5",
    "typescript": "5.9.3",
    "@biomejs/biome": "^1.9.4"
  }
}'

REQUIRED_DEPS_JSON="$REQUIRED_DEPS_JSON" TARGET_ROOT="$TARGET_ROOT" node - <<'NODE'
const fs = require('fs');
const targetRoot = process.env.TARGET_ROOT;
const pkgPath = `${targetRoot}/package.json`;
const required = JSON.parse(process.env.REQUIRED_DEPS_JSON);

let pkg = {};
if (fs.existsSync(pkgPath)) {
  try { pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8')); } catch (e) {
    console.error(`ERROR: Failed to parse ${pkgPath}: ${e}`);
    process.exit(1);
  }
}

for (const section of ['dependencies', 'devDependencies']) {
  pkg[section] = { ...(pkg[section] || {}), ...(required[section] || {}) };
}
pkg.name ??= 'opencode-config';
pkg.private ??= true;

fs.writeFileSync(pkgPath, JSON.stringify(pkg, null, 2) + '\n', { encoding: 'utf8', mode: 0o600 });
console.log(`  Updated ${pkgPath}`);
NODE

# Install with bun
if command -v bun >/dev/null 2>&1; then
  echo "  Running bun install..."
  if ! (cd "$TARGET_ROOT" && CXXFLAGS='-std=c++20' bun install 2>&1 | tail -3); then
    echo "${RED}ERROR: bun install failed.${RESET}" >&2
    echo "  Install Node 22 LTS and try again." >&2
    exit 1
  fi
else
  echo "  ${YELLOW}WARN: bun not found; skipping dependency install.${RESET}" >&2
fi

# ============================================================
# SUMMARY
# ============================================================
echo ""
echo "${GREEN}================================================${RESET}"
echo "${GREEN}  Ring → OpenCode - Install Complete${RESET}"
echo "${GREEN}================================================${RESET}"
echo ""
echo "Installed from Ring monorepo:"
echo "  • $agent_count agents (from ${#RING_PLUGINS[@]} plugins)"
echo "  • $skill_count skills + $shared_count shared patterns"
echo "  • $cmd_count commands"
echo "  • Plugin runtime, standards, templates, prompts"
echo ""
echo "Backup: $BACKUP_DIR"
echo ""
echo "To verify:"
echo "  1. Start OpenCode in your project"
echo "  2. Ring skills should appear in command palette"
echo ""
