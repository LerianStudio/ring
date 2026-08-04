---
name: ring:declaring-plugin-permissions
description: >-
  Interactively authoring an access-manager permission-declaration manifest
  (permissions.yaml) for the access-manager "inversão de responsabilidade": drives
  a plugin team through discovering its real Authorize() surface, normalizing every
  action to the SEMANTIC standard (never HTTP verbs), declaring roles/group grants
  and the M2M contract, then emits and validates a manifest that matches the
  lib-auth/v3 auth/declaration schema. Use when a plugin must publish its own
  permissions at boot (WireFromEnv) instead of the access-manager seed owning them,
  or when writing/fixing a permissions.yaml. Skip when the plugin has no auth guards,
  or you only need the wiring (see WireFromEnv) and the manifest already exists.
allowed-tools:
  - AskUserQuestion
  - Read
  - Grep
  - Glob
  - Write
  - Edit
  - Bash
---

# Declaring Plugin Permissions

Drive a Lerian plugin team through authoring `permissions.yaml` — the client-side,
SEMANTIC declaration the plugin PUBLISHES at boot under the access-manager
inversion. This is an **interactive workflow**: follow the steps in order and use
`AskUserQuestion` to gather every choice. Do not free-hand a manifest.

## Overview

Schema authority: `lib-auth/v3 auth/declaration/manifest.go` (>= `v3.4.0-beta.1`),
mirrored server-side by `plugin-access-manager identity/pkg/model/declaration.go`.
The reconciler validates this exact shape at boot and refuses a bad manifest.

**THE CRITICAL INVARIANT:** every `(resource, action)` pair in the manifest MUST
exactly match a real `AuthClient.Authorize(service, resource, action)` guard in the
plugin (`lib-auth auth/middleware/middleware.go`). If they diverge, authz silently
breaks — the guard demands a permission the manifest never declared. Adopting the
semantic standard therefore means the **route guards AND the manifest move together**.

- CANONICAL model (semantic, complies): `br-sisbajud`
  (`internal/auth/declaration/permissions.yaml`).
- ANTI-EXAMPLE (HTTP verbs, do NOT copy): `midaz-fees` — its guards pass
  `Authorize("plugin-fees","estimates","post")`. Legacy. Never emit verb actions.

## When to use
- A plugin must publish its own permissions at boot (inversion) — authoring a new
  `permissions.yaml`.
- Fixing or migrating a plugin whose guards/manifest use HTTP verbs to the semantic
  standard.

## Skip when
- The plugin has no `Authorize(...)` guards / no RBAC surface.
- Only the wiring is needed and the manifest already exists — point to
  `authdecl.WireFromEnv` and stop.

## The naming standard (non-negotiable)

The schema doc comment says verbatim: *"The action is SEMANTIC
(create/read/update/delete), never an HTTP verb."*

| HTTP verb (FORBIDDEN) | Semantic action (REQUIRED) |
|-----------------------|----------------------------|
| post   | create |
| get    | read |
| put / patch | update |
| delete (method) | delete / remove |

Domain verbs are first-class and encouraged where CRUD does not fit:
`rotate`, `trigger`, `justify`, `generate`, `reprocess`, `read_pii`,
`request_read`, `request_write`, `receive`. Keep them; do not force them into CRUD.

**This is ENFORCED, not just advised.** `post`/`get`/`put`/`patch` are rejected by
the lib-auth manifest validator at boot AND by the `check-manifest-actions` CI
guard (Step 9). Only `delete` among HTTP methods is allowed — it is also a valid
semantic action. Never emit `post`/`get`/`put`/`patch` as an `action`.

## Manifest schema (author against THIS)

Top-level YAML: `service` (str, REQUIRED), `version` (int, REQUIRED), `permissions`
(list), `roles` (list), `m2m` (object). All bare-name rules below: **the server
composes the prefix — never pre-prefix.**

| Field | Rule |
|-------|------|
| `service` | REQUIRED, non-empty, no `.`/`..` segment. KEEP any `plugin-` prefix. MUST equal the M2M app slug AND DisplayName (BOLA, enforced at boot). Also the 1st arg of `Authorize`. |
| `version` | REQUIRED int >= 1. ADVISORY — excluded from content hash; bumping alone is a no-op publish. |
| `permissions[].resource` | REQUIRED, **BARE** (server composes `{service}/`). |
| `permissions[].action` | REQUIRED, **SEMANTIC** — never an HTTP verb. |
| `permissions[].effect` | `allow` or `deny` ONLY. |
| `permissions[].roles` | >= 1 BARE role name, each MUST be declared in `roles:`. |
| `roles[].name` | REQUIRED, BARE. `/` allowed as hierarchy separator (`fees/editor`). |
| `roles[].granted_to` | list of `{ group: <bare-name> }`. **GROUP-ONLY** — there is no `user` grantee. Server composes the `{owner}/` prefix. |
| `m2m.exposed` | bool — this plugin is callable as an M2M target. |
| `m2m.needs` | list of target service slugs this plugin CALLS via M2M (e.g. `midaz`). |

