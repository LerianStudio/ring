# TypeScript Standards

This file defines the specific standards for TypeScript (backend) development.

> **Reference**: Always consult `docs/PROJECT_RULES.md` for common project standards.

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

## Type Safety Rules

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

## Testing Patterns

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

## DDD Patterns (TypeScript Implementation)

If DDD is enabled in the project, use these patterns.

### Entity

```typescript
// Entity - object with identity that persists over time
import { z } from 'zod';

// Branded type for ID
type UserId = Brand<string, 'UserId'>;

// Entity class
class User {
    constructor(
        public readonly id: UserId,
        public email: Email,
        public name: string,
        public readonly createdAt: Date,
        public updatedAt: Date,
    ) {}

    // Identity comparison - entities are equal if IDs match
    equals(other: User): boolean {
        return this.id === other.id;
    }

    // Domain behavior
    changeName(newName: string): void {
        if (newName.length < 1) {
            throw new DomainError('Name cannot be empty');
        }
        this.name = newName;
        this.updatedAt = new Date();
    }
}
```

### Value Object

```typescript
// Value Object - immutable, defined by attributes, no identity
class Money {
    private constructor(
        private readonly amount: number, // cents to avoid float issues
        private readonly currency: string,
    ) {}

    // Factory with validation
    static create(amount: number, currency: string): Result<Money, ValidationError> {
        if (!currency || currency.length !== 3) {
            return { success: false, error: new ValidationError('Invalid currency') };
        }
        return { success: true, data: new Money(amount, currency) };
    }

    // Operations return new instances (immutable)
    add(other: Money): Result<Money, DomainError> {
        if (this.currency !== other.currency) {
            return { success: false, error: new DomainError('Currency mismatch') };
        }
        return { success: true, data: new Money(this.amount + other.amount, this.currency) };
    }

    // Value comparison - equal if all attributes match
    equals(other: Money): boolean {
        return this.amount === other.amount && this.currency === other.currency;
    }

    // Getters
    getAmount(): number { return this.amount; }
    getCurrency(): string { return this.currency; }
}

// Value Object with Zod validation
const emailSchema = z.string().email();
type Email = z.infer<typeof emailSchema> & { __brand: 'Email' };

function createEmail(value: string): Result<Email, ValidationError> {
    const result = emailSchema.safeParse(value);
    if (!result.success) {
        return { success: false, error: new ValidationError(result.error) };
    }
    return { success: true, data: value as Email };
}
```

### Aggregate Root

```typescript
// Aggregate Root - entry point for cluster of entities
class Order {
    private readonly events: DomainEvent[] = [];

    constructor(
        public readonly id: OrderId,
        public readonly customerId: CustomerId,
        private items: OrderItem[],
        private status: OrderStatus,
        private total: Money,
    ) {}

    // All modifications through Aggregate Root
    addItem(product: Product, quantity: number): Result<void, DomainError> {
        // Enforce invariants
        if (this.status !== 'draft') {
            return { success: false, error: new DomainError('Order is not modifiable') };
        }

        const item = OrderItem.create(product, quantity);
        this.items.push(item);
        this.recalculateTotal();

        // Emit domain event
        this.events.push(new OrderItemAdded({
            orderId: this.id,
            productId: product.id,
            quantity,
        }));

        return { success: true, data: undefined };
    }

    // Invariant enforcement
    submit(): Result<void, DomainError> {
        if (this.items.length === 0) {
            return { success: false, error: new DomainError('Order cannot be empty') };
        }
        if (this.status !== 'draft') {
            return { success: false, error: new DomainError('Order already submitted') };
        }

        this.status = 'submitted';
        this.events.push(new OrderSubmitted({ orderId: this.id }));

        return { success: true, data: undefined };
    }

    // Get pending events for publishing
    pullEvents(): DomainEvent[] {
        const events = [...this.events];
        this.events.length = 0;
        return events;
    }

    private recalculateTotal(): void {
        // ... recalculate total from items
    }
}
```

### Domain Event

```typescript
// Domain Event - record of something that happened (past tense)
interface DomainEvent {
    readonly eventName: string;
    readonly occurredAt: Date;
    readonly payload: Record<string, unknown>;
}

class OrderSubmitted implements DomainEvent {
    readonly eventName = 'order.submitted';
    readonly occurredAt = new Date();

    constructor(
        readonly payload: {
            orderId: OrderId;
            customerId?: CustomerId;
            total?: Money;
        }
    ) {}
}

// Event Publisher interface
interface EventPublisher {
    publish(events: DomainEvent[]): Promise<void>;
}
```

