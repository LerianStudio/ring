# Python Standards

Este arquivo define os padrões específicos para desenvolvimento em Python.

> **Referência**: Sempre consulte também `docs/STANDARDS.md` para padrões comuns do projeto.

---

## Version

- Python 3.11+ (preferível 3.12+)

---

## Frameworks & Libraries

### Web Frameworks

| Framework | Use Case |
|-----------|----------|
| FastAPI | High-performance async APIs |
| Django | Full-featured web framework |
| Flask | Lightweight, flexible |
| Litestar | Modern async framework |

### ORMs & Database

| Library | Use Case |
|---------|----------|
| SQLAlchemy 2.0 | Full ORM (sync + async) |
| Tortoise ORM | Async-first ORM |
| asyncpg | PostgreSQL async driver |
| Motor | MongoDB async driver |
| redis-py | Redis client |

### Validation

| Library | Use Case |
|---------|----------|
| Pydantic v2 | Data validation + settings |
| marshmallow | Serialization/validation |
| attrs | Classes without boilerplate |

### Async

| Library | Use Case |
|---------|----------|
| asyncio | Core async (stdlib) |
| aiohttp | Async HTTP client |
| httpx | Sync + async HTTP client |
| aiocache | Async caching |

### Testing

| Library | Use Case |
|---------|----------|
| pytest | Test framework |
| pytest-asyncio | Async test support |
| pytest-mock | Mocking |
| hypothesis | Property-based testing |
| testcontainers | Integration tests |

### Observability

| Library | Use Case |
|---------|----------|
| structlog | Structured logging |
| python-json-logger | JSON logging |
| OpenTelemetry | Tracing + metrics |
| Sentry | Error tracking |

---

## Type Hints (MANDATORY)

### Basic Type Hints

```python
from typing import Optional, List, Dict, Any
from datetime import datetime

def get_user(user_id: str) -> User:
    """Fetch user by ID."""
    ...

def create_user(
    name: str,
    email: str,
    age: Optional[int] = None,
) -> User:
    """Create a new user."""
    ...

def process_items(items: List[str]) -> Dict[str, int]:
    """Process items and return counts."""
    ...

# Python 3.10+ - use built-in types
def get_users() -> list[User]:
    ...

def get_config() -> dict[str, Any]:
    ...
```

### Mypy Strict Mode

```ini
# pyproject.toml
[tool.mypy]
python_version = "3.11"
strict = true
warn_return_any = true
warn_unused_ignores = true
disallow_untyped_defs = true
disallow_any_generics = true
no_implicit_optional = true
```

### Protocol for Interfaces

```python
from typing import Protocol, runtime_checkable

@runtime_checkable
class UserRepository(Protocol):
    """Repository interface for User operations."""

    async def find_by_id(self, user_id: str) -> User | None:
        """Find user by ID."""
        ...

    async def save(self, user: User) -> None:
        """Save user to storage."""
        ...

# Implementation doesn't need to inherit - just implement methods
class PostgresUserRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def find_by_id(self, user_id: str) -> User | None:
        return await self.db.get(User, user_id)

    async def save(self, user: User) -> None:
        self.db.add(user)
        await self.db.commit()

# Type checking works
def create_user_service(repo: UserRepository) -> UserService:
    return UserService(repo)
```

---

## Pydantic Models

### Data Validation

```python
from pydantic import BaseModel, Field, field_validator, EmailStr
from decimal import Decimal
from datetime import datetime
from typing import Optional

class CreateUserInput(BaseModel):
    """Input for creating a user."""

    name: str = Field(min_length=1, max_length=100)
    email: EmailStr
    age: Optional[int] = Field(default=None, ge=0, le=150)

    @field_validator('name')
    @classmethod
    def name_must_not_be_empty(cls, v: str) -> str:
        if not v.strip():
            raise ValueError('Name cannot be empty or whitespace')
        return v.strip()

class User(BaseModel):
    """User entity."""

    id: str
    name: str
    email: str
    created_at: datetime
    updated_at: datetime

    model_config = {
        'from_attributes': True,  # Allow from ORM models
        'json_encoders': {
            datetime: lambda v: v.isoformat(),
        },
    }
```

