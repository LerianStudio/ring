#!/usr/bin/env bash
# ==============================================================================
# Ring - Unified Symlinks Installer
# ==============================================================================
# Installs Ring agents/skills/commands/hooks into one or more AI coding tools:
#
#   • Claude Code   -> ~/.claude/{agents,commands,skills,hooks}       (per-file)
#   • Factory AI    -> ~/.factory/{agents,commands,skills,hooks}      (per-file)
#   • Opencode      -> ~/.config/opencode/{agent,command,skill}       (top-level)
#   • Codex         -> ~/.codex/skills                                (top-level)
#
# Claude Code / Factory AI: per-file symlinks against the source plugin tree.
# Opencode / Codex: top-level symlinks against a built tree at .ring-build/
# because both tools need namespace/frontmatter transforms before install.
#
# Usage:
#   bash install-symlinks.sh                            # interactive menu
#   bash install-symlinks.sh --claude                   # Claude Code only
#   bash install-symlinks.sh --opencode                 # Opencode (auto-builds)
#   bash install-symlinks.sh --all                      # all four tools
#   bash install-symlinks.sh remove                     # remove all symlinks
#   bash install-symlinks.sh doctor                     # verify install
#   bash install-symlinks.sh build                      # rebuild opencode/codex
#   bash install-symlinks.sh all --all                  # clean + build + install
#   bash install-symlinks.sh install /path/to/ring      # explicit repo path
#
# Subcommands (positional, optional; defaults to install):
#   install     Install symlinks for selected targets (default)
#   remove      Remove all Ring symlinks (alias: uninstall)
#   build       Generate .ring-build/{opencode,codex} from source
#   clean       Remove .ring-build/ outputs
#   doctor      Verify install symlinks and build outputs
#   all         clean + build + install
#
# Target flags (omit to be prompted interactively):
#   --claude    Claude Code         (~/.claude/)
#   --factory   Factory AI          (~/.factory/)
#   --opencode  Opencode            (~/.config/opencode/)
#   --codex     Codex               (~/.codex/)
#   --all       All of the above
#
# Behavior flags:
#   --dry-run   Print intended actions; change nothing
#   --verbose   Per-file logging
#   --force     Replace non-symlink collisions (timestamped backup)
#   --yes / -y  Skip confirmation in interactive mode
#   --help / -h Show this message
#
# Requirements:
#   - bash 3.2+ (macOS) or bash 4+ (Linux)
#   - jq        (Claude/Factory hooks.json merge)
#   - python3   (Codex frontmatter transform; only needed for opencode/codex)
#   - rsync     (opencode/codex build)
# ==============================================================================

set -euo pipefail

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# --- Globals ---
SCRIPT_SOURCE="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd -P "$(dirname "$SCRIPT_SOURCE")" && pwd)"
RING_DIR=""

# Target directories
CLAUDE_DIR="$HOME/.claude"
FACTORY_DIR="$HOME/.factory"
OPENCODE_DIR="$HOME/.config/opencode"
CODEX_DIR="$HOME/.codex"

# Build outputs (for opencode/codex)
BUILD_DIR=""
OPENCODE_OUT=""
CODEX_OUT=""
PY_HELPER=""
LOOKUP_JSON=""

# Plugin teams
TEAMS="default dev-team pm-team tw-team"

# Target selection (set via flags or interactive prompt)
INSTALL_CLAUDE=false
INSTALL_FACTORY=false
INSTALL_OPENCODE=false
INSTALL_CODEX=false

# Behavior flags
SUBCMD=""
DRY_RUN=0
VERBOSE=0
FORCE=0
ASSUME_YES=0
POSITIONAL_PATH=""

# Counters
CREATED=0
SKIPPED=0
UPDATED=0
ERRORS=0
REMOVED=0

# --- Logging helpers ---
log_info()    { printf "  ${BLUE}INFO${NC}    %s\n" "$1"; }
log_success() { printf "  ${GREEN}OK${NC}      %s\n" "$1"; }
log_skip()    { printf "  ${YELLOW}SKIP${NC}    %s\n" "$1"; }
log_warn()    { printf "  ${YELLOW}WARN${NC}    %s\n" "$1"; }
log_error()   { printf "  ${RED}ERROR${NC}   %s\n" "$1" >&2; }
log_section() { printf "\n  ${BOLD}${CYAN}── %s ──${NC}\n\n" "$1"; }
log_dim()     { printf "  ${DIM}%s${NC}\n" "$1"; }
vlog()        { if [ "$VERBOSE" -eq 1 ]; then printf "  ${DIM}· %s${NC}\n" "$1"; fi; }

print_banner() {
  printf "${CYAN}"
  printf "\n  ╔══════════════════════════════════════════════════╗\n"
  printf "  ║        Ring - Unified Symlinks Installer        ║\n"
  printf "  ╚══════════════════════════════════════════════════╝\n"
  printf "${NC}\n"
}