Composed names the server builds: permission `{service}/{resource}:{action}`,
role `{service}/{name}`, group `{owner}/{group}`.

See `template.permissions.yaml` in this folder for a compact, valid, commented example.

---

## Interactive workflow — follow in order

### Step 1 — Determine `service`
Grep the plugin for its product/slug constant before asking:
```bash
grep -rn -iE "ProductName|ApplicationName|ModuleName|feesApplicationName|Slug\s*=" \
  --include="*.go" <plugin-root> | head
```
Propose the found constant as the default. Confirm with `AskUserQuestion`, and
**warn**: it MUST equal the M2M app DisplayName and be the first arg of every
`Authorize(...)` call (BOLA). Keep any `plugin-` prefix.

### Step 2 — Discover the REAL authorization surface
Enumerate what the code actually enforces today:
```bash
grep -rn "\.Authorize(" --include="*.go" <plugin-root>
```
Extract each `(service, resource, action)` triple from the guard chains (and route
tables). Present the full list. **This list is ground truth** — the manifest must
cover exactly these pairs (Step 8 re-checks).

### Step 3 — Normalize actions to the SEMANTIC standard
For EACH discovered action:
- If it is an HTTP verb (post/get/put/patch/delete-method) → propose the semantic
  equivalent from the table AND **flag that the route guard must change too**
  (guard + manifest move together — this is a code change, not just YAML).
- If it is already semantic → keep it.
- If CRUD does not fit → offer the relevant domain verb.

Use `AskUserQuestion` per action/resource to let the engineer confirm or rename,
offering sensible options (e.g. for `delete`: `delete` vs `remove`). Record the
final semantic `(resource, action)` set. If any guard currently passes a verb, list
those guards explicitly as **follow-up code edits the team owns** — do not silently
emit verb actions to make the mismatch "go away".

### Step 4 — Roles and group grants
Ask (via `AskUserQuestion`):
- Which roles exist? Default `viewer` + `editor`; offer domain roles
  (operator/investigator/compliance-officer/…) as in `br-sisbajud`.
- Which BARE group(s) grant each role? (Groups are group-only, bare.)
- Grant mapping — offer this DEFAULT, let them override:
  **read/query actions → viewer + editor; mutating actions → editor-only.**

Every permission MUST list >= 1 role, and every listed role MUST be declared.

### Step 5 — M2M contract
Ask:
- `exposed`: is this plugin an M2M target (callable by other plugins)?
- `needs`: which services does it CALL via M2M (e.g. `midaz`)? Omit the block if
  neither applies.

### Step 6 — Emit `permissions.yaml`
`Write` the manifest to the plugin's declaration dir (mirror `br-sisbajud`:
`internal/auth/declaration/permissions.yaml`). Bare resources/groups/roles,
semantic actions, valid effects, >= 1 role per permission. Then show the wiring the
plugin adds (manifest authoring is the focus; this is the glue):

```go
//go:embed permissions.yaml
var Manifest []byte

// ...at startup (authdecl = github.com/LerianStudio/lib-auth/v3/auth/declaration, >= v3.4.0-beta.1):
stop, err := authdecl.WireFromEnv(ctx, authdecl.WireInput{
    Slug:     <service>,   // MUST equal manifest.service (BOLA)
    Manifest: Manifest,
    Logger:   logger,
})
```
Deployment sets the FIXED, un-prefixed env contract (default OFF, fail-open):
`DECLARATION_ENABLED`, `PLUGIN_IDENTITY_HOST`, `M2M_CLIENT_ID`, `M2M_CLIENT_SECRET`,
`PLUGIN_AUTH_ENABLED`, `PLUGIN_AUTH_HOST`.

### Step 7 — Validate
Run structural checks against every rule below, and if a Go toolchain + lib-auth
(>= v3.4.0-beta.1) are available, verify against the REAL validator (parse+Validate,
zero network) with a tiny throwaway program:
```go
// authdecl "github.com/LerianStudio/lib-auth/v3/auth/declaration"
// _, err := authdecl.New(authdecl.Config{Slug: "<service>", Manifest: raw, /* IdentityAddr, ClientID/Secret dummy */})
// New parses + Validate()s the manifest eagerly and enforces slug==service (BOLA); a
// non-manifest error means the manifest itself is structurally valid.
```
Or a YAML lint + this checklist. **Validation rules (all aggregated at boot):**
- `service` non-empty and not `.`/`..`.
- `version` >= 1.
- each `action` is SEMANTIC: `post`/`get`/`put`/`patch` are REJECTED at boot
  (`delete` is allowed — also a valid semantic action).