### Financial Precision

```python
from pydantic import BaseModel, Field
from decimal import Decimal

class Money(BaseModel):
    """Value object for monetary amounts."""

    amount: Decimal = Field(decimal_places=2)
    currency: str = Field(min_length=3, max_length=3)

    def add(self, other: 'Money') -> 'Money':
        if self.currency != other.currency:
            raise ValueError('Currency mismatch')
        return Money(
            amount=self.amount + other.amount,
            currency=self.currency,
        )

# FORBIDDEN - never use float for money
class BadMoney(BaseModel):
    amount: float  # WRONG - precision issues
```

### Settings Management

```python
from pydantic_settings import BaseSettings
from pydantic import Field, SecretStr

class Settings(BaseSettings):
    """Application settings from environment."""

    # Database
    database_url: str = Field(alias='DATABASE_URL')
    database_pool_size: int = Field(default=5)

    # Redis
    redis_url: str = Field(alias='REDIS_URL')

    # Auth
    jwt_secret: SecretStr = Field(alias='JWT_SECRET')
    jwt_expiration: int = Field(default=3600)

    # App
    debug: bool = Field(default=False)
    log_level: str = Field(default='INFO')

    model_config = {
        'env_file': '.env',
        'env_file_encoding': 'utf-8',
    }

# Usage - validates at startup
settings = Settings()
```

---

## Async Patterns

### Async Context Managers

```python
from contextlib import asynccontextmanager
from typing import AsyncGenerator

@asynccontextmanager
async def get_db_session() -> AsyncGenerator[AsyncSession, None]:
    """Provide database session with automatic cleanup."""
    session = AsyncSession(engine)
    try:
        yield session
        await session.commit()
    except Exception:
        await session.rollback()
        raise
    finally:
        await session.close()

# Usage
async def create_user(input: CreateUserInput) -> User:
    async with get_db_session() as session:
        user = User(**input.model_dump())
        session.add(user)
        return user
```

### Background Tasks

```python
import asyncio
from typing import Callable, Coroutine, Any

class BackgroundTasks:
    """Manage background tasks."""

    def __init__(self):
        self._tasks: set[asyncio.Task] = set()

    def add_task(
        self,
        coro: Coroutine[Any, Any, Any],
        name: str | None = None,
    ) -> asyncio.Task:
        task = asyncio.create_task(coro, name=name)
        self._tasks.add(task)
        task.add_done_callback(self._tasks.discard)
        return task

    async def shutdown(self, timeout: float = 30.0) -> None:
        """Wait for all tasks to complete."""
        if self._tasks:
            await asyncio.wait(self._tasks, timeout=timeout)

# Usage
background = BackgroundTasks()

async def send_email(user: User) -> None:
    # ... send email logic
    pass

async def create_user_handler(input: CreateUserInput) -> User:
    user = await create_user(input)
    background.add_task(send_email(user), name=f'email_{user.id}')
    return user
```

### Error Handling with Async

```python
import asyncio
from typing import TypeVar, Generic

T = TypeVar('T')

class Result(Generic[T]):
    """Result type for error handling."""

    def __init__(self, value: T | None = None, error: Exception | None = None):
        self._value = value
        self._error = error

    @property
    def is_ok(self) -> bool:
        return self._error is None

    @property
    def value(self) -> T:
        if self._error:
            raise self._error
        return self._value  # type: ignore

    @property
    def error(self) -> Exception | None:
        return self._error

    @classmethod
    def ok(cls, value: T) -> 'Result[T]':
        return cls(value=value)

    @classmethod
    def err(cls, error: Exception) -> 'Result[T]':
        return cls(error=error)

# Usage
async def create_user_safe(input: CreateUserInput) -> Result[User]:
    try:
        user = await create_user(input)
        return Result.ok(user)
    except ValidationError as e:
        return Result.err(e)
```

---

## SQLAlchemy 2.0 Async

### Model Definition