# --- Usage ---
usage() {
  cat <<'EOF'

  Ring Installer — symlink Ring into Claude Code, Factory AI, Opencode, or Codex.

  USAGE:
    bash install-symlinks.sh [SUBCOMMAND] [TARGETS] [FLAGS] [/path/to/ring]

  SUBCOMMANDS (default: install):
    install         Install symlinks for selected targets
    remove          Remove all Ring symlinks (alias: uninstall)
    build           Generate .ring-build/{opencode,codex} outputs
    clean           Remove .ring-build/ outputs
    doctor          Verify install symlinks and build outputs
    all             clean + build + install

  TARGET FLAGS (omit to be prompted interactively):
    --claude        Claude Code        (~/.claude/)
    --factory       Factory AI         (~/.factory/)
    --opencode      Opencode           (~/.config/opencode/)
    --codex         Codex              (~/.codex/)
    --all           All of the above

  BEHAVIOR FLAGS:
    --dry-run       Print intended actions; change nothing
    --verbose       Per-file logging
    --force         Replace non-symlink collisions (timestamped backup)
    --yes / -y      Skip confirmation in interactive mode
    --help / -h     Show this message

  EXAMPLES:
    bash install-symlinks.sh                    # interactive menu
    bash install-symlinks.sh --claude           # Claude Code only (no prompt)
    bash install-symlinks.sh --opencode         # Opencode (auto-builds first)
    bash install-symlinks.sh --all              # all four tools
    bash install-symlinks.sh remove             # remove all Ring symlinks
    bash install-symlinks.sh doctor             # verify install
    bash install-symlinks.sh all --all -y       # clean + build + install all

  EXIT CODES:
    0  success
    1  usage error
    2  missing required tool (jq / python3 / rsync)
    3  invalid Ring repo (missing CLAUDE.md or default/agents/)
    4  install collision (non-symlink target; re-run with --force)
    5  build produced zero output

EOF
}

# --- Repo detection & sanity ---
resolve_ring_dir() {
  if [ -n "$POSITIONAL_PATH" ]; then
    RING_DIR="$(cd "$POSITIONAL_PATH" 2>/dev/null && pwd)" \
      || { log_error "Path not found: $POSITIONAL_PATH"; exit 1; }
  else
    RING_DIR="$SCRIPT_DIR"
  fi

  if [ ! -f "$RING_DIR/CLAUDE.md" ] || [ ! -d "$RING_DIR/default/agents" ]; then
    log_error "Not a Ring repo: $RING_DIR"
    log_error "Missing CLAUDE.md or default/agents/. Provide the correct path."
    exit 3
  fi

  BUILD_DIR="$RING_DIR/.ring-build"
  OPENCODE_OUT="$BUILD_DIR/opencode"
  CODEX_OUT="$BUILD_DIR/codex/skills"
  PY_HELPER="$RING_DIR/scripts/_codex_frontmatter.py"
  LOOKUP_JSON="$BUILD_DIR/.codex-lookup.json"
}

require_cmd() {
  local cmd="$1"; local why="$2"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    log_error "$cmd is required for $why but was not found in PATH"
    case "$cmd" in
      jq) log_error "install: brew install jq  |  apt install jq" ;;
      python3)
        case "$(uname -s)" in
          Darwin) log_error "install: xcode-select --install" ;;
          *)      log_error "install via your package manager" ;;
        esac
        ;;
      rsync) log_error "install: brew install rsync  |  apt install rsync" ;;
    esac
    exit 2
  fi
}

# --- Tool auto-detection ---
detect_tool() {
  # detect_tool <dir>  -> "installed" | "not-detected"
  if [ -d "$1" ]; then echo "installed"; else echo "not-detected"; fi
}

# --- Interactive target prompt ---
interactive_select_targets() {
  local c_state f_state o_state x_state
  c_state="$(detect_tool "$CLAUDE_DIR")"
  f_state="$(detect_tool "$FACTORY_DIR")"
  o_state="$(detect_tool "$OPENCODE_DIR")"
  x_state="$(detect_tool "$CODEX_DIR")"

  local c_mark f_mark o_mark x_mark
  [ "$c_state" = "installed" ] && c_mark="${GREEN}✓${NC}" || c_mark="${DIM}·${NC}"
  [ "$f_state" = "installed" ] && f_mark="${GREEN}✓${NC}" || f_mark="${DIM}·${NC}"
  [ "$o_state" = "installed" ] && o_mark="${GREEN}✓${NC}" || o_mark="${DIM}·${NC}"
  [ "$x_state" = "installed" ] && x_mark="${GREEN}✓${NC}" || x_mark="${DIM}·${NC}"

  printf "  ${BOLD}Detected on this system:${NC}\n"
  printf "    %b  Claude Code      ${DIM}%s${NC}\n" "$c_mark" "$CLAUDE_DIR"
  printf "    %b  Factory AI       ${DIM}%s${NC}\n" "$f_mark" "$FACTORY_DIR"
  printf "    %b  Opencode         ${DIM}%s${NC}\n" "$o_mark" "$OPENCODE_DIR"
  printf "    %b  Codex            ${DIM}%s${NC}\n" "$x_mark" "$CODEX_DIR"
  printf "\n"
  printf "  ${BOLD}What do you want to install?${NC}\n"
  printf "    ${BOLD}1${NC}) Claude Code\n"
  printf "    ${BOLD}2${NC}) Factory AI\n"
  printf "    ${BOLD}3${NC}) Opencode    ${DIM}(will build .ring-build/opencode/ first)${NC}\n"
  printf "    ${BOLD}4${NC}) Codex       ${DIM}(will build .ring-build/codex/ first)${NC}\n"
  printf "    ${BOLD}5${NC}) All detected\n"
  printf "    ${BOLD}6${NC}) All four\n"
  printf "    ${BOLD}q${NC}) Cancel\n"
  printf "\n"
  printf "  ${BOLD}Selection${NC} (number, comma-separated like ${CYAN}1,3${NC}, or ${CYAN}q${NC}): "

  local choice
  read -r choice || { printf "\n"; log_error "no input received"; exit 1; }
  printf "\n"

  case "$choice" in
    q|Q|"") log_info "Cancelled."; exit 0 ;;
  esac

  # Parse comma-separated list of digits
  local IFS=','
  local picks=()
  read -ra picks <<<"$choice"
  unset IFS

  local pick
  for pick in "${picks[@]}"; do
    pick="${pick// /}"  # strip spaces
    case "$pick" in
      1) INSTALL_CLAUDE=true ;;
      2) INSTALL_FACTORY=true ;;
      3) INSTALL_OPENCODE=true ;;
      4) INSTALL_CODEX=true ;;
      5)
        [ "$c_state" = "installed" ] && INSTALL_CLAUDE=true
        [ "$f_state" = "installed" ] && INSTALL_FACTORY=true
        [ "$o_state" = "installed" ] && INSTALL_OPENCODE=true
        [ "$x_state" = "installed" ] && INSTALL_CODEX=true
        ;;
      6)
        INSTALL_CLAUDE=true
        INSTALL_FACTORY=true
        INSTALL_OPENCODE=true
        INSTALL_CODEX=true
        ;;
      *) log_error "Invalid selection: '$pick'"; exit 1 ;;
    esac
  done

  if ! any_target_selected; then
    log_error "No targets selected."
    exit 1
  fi
}

