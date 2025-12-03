---
name: dev-import-tasks
description: |
  Gate 0 of the development cycle - parses markdown task files, extracts structured
  task data, and validates required fields. Produces a validated task list for
  subsequent gates.

trigger: |
  - Starting Gate 0 of development-cycle
  - Need to parse a markdown file with development tasks
  - Converting human-readable tasks to structured format

skip_when: |
  - Tasks already parsed and in state -> proceed to Gate 1
  - Not a markdown task file -> use appropriate parser
  - Resuming cycle with valid state -> skip to current gate

sequence:
  before: [dev-analysis]

related:
  complementary: [development-cycle, dev-analysis]
---

# Dev Import Tasks (Gate 0)

## Overview

This skill parses markdown files containing development tasks and produces a validated, structured list. It enforces required fields and warns about missing optional fields that will need to be inferred.

**Announce at start:** "I'm using the dev-import-tasks skill to parse and validate the task file."

## Expected Input Format

The skill expects a markdown file with tasks in this format:

```markdown
## Task: ID - Title

### Requisitos Funcionais
- Functional requirement 1
- Functional requirement 2

### Requisitos Tecnicos
- Technical specification 1
- Technical specification 2

### Criterios de Aceitacao
- [ ] Acceptance criterion 1
- [ ] Acceptance criterion 2
- [ ] Acceptance criterion 3

### Referencias
- PRD: path/to/prd.md
- TRD: path/to/trd.md
- API: path/to/api-spec.yaml
```

### Alternate Header Formats (Also Supported)

The parser also accepts these variations:

| Section | Alternate Names |
|---------|-----------------|
| Requisitos Funcionais | Functional Requirements, Requirements, Funcional |
| Requisitos Tecnicos | Technical Requirements, Tech Requirements, Tecnico |
| Criterios de Aceitacao | Acceptance Criteria, Criteria, AC, Done When |
| Referencias | References, Refs, Links, Related Docs |

## Step 1: Load and Validate File

```
1. Receive file path from orchestrator
2. Verify file exists
3. Verify file extension is .md
4. Read file contents
5. Verify file is not empty
```

**On file not found:**
```
ERROR: Task file not found
Path: [provided_path]
Action: Verify the path is correct and the file exists.
```

**On empty file:**
```
ERROR: Task file is empty
Path: [provided_path]
Action: Add tasks to the file using the expected format.
```

## Step 2: Parse Tasks

### Task Detection Pattern

Look for task headers matching:
- `## Task: ID - Title`
- `## Task ID: Title`
- `## ID - Title`
- `## ID: Title`

Extract:
- **ID**: First alphanumeric identifier (e.g., TASK-001, T001, 1)
- **Title**: Remaining text after ID separator (- or :)

### Section Parsing

For each detected task, extract sections:

```python
task = {
    "id": extracted_id,
    "title": extracted_title,
    "functional_requirements": [],  # From Requisitos Funcionais
    "technical_requirements": [],   # From Requisitos Tecnicos
    "acceptance_criteria": [],      # From Criterios de Aceitacao
    "references": {}                # From Referencias
}
```

**Parsing rules:**
- List items: Lines starting with `- ` or `* `
- Checkbox items: Lines starting with `- [ ]` or `- [x]`
- Key-value references: Lines matching `- Key: value`
- Continue until next `##` header or EOF

## Step 3: Validate Required Fields

### Required Fields (ERROR if missing)

| Field | Validation | Error Message |
|-------|------------|---------------|
| id | Non-empty string | "Task missing ID - cannot track without identifier" |
| title | Non-empty string | "Task [id] missing title - cannot proceed without description" |
| acceptance_criteria | At least 1 item | "Task [id] missing acceptance criteria - cannot validate without criteria" |

### Optional Fields (WARNING if missing)

| Field | Warning | Inference Note |
|-------|---------|----------------|
| functional_requirements | "Task [id] missing functional requirements - will infer from title and criteria" | Can be inferred from title context |
| technical_requirements | "Task [id] missing technical requirements - will be determined during analysis" | Determined in Gate 1 (Analysis) |
| references | "Task [id] has no references - context may be limited" | Not required but helpful |

## Step 4: Build Output Structure

For each validated task, produce:

```json
{
  "id": "TASK-001",
  "title": "Implement user authentication endpoint",
  "status": "pending",
  "functional_requirements": [
    "User can login with email and password",
    "User receives JWT token on successful login",
    "Invalid credentials return 401 error"
  ],
  "technical_requirements": [
    "Use bcrypt for password hashing",
    "JWT expiration: 15 minutes",
    "Refresh token expiration: 7 days"
  ],
  "acceptance_criteria": [
    {"text": "Login endpoint returns 200 with valid credentials", "checked": false},
    {"text": "Login endpoint returns 401 with invalid credentials", "checked": false},
    {"text": "JWT contains user ID and role claims", "checked": false}
  ],
  "references": {
    "PRD": "docs/prd/auth.md",
    "TRD": "docs/trd/auth.md",
    "API": "docs/api/auth.yaml"
  },
  "validation": {
    "has_functional_requirements": true,
    "has_technical_requirements": true,
    "has_acceptance_criteria": true,
    "has_references": true,
    "warnings": []
  }
}
```

## Step 5: Generate Import Report

Produce a summary for the orchestrator:

