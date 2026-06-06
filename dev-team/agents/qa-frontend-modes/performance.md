# QA Analyst (Frontend) — Performance Testing Mode

Extends `qa-analyst-frontend.v2.md`. Load when dispatched with `mode: performance`.

## What to Test

- Core Web Vitals: LCP, CLS, INP per page
- Lighthouse score (Performance, Accessibility, Best Practices, SEO)
- Bundle size analysis (no unexpected large chunks)
- Image optimization (next/image usage, WebP format)
- Server Component usage for static/slow-changing data

## Core Web Vitals Thresholds

| Metric | Good | Needs Improvement | Poor |
|--------|------|-------------------|------|
| LCP (Largest Contentful Paint) | ≤2.5s | 2.5-4.0s | >4.0s |
| CLS (Cumulative Layout Shift) | ≤0.1 | 0.1-0.25 | >0.25 |
| INP (Interaction to Next Paint) | ≤200ms | 200-500ms | >500ms |

## Lighthouse CI

```yaml
# lighthouserc.yml
ci:
  collect:
    url:
      - http://localhost:3000/
      - http://localhost:3000/transactions
      - http://localhost:3000/transfers/new
    numberOfRuns: 3
  assert:
    assertions:
      categories:performance:
        - warn
        - minScore: 0.85
      categories:accessibility:
        - error
        - minScore: 0.9
      first-contentful-paint:
        - warn
        - maxNumericValue: 2000
      largest-contentful-paint:
        - error
        - maxNumericValue: 2500
      cumulative-layout-shift:
        - error
        - maxNumericValue: 0.1
```

## Bundle Analysis

```bash
# Next.js bundle analyzer
ANALYZE=true next build

# Check for:
# - Unexpected large chunks (>500KB parsed)
# - Duplicate dependencies
# - Missing tree-shaking
```

## Performance Test (Playwright + Web Vitals)

```typescript
import { test, expect } from '@playwright/test';

test('dashboard LCP is acceptable', async ({ page }) => {
  await page.goto('/dashboard');

  // Collect Web Vitals
  const lcp = await page.evaluate(() => {
    return new Promise<number>((resolve) => {
      new PerformanceObserver((list) => {
        const entries = list.getEntries();
        resolve(entries[entries.length - 1].startTime);
      }).observe({ entryTypes: ['largest-contentful-paint'] });

      // Timeout fallback
      setTimeout(() => resolve(0), 5000);
    });
  });

  expect(lcp).toBeLessThan(2500);
});
```

## Common Performance Issues

| Issue | Detection | Fix |
|-------|-----------|-----|
| Client Component where Server Component would work | `'use client'` directive check | Remove if no interactivity needed |
| Large images not using next/image | `<img src=` in components | Replace with `<Image>` from next/image |
| Missing lazy loading for below-fold content | Bundle entry point size | Use `dynamic(() => import(...), { ssr: false })` |
| Waterfall API calls | Sequential `await` in component | Use `Promise.all` or Suspense streaming |
| Missing `generateStaticParams` for dynamic routes | Dynamic routes analysis | Add `generateStaticParams` for static data |

## Output Format

```markdown
## VERDICT: [PASS | FAIL]

## Performance Testing Summary

| Metric | Value |
|--------|-------|
| Pages Tested | N |
| Lighthouse Runs | 3 per page |
| Bundle Analysis | Yes/No |

## Core Web Vitals Report

| Page | LCP | CLS | INP | Lighthouse Score |
|------|-----|-----|-----|-----------------|
| `/dashboard` | 1.8s ✅ | 0.05 ✅ | 180ms ✅ | 91 ✅ |
| `/transactions` | 3.1s ❌ | 0.08 ✅ | 220ms ⚠️ | 78 ⚠️ |
| `/transfers/new` | 2.1s ✅ | 0.03 ✅ | 150ms ✅ | 88 ✅ |

## Issues Found

[If any fail thresholds]
### `/transactions`: LCP 3.1s (exceeds 2.5s threshold)
- **Root cause:** Transaction list renders as Client Component with client-side data fetch
- **Fix:** Convert to Server Component with `async/await` data fetch, stream with Suspense

### `/transactions`: INP 220ms (needs improvement)
- **Root cause:** Filter dropdown triggers expensive re-render of full list
- **Fix:** Memoize filtered list with `useMemo`, virtualize with `@tanstack/virtual`

## Next Steps
[PASS: "Core Web Vitals within thresholds." | FAIL: list issues with fixes, prioritized by impact.]
```
