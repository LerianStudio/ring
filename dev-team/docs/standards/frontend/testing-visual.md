# Frontend Standards - Visual/Snapshot Testing

> **Module:** testing-visual.md | **Sections:** 4 | **Parent:** [frontend.md](../frontend.md)

This module covers visual and snapshot testing patterns for React/Next.js applications. Ensures UI consistency through snapshot testing, responsive coverage, and component state verification.

> **Gate Reference:** This module is loaded by `ring:qa-frontend` at Gate 4 (Visual Testing).

---

## Table of Contents

| # | [Section Name](#anchor-link) | Description |
|---|------------------------------|-------------|
| 1 | [Snapshot Testing Patterns](#snapshot-testing-patterns-mandatory) | toMatchSnapshot usage with Vitest |
| 2 | [States Coverage](#states-coverage-mandatory) | All component states must be captured |
| 3 | [Responsive Snapshots](#responsive-snapshots-mandatory) | Mobile, tablet, desktop viewports |
| 4 | [Component Duplication Check](#component-duplication-check-mandatory) | Prevent recreating design-system components |

**Meta-sections:** [Output Format (Gate 4 - Visual Testing)](#output-format-gate-4---visual-testing), [Anti-Rationalization Table](#anti-rationalization-table-visual-testing)

---

## Snapshot Testing Patterns (MANDATORY)

**HARD GATE:** All UI components MUST have snapshot tests covering all states and viewports.

### Required Tool Setup

| Tool | Purpose | Config |
|------|---------|--------|
| Vitest | Test runner | `vitest.config.ts` |
| `@testing-library/react` | Component rendering | Standard setup |
| `toMatchSnapshot()` | Snapshot comparison | Built into Vitest |

### Basic Snapshot Pattern

```tsx
import { render } from '@testing-library/react';

describe('TransactionCard snapshots', () => {
    it('MUST match snapshot for default state', () => {
        const { container } = render(
            <TransactionCard transaction={mockTransaction} />
        );
        expect(container).toMatchSnapshot();
    });

    it('MUST match snapshot for pending state', () => {
        const { container } = render(
            <TransactionCard transaction={{ ...mockTransaction, status: 'pending' }} />
        );
        expect(container).toMatchSnapshot();
    });
});
```

### Naming Convention

| Pattern | Example |
|---------|---------|
| `{Component}.snapshot.test.tsx` | `TransactionCard.snapshot.test.tsx` |
| `{Page}.snapshot.test.tsx` | `DashboardPage.snapshot.test.tsx` |

### Snapshot Update Protocol

When snapshots change intentionally:

1. Review the diff carefully - MUST verify change is intentional
2. Update with `vitest --update` only after review
3. Commit updated snapshots with descriptive message

### FORBIDDEN Patterns

```tsx
// FORBIDDEN: Snapshot of entire page without isolation
expect(document.body).toMatchSnapshot(); // Too broad, too brittle

// FORBIDDEN: Skipping snapshot update review
// Running vitest --update without reviewing diffs

// FORBIDDEN: Snapshot without component states
describe('Button', () => {
    it('snapshot', () => {
        // WRONG: Only default state
        expect(render(<Button />).container).toMatchSnapshot();
    });
});
```

---

## States Coverage (MANDATORY)

**HARD GATE:** Every component MUST have snapshots for all applicable states.

### Required States

| State | When Applicable | What to Verify |
|-------|----------------|----------------|
| **Default** | All components | Normal render |
| **Empty** | Lists, tables, dashboards | Empty state message |
| **Loading** | Async components | Skeleton/spinner render |
| **Error** | Components with data fetch | Error message display |
| **Success** | Forms, mutations | Success feedback |
| **Disabled** | Interactive components | Visual disabled state |

### Edge Case States

| State | When Applicable | What to Verify |
|-------|----------------|----------------|
| **Long text** | Text displays | Overflow handling (truncation, wrapping) |
| **0 items** | Lists, tables | Empty state vs zero count |
| **1 item** | Lists, tables | Singular rendering |
| **1000+ items** | Lists, tables | Virtualization, pagination |
| **Special characters** | Text inputs | Unicode, emoji, RTL text |

### Test Pattern

```tsx
describe('TransactionList snapshots', () => {
    // Required states
    it('MUST match snapshot for default state', () => {
        const { container } = render(
            <TransactionList transactions={mockTransactions} />
        );
        expect(container).toMatchSnapshot();
    });

    it('MUST match snapshot for empty state', () => {
        const { container } = render(
            <TransactionList transactions={[]} />
        );
        expect(container).toMatchSnapshot();
    });

    it('MUST match snapshot for loading state', () => {
        const { container } = render(
            <TransactionList transactions={[]} isLoading={true} />
        );
        expect(container).toMatchSnapshot();
    });

    it('MUST match snapshot for error state', () => {
        const { container } = render(
            <TransactionList transactions={[]} error="Failed to load" />
        );
        expect(container).toMatchSnapshot();
    });

    // Edge cases
    it('MUST match snapshot with long transaction description', () => {
        const longTransaction = {
            ...mockTransactions[0],
            description: 'A'.repeat(500),
        };
        const { container } = render(
            <TransactionList transactions={[longTransaction]} />
        );
        expect(container).toMatchSnapshot();
    });

    it('MUST match snapshot with single item', () => {
        const { container } = render(
            <TransactionList transactions={[mockTransactions[0]]} />
        );
        expect(container).toMatchSnapshot();
    });
});
```

### State Coverage Checklist

Before marking visual tests complete:

- [ ] Default state snapshot exists
- [ ] Empty state snapshot exists (if applicable)
- [ ] Loading state snapshot exists (if applicable)
- [ ] Error state snapshot exists (if applicable)
- [ ] Disabled state snapshot exists (if applicable)
- [ ] Long text overflow snapshot exists (if applicable)
- [ ] All snapshots pass without updates needed

---

## Responsive Snapshots (MANDATORY)

**HARD GATE:** Components that render differently across viewports MUST have responsive snapshots.

### Required Viewports

| Viewport | Width | Use For |
|----------|-------|---------|
| **Mobile** | 375px | Phone layout |
| **Tablet** | 768px | Tablet layout |
| **Desktop** | 1280px | Desktop layout |

### Test Pattern with Viewport Simulation

```tsx
import { render } from '@testing-library/react';

const VIEWPORTS = {
    mobile: 375,
    tablet: 768,
    desktop: 1280,
} as const;

describe('Dashboard responsive snapshots', () => {
    Object.entries(VIEWPORTS).forEach(([name, width]) => {
        it(`MUST match snapshot at ${name} (${width}px)`, () => {
            // Set viewport width
            Object.defineProperty(window, 'innerWidth', {
                writable: true,
                configurable: true,
                value: width,
            });
            window.dispatchEvent(new Event('resize'));

            const { container } = render(<Dashboard />);
            expect(container).toMatchSnapshot();
        });
    });
});
```

### E2E Responsive Snapshots (Playwright)

```typescript
import { test, expect } from '@playwright/test';

const VIEWPORTS = [
    { name: 'mobile', width: 375, height: 812 },
    { name: 'tablet', width: 768, height: 1024 },
    { name: 'desktop', width: 1280, height: 720 },
];

for (const viewport of VIEWPORTS) {
    test(`Dashboard MUST render correctly at ${viewport.name}`, async ({ page }) => {
        await page.setViewportSize({ width: viewport.width, height: viewport.height });
        await page.goto('/dashboard');
        await expect(page).toHaveScreenshot(`dashboard-${viewport.name}.png`);
    });
}
```

### When Responsive Snapshots Are Required

| Applies To | Example |
|------------|---------|
| Page layouts | Dashboard, Settings, Profile |
| Navigation | Sidebar → hamburger menu |
| Tables | Full table → card view |
| Grids | Multi-column → single column |

### When NOT Required

| Does Not Apply To | Why |
|-------------------|-----|
| Icons | Same at all sizes |
| Simple buttons | No layout change |
| Inline text | Flow naturally |

---

## Component Duplication Check (MANDATORY)

<!-- Replace @your-org/design-system with your organization's design system package. -->
**HARD GATE:** MUST NOT recreate components that exist in `@your-org/design-system`.

### Detection Pattern

Before creating any component in `components/ui/`:

```bash
# Check if component exists in the design system
grep -r "export.*{ComponentName}" node_modules/@your-org/design-system/

# If found → Import from the design system
# If NOT found → Create as shadcn/radix fallback in components/ui/
```

### Test Pattern

```tsx
describe('Component duplication check', () => {
    it('MUST NOT duplicate design-system components', () => {
        // List of components available in the design system
        const designSystemComponents = [
            'Button', 'Input', 'Select', 'FormField', 'FormItem',
            'FormLabel', 'FormControl', 'FormMessage', 'FormTooltip',
            'Dialog', 'Sheet', 'Popover', 'Tooltip', 'Toast',
            'Table', 'Card', 'Badge', 'Avatar', 'Tabs',
            'Accordion', 'Separator', 'ScrollArea', 'Skeleton',
        ];

        // Check that project components/ui/ doesn't duplicate the design system
        // This is a documentation/review check, not a runtime test
    });
});
```

### Review Checklist

| Check | How to Verify |
|-------|---------------|
| No duplicated components | `ls components/ui/` vs design-system exports |
| Fallback components documented | Each shadcn component has comment: "Fallback: not in design-system" |
| Import paths correct | design-system → `@your-org/design-system`, fallback → `@/components/ui/` |

---

## Output Format (Gate 4 - Visual Testing)

```markdown
## Visual Testing Summary

| Metric | Value |
|--------|-------|
| Components with snapshots | X |
| Total snapshots | Y |
| States covered | Default, Empty, Loading, Error, Disabled |
| Viewports tested | 375px, 768px, 1280px |
| Snapshot failures | 0 |

### Snapshot Coverage by Component

| Component | States | Viewports | Edge Cases | Status |
|-----------|--------|-----------|------------|--------|
| TransactionList | 4/4 | 3/3 | Long text, 0 items | PASS |
| UserCard | 3/3 | N/A | Special chars | PASS |
| Dashboard | 4/4 | 3/3 | Empty state | PASS |

### Component Duplication Check

| Component in components/ui/ | In design-system? | Status |
|-----------------------------|------------------|--------|
| DateRangePicker | No | PASS (valid fallback) |
| Button | Yes | FAIL (duplicate!) |

### Standards Compliance

| Standard | Status | Evidence |
|----------|--------|----------|
| All snapshots pass | PASS | 0 failures |
| States coverage | PASS | All applicable states |
| Responsive coverage | PASS | 3 viewports |
| No design-system duplication | PASS | 0 duplicates |
```

---

## Anti-Rationalization Table (Visual Testing)

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Snapshot tests are brittle" | Brittle snapshots catch unintended changes. | **Write snapshots** |
| "We'll test visually in the browser" | Manual testing doesn't catch regressions. | **Add snapshot tests** |
| "Only default state matters" | Error and loading states are user-facing too. | **Test all states** |
| "Mobile layout is the same" | Responsive issues are common and subtle. | **Test all viewports** |
| "This shadcn component is better" | design-system is PRIMARY. Don't duplicate. | **Check design-system first** |
| "Snapshot diffs are too noisy" | Noisy diffs indicate untested refactors. | **Review and update snapshots** |

---
