# Audit Dimensions: Category B — Security & Access Control

These are the 9 (+1 conditional) explorer agent prompts for Security dimensions.
Agent 33 (Multi-Tenant) is CONDITIONAL — only dispatch if MULTI_TENANT=true.
Inject Ring standards and detected stack before dispatching.

### Agent 6: Auth Protection Auditor

```prompt
Audit authentication and authorization implementation for production readiness.

**Detected Stack:** {DETECTED_STACK}

**Ring Standards (Source of Truth):**
---BEGIN STANDARDS---
{INJECTED: "Access Manager Integration" section from security.md}
---END STANDARDS---

**Search Patterns:**
- Files: `**/auth/*.go`, `**/middleware*.go`, `**/routes.go`
- Keywords: `Authorize`, `protected`, `JWT`, `tenant`, `ExtractToken`
- Standards-specific: `AccessManager`, `lib-auth`, `ProtectedGroup`

**Reference Implementation (GOOD):**
```go
// Protected route group
protected := func(resource, action string) fiber.Router {
    return auth.ProtectedGroup(api, authClient, tenantExtractor, resource, action)
}

// All routes use protected
protected("contexts", "create").Post("/v1/config/contexts", handler.Create)

// JWT validation via lib-auth (MANDATORY — do not use custom JWT parsing)
claims, err := auth.ValidateAndExtractClaims(tokenString)
if err != nil {
    return nil, ErrInvalidToken
}
```

**Check Against Ring Standards For:**
1. (HARD GATE) All routes protected via Access Manager integration per security.md
2. (HARD GATE) lib-auth used for JWT validation (not custom JWT parsing)
3. Resource/action authorization granularity per Ring access control model
4. RBAC resource names match public route collections when applicable (`/v1/payments` -> `"payments"`, not `"payment"`)
5. Token expiration enforcement
6. Tenant extraction from JWT claims
7. Auth bypass for health/ready endpoints only

**Severity Ratings:**
- CRITICAL: Unprotected data endpoints (HARD GATE violation per Ring standards)
- CRITICAL: JWT parsed but not validated
- CRITICAL: HARD GATE violation — not using lib-auth for access management
- HIGH: Missing token expiration check
- HIGH: Tenant claims not enforced
- MEDIUM: Plural collection route protected by singular RBAC resource
- MEDIUM: Overly broad permissions
- LOW: Missing fine-grained actions

**Output Format:**
```
## Auth Protection Audit Findings

### Summary
- Protected routes: X/Y
- JWT validation: Complete/Partial/Missing
- Tenant enforcement: Yes/No

### Critical Issues
[file:line] - Description

### Recommendations
1. ...
```
```

### Agent 7: IDOR & Access Control Auditor

```prompt
Audit IDOR (Insecure Direct Object Reference) protection for production readiness.

**Detected Stack:** {DETECTED_STACK}

**Search Patterns:**
- Files: `**/verifier*.go`, `**/handlers.go`, `**/context.go`
- Keywords: `VerifyOwnership`, `tenantID`, `contextID`, `ParseAndVerify`

**Reference Implementation (GOOD):**
```go
// 4-layer IDOR protection
func ParseAndVerifyContextParam(fiberCtx *fiber.Ctx, verifier ContextOwnershipVerifier) (uuid.UUID, uuid.UUID, error) {
    // 1. UUID format validation
    contextID, err := uuid.Parse(fiberCtx.Params("contextId"))
    if err != nil {
        return uuid.Nil, uuid.Nil, ErrInvalidID
    }

    // 2. Extract tenant from auth context (cannot be spoofed)
    tenantID := auth.GetTenantID(ctx)

    // 3. Database query filtered by tenant
    // 4. Post-query ownership verification
    if err := verifier.VerifyOwnership(ctx, tenantID, contextID); err != nil {
        return uuid.Nil, uuid.Nil, err
    }
    return contextID, tenantID, nil
}

// Verifier implementation
func (v *verifier) VerifyOwnership(ctx context.Context, tenantID, resourceID uuid.UUID) error {
    resource, err := v.query.Get(ctx, tenantID, resourceID)  // Query WITH tenant filter
    if errors.Is(err, sql.ErrNoRows) {
        return ErrNotFound
    }
    if resource.TenantID != tenantID {  // Double-check ownership
        return ErrNotOwned
    }
    return nil
}
```

**Reference Implementation (BAD):**
```go
// BAD: No ownership verification
func GetResource(c *fiber.Ctx) error {
    id := c.Params("id")
    resource, err := repo.FindByID(ctx, id)  // No tenant filter!
    return c.JSON(resource)
}
```

**Check For:**
1. All resource access verifies ownership
2. Tenant ID from JWT context (not request params)
3. Database queries include tenant filter
4. Post-query ownership double-check
5. UUID validation before database lookup
6. Consistent verifier pattern across modules

**Severity Ratings:**
- CRITICAL: Resource access without ownership check
- CRITICAL: Tenant ID from user input (not JWT)
- HIGH: Missing post-query ownership verification
- MEDIUM: Inconsistent verifier implementation
- LOW: Missing UUID format validation

**Output Format:**
```
## IDOR Protection Audit Findings

### Summary
- Modules with verifiers: X/Y
- Multi-tenant filtered queries: X/Y
- Post-query verification: X/Y

### Critical Issues
[file:line] - Description

### Recommendations
1. ...
```
```

### Agent 8: SQL Safety Auditor

