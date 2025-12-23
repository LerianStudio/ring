# TypeScript Standards

> **⚠️ MAINTENANCE:** This file is indexed in `dev-team/skills/shared-patterns/standards-coverage-table.md`.
> When adding/removing `## ` sections, update the coverage table AND agent files per THREE-FILE UPDATE RULE in CLAUDE.md.

This file defines the specific standards for TypeScript (backend) development.

> **Reference**: Always consult `docs/PROJECT_RULES.md` for common project standards.

---

## Table of Contents

| # | Section | Description |
|---|---------|-------------|
| 1 | [Version](#version) | TypeScript and Node.js versions |
| 2 | [Strict Configuration](#strict-configuration-mandatory) | tsconfig.json requirements |
| 3 | [Frameworks & Libraries](#frameworks--libraries) | Required packages |
| 4 | [Type Safety](#type-safety) | Never use any, branded types |
| 5 | [Zod Validation Patterns](#zod-validation-patterns) | Schema validation |
| 6 | [Dependency Injection](#dependency-injection) | TSyringe patterns |
| 7 | [AsyncLocalStorage for Context](#asynclocalstorage-for-context) | Request context propagation |
| 8 | [Testing](#testing) | Type-safe mocks, fixtures |
| 9 | [Error Handling](#error-handling) | Custom error classes |
| 10 | [Function Design](#function-design-mandatory) | Single responsibility principle |
| 11 | [Naming Conventions](#naming-conventions) | Files, interfaces, types |
| 12 | [Directory Structure](#directory-structure) | Project layout (Lerian pattern) |
| 13 | [RabbitMQ Worker Pattern](#rabbitmq-worker-pattern) | Async message processing |

**Meta-sections (not checked by agents):**
- [Checklist](#checklist) - Self-verification before submitting code

---

## Version

- TypeScript 5.0+
- Node.js 20+ / Deno 1.40+ / Bun 1.0+

---

## Strict Configuration (MANDATORY)

```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "noPropertyAccessFromIndexSignature": true,
    "exactOptionalPropertyTypes": true,
    "noFallthroughCasesInSwitch": true,
    "noImplicitReturns": true,
    "forceConsistentCasingInFileNames": true,
    "skipLibCheck": false
  }
}
```

---

## Frameworks & Libraries

### Backend Frameworks

| Framework | Use Case |
|-----------|----------|
| Express | Traditional, widely adopted |
| Fastify | High performance |
| NestJS | Enterprise, Angular-style DI |
| Hono | Ultrafast, edge-ready |
| tRPC | End-to-end type safety |

### ORMs & Query Builders

| Library | Use Case |
|---------|----------|
| Prisma | Type-safe ORM, migrations |
| Drizzle | Lightweight, SQL-like |
| TypeORM | Decorator-based ORM |
| Kysely | Type-safe query builder |

### Validation

| Library | Use Case |
|---------|----------|
| Zod | Schema validation + types |
| Yup | Object schema validation |
| joi | Classic validation |
| class-validator | Decorator-based |

### Testing

| Library | Use Case |
|---------|----------|
| Vitest | Fast, Vite-native |
| Jest | Full-featured |
| Supertest | HTTP testing |
| testcontainers | Integration tests |

---

## Type Safety

### NEVER use `any`

```typescript
// FORBIDDEN
const data: any = fetchData();
function process(x: any) { ... }

// CORRECT - use unknown with type narrowing
const data: unknown = fetchData();
if (isUser(data)) {
    console.log(data.name); // Now TypeScript knows it's User
}

// Type guard
function isUser(value: unknown): value is User {
    return (
        typeof value === 'object' &&
        value !== null &&
        'id' in value &&
        'name' in value
    );
}
```

### Branded Types for IDs

```typescript
// Define branded type to prevent ID mixing
type Brand<T, B> = T & { __brand: B };

type UserId = Brand<string, 'UserId'>;
type TenantId = Brand<string, 'TenantId'>;
type OrderId = Brand<string, 'OrderId'>;

// Factory functions with validation
function createUserId(value: string): UserId {
    if (!value.startsWith('usr_')) {
        throw new Error('Invalid user ID format');
    }
    return value as UserId;
}

// Now TypeScript prevents mixing IDs
function getUser(id: UserId): User { ... }
function getOrder(id: OrderId): Order { ... }

const userId = createUserId('usr_123');
const orderId = createOrderId('ord_456');

getUser(userId);   // OK
getUser(orderId);  // TypeScript ERROR - type mismatch
```

### Discriminated Unions for State

```typescript
// CORRECT - use discriminated unions
type RequestState<T> =
    | { status: 'idle' }
    | { status: 'loading' }
    | { status: 'success'; data: T }
    | { status: 'error'; error: Error };

function handleState(state: RequestState<User>) {
    switch (state.status) {
        case 'idle':
            return null;
        case 'loading':
            return <Spinner />;
        case 'success':
            return <UserCard user={state.data} />; // TypeScript knows data exists
        case 'error':
            return <ErrorMessage error={state.error} />; // TypeScript knows error exists
    }
}
```

### Result Type for Error Handling

```typescript
// Define Result type
type Result<T, E = Error> =
    | { success: true; data: T }
    | { success: false; error: E };

// Usage
async function createUser(input: CreateUserInput): Promise<Result<User, ValidationError>> {
    const validation = userSchema.safeParse(input);
    if (!validation.success) {
        return { success: false, error: new ValidationError(validation.error) };
    }

    const user = await db.user.create({ data: validation.data });
    return { success: true, data: user };
}

// Pattern matching approach
const result = await createUser(input);
if (result.success) {
    console.log(result.data.id); // TypeScript knows data exists
} else {
    console.error(result.error.message); // TypeScript knows error exists
}
```

---

## Zod Validation Patterns

### Schema Definition

```typescript
import { z } from 'zod';

// Reusable primitives
const emailSchema = z.string().email();
const uuidSchema = z.string().uuid();
const moneySchema = z.number().positive().multipleOf(0.01);

// Compose schemas
const createUserSchema = z.object({
    email: emailSchema,
    name: z.string().min(1).max(100),
    role: z.enum(['admin', 'user', 'guest']),
    preferences: z.object({
        theme: z.enum(['light', 'dark']).default('light'),
        notifications: z.boolean().default(true),
    }).optional(),
});

// Infer TypeScript type from schema
type CreateUserInput = z.infer<typeof createUserSchema>;

// Runtime validation
function createUser(input: unknown): CreateUserInput {
    return createUserSchema.parse(input); // Throws on invalid
}

// Safe parsing (returns Result-like)
function validateUser(input: unknown) {
    const result = createUserSchema.safeParse(input);
    if (!result.success) {
        return { error: result.error.flatten() };
    }
    return { data: result.data };
}
```

### Schema Composition

```typescript
// Base schemas
const timestampSchema = z.object({
    createdAt: z.date(),
    updatedAt: z.date(),
});

const identifiableSchema = z.object({
    id: uuidSchema,
});

// Compose for full entity
const userSchema = identifiableSchema
    .merge(timestampSchema)
    .extend({
        email: emailSchema,
        name: z.string(),
    });
```

---

## Dependency Injection

### Using TSyringe

```typescript
import { container, injectable, inject } from 'tsyringe';

// Define interface
interface UserRepository {
    findById(id: string): Promise<User | null>;
    save(user: User): Promise<void>;
}

// Implement
@injectable()
class PostgresUserRepository implements UserRepository {
    constructor(
        @inject('Database') private db: Database
    ) {}

    async findById(id: string): Promise<User | null> {
        return this.db.user.findUnique({ where: { id } });
    }

    async save(user: User): Promise<void> {
        await this.db.user.upsert({ where: { id: user.id }, ...user });
    }
}

// Service using repository
@injectable()
class UserService {
    constructor(
        @inject('UserRepository') private repo: UserRepository
    ) {}

    async getUser(id: string): Promise<User> {
        const user = await this.repo.findById(id);
        if (!user) throw new NotFoundError('User not found');
        return user;
    }
}

// Register in container
container.register('Database', { useClass: PrismaDatabase });
container.register('UserRepository', { useClass: PostgresUserRepository });

// Resolve
const userService = container.resolve(UserService);
```

---

## AsyncLocalStorage for Context

```typescript
import { AsyncLocalStorage } from 'async_hooks';

// Define context type
interface RequestContext {
    requestId: string;
    userId?: string;
    tenantId?: string;
}

// Create storage
const asyncLocalStorage = new AsyncLocalStorage<RequestContext>();

// Get current context
export function getContext(): RequestContext {
    const ctx = asyncLocalStorage.getStore();
    if (!ctx) throw new Error('No context available');
    return ctx;
}

// Middleware to set context
export function contextMiddleware(req: Request, res: Response, next: NextFunction) {
    const context: RequestContext = {
        requestId: req.headers['x-request-id'] as string || crypto.randomUUID(),
        userId: req.user?.id,
        tenantId: req.headers['x-tenant-id'] as string,
    };

    asyncLocalStorage.run(context, () => next());
}

// Usage anywhere in call chain
async function processOrder(orderId: string) {
    const { tenantId, userId } = getContext();
    logger.info('Processing order', { orderId, tenantId, userId });
    // ...
}
```

---

## Testing

### Type-Safe Mocks

```typescript
import { vi, describe, it, expect } from 'vitest';

// Create typed mock
const mockUserRepository: jest.Mocked<UserRepository> = {
    findById: vi.fn(),
    save: vi.fn(),
};

describe('UserService', () => {
    it('returns user when found', async () => {
        // Arrange
        const user: User = { id: 'usr_123', name: 'John', email: 'john@example.com' };
        mockUserRepository.findById.mockResolvedValue(user);

        const service = new UserService(mockUserRepository);

        // Act
        const result = await service.getUser('usr_123');

        // Assert
        expect(result).toEqual(user);
        expect(mockUserRepository.findById).toHaveBeenCalledWith('usr_123');
    });

    it('throws NotFoundError when user not found', async () => {
        // Arrange
        mockUserRepository.findById.mockResolvedValue(null);

        const service = new UserService(mockUserRepository);

        // Act & Assert
        await expect(service.getUser('usr_999')).rejects.toThrow(NotFoundError);
    });
});
```

### Type-Safe Fixtures

```typescript
// fixtures/user.ts
import { faker } from '@faker-js/faker';

export function createUserFixture(overrides: Partial<User> = {}): User {
    return {
        id: `usr_${faker.string.uuid()}`,
        name: faker.person.fullName(),
        email: faker.internet.email(),
        createdAt: faker.date.past(),
        updatedAt: new Date(),
        ...overrides,
    };
}

// Usage in tests
const user = createUserFixture({ name: 'Test User' });
```

### Edge Case Coverage (MANDATORY)

**Every acceptance criterion MUST have edge case tests beyond the happy path.**

| AC Type | Required Edge Cases | Minimum Count |
|---------|---------------------|---------------|
| Input validation | null, undefined, empty string, boundary values, invalid format, special chars | 3+ |
| CRUD operations | not found, duplicate, concurrent access, large payload | 3+ |
| Business logic | zero, negative, overflow, boundary conditions, invalid state | 3+ |
| Error handling | timeout, connection refused, invalid response, retry exhausted | 2+ |
| Authentication | expired token, invalid token, missing token, revoked token | 2+ |

**Edge Case Test Pattern:**

```typescript
describe('UserService', () => {
    describe('createUser', () => {
        // Happy path
        it('creates user with valid input', async () => {
            const result = await service.createUser(validInput);
            expect(result.id).toBeDefined();
        });

        // Edge cases (MANDATORY - minimum 3)
        it('throws ValidationError for null input', async () => {
            await expect(service.createUser(null as any)).rejects.toThrow(ValidationError);
        });

        it('throws ValidationError for empty email', async () => {
            await expect(service.createUser({ ...validInput, email: '' })).rejects.toThrow(ValidationError);
        });

        it('throws ValidationError for invalid email format', async () => {
            await expect(service.createUser({ ...validInput, email: 'invalid' })).rejects.toThrow(ValidationError);
        });

        it('throws ValidationError for email exceeding max length', async () => {
            const longEmail = 'a'.repeat(256) + '@test.com';
            await expect(service.createUser({ ...validInput, email: longEmail })).rejects.toThrow(ValidationError);
        });

        it('throws DuplicateError for existing email', async () => {
            mockRepo.findByEmail.mockResolvedValue(existingUser);
            await expect(service.createUser(validInput)).rejects.toThrow(DuplicateError);
        });
    });
});
```

**Anti-Pattern (FORBIDDEN):**

```typescript
// ❌ WRONG: Only happy path
describe('UserService', () => {
    it('creates user', async () => {
        const result = await service.createUser(validInput);
        expect(result).toBeDefined();  // No edge cases = incomplete test
    });
});
```

---

## Error Handling

### Custom Error Classes

```typescript
// Base application error
export class AppError extends Error {
    constructor(
        message: string,
        public readonly code: string,
        public readonly statusCode: number = 500,
        public readonly details?: Record<string, unknown>
    ) {
        super(message);
        this.name = this.constructor.name;
    }

    toJSON() {
        return {
            error: {
                code: this.code,
                message: this.message,
                details: this.details,
            },
        };
    }
}

// Specific errors
export class NotFoundError extends AppError {
    constructor(resource: string) {
        super(`${resource} not found`, 'NOT_FOUND', 404);
    }
}

export class ValidationError extends AppError {
    constructor(errors: z.ZodError) {
        super('Validation failed', 'VALIDATION_ERROR', 400, {
            fields: errors.flatten().fieldErrors,
        });
    }
}

export class UnauthorizedError extends AppError {
    constructor(message = 'Unauthorized') {
        super(message, 'UNAUTHORIZED', 401);
    }
}
```

---

## Function Design (MANDATORY)

**Single Responsibility Principle (SRP):** Each function MUST have exactly ONE responsibility.

### Rules

| Rule | Description |
|------|-------------|
| **One responsibility per function** | A function should do ONE thing and do it well |
| **Max 20-30 lines** | If longer, break into smaller functions |
| **One level of abstraction** | Don't mix high-level and low-level operations |
| **Descriptive names** | Function name should describe its single responsibility |

### Examples

```typescript
// ❌ BAD - Multiple responsibilities
async function processOrder(order: Order): Promise<void> {
    // Validate order
    if (!order.items?.length) {
        throw new Error('no items');
    }
    // Calculate total
    let total = 0;
    for (const item of order.items) {
        total += item.price * item.quantity;
    }
    // Apply discount
    if (order.couponCode) {
        total = total * 0.9;
    }
    // Save to database
    await db.orders.save(order);
    // Send email
    await sendEmail(order.customerEmail, 'Order confirmed');
}

// ✅ GOOD - Single responsibility per function
async function processOrder(order: Order): Promise<void> {
    validateOrder(order);
    const total = calculateTotal(order.items);
    const finalTotal = applyDiscount(total, order.couponCode);
    await saveOrder(order, finalTotal);
    await notifyCustomer(order.customerEmail);
}

function validateOrder(order: Order): void {
    if (!order.items?.length) {
        throw new ValidationError('Order must have items');
    }
}

function calculateTotal(items: OrderItem[]): number {
    return items.reduce((sum, item) => sum + item.price * item.quantity, 0);
}

function applyDiscount(total: number, couponCode?: string): number {
    return couponCode ? total * 0.9 : total;
}
```

### Signs a Function Has Multiple Responsibilities

| Sign | Action |
|------|--------|
| Multiple `// section` comments | Split at comment boundaries |
| "and" in function name | Split into separate functions |
| More than 3 parameters | Consider parameter object or splitting |
| Nested conditionals > 2 levels | Extract inner logic to functions |
| Function does validation AND processing | Separate validation function |

---

## Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Files | kebab-case | `user-service.ts` |
| Interfaces | PascalCase | `UserRepository` |
| Types | PascalCase | `CreateUserInput` |
| Functions | camelCase | `createUser` |
| Constants | UPPER_SNAKE | `MAX_RETRY_COUNT` |
| Enums | PascalCase + UPPER_SNAKE values | `UserRole.ADMIN` |

---

## Directory Structure

The directory structure follows the **Lerian pattern** - a simplified hexagonal architecture without explicit DDD folders.

```
/src
  /bootstrap           # Application initialization
    config.ts
    server.ts
    service.ts
  /services            # Business logic
    /command           # Write operations (use cases)
    /query             # Read operations (use cases)
  /adapters            # Infrastructure implementations
    /http/in           # HTTP handlers + routes
    /grpc/in           # gRPC handlers (if needed)
    /postgres          # PostgreSQL repositories
    /mongodb           # MongoDB repositories
    /redis             # Redis repositories
    /rabbitmq          # RabbitMQ producers/consumers
  /lib                 # Utilities
    db.ts
    logger.ts
  /types               # Shared types and models
    index.ts
/tests
  /unit
  /integration
```

**Key differences from traditional DDD:**
- **No `/src/domain` folder** - Business entities live in `/src/types` or within service files
- **Services are the core** - `/src/services` contains all business logic (command/query pattern)
- **Adapters are flat** - Database repositories are organized by technology, not by domain

---

## RabbitMQ Worker Pattern

When the application includes async processing (API+Worker or Worker Only), follow this pattern.

### Application Types

| Type | Characteristics | Components |
|------|----------------|------------|
| **API Only** | HTTP endpoints, no async processing | Handlers, Services, Repositories |
| **API + Worker** | HTTP endpoints + async message processing | All above + Consumers, Producers |
| **Worker Only** | No HTTP, only message processing | Consumers, Services, Repositories |

### Architecture Overview

```text
┌─────────────────────────────────────────────────────────────┐
│  Service Bootstrap                                          │
│  ├── HTTP Server (Express/Fastify)  ← API endpoints        │
│  ├── RabbitMQ Consumer              ← Event-driven workers │
│  └── Redis Consumer (optional)      ← Scheduled polling    │
└─────────────────────────────────────────────────────────────┘
```

### Core Types

```typescript
// Handler function signature
type QueueHandlerFunc = (ctx: Context, body: Buffer) => Promise<void>;

// Consumer configuration
interface ConsumerConfig {
    connection: RabbitMQConnection;
    routes: Map<string, QueueHandlerFunc>;
    numberOfWorkers: number;   // Workers per queue (default: 5)
    prefetchCount: number;     // QoS prefetch (default: 10)
    logger: Logger;
    telemetry: Telemetry;
}

// Context for handlers
interface Context {
    requestId: string;
    logger: Logger;
    span: Span;
}
```

### Worker Configuration

| Config | Default | Purpose |
|--------|---------|---------|
| `RABBITMQ_NUMBERS_OF_WORKERS` | 5 | Concurrent workers per queue |
| `RABBITMQ_NUMBERS_OF_PREFETCH` | 10 | Messages buffered per worker |
| `RABBITMQ_CONSUMER_USER` | - | Separate credentials for consumer |
| `RABBITMQ_{QUEUE}_QUEUE` | - | Queue name per handler |

**Formula:** `Total buffered = Workers × Prefetch` (e.g., 5 × 10 = 50 messages)

### Handler Registration

```typescript
// Register handlers per queue
class MultiQueueConsumer {
    registerRoutes(routes: ConsumerRoutes): void {
        routes.register(
            process.env.RABBITMQ_BALANCE_CREATE_QUEUE!,
            this.handleBalanceCreate.bind(this)
        );
        routes.register(
            process.env.RABBITMQ_TRANSACTION_QUEUE!,
            this.handleTransaction.bind(this)
        );
    }
}
```

### Handler Implementation

```typescript
async handleBalanceCreate(ctx: Context, body: Buffer): Promise<void> {
    // 1. Parse and validate message
    const parsed = queueMessageSchema.safeParse(JSON.parse(body.toString()));
    if (!parsed.success) {
        ctx.logger.error('Invalid message format', { error: parsed.error });
        throw new Error(`Invalid message: ${parsed.error.message}`);
    }

    // 2. Execute business logic
    const result = await this.useCase.createBalance(ctx, parsed.data);
    if (!result.success) {
        throw result.error;
    }

    // 3. Success → Ack automatically (by returning without error)
}
```

### Message Acknowledgment

| Result | Action | Effect |
|--------|--------|--------|
| Resolves | `msg.ack()` | Message removed from queue |
| Rejects/Throws | `msg.nack(false, true)` | Message requeued |

### Worker Lifecycle

```text
runConsumers()
├── For each registered queue:
│   ├── ensureChannel() with exponential backoff
│   ├── Set QoS (prefetch)
│   ├── Start consume()
│   └── Process messages with concurrency limit

processMessage():
├── Extract/generate TraceID from headers
├── Create context with requestId
├── Start OpenTelemetry span
├── Call handler(ctx, msg.content)
├── On success: msg.ack()
└── On error: log + msg.nack(false, true)
```

### Exponential Backoff with Jitter

```typescript
const BACKOFF_CONFIG = {
    maxRetries: 5,
    initialBackoff: 500,    // ms
    maxBackoff: 10_000,     // ms
    backoffFactor: 2.0,
} as const;

function fullJitter(baseDelay: number): number {
    const jitter = Math.random() * baseDelay;
    return Math.min(jitter, BACKOFF_CONFIG.maxBackoff);
}

function nextBackoff(current: number): number {
    const next = current * BACKOFF_CONFIG.backoffFactor;
    return Math.min(next, BACKOFF_CONFIG.maxBackoff);
}
```

### Producer Implementation

```typescript
class ProducerRepository {
    async publish(
        exchange: string,
        routingKey: string,
        message: unknown,
        ctx: Context
    ): Promise<void> {
        await this.ensureChannel();

        const headers = {
            'x-request-id': ctx.requestId,
            ...injectTraceHeaders(ctx.span),
        };

        this.channel.publish(
            exchange,
            routingKey,
            Buffer.from(JSON.stringify(message)),
            {
                contentType: 'application/json',
                persistent: true,
                headers,
            }
        );
    }
}
```

### Message Schema with Zod

```typescript
const queueDataSchema = z.object({
    id: z.string().uuid(),
    value: z.unknown(),
});

const queueMessageSchema = z.object({
    organizationId: z.string().uuid(),
    ledgerId: z.string().uuid(),
    auditId: z.string().uuid(),
    data: z.array(queueDataSchema),
});

type QueueMessage = z.infer<typeof queueMessageSchema>;
```

### Service Bootstrap (API + Worker)

```typescript
class Service {
    constructor(
        private readonly server: HttpServer,
        private readonly consumer: MultiQueueConsumer,
        private readonly logger: Logger,
    ) {}

    async run(): Promise<void> {
        // Run all components concurrently
        await Promise.all([
            this.server.listen(),
            this.consumer.start(),
        ]);

        // Graceful shutdown
        process.on('SIGTERM', async () => {
            this.logger.info('Shutting down...');
            await this.consumer.stop();
            await this.server.close();
        });
    }
}
```

### Directory Structure for Workers

```text
/src
  /infrastructure
    /rabbitmq
      consumer.ts      # ConsumerRoutes, worker pool
      producer.ts      # ProducerRepository
      connection.ts    # Connection management
  /bootstrap
    rabbitmq-server.ts # MultiQueueConsumer, handler registration
    service.ts         # Service orchestration
  /lib
    backoff.ts         # Backoff utilities
  /types
    queue.ts           # Message schemas
```

### Worker Checklist

- [ ] Handlers are idempotent (safe to process duplicates)
- [ ] Manual Ack enabled (`noAck: false`)
- [ ] Error handling throws error (triggers Nack)
- [ ] Context propagation with requestId
- [ ] OpenTelemetry spans for tracing
- [ ] Exponential backoff for connection recovery
- [ ] Graceful shutdown with proper cleanup
- [ ] Separate credentials for consumer vs producer
- [ ] Zod validation for all message payloads

---

## Checklist

Before submitting TypeScript code, verify:

### Type Safety
- [ ] No `any` types (use `unknown` with narrowing)
- [ ] Strict mode enabled in tsconfig.json
- [ ] Zod validation for all external input
- [ ] Branded types for IDs
- [ ] Discriminated unions for state machines
- [ ] Type inference used where possible (avoid redundant annotations)
- [ ] No `@ts-ignore` or `@ts-expect-error` without explanation

### Error Handling
- [ ] Error classes extend base AppError
- [ ] All async functions have proper error handling
- [ ] Result type used for operations that can fail

### DDD (if enabled)
- [ ] Entities have identity comparison (`equals` method)
- [ ] Value Objects are immutable (private constructor, factory methods)
- [ ] Aggregates enforce invariants before state changes
- [ ] Domain Events emitted for significant state changes
- [ ] Repository interfaces defined in domain layer
- [ ] No infrastructure dependencies in domain layer
