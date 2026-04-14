---
name: ring:dev-licensing
slug: dev-licensing
version: 1.0.0
type: skill
description: |
  Apply or switch the license for a Lerian service repository.
  Supports three license types: Apache 2.0 (open source, like Midaz core),
  Elastic License v2 (source-available, for Lerian products), and
  Proprietary (Lerian Studio General License, all rights reserved).
  Replaces/creates the LICENSE file, updates source file headers,
  updates SPDX identifiers, and validates consistency across the codebase.
  Licensing is per-app — decided case by case.

trigger: |
  - User requests to set, apply, or switch a license on a repository
  - User runs /ring:dev-license command
  - Scaffolding a new service from the boilerplate
  - Task mentions "license", "licensing", "license header", "Apache 2.0", "ELv2", "proprietary"
  - Gate 0 of dev-cycle when no LICENSE file exists or license is unknown

skip_when: |
  - Repository already has the requested license AND all source headers match AND SPDX identifiers are correct (verified, not assumed)
  - Non-code repositories (documentation-only, design assets)

prerequisite: |
  - Repository with source files (Go, TypeScript, or similar)
  - User has confirmed the desired license type

related:
  complementary: [ring:dev-cycle, ring:dev-implementation, ring:backend-engineer-golang, ring:backend-engineer-typescript]

input_schema:
  required: []
  optional:
    - name: license_type
      type: string
      enum: [apache, elv2, proprietary]
      description: "The license to apply. If omitted, the skill detects the current license from the repository or prompts the user interactively."
    - name: copyright_holder
      type: string
      default: "Lerian Studio Ltd."
      description: "Copyright holder name for headers and LICENSE file"
    - name: copyright_year
      type: string
      default: "current year"
      description: "Copyright year (defaults to current year)"
    - name: dry_run
      type: boolean
      default: false
      description: "Report what would change without modifying files"
    - name: source_dirs
      type: array
      items: string
      default: ["cmd/", "internal/", "pkg/", "src/", "app/", "lib/"]
      description: "Directories to scan for source files requiring headers"

output_schema:
  format: markdown
  required_sections:
    - name: "License Summary"
      pattern: "^## License Summary"
      required: true
    - name: "Changes Applied"
      pattern: "^## Changes Applied"
      required: true
    - name: "Validation Results"
      pattern: "^## Validation Results"
      required: true
  metrics:
    - name: result
      type: enum
      values: [PASS, FAIL]
    - name: files_updated
      type: integer
    - name: files_skipped
      type: integer
    - name: inconsistencies_found
      type: integer

examples:
  - name: "Apply Apache 2.0 license"
    invocation: "/ring:dev-license apache"
    expected_flow: |
      1. Detect current license (if any)
      2. Confirm change with user
      3. Write LICENSE file
      4. Update all .go source file headers
      5. Update SPDX identifiers in go.mod/package.json
      6. Update README.md badge/section
      7. Validate all files have consistent headers
  - name: "Switch from proprietary to ELv2"
    invocation: "/ring:dev-license elv2"
    expected_flow: |
      1. Detect current proprietary license
      2. Warn: switching from proprietary to source-available
      3. Confirm with user
      4. Replace LICENSE file
      5. Update all source headers
      6. Validate consistency
---

# License Management for Lerian Services

<cannot_skip>

## CRITICAL: This Skill ORCHESTRATES. Agents IMPLEMENT.

| Who | Responsibility |
|-----|----------------|
| **This Skill** | Detect current license, determine changes, validate results |
| **ring:backend-engineer-golang** | Update Go source file headers (when Go project) |
| **ring:backend-engineer-typescript** | Update TypeScript source file headers (when TS project) |

**CANNOT change license without user confirmation.**

**FORBIDDEN: Applying a license that the user did not explicitly choose.**

</cannot_skip>

---

## License Types

Lerian uses three license types, chosen per-app:

