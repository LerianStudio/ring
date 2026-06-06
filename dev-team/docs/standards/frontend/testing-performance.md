# Frontend Standards - Performance Testing

> **Module:** testing-performance.md | **Sections:** 5 | **Parent:** [frontend.md](../frontend.md)

This module covers frontend performance testing patterns for React/Next.js applications. Ensures Core Web Vitals compliance, Lighthouse scores, bundle size control, and Server Component optimization.

> **Gate Reference:** This module is loaded by `ring:qa-frontend` at Gate 6 (Performance Testing).

---

## Table of Contents

| # | [Section Name](#anchor-link) | Description |
|---|------------------------------|-------------|
| 1 | [Core Web Vitals](#core-web-vitals-mandatory) | LCP, CLS, INP thresholds |
| 2 | [Lighthouse Score](#lighthouse-score-mandatory) | Performance score requirements |
| 3 | [Bundle Analysis](#bundle-analysis-mandatory) | Bundle size monitoring |
| 4 | [Server Component Audit](#server-component-audit-mandatory) | 'use client' minimization |
| 5 | [Anti-Pattern Detection](#anti-pattern-detection-mandatory) | Performance anti-patterns from frontend.md |

**Meta-sections:** [Output Format (Gate 6 - Performance Testing)](#output-format-gate-6---performance-testing), [Anti-Rationalization Table](#anti-rationalization-table-performance-testing)

---

## Core Web Vitals (MANDATORY)

**HARD GATE:** All pages MUST meet Core Web Vitals thresholds. Failure to meet any threshold = FAIL.

### Required Thresholds

| Metric | Threshold | Description |
|--------|-----------|-------------|
| **LCP** (Largest Contentful Paint) | < 2.5s | Time to render largest visible element |
| **CLS** (Cumulative Layout Shift) | < 0.1 | Visual stability of the page |
| **INP** (Interaction to Next Paint) | < 200ms | Responsiveness to user interaction |

### Measurement with web-vitals

```typescript
import { onLCP, onCLS, onINP, type Metric } from 'web-vitals';

// Integration in test setup
function measureWebVitals(): Promise<Record<string, number>> {
    return new Promise((resolve) => {
        const metrics: Record<string, number> = {};

        onLCP((metric: Metric) => { metrics.LCP = metric.value; });
        onCLS((metric: Metric) => { metrics.CLS = metric.value; });
        onINP((metric: Metric) => { metrics.INP = metric.value; });

        // Resolve after page interaction
        setTimeout(() => resolve(metrics), 5000);
    });
}
```

### E2E Measurement with Playwright

```typescript
import { test, expect } from '@playwright/test';

test('Dashboard MUST meet Core Web Vitals', async ({ page }) => {
    await page.goto('/dashboard');

    // Wait for page to be fully loaded
    await page.waitForLoadState('networkidle');

    // Measure LCP
    const lcp = await page.evaluate(() => {
        return new Promise<number>((resolve) => {
            new PerformanceObserver((list) => {
                const entries = list.getEntries();
                resolve(entries[entries.length - 1].startTime);
            }).observe({ type: 'largest-contentful-paint', buffered: true });
        });
    });
    expect(lcp).toBeLessThan(2500); // < 2.5s

    // Measure CLS
    const cls = await page.evaluate(() => {
        return new Promise<number>((resolve) => {
            let clsValue = 0;
            new PerformanceObserver((list) => {
                for (const entry of list.getEntries()) {
                    if (!(entry as any).hadRecentInput) {
                        clsValue += (entry as any).value;
                    }
                }
                resolve(clsValue);
            }).observe({ type: 'layout-shift', buffered: true });
            setTimeout(() => resolve(clsValue), 3000);
        });
    });
    expect(cls).toBeLessThan(0.1);
});
```

### Pages to Test

| Page Type | Why | Example |
|-----------|-----|---------|
| Landing/Home | First user impression | `/` |
| Dashboard | Heaviest data page | `/dashboard` |
| List pages | Data-heavy | `/transactions` |
| Form pages | Interactive | `/transactions/new` |
| Detail pages | Dynamic content | `/transactions/:id` |

---

## Lighthouse Score (MANDATORY)

**HARD GATE:** Lighthouse Performance score MUST be > 90 for all pages.

### Required Scores

| Category | Minimum Score |
|----------|---------------|
| **Performance** | > 90 |
| **Accessibility** | > 90 (also covered by Gate 2) |
| **Best Practices** | > 90 |
| **SEO** | > 80 (if applicable) |

### Running Lighthouse in CI

```bash
# Install
npm i -D @lhci/cli

# Run against local dev server
npx lhci autorun --config=lighthouserc.json

# Quick single-page check
npx lighthouse http://localhost:3000/dashboard --output=json --output-path=./lighthouse-report.json
```

### Lighthouse Configuration

```json
{
    "ci": {
        "collect": {
            "url": [
                "http://localhost:3000/",
                "http://localhost:3000/dashboard",
                "http://localhost:3000/transactions"
            ],
            "numberOfRuns": 3
        },
        "assert": {
            "assertions": {
                "categories:performance": ["error", { "minScore": 0.9 }],
                "categories:accessibility": ["error", { "minScore": 0.9 }],
                "categories:best-practices": ["error", { "minScore": 0.9 }]
            }
        }
    }
}
```

### Common Lighthouse Failures and Fixes

| Issue | Impact | Fix |
|-------|--------|-----|
| Unoptimized images | LCP, Performance | Use `next/image` |
| No font preloading | LCP | Add `<link rel="preload">` for fonts |
| Unused CSS/JS | Performance | Tree-shake, code-split |
| No text compression | Transfer size | Enable gzip/brotli |
| Third-party scripts | LCP, TBT | Lazy load, defer |
| Layout shifts | CLS | Set explicit dimensions on images/videos |

---

## Bundle Analysis (MANDATORY)

**HARD GATE:** Bundle size increase MUST NOT exceed 10% vs baseline without justification.

### Measurement Tools

| Tool | Purpose | Command |
|------|---------|---------|
| `@next/bundle-analyzer` | Next.js bundle visualization | `ANALYZE=true next build` |
| `source-map-explorer` | Treemap visualization | `npx source-map-explorer .next/static/**/*.js` |
| `bundlephobia` | Package size check | Check before adding dependency |

### Next.js Bundle Analyzer Setup

```typescript
// next.config.ts
import withBundleAnalyzer from '@next/bundle-analyzer';

const config = withBundleAnalyzer({
    enabled: process.env.ANALYZE === 'true',
})({
    // ... other config
});

export default config;
```

### Size Budget

| Budget | Threshold | What to Check |
|--------|-----------|---------------|
| **Total JS** | < 200KB (gzipped) | First load JS |
| **Per-page JS** | < 50KB (gzipped) | Page-specific bundle |
| **Single dependency** | < 50KB (gzipped) | Any single package |
| **Increase vs baseline** | < 10% | Compared to previous build |

### Verification Pattern

```bash
# Build and capture sizes
next build 2>&1 | grep -A 20 "Route (app)"

# Compare with baseline
# Store baseline in: .next-size-baseline.json
# Compare after build
```

### Tree-Shaking Verification for sindarian-ui

```typescript
// CORRECT: Named imports (tree-shakeable)
import { Button, Input } from '@lerianstudio/sindarian-ui';

// FORBIDDEN: Wildcard import (imports everything)
import * as SindarianUI from '@lerianstudio/sindarian-ui';

// FORBIDDEN: Default import of entire library
import SindarianUI from '@lerianstudio/sindarian-ui';
```

---

## Server Component Audit (MANDATORY)

**HARD GATE:** `'use client'` directive MUST only be used when strictly necessary.

### When 'use client' Is Required

| Requires 'use client' | Does NOT Require 'use client' |
|------------------------|-------------------------------|
| `useState`, `useReducer` | Static rendering |
| `useEffect`, `useLayoutEffect` | Data fetching (async) |
| `onClick`, `onChange` event handlers | `<Link>` navigation |
| Browser APIs (`window`, `localStorage`) | Server-side data transforms |
| `useContext` (client context) | Displaying data from props |

### Audit Pattern

```bash
# Find all 'use client' files
grep -rn "'use client'" --include="*.tsx" --include="*.ts" src/

# Count server vs client components
echo "Client components:"
grep -rl "'use client'" --include="*.tsx" src/ | wc -l

echo "Total components:"
find src/ -name "*.tsx" | wc -l

# Percentage should be < 40% client components
```

### Common Violations

| Pattern | Why It's Wrong | Fix |
|---------|----------------|-----|
| `'use client'` on layout | Makes entire subtree client | Extract interactive parts |
| `'use client'` for data display | No interactivity needed | Remove directive |
| `'use client'` for `<Link>` | Next.js Link works in server | Remove directive |
| Entire page as client | Loses server rendering benefits | Split into server + client parts |

### Test Pattern

```typescript
describe('Server Component audit', () => {
    it('MUST have < 40% client components', () => {
        // This is verified via build analysis
        // Count 'use client' files vs total .tsx files
    });

    it('MUST NOT have use client on layout files', () => {
        // Check layout.tsx files don't have 'use client'
    });
});
```

---

## Anti-Pattern Detection (MANDATORY)

**HARD GATE:** All performance anti-patterns from [frontend.md Section 12](../frontend.md#forbidden-patterns) MUST be detected and reported.

### Performance Anti-Patterns to Detect

| Pattern | Detection | Fix |
|---------|-----------|-----|
| Bare `<img>` without `next/image` | `grep -rn '<img' --include="*.tsx"` | Replace with `next/image` |
| Inline styles in loops | Manual review | Use `className` or CSS Modules |
| Missing `key` prop | ESLint rule `react/jsx-key` | Add stable `key` prop |
| `useEffect` for data fetching | `grep -rn 'useEffect.*fetch'` | Use TanStack Query |
| Unoptimized re-renders | React DevTools Profiler | Add `memo`, `useMemo` where measured |

### Automated Detection

```bash
# Bare <img> tags (should use next/image)
grep -rn '<img ' --include="*.tsx" src/ | grep -v 'next/image' | grep -v '_test'

# useEffect for fetching (should use TanStack Query)
grep -rn 'useEffect.*fetch\|useEffect.*axios\|useEffect.*api' --include="*.tsx" src/

# Wildcard sindarian-ui imports (not tree-shakeable)
grep -rn "import \* as.*sindarian" --include="*.tsx" --include="*.ts" src/

# Missing next/image imports where <img> is used
grep -rln '<img ' --include="*.tsx" src/ | while read f; do
    grep -q "next/image" "$f" || echo "VIOLATION: $f uses <img> without next/image"
done
```

### Quality Gate Checklist

Before marking performance tests complete:

- [ ] All pages meet LCP < 2.5s
- [ ] All pages meet CLS < 0.1
- [ ] All pages meet INP < 200ms
- [ ] Lighthouse Performance score > 90
- [ ] Bundle size within 10% of baseline
- [ ] No bare `<img>` tags (all use `next/image`)
- [ ] `'use client'` used only when necessary (< 40% of components)
- [ ] sindarian-ui imports are tree-shakeable (named imports only)
- [ ] No `useEffect` for data fetching

---

## Output Format (Gate 6 - Performance Testing)

```markdown
## Performance Testing Summary

| Metric | Value | Threshold | Status |
|--------|-------|-----------|--------|
| LCP | X.Xs | < 2.5s | PASS/FAIL |
| CLS | X.XX | < 0.1 | PASS/FAIL |
| INP | Xms | < 200ms | PASS/FAIL |
| Lighthouse Performance | XX | > 90 | PASS/FAIL |
| Bundle size change | +X% | < 10% | PASS/FAIL |

### Core Web Vitals by Page

| Page | LCP | CLS | INP | Status |
|------|-----|-----|-----|--------|
| / | 1.2s | 0.02 | 85ms | PASS |
| /dashboard | 2.1s | 0.05 | 120ms | PASS |
| /transactions | 1.8s | 0.01 | 95ms | PASS |

### Bundle Analysis

| Metric | Current | Baseline | Change | Status |
|--------|---------|----------|--------|--------|
| Total JS (gzipped) | 180KB | 175KB | +2.8% | PASS |
| Largest page | 45KB | 42KB | +7.1% | PASS |

### Server Component Audit

| Metric | Value |
|--------|-------|
| Total .tsx files | X |
| Client components | Y |
| Client ratio | Z% (< 40%) |

### Anti-Pattern Detection

| Pattern | Occurrences | Status |
|---------|-------------|--------|
| Bare <img> | 0 | PASS |
| useEffect for fetching | 0 | PASS |
| Wildcard sindarian imports | 0 | PASS |

### Standards Compliance

| Standard | Status | Evidence |
|----------|--------|----------|
| Core Web Vitals | PASS | All pages within thresholds |
| Lighthouse > 90 | PASS | Score: XX |
| Bundle size | PASS | +X% (< 10%) |
| Server Components | PASS | Y% client (< 40%) |
| Anti-patterns | PASS | 0 violations |
```

---

## Anti-Rationalization Table (Performance Testing)

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Performance is fine on my machine" | Users have slower devices and connections. | **Measure with Lighthouse** |
| "We'll optimize later" | Performance debt compounds. Fix during development. | **Meet thresholds now** |
| "Bundle size doesn't matter with fast internet" | Mobile users on 3G exist. Bundle size matters. | **Stay within budget** |
| "Everything needs to be a client component" | Server components reduce JS sent to browser. | **Audit 'use client' usage** |
| "One extra dependency won't hurt" | Dependencies compound. 50KB x 10 = 500KB. | **Check bundlephobia first** |
| "next/image is too complex" | next/image provides free optimization (WebP, lazy load). | **Always use next/image** |

---