- each permission: non-empty `resource` and `action`; `effect` in {allow, deny};
  >= 1 role; every role reference is a DECLARED role.
- no duplicate composed permission `{service}/{resource}:{action}`.
- no duplicate composed role `{service}/{name}`.
- no Casdoor-safe-name collision: chars `/ ? : # & % = + ;` and whitespace collapse
  to `-` (lossy), so two different names can collide — and a name that derives to
  empty is rejected.

### Step 8 — Alignment gate (BLOCKING)
Re-confirm every declared `(resource, action)` maps to a real `Authorize(...)` call
(Step 2 list) and vice-versa. Enumerate ANY mismatch as blocking:
- guard exists, manifest missing → add the permission.
- manifest declares a pair no guard uses → remove it or add the guard.
- guard still passes an HTTP verb → the team MUST update the guard to the semantic
  action so both sides use it (do not "fix" it by declaring the verb).

Do not consider the manifest done while any mismatch remains.

### Step 9 — Scaffold the durable CI guard (Makefile)
The alignment gate above is a one-time check. Lock the semantic standard in so a
future edit that reintroduces an HTTP verb FAILS the build — two layers:

- **Boot-time (lib-auth):** the manifest validator rejects `post`/`get`/`put`/`patch`
  actions at boot — a plugin with an HTTP-verb action won't start. `delete` stays
  valid. Automatic once the plugin is on the lib-auth release carrying the rule;
  nothing to add.
- **CI (Makefile):** add an earlier, cheaper guard that fails in CI before boot.

Check the plugin's Makefile for the existing `check-*` convention (most Lerian
plugins wire `check-tests`, `check-migrations`, … into a `ci:`/`check` aggregate —
grep `^check-` and `^ci:`). Add a `check-manifest-actions` target matching that
idiom and wire it into the aggregate:

```makefile
MANIFEST ?= internal/auth/declaration/permissions.yaml

.PHONY: check-manifest-actions
# Fail if the manifest uses HTTP-verb actions. 'delete' is allowed (also a valid
# semantic action). Mirrors the boot-time lib-auth rule.
check-manifest-actions:
	@echo "Checking manifest actions are semantic (not HTTP verbs)..."
	@if grep -inE '^[[:space:]]*action:[[:space:]]*["'\'']?(post|get|put|patch)["'\'']?[[:space:]]*$$' $(MANIFEST); then \
		echo "ERROR: HTTP-verb action in $(MANIFEST) — use a SEMANTIC action (create/read/update/delete or a domain verb). 'delete' is allowed."; \
		exit 1; \
	fi
	@echo "OK: manifest actions are semantic."
```

Add `check-manifest-actions` to the `ci:`/`check:` prerequisite list (and `.PHONY`).
If the plugin has no `check-*`/`ci` idiom, still add the target and call it where
tests run. Confirm it FAILS on a seeded `action: post` and PASSES on the real
manifest before finishing.

---

## Red Flags — STOP
- An `action` is `post`/`get`/`put`/`patch`/`delete`-the-method → it is an HTTP verb.
- A `resource`, `role`, or `group` carries a `{service}/` or `{owner}/` prefix → it
  will double-prefix; write it BARE.
- A `granted_to` entry has a `user:` key → there is no user grantee; groups only.
- A permission lists zero roles, or a role not in `roles:` → validation fails.
- You are emitting a verb action to sidestep a guard mismatch → fix the guard instead.
- `service` differs from the M2M app DisplayName / the `Authorize` 1st arg → BOLA break.

All of these mean: **stop and correct before writing/finishing the manifest.**

## Anti-Rationalization

| Rationalization | Why it's WRONG | Required action |
|-----------------|----------------|-----------------|
| "The guard passes `post`, so I'll declare `post` to match." | Freezes the legacy anti-pattern; the standard is semantic on BOTH sides. | Rename guard AND manifest to the semantic action together. |
| "I'll pre-prefix the resource with the service to be safe." | Server composes the prefix; you get `{service}/{service}/…`. | Write resources/roles/groups BARE. |
| "A user grantee would be convenient here." | The schema has no user grantee. | Use a group; grant the group to the role. |
| "Version bump publishes the new content." | Version is excluded from the content hash — bump alone is a no-op. | Change the actual permissions/roles content. |
| "The manifest is valid, so we're done." | Structural validity ≠ alignment with real guards. | Pass Step 8; every pair must map to an `Authorize` call. |