```python
from sqlalchemy import String, DateTime, func
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column
from datetime import datetime

class Base(DeclarativeBase):
    pass

class UserModel(Base):
    __tablename__ = 'users'

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    name: Mapped[str] = mapped_column(String(100))
    email: Mapped[str] = mapped_column(String(255), unique=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), onupdate=func.now()
    )
```

### Repository Pattern

```python
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

class PostgresUserRepository:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def find_by_id(self, user_id: str) -> User | None:
        stmt = select(UserModel).where(UserModel.id == user_id)
        result = await self.session.execute(stmt)
        row = result.scalar_one_or_none()
        return User.model_validate(row) if row else None

    async def find_by_email(self, email: str) -> User | None:
        stmt = select(UserModel).where(UserModel.email == email)
        result = await self.session.execute(stmt)
        row = result.scalar_one_or_none()
        return User.model_validate(row) if row else None

    async def save(self, user: User) -> None:
        model = UserModel(**user.model_dump())
        self.session.add(model)
        await self.session.flush()
```

---

## FastAPI Patterns

### Dependency Injection

```python
from fastapi import Depends, FastAPI
from typing import Annotated

app = FastAPI()

async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSession(engine) as session:
        yield session

async def get_user_repository(
    db: Annotated[AsyncSession, Depends(get_db)]
) -> UserRepository:
    return PostgresUserRepository(db)

async def get_user_service(
    repo: Annotated[UserRepository, Depends(get_user_repository)]
) -> UserService:
    return UserService(repo)

@app.post('/users', response_model=User)
async def create_user(
    input: CreateUserInput,
    service: Annotated[UserService, Depends(get_user_service)],
) -> User:
    return await service.create(input)
```

### Error Handling

```python
from fastapi import HTTPException, Request
from fastapi.responses import JSONResponse

class ServiceError(Exception):
    """Base service error."""

    def __init__(self, message: str, code: str, status_code: int = 500):
        self.message = message
        self.code = code
        self.status_code = status_code

class NotFoundError(ServiceError):
    def __init__(self, resource: str):
        super().__init__(
            message=f'{resource} not found',
            code='NOT_FOUND',
            status_code=404,
        )

@app.exception_handler(ServiceError)
async def service_error_handler(request: Request, exc: ServiceError) -> JSONResponse:
    return JSONResponse(
        status_code=exc.status_code,
        content={'error': {'code': exc.code, 'message': exc.message}},
    )
```

---

## Testing Patterns

### Pytest Fixtures

```python
import pytest
from pytest_asyncio import fixture

@fixture
async def db_session() -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSession(test_engine) as session:
        yield session
        await session.rollback()

@fixture
def user_repository(db_session: AsyncSession) -> UserRepository:
    return PostgresUserRepository(db_session)

@fixture
def user_service(user_repository: UserRepository) -> UserService:
    return UserService(user_repository)
```

### Async Tests

```python
import pytest

@pytest.mark.asyncio
async def test_create_user(user_service: UserService) -> None:
    # Arrange
    input = CreateUserInput(name='John', email='john@example.com')

    # Act
    user = await user_service.create(input)

    # Assert
    assert user.id is not None
    assert user.name == 'John'
    assert user.email == 'john@example.com'

@pytest.mark.asyncio
async def test_create_user_duplicate_email(user_service: UserService) -> None:
    # Arrange
    input = CreateUserInput(name='John', email='john@example.com')
    await user_service.create(input)

    # Act & Assert
    with pytest.raises(DuplicateEmailError):
        await user_service.create(input)
```

---

## Linting & Formatting

### Ruff Configuration

```toml
# pyproject.toml
[tool.ruff]
line-length = 100
target-version = "py311"

[tool.ruff.lint]
select = [
    "E",    # pycodestyle errors
    "W",    # pycodestyle warnings
    "F",    # pyflakes
    "I",    # isort
    "C4",   # flake8-comprehensions
    "B",    # flake8-bugbear
    "UP",   # pyupgrade
    "ARG",  # flake8-unused-arguments
    "SIM",  # flake8-simplify
]
ignore = ["E501"]  # line too long - handled by formatter

[tool.ruff.format]
quote-style = "single"
```