| License | SPDX Identifier | Use Case | Header Style |
|---------|-----------------|----------|--------------|
| **Apache 2.0** | `Apache-2.0` | Open source projects (e.g., Midaz core) | Copyright + Apache reference |
| **Elastic License v2** | `Elastic-2.0` | Source-available Lerian products | Copyright + ELv2 reference |
| **Proprietary** | `LicenseRef-Lerian-Proprietary` | Internal/closed repositories | Copyright + all rights reserved |

### License Header Templates

#### Apache 2.0 Header (for `.go` files)

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

package yourpackage
```

#### Elastic License v2 Header (for `.go` files)

```go
// Copyright (c) {YEAR} {COPYRIGHT_HOLDER}
// Use of this source code is governed by the Elastic License 2.0
// that can be found in the LICENSE file.

package yourpackage
```

#### Proprietary Header (for `.go` files)

```go
// Copyright (c) {YEAR} {COPYRIGHT_HOLDER}. All rights reserved.
// This source code is proprietary and confidential.
// Unauthorized copying of this file is strictly prohibited.

package yourpackage
```

### TypeScript/JavaScript Header Templates

#### Apache 2.0 Header (for `.ts`/`.js` files)

```typescript
/**
 * Copyright (c) {YEAR} {COPYRIGHT_HOLDER}
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
```

#### Elastic License v2 Header (for `.ts`/`.js` files)

```typescript
/**
 * Copyright (c) {YEAR} {COPYRIGHT_HOLDER}
 * Use of this source code is governed by the Elastic License 2.0
 * that can be found in the LICENSE file.
 */
```

#### Proprietary Header (for `.ts`/`.js` files)

```typescript
/**
 * Copyright (c) {YEAR} {COPYRIGHT_HOLDER}. All rights reserved.
 * This source code is proprietary and confidential.
 * Unauthorized copying of this file is strictly prohibited.
 */
```

---

## Gate 0: Detection

**Orchestrator executes directly. No agent dispatch.**

```text
DETECT (run in parallel):

1. LICENSE file:
   - ls LICENSE LICENSE.md LICENSE.txt 2>/dev/null
   - If found: read first 5 lines to identify type

2. Identify license type from LICENSE content:
   - grep -l "Apache License" LICENSE* → apache
   - grep -l "Elastic License" LICENSE* → elv2
   - grep -l "All rights reserved.*Lerian" LICENSE* → proprietary
   - grep -l "All rights reserved" LICENSE* → unknown-proprietary
   - No LICENSE file → none

3. Current source headers:
   - head -3 $(find . -name "*.go" -not -path "./vendor/*" -not -name "*.pb.go" | head -5)
   - head -5 $(find . -name "*.ts" -not -path "./node_modules/*" | head -5)

4. SPDX identifiers:
   - grep -i "license" go.mod 2>/dev/null
   - grep '"license"' package.json 2>/dev/null

5. README license section:
   - grep -i "license\|badge" README.md 2>/dev/null | head -10
```

**Output:**

```text
CURRENT LICENSE DETECTION:
| Component        | Status              | Evidence           |
|------------------|---------------------|--------------------|
| LICENSE file     | {type} / none       | {file path}        |
| Source headers   | {type} / mixed / none | {sample}         |
| SPDX identifier  | {value} / none      | {file:line}        |
| README section   | present / absent    | {line}             |
```

### License Type Resolution

If `license_type` was provided as input, use it directly.

If `license_type` was NOT provided (interactive mode):
1. Use the detected license from Gate 0 as the current state
2. Ask the user: "Detected current license: {detected_type}. Which license should this repository use? [apache|elv2|proprietary]"
3. Set `license_type` to the user's selection
4. If no LICENSE file was detected AND no type provided: ask user to choose before proceeding

**MUST have a resolved `license_type` before entering Gate 1.**

---

## Gate 1: Confirmation

**MUST confirm with user before making changes.**

If current license matches requested license:

```text
"This repository already uses {license_type}. Checking for consistency..."
→ Skip to Gate 3 (Validation only)
```

If current license differs from requested:

```text
"⚠️ LICENSE CHANGE DETECTED