### Repository Pattern

```typescript
// Repository interface (port) - collection-like API
interface OrderRepository {
    findById(id: OrderId): Promise<Order | null>;
    findByCustomer(customerId: CustomerId): Promise<Order[]>;
    save(order: Order): Promise<void>;
    delete(id: OrderId): Promise<void>;
}

// Prisma implementation (adapter)
class PrismaOrderRepository implements OrderRepository {
    constructor(
        private readonly prisma: PrismaClient,
        private readonly eventPublisher: EventPublisher,
    ) {}

    async findById(id: OrderId): Promise<Order | null> {
        const data = await this.prisma.order.findUnique({
            where: { id },
            include: { items: true },
        });
        return data ? this.toDomain(data) : null;
    }

    async save(order: Order): Promise<void> {
        await this.prisma.$transaction(async (tx) => {
            await tx.order.upsert({
                where: { id: order.id },
                create: this.toData(order),
                update: this.toData(order),
            });

            // Publish domain events
            const events = order.pullEvents();
            await this.eventPublisher.publish(events);
        });
    }

    private toDomain(data: OrderData): Order {
        // Map database model to domain entity
    }

    private toData(order: Order): OrderData {
        // Map domain entity to database model
    }
}
```

### Domain Service

```typescript
// Domain Service - business logic that doesn't belong to entities
class PricingService {
    constructor(
        private readonly discountRepo: DiscountRepository,
        private readonly taxService: TaxService,
    ) {}

    // Cross-aggregate operation
    async calculateOrderTotal(
        items: OrderItem[],
        customerId: CustomerId,
    ): Promise<Result<Money, DomainError>> {
        const subtotal = this.calculateSubtotal(items);

        const discount = await this.discountRepo.findForCustomer(customerId);
        const withDiscountResult = discount
            ? subtotal.subtract(discount.amount)
            : { success: true as const, data: subtotal };

        if (!withDiscountResult.success) {
            return withDiscountResult;
        }

        const taxResult = await this.taxService.calculate(withDiscountResult.data);
        if (!taxResult.success) {
            return taxResult;
        }

        return withDiscountResult.data.add(taxResult.data);
    }

    private calculateSubtotal(items: OrderItem[]): Money {
        return items.reduce(
            (sum, item) => sum.add(item.total).data!,
            Money.create(0, 'USD').data!,
        );
    }
}
```

### DDD Directory Structure

```
/src
  /domain                    # Core domain (no external dependencies)
    /order
      order.ts               # Aggregate root
      order-item.ts          # Child entity
      order-status.ts        # Value object / enum
      order-events.ts        # Domain events
      order-repository.ts    # Repository interface (port)
    /shared
      money.ts               # Shared value object
      domain-error.ts        # Domain errors
      domain-event.ts        # Event interface
  /application               # Use cases / Application services
    /order
      create-order.ts        # Command handler
      get-order.ts           # Query handler
  /infrastructure            # Adapters
    /persistence
      prisma-order-repository.ts
    /messaging
      rabbitmq-event-publisher.ts
  /api                       # HTTP handlers
    /order
      order-controller.ts
```

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

## Directory Structure (Backend)

```
/src
  /domain              # Business entities
    user.ts
    errors.ts
  /services            # Business logic
    user-service.ts
  /repositories        # Data access
    user-repository.ts
    /implementations
      postgres-user-repository.ts
  /handlers            # HTTP handlers
    user-handler.ts
  /middleware          # Express/Fastify middleware
    auth.ts
    error-handler.ts
  /lib                 # Utilities
    db.ts
    logger.ts
  /types               # Shared types
    index.ts
/tests
  /unit
  /integration
```

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

---

## 12-Factor App Compliance (MANDATORY for All Services)