### Commands

```bash
# Format code
ruff format .

# Lint code
ruff check .

# Fix auto-fixable issues
ruff check --fix .

# Type check
mypy src/
```

---

## DDD Patterns (Python Implementation)

Se DDD estiver habilitado no projeto, use estes padrões.

### Entity

```python
from dataclasses import dataclass, field
from datetime import datetime
from typing import NewType
import uuid

# Branded type for ID (using NewType)
UserId = NewType('UserId', str)
OrderId = NewType('OrderId', str)

def create_user_id() -> UserId:
    return UserId(f'usr_{uuid.uuid4().hex[:12]}')

@dataclass
class User:
    """Entity - objeto com identidade que persiste ao longo do tempo."""

    id: UserId
    email: str
    name: str
    created_at: datetime = field(default_factory=datetime.utcnow)
    updated_at: datetime = field(default_factory=datetime.utcnow)

    def __eq__(self, other: object) -> bool:
        """Identity comparison - entities are equal if IDs match."""
        if not isinstance(other, User):
            return NotImplemented
        return self.id == other.id

    def __hash__(self) -> int:
        return hash(self.id)

    def change_name(self, new_name: str) -> None:
        """Domain behavior with validation."""
        if not new_name.strip():
            raise DomainError('Name cannot be empty')
        self.name = new_name.strip()
        self.updated_at = datetime.utcnow()
```

### Value Object

```python
from dataclasses import dataclass
from decimal import Decimal
from typing import Self

@dataclass(frozen=True)  # frozen=True makes it immutable
class Money:
    """Value Object - imutável, definido por atributos, sem identidade."""

    amount: Decimal
    currency: str

    def __post_init__(self) -> None:
        """Validate on creation."""
        if len(self.currency) != 3:
            raise ValueError('Currency must be 3 characters')
        if self.amount < 0:
            raise ValueError('Amount cannot be negative')

    def add(self, other: Self) -> Self:
        """Operations return new instances (immutable)."""
        if self.currency != other.currency:
            raise DomainError('Currency mismatch')
        return Money(amount=self.amount + other.amount, currency=self.currency)

    def subtract(self, other: Self) -> Self:
        if self.currency != other.currency:
            raise DomainError('Currency mismatch')
        return Money(amount=self.amount - other.amount, currency=self.currency)

    @classmethod
    def zero(cls, currency: str = 'USD') -> Self:
        return cls(amount=Decimal('0'), currency=currency)


@dataclass(frozen=True)
class Email:
    """Value Object with validation."""

    value: str

    def __post_init__(self) -> None:
        import re
        if not re.match(r'^[\w\.-]+@[\w\.-]+\.\w+$', self.value):
            raise ValueError('Invalid email format')
```

### Aggregate Root

```python
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Self

class OrderStatus(str, Enum):
    DRAFT = 'draft'
    SUBMITTED = 'submitted'
    CONFIRMED = 'confirmed'
    CANCELLED = 'cancelled'

@dataclass
class OrderItem:
    """Child entity within Order aggregate."""

    id: str
    product_id: str
    quantity: int
    unit_price: Money

    @property
    def total(self) -> Money:
        return Money(
            amount=self.unit_price.amount * self.quantity,
            currency=self.unit_price.currency,
        )

@dataclass
class Order:
    """Aggregate Root - ponto de entrada para cluster de entidades."""

    id: OrderId
    customer_id: str
    status: OrderStatus = OrderStatus.DRAFT
    items: list[OrderItem] = field(default_factory=list)
    _events: list['DomainEvent'] = field(default_factory=list, repr=False)

    def add_item(self, product_id: str, quantity: int, unit_price: Money) -> None:
        """All modifications through Aggregate Root."""
        # Enforce invariants
        if self.status != OrderStatus.DRAFT:
            raise DomainError('Order is not modifiable')
        if quantity <= 0:
            raise DomainError('Quantity must be positive')

        item = OrderItem(
            id=f'item_{uuid.uuid4().hex[:8]}',
            product_id=product_id,
            quantity=quantity,
            unit_price=unit_price,
        )
        self.items.append(item)

        # Emit domain event
        self._events.append(OrderItemAdded(
            order_id=self.id,
            product_id=product_id,
            quantity=quantity,
        ))

    def submit(self) -> None:
        """Invariant enforcement."""
        if not self.items:
            raise DomainError('Order cannot be empty')
        if self.status != OrderStatus.DRAFT:
            raise DomainError('Order already submitted')

        self.status = OrderStatus.SUBMITTED
        self._events.append(OrderSubmitted(order_id=self.id, total=self.total))

    @property
    def total(self) -> Money:
        if not self.items:
            return Money.zero()
        return sum(
            (item.total for item in self.items[1:]),
            start=self.items[0].total,
        )

    def pull_events(self) -> list['DomainEvent']:
        """Get pending events for publishing."""
        events = self._events.copy()
        self._events.clear()
        return events
```