any_target_selected() {
  [ "$INSTALL_CLAUDE" = true ] || [ "$INSTALL_FACTORY" = true ] \
    || [ "$INSTALL_OPENCODE" = true ] || [ "$INSTALL_CODEX" = true ]
}

selected_targets_summary() {
  local parts=()
  [ "$INSTALL_CLAUDE"   = true ] && parts+=("Claude Code")
  [ "$INSTALL_FACTORY"  = true ] && parts+=("Factory AI")
  [ "$INSTALL_OPENCODE" = true ] && parts+=("Opencode")
  [ "$INSTALL_CODEX"    = true ] && parts+=("Codex")
  local IFS=", "
  echo "${parts[*]}"
}

# --- Dry-run aware mutators ---
do_mkdir_p() {
  if [ "$DRY_RUN" -eq 1 ]; then
    vlog "[dry-run] mkdir -p $1"
  else
    mkdir -p "$1"
  fi
}

do_rm_one() {
  if [ "$DRY_RUN" -eq 1 ]; then
    vlog "[dry-run] rm -f $1"
  else
    rm -f "$1" 2>/dev/null || rm -rf "$1" 2>/dev/null || true
  fi
}

do_rm_rf() {
  if [ "$DRY_RUN" -eq 1 ]; then
    vlog "[dry-run] rm -rf $1"
  else
    rm -rf "$1"
  fi
}

do_mv() {
  if [ "$DRY_RUN" -eq 1 ]; then
    vlog "[dry-run] mv $1 -> $2"
  else
    mv "$1" "$2"
  fi
}

do_cp_file() {
  if [ "$DRY_RUN" -eq 1 ]; then
    vlog "[dry-run] cp $1 -> $2"
  else
    mkdir -p "$(dirname "$2")"
    cp -f "$1" "$2"
  fi
}

do_rsync_dir() {
  if [ "$DRY_RUN" -eq 1 ]; then
    vlog "[dry-run] rsync -a $1/ -> $2/"
  else
    mkdir -p "$2"
    rsync -a --delete "$1/" "$2/"
  fi
}

do_ln_s() {
  if [ "$DRY_RUN" -eq 1 ]; then
    vlog "[dry-run] ln -s $1 -> $2"
  else
    ln -s "$1" "$2"
  fi
}

# ==============================================================================
# CLAUDE / FACTORY: per-file symlink install (preserves original logic)
# ==============================================================================

create_perfile_directories() {
  local target_dir="$1"
  local sub
  for sub in agents commands skills hooks; do
    [ -d "$target_dir/$sub" ] || do_mkdir_p "$target_dir/$sub"
  done
}

create_symlink() {
  local src="$1"; local target="$2"
  local name; name="$(basename "$target")"

  if [ -L "$target" ]; then
    local existing
    existing="$(readlink "$target")"
    if [ "$existing" = "$src" ]; then
      SKIPPED=$((SKIPPED + 1))
      return
    fi
    do_rm_one "$target"
    do_ln_s "$src" "$target"
    log_success "$name (updated)"
    UPDATED=$((UPDATED + 1))
    return
  fi

  if [ -e "$target" ]; then
    if [ "$FORCE" -eq 1 ]; then
      local backup="${target}.backup_$(date +%Y%m%d_%H%M%S)"
      do_mv "$target" "$backup"
      do_ln_s "$src" "$target"
      log_success "$name (backed up + replaced)"
      CREATED=$((CREATED + 1))
      return
    fi
    log_error "$name already exists as a regular file (use --force to back up). Skipping."
    ERRORS=$((ERRORS + 1))
    return
  fi

  do_ln_s "$src" "$target"
  CREATED=$((CREATED + 1))
}

link_perfile_agents() {
  local plugin="$1"; local target_dir="$2"
  local agents_dir="$RING_DIR/$plugin/agents"
  [ -d "$agents_dir" ] || return 0
  local agent name
  for agent in "$agents_dir"/*.md; do
    [ -f "$agent" ] || continue
    name="$(basename "$agent")"
    create_symlink "$agent" "$target_dir/agents/$name"
  done
}

link_perfile_commands() {
  local plugin="$1"; local target_dir="$2"
  local commands_dir="$RING_DIR/$plugin/commands"
  [ -d "$commands_dir" ] || return 0
  local cmd name
  for cmd in "$commands_dir"/*.md; do
    [ -f "$cmd" ] || continue
    name="$(basename "$cmd")"
    create_symlink "$cmd" "$target_dir/commands/$name"
  done
}

link_perfile_skills() {
  local plugin="$1"; local target_dir="$2"
  local skills_dir="$RING_DIR/$plugin/skills"
  [ -d "$skills_dir" ] || return 0
  local skill name
  for skill in "$skills_dir"/*/; do
    [ -d "$skill" ] || continue
    name="$(basename "$skill")"
    [ "$name" = "shared-patterns" ] && continue
    create_symlink "$skill" "$target_dir/skills/$name"
  done
}

