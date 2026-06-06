---
name: ring:dev-k6-load-testing
description: |
  Load testing skill using k6 — generates tests following the Lerian k6 platform
  conventions for execution on Palantir (Self-Service Testing).
  Produces product directories, scenario YAMLs, helper clients, and bundleable
  test scripts compatible with the LerianStudio/k6 platform/ structure.
  Standalone skill, not gated — invoke on demand or as part of CI.
---

# k6 Load Testing (Palantir Platform)

## When to use
- After integration testing passes
- Before production deploy of performance-sensitive changes
- New API endpoints or significant throughput-path changes
- Need to validate SLOs under load (latency, error rate, throughput)
- CI pipeline requires load test gate via Palantir

## Skip when
- Task is documentation-only, configuration-only, or non-code
- No HTTP/gRPC endpoints affected by the change
- Changes limited to static assets, configs, or non-runtime code
- Service has no network-facing interface

## Related
**Complementary:** ring:dev-implementation, ring:codereview


This skill generates k6 load tests following the Lerian k6 platform conventions.
Tests are structured for execution via Palantir (Self-Service Testing) and are
bundled by webpack into self-contained scripts deployed to EKS via k6-operator.

**Reference repository:** `LerianStudio/k6` — specifically `platform/` directory.

**Block conditions:**
- Test script missing `handleSummary` export = FAIL (Palantir can't collect results)
- `scenario.yaml` param names don't match `__ENV` vars in test.js = FAIL
- Test doesn't read VUS/DURATION from `__ENV` = FAIL
- No `checkResponse()` from shared utils = FAIL
- Missing `product.yaml` = FAIL

## Step 1: Validate Input

Required:
- `product` — product name in lowercase (e.g., `midaz`, `tracer`, `reporter`, `matcher`)
- `endpoints` — list of endpoints to test, each with method, path, and optional payload
- `base_port` — local dev port for the product (e.g., 3000 for midaz, 4020 for tracer)

Optional:
- `scenario_types` — which scenarios to generate (default: `[smoke, load, stress]`)
- `auth_type` — `bearer` (default, uses `shared/auth.js`) | `api-key` | `none`
- `api_key_header` — header name for API key auth (default: `X-API-Key`)
- `custom_thresholds` — override default thresholds
- `existing_product` — if true, extend existing product directory

## Step 2: Understand the Platform Structure

All test code lives under `platform/` in the `LerianStudio/k6` repo:

```
platform/
├── products/{product}/
│   ├── product.yaml              # Product metadata (read by Palantir)
│   ├── helpers/
│   │   └── client.js             # HTTP client for this product's API
│   └── scenarios/
│       └── {scenario}/
│           ├── scenario.yaml     # Catalog metadata (read by Palantir)
│           └── test.js           # k6 test script (webpack entry point)
├── shared/
│   ├── auth.js                   # getAuthHeaders(), authenticate()
│   ├── utils.js                  # checkResponse(), sleepWithJitter(), defaultHandleSummary()
│   └── palantir/                 # SDK for complex scenarios (fixtures, runtime)
│       ├── index.js              # scenario(), fixture(), createTestExports()
│       ├── runtime.js            # Builds k6 exports from config
│       ├── scenario.js           # Declarative scenario config builder
│       └── templates.js          # Built-in test type templates (smoke/quick/full/breakpoint/soak)
├── dist/                         # Webpack output (git-ignored)
├── build.js                      # Bundler entry point
├── webpack.config.js             # Auto-discovers products/*/scenarios/*/test.js
├── config.yaml                   # Platform-level test catalog metadata
└── package.json
```

### Two Patterns for Writing Tests

**Pattern A: Simple client (recommended for most tests)**

Product `helpers/client.js` provides `get()`, `post()`, `patch()`, `del()` scoped to
the product's base URL. Scenarios import the client and `shared/utils.js` directly.

Used by: smoke, load, stress, soak scenarios for midaz, console, pix.

**Pattern B: Palantir SDK (for complex scenarios with fixtures)**

For scenarios that need declarative fixture setup (create rules, limits, etc.),
sanity checks, and built-in metric tracking, use the Palantir SDK:

```javascript
import { scenario, fixture, createTestExports } from '../../../../shared/palantir/index.js';
```

Used by: tracer scenarios (pass-through, denied-by-limit, denied-by-rule, complex-approval).

**Choose Pattern A** unless the product requires setup fixtures (rules, limits, etc.) that
must be created and activated before load can run.

## Step 3: Create Product Files

### 3a. product.yaml

Create `platform/products/{product}/product.yaml`:

```yaml
product: {product}
description: "{Product description} - performance tests"
base_url_env: {PRODUCT}_BASE_URL

defaults:
  thresholds:
    http_req_duration: ["p(95)<500", "p(99)<1000"]
    http_req_failed: ["rate<0.01"]
  env:
    API_VERSION: "v1"

tags:
  - {product}
  - {relevant-tags}
```

### 3b. helpers/client.js

Create `platform/products/{product}/helpers/client.js`:

For **bearer auth** (most products):

```javascript
import http from 'k6/http';
import { getAuthHeaders } from '../../../shared/auth.js';

const BASE_URL = __ENV.{PRODUCT}_BASE_URL || __ENV.TARGET_URL || 'http://localhost:{base_port}';
const API_VERSION = __ENV.API_VERSION || 'v1';

export function apiUrl(path) {
  return `${BASE_URL}/${API_VERSION}${path}`;
}

export function get(path, params = {}) {
  const { headers: extraHeaders, ...restParams } = params;
  return http.get(apiUrl(path), {
    ...restParams,
    headers: { ...getAuthHeaders(), ...extraHeaders },
  });
}

export function post(path, body, params = {}) {
  const { headers: extraHeaders, ...restParams } = params;
  return http.post(apiUrl(path), JSON.stringify(body), {
    ...restParams,
    headers: { ...getAuthHeaders(), ...extraHeaders },
  });
}

export function patch(path, body, params = {}) {
  const { headers: extraHeaders, ...restParams } = params;
  return http.patch(apiUrl(path), JSON.stringify(body), {
    ...restParams,
    headers: { ...getAuthHeaders(), ...extraHeaders },
  });
}

export function del(path, params = {}) {
  const { headers: extraHeaders, ...restParams } = params;
  return http.del(apiUrl(path), null, {
    ...restParams,
    headers: { ...getAuthHeaders(), ...extraHeaders },
  });
}
```

For **API key auth** (e.g., tracer):

```javascript
import http from 'k6/http';

const BASE_URL = __ENV.{PRODUCT}_BASE_URL || __ENV.TARGET_URL || 'http://localhost:{base_port}';
const API_VERSION = __ENV.API_VERSION || 'v1';

function getHeaders() {
  const headers = { 'Content-Type': 'application/json' };
  const apiKey = __ENV.{PRODUCT}_API_KEY;
  if (apiKey) {
    headers['{api_key_header}'] = apiKey;
  }
  return headers;
}

export function apiUrl(path) {
  return `${BASE_URL}/${API_VERSION}${path}`;
}

// ... same get/post/patch/del pattern with getHeaders() ...

export function readiness() {
  return http.get(`${BASE_URL}/health`, {
    tags: { name: '{product}_readiness' },
  });
}
```

**Key rules for the client:**
- `__ENV.TARGET_URL` is the primary URL injected by Palantir SST — always include as fallback
- Product-specific env var (`{PRODUCT}_BASE_URL`) allows override in multi-product environments
- Never hardcode auth credentials — read from `__ENV`

## Step 4: Create Scenario Files

### 4a. scenario.yaml (per scenario)

Create `platform/products/{product}/scenarios/{type}/scenario.yaml`:

```yaml
name: "{Scenario Display Name}"
description: "{What this scenario validates}"
type: {smoke|load|stress|soak|functional}
tags: [{type}, {relevant-tags}]

defaults:
  vus: {default_vus}
  duration: "{default_duration}"
  parallelism: 1

params:
  - name: VUS
    label: "Virtual Users"
    type: number
    default: "{default_vus}"
    description: "Number of concurrent virtual users"
  - name: DURATION
    label: "Test Duration"
    type: string
    default: "{default_duration}"
    description: "How long the test runs (e.g. 1m, 5m, 30s)"
```

**Rules:**
- Every `params[].name` MUST match a `__ENV.XXX` variable read in test.js
- `type` must be one of: smoke, load, stress, soak, breakpoint, capacity, functional
- `defaults` define what Palantir pre-fills in the form

### Default values per scenario type

| Type | VUs | Duration | Thresholds |
|------|-----|----------|------------|
| smoke | 3-5 | 1m | p(95)<500 |
| load | 50 | 10m | p(95)<300, p(99)<500 |
| stress | 100-200 | 5m | p(95)<500, p(99)<1000 |
| soak | 30 | 30m-2h | p(95)<300, p(99)<500 |

### 4b. test.js (Pattern A — Simple)

Create `platform/products/{product}/scenarios/{type}/test.js`:

**Smoke test:**

```javascript
import { sleep } from 'k6';
import { get } from '../../helpers/client.js';
import { checkResponse, sleepWithJitter, defaultHandleSummary } from '../../../../shared/utils.js';

export const options = {
  vus: __ENV.VUS ? parseInt(__ENV.VUS) : 5,
  duration: __ENV.DURATION || '1m',
  thresholds: {
    http_req_duration: ['p(95)<500'],
    http_req_failed: ['rate<0.01'],
  },
};

export default function () {
  // Health/readiness check
  const healthRes = get('/health');
  checkResponse(healthRes, 200, 'health check');

  // Representative API calls for this product
  const res = get('/{resource}');
  checkResponse(res, 200, 'list {resource}');

  sleep(sleepWithJitter(1));
}

// MANDATORY: Palantir results collection
export { defaultHandleSummary as handleSummary };
```

**Load test (with ramp-up stages):**

```javascript
import { sleep } from 'k6';
import { get, post } from '../../helpers/client.js';
import { checkResponse, sleepWithJitter, randomString, defaultHandleSummary } from '../../../../shared/utils.js';

const VUS = __ENV.VUS ? parseInt(__ENV.VUS) : 50;
const DURATION = __ENV.DURATION || '10m';
const RAMP_UP = __ENV.RAMP_UP || '2m';

export const options = {
  stages: [
    { duration: RAMP_UP, target: VUS },
    { duration: DURATION, target: VUS },
    { duration: '1m', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<300', 'p(99)<500'],
    http_req_failed: ['rate<0.01'],
  },
};

export default function () {
  // Product-specific API flow
  // Example: list → get → create cycle
  const listRes = get('/{resource}');
  checkResponse(listRes, 200, 'list {resource}');

  if (listRes.status === 200) {
    const items = JSON.parse(listRes.body);
    if (items.items && items.items.length > 0) {
      const id = items.items[0].id;
      const detailRes = get(`/{resource}/${id}`);
      checkResponse(detailRes, 200, 'get {resource}');
    }
  }

  sleep(sleepWithJitter(0.5, 0.3));
}

export { defaultHandleSummary as handleSummary };
```

**Stress test:**

```javascript
import { sleep } from 'k6';
import { get, post } from '../../helpers/client.js';
import { checkResponse, sleepWithJitter, randomString, defaultHandleSummary } from '../../../../shared/utils.js';

const VUS = __ENV.VUS ? parseInt(__ENV.VUS) : 100;
const DURATION = __ENV.DURATION || '5m';
const RAMP_UP = __ENV.RAMP_UP || '1m';

export const options = {
  stages: [
    { duration: RAMP_UP, target: VUS },
    { duration: DURATION, target: VUS },
    { duration: '30s', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<500', 'p(99)<1000'],
    http_req_failed: ['rate<0.02'],
  },
};

export default function () {
  // Higher-intensity flow: mixed reads + writes
  // Adapt to product's critical path

  sleep(sleepWithJitter(0.3, 0.2));
}

export { defaultHandleSummary as handleSummary };
```

### 4c. test.js (Pattern B — Palantir SDK with Fixtures)

For products that need fixture setup (like Tracer with rules/limits):

```javascript
import { scenario, fixture, createTestExports } from '../../../../shared/palantir/index.js';
import * as client from '../../helpers/client.js';

const config = scenario({
  name: '{Scenario Name}',
  fixtures: [
    fixture.rule({
      expression: '{CEL expression}',
      action: 'ALLOW',
      description: '{rule description}',
    }),
    fixture.limit({
      limitType: 'DAILY',
      maxAmount: 999000000,
      description: '{limit description}',
    }),
  ],
  sanity: {
    expectedDecision: 'ALLOW',
  },
  thresholds: {
    'http_req_duration': ['p(95)<500', 'p(99)<1000'],
    'txn_correctness_rate': ['rate>0.99'],
    'txn_error_rate': ['rate<0.01'],
  },
});

function buildPayload() {
  return {
    // Product-specific payload
  };
}

function checks(body) {
  return {
    'decision is ALLOW': () => body.decision === 'ALLOW',
    // Product-specific checks
  };
}

const test = createTestExports({ config, client, buildPayload, checks });
export const options = test.options;
export const setup = test.setup;
export default test.default;
export const handleSummary = test.handleSummary;
```

## Step 5: Build and Verify

```bash
cd platform
npm install          # first time only
npm run build        # webpack bundles all scenarios
```

Verify bundle was created:

```bash
ls -la dist/{product}/
# Expected: {scenario}.bundle.js for each scenario
```

Verify bundle runs locally:

```bash
# With product running locally
k6 run dist/{product}/smoke.bundle.js

# Override target URL
k6 run -e TARGET_URL=http://localhost:{port} dist/{product}/smoke.bundle.js
```

## Step 6: Mandatory Checklist

Before marking complete, verify ALL items:

- [ ] `products/{product}/product.yaml` exists with `base_url_env` and default thresholds
- [ ] `products/{product}/helpers/client.js` exists with `TARGET_URL` fallback
- [ ] At least `scenarios/smoke/` exists with both `scenario.yaml` and `test.js`
- [ ] Every `scenario.yaml` param `name` matches a `__ENV.XXX` in `test.js`
- [ ] Every `test.js` exports `handleSummary` (re-export `defaultHandleSummary`)
- [ ] Every `test.js` reads `VUS` and `DURATION` from `__ENV`
- [ ] Every `test.js` defines `thresholds` in `options`
- [ ] Every `test.js` uses `checkResponse()` from `shared/utils.js`
- [ ] `npm run build` succeeds and produces bundles in `dist/{product}/`
- [ ] Bundle runs locally with `k6 run dist/{product}/smoke.bundle.js`

## Environment Variables Reference

### Injected by Palantir SST (available in all tests)

| Variable | Description |
|----------|-------------|
| `TARGET_URL` | Base URL of the product under test |
| `VUS` | Number of virtual users |
| `DURATION` | Test duration (e.g., `30s`, `5m`) |
| `ENVIRONMENT_ID` | SST environment UUID |
| `K6_TESTID` | Test run UUID (for Grafana filtering) |

### Authentication (from shared/auth.js)

| Variable | Description |
|----------|-------------|
| `AUTH_TOKEN` | Bearer token (takes priority) |
| `AUTH_USER` / `AUTH_PASS` | Basic auth credentials |
| `AUTH_URL` | OAuth token endpoint |
| `AUTH_CLIENT_ID` | OAuth client ID |
| `AUTH_CLIENT_SECRET` | OAuth client secret |

### Shared Utilities (from shared/utils.js)

| Function | Description |
|----------|-------------|
| `checkResponse(res, status?, label?)` | Asserts status + duration <5s, tracks `custom_error_rate` and `custom_request_duration` |
| `sleepWithJitter(base?, jitter?)` | Returns `base + random(0, jitter)` — avoids thundering herd |
| `defaultHandleSummary(data)` | Writes summary JSON to `/tmp/summary.json` + stdout markers for SST collection |
| `randomString(length?)` | Random alphanumeric string |

## Output Report

```markdown
## Load Test Summary

| Metric | Value |
|--------|-------|
| Result | PASS |
| Product | {product} |
| Scenarios Created | smoke, load, stress |
| Pattern | A (Simple client) / B (Palantir SDK) |

## Files Created

| File | Purpose |
|------|---------|
| `platform/products/{product}/product.yaml` | Product metadata |
| `platform/products/{product}/helpers/client.js` | HTTP client |
| `platform/products/{product}/scenarios/smoke/scenario.yaml` | Smoke catalog |
| `platform/products/{product}/scenarios/smoke/test.js` | Smoke test |
| `platform/products/{product}/scenarios/load/scenario.yaml` | Load catalog |
| `platform/products/{product}/scenarios/load/test.js` | Load test |

## Palantir Integration

- Bundle path: `dist/{product}/{scenario}.bundle.js`
- Build verified: ✅
- Local run verified: ✅ (smoke @ localhost:{port})

## Next Steps
- Push to `LerianStudio/k6` repository
- Verify in Palantir UI: product appears in catalog with all scenarios
- Run smoke test via SST to validate end-to-end flow
```