```prompt
Audit SQL injection prevention for production readiness.

**Detected Stack:** {DETECTED_STACK}

**Search Patterns:**
- Files: `**/*.postgresql.go`, `**/repository/*.go`, `**/*_repo.go`
- Keywords: `ExecContext`, `QueryContext`, `Exec(`, `Query(`, `$1`, `$2`
- Also search for: String concatenation in SQL: `"SELECT.*" +`, `fmt.Sprintf.*SELECT`

**Reference Implementation (GOOD):**
```go
// Parameterized queries
query := `INSERT INTO resources (id, name, tenant_id) VALUES ($1, $2, $3)`
_, err = tx.ExecContext(ctx, query, id, name, tenantID)

// SQL identifier escaping for dynamic schemas
func QuoteIdentifier(identifier string) string {
    return "\"" + strings.ReplaceAll(identifier, "\"", "\"\"") + "\""
}
schemaQuery := "SET LOCAL search_path TO " + QuoteIdentifier(tenantID)

// Query builder (Squirrel)
query := sq.Select("*").From("resources").Where(sq.Eq{"tenant_id": tenantID})
```

**Reference Implementation (BAD):**
```go
// BAD: String concatenation
query := "SELECT * FROM users WHERE name = '" + name + "'"

// BAD: fmt.Sprintf for values
query := fmt.Sprintf("SELECT * FROM users WHERE id = '%s'", id)

// BAD: Unescaped identifier
query := "SET search_path TO " + tenantID  // SQL injection via tenant
```

**Check For:**
1. All queries use parameterized statements ($1, $2, ...)
2. No string concatenation in SQL queries
3. Dynamic identifiers properly escaped (QuoteIdentifier)
4. Query builders used for complex WHERE clauses
5. No raw SQL with user input

**Severity Ratings:**
- CRITICAL: String concatenation with user input
- CRITICAL: fmt.Sprintf with user values
- HIGH: Unescaped dynamic identifiers
- MEDIUM: Raw SQL where builder would be safer
- LOW: Inconsistent query patterns

**Output Format:**
```
## SQL Safety Audit Findings

### Summary
- Parameterized queries: X/Y
- String concatenation risks: Z
- Identifier escaping: Yes/No

### Critical Issues
[file:line] - Description

### Recommendations
1. ...
```
```

### Agent 9: Input Validation Auditor

```prompt
Audit input validation patterns for production readiness.

**Detected Stack:** {DETECTED_STACK}

**Ring Standards (Source of Truth):**
---BEGIN STANDARDS---
{INJECTED: "Frameworks & Libraries" section from core.md — specifically go-playground/validator/v10 reference}
---END STANDARDS---

**Search Patterns:**
- Files: `**/dto.go`, `**/handlers.go`, `**/value_objects/*.go`
- Keywords: `validate:`, `BodyParser`, `IsValid()`, `Parse`, `required`
- Standards-specific: `validator/v10`, `go-playground/validator`

**Reference Implementation (GOOD):**
```go
// DTO with validation tags
type CreateRequest struct {
    Name   string `json:"name" validate:"required,min=1,max=255"`
    Type   string `json:"type" validate:"required,oneof=TYPE_A TYPE_B"`
    Amount int    `json:"amount" validate:"gte=0,lte=1000000"`
}

// Handler with body parsing error handling
func (h *Handler) Create(c *fiber.Ctx) error {
    var payload CreateRequest
    if err := c.BodyParser(&payload); err != nil {
        return badRequest(c, span, logger, "invalid request body", err)
    }
    // Validate struct
    if err := h.validator.Struct(payload); err != nil {
        return badRequest(c, span, logger, "validation failed", err)
    }
    ...
}

// Value object with domain validation
func (vo ValueObject) IsValid() bool {
    if vo.value == "" || len(vo.value) > maxLength {
        return false
    }
    return validPattern.MatchString(vo.value)
}
```

**Reference Implementation (BAD):**
```go
// BAD: No validation tags
type Request struct {
    Name string `json:"name"`  // No validation!
}

// BAD: Ignoring body parse error
payload := Request{}
c.BodyParser(&payload)  // Error ignored!

// BAD: No bounds checking
amount := c.QueryInt("amount")  // Could be negative or huge
```

**Check Against Ring Standards For:**
1. (HARD GATE) go-playground/validator/v10 used for struct validation per Ring core.md
2. (HARD GATE) All DTOs have validate: tags on required fields
3. BodyParser errors are handled (not ignored)
4. Query/path params validated before use
5. Numeric bounds enforced (min/max)
6. String length limits enforced
7. Enum values constrained (oneof=)
8. Value objects have IsValid() methods
9. File upload size/type validation

**Severity Ratings:**
- CRITICAL: BodyParser errors ignored
- CRITICAL: HARD GATE violation — not using go-playground/validator/v10 per Ring standards
- HIGH: No validation on user input DTOs
- HIGH: Unbounded numeric inputs
- MEDIUM: Missing string length limits
- LOW: Value objects without IsValid()

**Output Format:**
```
## Input Validation Audit Findings

### Summary
- DTOs with validation tags: X/Y
- BodyParser error handling: X/Y
- Value objects with IsValid: X/Y

### Critical Issues
[file:line] - Description

### Recommendations
1. ...
```
```

### Agent 37: Secret Scanning Auditor

```prompt
Audit the codebase for hardcoded secrets, credentials, API keys, tokens, and sensitive data exposure for production readiness.

**Detected Stack:** {DETECTED_STACK}

**Ring Standards (Source of Truth):**
---BEGIN STANDARDS---
{INJECTED: Secret scanning patterns — no dedicated standards file; patterns derived from industry secret detection rules (GitHub secret scanning, truffleHog, gitleaks)}
---END STANDARDS---

**Search Patterns:**
- All source files: `**/*.go`, `**/*.ts`, `**/*.tsx`, `**/*.js`, `**/*.jsx`, `**/*.py`, `**/*.java`
- Configuration files: `**/*.yaml`, `**/*.yml`, `**/*.json`, `**/*.toml`, `**/*.ini`, `**/*.conf`, `**/*.cfg`
- Environment files: `**/*.env`, `**/*.env.*`, `.env.local`, `.env.production`
- Key/certificate files: `**/*.pem`, `**/*.key`, `**/*.p12`, `**/*.pfx`, `**/*.crt`, `**/*.cer`
- Docker/CI: `**/Dockerfile*`, `**/.github/workflows/*.yml`, `**/docker-compose*.yml`, `**/.gitlab-ci.yml`
- Keywords (credentials): `password`, `passwd`, `pwd`, `secret`, `api_key`, `apikey`, `api-key`, `token`, `auth_token`, `access_token`, `private_key`, `credential`
- Keywords (connection): `connection_string`, `conn_str`, `database_url`, `redis_url`, `mongodb_uri`, `dsn`
- Keywords (cloud): `AKIA`, `ASIA` (AWS), `AIza` (GCP), `ghp_`, `gho_`, `ghu_` (GitHub), `sk-` (OpenAI/Stripe), `xoxb-`, `xoxp-` (Slack)
- Patterns (high-entropy): Base64 strings > 20 chars, hex strings > 32 chars, `eyJ` (JWT prefix)
- Patterns (private keys): `-----BEGIN.*PRIVATE KEY-----`, `-----BEGIN RSA`, `-----BEGIN EC`, `-----BEGIN OPENSSH`

**Secret Detection Patterns to Check:**

| Pattern | Risk Level | What to Look For |
|---------|:----------:|------------------|
| Private keys in source | CRITICAL | `-----BEGIN RSA PRIVATE KEY-----` or similar PEM blocks committed to repo |
| Cloud provider credentials | CRITICAL | AWS access keys (`AKIA...`), GCP service account JSON, Azure client secrets in source |
| Database connection strings with passwords | CRITICAL | `postgres://user:password@`, `mongodb+srv://user:pass@`, `mysql://root:pass@` |
| API keys/tokens hardcoded | HIGH | `const API_KEY = "sk-..."`, `token: "ghp_..."`, inline bearer tokens |
| .env files in version control | HIGH | `.env`, `.env.production` tracked by git (not in .gitignore) |
| JWT tokens hardcoded | HIGH | Strings starting with `eyJ` (base64-encoded JSON header) in source code |
| Secrets in CI/CD config | HIGH | Plaintext secrets in GitHub Actions workflows, Docker compose, or CI config |
| Secrets in config files without encryption | MEDIUM | Passwords or tokens in YAML/JSON/TOML config files not using vault references |
| Secrets in comments or documentation | MEDIUM | Example credentials in comments that are actually real, or TODO with temp credentials |
| Secrets in test fixtures | MEDIUM | Test files containing what appear to be real credentials (not obviously fake) |
| Weak secret references | LOW | Hardcoded default passwords like `password123`, `admin`, `changeme` in non-test code |
| Example credentials resembling real ones | LOW | Test/example values that follow real credential formats (could confuse scanning tools) |

**Gitignore Verification (MANDATORY — do not skip):**
1. **Check .gitignore exists** at repository root
2. **Verify .env exclusion**: `.env`, `.env.*`, `.env.local`, `.env.production` MUST be in .gitignore
3. **Verify key file exclusion**: `*.pem`, `*.key`, `*.p12`, `*.pfx` SHOULD be in .gitignore
4. **Check for tracked .env files**: `git ls-files '*.env*'` — any results are HIGH severity findings
5. **Check for tracked key files**: `git ls-files '*.pem' '*.key'` — any results are CRITICAL

**Reference Implementation (GOOD):**
```go
// GOOD: Secrets from environment variables
dbURL := os.Getenv("DATABASE_URL")
if dbURL == "" {
    log.Fatal("DATABASE_URL environment variable is required")
}

// GOOD: API key from environment
apiKey := os.Getenv("EXTERNAL_API_KEY")

// GOOD: Secret from vault/secret manager
secret, err := vault.ReadSecret(ctx, "secret/data/myapp/api-key")
if err != nil {
    return fmt.Errorf("failed to read secret: %w", err)
}
```

```typescript
// GOOD: Secrets from environment
const dbUrl = process.env.DATABASE_URL;
if (!dbUrl) {
  throw new Error('DATABASE_URL environment variable is required');
}

// GOOD: Secret from config service
const apiKey = await configService.getSecret('EXTERNAL_API_KEY');
```

```yaml
# GOOD: .gitignore includes secret files
.env
.env.*
.env.local
.env.production
*.pem
*.key
*.p12
*.pfx
credentials.json
```

**Reference Implementation (BAD):**
```go
// BAD: Hardcoded API key
const APIKey = "sk-proj-abc123xyz789..."

// BAD: Hardcoded database connection with password
const DatabaseURL = "postgres://admin:SuperSecret123@db.example.com:5432/production"

// BAD: Hardcoded AWS credentials
const AWSAccessKey = "AKIAIOSFODNN7EXAMPLE"
const AWSSecretKey = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
```

```typescript
// BAD: Inline token
const headers = {
  Authorization: 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
};

// BAD: Hardcoded connection string
const mongoUri = 'mongodb+srv://admin:P@ssw0rd@cluster0.example.mongodb.net/prod';
```

```yaml
# BAD: Secrets in docker-compose.yml
services:
  app:
    environment:
      - DB_PASSWORD=MySecretPassword123
      - API_KEY=sk-live-abc123
```

**Check Against Standards For:**
1. (CRITICAL) No private keys (RSA, SSH, TLS) committed to source control
2. (CRITICAL) No cloud provider credentials (AWS access keys, GCP service account JSON, Azure secrets) in source
3. (CRITICAL) No database connection strings with embedded passwords in source code
4. (HIGH) No API keys or tokens hardcoded in source files (MUST come from environment or secret manager)
5. (HIGH) .env files are in .gitignore and not tracked by git
6. (HIGH) No plaintext secrets in CI/CD configuration files
7. (HIGH) No hardcoded JWT tokens in source code
8. (MEDIUM) Configuration files use vault references or environment variable substitution for secrets
9. (MEDIUM) No real-looking credentials in comments, documentation, or TODO items
10. (MEDIUM) Test fixtures use obviously fake credentials (e.g., `test-key-not-real`, not `sk-abc123`)
11. (LOW) No default passwords like `password`, `admin`, `changeme` in non-test code
12. (LOW) Example credentials in documentation are clearly marked as fake

**Severity Ratings:**
- CRITICAL: Private keys committed to repo (full compromise), cloud provider credentials in source (account takeover), database connection strings with passwords (data breach)
- HIGH: API keys/tokens hardcoded (service compromise), .env tracked by git (secret exposure on clone), secrets in CI/CD config (pipeline compromise), hardcoded JWT tokens (authentication bypass)
- MEDIUM: Secrets in config files without encryption (exposure if config leaked), real-looking credentials in comments (confusion, potential real secrets), test fixtures with real-format secrets (may be actual secrets)
- LOW: Default/weak passwords in non-test code (brute force risk), example credentials resembling real format (scanner noise)

**Output Format:**
```
## Secret Scanning Audit Findings

### Summary
- Files scanned: X
- Secrets found: Y total (Z unique)
- .gitignore coverage: Adequate/Inadequate
- .env files tracked: X (MUST be 0)
- Key/certificate files tracked: X (MUST be 0)
- Secret management approach: {env vars / vault / config service / mixed / none detected}

### Critical Issues
[file:line] - Description (type: {secret type})
  Evidence: {redacted snippet showing pattern, NOT the actual secret}
  Impact: {what an attacker could do with this secret}
  Fix: Move to environment variable or secret manager; rotate immediately

### High Issues
[file:line] - Description (type: {secret type})
  Evidence: {redacted snippet}
  Fix: {specific remediation}

### Medium Issues
[file:line] - Description

### Low Issues
[file:line] - Description

### .gitignore Analysis
- .env patterns: {listed / missing}
- Key file patterns: {listed / missing}
- Tracked secret files: {list or "none"}

### Recommendations
1. ...

### IMPORTANT: Secret Rotation Notice
{If any CRITICAL or HIGH secrets are found, include this notice:}
WARNING: Any secrets found in source code MUST be considered compromised.
Rotate all affected credentials IMMEDIATELY — removing from code is not sufficient.
```
```

### Agent 41: Data Encryption at Rest Auditor

```prompt
Audit data encryption at rest, key management, and sensitive data protection for production readiness.

**Detected Stack:** {DETECTED_STACK}

**Ring Standards (Source of Truth):**
---BEGIN STANDARDS---
{INJECTED: Data encryption patterns — no dedicated standards file; patterns derived from security best practices and OWASP guidelines}
---END STANDARDS---

**Search Patterns:**
- Go files: `**/*.go` — search for encryption libraries, hashing functions, sensitive field handling, key management
- TypeScript files: `**/*.ts`, `**/*.tsx` — search for crypto modules, encryption utilities, password hashing
- Config files: `**/*.yaml`, `**/*.yml`, `**/*.env*`, `**/docker-compose*` — search for encryption keys, database encryption settings
- SQL/Migration files: `**/*.sql`, `**/migrations/**` — search for sensitive columns, pgcrypto, encryption extensions
- Keywords (Go): `crypto/aes`, `crypto/cipher`, `bcrypt`, `scrypt`, `argon2`, `aes.NewCipher`, `gcm`, `Seal`, `Open`, `GenerateFromPassword`, `CompareHashAndPassword`
- Keywords (TS): `crypto`, `createCipheriv`, `createDecipheriv`, `node-forge`, `bcrypt`, `argon2`, `scrypt`, `pbkdf2`
- Keywords (DB): `pgcrypto`, `encrypt`, `decrypt`, `gen_salt`, `crypt`, `ENCRYPTED`, `BYTEA`
- Keywords (Config): `ENCRYPTION_KEY`, `MASTER_KEY`, `KMS`, `vault`, `SECRET_KEY`, `CIPHER`

**Sensitive Data Patterns to Identify:**

| Data Type | Identifiers | Required Protection |
|-----------|-------------|---------------------|
| Passwords | `password`, `passwd`, `pass`, `secret` | Hashed with bcrypt/argon2/scrypt (NEVER plaintext, NEVER reversible encryption) |
| Credit cards | `credit_card`, `card_number`, `pan`, `cc_num` | Field-level encryption (AES-256-GCM), masked in logs |
| Bank accounts | `bank_account`, `account_number`, `iban`, `routing` | Field-level encryption |
| SSN / Tax IDs | `ssn`, `tax_id`, `national_id`, `social_security` | Field-level encryption |
| API keys / tokens | `api_key`, `token`, `secret_key`, `access_key` | Encrypted at rest, never in source |
| PII (general) | `email`, `phone`, `address`, `date_of_birth` | Encryption recommended for regulated environments |

**Encryption Safety Methodology (MANDATORY — do not skip):**
1. **Inventory sensitive fields**: Scan models, database schemas, and API payloads for sensitive data types
2. **Check password hashing**: Verify all password storage uses bcrypt, argon2, or scrypt — NEVER plaintext or reversible encryption
3. **Check field encryption**: Verify financial and identity data uses AES-256-GCM or equivalent field-level encryption
4. **Check key management**: Verify encryption keys come from KMS, Vault, or secure secret store — NOT from source code or .env files
5. **Check backups**: Verify database backup processes include encryption
6. **Check algorithm strength**: Flag use of MD5, SHA1, DES, RC4, or other deprecated algorithms

**Go Encryption Patterns to Check:**

| Pattern | Risk Level | What to Look For |
|---------|:----------:|------------------|
| Plaintext passwords | CRITICAL | `password` field stored as `string` in DB without hashing |
| Weak hash for passwords | CRITICAL | `md5.Sum`, `sha1.Sum`, `sha256.Sum` used for password hashing (use bcrypt/argon2 instead) |
| Unencrypted financial data | CRITICAL | Credit card, bank account stored as plain `string` in DB |
| Keys in source | HIGH | `ENCRYPTION_KEY`, `MASTER_KEY` hardcoded in Go files or committed .env |
| No key rotation | MEDIUM | Single encryption key with no rotation mechanism or key versioning |
| Weak algorithm | MEDIUM | DES, RC4, AES-ECB (use AES-GCM), MD5/SHA1 for integrity |
| Unencrypted backups | HIGH | Backup commands/scripts without encryption flag |

**TypeScript Encryption Patterns to Check:**

| Pattern | Risk Level | What to Look For |
|---------|:----------:|------------------|
| Plaintext passwords | CRITICAL | Password stored/compared as plain string without hashing |
| Weak hash for passwords | CRITICAL | `crypto.createHash('md5')` or `crypto.createHash('sha1')` for passwords |
| Unencrypted sensitive data | CRITICAL | PII or financial data stored without encryption |
| Keys in source | HIGH | Encryption keys hardcoded in TypeScript files |
| No key rotation | MEDIUM | Static encryption key with no versioning |
| Weak algorithm | MEDIUM | `createCipheriv('des', ...)`, `createCipheriv('aes-128-ecb', ...)` |

**Reference Implementation (GOOD — Go):**
```go
// GOOD: Password hashing with bcrypt
import "golang.org/x/crypto/bcrypt"

func HashPassword(password string) (string, error) {
    hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
    if err != nil {
        return "", fmt.Errorf("hashing password: %w", err)
    }
    return string(hash), nil
}

func VerifyPassword(hash, password string) error {
    return bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
}

// GOOD: AES-256-GCM field encryption with key from Vault
func EncryptField(plaintext []byte, key []byte) ([]byte, error) {
    block, err := aes.NewCipher(key)
    if err != nil {
        return nil, err
    }
    gcm, err := cipher.NewGCM(block)
    if err != nil {
        return nil, err
    }
    nonce := make([]byte, gcm.NonceSize())
    if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
        return nil, err
    }
    return gcm.Seal(nonce, nonce, plaintext, nil), nil
}

// GOOD: Key from Vault/KMS
func GetEncryptionKey(ctx context.Context) ([]byte, error) {
    secret, err := vaultClient.Logical().Read("secret/data/encryption-key")
    if err != nil {
        return nil, fmt.Errorf("reading encryption key from vault: %w", err)
    }
    return base64.StdEncoding.DecodeString(secret.Data["key"].(string))
}
```

**Reference Implementation (BAD — Go):**
```go
// BAD: Plaintext password storage
type User struct {
    Email    string `db:"email"`
    Password string `db:"password"` // stored as plain text!
}

// BAD: MD5 for password hashing — trivially crackable
func HashPassword(password string) string {
    hash := md5.Sum([]byte(password))
    return hex.EncodeToString(hash[:])
}

// BAD: Encryption key hardcoded in source
var encryptionKey = []byte("my-super-secret-key-1234567890ab")

// BAD: AES-ECB mode — deterministic, leaks patterns
block, _ := aes.NewCipher(key)
block.Encrypt(ciphertext, plaintext) // ECB mode — do NOT use
```

**Reference Implementation (GOOD — TypeScript):**
```typescript
// GOOD: Password hashing with argon2
import argon2 from 'argon2';

async function hashPassword(password: string): Promise<string> {
    return argon2.hash(password, { type: argon2.argon2id });
}

async function verifyPassword(hash: string, password: string): Promise<boolean> {
    return argon2.verify(hash, password);
}

// GOOD: AES-256-GCM field encryption
import { createCipheriv, createDecipheriv, randomBytes } from 'crypto';

function encryptField(plaintext: string, key: Buffer): string {
    const iv = randomBytes(16);
    const cipher = createCipheriv('aes-256-gcm', key, iv);
    const encrypted = Buffer.concat([cipher.update(plaintext, 'utf8'), cipher.final()]);
    const tag = cipher.getAuthTag();
    return Buffer.concat([iv, tag, encrypted]).toString('base64');
}
```

**Reference Implementation (BAD — TypeScript):**
```typescript
// BAD: Plaintext password comparison
async function login(email: string, password: string): Promise<User> {
    const user = await db.users.findByEmail(email);
    if (user.password !== password) throw new Error('Invalid'); // plaintext!
    return user;
}

// BAD: MD5 for hashing
import { createHash } from 'crypto';
const hash = createHash('md5').update(password).digest('hex');

// BAD: Encryption key in source
const ENCRYPTION_KEY = 'hardcoded-secret-key-do-not-do-this';
```

**Check Against Standards For:**
1. (CRITICAL) All passwords are hashed with bcrypt, argon2, or scrypt — never plaintext or reversible encryption
2. (CRITICAL) Credit card and financial data is encrypted at rest with AES-256-GCM or equivalent
3. (CRITICAL) No weak hashing algorithms (MD5, SHA1) used for passwords or security-sensitive data
4. (HIGH) PII (SSN, tax ID, national ID) is encrypted with field-level encryption
5. (HIGH) Encryption keys are stored in KMS, Vault, or secure secret store — not in source code or .env files
6. (HIGH) Database backups are encrypted
7. (MEDIUM) No deprecated/weak encryption algorithms (DES, RC4, AES-ECB)
8. (MEDIUM) Key rotation mechanism exists (key versioning, re-encryption strategy)
9. (LOW) Non-sensitive data is not unnecessarily encrypted (performance overhead)

**Severity Ratings:**
- CRITICAL: Plaintext password storage, credit card/financial data stored unencrypted, weak hash algorithms (MD5/SHA1) for passwords
- HIGH: PII stored without field-level encryption, encryption keys in source code or .env, unencrypted backups, no key management strategy
- MEDIUM: Weak encryption algorithms (DES, RC4, AES-ECB), no key rotation mechanism, SHA256 used for password hashing (use bcrypt/argon2 instead)
- LOW: Non-sensitive data encrypted unnecessarily (performance overhead), missing encryption documentation

**Output Format:**
```
## Data Encryption at Rest Audit Findings

### Summary
- Sensitive data types found: {password, credit card, SSN, ...}
- Password hashing: {bcrypt / argon2 / scrypt / MD5 / SHA1 / plaintext}
- Field encryption: {AES-256-GCM / AES-ECB / none}
- Key management: {Vault / KMS / env var / hardcoded / none}
- Key rotation: Yes/No
- Backup encryption: Yes/No/Unknown

### Critical Issues
[file:line] - Description (data type: {type}, current protection: {none/weak})

### High Issues
[file:line] - Description (data type: {type})

### Medium Issues
[file:line] - Description

### Low Issues
[file:line] - Description

### Sensitive Data Inventory
| Field/Column | Data Type | Location | Current Protection | Required Protection | Gap |
|-------------|-----------|----------|-------------------|--------------------|----|
| ... | ... | ... | ... | ... | ... |

### Recommendations
1. ...
```
```

### Agent 43: Rate Limiting Auditor

```prompt
Audit rate limiting implementation across the codebase for production readiness.

**Detected Stack:** {DETECTED_STACK}

**Ring Standards (Source of Truth):**
---BEGIN STANDARDS---
{INJECTED: security.md § Rate Limiting (MANDATORY)}
---END STANDARDS---

**Search Patterns:**
- Go files: `**/*.go` — search for rate limiting middleware, limiter configuration, Redis storage for rate limits
- Config files: `**/*.env*`, `**/docker-compose*`, `**/config*.go` — search for RATE_LIMIT env vars
- Middleware files: `**/middleware/**`, `**/bootstrap/**` — search for limiter registration
- Keywords (Go): `limiter`, `ratelimit`, `rate_limit`, `RateLimit`, `RATE_LIMIT`, `fiber/middleware/limiter`, `MaxRequests`, `Expiration`, `KeyGenerator`, `LimitReached`, `429`, `Retry-After`
- Keywords (Config): `RATE_LIMIT_ENABLED`, `RATE_LIMIT_MAX`, `RATE_LIMIT_EXPIRY_SEC`, `EXPORT_RATE_LIMIT`, `DISPATCH_RATE_LIMIT`

**Rate Limiting Patterns to Check:**

| Pattern | Risk Level | What to Look For |
|---------|:----------:|------------------|
| No rate limiting at all | CRITICAL | No limiter middleware registered on any route |
| Single-tier only | HIGH | Only global rate limit, no export/dispatch tiers |
| In-memory storage only | HIGH | `fiber.Storage` not backed by Redis — rate limits not shared across instances |
| Hardcoded limits | MEDIUM | Rate limit values hardcoded in code instead of env vars |
| No key generation strategy | HIGH | Default key generator (IP only) — no UserID or TenantID+IP |
| Rate limiting disabled in production | CRITICAL | `RATE_LIMIT_ENABLED=false` with no production override |
| No 429 response with Retry-After | MEDIUM | Rate limit exceeded but no `Retry-After` header in response |
| No graceful degradation | HIGH | Redis unavailable causes request failures instead of fallback to in-memory |

**Three-tier Strategy Verification (MANDATORY — do not skip):**
1. **Global tier**: Verify a general rate limiter exists on all protected routes (default: 100 req/60s)
2. **Export tier**: Verify resource-intensive endpoints (exports, bulk ops) have a stricter limiter (default: 10 req/60s)
3. **Dispatch tier**: Verify external integration endpoints (webhooks, external calls) have their own limiter (default: 50 req/60s)

**Redis Storage Verification (MANDATORY — do not skip):**
1. **Storage implementation**: Verify rate limiter uses Redis-backed storage implementing `fiber.Storage` interface
2. **Key prefix**: Verify rate limit keys use `ratelimit:` prefix for namespace isolation
3. **Sentinel errors**: Verify Redis operations use sentinel errors (not `fmt.Errorf`)
4. **Graceful degradation**: Verify fallback behavior when Redis is unavailable

**Production Safety Verification (MANDATORY — do not skip):**
1. **Force-enable in production**: Verify rate limiting cannot be disabled when `ENV_NAME=production`
2. **Key generation**: Verify key generator uses UserID > TenantID+IP > IP priority
3. **Configuration via env vars**: Verify all limits are configurable via environment variables

**Reference Implementation (GOOD — Go):**
```go
// GOOD: Three-tier rate limiting with Redis storage
rateLimitStorage := ratelimit.NewRedisStorage(redisConn)

// Global limiter
app.Use(limiter.New(limiter.Config{
    Max:        cfg.RateLimit.Max,
    Expiration: time.Duration(cfg.RateLimit.ExpirySec) * time.Second,
    Storage:    rateLimitStorage,
    KeyGenerator: func(c *fiber.Ctx) string {
        // UserID > TenantID+IP > IP
        if uid := c.Locals("userID"); uid != nil {
            return fmt.Sprintf("user:%v", uid)
        }
        if tid := c.Locals("tenantID"); tid != nil {
            return fmt.Sprintf("tenant:%v:ip:%s", tid, c.IP())
        }
        return c.IP()
    },
}))
```

**Reference Implementation (BAD — Go):**
```go
// BAD: No rate limiting at all — DoS vulnerable
app.Get("/api/v1/exports", exportHandler)

// BAD: Hardcoded limits, no Redis storage
app.Use(limiter.New(limiter.Config{
    Max:        100,           // hardcoded
    Expiration: time.Minute,   // hardcoded
    // No Storage — in-memory only, not shared across instances
}))

// BAD: Rate limiting can be disabled in production
if cfg.RateLimit.Enabled {
    app.Use(rateLimiter)
}
```

**Check Against Standards For:**
1. (CRITICAL) Rate limiting middleware exists and is registered on protected routes
2. (CRITICAL) Rate limiting cannot be disabled in production environment
3. (HIGH) Three-tier strategy implemented (Global, Export, Dispatch)
4. (HIGH) Redis-backed distributed storage (not in-memory only)
5. (HIGH) Key generation uses UserID > TenantID+IP > IP priority
6. (HIGH) Graceful degradation when Redis is unavailable
7. (MEDIUM) All rate limit values configurable via environment variables
8. (MEDIUM) 429 response includes `Retry-After` header
9. (MEDIUM) Sentinel errors used in Redis storage operations
10. (LOW) Rate limit key prefix isolates namespace (`ratelimit:`)

**Severity Ratings:**
- CRITICAL: No rate limiting middleware at all, rate limiting disabled in production
- HIGH: Single-tier only (no export/dispatch tiers), in-memory storage only (not distributed), no key generation strategy (IP only), no graceful degradation on Redis failure
- MEDIUM: Hardcoded rate limit values (not configurable), no Retry-After header, fmt.Errorf instead of sentinel errors
- LOW: Missing key prefix, rate limit logging not structured, no rate limit metrics/observability

**Output Format:**
```
## Rate Limiting Audit Findings

### Summary
- Rate limiting middleware: {Present / Absent}
- Tiers implemented: {Global, Export, Dispatch / Global only / None}
- Storage backend: {Redis / In-memory / None}
- Key generation: {UserID+TenantID+IP / IP only / Default}
- Production safety: {Force-enabled / Disableable / Not configured}
- Graceful degradation: {Yes / No}

### Critical Issues
[file:line] - Description

### High Issues
[file:line] - Description

### Medium Issues
[file:line] - Description

### Low Issues
[file:line] - Description

### Recommendations
1. ...
```
```

### Agent 44: CORS Configuration Auditor

```prompt
Audit CORS (Cross-Origin Resource Sharing) configuration across the codebase for production readiness.

**Detected Stack:** {DETECTED_STACK}

**Ring Standards (Source of Truth):**
---BEGIN STANDARDS---
{INJECTED: security.md § CORS Configuration (MANDATORY)}
---END STANDARDS---

**Search Patterns:**
- Go files: `**/*.go` — search for CORS middleware configuration, origin validation, preflight handling
- Config files: `**/*.env*`, `**/docker-compose*`, `**/config*.go` — search for CORS env vars
- Middleware files: `**/middleware/**`, `**/bootstrap/**` — search for CORS and Helmet middleware registration
- Keywords (Go): `cors`, `CORS`, `AllowOrigins`, `AllowMethods`, `AllowHeaders`, `fiber/middleware/cors`, `helmet`, `Helmet`, `HSTS`, `HSTSMaxAge`, `ContentSecurityPolicy`, `XFrameOptions`, `PermissionPolicy`
- Keywords (Config): `CORS_ALLOWED_ORIGINS`, `CORS_ALLOWED_METHODS`, `CORS_ALLOWED_HEADERS`, `TLS_TERMINATED_UPSTREAM`, `SERVER_TLS_CERT_FILE`

**CORS Patterns to Check:**

| Pattern | Risk Level | What to Look For |
|---------|:----------:|------------------|
| No CORS middleware at all | CRITICAL | No `cors.New()` or equivalent middleware registered |
| Wildcard origins in production | CRITICAL | `AllowOrigins: "*"` when `ENV_NAME=production` |
| Empty origins in production | CRITICAL | `CORS_ALLOWED_ORIGINS` not set in production |
| Hardcoded origins | HIGH | Origins in code instead of env var configuration |
| CORS after business logic | HIGH | CORS middleware placed after auth/handler — preflight fails |
| No production validation | HIGH | No check for wildcard/empty origins in production |
| Origin reflection without validation | CRITICAL | `AllowOriginsFunc` that returns true for all origins |
| No Helmet integration | MEDIUM | CORS configured but no Helmet security headers |
| HSTS not enabled with TLS | HIGH | TLS configured but `HSTSMaxAge` not set |

**Middleware Ordering Verification (MANDATORY — do not skip):**
Verify CORS is placed in the correct position in the middleware chain:
```
Recover → Request ID → CORS → Helmet (Security Headers) → Telemetry → Rate Limiter → Handler
```

**Production Validation Verification (MANDATORY — do not skip):**
1. **No wildcard origins**: Verify `*` is rejected when `ENV_NAME=production`
2. **No empty origins**: Verify empty `CORS_ALLOWED_ORIGINS` is rejected in production
3. **HTTPS origins**: Verify production origins use `https://` (not `http://`)
4. **Sentinel errors**: Verify validation uses sentinel errors (not `fmt.Errorf`)

**Helmet Integration Verification (MANDATORY — do not skip):**
1. **Security headers present**: Verify Helmet middleware is registered
2. **HSTS conditional**: Verify HSTS is enabled only when TLS is configured (cert file or TLSTerminatedUpstream)
3. **CSP configured**: Verify Content-Security-Policy header is set
4. **Cross-origin policies**: Verify CrossOriginEmbedderPolicy, CrossOriginOpenerPolicy, CrossOriginResourcePolicy

**Reference Implementation (GOOD — Go):**
```go
// GOOD: Configuration-driven CORS with production validation
app.Use(cors.New(cors.Config{
    AllowOrigins: cfg.Server.CORSAllowedOrigins,  // From env vars
    AllowMethods: cfg.Server.CORSAllowedMethods,
    AllowHeaders: cfg.Server.CORSAllowedHeaders,
}))

// GOOD: Production validation with sentinel errors
var (
    ErrCORSOriginsEmpty    = errors.New("CORS_ALLOWED_ORIGINS must be set in production")
    ErrCORSOriginsWildcard = errors.New("CORS_ALLOWED_ORIGINS must not contain wildcard (*) in production")
)

func validateProductionConfig(cfg *Config) error {
    if cfg.App.EnvName != "production" {
        return nil
    }
    origins := strings.TrimSpace(cfg.Server.CORSAllowedOrigins)
    if origins == "" {
        return ErrCORSOriginsEmpty
    }
    if strings.Contains(origins, "*") {
        return ErrCORSOriginsWildcard
    }
    return nil
}
```

**Reference Implementation (BAD — Go):**
```go
// BAD: Wildcard origins — allows any site to make requests
cors.Config{AllowOrigins: "*"}

// BAD: Hardcoded origins
cors.Config{AllowOrigins: "https://app.example.com"}

// BAD: No CORS middleware at all

// BAD: CORS after business logic — preflight fails
app.Use(authMiddleware)
app.Use(rateLimiter)
app.Use(cors.New(corsCfg))  // Too late

// BAD: Origin reflection without validation
cors.Config{
    AllowOriginsFunc: func(origin string) bool {
        return true  // Effectively same as wildcard
    },
}
```

**Check Against Standards For:**
1. (CRITICAL) CORS middleware is registered on the HTTP server
2. (CRITICAL) Wildcard origins (`*`) are not used in production
3. (CRITICAL) Empty origins are rejected in production
4. (CRITICAL) No origin reflection function that accepts all origins
5. (HIGH) Origins are configuration-driven via env vars (not hardcoded)
6. (HIGH) CORS is placed before Helmet and business logic in middleware chain
7. (HIGH) Production validation exists with sentinel errors
8. (HIGH) HSTS is enabled when TLS is configured
9. (MEDIUM) Helmet middleware is registered with security headers (CSP, X-Frame-Options, etc.)
10. (MEDIUM) Cross-origin policies are set (Embedder, Opener, Resource)
11. (LOW) Production origins use HTTPS (not HTTP)

**Severity Ratings:**
- CRITICAL: No CORS middleware, wildcard origins in production, empty origins in production, origin reflection accepting all
- HIGH: Hardcoded origins, CORS placed after business logic, no production validation, HSTS not enabled with TLS
- MEDIUM: No Helmet security headers, missing cross-origin policies, no CSP header
- LOW: HTTP origins in production, missing PermissionPolicy, verbose CORS error messages

**Output Format:**
```
## CORS Configuration Audit Findings

### Summary
- CORS middleware: {Present / Absent}
- Allowed origins source: {Env var / Hardcoded / Wildcard / Not configured}
- Production validation: {Present with sentinel errors / Present without sentinel errors / Absent}
- Middleware ordering: {Correct / Incorrect — position: {actual position}}
- Helmet integration: {Present / Absent}
- HSTS: {Enabled / Disabled / N/A (no TLS)}

### Critical Issues
[file:line] - Description

### High Issues
[file:line] - Description

### Medium Issues
[file:line] - Description

### Low Issues
[file:line] - Description

### Recommendations
1. ...
```
```

---

## Consolidated Report Template (Thorough)

> **EXTRACTED TO SHARED PATTERN:** The consolidated report template has been moved to avoid duplication.
> Load from: [`shared-patterns/consolidated-report-template.md`](../../shared-patterns/consolidated-report-template.md)
>
> After all explorers complete, read and apply that template exactly as written.
> MANDATORY: every section REQUIRED — do not abbreviate, summarize, condense, or skip any section.