Current: {current_license}
Requested: {requested_license}

This will:
- Replace LICENSE file
- Update headers in {N} source files
- Update SPDX identifiers

Proceed? [y/N]"
```

If no current license:

```text
"No license detected. Will apply {requested_license}.

This will:
- Create LICENSE file
- Add headers to {N} source files
- Set SPDX identifiers

Proceed? [y/N]"
```

**HARD GATE: MUST NOT proceed without explicit user confirmation.**

---

## Gate 2: Application

**Dispatch the appropriate agent based on project language.**

### Step 2.1: Write LICENSE File

**Orchestrator writes the LICENSE file directly** (no agent needed for a single file write).

Read the reference license text from `dev-team/skills/dev-licensing/references/`:

| License Type | Reference File | Output File |
|---|---|---|
| apache | `references/apache-2.0.txt` | `LICENSE` |
| elv2 | `references/elastic-v2.txt` | `LICENSE` |
| proprietary | `references/proprietary.txt` | `LICENSE` |

For **proprietary**, replace `{YEAR}` placeholder with the copyright year. For **apache**, the appendix contains `[yyyy]` and `[name of copyright owner]` — these are left as-is in the license body (the boilerplate notice at the bottom is informational). The actual copyright attribution goes in source file headers.

MUST remove any old LICENSE.md or LICENSE.txt if the new file is named `LICENSE` (and vice versa). Only one license file should exist.

### Step 2.2: Update Source File Headers

**Dispatch agent to update headers in all source files.**

For **Go projects**, dispatch `ring:backend-engineer-golang`:

> TASK: Update license headers in all .go source files to match the {license_type} license.
>
> LICENSE TYPE: {license_type}
> COPYRIGHT HOLDER: {copyright_holder}
> COPYRIGHT YEAR: {copyright_year}
>
> HEADER TEMPLATE (use this exact text):
> ```
> {header_template from License Header Templates section above}
> ```
>
> RULES:
> 1. Header MUST be the FIRST content in every .go file (before package declaration)
> 2. If an existing header exists (lines starting with `//` before `package`), REPLACE it entirely
> 3. If no header exists, ADD the header before the package declaration
> 4. Preserve a blank line between the header and the package declaration
> 5. DO NOT modify generated files (*.pb.go, mock_*.go)
> 6. DO NOT modify files in vendor/
> 7. Process ALL .go files in: cmd/, internal/, pkg/, and any other source directories
> 8. Include test files (*_test.go) — they are source code
>
> VERIFICATION: After updating, run:
> ```bash
> find . -name "*.go" -not -path "./vendor/*" -not -name "*.pb.go" -not -name "mock_*.go" \
>     -exec sh -c 'head -1 "$1" | grep -q "^// Copyright" || echo "MISSING: $1"' _ {} \;
> ```
> This MUST return zero results.

For **TypeScript projects**, dispatch `ring:backend-engineer-typescript`:

> TASK: Update license headers in all .ts/.js source files to match the {license_type} license.
>
> (Same structure as Go dispatch, adapted for TS/JS header format and file patterns.)
>
> RULES:
> 1. Header MUST be the FIRST content in every .ts/.js file (before imports)
> 2. If an existing header block comment exists (`/** ... */` before first import), REPLACE it
> 3. DO NOT modify files in node_modules/
> 4. DO NOT modify generated files (*.d.ts in build output)
> 5. Process ALL .ts/.js files in: src/, app/, lib/
> 6. Include test files (*.test.ts, *.spec.ts)

### Step 2.3: Update SPDX Identifiers

**Orchestrator updates SPDX identifiers directly** (simple text replacements).

| File | Field | Apache 2.0 | ELv2 | Proprietary |
|------|-------|------------|------|-------------|
| `go.mod` | (comment at top, if convention used) | `// SPDX-License-Identifier: Apache-2.0` | `// SPDX-License-Identifier: Elastic-2.0` | `// SPDX-License-Identifier: LicenseRef-Lerian-Proprietary` |
| `package.json` | `"license"` | `"Apache-2.0"` | `"Elastic-2.0"` | `"SEE LICENSE IN LICENSE"` |