link_perfile_hooks() {
  local plugin="$1"; local target_dir="$2"
  local hooks_dir="$RING_DIR/$plugin/hooks"
  [ -d "$hooks_dir" ] || return 0

  # 1) symlink .sh hook scripts
  local hook_script name
  for hook_script in "$hooks_dir"/*.sh; do
    [ -f "$hook_script" ] || continue
    name="$(basename "$hook_script")"
    create_symlink "$hook_script" "$target_dir/hooks/$name"
  done

  # 2) merge hooks.json into settings.json
  local hooks_json="$hooks_dir/hooks.json"
  [ -f "$hooks_json" ] || return 0

  if [ "$DRY_RUN" -eq 1 ]; then
    vlog "[dry-run] merge $hooks_json into $target_dir/settings.json"
    return 0
  fi

  require_cmd jq "hooks.json merge"

  local settings_file="$target_dir/settings.json"
  local hooks_target="$target_dir/hooks"
  local rewritten
  rewritten=$(sed "s|\${CLAUDE_PLUGIN_ROOT}/hooks/|$hooks_target/|g" "$hooks_json")

  if [ ! -f "$settings_file" ]; then
    local formatted
    formatted=$(echo "$rewritten" | jq '.' 2>/dev/null)
    if [ -n "$formatted" ]; then
      echo "$formatted" >"$settings_file"
      log_success "Created settings.json with hooks from $plugin"
    else
      log_error "Invalid hooks.json in $plugin — skipping"
      ERRORS=$((ERRORS + 1))
    fi
    return
  fi

  local merged
  merged=$(
    echo "$rewritten" | jq -s '
      .[0] as $base | .[1] as $new |
      ($base.hooks // {}) as $bh | ($new.hooks // {}) as $nh |
      ($bh | keys) + ($nh | keys) | unique | reduce .[] as $evt ({};
        . + {($evt): (($bh[$evt] // []) + ($nh[$evt] // []) | unique_by({matcher: (.matcher // ""), hooks: .hooks}))}
      ) | $base * {hooks: .}
    ' "$settings_file" -
  )

  if [ -n "$merged" ]; then
    echo "$merged" | jq '.' >"$settings_file"
    log_success "Merged hooks from $plugin into settings.json"
  else
    log_error "Failed to merge hooks from $plugin"
    ERRORS=$((ERRORS + 1))
  fi
}

install_perfile() {
  local target_dir="$1"; local label="$2"
  log_section "$label  ($target_dir)"
  create_perfile_directories "$target_dir"
  local plugin
  for plugin in $TEAMS; do
    [ -d "$RING_DIR/$plugin" ] || continue
    link_perfile_agents   "$plugin" "$target_dir"
    link_perfile_commands "$plugin" "$target_dir"
    link_perfile_skills   "$plugin" "$target_dir"
    link_perfile_hooks    "$plugin" "$target_dir"
  done
}

# ==============================================================================
# OPENCODE / CODEX: build .ring-build/ + top-level dir symlinks
# (Logic adapted from ring-install.sh)
# ==============================================================================

# ----- build helpers -----
build_copy_opencode_agents() {
  local team="$1"
  local src_dir="$RING_DIR/$team/agents"
  local dst_dir="$OPENCODE_OUT/agent/$team"
  [ -d "$src_dir" ] || return 0
  local f base
  for f in "$src_dir"/*.md; do
    [ -e "$f" ] || continue
    base="$(basename "$f")"
    do_cp_file "$f" "$dst_dir/$base"
    vlog "opencode agent: $team/$base"
  done
}

build_copy_opencode_skills() {
  local team="$1"
  local src_dir="$RING_DIR/$team/skills"
  local dst_dir="$OPENCODE_OUT/skill/$team"
  [ -d "$src_dir" ] || return 0
  local d name
  for d in "$src_dir"/*/; do
    [ -d "$d" ] || continue
    name="$(basename "$d")"
    if [ "$name" = "shared-patterns" ]; then
      build_copy_shared_patterns_opencode "$team" "$d"
      continue
    fi
    do_rsync_dir "$d" "$dst_dir/$name"
    vlog "opencode skill: $team/$name"
  done
}

build_copy_shared_patterns_opencode() {
  local team="$1"; local src="$2"
  local count
  count=$(find "$src" -maxdepth 1 -name '*.md' -type f 2>/dev/null | wc -l | tr -d ' ')
  if [ "${count:-0}" -eq 0 ]; then
    vlog "opencode shared-patterns empty: $team (skip)"
    return 0
  fi
  local dst="$OPENCODE_OUT/skill/$team/shared-patterns"
  if [ "$DRY_RUN" -eq 1 ]; then
    vlog "[dry-run] rsync -a $src -> $dst/"
  else
    mkdir -p "$dst"
    rsync -a --delete "$src" "$dst/"
  fi
  vlog "opencode shared-patterns: $team"
}

build_copy_docs_mirror_opencode() {
  local src="$RING_DIR/dev-team/docs"
  local dst="$OPENCODE_OUT/skill/docs"
  [ -d "$src" ] || return 0
  do_rsync_dir "$src" "$dst"
  vlog "opencode docs mirror"
}

build_copy_top_level_cross_plugin_opencode() {
  local src="$RING_DIR/dev-team/skills/shared-patterns"
  local dst="$OPENCODE_OUT/dev-team/skills/shared-patterns"
  [ -d "$src" ] || return 0
  do_rsync_dir "$src" "$dst"
  vlog "opencode top-level cross-plugin mirror"
}

