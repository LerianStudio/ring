# Multi-Tenant Analysis Checklist (MANDATORY)

**⛔ MULTI-TENANT ANALYSIS (MANDATORY):**

See [multi-tenant.md § Canonical Model Compliance](../../docs/standards/golang/multi-tenant.md#hard-gate-canonical-model-compliance) for the canonical patterns and [multi-tenant.md § Canonical File Map](../../docs/standards/golang/multi-tenant.md#canonical-file-map) for valid file locations.

**Existence ≠ Compliance.** Code that has "some multi-tenant" but does not match the Ring canonical model is NON-COMPLIANT and MUST be flagged as a gap.

## Compliance Audit

1. WebFetch multi-tenant.md: https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/multi-tenant.md
2. **Detection:** Check if any multi-tenant code exists (`MULTI_TENANT_ENABLED`, `dispatch layer` in go.mod, `TenantMiddleware`)
3. **If multi-tenant code exists → run compliance audit:**
   - Config vars: MUST use the 7 canonical `MULTI_TENANT_*` names (not `TENANT_MANAGER_ADDRESS`, `TENANT_URL`, etc.)
   - Middleware: MUST use `tmmiddleware.NewTenantMiddleware` with `WithPG`/`WithMB` options from lib-commons v4
   - Route ordering: Auth MUST run before tenant middleware — per-route via `WhenEnabled` (not global `app.Use`)
   - Repositories: MUST use `tmcore.GetPGContext`/`tmcore.GetMBContext` (not static connections)
   - Redis: MUST use `valkey.GetKeyContext` for every key operation (including Lua script KEYS[]/ARGV[])
   - S3: MUST use `s3.GetS3KeyStorageContext` for every object key
   - RabbitMQ: MUST use `tmrabbitmq.Manager` (Layer 1 — vhost isolation) + `X-Tenant-ID` header (Layer 2 — audit)
   - Circuit breaker: MUST have `client.WithCircuitBreaker` on Tenant Manager client
   - Backward compat: MUST have `TestMultiTenant_BackwardCompatibility` test
   - Non-canonical files: MUST NOT have custom tenant packages (`internal/tenant/`, `pkg/multitenancy/`, custom middleware). See [dev-multi-tenant SKILL.md § Phase 3](../dev-multi-tenant/SKILL.md#phase-3-non-canonical-file-detection-mandatory) for specific grep commands.
   - Each non-compliant item → ISSUE-XXX with severity based on impact
4. **If multi-tenant code is MISSING entirely** → ISSUE-XXX (CRITICAL): "Service does not support multi-tenant mode. MUST run ring:dev-multi-tenant."
5. **If non-compliant** → ISSUE-XXX per component: "Multi-tenant [component] is non-compliant. MUST be replaced with canonical lib-commons v4 pattern."
6. **Backward compatibility:** Service MUST work with `MULTI_TENANT_ENABLED=false` (default) and without any `MULTI_TENANT_*` env vars

## Performance & Operational Readiness

**These checks apply when multi-tenant IS implemented. Flag as ISSUE-XXX if missing.**

### Connection Pool Health
```bash
# Check pool configuration is parameterized (not hardcoded)
grep -rn "WithMaxTenantPools\|WithIdleTimeout" internal/ pkg/ cmd/ --include="*.go"
# Expected: Pool limits come from config (env vars), not hardcoded values

# Check for hardcoded pool sizes (outside config/bootstrap)
grep -rn "MaxOpenConns.*=\|MaxIdleConns.*=" internal/ pkg/ --include="*.go" | grep -v "_test.go" | grep -v "config\.\|Config\.\|cfg\."
# Expected: 0 matches outside config. Pool sizes should come from config or ConnectionSettings.
```
- ISSUE if pool limits are hardcoded → MEDIUM: "Pool limits MUST come from MULTI_TENANT_MAX_TENANT_POOLS config"
- ISSUE if idle timeout is missing → MEDIUM: "MUST configure WithIdleTimeout to prevent connection leaks"

### Circuit Breaker Configuration
```bash
# Verify circuit breaker is configured with env-driven thresholds
grep -rn "WithCircuitBreaker" internal/ pkg/ cmd/ --include="*.go"
# Expected: threshold and timeout come from config, not hardcoded
```
- ISSUE if circuit breaker uses hardcoded values → MEDIUM: "Circuit breaker thresholds MUST come from MULTI_TENANT_CIRCUIT_BREAKER_* config"

### Metrics Implementation
```bash
# Verify all 4 mandatory metrics exist
grep -rn "tenant_connections_total\|tenant_connection_errors_total\|tenant_consumers_active\|tenant_messages_processed_total" internal/ pkg/ --include="*.go"
# Expected: All 4 metrics present
```
- ISSUE if any metric missing → MEDIUM: "Missing multi-tenant metric: [name]. All 4 are MANDATORY."
- ISSUE if metrics are not no-op in single-tenant mode → LOW: "Metrics MUST use no-op when MULTI_TENANT_ENABLED=false"

### Graceful Shutdown
```bash
# Verify managers are closed on shutdown (check bootstrap, cmd, and pkg paths)
grep -rn "\.Close()\|\.Shutdown()" internal/bootstrap/ cmd/ pkg/ --include="*.go" 2>/dev/null
# Expected: PostgresManager.Close(), MongoManager.Close(), RabbitMQManager.Close() in shutdown path
```
- ISSUE if managers not closed on shutdown → HIGH: "Connection managers MUST be closed on graceful shutdown to prevent leaks"

### Error Handling Completeness
```bash
# Verify sentinel errors are handled (search all Go source paths)
grep -rn "ErrTenantNotFound\|ErrCircuitBreakerOpen\|ErrManagerClosed\|ErrServiceNotConfigured\|ErrTenantContextRequired\|IsTenantNotProvisionedError" internal/ pkg/ --include="*.go"
# Expected: All sentinel errors handled in middleware or error handler
```
- ISSUE if sentinel errors not handled → HIGH: "Multi-tenant error [name] not handled. See multi-tenant.md § Error Handling."

### Single-Tenant Adaptability (for non-MT codebases analyzed by dev-refactor)
```bash
# Check for global DB singletons (non-MT-adaptable)
# This catches package-level var db = ... patterns, NOT struct field access like r.connection.GetDB()
grep -rn "^var.*sql\.DB\|^var.*pgx\.Pool\|^var.*mongo\.Client\|^var.*redis\.Client" internal/ pkg/ --include="*.go" | grep -v "_test.go"
# Expected: 0 matches. Database connections should be struct fields, not package-level vars.

# Check that repository methods accept context as first parameter
# Sample 5 repository files and verify ctx is first param
for f in $(find internal/adapters/ pkg/adapters/ -name "*.go" ! -name "*_test.go" 2>/dev/null | head -5); do
  missing=$(grep -c "^func (r \*.*) .*[^(](" "$f" 2>/dev/null)
  with_ctx=$(grep -c "^func (r \*.*) .*(ctx context\.Context" "$f" 2>/dev/null)
  total=$((missing + with_ctx))
  if [ "$total" -gt 0 ] && [ "$with_ctx" -lt "$total" ]; then
    echo "LOW CTX COVERAGE: $f ($with_ctx/$total methods have ctx)"
  fi
done
# Expected: All repository methods accept ctx context.Context as first parameter.
```
- ISSUE if global DB singletons found → HIGH: "Package-level database variable blocks per-tenant connection routing. Refactor to struct field with constructor injection."
- ISSUE if <80% of repository methods accept ctx → MEDIUM: "Repository methods must accept ctx context.Context as first parameter for MT adaptation."