```json
{
  "status": "success|warning|error",
  "source_file": "path/to/tasks.md",
  "parsed_at": "ISO timestamp",
  "summary": {
    "total_tasks": 5,
    "valid_tasks": 5,
    "tasks_with_warnings": 2,
    "tasks_with_errors": 0
  },
  "tasks": [
    // Array of validated task objects
  ],
  "warnings": [
    {"task_id": "TASK-003", "message": "Missing technical requirements"},
    {"task_id": "TASK-004", "message": "Missing functional requirements"}
  ],
  "errors": []
}
```

## Error Handling

### Parse Errors

```
When a task cannot be parsed:

1. Log the error with context:
   - Line number where parsing failed
   - Expected format vs actual content
   - Suggestion for fix

2. Continue parsing remaining tasks

3. Include in errors array:
   {
     "task_id": "unknown",
     "line": 45,
     "message": "Could not parse task header",
     "context": "## This is not a valid task header",
     "suggestion": "Use format: ## Task: ID - Title"
   }
```

### Validation Errors

```
When a task fails validation:

1. If missing required field:
   - Add to errors array
   - Do NOT include task in output
   - Set status = "error"

2. If missing optional field:
   - Add to warnings array
   - Include task in output with validation.warnings
   - Set status = "warning"
```

### Fatal Errors

```
When import cannot proceed:

1. No tasks found in file:
   ERROR: No tasks found in file
   Path: [file_path]
   Expected: At least one task header (## Task: ID - Title)
   Action: Add tasks using the expected format

2. All tasks have errors:
   ERROR: All tasks failed validation
   Total: [count] tasks
   Errors: [error list]
   Action: Fix the listed errors and retry
```

## Example: Complete Import

### Input File (tasks.md)

```markdown
# Sprint 23 Tasks

## Task: AUTH-001 - Implement login endpoint

### Requisitos Funcionais
- User can login with email and password
- Returns JWT token on success
- Returns error on invalid credentials

### Requisitos Tecnicos
- Use bcrypt for password hashing
- JWT expires in 15 minutes
- Implement rate limiting (5 attempts/minute)

### Criterios de Aceitacao
- [ ] POST /api/auth/login returns 200 with valid credentials
- [ ] POST /api/auth/login returns 401 with invalid credentials
- [ ] Response includes access_token and refresh_token
- [ ] Rate limiting triggers after 5 failed attempts

### Referencias
- PRD: docs/prd/authentication.md
- TRD: docs/trd/authentication.md

## Task: AUTH-002 - Implement logout endpoint

### Requisitos Funcionais
- User can logout and invalidate session

### Criterios de Aceitacao
- [ ] POST /api/auth/logout invalidates current token
- [ ] Subsequent requests with token return 401
```

### Output

```json
{
  "status": "warning",
  "source_file": "tasks.md",
  "parsed_at": "2025-12-03T12:30:00Z",
  "summary": {
    "total_tasks": 2,
    "valid_tasks": 2,
    "tasks_with_warnings": 1,
    "tasks_with_errors": 0
  },
  "tasks": [
    {
      "id": "AUTH-001",
      "title": "Implement login endpoint",
      "status": "pending",
      "functional_requirements": [
        "User can login with email and password",
        "Returns JWT token on success",
        "Returns error on invalid credentials"
      ],
      "technical_requirements": [
        "Use bcrypt for password hashing",
        "JWT expires in 15 minutes",
        "Implement rate limiting (5 attempts/minute)"
      ],
      "acceptance_criteria": [
        {"text": "POST /api/auth/login returns 200 with valid credentials", "checked": false},
        {"text": "POST /api/auth/login returns 401 with invalid credentials", "checked": false},
        {"text": "Response includes access_token and refresh_token", "checked": false},
        {"text": "Rate limiting triggers after 5 failed attempts", "checked": false}
      ],
      "references": {
        "PRD": "docs/prd/authentication.md",
        "TRD": "docs/trd/authentication.md"
      },
      "validation": {
        "has_functional_requirements": true,
        "has_technical_requirements": true,
        "has_acceptance_criteria": true,
        "has_references": true,
        "warnings": []
      }
    },
    {
      "id": "AUTH-002",
      "title": "Implement logout endpoint",
      "status": "pending",
      "functional_requirements": [
        "User can logout and invalidate session"
      ],
      "technical_requirements": [],
      "acceptance_criteria": [
        {"text": "POST /api/auth/logout invalidates current token", "checked": false},
        {"text": "Subsequent requests with token return 401", "checked": false}
      ],
      "references": {},
      "validation": {
        "has_functional_requirements": true,
        "has_technical_requirements": false,
        "has_acceptance_criteria": true,
        "has_references": false,
        "warnings": [
          "Missing technical requirements - will be determined during analysis",
          "No references provided - context may be limited"
        ]
      }
    }
  ],
  "warnings": [
    {"task_id": "AUTH-002", "message": "Missing technical requirements - will be determined during analysis"},
    {"task_id": "AUTH-002", "message": "No references provided - context may be limited"}
  ],
  "errors": []
}
```

## Execution Report

| Metric | Value |
|--------|-------|
| Duration | Xm Ys |
| Iterations | 1 |
| Result | PASS/WARNING/FAIL |

### Details
- source_file: [path]
- total_tasks: [count]
- valid_tasks: [count]
- tasks_with_warnings: [count]
- tasks_with_errors: [count]

### Issues Encountered
- [List of warnings and errors]
- Or "None"

### Handoff to Next Gate
- Gate 1 (Analysis) receives: [count] validated tasks
- Tasks requiring inference: [list of task IDs with missing optional fields]
- Ready to proceed: [yes/no]
- Blocking issues: [list or "none"]
