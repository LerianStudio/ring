---
allowed-tools: Read(*), Glob(*), Grep(*), Bash(*), Write(*)
description: Generate architecture, flow, and relationship diagrams using ASCII art and mermaid syntax
argument-hint: [--type=architecture|flow|sequence|class|entity] [--scope=<path>]
---

# /ring-dev-team:analysis:diagram

## Instructions

Generate architecture, flow, and relationship diagrams from code structure and documentation using ASCII art and mermaid syntax.

## Usage

```bash
/ring-dev-team:analysis:diagram [--type=architecture|flow|sequence|class|entity] [--scope=<path>]
```

**Arguments:**

- `--type`: Type of diagram to generate (optional, defaults to architecture)
- `--scope`: File path or directory to analyze (optional, defaults to current directory)

## Process

Follow this systematic approach to diagram generation:

1. **Code Analysis Phase**
   - Analyze project structure using file discovery
   - Identify main modules, packages, and entry points
   - Map relationships between components
   - Locate APIs and endpoints

2. **Diagram Generation Phase**
   - Choose appropriate diagram type based on analysis
   - Generate ASCII or Mermaid syntax diagrams
   - Include interactive elements where applicable
   - Create comprehensive documentation

3. **Output Organization Phase**
   - Save diagrams to structured directory paths
   - Include supporting documentation
   - Provide usage examples and explanations
## Diagram Generation Process

### 1. Code Analysis

```bash
# Analyze project structure
fd "main|index|app" --type f
rg "class|interface|type" --type ts --type js

# Find relationships
rg "import|require|use|extends|implements" -A 1 -B 1
rg "new|create|getInstance" -A 2

# Identify APIs and endpoints
rg "@(Get|Post|Put|Delete)|router\.|app\." -A 2
```

### 2. Diagram Types

#### Architecture Diagram (ASCII)

```
┌─────────────────────────────────────────────────────────────┐
│                      Frontend (React/Fresh)                  │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────────┐   │
│  │   Browser   │  │   Mobile App │  │   CLI Client    │   │
│  └──────┬──────┘  └──────┬───────┘  └────────┬────────┘   │
└─────────┼─────────────────┼──────────────────┼─────────────┘
          │                 │                  │
          └─────────────────┴──────────────────┘
                            │
                  ┌─────────▼─────────┐
                  │   Load Balancer   │
                  │    (HAProxy)      │
                  └─────────┬─────────┘
                            │
        ┌───────────────────┴───────────────────┐
        │                                       │
┌───────▼────────┐                    ┌────────▼────────┐
│   API Gateway  │                    │  Static Assets  │
│  (Kong/Envoy)  │                    │     (CDN)       │
└───────┬────────┘                    └─────────────────┘
        │
┌───────┴────────────────────────────────────┐
│              Microservices                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐ │
│  │   Auth   │  │  Orders  │  │ Payments │ │
│  │ Service  │  │ Service  │  │ Service  │ │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘ │
└───────┼─────────────┼─────────────┼───────┘
        │             │             │
        └─────────────┴─────────────┘
                      │
         ┌────────────┴────────────┐
         │                         │
┌────────▼────────┐      ┌─────────▼────────┐
│    PostgreSQL   │      │   Message Queue  │
│   (Primary DB)  │      │    (RabbitMQ)    │
└─────────────────┘      └──────────────────┘
```

#### Flow Diagram (Mermaid)

```mermaid
flowchart TD
    A[User Request] --> B{Authenticated?}
    B -->|No| C[Login Page]
    B -->|Yes| D[Load Dashboard]

    C --> E[Enter Credentials]
    E --> F{Valid?}
    F -->|No| C
    F -->|Yes| G[Generate Token]
    G --> D

    D --> H[Fetch User Data]
    H --> I[Render Dashboard]
    I --> J{User Action}

    J -->|View Reports| K[Load Reports]
    J -->|Edit Profile| L[Profile Form]
    J -->|Logout| M[Clear Authentication]

    K --> N[Query Database]
    N --> O[Format Data]
    O --> P[Display Charts]
```

#### Sequence Diagram

```mermaid
sequenceDiagram
    participant C as Client
    participant G as Gateway
    participant A as Auth Service
    participant D as Database
    participant Q as Queue

    C->>G: POST /api/login
    G->>A: Validate credentials
    A->>D: Check user exists
    D-->>A: User data

    alt Valid credentials
        A->>A: Generate JWT
        A-->>G: Token + User info
        G-->>C: 200 OK + Token
    else Invalid credentials
        A-->>G: 401 Unauthorized
        G-->>C: 401 Unauthorized
    end

    C->>G: GET /api/data (Token)
    G->>G: Validate token
    G->>Q: Log access event
    G-->>C: Return data
```

#### Class Diagram

```mermaid
classDiagram
    class User {
        +String id
        +String email
        +String name
        -String passwordHash
        +login()
        +logout()
        +updateProfile()
    }

    class Order {
        +String id
        +String userId
        +OrderStatus status
        +List~OrderItem~ items
        +calculateTotal()
        +submit()
        +cancel()
    }

    class OrderItem {
        +String productId
        +int quantity
        +Decimal price
        +getSubtotal()
    }

    class Product {
        +String id
        +String name
        +Decimal price
        +int stock
        +isAvailable()
        +updateStock()
    }

    User "1" --> "*" Order : places
    Order "1" --> "*" OrderItem : contains
    OrderItem "*" --> "1" Product : references
```

#### Entity Relationship Diagram