### Domain Event

```python
from dataclasses import dataclass, field
from datetime import datetime
from typing import Protocol

class DomainEvent(Protocol):
    """Domain Event - registro de algo que aconteceu (passado)."""

    @property
    def event_name(self) -> str: ...

    @property
    def occurred_at(self) -> datetime: ...

@dataclass(frozen=True)
class OrderSubmitted:
    """Event emitted when order is submitted."""

    order_id: OrderId
    total: Money
    occurred_at: datetime = field(default_factory=datetime.utcnow)

    @property
    def event_name(self) -> str:
        return 'order.submitted'

@dataclass(frozen=True)
class OrderItemAdded:
    """Event emitted when item is added to order."""

    order_id: OrderId
    product_id: str
    quantity: int
    occurred_at: datetime = field(default_factory=datetime.utcnow)

    @property
    def event_name(self) -> str:
        return 'order.item_added'

# Event Publisher Protocol
class EventPublisher(Protocol):
    async def publish(self, events: list[DomainEvent]) -> None: ...
```

### Repository Pattern

```python
from typing import Protocol

# Repository interface (port) - collection-like API
class OrderRepository(Protocol):
    """Repository interface defined in domain layer."""

    async def find_by_id(self, order_id: OrderId) -> Order | None: ...
    async def find_by_customer(self, customer_id: str) -> list[Order]: ...
    async def save(self, order: Order) -> None: ...
    async def delete(self, order_id: OrderId) -> None: ...

# SQLAlchemy implementation (adapter)
class SQLAlchemyOrderRepository:
    """Repository implementation in infrastructure layer."""

    def __init__(
        self,
        session: AsyncSession,
        event_publisher: EventPublisher,
    ) -> None:
        self.session = session
        self.event_publisher = event_publisher

    async def find_by_id(self, order_id: OrderId) -> Order | None:
        stmt = select(OrderModel).where(OrderModel.id == order_id)
        result = await self.session.execute(stmt)
        row = result.scalar_one_or_none()
        return self._to_domain(row) if row else None

    async def save(self, order: Order) -> None:
        model = self._to_model(order)
        self.session.add(model)
        await self.session.flush()

        # Publish domain events after persistence
        events = order.pull_events()
        if events:
            await self.event_publisher.publish(events)

    def _to_domain(self, model: OrderModel) -> Order:
        """Map database model to domain entity."""
        return Order(
            id=OrderId(model.id),
            customer_id=model.customer_id,
            status=OrderStatus(model.status),
            items=[self._item_to_domain(item) for item in model.items],
        )

    def _to_model(self, order: Order) -> OrderModel:
        """Map domain entity to database model."""
        return OrderModel(
            id=order.id,
            customer_id=order.customer_id,
            status=order.status.value,
            items=[self._item_to_model(item) for item in order.items],
        )
```

### Domain Service

