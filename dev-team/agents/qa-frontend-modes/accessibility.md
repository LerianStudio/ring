# QA Analyst (Frontend) — Accessibility Testing Mode

Extends `qa-analyst-frontend.v2.md`. Load when dispatched with `mode: accessibility`.

## What to Test

- WCAG 2.1 AA compliance
- axe-core automated scan for violations
- Keyboard navigation (Tab, Enter, Escape, Arrow keys)
- Screen reader announcements (ARIA live regions, landmark roles)
- Focus management (modal open/close, error announcement)
- Color contrast ratios (minimum 4.5:1 for normal text)
- Touch targets (minimum 44×44px)

## Automated Scan (axe-core)

```tsx
import { axe, toHaveNoViolations } from 'jest-axe';
expect.extend(toHaveNoViolations);

describe('TransactionList — Accessibility', () => {
  it('has no axe violations', async () => {
    const { container } = render(
      <TransactionList items={mockTransactions} />
    );
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('has no axe violations in loading state', async () => {
    const { container } = render(<TransactionList items={[]} isLoading />);
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('has no axe violations in error state', async () => {
    const { container } = render(
      <TransactionList items={[]} error={new Error('Failed')} />
    );
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });
});
```

## Keyboard Navigation

```tsx
describe('Keyboard Navigation', () => {
  it('navigates list with arrow keys', async () => {
    const user = userEvent.setup();
    render(<TransactionList items={mockTransactions} />);

    const list = screen.getByRole('list');
    const items = screen.getAllByRole('listitem');

    await user.tab(); // focus first item
    expect(items[0]).toHaveFocus();

    await user.keyboard('{ArrowDown}');
    expect(items[1]).toHaveFocus();
  });

  it('opens detail on Enter', async () => {
    const user = userEvent.setup();
    const onSelect = vi.fn();
    render(<TransactionList items={mockTransactions} onSelect={onSelect} />);

    await user.tab();
    await user.keyboard('{Enter}');
    expect(onSelect).toHaveBeenCalledWith('1');
  });
});
```

## Focus Management

```tsx
describe('Modal Focus Management', () => {
  it('traps focus inside modal when open', async () => {
    const user = userEvent.setup();
    render(<TransactionDetailModal isOpen={true} onClose={vi.fn()} />);

    // First focusable element inside modal gets focus
    expect(screen.getByRole('dialog')).toBeInTheDocument();
    const closeButton = screen.getByRole('button', { name: /close/i });
    expect(closeButton).toHaveFocus();
  });

  it('returns focus to trigger on close', async () => {
    const user = userEvent.setup();
    const { rerender } = render(<TransactionDetailModal isOpen={true} />);
    const trigger = screen.getByRole('button', { name: /view details/i });

    rerender(<TransactionDetailModal isOpen={false} />);
    expect(trigger).toHaveFocus();
  });
});
```

## Output Format

```markdown
## VERDICT: [PASS | FAIL]

## Accessibility Testing Summary

| Metric | Value |
|--------|-------|
| Components Scanned | N |
| axe Violations | N |
| Keyboard Tests | N passed / N total |
| WCAG Level | AA |

## Violations Report

[If any violations]
### [Violation ID]: [Description]
- **Severity:** critical/serious/moderate/minor
- **Location:** `ComponentName` — `selector`
- **WCAG Criterion:** [e.g., 1.3.1 Info and Relationships]
- **Fix:** [specific code change]

## Keyboard Navigation Results

| Flow | Status |
|------|--------|
| Tab through list items | ✅ PASS |
| Arrow key navigation | ✅ PASS |
| Enter to open detail | ✅ PASS |
| Escape to close modal | ✅ PASS |
| Focus trap in modal | ✅ PASS |

## Next Steps
[PASS: "WCAG 2.1 AA compliant." | FAIL: list violations with fixes.]
```
