---
name: ring:dev-licensing
description: |
  Apply or switch the license for a Lerian service repository. Supports Apache 2.0,
  Elastic License v2, and Proprietary (Lerian Studio General License). Replaces/creates
  LICENSE file, updates source file headers, updates SPDX identifiers, validates consistency.
---

# License Management

## When to use
- User requests to set, apply, or switch a license on a repository
- Scaffolding a new service from the boilerplate
- Task mentions "license", "licensing", "license header", "Apache 2.0", "ELv2", "proprietary"
- Gate 0 of dev-cycle when no LICENSE file exists

## Skip when
- Repository already has requested license AND all headers match AND SPDX is correct (verified)
- Non-code repositories (documentation-only, design assets)

## Related
**Complementary:** ring:dev-cycle, ring:dev-implementation


You orchestrate. Agents update source headers. NEVER apply a license without user confirmation.

## License Types

| License | SPDX | Use Case |
|---------|------|----------|
| Apache 2.0 | `Apache-2.0` | Open source (e.g., Midaz core) |
| Elastic License v2 | `Elastic-2.0` | Source-available Lerian products |
| Proprietary | `LicenseRef-Lerian-Proprietary` | Internal/closed repositories |

## Header Templates

### Apache 2.0 — Go
```go
// Copyright (c) {YEAR} {COPYRIGHT_HOLDER}
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
```

### Elastic License v2 — Go
```go
// Copyright (c) {YEAR} {COPYRIGHT_HOLDER}
// Use of this source code is governed by the Elastic License 2.0
// that can be found in the LICENSE file.
```

### Proprietary — Go
```go
// Copyright (c) {YEAR} {COPYRIGHT_HOLDER}. All rights reserved.
// This source code is proprietary and confidential.
// Unauthorized copying of this file is strictly prohibited.
```

TypeScript: wrap the same text in `/** ... */`.

## Gate 0: Detection

Orchestrator runs directly:

```bash
# 1. Detect LICENSE file
ls LICENSE LICENSE.md LICENSE.txt 2>/dev/null
head -5 LICENSE 2>/dev/null

# 2. Identify type
grep -l "Apache License" LICENSE* 2>/dev/null → apache
grep -l "Elastic License" LICENSE* 2>/dev/null → elv2
grep -l "All rights reserved" LICENSE* 2>/dev/null → proprietary

# 3. Sample current source headers
head -5 $(find . -name "*.go" ! -path "*/vendor/*" ! -name "*.pb.go" | head -5)
head -5 $(find . -name "*.ts" ! -path "*/node_modules/*" | head -5)

# 4. Detect language
test -f go.mod && echo "Go project"
test -f package.json && echo "TypeScript project"
```

Determine:
- `current_license`: apache | elv2 | proprietary | none
- `language`: go | typescript | both
- `copyright_holder`: from existing headers or Lerian Studio default
- `year`: current year

## Gate 1: User Confirmation

Present summary and wait for explicit APPROVED:

```
Current license: {current_license}
Target license: {target_license}
Language: {language}
Copyright: {copyright_holder} ({year})

Changes:
- LICENSE file: CREATE/REPLACE with {target_license}
- Source headers: UPDATE {N} files
- README badge: UPDATE

Proceed? (APPROVED / CANCEL)
```

STOP if user does not confirm.

## Gate 2: Implementation

After confirmation:

**1. Replace LICENSE file** (orchestrator writes directly):
- Apache 2.0: fetch from https://www.apache.org/licenses/LICENSE-2.0.txt
- ELv2: write canonical ELv2 text
- Proprietary: write Lerian General License text

**2. Update source headers** (dispatch agent):

```yaml
Task:
  subagent_type: "ring:backend-engineer-{language}"
  description: "Update license headers to {target_license}"
  prompt: |
    Update all source file headers to {target_license} format.
    Copyright: {copyright_holder}, {year}
    
    Files to update:
    - Go: find . -name "*.go" ! -path "*/vendor/*" ! -name "*.pb.go" ! -name "*/mocks/*"
    - TS: find . -name "*.ts" -o -name "*.tsx" ! -path "*/node_modules/*"
    
    Header template: {header_template}
    
    For each file:
    1. Remove existing copyright block (first comment block if it mentions Copyright)
    2. Add new header at top of file
    3. Preserve package declaration and imports
    
    Output: list of files updated
```

## Gate 3: Validation

Orchestrator runs:

```bash
# All files should have consistent headers
grep -rL "Copyright (c)" $(find . -name "*.go" ! -path "*/vendor/*" ! -name "*.pb.go")
grep -rL "Copyright (c)" $(find . -name "*.ts" ! -path "*/node_modules/*")

# LICENSE file exists and has correct type
head -3 LICENSE | grep -i "{target_keyword}"
```

Report:
- Files missing headers: list
- LICENSE file status: PASS/FAIL
- Consistency: PASS/FAIL (if mismatches found, dispatch agent to fix)