```
┌─────────────────┐         ┌─────────────────┐
│     users       │         │    orders       │
├─────────────────┤         ├─────────────────┤
│ id          PK  │────┐    │ id          PK  │
│ email       UQ  │    │    │ user_id     FK  │
│ name            │    └───>│ status          │
│ created_at      │         │ total           │
│ updated_at      │         │ created_at      │
└─────────────────┘         └────────┬────────┘
                                     │
                            ┌────────▼────────┐
                            │   order_items   │
                            ├─────────────────┤
                            │ id          PK  │
                            │ order_id    FK  │
                            │ product_id  FK  │
                            │ quantity        │
                            │ price           │
                            └────────┬────────┘
                                     │
                            ┌────────▼────────┐
                            │    products     │
                            ├─────────────────┤
                            │ id          PK  │
                            │ name            │
                            │ price           │
                            │ stock           │
                            │ category_id FK  │
                            └─────────────────┘
```

### 3. Component Diagram

```
┌───────────────────────────────────────────────────┐
│                  Frontend Layer                    │
│  ┌─────────────┐ ┌──────────────┐ ┌────────────┐ │
│  │   Header    │ │   Dashboard  │ │   Footer   │ │
│  │ Component   │ │  Component   │ │ Component  │ │
│  └──────┬──────┘ └──────┬───────┘ └─────┬──────┘ │
│         └────────────────┴───────────────┘        │
│                          │                         │
│                   ┌──────▼──────┐                 │
│                   │  App State  │                 │
│                   │  (Redux)    │                 │
│                   └──────┬──────┘                 │
└──────────────────────────┼────────────────────────┘
                           │
                    ┌──────▼──────┐
                    │  API Client │
                    │   (Axios)   │
                    └──────┬──────┘
                           │
┌──────────────────────────┼────────────────────────┐
│                   Backend Layer                    │
│                   ┌──────▼──────┐                 │
│                   │  REST API   │                 │
│                   │  Controller │                 │
│                   └──────┬──────┘                 │
│         ┌────────────────┼────────────────┐       │
│         │                │                │       │
│  ┌──────▼──────┐ ┌──────▼──────┐ ┌──────▼──────┐│
│  │   Service   │ │   Service   │ │   Service   ││
│  │    Layer    │ │    Layer    │ │    Layer    ││
│  └──────┬──────┘ └──────┬──────┘ └──────┬──────┘│
│         └────────────────┼────────────────┘       │
│                   ┌──────▼──────┐                 │
│                   │ Data Access │                 │
│                   │    Layer    │                 │
│                   └──────┬──────┘                 │
└──────────────────────────┼────────────────────────┘
                           │
                    ┌──────▼──────┐
                    │  Database   │
                    │ (PostgreSQL)│
                    └─────────────┘
```

### 4. Auto-Generation Script

```typescript
// generate-diagram.ts
import { walk } from '@std/fs/walk.ts'

async function generateArchitectureDiagram(rootPath: string) {
  const components: Map<string, string[]> = new Map()

  // Scan for components
  for await (const entry of walk(rootPath)) {
    if (entry.isFile && entry.name.endsWith('.ts')) {
      const content = await Deno.readTextFile(entry.path)

      // Extract imports
      const imports = content.match(/import.*from\s+['"](.+)['"]/g)
      if (imports) {
        components.set(entry.path, imports)
      }
    }
  }

  // Generate mermaid diagram
  let diagram = 'graph TD\n'

  components.forEach((imports, file) => {
    const fileName = file.split('/').pop()?.replace('.ts', '')
    imports.forEach((imp) => {
      const dep = imp.match(/['"](.+)['"]/)?.[1]
      if (dep && !dep.startsWith('@') && !dep.startsWith('.')) {
        diagram += `  ${fileName} --> ${dep}\n`
      }
    })
  })

  return diagram
}
```

### 5. Interactive Diagrams

```html
<!-- For web output -->
<script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>
<script>
  mermaid.initialize({ startOnLoad: true })
</script>

<div class="mermaid">${generatedDiagram}</div>
```
## Output Format

**Save all diagrams to:** `docs/ring-dev-team:analysis:diagrams/[type]/[diagram-name].md`

Examples:

- Architecture diagram → `docs/ring-dev-team:analysis:diagrams/architecture/system-overview.md`
- Flow diagram → `docs/ring-dev-team:analysis:diagrams/flow/user-authentication.md`
- Sequence diagram → `docs/ring-dev-team:analysis:diagrams/sequence/order-processing.md`
- Class diagram → `docs/ring-dev-team:analysis:diagrams/class/user-management.md`
- Entity diagram → `docs/ring-dev-team:analysis:diagrams/entity/database-schema.md`

```markdown
# ${DiagramType} Diagram: ${DiagramName}

## Overview

[Brief description of what the diagram shows]

## Diagram

[ASCII or Mermaid diagram]

## Key Components

- **Component A**: Description
- **Component B**: Description
- **Component C**: Description

## Relationships

- A → B: Data flow for X
- B → C: Triggers Y process
- C → A: Returns Z result

## Notes

- [Important architectural decisions]
- [Scalability considerations]
- [Security boundaries]
```
## Diagram Best Practices

1. **Keep it simple** - Focus on key components
2. **Use consistent symbols** - Stick to standard notations
3. **Label clearly** - Add descriptive labels
4. **Show data flow** - Indicate direction with arrows
5. **Group related items** - Use boxes/boundaries
6. **Include legend** - Explain symbols if needed

## Guidelines

- Start with high-level overview
- Add detail progressively
- Use colors sparingly (ASCII compatible)
- Maintain aspect ratio for readability
- Export in multiple formats if needed
- Keep source files for updates
