# QA Analyst (Frontend) — E2E Testing Mode

Extends `qa-analyst-frontend.v2.md`. Load when dispatched with `mode: e2e`.

## What to Test

- Full user flows from `user-flows.md` (product-designer handoff)
- Happy path and critical error paths
- Cross-page navigation and state persistence
- Authentication flows
- Form submission with real validation

## Playwright Test Structure

```typescript
import { test, expect } from '@playwright/test';

test.describe('Transfer Flow', () => {
  test.beforeEach(async ({ page }) => {
    // Authenticate before each test
    await page.goto('/auth/login');
    await page.fill('[name="email"]', 'test@lerian.studio');
    await page.fill('[name="password"]', 'testpassword');
    await page.click('button[type="submit"]');
    await page.waitForURL('/dashboard');
  });

  test('happy path: create transfer successfully', async ({ page }) => {
    await page.goto('/transfers/new');

    // Fill form
    await page.fill('[name="amount"]', '100.00');
    await page.selectOption('[name="currency"]', 'BRL');
    await page.fill('[name="description"]', 'Test payment');

    // Submit
    await page.click('button[type="submit"]');

    // Verify success
    await expect(page).toHaveURL(/\/transfers\/[a-z0-9-]+$/);
    await expect(page.getByText('Transfer created successfully')).toBeVisible();
  });

  test('error path: insufficient balance shows error', async ({ page }) => {
    await page.goto('/transfers/new');
    await page.fill('[name="amount"]', '999999999.00');
    await page.click('button[type="submit"]');

    await expect(page.getByRole('alert')).toContainText('Insufficient balance');
    await expect(page).toHaveURL('/transfers/new'); // stays on same page
  });

  test('validation: required fields shown on empty submit', async ({ page }) => {
    await page.goto('/transfers/new');
    await page.click('button[type="submit"]');

    await expect(page.getByText('Amount is required')).toBeVisible();
    await expect(page.getByText('Currency is required')).toBeVisible();
  });
});
```

## Flow Coverage (From user-flows.md)

Before implementing tests, read `user-flows.md` from product-designer:

```markdown
## Flow Coverage Checklist

From user-flows.md:
- [ ] Flow 1: Transfer creation — happy path
- [ ] Flow 1: Transfer creation — validation error
- [ ] Flow 1: Transfer creation — insufficient balance
- [ ] Flow 2: Transaction list — filter by status
- [ ] Flow 2: Transaction list — pagination
```

## Page Object Pattern (For Complex Flows)

```typescript
class TransferPage {
  constructor(private page: Page) {}

  async goto() {
    await this.page.goto('/transfers/new');
  }

  async fillAmount(amount: string) {
    await this.page.fill('[name="amount"]', amount);
  }

  async submit() {
    await this.page.click('button[type="submit"]');
  }

  async getErrorMessage() {
    return this.page.getByRole('alert').textContent();
  }
}
```

## Running E2E Tests

```bash
# Run all E2E tests
npx playwright test

# Run specific flow
npx playwright test --grep "Transfer Flow"

# With UI (debugging)
npx playwright test --ui
```

## Output Format

```markdown
## VERDICT: [PASS | FAIL]

## E2E Testing Summary

| Metric | Value |
|--------|-------|
| Flows Tested | N |
| Scenarios | N |
| Browser | Chromium (default) |
| Duration | Xs |

## Flow Coverage

| Flow | Scenario | Status |
|------|----------|--------|
| Transfer creation | Happy path | ✅ PASS |
| Transfer creation | Validation error | ✅ PASS |
| Transfer creation | Insufficient balance | ✅ PASS |
| Transaction list | Filter by status | ✅ PASS |

## Failures

[If any]
### [Flow]: [Scenario]
- **Error:** [description]
- **Screenshot:** `test-results/[name].png`
- **Root cause:** [analysis]
- **Fix:** [recommendation]

## Next Steps
[PASS: "All flows pass." | FAIL: list failures with fixes.]
```