build_copy_opencode_commands() {
  local team="$1"
  local src_dir="$RING_DIR/$team/commands"
  local dst_dir="$OPENCODE_OUT/command/$team"
  [ -d "$src_dir" ] || return 0
  local f base
  for f in "$src_dir"/*.md; do
    [ -e "$f" ] || continue
    base="$(basename "$f")"
    do_cp_file "$f" "$dst_dir/$base"
    vlog "opencode command: $team/$base"
  done
}

build_codex_skill() {
  local team="$1"; local skill_dir="$2"
  local name dst_dir src_skill_md dst_skill_md
  name="$(basename "$skill_dir")"
  [ "$name" = "shared-patterns" ] && return 0
  dst_dir="$CODEX_OUT/$team/ring-${team}-${name}"
  src_skill_md="$skill_dir/SKILL.md"
  dst_skill_md="$dst_dir/SKILL.md"

  if [ ! -f "$src_skill_md" ]; then
    log_warn "skipping (no SKILL.md): $skill_dir"
    return 0
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    vlog "[dry-run] codex skill: $team/$name -> ring-${team}-${name}"
    return 0
  fi

  mkdir -p "$dst_dir"
  rsync -a --delete --exclude='SKILL.md' "$skill_dir/" "$dst_dir/"

  python3 "$PY_HELPER" \
    --source "$src_skill_md" \
    --dest   "$dst_skill_md" \
    --team   "$team" \
    --skill-name "$name" \
    --lookup "$LOOKUP_JSON"

  rewrite_accessory_paths_in "$dst_dir" "$team"
  vlog "codex skill: $team/$name -> ring-${team}-${name}"
}

build_copy_shared_patterns_codex() {
  local team="$1"
  local src="$RING_DIR/$team/skills/shared-patterns"
  local dst="$CODEX_OUT/$team/shared-patterns"
  [ -d "$src" ] || return 0
  local count
  count=$(find "$src" -maxdepth 1 -name '*.md' -type f 2>/dev/null | wc -l | tr -d ' ')
  if [ "${count:-0}" -eq 0 ]; then
    vlog "codex shared-patterns empty: $team (skip)"
    return 0
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    vlog "[dry-run] rsync -a $src/ -> $dst/"
    return 0
  fi
  mkdir -p "$dst"
  rsync -a --delete "$src/" "$dst/"
  rewrite_accessory_paths_in "$dst" "$team"
  vlog "codex shared-patterns: $team"
}

build_copy_docs_mirror_codex() {
  local src="$RING_DIR/dev-team/docs"
  local dst="$CODEX_OUT/docs"
  [ -d "$src" ] || return 0
  do_rsync_dir "$src" "$dst"
  vlog "codex docs mirror"
}

rewrite_accessory_paths_in() {
  local dir="$1"; local team="$2"
  [ -d "$dir" ] || return 0
  local f
  find "$dir" -type f -name '*.md' ! -name 'SKILL.md' -print | while IFS= read -r f; do
    python3 "$PY_HELPER" --rewrite-paths \
      --source "$f" --dest "$f" \
      --team "$team" --lookup "$LOOKUP_JSON"
  done
}

# ----- build orchestration -----
do_clean_build() {
  log_section "Clean build outputs"

  if [ -d "$OPENCODE_OUT" ]; then
    do_rm_rf "$OPENCODE_OUT"
    vlog "removed $OPENCODE_OUT"
  fi

  # Codex .system/ is preserved (manually maintained)
  if [ -d "$CODEX_OUT" ]; then
    local entry base
    for entry in "$CODEX_OUT"/* "$CODEX_OUT"/.[!.]*; do
      [ -e "$entry" ] || continue
      base="$(basename "$entry")"
      [ "$base" = ".system" ] && { vlog "preserve $entry"; continue; }
      [ "$base" = ".codex-lookup.json" ] && continue
      do_rm_rf "$entry"
      vlog "removed $entry"
    done
  else
    do_mkdir_p "$CODEX_OUT"
  fi

  [ -f "$LOOKUP_JSON" ] && do_rm_one "$LOOKUP_JSON"
  log_success "Build outputs cleaned."
}

do_build() {
  require_cmd python3 "Codex frontmatter transform"
  require_cmd rsync   "build mirroring"
  log_section "Build .ring-build/ (opencode + codex)"

  do_clean_build

  do_mkdir_p "$OPENCODE_OUT/agent"
  do_mkdir_p "$OPENCODE_OUT/skill"
  do_mkdir_p "$OPENCODE_OUT/command"
  do_mkdir_p "$CODEX_OUT"

  if [ "$DRY_RUN" -eq 1 ]; then
    vlog "[dry-run] build lookup -> $LOOKUP_JSON"
  else
    python3 "$PY_HELPER" --build-lookup "$RING_DIR" --lookup-out "$LOOKUP_JSON"
    vlog "lookup written: $LOOKUP_JSON"
  fi

  local team d
  for team in $TEAMS; do
    [ -d "$RING_DIR/$team" ] || { log_warn "team dir missing: $team"; continue; }
    build_copy_opencode_agents   "$team"
    build_copy_opencode_skills   "$team"
    build_copy_opencode_commands "$team"
    build_copy_shared_patterns_codex "$team"

    if [ -d "$RING_DIR/$team/skills" ]; then
      for d in "$RING_DIR/$team/skills"/*/; do
        [ -d "$d" ] || continue
        build_codex_skill "$team" "${d%/}"
      done
    fi
  done

  build_copy_docs_mirror_opencode
  build_copy_docs_mirror_codex
  build_copy_top_level_cross_plugin_opencode

  if [ "$DRY_RUN" -eq 0 ]; then
    local count
    count=$(find "$OPENCODE_OUT" "$CODEX_OUT" -mindepth 1 -maxdepth 4 -type f 2>/dev/null | wc -l | tr -d ' ')
    if [ "${count:-0}" -eq 0 ]; then
      log_error "build produced zero output"
      exit 5
    fi
  fi
  log_success "Build complete."
}