```python
class PricingService:
    """Domain Service - lógica de negócio que não pertence a entidades."""

    def __init__(
        self,
        discount_repo: DiscountRepository,
        tax_calculator: TaxCalculator,
    ) -> None:
        self.discount_repo = discount_repo
        self.tax_calculator = tax_calculator

    async def calculate_order_total(
        self,
        items: list[OrderItem],
        customer_id: str,
    ) -> Money:
        """Cross-aggregate operation."""
        subtotal = self._calculate_subtotal(items)

        # Apply customer discount
        discount = await self.discount_repo.find_for_customer(customer_id)
        if discount:
            subtotal = subtotal.subtract(discount.amount)

        # Add tax
        tax = await self.tax_calculator.calculate(subtotal)

        return subtotal.add(tax)

    def _calculate_subtotal(self, items: list[OrderItem]) -> Money:
        if not items:
            return Money.zero()
        return sum(
            (item.total for item in items[1:]),
            start=items[0].total,
        )
```

### Domain Errors

```python
class DomainError(Exception):
    """Base class for domain errors."""

    def __init__(self, message: str, code: str = 'DOMAIN_ERROR') -> None:
        self.message = message
        self.code = code
        super().__init__(message)

class OrderNotFoundError(DomainError):
    def __init__(self, order_id: str) -> None:
        super().__init__(f'Order {order_id} not found', 'ORDER_NOT_FOUND')

class InvalidOrderStateError(DomainError):
    def __init__(self, current_state: str, action: str) -> None:
        super().__init__(
            f'Cannot {action} order in {current_state} state',
            'INVALID_ORDER_STATE',
        )
```

### DDD Directory Structure

```
/src
  /domain                      # Core domain (no external dependencies)
    /order
      __init__.py
      order.py                 # Aggregate root + child entities
      order_status.py          # Value object / enum
      order_events.py          # Domain events
      order_repository.py      # Repository Protocol (port)
    /shared
      __init__.py
      money.py                 # Shared value object
      domain_error.py          # Domain errors
      domain_event.py          # Event Protocol
  /application                 # Use cases / Application services
    /order
      __init__.py
      create_order.py          # Command handler
      get_order.py             # Query handler
  /infrastructure              # Adapters
    /persistence
      __init__.py
      sqlalchemy_order_repository.py
      models.py                # SQLAlchemy models
    /messaging
      __init__.py
      rabbitmq_event_publisher.py
  /api                         # HTTP handlers (FastAPI)
    /order
      __init__.py
      routes.py
      schemas.py               # Pydantic request/response schemas
  /config
    __init__.py
    settings.py
/tests
  /unit
    /domain
  /integration
  conftest.py
```

---

## Directory Structure (Simple)

Para projetos sem DDD:

```
/src
  /domain              # Business entities
    __init__.py
    user.py
    errors.py
  /services            # Business logic
    __init__.py
    user_service.py
  /repositories        # Data access
    __init__.py
    user_repository.py
    /implementations
      postgres_user_repository.py
  /api                 # FastAPI routes
    __init__.py
    routes.py
    dependencies.py
  /lib                 # Utilities
    __init__.py
    db.py
    logger.py
  /config              # Settings
    __init__.py
    settings.py
/tests
  /unit
  /integration
  conftest.py
```

---

## Checklist

Before submitting Python code, verify:

### Type Safety
- [ ] Type hints on all functions and methods
- [ ] Mypy strict mode passes
- [ ] NewType for domain IDs (UserId, OrderId, etc.)

### Data & Validation
- [ ] Pydantic for all external input validation
- [ ] Decimal for financial calculations (never float)
- [ ] frozen=True dataclasses for Value Objects

### Async & Resources
- [ ] Async for all I/O operations
- [ ] Context managers for resource cleanup
- [ ] Protocol for interfaces (not ABC unless needed)

### Quality
- [ ] Ruff format and lint pass
- [ ] pytest tests with proper fixtures

### DDD (if enabled)
- [ ] Entities use identity comparison (`__eq__` by ID)
- [ ] Value Objects are immutable (`frozen=True`)
- [ ] Aggregates enforce invariants before state changes
- [ ] Domain Events emitted for significant state changes
- [ ] Repository Protocols defined in domain layer
- [ ] No infrastructure dependencies in domain layer