The [12-Factor App methodology](https://12factor.net) defines cloud-native best practices. TypeScript developers are responsible for implementing code patterns that enable 12-Factor compliance.

### Developer-Owned Factors

| Factor | What Developers Must Do | Verification |
|--------|------------------------|--------------|
| III. Config | Read ALL config from process.env | No hardcoded values |
| IV. Backing Services | Connect via URL from config | No hardcoded hosts |
| VI. Processes | Write stateless code, no local file storage | No fs.writeFile for user data |
| IX. Disposability | Implement graceful shutdown (SIGTERM) | process.on('SIGTERM') present |
| XI. Logs | Write to stdout only, JSON format | No fs.createWriteStream for logs |

---

### III. Config - Environment Variables (CRITICAL)

**All configuration MUST come from environment variables.** Validate with Zod at startup.

#### CORRECT Pattern

```typescript
import { z } from 'zod';

// Define and validate config at startup
const configSchema = z.object({
  // Application
  NODE_ENV: z.enum(['development', 'staging', 'production']).default('development'),
  PORT: z.string().transform(Number).default('3000'),
  LOG_LEVEL: z.enum(['debug', 'info', 'warn', 'error']).default('info'),

  // Database
  DATABASE_URL: z.string().url(),
  DATABASE_POOL_SIZE: z.string().transform(Number).default('10'),

  // Redis
  REDIS_URL: z.string().url(),

  // External Services
  AUTH_SERVICE_URL: z.string().url(),

  // Secrets (required, no defaults)
  JWT_SECRET: z.string().min(32),
  API_KEY: z.string().min(20),
});

// Validate on startup - fails fast if config missing
export const config = configSchema.parse(process.env);

// Type-safe access throughout application
console.log(config.DATABASE_URL);  // TypeScript knows it's a string
```

#### FORBIDDEN Patterns (Will Fail Code Review)

```typescript
// FORBIDDEN - Hardcoded connection strings
const dbHost = 'localhost:5432';                    // FAIL
const dbHost = 'db.internal.company.com';           // FAIL
const redisUrl = 'redis://localhost:6379';          // FAIL

// FORBIDDEN - Hardcoded credentials
const apiKey = 'sk_live_xxx';                       // FAIL - SECURITY CRITICAL
const jwtSecret = 'mysecretkey';                    // FAIL - SECURITY CRITICAL

// FORBIDDEN - Environment-specific code paths with hardcoded values
if (process.env.NODE_ENV === 'production') {
  const dbHost = 'prod-db.internal';                // FAIL - Still hardcoded!
}

// FORBIDDEN - Config files with secrets
import config from './config.json';                  // FAIL if contains credentials
```

#### Verification Command

```bash
# Check for hardcoded hosts (should return empty)
grep -rE "(localhost|127\.0\.0\.1|:5432|:6379|:3306)" \
  --include="*.ts" --include="*.js" | grep -v test | grep -v node_modules | grep -v ".d.ts"
```

---

### VI. Processes - Stateless Code (CRITICAL)

**Applications must be stateless.** Any data that needs to persist must use a backing service.

#### CORRECT Patterns

```typescript
// CORRECT - Session in Redis
import Redis from 'ioredis';

class SessionStore {
  constructor(private redis: Redis) {}

  async get(sessionId: string): Promise<Session | null> {
    const data = await this.redis.get(`session:${sessionId}`);
    if (!data) return null;
    return JSON.parse(data) as Session;
  }

  async set(sessionId: string, session: Session, ttlSeconds = 86400): Promise<void> {
    await this.redis.setex(`session:${sessionId}`, ttlSeconds, JSON.stringify(session));
  }
}

// CORRECT - File uploads to S3
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';

class StorageService {
  constructor(private s3: S3Client, private bucket: string) {}

  async upload(key: string, body: Buffer): Promise<string> {
    await this.s3.send(new PutObjectCommand({
      Bucket: this.bucket,
      Key: key,
      Body: body,
    }));
    return `s3://${this.bucket}/${key}`;
  }
}
```

#### FORBIDDEN Patterns (Will Fail Code Review)

```typescript
// FORBIDDEN - Local file storage for user data
import fs from 'fs';

async function uploadFile(filename: string, data: Buffer): Promise<void> {
  await fs.promises.writeFile(`/uploads/${filename}`, data);  // FAIL - Lost on restart!
}

// FORBIDDEN - In-memory session (lost on restart)
const sessions = new Map<string, Session>();        // FAIL - Global state!

function getSession(id: string): Session | undefined {
  return sessions.get(id);                          // FAIL - Gone when process restarts!
}

// FORBIDDEN - Local cache that can't be shared
const cache = new Map<string, unknown>();           // FAIL - Not shared across replicas!
```

#### Verification Command

```bash
# Check for local file storage (should return empty for user data)
grep -rE "fs\.writeFile|fs\.createWriteStream|writeFileSync" \
  --include="*.ts" --include="*.js" | grep -v test | grep -v node_modules | grep -v ".log"
```

---

### IX. Disposability - Graceful Shutdown (CRITICAL)

**All services MUST handle SIGTERM gracefully.** This is required for Kubernetes rolling deployments.

#### REQUIRED Pattern

```typescript
import http from 'http';

const server = http.createServer(app);