# ----- top-level dir symlink install (opencode/codex) -----
ensure_toplevel_symlink() {
  local src="$1"; local target="$2"

  if [ -L "$target" ]; then
    local current; current="$(readlink "$target")"
    if [ "$current" = "$src" ]; then
      SKIPPED=$((SKIPPED + 1))
      vlog "SKIP   $target (already correct)"
      return 0
    fi
    do_rm_one "$target"
    do_mkdir_p "$(dirname "$target")"
    do_ln_s "$src" "$target"
    log_success "$(basename "$target") (updated; was -> $current)"
    UPDATED=$((UPDATED + 1))
    return 0
  fi

  if [ -e "$target" ]; then
    if [ "$FORCE" -eq 1 ]; then
      local backup="${target}.backup_$(date +%Y%m%d_%H%M%S)"
      do_mv "$target" "$backup"
      do_mkdir_p "$(dirname "$target")"
      do_ln_s "$src" "$target"
      log_success "$(basename "$target") (backed up: $backup)"
      CREATED=$((CREATED + 1))
      return 0
    fi
    log_error "collision: $target exists and is not a symlink (use --force to back up)"
    ERRORS=$((ERRORS + 1))
    exit 4
  fi

  do_mkdir_p "$(dirname "$target")"
  do_ln_s "$src" "$target"
  log_success "$(basename "$target")"
  CREATED=$((CREATED + 1))
}

install_opencode() {
  log_section "Opencode  ($OPENCODE_DIR)"

  # Clean up any dangling opencode/plugins symlink (historical artifact)
  local plugins_tgt="$OPENCODE_DIR/plugins"
  if [ -L "$plugins_tgt" ] && [ ! -e "$plugins_tgt" ]; then
    do_rm_one "$plugins_tgt"
    log_success "removed dangling plugins symlink"
  fi

  ensure_toplevel_symlink "$OPENCODE_OUT/agent"   "$OPENCODE_DIR/agent"
  ensure_toplevel_symlink "$OPENCODE_OUT/skill"   "$OPENCODE_DIR/skill"
  ensure_toplevel_symlink "$OPENCODE_OUT/command" "$OPENCODE_DIR/command"
}

install_codex() {
  log_section "Codex  ($CODEX_DIR)"
  ensure_toplevel_symlink "$CODEX_OUT" "$CODEX_DIR/skills"
}

# ==============================================================================
# REMOVE
# ==============================================================================

