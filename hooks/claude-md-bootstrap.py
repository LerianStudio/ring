#!/usr/bin/env python3
"""
CLAUDE.md Bootstrap Orchestrator
Discovers repository layers, dispatches agents, generates CLAUDE.md
"""

import json
import os
import re
import sys
import subprocess
import tempfile
from pathlib import Path
from typing import Dict, List, Optional, Tuple
import time

# Configuration
MAX_LINES = 500
MAX_LAYER_ANALYSIS_TIME = 120  # seconds per layer agent
PROJECT_DIR = Path(os.environ.get('CLAUDE_PROJECT_DIR', '.')).resolve()


class BootstrapOrchestrator:
    """Orchestrates the CLAUDE.md generation process."""

    def __init__(self, project_dir: Path):
        self.project_dir = project_dir
        self.layers = []
        self.layer_findings = {}
        self.cross_cutting = {}
        self.claude_cli_available = self._check_claude_cli()

    def _check_claude_cli(self) -> bool:
        """Check if Claude Code CLI is available."""
        try:
            result = subprocess.run(
                ['claude', '--version'],
                capture_output=True,
                timeout=5
            )
            return result.returncode == 0
        except (subprocess.TimeoutExpired, FileNotFoundError):
            return False

    def _invoke_claude_agent(self, prompt: str, max_turns: int = 3, timeout: int = 120) -> Optional[str]:
        """Invoke Claude Code CLI in headless mode."""
        if not self.claude_cli_available:
            return None

        try:
            result = subprocess.run([
                'claude',
                '--print', prompt,
                '--output-format', 'json',
                '--max-turns', str(max_turns),
                '--allowedTools', 'Glob,Grep,Read,Bash'
            ],
            capture_output=True,
            text=True,
            timeout=timeout,
            cwd=str(self.project_dir)
            )

            if result.returncode == 0:
                # Parse JSON output from Claude CLI
                response_data = json.loads(result.stdout)
                # Extract the actual response text from JSON structure
                # CLI returns: {"type":"result", "result":"actual content"}
                if isinstance(response_data, dict):
                    if 'result' in response_data:
                        return response_data['result']
                    elif 'content' in response_data:
                        return response_data['content']
                elif isinstance(response_data, str):
                    return response_data
                else:
                    return str(response_data)
            return None

        except (subprocess.TimeoutExpired, json.JSONDecodeError, Exception) as e:
            print(f"Claude CLI invocation failed: {e}", file=sys.stderr)
            return None

    def run(self) -> bool:
        """Execute the full bootstrap process."""
        try:
            # Single-pass generation with Opus for maximum quality
            print("[Bootstrap] Generating CLAUDE.md with Claude Opus...", file=sys.stderr)

            if self.claude_cli_available:
                content = self.generate_with_opus()
                if content and '# CLAUDE.md' in content:
                    print("[Bootstrap] ✓ Opus generation successful", file=sys.stderr)
                    return self.write_claude_md(content)
                else:
                    print("[Bootstrap] ⚠ Opus generation failed, using template", file=sys.stderr)

            # Fallback to template
            print("[Bootstrap] Using template generation...", file=sys.stderr)
            content = self.generate_template_only()
            return self.write_claude_md(content)

        except Exception as e:
            print(f"Bootstrap failed: {e}", file=sys.stderr)
            self.write_fallback_template()
            return False

    def generate_with_opus(self) -> Optional[str]:
        """Single-pass CLAUDE.md generation using Opus."""
        prompt = f"""Analyze this repository at {self.project_dir} and generate a complete, actionable CLAUDE.md file.

CRITICAL REQUIREMENTS:
1. **Explore the codebase thoroughly** - Use Read, Glob, Grep tools to understand the actual structure
2. **Maximum 500 lines** - Token-conscious output
3. **Actionable content** - Specific file paths, runnable commands, real workflows
4. **Return ONLY the markdown content** - No explanations before or after

REQUIRED SECTIONS:
- Repository Overview (2-3 sentences: what it does, tech stack, architecture style)
- Architecture (describe actual directories found: skills/, hooks/, agents/, commands/, etc.)
- Common Commands (git, build, test, plugin-specific commands)
- Key Workflows (how to add skills, modify hooks, create agents - with exact file paths)
- Important Patterns (code organization, naming, anti-patterns to avoid)

STYLE:
- Use exact file paths found in the repo (e.g., `skills/using-ring/SKILL.md:15`)
- List actual commands that work (not placeholders)
- Focus on "how to work in this repo" not generic advice

Generate the complete CLAUDE.md now, starting with:
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository."""

        print("[Bootstrap] Invoking Claude Opus (this may take 60-120 seconds)...", file=sys.stderr)

        result = subprocess.run([
            'claude',
            '--print', prompt,
            '--output-format', 'json',
            '--max-turns', '8',
            '--model', 'opus',
            '--allowedTools', 'Glob,Grep,Read,Bash'
        ],
        capture_output=True,
        text=True,
        timeout=180,  # 3 minutes max
        cwd=str(self.project_dir),
        stdin=subprocess.DEVNULL
        )

        if result.returncode == 0:
            try:
                response_data = json.loads(result.stdout)
                if isinstance(response_data, dict) and 'result' in response_data:
                    content = response_data['result']
                    # Verify it's actual CLAUDE.md content
                    if '# CLAUDE.md' in content:
                        return content
            except json.JSONDecodeError as e:
                print(f"Failed to parse Opus response: {e}", file=sys.stderr)

        return None

    def generate_template_only(self) -> str:
        """Generate minimal template when Opus unavailable."""
        return """# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

[Auto-generated minimal template - Claude Opus unavailable]

## Architecture

Explore the codebase to understand the structure.

## Common Commands

```bash
# Check git status
git status

# View recent commits
git log --oneline -10
```

## Key Workflows

1. Explore the codebase to understand patterns
2. Check existing files for conventions
3. Follow established directory structure

## Important Patterns

Check existing code for patterns and conventions used in this repository.
"""

    def discover_layers(self) -> bool:
        """Phase 1: Discover architectural layers using Claude CLI."""
        try:
            # Prepare discovery prompt
            discovery_prompt = """Analyze this codebase and identify its architectural layers.

You may explain your findings, but you MUST end your response with a valid JSON object in this exact format:

```json
{
  "layers": [
    {"name": "Skills System", "directories": ["skills/"], "description": "Workflow documentation system", "technologies": ["Markdown", "YAML"]},
    {"name": "Hooks System", "directories": ["hooks/"], "description": "Session lifecycle automation", "technologies": ["Bash", "Python"]}
  ],
  "cross_cutting": {
    "authentication": "path/to/auth or N/A",
    "logging": "path/to/logging or N/A",
    "configuration": "path/to/config or N/A",
    "testing": "path/to/tests or N/A"
  }
}
```

Identify ALL distinct architectural layers. Look beyond conventional patterns (API/services/models) - this could be a skills system, plugin architecture, CLI tool, documentation system, etc.

END YOUR RESPONSE WITH THE JSON CODE BLOCK ABOVE (filled with actual findings)."""

            # Try agent-based discovery via Claude CLI
            if self.claude_cli_available:
                print("Using Claude CLI for intelligent layer discovery...", file=sys.stderr)
                agent_response = self._invoke_claude_agent(discovery_prompt, max_turns=5, timeout=90)

                if agent_response:
                    # Parse JSON response - try multiple strategies
                    try:
                        data = None

                        # Strategy 1: Direct JSON parsing
                        try:
                            data = json.loads(agent_response)
                        except json.JSONDecodeError:
                            pass

                        # Strategy 2: Extract from markdown code block
                        if not data:
                            json_match = re.search(r'```json\s*(\{.*?\})\s*```', agent_response, re.DOTALL)
                            if json_match:
                                try:
                                    data = json.loads(json_match.group(1))
                                except json.JSONDecodeError:
                                    pass

                        # Strategy 3: Find last complete JSON object with "layers" key
                        if not data:
                            # Match nested JSON objects properly
                            pattern = r'\{(?:[^{}]|(?:\{(?:[^{}]|(?:\{[^{}]*\}))*\}))*"layers"(?:[^{}]|(?:\{(?:[^{}]|(?:\{[^{}]*\}))*\}))*\}'
                            matches = list(re.finditer(pattern, agent_response, re.DOTALL))
                            if matches:
                                # Try last match first (most likely to be the final answer)
                                for match in reversed(matches):
                                    try:
                                        data = json.loads(match.group(0))
                                        if 'layers' in data:
                                            break
                                    except json.JSONDecodeError:
                                        continue

                        # Strategy 4: Extract from natural language (parse manually)
                        if not data:
                            # Look for explicit layer mentions in text
                            layers = self._extract_layers_from_text(agent_response)
                            if layers:
                                data = {'layers': layers, 'cross_cutting': {}}

                        if data and 'layers' in data and data['layers']:
                            self.layers = data['layers']
                            self.cross_cutting = data.get('cross_cutting', {})
                            print(f"✓ Discovered {len(self.layers)} layers via agent", file=sys.stderr)
                            return True
                        else:
                            print(f"⚠ No valid layer data in agent response", file=sys.stderr)

                    except Exception as e:
                        print(f"Failed to parse agent response: {e}", file=sys.stderr)

            # Fallback to static discovery
            print("Falling back to static discovery...", file=sys.stderr)
            self.layers = self.static_layer_discovery()

            if not self.layers:
                print("Warning: No layers discovered, using fallback", file=sys.stderr)
                self.layers = self.fallback_layers()

            return len(self.layers) > 0

        except Exception as e:
            print(f"Layer discovery failed: {e}", file=sys.stderr)
            self.layers = self.fallback_layers()
            return False

    def _extract_layers_from_text(self, text: str) -> List[Dict]:
        """Extract layer information from natural language response."""
        layers = []

        # Look for common patterns like "**Layer Name** - description"
        # or "- **directory/** - description"
        layer_patterns = [
            r'\*\*([^*]+)\*\*\s*(?:\(`([^`]+)`\))?\s*[-:]\s*([^\n]+)',
            r'-\s*\*\*([^*]+)/\*\*\s*[-:]\s*([^\n]+)',
        ]

        for pattern in layer_patterns:
            matches = re.findall(pattern, text)
            for match in matches:
                if len(match) >= 2:
                    name = match[0].strip()
                    description = match[-1].strip()
                    directories = [match[1]] if len(match) > 2 and match[1] else [name.lower().replace(' ', '-') + '/']

                    layers.append({
                        'name': name,
                        'directories': directories,
                        'description': description,
                        'technologies': []
                    })

        return layers[:10]  # Limit to 10 layers max

    def static_layer_discovery(self) -> List[Dict]:
        """Temporary: Discover layers via filesystem analysis."""
        layers = []

        # Common patterns to look for
        patterns = {
            'API Layer': ['api/', 'routes/', 'controllers/', 'endpoints/'],
            'Business Logic': ['services/', 'domain/', 'core/', 'business/'],
            'Data Layer': ['models/', 'repositories/', 'db/', 'database/'],
            'Frontend': ['components/', 'pages/', 'views/', 'ui/', 'frontend/'],
            'Infrastructure': ['docker/', 'k8s/', 'terraform/', '.github/'],
            'Configuration': ['config/', 'settings/', '.env'],
            'Testing': ['tests/', 'test/', '__tests__/', 'spec/'],
        }

        for layer_name, directories in patterns.items():
            found_dirs = []
            for dir_pattern in directories:
                # Check both root and src/ subdirectory
                for base in ['', 'src/', 'lib/']:
                    check_path = self.project_dir / base / dir_pattern.rstrip('/')
                    if check_path.exists():
                        found_dirs.append(str(check_path.relative_to(self.project_dir)))

            if found_dirs:
                layers.append({
                    'name': layer_name,
                    'directories': found_dirs,
                    'description': f'{layer_name} implementation'
                })

        return layers

    def fallback_layers(self) -> List[Dict]:
        """Return minimal layer structure when discovery fails."""
        return [
            {
                'name': 'Monolithic',
                'directories': ['.'],
                'description': 'Single-layer application structure'
            }
        ]

    def analyze_layers(self):
        """Phase 2: Analyze each layer (parallel when agents available)."""
        # Prepare all layer prompts
        layer_prompts = []
        for layer in self.layers:
            prompt = f"""
Deep-dive into the {layer['name']} of this codebase:

Focus on: {', '.join(layer['directories'])}

Provide:
1. Key components and their roles
2. Important patterns/conventions
3. Common workflows
4. Notable files (with exact paths)
5. Dependencies and integrations

Be concise but complete (max 150 words).

Format as JSON:
{{
  "components": ["comp1", "comp2"],
  "patterns": ["pattern1", "pattern2"],
  "key_files": ["path/to/file1.ext", "path/to/file2.ext"],
  "technologies": ["tech1", "tech2"],
  "summary": "Brief description"
}}
"""
            layer_prompts.append((layer['name'], prompt))

        # Try parallel agent analysis via Claude CLI
        if self.claude_cli_available and len(layer_prompts) > 0:
            print(f"Analyzing {len(layer_prompts)} layers via Claude CLI...", file=sys.stderr)

            # Note: True parallel execution would require concurrent.futures
            # For now, run sequentially but with intelligent agent analysis
            for layer_name, prompt in layer_prompts:
                agent_response = self._invoke_claude_agent(prompt, max_turns=3, timeout=120)

                if agent_response:
                    try:
                        # Extract JSON from response
                        json_match = re.search(r'```json\s*(\{.*?\})\s*```', agent_response, re.DOTALL)
                        if json_match:
                            findings = json.loads(json_match.group(1))
                        else:
                            findings = json.loads(agent_response)

                        self.layer_findings[layer_name] = findings
                        print(f"  ✓ Analyzed {layer_name}", file=sys.stderr)
                    except json.JSONDecodeError:
                        # Fallback to static for this layer
                        print(f"  ⚠ Agent parse failed for {layer_name}, using static", file=sys.stderr)
                        layer_data = next((l for l in self.layers if l['name'] == layer_name), None)
                        if layer_data:
                            self.layer_findings[layer_name] = self.analyze_layer_static(layer_data)
                else:
                    # Fallback to static for this layer
                    layer_data = next((l for l in self.layers if l['name'] == layer_name), None)
                    if layer_data:
                        self.layer_findings[layer_name] = self.analyze_layer_static(layer_data)
        else:
            # Use static analysis when CLI unavailable
            print("Using static analysis (Claude CLI unavailable)...", file=sys.stderr)
            for layer in self.layers:
                self.layer_findings[layer['name']] = self.analyze_layer_static(layer)

    def analyze_layer_static(self, layer: Dict) -> Dict:
        """Temporary: Analyze layer via filesystem."""
        findings = {
            'name': layer['name'],
            'directories': layer['directories'],
            'key_files': [],
            'technologies': [],
            'patterns': []
        }

        # Find key files in layer directories
        for dir_path in layer['directories']:
            full_path = self.project_dir / dir_path
            if full_path.exists() and full_path.is_dir():
                # TODO(review): Extract file patterns to class constant for easier maintenance (reported by code-reviewer on 2025-11-22, severity: Low)
                # Look for important files
                for pattern in ['*.py', '*.js', '*.ts', '*.go', '*.java']:
                    # TODO(review): Document magic number 3 as MAX_EXAMPLE_FILES constant (reported by code-reviewer on 2025-11-22, severity: Low)
                    files = list(full_path.glob(pattern))[:3]  # Limit to 3 examples
                    for f in files:
                        rel_path = f.relative_to(self.project_dir)
                        findings['key_files'].append(str(rel_path))

        return findings

    def synthesize_content(self) -> str:
        """Phase 3: Generate CLAUDE.md content."""
        # Prepare synthesis data
        synthesis_data = {
            "repository_path": str(self.project_dir),
            "layers": self.layers,
            "layer_findings": self.layer_findings,
            "timestamp": time.strftime("%Y-%m-%d %H:%M:%S")
        }

        # Synthesis prompt
        synthesis_prompt = f"""
You are generating a CLAUDE.md file for this repository.

INPUT DATA:
{json.dumps(synthesis_data, indent=2)}

CONSTRAINTS:
- Maximum 500 lines (HARD LIMIT)
- Token-conscious (this file gets re-injected every prompt)
- Actionable and practical (not generic)

REQUIRED SECTIONS:
1. Repository Overview (2-3 sentences max)
2. Architecture (layer-by-layer breakdown)
3. Common Commands (git, build, test, deploy)
4. Key Workflows (how developers work in this repo)
5. Important Patterns (conventions, anti-patterns)

STYLE:
- Concise bullet points
- Use exact file paths
- Focus on "how to work in this repo" not "what this repo does"
- Prioritize information Claude needs to write good code here

Generate the complete CLAUDE.md content now. Start with:
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.
"""

        # Try agent-based synthesis via Claude CLI
        if self.claude_cli_available:
            print("Synthesizing CLAUDE.md via Claude CLI...", file=sys.stderr)
            agent_response = self._invoke_claude_agent(synthesis_prompt, max_turns=5, timeout=120)

            if agent_response:
                # Agent should return the complete CLAUDE.md content
                # Check if it starts with expected header
                if '# CLAUDE.md' in agent_response:
                    print("  ✓ Agent synthesis successful", file=sys.stderr)
                    return agent_response
                else:
                    print("  ⚠ Agent synthesis invalid format, using template", file=sys.stderr)

        # Fallback to template generation
        print("Using template generation...", file=sys.stderr)
        return self.generate_enhanced_template(synthesis_data)

    def generate_enhanced_template(self, data: Dict) -> str:
        """Enhanced template generation with richer content."""
        lines = []
        lines.append("# CLAUDE.md")
        lines.append("")
        lines.append("This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.")
        lines.append("")
        lines.append("## Repository Overview")
        lines.append("")

        # Determine main technologies
        all_techs = set()
        for findings in self.layer_findings.values():
            if 'technologies' in findings:
                all_techs.update(findings.get('technologies', []))

        if all_techs:
            lines.append(f"Repository using {', '.join(list(all_techs)[:3])} with {len(self.layers)}-layer architecture.")
        else:
            lines.append(f"Repository with {len(self.layers)}-layer architecture. [Auto-generated documentation]")

        lines.append("")
        lines.append("## Architecture")
        lines.append("")
        lines.append("### Core Components")
        lines.append("")

        for layer in self.layers:
            findings = self.layer_findings.get(layer['name'], {})
            lines.append(f"**{layer['name']}** (`{', '.join(layer['directories'])}`)")
            lines.append(f"- {layer['description']}")

            if findings.get('key_files'):
                lines.append("- Notable files:")
                for f in findings['key_files'][:5]:  # Limit to 5 files
                    lines.append(f"  - `{f}`")

            if findings.get('patterns'):
                lines.append(f"- Patterns: {', '.join(findings['patterns'][:3])}")

            lines.append("")

        # Add cross-cutting concerns if found
        lines.append("### Cross-Cutting Concerns")
        lines.append("")
        lines.append("- **Configuration:** Check for .env, config/ directories")
        lines.append("- **Testing:** Look for test/, tests/, or __tests__/ directories")
        lines.append("- **Documentation:** Check README.md and docs/ directory")
        lines.append("")

        lines.append("## Common Commands")
        lines.append("")
        lines.append("### Git Operations")
        lines.append("```bash")
        lines.append("# Check status")
        lines.append("git status")
        lines.append("")
        lines.append("# View recent commits")
        lines.append("git log --oneline -10")
        lines.append("")
        lines.append("# Create feature branch")
        lines.append("git checkout -b feature/your-feature")
        lines.append("```")
        lines.append("")

        # Add package manager commands if detected
        if (self.project_dir / "package.json").exists():
            lines.append("### Node.js/npm")
            lines.append("```bash")
            lines.append("# Install dependencies")
            lines.append("npm install")
            lines.append("")
            lines.append("# Run development server")
            lines.append("npm run dev")
            lines.append("")
            lines.append("# Run tests")
            lines.append("npm test")
            lines.append("```")
            lines.append("")

        if (self.project_dir / "requirements.txt").exists() or (self.project_dir / "pyproject.toml").exists():
            lines.append("### Python")
            lines.append("```bash")
            lines.append("# Install dependencies")
            lines.append("pip install -r requirements.txt")
            lines.append("")
            lines.append("# Run tests")
            lines.append("pytest")
            lines.append("```")
            lines.append("")

        lines.append("## Key Workflows")
        lines.append("")
        lines.append("### Working in This Repository")
        lines.append("1. Review this CLAUDE.md for repository context")
        lines.append("2. Check existing code patterns in similar files")
        lines.append("3. Follow directory structure conventions")
        lines.append("4. Run tests before committing changes")
        lines.append("")

        if len(self.layers) > 1:
            lines.append("### Adding New Features")
            lines.append("1. Identify the appropriate layer for your changes")
            lines.append("2. Follow existing patterns in that layer")
            lines.append("3. Update tests accordingly")
            lines.append("4. Document significant changes")
            lines.append("")

        lines.append("## Important Patterns")
        lines.append("")
        lines.append("### Code Organization")
        for layer in self.layers[:3]:  # Show first 3 layers
            lines.append(f"- **{layer['name']}:** {', '.join(layer['directories'])}")
        lines.append("")

        lines.append("### Anti-Patterns to Avoid")
        lines.append("- Creating files without checking existing patterns first")
        lines.append("- Mixing concerns across architectural layers")
        lines.append("- Skipping tests for new functionality")
        lines.append("- Committing without reviewing changes")
        lines.append("")

        lines.append("---")
        lines.append("")
        lines.append(f"*Generated on {data['timestamp']} by CLAUDE.md Bootstrap*")

        return '\n'.join(lines)

    def write_claude_md(self, content: str) -> bool:
        """Validate and write CLAUDE.md to disk."""
        lines = content.split('\n')

        # Enforce line limit
        if len(lines) > MAX_LINES:
            lines = lines[:MAX_LINES]
            lines.append("... (truncated to 500 lines)")
            content = '\n'.join(lines)

        # Write file
        claude_md_path = self.project_dir / 'CLAUDE.md'
        try:
            claude_md_path.write_text(content, encoding='utf-8')
            # Set secure permissions (owner read/write only)
            os.chmod(claude_md_path, 0o600)
            return True
        except Exception as e:
            print(f"Failed to write CLAUDE.md: {e}", file=sys.stderr)
            return False

    def write_fallback_template(self):
        """Write minimal fallback template on error."""
        fallback = """# CLAUDE.md

This file provides guidance to Claude Code when working in this repository.

## Repository Overview

[Auto-generated CLAUDE.md - bootstrap process encountered errors]

## Architecture

[Analysis incomplete - delete this file to trigger regeneration on next session]

## Common Commands

```bash
# Check git status
git status

# View recent commits
git log --oneline -10
```

## Notes

This CLAUDE.md was auto-generated but the analysis process failed.
You can:
- Edit this file manually with repository-specific guidance
- Delete this file to trigger regeneration on next session start
- Check hook logs for error details
"""

        claude_md_path = self.project_dir / 'CLAUDE.md'
        try:
            claude_md_path.write_text(fallback, encoding='utf-8')
            # Set secure permissions (owner read/write only)
            os.chmod(claude_md_path, 0o600)
        except Exception as e:
            # Log exception instead of silently swallowing
            print(f"Warning: Failed to write fallback CLAUDE.md: {e}", file=sys.stderr)


def main():
    """Main entry point."""
    orchestrator = BootstrapOrchestrator(PROJECT_DIR)
    success = orchestrator.run()
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