If the file does not already have an SPDX field, add one only if the project convention supports it. Do not force SPDX into `go.mod` if no comment convention exists.

### Step 2.4: Update README.md

If README.md contains a license badge or section, update it:

**Badge patterns to detect and replace:**

```markdown
<!-- Apache 2.0 -->
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

<!-- ELv2 -->
[![License](https://img.shields.io/badge/License-Elastic_2.0-blue.svg)](https://www.elastic.co/licensing/elastic-license)

<!-- Proprietary -->
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)](./LICENSE)
```

**License section pattern:**

```markdown
## License

This project is licensed under the {LICENSE_NAME} — see the [LICENSE](./LICENSE) file for details.
```

| License Type | LICENSE_NAME |
|---|---|
| apache | Apache License 2.0 |
| elv2 | Elastic License 2.0 (ELv2) |
| proprietary | Lerian Studio General License |

If no license section or badge exists in README.md, do NOT add one. Only update existing references.

---

## Gate 3: Validation

**Orchestrator executes directly. MUST pass before reporting success.**

```text
VALIDATE (run in parallel):

V1. LICENSE file exists and matches requested type:
    - ls LICENSE && head -3 LICENSE
    - Verify content matches reference

V2. No duplicate license files:
    - ls LICENSE LICENSE.md LICENSE.txt 2>/dev/null | wc -l
    - MUST be exactly 1

V3. Source headers consistent:
    - For Go:
      find . -name "*.go" -not -path "./vendor/*" -not -name "*.pb.go" -not -name "mock_*.go" \
          -exec sh -c 'head -1 "$1" | grep -q "^// Copyright" || echo "MISSING: $1"' _ {} \;
    - MUST return 0 results

V4. No mixed headers (old license headers remaining):
    - For apache: grep -rn "Elastic License" --include="*.go" --exclude-dir=vendor | grep -v "_test.go" → 0 results
    - For elv2: grep -rn "Apache License" --include="*.go" --exclude-dir=vendor | grep -v "_test.go" → 0 results
    - For proprietary: grep -rn "Apache License\|Elastic License" --include="*.go" --exclude-dir=vendor → 0 results

V5. SPDX consistency (if identifiers exist):
    - grep -i "license" go.mod package.json 2>/dev/null
    - Verify matches requested type

V6. Build verification:
    - go build ./... (Go projects)
    - npm run build / tsc --noEmit (TS projects)
    - Headers MUST NOT break compilation
```

**Validation output:**

```text
VALIDATION RESULTS:
| Check            | Status | Evidence |
|------------------|--------|----------|
| LICENSE file     | PASS/FAIL | {details} |
| No duplicates    | PASS/FAIL | {count} |
| Headers present  | PASS/FAIL | {missing count} |
| No mixed headers | PASS/FAIL | {conflicts} |
| SPDX identifiers | PASS/FAIL/N/A | {values} |
| Build passes     | PASS/FAIL | {output} |
```

**HARD GATE: All checks MUST pass. If any check fails, report the specific failures and dispatch the appropriate agent to fix them. Re-validate after fixes.**

---

## Severity Calibration

| Severity | Criteria | Examples |
|----------|----------|----------|
| **CRITICAL** | License mismatch between LICENSE file and source headers | Apache LICENSE with ELv2 headers, no LICENSE file at all |
| **HIGH** | Missing headers in source files, duplicate license files | .go files without copyright, both LICENSE and LICENSE.md present |
| **MEDIUM** | SPDX identifier mismatch, README badge outdated | go.mod says MIT but LICENSE is Apache |
| **LOW** | Missing README license section, style inconsistencies | No badge, minor formatting differences in headers |

---

## Pressure Resistance

