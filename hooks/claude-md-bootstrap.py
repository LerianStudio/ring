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
                if isinstance(response_data, dict) and 'content' in response_data:
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
            # Phase 1: Layer Discovery
            print("[Phase 1] Discovering repository layers...", file=sys.stderr)
            if not self.discover_layers():
                print("Warning: Layer discovery failed, using fallback", file=sys.stderr)
                self.layers = self.fallback_layers()

            # Phase 2: Parallel Layer Analysis
            print(f"[Phase 2] Analyzing {len(self.layers)} layers...", file=sys.stderr)
            self.analyze_layers()

            # Phase 3: Synthesis
            print("[Phase 3] Synthesizing CLAUDE.md...", file=sys.stderr)
            content = self.synthesize_content()

            # Phase 4: Validation and Write
            print("[Phase 4] Validating and writing file...", file=sys.stderr)
            return self.write_claude_md(content)

        except Exception as e:
            print(f"Bootstrap failed: {e}", file=sys.stderr)
            self.write_fallback_template()
            return False

    def discover_layers(self) -> bool:
        """Phase 1: Discover architectural layers using Claude CLI."""
        try:
            # Prepare discovery prompt
            discovery_prompt = """Analyze this codebase's layered architecture:

1. Identify ALL architectural layers (e.g., skills system, hooks, commands, agents, API, business logic, data, UI, infrastructure)
2. For each layer, provide:
   - Layer name
   - Primary directories/files
   - Key responsibilities
   - Technologies used
3. Identify cross-cutting concerns (auth, logging, config, testing)

Format your response as valid JSON only (no markdown, no explanation):
{
  "layers": [
    {
      "name": "Layer Name",
      "directories": ["dir1/", "dir2/"],
      "description": "What this layer does",
      "technologies": ["tech1", "tech2"]
    }
  ],
  "cross_cutting": {
    "authentication": "path/to/auth",
    "logging": "path/to/logging",
    "configuration": "path/to/config",
    "testing": "test/ directories"
  }
}"""

            # Try agent-based discovery via Claude CLI
            if self.claude_cli_available:
                print("Using Claude CLI for intelligent layer discovery...", file=sys.stderr)
                agent_response = self._invoke_claude_agent(discovery_prompt, max_turns=3, timeout=30)

                if agent_response:
                    # Parse JSON response
                    try:
                        # Extract JSON from response (may contain markdown code blocks)
                        json_match = re.search(r'```json\s*(\{.*?\})\s*```', agent_response, re.DOTALL)
                        if json_match:
                            data = json.loads(json_match.group(1))
                        else:
                            # Try parsing entire response as JSON
                            data = json.loads(agent_response)

                        if 'layers' in data and data['layers']:
                            self.layers = data['layers']
                            self.cross_cutting = data.get('cross_cutting', {})
                            print(f"Discovered {len(self.layers)} layers via agent", file=sys.stderr)
                            return True
                    except json.JSONDecodeError as e:
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
                agent_response = self._invoke_claude_agent(prompt, max_turns=2, timeout=60)

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
            agent_response = self._invoke_claude_agent(synthesis_prompt, max_turns=5, timeout=60)

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
