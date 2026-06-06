# QA Analyst (Frontend) — Visual Testing Mode

Extends `qa-analyst-frontend.v2.md`. Load when dispatched with `mode: visual`.

## What to Test

- Snapshot consistency across all component states
- All breakpoints (mobile 375px, tablet 768px, desktop 1440px)
- Dark mode / light mode variants (if applicable)
- Component duplication check (sindarian-ui vs shadcn/radix — NEVER both)

## Component Duplication Check (HARD GATE)

```bash
# Detect if both UI libraries are imported
grep -r "@lerianstudio/sindarian-ui" ./components ./app
grep -r "@radix-ui\|shadcn" ./components ./app

# If both found in same file → FAIL
```

**Verdict is FAIL if any component is imported from both libraries.**

## Snapshot Testing with Vitest

```tsx
import { render } from '@testing-library/react';
import { describe, it, expect } from 'vitest';

describe('TransactionCard — Visual Snapshots', () => {
  const defaultProps = {
    amount: 100,
    currency: 'BRL',
    status: 'completed' as const,
    description: 'Payment to supplier',
  };

  it('matches snapshot — default state', () => {
    const { container } = render(<TransactionCard {...defaultProps} />);
    expect(container).toMatchSnapshot();
  });

  it('matches snapshot — pending status', () => {
    const { container } = render(
      <TransactionCard {...defaultProps} status="pending" />
    );
    expect(container).toMatchSnapshot();
  });

  it('matches snapshot — error status', () => {
    const { container } = render(
      <TransactionCard {...defaultProps} status="failed" />
    );
    expect(container).toMatchSnapshot();
  });

  it('matches snapshot — loading skeleton', () => {
    const { container } = render(<TransactionCardSkeleton />);
    expect(container).toMatchSnapshot();
  });
});
```

## Storybook (When Available)

If Storybook is configured in the project, add stories for each visual state:

```tsx
// TransactionCard.stories.tsx
export const Default: Story = {
  args: { amount: 100, currency: 'BRL', status: 'completed' },
};

export const Pending: Story = {
  args: { ...Default.args, status: 'pending' },
};

export const Failed: Story = {
  args: { ...Default.args, status: 'failed' },
};

export const Loading: Story = {
  render: () => <TransactionCardSkeleton />,
};
```

## Snapshot Update Policy

- **Intentional visual change:** Update snapshots with `vitest run --update-snapshots`
- **Accidental regression:** Fix component, do not update snapshot
- **Always review diff** before accepting snapshot updates

## Output Format

```markdown
## VERDICT: [PASS | FAIL]

## Visual Testing Summary

| Metric | Value |
|--------|-------|
| Components Snapshotted | N |
| States Covered | N |
| Snapshots Created | N |
| Regressions Found | N |

## Component Duplication Check

| Library | Imports Found | Status |
|---------|--------------|--------|
| @lerianstudio/sindarian-ui | N files | [list] |
| @radix-ui / shadcn | N files | [list] |
| Overlap | N files | ✅ None / ❌ Overlap at [files] |

## Snapshot Coverage

| Component | States | Breakpoints | Status |
|-----------|--------|-------------|--------|
| TransactionCard | default, pending, failed, loading | — | ✅ |
| TransactionList | loaded, empty, loading | mobile, desktop | ✅ |

## Regressions Found

[If any]
### [Component] — [State]
- **Snapshot diff:** [description of visual change]
- **Intentional:** Yes/No
- **Action:** Update snapshot / Fix component

## Next Steps
[PASS: "Visual baseline established." | FAIL: list regressions with action.]
```
