# Frontend Standards

> **⚠️ MAINTENANCE:** This file is indexed in `dev-team/skills/shared-patterns/standards-coverage-table.md`.
> When adding/removing `## ` sections, follow FOUR-FILE UPDATE RULE in CLAUDE.md: (1) edit standards file, (2) update TOC, (3) update standards-coverage-table.md, (4) update agent file.

This file defines the specific standards for frontend development.

> **Reference**: Always consult `docs/PROJECT_RULES.md` for common project standards.

---

## Table of Contents

| # | Section | Description |
|---|---------|-------------|
| 1 | [Framework](#framework) | React 18+, Next.js (version policy) |
| 2 | [Libraries & Tools](#libraries--tools) | Core, state, forms, UI, styling, testing |
| 3 | [State Management Patterns](#state-management-patterns) | TanStack Query, Zustand |
| 4 | [Form Patterns](#form-patterns) | React Hook Form + Zod |
| 5 | [Styling Standards](#styling-standards) | TailwindCSS, CSS variables |
| 6 | [Typography Standards](#typography-standards) | Font selection and pairing |
| 7 | [Animation Standards](#animation-standards) | CSS transitions, Framer Motion |
| 8 | [Component Patterns](#component-patterns) | Compound components, error boundaries |
| 9 | [File Organization](#file-organization-mandatory) | File-level single responsibility |
| 10 | [Accessibility](#accessibility) | WCAG 2.1 AA compliance |
| 11 | [Performance](#performance) | Code splitting, image optimization |
| 12 | [Directory Structure](#directory-structure) | Next.js App Router layout |
| 13 | [Forbidden Patterns](#forbidden-patterns) | Anti-patterns to avoid |
| 14 | [Standards Compliance Categories](#standards-compliance-categories) | Categories for ring:planning-backend-refactor |
| 15 | [Form Field Abstraction Layer](#form-field-abstraction-layer) | **HARD GATE:** Field wrappers, dual-mode (sindarian-ui vs vanilla) |
| 16 | [Provider Composition Pattern](#provider-composition-pattern) | Nested providers order, feature providers |
| 17 | [Custom Hooks Patterns](#custom-hooks-patterns) | **HARD GATE:** usePagination, useCursorPagination, useCreateUpdateSheet, useStepper, useDebounce |
| 18 | [Core five Utilities Pattern](#fetcher-utilities-pattern) | getCore five, postCore five, patchCore five, deleteCore five |
| 19 | [Client-Side Error Handling](#client-side-error-handling) | **HARD GATE:** ErrorBoundary, API error helpers, toast integration |
| 20 | [Data Table Pattern](#data-table-pattern) | TanStack Table, server-side pagination, column definitions |

**Meta-sections (not checked by agents):**
- [Checklist](#checklist) - Self-verification before submitting code

---

## Framework

- React 18+
- Next.js (see version policy below)
- TypeScript strict mode (see `typescript.md`)

### Framework Version Policy

| Scenario | Rule |
|----------|------|
| **New project** | Use **latest stable version** (verify at nextjs.org before starting) |
| **Existing codebase** | **Maintain project's current version** (read package.json) |

**Before starting any project:**
1. For NEW projects: Check https://nextjs.org for latest stable version
2. For EXISTING projects: Read `package.json` to determine current version
3. NEVER hardcode a specific version in implementation - use project's version

---

## Libraries & Tools

### Core

| Library | Use Case |
|---------|----------|
| React 18+ | UI framework |
| Next.js (latest stable) | Full-stack framework (see version policy above) |
| TypeScript 5+ | Type safety |

### State Management

| Library | Use Case |
|---------|----------|
| TanStack Query | Server state (API data) |
| Zustand | Client state (UI state) |
| Context API | Simple shared state |
| Redux Toolkit | Complex global state |

### Forms

| Library | Use Case |
|---------|----------|
| React Hook Form | Form state management |
| Zod | Schema validation |
| @hookform/resolvers | RHF + Zod integration |

### UI Components

| Library | Use Case |
|---------|----------|
| Radix UI | Headless primitives |
| shadcn/ui | Pre-styled Radix components |
| Chakra UI | Full component library |
| Headless UI | Tailwind-native primitives |

### Styling

| Library | Use Case |
|---------|----------|
| TailwindCSS | Utility-first CSS |
| CSS Modules | Scoped CSS |
| Styled Components | CSS-in-JS |
| CSS Variables | Theming |

### Testing

| Library | Use Case |
|---------|----------|
| Vitest | Unit tests |
| Testing Library | Component tests |
| Playwright | E2E tests |
| MSW | API mocking |

---

## State Management Patterns

### Server State with TanStack Query

```typescript
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

// Query key factory
const userKeys = {
    all: ['users'] as const,
    lists: () => [...userKeys.all, 'list'] as const,
    list: (filters: UserFilters) => [...userKeys.lists(), filters] as const,
    details: () => [...userKeys.all, 'detail'] as const,
    detail: (id: string) => [...userKeys.details(), id] as const,
};

// Typed query hook
function useUser(userId: string) {
    return useQuery({
        queryKey: userKeys.detail(userId),
        queryFn: () => fetchUser(userId),
        staleTime: 5 * 60 * 1000, // 5 minutes
    });
}

// Mutation with cache update
function useCreateUser() {
    const queryClient = useQueryClient();

    return useMutation({
        mutationFn: createUser,
        onSuccess: (newUser) => {
            // Update cache
            queryClient.setQueryData(
                userKeys.detail(newUser.id),
                newUser
            );
            // Invalidate list
            queryClient.invalidateQueries({
                queryKey: userKeys.lists(),
            });
        },
    });
}
```

### Client State with Zustand

```typescript
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface UIState {
    theme: 'light' | 'dark';
    sidebarOpen: boolean;
    setTheme: (theme: 'light' | 'dark') => void;
    toggleSidebar: () => void;
}

const useUIStore = create<UIState>()(
    persist(
        (set) => ({
            theme: 'light',
            sidebarOpen: true,
            setTheme: (theme) => set({ theme }),
            toggleSidebar: () => set((state) => ({
                sidebarOpen: !state.sidebarOpen
            })),
        }),
        { name: 'ui-storage' }
    )
);

// Usage in component
function Header() {
    const { theme, setTheme } = useUIStore();
    return <ThemeToggle theme={theme} onChange={setTheme} />;
}
```

---

## Form Patterns

### React Hook Form + Zod

```typescript
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';

// Schema
const createUserSchema = z.object({
    name: z.string().min(1, 'Name is required').max(100),
    email: z.string().email('Invalid email'),
    role: z.enum(['admin', 'user', 'guest']),
    notifications: z.boolean().default(true),
});

type CreateUserInput = z.infer<typeof createUserSchema>;

// Component
function CreateUserForm() {
    const {
        register,
        handleSubmit,
        formState: { errors, isSubmitting },
    } = useForm<CreateUserInput>({
        resolver: zodResolver(createUserSchema),
        defaultValues: {
            notifications: true,
        },
    });

    const createUser = useCreateUser();

    const onSubmit = async (data: CreateUserInput) => {
        await createUser.mutateAsync(data);
    };

    return (
        <form onSubmit={handleSubmit(onSubmit)}>
            <Input
                {...register('name')}
                error={errors.name?.message}
            />
            <Input
                {...register('email')}
                error={errors.email?.message}
            />
            <Select {...register('role')}>
                <option value="user">User</option>
                <option value="admin">Admin</option>
            </Select>
            <Button type="submit" loading={isSubmitting}>
                Create User
            </Button>
        </form>
    );
}
```

---

## Styling Standards

### TailwindCSS Best Practices

```tsx
// Use semantic class groupings
<div className="
    flex items-center justify-between
    p-4 gap-4
    bg-white dark:bg-gray-900
    border border-gray-200 rounded-lg
    hover:shadow-md transition-shadow
">

// Extract repeated patterns to components
function Card({ children, className }: CardProps) {
    return (
        <div className={cn(
            'bg-white dark:bg-gray-900',
            'border border-gray-200 rounded-lg',
            'p-4 shadow-sm',
            className
        )}>
            {children}
        </div>
    );
}
```

### CSS Variables for Theming

> **Lerian Console DS (decisão 2026-04-22):** use o padrão de **duas camadas** — valor raw em canais HSL + wrapper Tailwind. NÃO use o padrão single-layer do shadcn (`--color-primary: 220 90% 56%`): ele impede `hsl(var(--x) / alpha)`, necessário para dark mode robusto e estados (hover/disabled). Os **nomes de token espelham o Figma** e os **valores autoritativos vivem no `ring-tokens`** (accent do Console = `#FEED02`); o exemplo abaixo é ilustrativo do padrão.

```css
/* Camada 1 — valor raw em canais HSL (sem hsl()), para permitir alpha dinâmico.
   Nomes alinhados ao Figma / ring-tokens. */
:root {
    --body-surface: 240 5% 96%;
    --container-surface: 0 0% 100%;
    --foreground: 222 47% 11%;
    --muted: 210 40% 96%;
    --border: 214 32% 91%;
    --accent: 55 99% 50%;          /* #FEED02 — valor real em ring-tokens */
    --radius: 0.5rem;
}

.dark {
    --body-surface: 222 47% 11%;
    --container-surface: 222 47% 14%;
    --foreground: 210 40% 98%;
    --muted: 217 33% 17%;
    --border: 217 33% 17%;
}

/* Camada 2 — wrappers Tailwind que consomem os canais (habilitam `/ alpha`) */
@theme inline {
    --color-body-surface: hsl(var(--body-surface));
    --color-container-surface: hsl(var(--container-surface));
    --color-foreground: hsl(var(--foreground));
    --color-muted: hsl(var(--muted));
    --color-border: hsl(var(--border));
    --color-accent: hsl(var(--accent));   /* permite hsl(var(--accent) / 0.12) */
}
```

### Mobile-First Responsive Design

```tsx
// Always start mobile, scale up
<div className="
    grid grid-cols-1
    sm:grid-cols-2
    lg:grid-cols-3
    xl:grid-cols-4
    gap-4
">

// Responsive text
<h1 className="text-2xl sm:text-3xl lg:text-4xl font-bold">

// Hide/show based on breakpoint
<div className="hidden md:block">Desktop only</div>
<div className="md:hidden">Mobile only</div>
```

> **Lerian Console DS (decisão 2026-04-22):** breakpoints Tailwind default permanecem. Formalize **3 viewports de referência** para design e testes visuais (Playwright): **375px** (mobile — iPhone SE/mini), **768px** (tablet — iPad portrait), **1280px** (desktop). Container com **cap de 1400px** (evita linhas longas demais em ultrawide). Toda tela nova deve ter snapshot baseline nesses 3 viewports.

---

## Typography Standards

### Font Selection (AVOID GENERIC)

```tsx
// FORBIDDEN - Generic AI fonts
font-family: 'Inter', sans-serif;      // Too common
font-family: 'Roboto', sans-serif;     // Too common
font-family: 'Arial', sans-serif;      // System font
font-family: system-ui, sans-serif;    // System stack

// RECOMMENDED - Distinctive fonts
font-family: 'Geist', sans-serif;      // Modern, tech
font-family: 'Satoshi', sans-serif;    // Contemporary
font-family: 'Cabinet Grotesk', sans-serif; // Bold, editorial
font-family: 'Clash Display', sans-serif;   // Display headings
font-family: 'General Sans', sans-serif;    // Clean, versatile
```

### Font Pairing

```css
/* Display + Body pairing */
--font-display: 'Clash Display', sans-serif;
--font-body: 'Satoshi', sans-serif;

/* Heading uses display */
h1, h2, h3 {
    font-family: var(--font-display);
}

/* Body uses readable font */
body, p, span {
    font-family: var(--font-body);
}
```

---

## Animation Standards

### CSS Transitions (Simple Effects)

```css
/* Standard transition */
.button {
    transition: all 150ms ease;
}

/* Specific properties for performance */
.card {
    transition: transform 200ms ease, box-shadow 200ms ease;
}

/* Hover states */
.card:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}
```

### Framer Motion (Complex Animations)

```tsx
import { motion, AnimatePresence } from 'framer-motion';

// Page transitions
function PageWrapper({ children }: { children: React.ReactNode }) {
    return (
        <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            transition={{ duration: 0.3 }}
        >
            {children}
        </motion.div>
    );
}

// Staggered list animation
function ItemList({ items }: { items: Item[] }) {
    return (
        <motion.ul>
            {items.map((item, i) => (
                <motion.li
                    key={item.id}
                    initial={{ opacity: 0, x: -20 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: i * 0.1 }}
                >
                    {item.name}
                </motion.li>
            ))}
        </motion.ul>
    );
}
```

### Animation Guidelines

1. **Focus on high-impact moments** - Page loads, modal opens, state changes
2. **One orchestrated animation > scattered micro-interactions**
3. **Keep durations short** - 150-300ms for UI, 300-500ms for page transitions
4. **Use easing** - `ease`, `ease-out` for exits, `ease-in-out` for continuous

---

## Component Patterns

### Compound Components

```tsx
// Flexible API for complex components
function Tabs({ children, defaultValue }: TabsProps) {
    const [value, setValue] = useState(defaultValue);
    return (
        <TabsContext.Provider value={{ value, setValue }}>
            <div className="tabs">{children}</div>
        </TabsContext.Provider>
    );
}

Tabs.List = function TabsList({ children }: { children: React.ReactNode }) {
    return <div className="tabs-list">{children}</div>;
};

Tabs.Trigger = function TabsTrigger({ value, children }: TabsTriggerProps) {
    const { value: selected, setValue } = useTabsContext();
    return (
        <button
            className={cn('tab', selected === value && 'active')}
            onClick={() => setValue(value)}
        >
            {children}
        </button>
    );
};

Tabs.Content = function TabsContent({ value, children }: TabsContentProps) {
    const { value: selected } = useTabsContext();
    if (value !== selected) return null;
    return <div className="tab-content">{children}</div>;
};

// Usage
<Tabs defaultValue="tab1">
    <Tabs.List>
        <Tabs.Trigger value="tab1">Tab 1</Tabs.Trigger>
        <Tabs.Trigger value="tab2">Tab 2</Tabs.Trigger>
    </Tabs.List>
    <Tabs.Content value="tab1">Content 1</Tabs.Content>
    <Tabs.Content value="tab2">Content 2</Tabs.Content>
</Tabs>
```

### Error Boundaries

```tsx
import { Component, ErrorInfo, ReactNode } from 'react';

interface Props {
    children: ReactNode;
    fallback: ReactNode;
}

interface State {
    hasError: boolean;
}

class ErrorBoundary extends Component<Props, State> {
    state: State = { hasError: false };

    static getDerivedStateFromError(): State {
        return { hasError: true };
    }

    componentDidCatch(error: Error, errorInfo: ErrorInfo) {
        console.error('Error:', error, errorInfo);
    }

    render() {
        if (this.state.hasError) {
            return this.props.fallback;
        }
        return this.props.children;
    }
}

// Usage
<ErrorBoundary fallback={<ErrorMessage />}>
    <UserProfile userId={userId} />
</ErrorBoundary>
```

#### Advanced Composition Patterns

For comprehensive guidance on composition patterns that prevent boolean prop
proliferation, compound component architecture, state lifting, and React 19
patterns — use skill `ring:applying-composition-patterns`.

Trigger indicators:
- Component accepts >3 boolean props
- Multiple conditional rendering branches based on boolean flags
- Component file exceeds 200 lines with >3 useState/useEffect hooks

---

## File Organization (MANDATORY)

**Single Responsibility per File:** Each component file MUST represent ONE UI concern.

### Rules

| Rule | Description |
|------|-------------|
| **One component per file** | A file exports ONE primary component |
| **Max 200 lines per component file** | If longer, extract sub-components or hooks |
| **Co-locate related files** | Component, hook, types, test in same feature folder |
| **Hooks in separate files** | Custom hooks that exceed 20 lines get their own file |
| **Separate data from presentation** | Container (data-fetching) and presentational components split |

### Examples

```tsx
// ❌ BAD - UserDashboard.tsx (400 lines, mixed concerns)
export function UserDashboard() {
    // 30 lines of state management
    const [users, setUsers] = useState<User[]>([]);
    const [filters, setFilters] = useState<UserFilters>({});
    const [sortConfig, setSortConfig] = useState<SortConfig>({});
    const [isExportModalOpen, setIsExportModalOpen] = useState(false);

    // 40 lines of data fetching
    useEffect(() => {
        fetchUsers(filters).then(setUsers);
    }, [filters]);

    // 50 lines of event handlers
    const handleSort = (column: string) => { ... };
    const handleFilter = (key: string, value: unknown) => { ... };
    const handleExport = (format: string) => { ... };
    const handleBulkAction = (action: string, ids: string[]) => { ... };

    // 280 lines of mixed JSX (filters + table + pagination + modal)
    return (
        <div>
            {/* 80 lines of filter panel */}
            {/* 100 lines of data table */}
            {/* 50 lines of pagination */}
            {/* 50 lines of export modal */}
        </div>
    );
}
```

```tsx
// ✅ GOOD - Split by concern

// UserDashboard.tsx (~50 lines) - Composition root
export function UserDashboard() {
    const { users, pagination, isLoading } = useUsers();
    const { filters, updateFilter, resetFilters } = useUserFilters();

    return (
        <div>
            <UserFilters filters={filters} onChange={updateFilter} onReset={resetFilters} />
            <UserTable users={users} isLoading={isLoading} />
            <Pagination {...pagination} />
        </div>
    );
}

// useUsers.ts (~60 lines) - Data fetching hook
export function useUsers(filters?: UserFilters) {
    return useQuery({
        queryKey: ['users', filters],
        queryFn: () => fetchUsers(filters),
    });
}

// useUserFilters.ts (~40 lines) - Filter state hook
export function useUserFilters() {
    const [filters, setFilters] = useState<UserFilters>({});

    const updateFilter = useCallback((key: string, value: unknown) => {
        setFilters((prev) => ({ ...prev, [key]: value }));
    }, []);

    const resetFilters = useCallback(() => setFilters({}), []);

    return { filters, updateFilter, resetFilters };
}

// UserFilters.tsx (~70 lines) - Filter panel component
interface UserFiltersProps {
    filters: UserFilters;
    onChange: (key: string, value: unknown) => void;
    onReset: () => void;
}

export function UserFilters({ filters, onChange, onReset }: UserFiltersProps) {
    return (
        <div className="flex gap-4">
            <InputField value={filters.name} onChange={(v) => onChange('name', v)} />
            <SelectField value={filters.role} onChange={(v) => onChange('role', v)} options={roleOptions} />
            <Button variant="ghost" onClick={onReset}>Reset</Button>
        </div>
    );
}

// UserTable.tsx (~80 lines) - Table component
interface UserTableProps {
    users: User[];
    isLoading: boolean;
}

export function UserTable({ users, isLoading }: UserTableProps) {
    if (isLoading) return <TableSkeleton />;

    return (
        <DataTable columns={userColumns} data={users} />
    );
}
```

### Signs a File Needs Splitting

| Sign | Action |
|------|--------|
| Component file exceeds 200 lines | Extract sub-components or hooks |
| More than 3 `useState`/`useEffect` in one file | Extract to custom hook |
| JSX return exceeds 100 lines | Extract child components |
| File mixes data fetching and presentation | Split container and presentational components |
| Multiple `useQuery`/`useMutation` in one file | Extract to dedicated hook files |
| Component accepts more than 5 props | Consider composition or compound component pattern |

---

## Accessibility

### Required Practices

```tsx
// Always use semantic HTML
<button>Click me</button>  // not <div onClick={}>

// Images need alt text
<img src={user.avatar} alt={`${user.name}'s avatar`} />

// Form inputs need labels
<label htmlFor="email">Email</label>
<input id="email" type="email" />

// Use ARIA when needed
<button aria-label="Close dialog" aria-expanded={isOpen}>
    <XIcon />
</button>

// Keyboard navigation
<div
    role="button"
    tabIndex={0}
    onKeyDown={(e) => e.key === 'Enter' && onClick()}
    onClick={onClick}
>
```

### Focus Management

```tsx
// Focus trap for modals
import { FocusTrap } from '@radix-ui/react-focus-scope';

<FocusTrap>
    <Dialog>...</Dialog>
</FocusTrap>

// Auto-focus on mount
const inputRef = useRef<HTMLInputElement>(null);
useEffect(() => {
    inputRef.current?.focus();
}, []);
```

---

## Performance

### Code Splitting

```tsx
import { lazy, Suspense } from 'react';

// Lazy load heavy components
const Dashboard = lazy(() => import('./pages/Dashboard'));
const Analytics = lazy(() => import('./pages/Analytics'));

// Use Suspense
<Suspense fallback={<LoadingSpinner />}>
    <Dashboard />
</Suspense>
```

### Image Optimization

```tsx
import Image from 'next/image';

// Always use next/image
<Image
    src={user.avatar}
    alt={user.name}
    width={48}
    height={48}
    priority={isAboveFold}
/>
```

### Memoization

```tsx
// Memo expensive components
const ExpensiveList = memo(function ExpensiveList({ items }: Props) {
    return items.map(item => <ExpensiveItem key={item.id} {...item} />);
});

// useMemo for expensive calculations
const sortedItems = useMemo(
    () => items.sort((a, b) => b.score - a.score),
    [items]
);

// useCallback for stable references
const handleClick = useCallback((id: string) => {
    setSelectedId(id);
}, []);
```

---

## Directory Structure

```text
/src
  /app                 # Next.js App Router
    /api               # API routes
    /(auth)            # Auth route group
    /(dashboard)       # Dashboard route group
    layout.tsx
    page.tsx
  /components
    /ui                # Primitive UI components
      button.tsx
      input.tsx
      card.tsx
    /features          # Feature-specific components
      /user
        UserProfile.tsx
        UserList.tsx
      /order
        OrderForm.tsx
  /hooks               # Custom hooks
    useUser.ts
    useDebounce.ts
  /lib                 # Utilities
    api.ts
    utils.ts
    cn.ts
  /stores              # Zustand stores
    userStore.ts
    uiStore.ts
  /types               # TypeScript types
    user.ts
    api.ts
/public                # Static assets
```

---

## Forbidden Patterns

**The following patterns are never allowed. Agents MUST refuse to implement these:**

### TypeScript Anti-Patterns

| Pattern | Why Forbidden | Correct Alternative |
|---------|---------------|---------------------|
| `any` type | Defeats TypeScript purpose | Use proper types, `unknown`, or generics |
| Type assertions without validation | Runtime errors | Use type guards or Zod parsing |
| `// @ts-ignore` or `// @ts-expect-error` | Hides real errors | Fix the type issue properly |
| Non-strict mode | Allows unsafe code | Enable `"strict": true` in tsconfig |

### Accessibility Anti-Patterns

| Pattern | Why Forbidden | Correct Alternative |
|---------|---------------|---------------------|
| `<div onClick={}>` for buttons | Not keyboard accessible | Use `<button>` element |
| `<span onClick={}>` for links | Not keyboard accessible | Use `<a href="">` element |
| Missing `alt` on images | Screen readers can't describe | Always provide descriptive alt text |
| Missing form labels | Inputs not associated | Use `<label htmlFor="">` |
| `tabIndex > 0` | Breaks natural tab order | Use `tabIndex={0}` or semantic HTML |
| `outline: none` without alternative | Removes focus visibility | Provide custom focus styles |

### State Management Anti-Patterns

| Pattern | Why Forbidden | Correct Alternative |
|---------|---------------|---------------------|
| `useEffect` for data fetching | Race conditions, no caching | Use TanStack Query |
| Props drilling > 3 levels | Unmaintainable | Use Context or Zustand |
| Storing server state in Redux/Zustand | Stale data, duplicate cache | Use TanStack Query for server state |
| `useState` for form state | No validation, verbose | Use React Hook Form |

### Security Anti-Patterns

| Pattern | Why Forbidden | Correct Alternative |
|---------|---------------|---------------------|
| `dangerouslySetInnerHTML` without sanitization | XSS vulnerability | Use DOMPurify or avoid entirely |
| Storing tokens in localStorage | XSS can steal tokens | Use httpOnly cookies |
| Hardcoded API keys in frontend | Exposed in bundle | Use environment variables, BFF |
| Unvalidated URL redirects | Open redirect vulnerability | Whitelist allowed domains |

### Font Anti-Patterns

| Pattern | Why Forbidden | Correct Alternative |
|---------|---------------|---------------------|
| `font-family: 'Inter'` | Generic AI aesthetic | Use Geist, Satoshi, Cabinet Grotesk |
| `font-family: 'Roboto'` | Generic, overused | Use General Sans, Clash Display |
| `font-family: 'Arial'` | System font, no character | Use distinctive web fonts |
| `font-family: system-ui` | No brand identity | Define specific font stack |

### Performance Anti-Patterns

| Pattern | Why Forbidden | Correct Alternative |
|---------|---------------|---------------------|
| `<img>` without next/image | No optimization | Use `next/image` component |
| Inline styles in loops | Creates new objects each render | Use className or CSS Modules |
| Missing `key` prop in lists | React can't optimize | Always provide stable keys |
| `useMemo`/`useCallback` everywhere | Premature optimization | Only when actually needed |

**If existing code uses FORBIDDEN patterns → Report as blocker, DO NOT extend.**

---

## Standards Compliance Categories

**When invoked from ring:planning-backend-refactor, check all categories:**

| Category | Ring Standard | What to Verify |
|----------|--------------|----------------|
| **TypeScript** | Strict mode, no `any` | tsconfig.json, *.tsx files |
| **Accessibility** | WCAG 2.1 AA | Semantic HTML, ARIA, keyboard nav |
| **State Management** | TanStack Query + Zustand | No useEffect for fetching |
| **Forms** | React Hook Form + Zod | Validation schemas present |
| **Styling** | Tailwind, CSS variables | No inline styles in logic |
| **Fonts** | Distinctive fonts | No Inter, Roboto, Arial |
| **Performance** | next/image, code splitting | Lazy loading, memoization |
| **Security** | No XSS vectors | dangerouslySetInnerHTML usage |

---

## Form Field Abstraction Layer

### Dual-Mode UI Library Support

⛔ **HARD GATE:** All forms MUST use field abstraction wrappers. Direct input usage is FORBIDDEN.

| Mode | Detection | Components |
|------|-----------|------------|
| **sindarian-ui** (primary) | `@lerianstudio/sindarian-ui` in package.json | FormField, FormItem, FormLabel, FormControl, FormMessage, FormTooltip |
| **shadcn/radix** (fallback) | Components not available in sindarian-ui | Place in project `components/ui/` using shadcn/ui + Radix primitives |

### Field Wrapper Components (MANDATORY)

| Component | Purpose | Required Props |
|-----------|---------|----------------|
| `InputField` | Text, number, email, password inputs | name, label, description?, placeholder?, tooltip? |
| `SelectField` | Single select dropdown | name, label, options, placeholder? |
| `ComboBoxField` | Searchable select with filtering | name, label, options, onSearch?, placeholder? |
| `MultiSelectField` | Multiple selection | name, label, options, maxItems? |
| `TextAreaField` | Multi-line text input | name, label, rows?, maxLength? |
| `CheckboxField` | Boolean checkbox | name, label, description? |
| `SwitchField` | Toggle switch | name, label, description? |
| `DatePickerField` | Date selection | name, label, minDate?, maxDate? |

### sindarian-ui Mode Implementation

```tsx
import {
    FormField,
    FormItem,
    FormLabel,
    FormControl,
    FormDescription,
    FormMessage,
    FormTooltip,
    Input,
} from '@lerianstudio/sindarian-ui';
import { useFormContext } from 'react-hook-form';

interface InputFieldProps {
    name: string;
    label: string;
    description?: string;
    placeholder?: string;
    tooltip?: string;
    type?: 'text' | 'email' | 'password' | 'number';
}

export function InputField({
    name,
    label,
    description,
    placeholder,
    tooltip,
    type = 'text',
}: InputFieldProps) {
    const { control } = useFormContext();

    return (
        <FormField
            control={control}
            name={name}
            render={({ field }) => (
                <FormItem>
                    <FormLabel>
                        {label}
                        {tooltip && <FormTooltip>{tooltip}</FormTooltip>}
                    </FormLabel>
                    <FormControl>
                        <Input
                            type={type}
                            placeholder={placeholder}
                            {...field}
                        />
                    </FormControl>
                    {description && <FormDescription>{description}</FormDescription>}
                    <FormMessage />
                </FormItem>
            )}
        />
    );
}
```

### Vanilla Mode Implementation (shadcn/ui)

```tsx
import {
    FormField,
    FormItem,
    FormLabel,
    FormControl,
    FormMessage,
    FormDescription,
} from '@/components/ui/form';
import { Input } from '@/components/ui/input';
import { useFormContext } from 'react-hook-form';
import {
    Tooltip,
    TooltipContent,
    TooltipTrigger,
} from '@/components/ui/tooltip';
import { HelpCircle } from 'lucide-react';

interface InputFieldProps {
    name: string;
    label: string;
    description?: string;
    placeholder?: string;
    tooltip?: string;
    type?: 'text' | 'email' | 'password' | 'number';
}

export function InputField({
    name,
    label,
    description,
    placeholder,
    tooltip,
    type = 'text',
}: InputFieldProps) {
    const { control } = useFormContext();

    return (
        <FormField
            control={control}
            name={name}
            render={({ field }) => (
                <FormItem>
                    <FormLabel className="flex items-center gap-1">
                        {label}
                        {tooltip && (
                            <Tooltip>
                                <TooltipTrigger asChild>
                                    <HelpCircle className="h-4 w-4 text-muted-foreground" />
                                </TooltipTrigger>
                                <TooltipContent>{tooltip}</TooltipContent>
                            </Tooltip>
                        )}
                    </FormLabel>
                    <FormControl>
                        <Input
                            type={type}
                            placeholder={placeholder}
                            {...field}
                        />
                    </FormControl>
                    {description && <FormDescription>{description}</FormDescription>}
                    <FormMessage />
                </FormItem>
            )}
        />
    );
}
```

### Form Usage Pattern

```tsx
import { useForm, FormProvider } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { InputField, SelectField } from '@/components/fields';

const schema = z.object({
    name: z.string().min(1, 'Name is required'),
    email: z.string().email('Invalid email'),
    role: z.enum(['admin', 'user', 'guest']),
});

type FormData = z.infer<typeof schema>;

function CreateUserForm() {
    const form = useForm<FormData>({
        resolver: zodResolver(schema),
        defaultValues: {
            name: '',
            email: '',
            role: 'user',
        },
    });

    const onSubmit = (data: FormData) => {
        // Submit logic
    };

    return (
        <FormProvider {...form}>
            <form onSubmit={form.handleSubmit(onSubmit)}>
                <InputField
                    name="name"
                    label="Name"
                    placeholder="Enter your name"
                    tooltip="Your full legal name"
                />
                <InputField
                    name="email"
                    label="Email"
                    type="email"
                    placeholder="you@example.com"
                />
                <SelectField
                    name="role"
                    label="Role"
                    options={[
                        { value: 'admin', label: 'Administrator' },
                        { value: 'user', label: 'User' },
                        { value: 'guest', label: 'Guest' },
                    ]}
                />
                <Button type="submit">Create User</Button>
            </form>
        </FormProvider>
    );
}
```

### Anti-Patterns (FORBIDDEN)

| Pattern | Why Forbidden | Correct Alternative |
|---------|---------------|---------------------|
| `<Input {...register('name')} />` directly | No label, no error display, no accessibility | Use `<InputField name="name" label="Name" />` |
| Inline error handling | Inconsistent UX | Use FormMessage from wrapper |
| Manual FormField for each input | Code duplication | Use pre-built field wrappers |
| Different field patterns per form | Inconsistent UX | Use shared field components |

---

## Provider Composition Pattern

### Provider Order (MANDATORY)

Providers MUST be composed in a specific order to ensure proper context availability.

```tsx
// src/app/providers.tsx
'use client';

import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { SessionProvider } from 'next-auth/react';
// Lerian Console DS (decisão 2026-04-22): provider de tema CUSTOM, NÃO next-themes.
// Justificativa: accent color por tenant (cada org tem sua cor primária) — next-themes
// não suporta isso nativamente. Mecanismo é o mesmo (class-based `.dark`); só o wrapper muda.
import { ThemeProvider } from '@/components/theme-provider';
import { Toaster } from '@/components/ui/toaster';
import { TooltipProvider } from '@/components/ui/tooltip';
import { useState } from 'react';

interface ProvidersProps {
    children: React.ReactNode;
}

export function Providers({ children }: ProvidersProps) {
    const [queryClient] = useState(
        () =>
            new QueryClient({
                defaultOptions: {
                    queries: {
                        staleTime: 60 * 1000, // 1 minute
                        refetchOnWindowFocus: false,
                    },
                },
            })
    );

    return (
        <SessionProvider>
            <QueryClientProvider client={queryClient}>
                <ThemeProvider
                    attribute="class"
                    defaultTheme="light"
                    tenantAccent={org?.accent}
                >
                    <TooltipProvider>
                        {children}
                        <Toaster />
                    </TooltipProvider>
                </ThemeProvider>
            </QueryClientProvider>
        </SessionProvider>
    );
}
```

### Provider Order Rules

| Order | Provider | Reason |
|-------|----------|--------|
| 1 | SessionProvider | Auth must be outermost for all components to access session |
| 2 | QueryClientProvider | Data fetching needs session for authenticated requests |
| 3 | ThemeProvider | Theme should wrap UI components |
| 4 | TooltipProvider | Radix tooltips need provider context |
| 5 | App-specific providers | Feature-specific contexts |

### Layout Integration

```tsx
// src/app/layout.tsx
import { Providers } from './providers';

export default function RootLayout({
    children,
}: {
    children: React.ReactNode;
}) {
    return (
        <html lang="en" suppressHydrationWarning>
            <body>
                <Providers>{children}</Providers>
            </body>
        </html>
    );
}
```

### Feature-Specific Providers

For feature-specific state, create scoped providers:

```tsx
// src/features/organization/providers/OrganizationProvider.tsx
'use client';

import { createContext, useContext, useState } from 'react';

interface OrganizationContextValue {
    organizationId: string | null;
    setOrganizationId: (id: string | null) => void;
}

const OrganizationContext = createContext<OrganizationContextValue | null>(null);

export function OrganizationProvider({ children }: { children: React.ReactNode }) {
    const [organizationId, setOrganizationId] = useState<string | null>(null);

    return (
        <OrganizationContext.Provider value={{ organizationId, setOrganizationId }}>
            {children}
        </OrganizationContext.Provider>
    );
}

export function useOrganization() {
    const context = useContext(OrganizationContext);
    if (!context) {
        throw new Error('useOrganization must be used within OrganizationProvider');
    }
    return context;
}
```

---

## Custom Hooks Patterns

### Pagination Hooks (MANDATORY for lists)

#### usePagination (Offset-based)

```tsx
import { useState, useCallback, useMemo } from 'react';

interface UsePaginationOptions {
    initialPage?: number;
    initialPageSize?: number;
    pageSizeOptions?: number[];
}

interface UsePaginationReturn {
    page: number;
    pageSize: number;
    offset: number;
    setPage: (page: number) => void;
    setPageSize: (size: number) => void;
    nextPage: () => void;
    prevPage: () => void;
    canNextPage: (totalItems: number) => boolean;
    canPrevPage: boolean;
    pageSizeOptions: number[];
    totalPages: (totalItems: number) => number;
}

export function usePagination({
    initialPage = 1,
    initialPageSize = 10,
    pageSizeOptions = [10, 20, 50, 100],
}: UsePaginationOptions = {}): UsePaginationReturn {
    const [page, setPage] = useState(initialPage);
    const [pageSize, setPageSize] = useState(initialPageSize);

    const offset = useMemo(() => (page - 1) * pageSize, [page, pageSize]);

    const nextPage = useCallback(() => setPage((p) => p + 1), []);
    const prevPage = useCallback(() => setPage((p) => Math.max(1, p - 1)), []);

    const canNextPage = useCallback(
        (totalItems: number) => page * pageSize < totalItems,
        [page, pageSize]
    );
    const canPrevPage = page > 1;

    const totalPages = useCallback(
        (totalItems: number) => Math.ceil(totalItems / pageSize),
        [pageSize]
    );

    const handleSetPageSize = useCallback((size: number) => {
        setPageSize(size);
        setPage(1); // Reset to first page on size change
    }, []);

    return {
        page,
        pageSize,
        offset,
        setPage,
        setPageSize: handleSetPageSize,
        nextPage,
        prevPage,
        canNextPage,
        canPrevPage,
        pageSizeOptions,
        totalPages,
    };
}
```

#### useCursorPagination (Cursor-based)

```tsx
import { useState, useCallback } from 'react';

interface CursorPaginationState {
    cursor: string | null;
    direction: 'next' | 'prev';
}

interface UseCursorPaginationOptions {
    initialPageSize?: number;
}

interface UseCursorPaginationReturn {
    cursor: string | null;
    pageSize: number;
    setPageSize: (size: number) => void;
    goToNext: (nextCursor: string) => void;
    goToPrev: (prevCursor: string) => void;
    reset: () => void;
    hasNext: boolean;
    hasPrev: boolean;
    setHasNext: (value: boolean) => void;
    setHasPrev: (value: boolean) => void;
}

export function useCursorPagination({
    initialPageSize = 10,
}: UseCursorPaginationOptions = {}): UseCursorPaginationReturn {
    const [state, setState] = useState<CursorPaginationState>({
        cursor: null,
        direction: 'next',
    });
    const [pageSize, setPageSize] = useState(initialPageSize);
    const [hasNext, setHasNext] = useState(false);
    const [hasPrev, setHasPrev] = useState(false);

    const goToNext = useCallback((nextCursor: string) => {
        setState({ cursor: nextCursor, direction: 'next' });
    }, []);

    const goToPrev = useCallback((prevCursor: string) => {
        setState({ cursor: prevCursor, direction: 'prev' });
    }, []);

    const reset = useCallback(() => {
        setState({ cursor: null, direction: 'next' });
    }, []);

    return {
        cursor: state.cursor,
        pageSize,
        setPageSize,
        goToNext,
        goToPrev,
        reset,
        hasNext,
        hasPrev,
        setHasNext,
        setHasPrev,
    };
}
```

### CRUD Sheet Hook Pattern

```tsx
import { useState, useCallback } from 'react';

type SheetMode = 'create' | 'edit' | 'view' | 'closed';

interface UseSheetOptions<T> {
    onSuccess?: (data: T) => void;
}

interface UseSheetReturn<T> {
    isOpen: boolean;
    mode: SheetMode;
    data: T | null;
    openCreate: () => void;
    openEdit: (item: T) => void;
    openView: (item: T) => void;
    close: () => void;
    isCreateMode: boolean;
    isEditMode: boolean;
    isViewMode: boolean;
}

export function useCreateUpdateSheet<T>({
    onSuccess,
}: UseSheetOptions<T> = {}): UseSheetReturn<T> {
    const [mode, setMode] = useState<SheetMode>('closed');
    const [data, setData] = useState<T | null>(null);

    const openCreate = useCallback(() => {
        setData(null);
        setMode('create');
    }, []);

    const openEdit = useCallback((item: T) => {
        setData(item);
        setMode('edit');
    }, []);

    const openView = useCallback((item: T) => {
        setData(item);
        setMode('view');
    }, []);

    const close = useCallback(() => {
        setMode('closed');
        setData(null);
    }, []);

    return {
        isOpen: mode !== 'closed',
        mode,
        data,
        openCreate,
        openEdit,
        openView,
        close,
        isCreateMode: mode === 'create',
        isEditMode: mode === 'edit',
        isViewMode: mode === 'view',
    };
}
```

### Utility Hooks

#### useDebounce

```tsx
import { useState, useEffect } from 'react';

export function useDebounce<T>(value: T, delay: number = 300): T {
    const [debouncedValue, setDebouncedValue] = useState<T>(value);

    useEffect(() => {
        const timer = setTimeout(() => setDebouncedValue(value), delay);
        return () => clearTimeout(timer);
    }, [value, delay]);

    return debouncedValue;
}
```

#### useStepper

```tsx
import { useState, useCallback } from 'react';

interface UseStepperOptions {
    initialStep?: number;
    totalSteps: number;
}

interface UseStepperReturn {
    currentStep: number;
    totalSteps: number;
    isFirstStep: boolean;
    isLastStep: boolean;
    nextStep: () => void;
    prevStep: () => void;
    goToStep: (step: number) => void;
    reset: () => void;
    progress: number;
}

export function useStepper({
    initialStep = 0,
    totalSteps,
}: UseStepperOptions): UseStepperReturn {
    const [currentStep, setCurrentStep] = useState(initialStep);

    const nextStep = useCallback(() => {
        setCurrentStep((s) => Math.min(s + 1, totalSteps - 1));
    }, [totalSteps]);

    const prevStep = useCallback(() => {
        setCurrentStep((s) => Math.max(s - 1, 0));
    }, []);

    const goToStep = useCallback(
        (step: number) => {
            if (step >= 0 && step < totalSteps) {
                setCurrentStep(step);
            }
        },
        [totalSteps]
    );

    const reset = useCallback(() => setCurrentStep(initialStep), [initialStep]);

    return {
        currentStep,
        totalSteps,
        isFirstStep: currentStep === 0,
        isLastStep: currentStep === totalSteps - 1,
        nextStep,
        prevStep,
        goToStep,
        reset,
        progress: ((currentStep + 1) / totalSteps) * 100,
    };
}
```

---

## Core five Utilities Pattern

### Base Core five Functions

```tsx
// src/lib/fetcher/index.ts

export interface Core fiveOptions extends RequestInit {
    params?: Record<string, string | number | boolean | undefined>;
}

function buildUrl(url: string, params?: Core fiveOptions['params']): string {
    if (!params) return url;

    const searchParams = new URLSearchParams();
    Object.entries(params).forEach(([key, value]) => {
        if (value !== undefined) {
            searchParams.append(key, String(value));
        }
    });

    const queryString = searchParams.toString();
    return queryString ? `${url}?${queryString}` : url;
}

async function handleResponse<T>(response: Response): Promise<T> {
    if (!response.ok) {
        const error = await response.json().catch(() => ({}));
        throw new ApiError(
            error.message || 'Request failed',
            response.status,
            error.code
        );
    }
    return response.json();
}

export async function getCore five<T>(
    url: string,
    options: Core fiveOptions = {}
): Promise<T> {
    const { params, ...fetchOptions } = options;
    const response = await fetch(buildUrl(url, params), {
        method: 'GET',
        headers: {
            'Content-Type': 'application/json',
            ...fetchOptions.headers,
        },
        ...fetchOptions,
    });
    return handleResponse<T>(response);
}

export async function postCore five<T, D = unknown>(
    url: string,
    data: D,
    options: Core fiveOptions = {}
): Promise<T> {
    const { params, ...fetchOptions } = options;
    const response = await fetch(buildUrl(url, params), {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            ...fetchOptions.headers,
        },
        body: JSON.stringify(data),
        ...fetchOptions,
    });
    return handleResponse<T>(response);
}

export async function patchCore five<T, D = unknown>(
    url: string,
    data: D,
    options: Core fiveOptions = {}
): Promise<T> {
    const { params, ...fetchOptions } = options;
    const response = await fetch(buildUrl(url, params), {
        method: 'PATCH',
        headers: {
            'Content-Type': 'application/json',
            ...fetchOptions.headers,
        },
        body: JSON.stringify(data),
        ...fetchOptions,
    });
    return handleResponse<T>(response);
}

export async function deleteCore five<T = void>(
    url: string,
    options: Core fiveOptions = {}
): Promise<T> {
    const { params, ...fetchOptions } = options;
    const response = await fetch(buildUrl(url, params), {
        method: 'DELETE',
        headers: {
            'Content-Type': 'application/json',
            ...fetchOptions.headers,
        },
        ...fetchOptions,
    });
    return handleResponse<T>(response);
}
```

### ApiError Class

```tsx
// src/lib/fetcher/api-error.ts

export class ApiError extends Error {
    constructor(
        message: string,
        public status: number,
        public code?: string
    ) {
        super(message);
        this.name = 'ApiError';
    }

    get isNotFound() {
        return this.status === 404;
    }

    get isUnauthorized() {
        return this.status === 401;
    }

    get isForbidden() {
        return this.status === 403;
    }

    get isValidationError() {
        return this.status === 400 || this.status === 422;
    }

    get isServerError() {
        return this.status >= 500;
    }
}
```

### Integration with TanStack Query

```tsx
// src/hooks/use-users.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getCore five, postCore five, patchCore five, deleteCore five } from '@/lib/fetcher';
import type { User, CreateUserInput, UpdateUserInput } from '@/types/user';

const userKeys = {
    all: ['users'] as const,
    lists: () => [...userKeys.all, 'list'] as const,
    list: (filters: Record<string, unknown>) => [...userKeys.lists(), filters] as const,
    details: () => [...userKeys.all, 'detail'] as const,
    detail: (id: string) => [...userKeys.details(), id] as const,
};

export function useUsers(filters: { page?: number; pageSize?: number } = {}) {
    return useQuery({
        queryKey: userKeys.list(filters),
        queryFn: () =>
            getCore five<{ data: User[]; total: number }>('/api/users', {
                params: filters,
            }),
    });
}

export function useUser(id: string) {
    return useQuery({
        queryKey: userKeys.detail(id),
        queryFn: () => getCore five<User>(`/api/users/${id}`),
        enabled: !!id,
    });
}

export function useCreateUser() {
    const queryClient = useQueryClient();

    return useMutation({
        mutationFn: (data: CreateUserInput) =>
            postCore five<User, CreateUserInput>('/api/users', data),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: userKeys.lists() });
        },
    });
}

export function useUpdateUser(id: string) {
    const queryClient = useQueryClient();

    return useMutation({
        mutationFn: (data: UpdateUserInput) =>
            patchCore five<User, UpdateUserInput>(`/api/users/${id}`, data),
        onSuccess: (updatedUser) => {
            queryClient.setQueryData(userKeys.detail(id), updatedUser);
            queryClient.invalidateQueries({ queryKey: userKeys.lists() });
        },
    });
}

export function useDeleteUser() {
    const queryClient = useQueryClient();

    return useMutation({
        mutationFn: (id: string) => deleteCore five(`/api/users/${id}`),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: userKeys.lists() });
        },
    });
}
```

---

## Client-Side Error Handling

### ErrorBoundary Component

```tsx
// src/components/error-boundary.tsx
'use client';

import { Component, ErrorInfo, ReactNode } from 'react';
import { Button } from '@/components/ui/button';
import { AlertTriangle } from 'lucide-react';

interface ErrorBoundaryProps {
    children: ReactNode;
    fallback?: ReactNode;
    onReset?: () => void;
}

interface ErrorBoundaryState {
    hasError: boolean;
    error: Error | null;
}

export class ErrorBoundary extends Component<ErrorBoundaryProps, ErrorBoundaryState> {
    constructor(props: ErrorBoundaryProps) {
        super(props);
        this.state = { hasError: false, error: null };
    }

    static getDerivedStateFromError(error: Error): ErrorBoundaryState {
        return { hasError: true, error };
    }

    componentDidCatch(error: Error, errorInfo: ErrorInfo) {
        console.error('ErrorBoundary caught an error:', error, errorInfo);
        // Report to error tracking service (e.g., Sentry)
    }

    handleReset = () => {
        this.setState({ hasError: false, error: null });
        this.props.onReset?.();
    };

    render() {
        if (this.state.hasError) {
            if (this.props.fallback) {
                return this.props.fallback;
            }

            return (
                <div className="flex flex-col items-center justify-center p-8 text-center">
                    <AlertTriangle className="h-12 w-12 text-destructive mb-4" />
                    <h2 className="text-lg font-semibold mb-2">Something went wrong</h2>
                    <p className="text-muted-foreground mb-4">
                        {this.state.error?.message || 'An unexpected error occurred'}
                    </p>
                    <Button onClick={this.handleReset} variant="outline">
                        Try again
                    </Button>
                </div>
            );
        }

        return this.props.children;
    }
}
```

### API Error Helpers

```tsx
// src/lib/error-helpers.ts
import { toast } from '@/components/ui/use-toast';
import { ApiError } from '@/lib/fetcher/api-error';

export function handleApiError(error: unknown): void {
    if (error instanceof ApiError) {
        if (error.isUnauthorized) {
            toast({
                variant: 'destructive',
                title: 'Session Expired',
                description: 'Please log in again.',
            });
            // Redirect to login
            window.location.href = '/login';
            return;
        }

        if (error.isForbidden) {
            toast({
                variant: 'destructive',
                title: 'Access Denied',
                description: 'You do not have permission to perform this action.',
            });
            return;
        }

        if (error.isValidationError) {
            toast({
                variant: 'destructive',
                title: 'Validation Error',
                description: error.message,
            });
            return;
        }

        if (error.isServerError) {
            toast({
                variant: 'destructive',
                title: 'Server Error',
                description: 'Something went wrong. Please try again later.',
            });
            return;
        }

        toast({
            variant: 'destructive',
            title: 'Error',
            description: error.message,
        });
        return;
    }

    // Unknown error
    toast({
        variant: 'destructive',
        title: 'Error',
        description: 'An unexpected error occurred.',
    });
}
```

### Error Recovery Patterns

```tsx
// Using with TanStack Query mutations
import { useToast } from '@/components/ui/use-toast';
import { handleApiError } from '@/lib/error-helpers';

function CreateUserForm() {
    const { toast } = useToast();
    const createUser = useCreateUser();

    const onSubmit = async (data: CreateUserInput) => {
        try {
            await createUser.mutateAsync(data);
            toast({
                title: 'Success',
                description: 'User created successfully.',
            });
        } catch (error) {
            handleApiError(error);
        }
    };

    return (
        <form onSubmit={handleSubmit(onSubmit)}>
            {/* form fields */}
            {createUser.isError && (
                <Alert variant="destructive">
                    <AlertDescription>
                        Failed to create user. Please try again.
                    </AlertDescription>
                </Alert>
            )}
        </form>
    );
}
```

### Query Error Handling

```tsx
// Global error handler for React Query
import { QueryClient } from '@tanstack/react-query';
import { handleApiError } from '@/lib/error-helpers';

export const queryClient = new QueryClient({
    defaultOptions: {
        queries: {
            retry: (failureCount, error) => {
                // Don't retry on 4xx errors
                if (error instanceof ApiError && error.status < 500) {
                    return false;
                }
                return failureCount < 3;
            },
        },
        mutations: {
            onError: (error) => {
                handleApiError(error);
            },
        },
    },
});
```

---

## Data Table Pattern

### TanStack Table with Pagination

```tsx
// src/components/data-table.tsx
'use client';

import {
    ColumnDef,
    flexRender,
    getCoreRowModel,
    useReactTable,
    getPaginationRowModel,
    SortingState,
    getSortedRowModel,
} from '@tanstack/react-table';
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from '@/components/ui/table';
import { Button } from '@/components/ui/button';
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from '@/components/ui/select';
import { useState } from 'react';

interface DataTableProps<TData, TValue> {
    columns: ColumnDef<TData, TValue>[];
    data: TData[];
    pageCount?: number;
    pagination?: {
        page: number;
        pageSize: number;
        onPageChange: (page: number) => void;
        onPageSizeChange: (size: number) => void;
    };
    isLoading?: boolean;
}

export function DataTable<TData, TValue>({
    columns,
    data,
    pageCount,
    pagination,
    isLoading,
}: DataTableProps<TData, TValue>) {
    const [sorting, setSorting] = useState<SortingState>([]);

    const table = useReactTable({
        data,
        columns,
        getCoreRowModel: getCoreRowModel(),
        getSortedRowModel: getSortedRowModel(),
        getPaginationRowModel: getPaginationRowModel(),
        onSortingChange: setSorting,
        state: {
            sorting,
        },
        manualPagination: !!pagination,
        pageCount: pageCount,
    });

    return (
        <div className="space-y-4">
            <div className="rounded-md border">
                <Table>
                    <TableHeader>
                        {table.getHeaderGroups().map((headerGroup) => (
                            <TableRow key={headerGroup.id}>
                                {headerGroup.headers.map((header) => (
                                    <TableHead key={header.id}>
                                        {header.isPlaceholder
                                            ? null
                                            : flexRender(
                                                  header.column.columnDef.header,
                                                  header.getContext()
                                              )}
                                    </TableHead>
                                ))}
                            </TableRow>
                        ))}
                    </TableHeader>
                    <TableBody>
                        {isLoading ? (
                            <TableRow>
                                <TableCell
                                    colSpan={columns.length}
                                    className="h-24 text-center"
                                >
                                    Loading...
                                </TableCell>
                            </TableRow>
                        ) : table.getRowModel().rows?.length ? (
                            table.getRowModel().rows.map((row) => (
                                <TableRow
                                    key={row.id}
                                    data-state={row.getIsSelected() && 'selected'}
                                >
                                    {row.getVisibleCells().map((cell) => (
                                        <TableCell key={cell.id}>
                                            {flexRender(
                                                cell.column.columnDef.cell,
                                                cell.getContext()
                                            )}
                                        </TableCell>
                                    ))}
                                </TableRow>
                            ))
                        ) : (
                            <TableRow>
                                <TableCell
                                    colSpan={columns.length}
                                    className="h-24 text-center"
                                >
                                    No results.
                                </TableCell>
                            </TableRow>
                        )}
                    </TableBody>
                </Table>
            </div>

            {pagination && (
                <div className="flex items-center justify-between px-2">
                    <div className="flex items-center space-x-2">
                        <p className="text-sm text-muted-foreground">Rows per page</p>
                        <Select
                            value={String(pagination.pageSize)}
                            onValueChange={(value) =>
                                pagination.onPageSizeChange(Number(value))
                            }
                        >
                            <SelectTrigger className="h-8 w-[70px]">
                                <SelectValue />
                            </SelectTrigger>
                            <SelectContent>
                                {[10, 20, 50, 100].map((size) => (
                                    <SelectItem key={size} value={String(size)}>
                                        {size}
                                    </SelectItem>
                                ))}
                            </SelectContent>
                        </Select>
                    </div>

                    <div className="flex items-center space-x-2">
                        <Button
                            variant="outline"
                            size="sm"
                            onClick={() => pagination.onPageChange(pagination.page - 1)}
                            disabled={pagination.page <= 1}
                        >
                            Previous
                        </Button>
                        <span className="text-sm text-muted-foreground">
                            Page {pagination.page} of {pageCount || 1}
                        </span>
                        <Button
                            variant="outline"
                            size="sm"
                            onClick={() => pagination.onPageChange(pagination.page + 1)}
                            disabled={pagination.page >= (pageCount || 1)}
                        >
                            Next
                        </Button>
                    </div>
                </div>
            )}
        </div>
    );
}
```

### Usage with Server-Side Pagination

```tsx
// src/app/users/page.tsx
'use client';

import { DataTable } from '@/components/data-table';
import { useUsers } from '@/hooks/use-users';
import { usePagination } from '@/hooks/use-pagination';
import { columns } from './columns';

export default function UsersPage() {
    const pagination = usePagination({ initialPageSize: 20 });
    const { data, isLoading } = useUsers({
        page: pagination.page,
        pageSize: pagination.pageSize,
    });

    return (
        <DataTable
            columns={columns}
            data={data?.data || []}
            pageCount={pagination.totalPages(data?.total || 0)}
            pagination={{
                page: pagination.page,
                pageSize: pagination.pageSize,
                onPageChange: pagination.setPage,
                onPageSizeChange: pagination.setPageSize,
            }}
            isLoading={isLoading}
        />
    );
}
```

### Column Definitions Pattern

```tsx
// src/app/users/columns.tsx
import { ColumnDef } from '@tanstack/react-table';
import { User } from '@/types/user';
import { Button } from '@/components/ui/button';
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { MoreHorizontal, Pencil, Trash } from 'lucide-react';

export const columns: ColumnDef<User>[] = [
    {
        accessorKey: 'name',
        header: 'Name',
    },
    {
        accessorKey: 'email',
        header: 'Email',
    },
    {
        accessorKey: 'role',
        header: 'Role',
        cell: ({ row }) => (
            <span className="capitalize">{row.getValue('role')}</span>
        ),
    },
    {
        accessorKey: 'createdAt',
        header: 'Created',
        cell: ({ row }) => (
            new Date(row.getValue('createdAt')).toLocaleDateString()
        ),
    },
    {
        id: 'actions',
        cell: ({ row }) => {
            const user = row.original;

            return (
                <DropdownMenu>
                    <DropdownMenuTrigger asChild>
                        <Button variant="ghost" className="h-8 w-8 p-0">
                            <MoreHorizontal className="h-4 w-4" />
                        </Button>
                    </DropdownMenuTrigger>
                    <DropdownMenuContent align="end">
                        <DropdownMenuItem onClick={() => handleEdit(user)}>
                            <Pencil className="mr-2 h-4 w-4" />
                            Edit
                        </DropdownMenuItem>
                        <DropdownMenuItem
                            onClick={() => handleDelete(user.id)}
                            className="text-destructive"
                        >
                            <Trash className="mr-2 h-4 w-4" />
                            Delete
                        </DropdownMenuItem>
                    </DropdownMenuContent>
                </DropdownMenu>
            );
        },
    },
];
```

---

## Checklist

Before submitting frontend code, verify:

- [ ] TypeScript strict mode (no `any`)
- [ ] Components use semantic HTML
- [ ] Forms validated with Zod
- [ ] TanStack Query for server state
- [ ] Zustand for client state (if needed)
- [ ] Mobile-first responsive design
- [ ] Keyboard accessible (tabIndex, onKeyDown)
- [ ] ARIA labels where needed
- [ ] Images use next/image with alt text
- [ ] No generic fonts (Inter, Roboto, Arial)
- [ ] Animations are purposeful, not decorative
- [ ] No FORBIDDEN patterns present
