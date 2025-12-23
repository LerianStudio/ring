# Frontend Standards

> **⚠️ MAINTENANCE:** This file is indexed in `dev-team/skills/shared-patterns/standards-coverage-table.md`.
> When adding/removing `## ` sections, update the coverage table AND agent files per THREE-FILE UPDATE RULE in CLAUDE.md.

This file defines the specific standards for frontend development.

> **Reference**: Always consult `docs/PROJECT_RULES.md` for common project standards.

---

## Table of Contents

| # | Section | Description |
|---|---------|-------------|
| 1 | [Framework](#framework) | React 18+, Next.js 14+ |
| 2 | [Libraries & Tools](#libraries--tools) | Core, state, forms, UI, styling, testing |
| 3 | [State Management Patterns](#state-management-patterns) | TanStack Query, Zustand |
| 4 | [Form Patterns](#form-patterns) | React Hook Form + Zod |
| 5 | [Styling Standards](#styling-standards) | TailwindCSS, CSS variables |
| 6 | [Typography Standards](#typography-standards) | Font selection and pairing |
| 7 | [Animation Standards](#animation-standards) | CSS transitions, Framer Motion |
| 8 | [Component Patterns](#component-patterns) | Compound components, error boundaries |
| 9 | [Accessibility](#accessibility) | WCAG 2.1 AA compliance |
| 10 | [Performance](#performance) | Code splitting, image optimization |
| 11 | [Directory Structure](#directory-structure) | Next.js App Router layout |
| 12 | [Forbidden Patterns](#forbidden-patterns) | Anti-patterns to avoid |
| 13 | [Standards Compliance Categories](#standards-compliance-categories) | Categories for dev-refactor |

**Meta-sections (not checked by agents):**
- [Checklist](#checklist) - Self-verification before submitting code

---

## Framework

- React 18+ / Next.js 14+
- TypeScript strict mode (see `typescript.md`)

---

## Libraries & Tools

### Core

| Library | Use Case |
|---------|----------|
| React 18+ | UI framework |
| Next.js 14+ | Full-stack framework |
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

```css
:root {
    --color-primary: 220 90% 56%;
    --color-secondary: 262 83% 58%;
    --color-background: 0 0% 100%;
    --color-foreground: 222 47% 11%;
    --color-muted: 210 40% 96%;
    --color-border: 214 32% 91%;
    --radius: 0.5rem;
}

.dark {
    --color-background: 222 47% 11%;
    --color-foreground: 210 40% 98%;
    --color-muted: 217 33% 17%;
    --color-border: 217 33% 17%;
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

---

## Accessibility

### Required Practices

```tsx
// Always use semantic HTML
<button>Click me</button>  // NOT <div onClick={}>

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

**The following patterns are NEVER allowed. Agents MUST refuse to implement these:**

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

**If existing code uses FORBIDDEN patterns → Report as blocker, do NOT extend.**

---

## Standards Compliance Categories

**When invoked from dev-refactor, check ALL categories:**

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