remove_perfile_symlinks() {
  local target_dir="$1"; local label="$2"
  [ -d "$target_dir" ] || return 0
  log_section "Removing $label  ($target_dir)"
  local dir item link_target
  for dir in agents commands skills hooks; do
    [ -d "$target_dir/$dir" ] || continue
    for item in "$target_dir/$dir"/*; do
      [ -L "$item" ] || continue
      link_target="$(readlink "$item")"
      # only remove symlinks pointing into Ring
      if [[ "$link_target" == "$RING_DIR"/* ]]; then
        do_rm_one "$item"
        log_success "Removed: $dir/$(basename "$item")"
        REMOVED=$((REMOVED + 1))
      fi
    done
  done

  # Clean Ring hook entries from settings.json
  local settings_file="$target_dir/settings.json"
  if [ -f "$settings_file" ] && command -v jq >/dev/null 2>&1; then
    if [ "$DRY_RUN" -eq 1 ]; then
      vlog "[dry-run] strip Ring hooks from $settings_file"
    else
      local cleaned
      cleaned=$(jq --arg hooks_path "$target_dir/hooks/" '
        if .hooks then
          .hooks |= with_entries(
            .value |= map(select(
              (.hooks // []) | all(.command | contains($hooks_path) | not)
            ))
          )
        else . end
      ' "$settings_file")
      if [ -n "$cleaned" ]; then
        echo "$cleaned" | jq '.' >"$settings_file"
        log_success "Cleaned Ring hooks from settings.json"
      fi
    fi
  fi
}

remove_toplevel_symlink() {
  local target="$1"; local label="$2"
  [ -L "$target" ] || return 0
  local current; current="$(readlink "$target")"
  if [[ "$current" == "$BUILD_DIR"/* ]] || [[ "$current" == "$RING_DIR"/* ]]; then
    do_rm_one "$target"
    log_success "Removed: $label"
    REMOVED=$((REMOVED + 1))
  fi
}

do_remove() {
  log_section "Removing Ring symlinks"
  [ "$INSTALL_CLAUDE"  = true ] && remove_perfile_symlinks "$CLAUDE_DIR"  "Claude Code"
  [ "$INSTALL_FACTORY" = true ] && remove_perfile_symlinks "$FACTORY_DIR" "Factory AI"

  if [ "$INSTALL_OPENCODE" = true ]; then
    log_section "Removing Opencode  ($OPENCODE_DIR)"
    remove_toplevel_symlink "$OPENCODE_DIR/agent"   "opencode/agent"
    remove_toplevel_symlink "$OPENCODE_DIR/skill"   "opencode/skill"
    remove_toplevel_symlink "$OPENCODE_DIR/command" "opencode/command"
  fi
  if [ "$INSTALL_CODEX" = true ]; then
    log_section "Removing Codex  ($CODEX_DIR)"
    remove_toplevel_symlink "$CODEX_DIR/skills" "codex/skills"
  fi

  printf "\n"
  printf "  ${GREEN}${BOLD}Done!${NC} Removed ${REMOVED} symlinks.\n\n"
}

# ==============================================================================
# DOCTOR
# ==============================================================================

doctor_check_toplevel() {
  local target="$1"; local expected="$2"
  if [ ! -L "$target" ]; then
    log_error "FAIL   $target (not a symlink)"
    return 1
  fi
  local current; current="$(readlink "$target")"
  if [ "$current" != "$expected" ]; then
    log_error "FAIL   $target (-> $current; expected $expected)"
    return 1
  fi
  if [ ! -e "$target" ]; then
    log_error "FAIL   $target (dangling -> $current)"
    return 1
  fi
  log_success "PASS   $target"
  return 0
}

doctor_check_perfile() {
  local target_dir="$1"; local label="$2"
  if [ ! -d "$target_dir" ]; then
    log_skip "$label not installed ($target_dir absent)"
    return 0
  fi
  local sub item link_target count_ok=0 count_bad=0
  for sub in agents commands skills hooks; do
    [ -d "$target_dir/$sub" ] || continue
    for item in "$target_dir/$sub"/*; do
      [ -L "$item" ] || continue
      link_target="$(readlink "$item")"
      if [[ "$link_target" == "$RING_DIR"/* ]]; then
        if [ -e "$item" ]; then
          count_ok=$((count_ok + 1))
        else
          log_error "DANGLING  $item -> $link_target"
          count_bad=$((count_bad + 1))
        fi
      fi
    done
  done
  if [ "$count_bad" -gt 0 ]; then
    log_error "$label: $count_ok OK, $count_bad broken"
    return 1
  fi
  log_success "$label: $count_ok symlinks OK"
  return 0
}

do_doctor() {
  log_section "Doctor — verifying install state"
  local rc=0

  # Per-file targets
  doctor_check_perfile "$CLAUDE_DIR"  "Claude Code"  || rc=1
  doctor_check_perfile "$FACTORY_DIR" "Factory AI"   || rc=1

  # Top-level targets (opencode/codex) only checked if directory exists
  if [ -d "$OPENCODE_DIR" ]; then
    doctor_check_toplevel "$OPENCODE_DIR/agent"   "$OPENCODE_OUT/agent"   || rc=1
    doctor_check_toplevel "$OPENCODE_DIR/skill"   "$OPENCODE_OUT/skill"   || rc=1
    doctor_check_toplevel "$OPENCODE_DIR/command" "$OPENCODE_OUT/command" || rc=1
  else
    log_skip "Opencode not installed ($OPENCODE_DIR absent)"
  fi

  if [ -d "$CODEX_DIR" ]; then
    doctor_check_toplevel "$CODEX_DIR/skills" "$CODEX_OUT" || rc=1
  else
    log_skip "Codex not installed ($CODEX_DIR absent)"
  fi

  # Build output sanity (only relevant if opencode/codex installed)
  if [ -d "$OPENCODE_OUT" ]; then
    if [ -d "$OPENCODE_OUT/skill/docs/standards" ]; then
      log_success "PASS   opencode docs mirror present"
    else
      log_error "FAIL   opencode docs mirror missing"
      rc=1
    fi
    if [ -d "$OPENCODE_OUT/dev-team/skills/shared-patterns" ]; then
      log_success "PASS   opencode cross-plugin mirror present"
    else
      log_error "FAIL   opencode cross-plugin mirror missing"
      rc=1
    fi
  fi

  if [ -d "$CODEX_OUT" ]; then
    if [ -d "$CODEX_OUT/.system" ]; then
      log_success "PASS   codex .system/ preserved"
    else
      log_warn ".system/ missing in $CODEX_OUT (manual Codex config)"
    fi
    if [ -d "$CODEX_OUT/docs/standards" ]; then
      log_success "PASS   codex docs mirror present"
    else
      log_error "FAIL   codex docs mirror missing"
      rc=1
    fi
  fi

  printf "\n"
  if [ "$rc" -eq 0 ]; then
    printf "  ${GREEN}${BOLD}Doctor: all checks PASS${NC}\n\n"
  else
    printf "  ${RED}${BOLD}Doctor: drift detected${NC}  — try ${BOLD}bash install-symlinks.sh all --all${NC}\n\n"
  fi
  return $rc
}

# ==============================================================================
# Main flow
# ==============================================================================

needs_build() {
  [ "$INSTALL_OPENCODE" = true ] || [ "$INSTALL_CODEX" = true ]
}

do_install() {
  # Auto-build if opencode/codex selected and build is stale/missing
  if needs_build; then
    if [ ! -d "$OPENCODE_OUT" ] || [ ! -d "$CODEX_OUT" ]; then
      log_info "Build outputs missing — running build first."
      do_build
    fi
  fi

  [ "$INSTALL_CLAUDE"   = true ] && install_perfile "$CLAUDE_DIR"  "Claude Code"
  [ "$INSTALL_FACTORY"  = true ] && install_perfile "$FACTORY_DIR" "Factory AI"
  [ "$INSTALL_OPENCODE" = true ] && install_opencode
  [ "$INSTALL_CODEX"    = true ] && install_codex
}

print_summary() {
  printf "\n"
  printf "  ${BOLD}════════════════════════════════════════${NC}\n"
  printf "  ${GREEN}Created:${NC}  %d symlinks\n" "$CREATED"
  [ "$UPDATED" -gt 0 ] && printf "  ${BLUE}Updated:${NC}  %d (pointed elsewhere)\n" "$UPDATED"
  printf "  ${YELLOW}Skipped:${NC}  %d (already correct)\n" "$SKIPPED"
  [ "$ERRORS" -gt 0 ] && printf "  ${RED}Errors:${NC}   %d\n" "$ERRORS"
  printf "  ${BOLD}════════════════════════════════════════${NC}\n\n"
  printf "  ${CYAN}Ring repo:${NC}   %s\n" "$RING_DIR"
  printf "  ${CYAN}Targets:${NC}     %s\n" "$(selected_targets_summary)"
  printf "\n"

  local total=$((CREATED + UPDATED + SKIPPED))
  if [ "$total" -gt 0 ] && [ "$ERRORS" -eq 0 ]; then
    printf "  ${GREEN}${BOLD}Ring is ready!${NC}\n\n"
    printf "  Try these commands:\n"
    printf "    ${BOLD}/ring:dev-cycle${NC}       — 10-gate development cycle\n"
    printf "    ${BOLD}/ring:pre-dev-feature${NC} — lightweight pre-dev workflow\n"
    printf "    ${BOLD}/ring:codereview${NC}      — parallel code review (9 defaults + conditionals)\n"
    printf "    ${BOLD}/ring:commit${NC}          — smart atomic commits\n\n"
  fi
}

confirm_interactive() {
  [ "$ASSUME_YES" -eq 1 ] && return 0
  [ ! -t 0 ] && return 0   # not a TTY — auto-yes for piped input
  printf "  Proceed? ${BOLD}[Y/n]${NC} "
  local ans
  read -r ans || true
  printf "\n"
  case "$ans" in
    n|N|no|NO) log_info "Cancelled."; exit 0 ;;
  esac
}

# --- Arg parsing ---
parse_args() {
  local arg
  local saw_target_flag=0

  while [ $# -gt 0 ]; do
    arg="$1"
    case "$arg" in
      install|remove|uninstall|build|clean|doctor|all)
        # back-compat: "uninstall" -> "remove"
        [ "$arg" = "uninstall" ] && arg="remove"
        if [ -n "$SUBCMD" ]; then
          log_error "Multiple subcommands given: $SUBCMD and $arg"
          exit 1
        fi
        SUBCMD="$arg"
        ;;
      --claude)    INSTALL_CLAUDE=true;   saw_target_flag=1 ;;
      --factory)   INSTALL_FACTORY=true;  saw_target_flag=1 ;;
      --opencode)  INSTALL_OPENCODE=true; saw_target_flag=1 ;;
      --codex)     INSTALL_CODEX=true;    saw_target_flag=1 ;;
      --all)
        INSTALL_CLAUDE=true
        INSTALL_FACTORY=true
        INSTALL_OPENCODE=true
        INSTALL_CODEX=true
        saw_target_flag=1
        ;;
      # back-compat with old install-symlinks.sh: --remove was a top-level flag
      --remove)
        if [ -n "$SUBCMD" ] && [ "$SUBCMD" != "remove" ]; then
          log_error "--remove cannot be combined with subcommand: $SUBCMD"
          exit 1
        fi
        SUBCMD="remove"
        ;;
      --dry-run) DRY_RUN=1 ;;
      --verbose|-v) VERBOSE=1 ;;
      --force)   FORCE=1 ;;
      --yes|-y)  ASSUME_YES=1 ;;
      --help|-h) usage; exit 0 ;;
      -*)
        log_error "Unknown flag: $arg"
        usage
        exit 1
        ;;
      *)
        if [ -n "$POSITIONAL_PATH" ]; then
          log_error "Multiple positional paths: $POSITIONAL_PATH and $arg"
          exit 1
        fi
        POSITIONAL_PATH="$arg"
        ;;
    esac
    shift
  done

  # Default subcommand
  [ -z "$SUBCMD" ] && SUBCMD="install"

  # For doctor/clean/build, --all means "act on everything that's installed"
  # For install/remove/all, we need explicit target selection
  case "$SUBCMD" in
    install|remove|all)
      if [ "$saw_target_flag" -eq 0 ]; then
        if [ -t 0 ]; then
          interactive_select_targets
        else
          log_error "No target selected and stdin is not a TTY."
          log_error "Specify --claude / --factory / --opencode / --codex / --all"
          exit 1
        fi
      fi
      ;;
    build|clean|doctor)
      # These don't strictly need target flags; they act on the build tree.
      # But if user passed --all or specific flags, we honor them in doctor output.
      :
      ;;
  esac
}

# ==============================================================================
# Entry point
# ==============================================================================

print_banner

parse_args "$@"
resolve_ring_dir

# Show plan
log_info "Ring repo:   $RING_DIR"
log_info "Subcommand:  $SUBCMD"
if any_target_selected; then
  log_info "Targets:     $(selected_targets_summary)"
fi
[ "$DRY_RUN" -eq 1 ] && log_warn "DRY-RUN mode — no changes will be made"
[ "$VERBOSE" -eq 1 ] && log_info "Verbose logging enabled"
[ "$FORCE"   -eq 1 ] && log_info "Force mode — non-symlink collisions will be backed up"

case "$SUBCMD" in
  install)
    confirm_interactive
    do_install
    print_summary
    ;;
  remove)
    confirm_interactive
    do_remove
    ;;
  build)
    do_build
    ;;
  clean)
    do_clean_build
    ;;
  doctor)
    do_doctor
    ;;
  all)
    confirm_interactive
    do_clean_build
    do_build
    do_install
    print_summary
    ;;
  *)
    log_error "Internal error: unknown subcommand '$SUBCMD'"
    exit 1
    ;;
esac
