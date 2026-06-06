# Frontend Standards - E2E Testing

> **Module:** testing-e2e.md | **Sections:** 5 | **Parent:** [frontend.md](../frontend.md)

This module covers end-to-end testing patterns for React/Next.js applications using Playwright. E2E tests validate complete user flows from the product-designer's specifications.

> **Gate Reference:** This module is loaded by `ring:qa-frontend` at Gate 5 (E2E Testing).

---

## Table of Contents

| # | [Section Name](#anchor-link) | Description |
|---|------------------------------|-------------|
| 1 | [User Flow Consumption](#user-flow-consumption-mandatory) | Converting product-designer flows to tests |
| 2 | [Error Path Testing](#error-path-testing-mandatory) | API failures, timeouts, invalid data |
| 3 | [Cross-Browser Testing](#cross-browser-testing-mandatory) | Chromium, Firefox, WebKit coverage |
| 4 | [Responsive E2E](#responsive-e2e-mandatory) | Mobile, tablet, desktop viewport testing |
| 5 | [Selector Strategy](#selector-strategy-mandatory) | data-testid conventions |

**Meta-sections:** [Output Format (Gate 5 - E2E Testing)](#output-format-gate-5---e2e-testing), [Anti-Rationalization Table](#anti-rationalization-table-e2e-testing)

---

## User Flow Consumption (MANDATORY)

**HARD GATE:** All user flows from `ring:product-designer` output MUST have corresponding E2E tests.

### Input Source

The `ring:product-designer` agent produces `user-flows.md` with structured user flows:

```markdown
## User Flow: Create Transaction
1. User navigates to /transactions
2. User clicks "New Transaction" button
3. User fills in amount, description, category
4. User clicks "Submit"
5. System shows success toast
6. Transaction appears in list
```

### Conversion Pattern

```typescript
import { test, expect } from '@playwright/test';

// user-flows.md → E2E test
test.describe('Create Transaction flow', () => {
    test('happy path: user creates a transaction', async ({ page }) => {
        // Step 1: User navigates to /transactions
        await page.goto('/transactions');

        // Step 2: User clicks "New Transaction" button
        await page.getByRole('button', { name: 'New Transaction' }).click();

        // Step 3: User fills in amount, description, category
        await page.getByLabel('Amount').fill('100.50');
        await page.getByLabel('Description').fill('Office supplies');
        await page.getByLabel('Category').selectOption('expenses');

        // Step 4: User clicks "Submit"
        await page.getByRole('button', { name: 'Submit' }).click();

        // Step 5: System shows success toast
        await expect(page.getByRole('alert')).toContainText('Transaction created');

        // Step 6: Transaction appears in list
        await expect(page.getByText('Office supplies')).toBeVisible();
    });
});
```

### Flow Coverage Requirements

| Requirement | Minimum |
|-------------|---------|
| All user flows from product-designer | 100% coverage |
| Each flow has happy path test | MANDATORY |
| Each flow has at least 1 error path | MANDATORY |
| Backend handoff endpoints covered | All endpoints |

### Backend Handoff Integration

When a backend dev cycle produces a handoff, use the endpoints and contracts:

```typescript
// Backend handoff provides: POST /api/v1/transactions
// Contract: { amount: number, description: string, category_id: string }

test('MUST validate against backend contract', async ({ page }) => {
    // Intercept API call to verify contract
    const requestPromise = page.waitForRequest('**/api/v1/transactions');

    await page.goto('/transactions/new');
    await page.getByLabel('Amount').fill('100.50');
    await page.getByLabel('Description').fill('Test');
    await page.getByRole('button', { name: 'Submit' }).click();

    const request = await requestPromise;
    const body = request.postDataJSON();
    expect(body).toHaveProperty('amount');
    expect(body).toHaveProperty('description');
    expect(body).toHaveProperty('category_id');
});
```

---

## Error Path Testing (MANDATORY)

**HARD GATE:** All E2E flows MUST test error scenarios, not just happy paths.

### Required Error Scenarios

| Scenario | How to Test | What to Verify |
|----------|-------------|----------------|
| API 500 error | Mock API response | Error message shown |
| API timeout | Delay response | Loading state, timeout message |
| Validation error | Submit invalid data | Field-level error messages |
| Network offline | Simulate offline | Offline indicator, retry option |
| 404 page | Navigate to invalid URL | 404 page renders |
| Unauthorized | Expired/invalid token | Redirect to login |

### Test Pattern: API Error

```typescript
test('MUST show error when API returns 500', async ({ page }) => {
    // Mock API to return 500
    await page.route('**/api/v1/transactions', (route) => {
        route.fulfill({
            status: 500,
            body: JSON.stringify({ error: 'Internal Server Error' }),
        });
    });

    await page.goto('/transactions');
    await page.getByRole('button', { name: 'New Transaction' }).click();
    await page.getByLabel('Amount').fill('100');
    await page.getByRole('button', { name: 'Submit' }).click();

    // Verify error handling
    await expect(page.getByRole('alert')).toContainText('error');
    // Form should still be visible (not cleared)
    await expect(page.getByLabel('Amount')).toHaveValue('100');
});
```

### Test Pattern: Validation Error

```typescript
test('MUST show validation errors for empty required fields', async ({ page }) => {
    await page.goto('/transactions/new');

    // Submit without filling required fields
    await page.getByRole('button', { name: 'Submit' }).click();

    // Verify field-level error messages
    await expect(page.getByText('Amount is required')).toBeVisible();
    await expect(page.getByText('Description is required')).toBeVisible();
});
```

### Test Pattern: Network Timeout

```typescript
test('MUST handle API timeout gracefully', async ({ page }) => {
    await page.route('**/api/v1/transactions', async (route) => {
        // Simulate slow response
        await new Promise(resolve => setTimeout(resolve, 30000));
        route.fulfill({ status: 200, body: '[]' });
    });

    await page.goto('/transactions');

    // Loading state should be visible
    await expect(page.getByTestId('loading-skeleton')).toBeVisible();

    // After timeout, error message should appear
    await expect(page.getByText(/timeout|try again/i)).toBeVisible({ timeout: 15000 });
});
```

---

## Cross-Browser Testing (MANDATORY)

**HARD GATE:** E2E tests MUST pass on Chromium, Firefox, and WebKit.

### Playwright Configuration

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
    projects: [
        {
            name: 'chromium',
            use: { ...devices['Desktop Chrome'] },
        },
        {
            name: 'firefox',
            use: { ...devices['Desktop Firefox'] },
        },
        {
            name: 'webkit',
            use: { ...devices['Desktop Safari'] },
        },
    ],
});
```

### Browser-Specific Considerations

| Browser | Common Issues | How to Handle |
|---------|---------------|---------------|
| **Firefox** | Date input formatting differs | Use consistent date picker component |
| **WebKit** | Scroll behavior differs | Use `scrollIntoView` polyfill |
| **All** | Animation timing | Use `page.waitForSelector` not timeouts |

### Running Cross-Browser Tests

```bash
# Run all browsers
npx playwright test

# Run specific browser
npx playwright test --project=chromium
npx playwright test --project=firefox
npx playwright test --project=webkit

# Run with report
npx playwright test --reporter=html
```

---

## Responsive E2E (MANDATORY)

**HARD GATE:** User flows that differ by viewport MUST be tested at mobile, tablet, and desktop sizes.

### Required Viewports

| Viewport | Device | Width x Height |
|----------|--------|---------------|
| **Mobile** | iPhone 13 | 390 x 844 |
| **Tablet** | iPad | 768 x 1024 |
| **Desktop** | Desktop Chrome | 1280 x 720 |

### Test Pattern

```typescript
const VIEWPORTS = [
    { name: 'mobile', width: 390, height: 844 },
    { name: 'tablet', width: 768, height: 1024 },
    { name: 'desktop', width: 1280, height: 720 },
];

for (const viewport of VIEWPORTS) {
    test.describe(`${viewport.name} viewport`, () => {
        test.use({ viewport: { width: viewport.width, height: viewport.height } });

        test('navigation MUST be accessible', async ({ page }) => {
            await page.goto('/');

            if (viewport.name === 'mobile') {
                // Mobile: hamburger menu
                await page.getByTestId('mobile-menu-trigger').click();
                await expect(page.getByRole('navigation')).toBeVisible();
            } else {
                // Tablet/Desktop: sidebar visible
                await expect(page.getByRole('navigation')).toBeVisible();
            }
        });
    });
}
```

### What to Test Responsively

| Element | Mobile | Tablet | Desktop |
|---------|--------|--------|---------|
| Navigation | Hamburger menu | Collapsed sidebar | Full sidebar |
| Tables | Card view | Scrollable | Full table |
| Forms | Stacked fields | 2-column | Multi-column |
| Modals | Full-screen sheet | Centered modal | Centered modal |

---

## Selector Strategy (MANDATORY)

**HARD GATE:** All E2E selectors MUST use `data-testid` or semantic roles. CSS class selectors are FORBIDDEN except for layout containers where no semantic role applies.

### Selector Priority

| Priority | Selector | When to Use |
|----------|----------|-------------|
| 1 (best) | `getByRole` | Buttons, links, headings, form controls |
| 2 | `getByLabel` | Form inputs with labels |
| 3 | `getByText` | Static text content |
| 4 | `getByTestId` | Complex components without semantic role |
| 5 (avoid) | CSS selectors | FORBIDDEN except for layout containers |

### data-testid Convention

| Pattern | Example |
|---------|---------|
| `{component}-{element}` | `transaction-list-item` |
| `{page}-{section}` | `dashboard-summary` |
| `{action}-trigger` | `create-transaction-trigger` |
| `{component}-{state}` | `loading-skeleton` |

### Correct Pattern

```typescript
// CORRECT: Semantic roles
await page.getByRole('button', { name: 'Submit' }).click();
await page.getByLabel('Email').fill('user@example.com');
await page.getByRole('heading', { name: 'Dashboard' });

// CORRECT: data-testid for complex elements
await page.getByTestId('transaction-list-item').first().click();
await page.getByTestId('dashboard-summary');
```

### FORBIDDEN Patterns

```typescript
// FORBIDDEN: CSS class selectors
await page.locator('.btn-primary').click();
await page.locator('#submit-button').click();
await page.locator('div.transaction-card').click();

// FORBIDDEN: XPath
await page.locator('//div[@class="card"]').click();

// FORBIDDEN: Fragile text matching
await page.locator('text=Submit').click(); // Use getByRole instead
```

---

## Output Format (Gate 5 - E2E Testing)

```markdown
## E2E Testing Summary

| Metric | Value |
|--------|-------|
| User flows tested | X/Y (from product-designer) |
| Happy path tests | X |
| Error path tests | Y |
| Browsers tested | Chromium, Firefox, WebKit |
| Viewports tested | Mobile, Tablet, Desktop |
| Consecutive passes | 3/3 |

### Flow Coverage

| User Flow | Happy Path | Error Paths | Browsers | Viewports | Status |
|-----------|------------|-------------|----------|-----------|--------|
| Create Transaction | PASS | API 500, Validation | 3/3 | 3/3 | PASS |
| View Dashboard | PASS | Empty state, Timeout | 3/3 | 3/3 | PASS |
| User Login | PASS | Invalid creds, Lockout | 3/3 | 3/3 | PASS |

### Backend Handoff Verification

| Endpoint | Method | Contract Verified | Status |
|----------|--------|-------------------|--------|
| /api/v1/transactions | POST | amount, description, category_id | PASS |
| /api/v1/transactions | GET | pagination, filters | PASS |

### Standards Compliance

| Standard | Status | Evidence |
|----------|--------|----------|
| All user-flows covered | PASS | X/Y flows |
| Error paths tested | PASS | Y error tests |
| Cross-browser | PASS | 3/3 browsers |
| Responsive | PASS | 3 viewports |
| 3x consecutive pass | PASS | Run 3 times |
```

---

## Anti-Rationalization Table (E2E Testing)

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Unit tests cover the user flow" | Unit tests don't test real browser + API interaction. | **Write E2E tests** |
| "We only need Chromium" | Users use Firefox and Safari too. Cross-browser bugs are common. | **Test all 3 browsers** |
| "Mobile is just a smaller screen" | Navigation, layout, and interactions change. | **Test all viewports** |
| "Happy path is enough" | Users encounter errors. Error handling MUST be tested. | **Add error path tests** |
| "CSS selectors are fine" | CSS classes change with refactors. Semantic selectors are stable. | **Use roles and test IDs** |
| "Product-designer flows are just suggestions" | Flows define acceptance criteria. MUST cover all. | **Test all flows** |

---
