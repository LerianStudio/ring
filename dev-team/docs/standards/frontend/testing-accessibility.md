# Frontend Standards - Accessibility Testing

> **Module:** testing-accessibility.md | **Sections:** 5 | **Parent:** [frontend.md](../frontend.md)

This module covers automated accessibility testing patterns for React/Next.js applications. WCAG 2.1 AA compliance is verified through axe-core, keyboard navigation testing, and focus management validation.

> **Gate Reference:** This module is loaded by `ring:qa-frontend` at Gate 2 (Accessibility Testing).

---

## Table of Contents

| # | [Section Name](#anchor-link) | Description |
|---|------------------------------|-------------|
| 1 | [axe-core Integration](#axe-core-integration-mandatory) | Automated WCAG scanning setup |
| 2 | [Semantic HTML Verification](#semantic-html-verification-mandatory) | HTML element correctness |
| 3 | [Keyboard Navigation](#keyboard-navigation-mandatory) | Tab order and key handling |
| 4 | [Focus Management](#focus-management-mandatory) | Focus trap, auto-focus, restoration |
| 5 | [Color Contrast](#color-contrast-mandatory) | Contrast ratio verification |

**Meta-sections:** [Output Format (Gate 2 - Accessibility Testing)](#output-format-gate-2---accessibility-testing), [Anti-Rationalization Table](#anti-rationalization-table-accessibility-testing)

---

## axe-core Integration (MANDATORY)

**HARD GATE:** All components MUST pass axe-core automated scans with zero WCAG 2.1 AA violations.

### Required Tools

| Tool | Purpose | Install |
|------|---------|---------|
| `@axe-core/playwright` | E2E accessibility scanning | `npm i -D @axe-core/playwright` |
| `jest-axe` | Unit-level accessibility testing | `npm i -D jest-axe` |
| `axe-core` | Core engine (peer dependency) | `npm i -D axe-core` |

### Unit Test Pattern (jest-axe + Vitest)

```tsx
import { render } from '@testing-library/react';
import { axe, toHaveNoViolations } from 'jest-axe';

expect.extend(toHaveNoViolations);

describe('LoginForm accessibility', () => {
    it('MUST have no WCAG AA violations', async () => {
        const { container } = render(<LoginForm />);
        const results = await axe(container);
        expect(results).toHaveNoViolations();
    });

    it('MUST have no violations in error state', async () => {
        const { container } = render(<LoginForm error="Invalid credentials" />);
        const results = await axe(container);
        expect(results).toHaveNoViolations();
    });
});
```

### E2E Pattern (@axe-core/playwright)

```typescript
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test('login page MUST be accessible', async ({ page }) => {
    await page.goto('/login');

    const accessibilityScanResults = await new AxeBuilder({ page })
        .withTags(['wcag2a', 'wcag2aa'])
        .analyze();

    expect(accessibilityScanResults.violations).toEqual([]);
});
```

### States to Test

| State | Why | Example |
|-------|-----|---------|
| Default | Baseline compliance | Component in normal state |
| Loading | Spinners need ARIA | `aria-busy="true"`, live region |
| Error | Error messages need association | `aria-describedby`, `role="alert"` |
| Empty | Empty states need content | Descriptive empty message |
| Disabled | Disabled controls need indication | `aria-disabled`, visual cue |

### FORBIDDEN Patterns

```tsx
// FORBIDDEN: Suppressing violations
const results = await axe(container, {
    rules: { 'color-contrast': { enabled: false } }  // NEVER suppress
});

// FORBIDDEN: Testing only happy path
// MUST test error, loading, empty, disabled states too
```

---

## Semantic HTML Verification (MANDATORY)

**HARD GATE:** All interactive elements MUST use correct semantic HTML elements. See [frontend.md Section 12 - Accessibility Anti-Patterns](../frontend.md#forbidden-patterns).

### Required Checks

| Element | Correct | FORBIDDEN | Test Pattern |
|---------|---------|-----------|--------------|
| Buttons | `<button>` | `<div onClick>`, `<span onClick>` | `getByRole('button')` |
| Links | `<a href="">` | `<span onClick>` with navigation | `getByRole('link')` |
| Headings | `<h1>`-`<h6>` in order | Skipping levels (h1 → h3) | `getByRole('heading', { level })` |
| Lists | `<ul>/<ol>/<li>` | `<div>` with visual bullets | `getByRole('list')` |
| Forms | `<form>` with `<label>` | `<div>` with inputs | `getByRole('form')` |
| Images | `<img alt="">` | `<img>` without alt | `getByRole('img', { name })` |
| Navigation | `<nav>` | `<div class="nav">` | `getByRole('navigation')` |

### Test Pattern

```tsx
import { render, screen } from '@testing-library/react';

describe('UserCard semantic HTML', () => {
    it('MUST use button for actions', () => {
        render(<UserCard user={mockUser} />);
        // Verify semantic elements
        expect(screen.getByRole('button', { name: /edit/i })).toBeInTheDocument();
        expect(screen.getByRole('img', { name: mockUser.name })).toBeInTheDocument();
        expect(screen.getByRole('heading')).toHaveTextContent(mockUser.name);
    });
});
```

### ARIA Attribute Validation

| Attribute | When Required | Test |
|-----------|---------------|------|
| `aria-label` | Icon-only buttons | `getByRole('button', { name: 'Close' })` |
| `aria-expanded` | Expandable sections | `expect(button).toHaveAttribute('aria-expanded', 'true')` |
| `aria-describedby` | Error messages | Input references error element |
| `aria-live` | Dynamic content | Toast, notifications |
| `role="alert"` | Error/success messages | `getByRole('alert')` |
| `aria-busy` | Loading states | `expect(region).toHaveAttribute('aria-busy', 'true')` |

---

## Keyboard Navigation (MANDATORY)

**HARD GATE:** All interactive elements MUST be keyboard accessible.

### Required Key Handlers

| Key | Expected Behavior | Where |
|-----|-------------------|-------|
| `Tab` | Move to next focusable element | All interactive elements |
| `Shift+Tab` | Move to previous focusable element | All interactive elements |
| `Enter` | Activate button/link | Buttons, links |
| `Space` | Toggle checkbox, activate button | Checkboxes, buttons |
| `Escape` | Close modal/dropdown | Modals, dropdowns, tooltips |
| `Arrow Up/Down` | Navigate list items | Dropdowns, menus, combobox |
| `Home/End` | Jump to first/last item | Lists, menus |

### Test Pattern

```tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

describe('Dropdown keyboard navigation', () => {
    it('MUST open with Enter and navigate with arrows', async () => {
        const user = userEvent.setup();
        render(<Dropdown options={['Option 1', 'Option 2', 'Option 3']} />);

        const trigger = screen.getByRole('combobox');
        await user.tab(); // Focus trigger
        expect(trigger).toHaveFocus();

        await user.keyboard('{Enter}'); // Open dropdown
        expect(screen.getByRole('listbox')).toBeVisible();

        await user.keyboard('{ArrowDown}'); // Navigate
        expect(screen.getByRole('option', { name: 'Option 1' })).toHaveFocus();

        await user.keyboard('{ArrowDown}');
        expect(screen.getByRole('option', { name: 'Option 2' })).toHaveFocus();

        await user.keyboard('{Escape}'); // Close
        expect(screen.queryByRole('listbox')).not.toBeInTheDocument();
        expect(trigger).toHaveFocus(); // Focus returns
    });
});
```

### Tab Order Verification

```tsx
describe('Form tab order', () => {
    it('MUST follow logical order', async () => {
        const user = userEvent.setup();
        render(<LoginForm />);

        await user.tab();
        expect(screen.getByLabelText('Email')).toHaveFocus();

        await user.tab();
        expect(screen.getByLabelText('Password')).toHaveFocus();

        await user.tab();
        expect(screen.getByRole('button', { name: /sign in/i })).toHaveFocus();
    });
});
```

### FORBIDDEN Patterns

```tsx
// FORBIDDEN: tabIndex > 0
<div tabIndex={2}>  // Breaks natural tab order

// FORBIDDEN: Removing outline without alternative
button:focus { outline: none; }  // Focus not visible

// FORBIDDEN: Click-only handlers
<div onClick={handler}>  // Not keyboard accessible
// CORRECT: Use button or add keyboard handler
<button onClick={handler}>
```

---

## Focus Management (MANDATORY)

**HARD GATE:** Focus MUST be managed correctly for modals, drawers, and dynamic content.

### Focus Trap (Modals and Drawers)

```tsx
describe('Modal focus trap', () => {
    it('MUST trap focus within modal', async () => {
        const user = userEvent.setup();
        render(<Modal isOpen={true} onClose={vi.fn()} />);

        const modal = screen.getByRole('dialog');
        const focusableElements = modal.querySelectorAll(
            'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
        );
        const firstFocusable = focusableElements[0] as HTMLElement;
        const lastFocusable = focusableElements[focusableElements.length - 1] as HTMLElement;

        // First element should be focused
        expect(firstFocusable).toHaveFocus();

        // Tab past last element wraps to first
        lastFocusable.focus();
        await user.tab();
        expect(firstFocusable).toHaveFocus();
    });
});
```

### Focus Restoration

```tsx
describe('Modal focus restoration', () => {
    it('MUST restore focus to trigger on close', async () => {
        const user = userEvent.setup();
        render(<ModalTrigger />);

        const openButton = screen.getByRole('button', { name: 'Open modal' });
        await user.click(openButton);

        // Close modal
        await user.keyboard('{Escape}');

        // Focus returns to trigger
        expect(openButton).toHaveFocus();
    });
});
```

### Auto-Focus on Mount

```tsx
describe('SearchDialog auto-focus', () => {
    it('MUST auto-focus search input on open', () => {
        render(<SearchDialog isOpen={true} />);
        expect(screen.getByRole('searchbox')).toHaveFocus();
    });
});
```

---

## Color Contrast (MANDATORY)

**HARD GATE:** All text MUST meet WCAG 2.1 AA contrast ratios.

### Required Ratios

| Content Type | Minimum Ratio | Example |
|-------------|---------------|---------|
| Normal text (< 18px) | 4.5:1 | Body text, labels |
| Large text (≥ 18px or 14px bold) | 3:1 | Headings, large buttons |
| UI components | 3:1 | Borders, icons, focus rings |
| Decorative | N/A | Background patterns |

### Verification with axe-core

axe-core automatically checks contrast ratios. Additional manual verification:

```tsx
describe('Theme contrast', () => {
    it('MUST pass contrast check in light mode', async () => {
        const { container } = render(
            <ThemeProvider mode="light">
                <Dashboard />
            </ThemeProvider>
        );
        const results = await axe(container);
        const contrastViolations = results.violations.filter(
            v => v.id === 'color-contrast'
        );
        expect(contrastViolations).toHaveLength(0);
    });

    it('MUST pass contrast check in dark mode', async () => {
        const { container } = render(
            <ThemeProvider mode="dark">
                <Dashboard />
            </ThemeProvider>
        );
        const results = await axe(container);
        const contrastViolations = results.violations.filter(
            v => v.id === 'color-contrast'
        );
        expect(contrastViolations).toHaveLength(0);
    });
});
```

### FORBIDDEN Patterns

| Pattern | Why Forbidden | Correct Alternative |
|---------|---------------|---------------------|
| Light gray text on white (#999 on #fff) | Fails 4.5:1 ratio | Use #595959 or darker |
| Placeholder-only labels | Low contrast, not persistent | Use visible labels |
| Color-only indicators | Color blind users can't see | Use color + icon/text |

---

## Output Format (Gate 2 - Accessibility Testing)

```markdown
## Accessibility Testing Summary

| Metric | Value |
|--------|-------|
| Components tested | X |
| axe-core violations | 0 |
| Keyboard navigation tests | Y |
| Focus management tests | Z |
| States tested | Default, Loading, Error, Empty, Disabled |

### axe-core Scan Results

| Component | States Scanned | Violations | Status |
|-----------|---------------|------------|--------|
| LoginForm | Default, Error | 0 | PASS |
| UserCard | Default, Loading | 0 | PASS |
| Dashboard | Default, Empty | 0 | PASS |

### Keyboard Navigation Results

| Component | Tab Order | Key Handlers | Status |
|-----------|-----------|-------------|--------|
| LoginForm | 3 stops, logical | Enter submits | PASS |
| Dropdown | Arrow navigation | Escape closes | PASS |

### Standards Compliance

| Standard | Status | Evidence |
|----------|--------|----------|
| axe-core 0 violations | PASS | All scans clean |
| Keyboard navigation | PASS | All handlers tested |
| Focus management | PASS | Trap + restoration |
| Color contrast | PASS | 4.5:1 verified |
| Semantic HTML | PASS | All roles correct |
```

---

## Anti-Rationalization Table (Accessibility Testing)

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "axe-core finds too many false positives" | axe-core has < 5% false positive rate for WCAG AA. | **Fix all violations** |
| "We'll add accessibility later" | Retrofitting accessibility costs 10x more. | **Test now** |
| "Only screen reader users need this" | Keyboard navigation benefits all power users. | **Test keyboard nav** |
| "The component library handles it" | Library components can be misused. | **Verify with axe-core** |
| "It's an internal tool, accessibility isn't needed" | Legal compliance applies to all apps. WCAG is mandatory. | **Test all components** |
| "Focus management is too complex" | Radix UI handles focus traps. Use the tools. | **Implement focus management** |

---