server.listen(config.PORT, () => {
  console.log(`Server listening on port ${config.PORT}`);
});

// REQUIRED - Graceful shutdown handler
const shutdown = async (signal: string) => {
  console.log(`${signal} received, shutting down gracefully...`);

  // Stop accepting new connections
  server.close(async () => {
    console.log('HTTP server closed');

    try {
      // REQUIRED - Close database connections
      await prisma.$disconnect();
      console.log('Database disconnected');

      // REQUIRED - Close Redis connections
      await redis.quit();
      console.log('Redis disconnected');

      console.log('Cleanup complete, exiting');
      process.exit(0);
    } catch (error) {
      console.error('Error during cleanup:', error);
      process.exit(1);
    }
  });

  // REQUIRED - Force exit after timeout
  setTimeout(() => {
    console.error('Forced shutdown after 30s timeout');
    process.exit(1);
  }, 30000);
};

// REQUIRED - Register signal handlers
process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
```

#### NestJS Pattern

```typescript
// main.ts
import { NestFactory } from '@nestjs/core';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // REQUIRED - Enable graceful shutdown hooks
  app.enableShutdownHooks();

  await app.listen(config.PORT);
}

// In a service - implement OnModuleDestroy
@Injectable()
class DatabaseService implements OnModuleDestroy {
  async onModuleDestroy() {
    await this.connection.close();
    console.log('Database connection closed');
  }
}
```

#### Verification Command

```bash
# Check for SIGTERM handling (should find process.on)
grep -rE "process\.on\(['\"]SIGTERM" --include="*.ts" --include="*.js" | grep -v node_modules
```

---

### XI. Logs - Stdout Only (MANDATORY)

**All logs MUST go to stdout.** Log aggregation is handled by the infrastructure.

#### CORRECT Pattern (Using @lerianstudio/lib-commons-js)

```typescript
import { ConsoleLogger } from '@lerianstudio/lib-commons-js';

// CORRECT - Structured logging to stdout
const logger = new ConsoleLogger();

// CORRECT - Structured logging with context using withFields
const requestLogger = logger.withFields({
  method: req.method,
  path: req.path,
  traceId: req.headers['x-trace-id'],
});
requestLogger.info('Request received');

// CORRECT - Error logging with context
const errorLogger = logger.withFields({
  traceId,
  userId,
  error: err.message,
  stack: err.stack,
});
errorLogger.error('Failed to process request');

// CORRECT - Using withDefaultMessageTemplate for consistent prefixes
const serviceLogger = logger.withDefaultMessageTemplate('[UserService]');
serviceLogger.info('Starting user lookup');

// CORRECT - Printf-style logging
logger.infof('User %s logged in from IP %s', userId, clientIp);
```

#### FORBIDDEN Patterns (Will Fail Code Review)

```typescript
// FORBIDDEN - File logging
import fs from 'fs';
const logStream = fs.createWriteStream('/var/log/app.log', { flags: 'a' });

// FORBIDDEN - Winston file transport
import winston from 'winston';
const logger = winston.createLogger({
  transports: [
    new winston.transports.File({ filename: 'error.log' })  // FAIL!
  ]
});

// FORBIDDEN - Console.log for production logs
console.log(`User ${userId} logged in`);  // FAIL - Unstructured, not JSON
```

#### Verification Command

```bash
# Check for file logging (should return empty)
grep -rE "createWriteStream.*\.log|transports\.File|writeFile.*\.log" \
  --include="*.ts" --include="*.js" | grep -v test | grep -v node_modules
```

---

### 12-Factor Compliance Checklist (TypeScript Developers)

Before submitting code for review, verify:

**Config (III) - CRITICAL:**
- [ ] All config loaded via process.env with Zod validation
- [ ] No hardcoded hostnames (localhost, IP addresses)
- [ ] No hardcoded credentials or API keys
- [ ] Config validation fails fast at startup

**Stateless (VI) - CRITICAL:**
- [ ] No local file storage for user data
- [ ] Sessions stored in Redis/database
- [ ] File uploads go to S3/GCS
- [ ] No in-memory Maps for user data

**Disposability (IX) - CRITICAL:**
- [ ] SIGTERM signal handler implemented
- [ ] Graceful server shutdown
- [ ] Database connections closed on shutdown
- [ ] Force exit timeout as safety net

**Logs (XI):**
- [ ] All logs written to stdout
- [ ] Using @lerianstudio/lib-commons-js ConsoleLogger
- [ ] Structured format with withFields for context
- [ ] No file-based logging