| User Says | This Is | Response |
|-----------|---------|----------|
| "Just update the LICENSE file, skip headers" | SCOPE_REDUCTION | "CANNOT skip header updates. LICENSE file and source headers MUST match. Inconsistent headers create legal ambiguity." |
| "Headers don't matter, the LICENSE file is what counts" | COMPLIANCE_BYPASS | "Per-file headers provide clear attribution when code is copied or distributed. MUST update both." |
| "Skip validation, I trust it worked" | QUALITY_BYPASS | "MUST validate. Mixed headers from a previous license are common and only caught by automated scanning." |
| "Use MIT instead" | SCOPE_CHANGE | "Lerian uses three license types: Apache 2.0, ELv2, or Proprietary. MIT is not in the approved set. Confirm with legal if MIT is required." |
| "Don't touch test files" | SCOPE_REDUCTION | "Test files are source code. Same license headers apply. MUST include test files." |
| "The boilerplate license is fine, don't change it" | COMPLIANCE_BYPASS | "If the boilerplate has a generic proprietary license but the app should be Apache or ELv2, MUST update. License is per-app." |

---

## Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "LICENSE file is enough, headers are cosmetic" | Headers protect IP when files are extracted or redistributed. Legal requires both. | **Update both LICENSE and headers** |
| "Only new files need headers" | All source files need consistent headers. Partial coverage = legal risk. | **Update all source files** |
| "Generated files should get headers too" | Generated files are regenerated and headers would be overwritten. Exclude them. | **Skip *.pb.go, mock_*.go** |
| "Current headers are close enough" | Close ≠ correct. Headers MUST match the chosen license exactly. | **Replace with exact template** |
| "Small repo, licensing doesn't matter" | Size is irrelevant. Every Lerian repo needs clear licensing. | **Apply license to all repos** |
| "I'll add headers later" | Later = never. License MUST be set when the repo is created or changed. | **Apply now** |

---

## Integration with dev-cycle

### Pre-Gate-0 License Check

When `ring:dev-cycle` starts on a repository, it SHOULD check license status:

```text
PRE-GATE-0 LICENSE CHECK:

1. ls LICENSE LICENSE.md LICENSE.txt 2>/dev/null
2. If no LICENSE file exists:
   → Ask user: "No LICENSE file detected. Which license should this repository use? [apache|elv2|proprietary]"
   → Invoke ring:dev-licensing with the chosen type
3. If LICENSE file exists:
   → Detect type (grep patterns from Gate 0)
   → Log: "License detected: {type}"
   → Continue to Gate 0

This check is advisory — it does not block Gate 0 execution.
If the user declines to set a license, log a warning and proceed.
```

### Scaffolding Integration

When creating a new service from the boilerplate:

1. The boilerplate ships with a generic proprietary LICENSE.md
2. During initial setup, prompt: "What license should this service use? [apache|elv2|proprietary]"
3. Invoke `ring:dev-licensing` with the chosen type
4. This replaces the boilerplate LICENSE.md with the correct license

---

## When Implementation Is Not Needed

Signs that licensing is already compliant:

| Sign | Verification |
|------|-------------|
| LICENSE file matches requested type | `head -3 LICENSE` shows correct license |
| All source files have correct headers | `find` + `grep` returns 0 missing files |
| SPDX identifiers match (if present) | `grep` in go.mod/package.json matches |
| README badge/section matches (if present) | Visual inspection or grep |
| No mixed headers from previous license | Cross-license grep returns 0 results |

**MUST verify all signs before concluding "not needed". Assumption is not verification.**

---

## Reference Files

Full license texts are available at:

- `dev-team/skills/dev-licensing/references/apache-2.0.txt` — Apache License 2.0
- `dev-team/skills/dev-licensing/references/elastic-v2.txt` — Elastic License v2
- `dev-team/skills/dev-licensing/references/proprietary.txt` — Lerian Studio General License (update year as needed)

These files are the canonical source for LICENSE file content. MUST use these as-is (with year substitution for proprietary).
