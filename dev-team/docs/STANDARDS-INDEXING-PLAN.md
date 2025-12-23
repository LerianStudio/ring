# Standards Indexing Plan

**Objetivo:** Remover padrões inline dos agents e substituir por referências OBRIGATÓRIAS aos standards files.

**Data:** 2025-12-23
**Status:** Em progresso

---

## Auditoria: Padrões Inline nos Agents

### 1. backend-engineer-golang.md (57 seções, 22 code blocks)

**Padrões INLINE que devem ser REFERÊNCIA:**

| Seção Inline | Linhas | Deve ir para | Ação |
|--------------|--------|--------------|------|
| FORBIDDEN Patterns Acknowledged | 289-327 | golang.md | MOVER - lista de patterns está inline |
| Bootstrap Pattern Acknowledged | 349-395 | golang.md | MOVER - estrutura de diretórios está inline |
| Application Type Detection | 397-423 | golang.md | MOVER - tabela de tipos está inline |
| Code Instrumentation | 517-546 | golang.md | MOVER - padrões de instrumentação inline |

**Seções que devem ser REFERÊNCIA (não inline):**
- [ ] FORBIDDEN Patterns → Ref: golang.md#forbidden-logging-patterns
- [ ] Bootstrap Pattern → Ref: golang.md#bootstrap-pattern
- [ ] Application Type → Ref: golang.md#application-types
- [ ] Code Instrumentation → Ref: golang.md#telemetry-observability

---

### 2. backend-engineer-typescript.md (61 seções, 26 code blocks)

**Padrões INLINE que devem ser REFERÊNCIA:**

| Seção Inline | Linhas | Deve ir para | Ação |
|--------------|--------|--------------|------|
| FORBIDDEN Patterns Acknowledged | 372-397 | typescript.md | MOVER |
| Bootstrap Pattern Acknowledged | 417-488 | typescript.md | MOVER - estrutura inline |
| Application Type Detection | 490-516 | typescript.md | MOVER |

**Seções que devem ser REFERÊNCIA:**
- [ ] FORBIDDEN Patterns → Ref: typescript.md#forbidden-patterns
- [ ] Bootstrap Pattern → Ref: typescript.md#bootstrap-pattern
- [ ] Application Type → Ref: typescript.md#application-types

---

### 3. frontend-bff-engineer-typescript.md (56 seções, 22 code blocks)

**Padrões INLINE que devem ser REFERÊNCIA:**

| Seção Inline | Linhas | Deve ir para | Ação |
|--------------|--------|--------------|------|
| FORBIDDEN Patterns Acknowledged | 271-298 | typescript.md | MOVER |
| Architecture Patterns | 300-363 | typescript.md | MOVER - Clean Architecture inline |
| Naming Conventions | 691-703 | typescript.md | MOVER |

**Seções que devem ser REFERÊNCIA:**
- [ ] FORBIDDEN Patterns → Ref: typescript.md#forbidden-patterns
- [ ] Architecture → Ref: typescript.md#architecture-patterns
- [ ] Naming → Ref: typescript.md#naming-conventions

---

### 4. frontend-engineer.md (87 seções, 10 code blocks)

**Padrões INLINE que devem ser REFERÊNCIA:**

| Seção Inline | Linhas | Deve ir para | Ação |
|--------------|--------|--------------|------|
| FORBIDDEN Patterns Acknowledged | 203-230 | frontend.md | MOVER |
| Next.js App Router | 291-335 | frontend.md | MOVER - Knowledge inline |
| React 18+ Concurrent | 337-356 | frontend.md | MOVER |
| Accessibility WCAG | 358-410 | frontend.md | MOVER |
| Performance Optimization | 412-449 | frontend.md | MOVER |
| Frontend Security | 451-487 | frontend.md | MOVER |
| Error Handling | 489-518 | frontend.md | MOVER |
| SEO and Metadata | 520-550 | frontend.md | MOVER |
| Design System Integration | 552-571 | frontend.md | MOVER |
| Testing Patterns | 620-657 | frontend.md | MOVER |
| Architecture Patterns | 659-686 | frontend.md | MOVER |

**Seções que devem ser REFERÊNCIA:**
- [ ] Todos os "(Knowledge)" sections → Ref: frontend.md#{section}

---

### 5. frontend-designer.md (112 seções, 8 code blocks)

**Padrões INLINE que devem ser REFERÊNCIA:**

| Seção Inline | Linhas | Deve ir para | Ação |
|--------------|--------|--------------|------|
| FORBIDDEN Patterns Acknowledged | 890-917 | frontend.md | MOVER |
| UX Research Integration | 405-430 | frontend.md | MOVER |
| Information Architecture | 432-452 | frontend.md | MOVER |
| Content Design | 454-485 | frontend.md | MOVER |
| Accessibility | 487-542 | frontend.md | MOVER |
| Mobile & Touch Design | 544-579 | frontend.md | MOVER |
| Internationalization | 581-614 | frontend.md | MOVER |
| Data Visualization | 616-643 | frontend.md | MOVER |
| Prototyping | 645-677 | frontend.md | MOVER |
| Design Tools Integration | 748-767 | frontend.md | MOVER |
| Handoff to Frontend | 769-810 | frontend.md | MOVER |
| Dark Mode Decision Framework | 973-998 | frontend.md | MOVER |

**Seções que devem ser REFERÊNCIA:**
- [ ] Todos os "(Knowledge)" sections → Ref: frontend.md#{section}

---

### 6. devops-engineer.md (38 seções, 14 code blocks)

**Padrões INLINE que devem ser REFERÊNCIA:**

| Seção Inline | Linhas | Deve ir para | Ação |
|--------------|--------|--------------|------|
| FORBIDDEN Patterns Acknowledged | 265-292 | devops.md | MOVER |
| Security Checklist | 412-430 | devops.md | MOVER |

**Seções que devem ser REFERÊNCIA:**
- [ ] FORBIDDEN Patterns → Ref: devops.md#forbidden-patterns
- [ ] Security Checklist → Ref: devops.md#security

---

### 7. sre.md (44 seções, 16 code blocks)

**Padrões INLINE que devem ser REFERÊNCIA:**

| Seção Inline | Linhas | Deve ir para | Ação |
|--------------|--------|--------------|------|
| FORBIDDEN Logging Patterns | 118-127 | sre.md (standards) | MOVER |
| FORBIDDEN Patterns Acknowledged | 129-191 | sre.md (standards) | MOVER |

**Seções que devem ser REFERÊNCIA:**
- [ ] FORBIDDEN Patterns → Ref: sre.md#forbidden-patterns
- [ ] Já usa referências para golang.md e sre.md (standards)

---

### 8. qa-analyst.md (98 seções, 36 code blocks)

**Padrões INLINE que devem ser REFERÊNCIA:**

| Seção Inline | Linhas | Deve ir para | Ação |
|--------------|--------|--------------|------|
| FORBIDDEN Test Patterns Acknowledged | 423-450 | golang.md/typescript.md | MOVER |
| Test Quality Gate | 271-332 | shared-patterns/ | MOVER |
| Legacy Code Testing Strategy | 563-583 | shared-patterns/ | MOVER |
| Testing Standards | 704-828 | golang.md/typescript.md | MOVER - muito código inline |
| Coverage Threshold Validation | 830-843 | shared-patterns/ | MOVER |
| Coverage Calculation Rules | 845-867 | shared-patterns/ | MOVER |
| Quality Checks | 869-887 | shared-patterns/ | MOVER |
| Skipped Test Detection | 889-935 | shared-patterns/ | MOVER |
| TDD RED Phase Verification | 937-947 | shared-patterns/ | MOVER |
| Assertion-less Test Detection | 949-964 | shared-patterns/ | MOVER |

**Seções que devem ser REFERÊNCIA:**
- [ ] FORBIDDEN Test Patterns → Ref: {language}.md#testing-patterns
- [ ] Test Quality Gate → Ref: shared-patterns/test-quality-gate.md
- [ ] Coverage Rules → Ref: shared-patterns/coverage-rules.md

---

## Plano de Execução

### Step 1: Criar seções ausentes nos standards files

**golang.md - Adicionar/Verificar:**
- [ ] Application Types section
- [ ] FORBIDDEN Logging Patterns section (já existe?)

**typescript.md - Adicionar/Verificar:**
- [ ] Bootstrap Pattern section
- [ ] Application Types section
- [ ] FORBIDDEN Patterns section

**frontend.md - Adicionar/Verificar:**
- [ ] Next.js App Router section
- [ ] React 18+ Concurrent section
- [ ] Accessibility WCAG section
- [ ] Performance Optimization section
- [ ] Frontend Security section
- [ ] Error Handling section
- [ ] SEO and Metadata section
- [ ] Design System Integration section
- [ ] Testing Patterns section
- [ ] Architecture Patterns section
- [ ] UX Research section
- [ ] Information Architecture section
- [ ] Content Design section
- [ ] Mobile & Touch Design section
- [ ] Internationalization section
- [ ] Data Visualization section
- [ ] Prototyping section
- [ ] Design Tools section
- [ ] Handoff Patterns section
- [ ] Dark Mode Framework section

**devops.md - Adicionar/Verificar:**
- [ ] FORBIDDEN Patterns section

**shared-patterns/ - Criar:**
- [ ] test-quality-gate.md
- [ ] coverage-rules.md

---

### Step 2: Atualizar standards-coverage-table.md

Adicionar índice completo para cada agent com TODAS as seções que devem verificar.

---

### Step 3: Refatorar agents

Para cada agent:
1. Remover conteúdo inline (código, tabelas de padrões)
2. Substituir por referência OBRIGATÓRIA:
   ```markdown
   ## FORBIDDEN Patterns (MANDATORY - WebFetch REQUIRED)
   
   **⛔ HARD GATE: You MUST load and acknowledge patterns from standards.**
   
   **Reference:** `golang.md#forbidden-logging-patterns`
   
   See [shared-patterns/standards-workflow.md](../skills/shared-patterns/standards-workflow.md) for loading process.
   
   **Required Acknowledgment:** List ALL forbidden patterns from WebFetch result.
   If you cannot list them → STOP, WebFetch failed.
   ```

---

### Step 4: Template de Referência

**Formato padrão para seções que referenciam standards:**

```markdown
## {Section Name} (MANDATORY - WebFetch REQUIRED)

**⛔ HARD GATE: This section REQUIRES loading standards via WebFetch.**

**Standards Reference:**
| Standards File | Section | Anchor |
|----------------|---------|--------|
| {file}.md | {Section Name} | #{anchor} |

**WebFetch URL:** `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/{file}.md`

**MANDATORY:** You MUST:
1. WebFetch the standards file
2. Find the referenced section
3. Acknowledge key patterns from that section
4. Apply patterns during implementation

**If WebFetch fails → STOP and report blocker. Do NOT proceed with assumptions.**

See [shared-patterns/standards-workflow.md](../skills/shared-patterns/standards-workflow.md) for complete loading process.
```

---

## Standards Files - Seções Existentes

### golang.md (24 seções)
1. Version
2. Core Dependency: lib-commons (MANDATORY)
3. Frameworks & Libraries
4. Configuration Loading (MANDATORY)
5. Telemetry & Observability (MANDATORY)
6. Bootstrap Pattern (MANDATORY)
7. Access Manager Integration (MANDATORY)
8. License Manager Integration (MANDATORY)
9. Data Transformation: ToEntity/FromEntity (MANDATORY)
10. Error Codes Convention (MANDATORY)
11. Error Handling
12. Function Design (MANDATORY)
13. Pagination Patterns
14. Testing Patterns
15. Logging Standards
16. Linting
17. Architecture Patterns
18. Directory Structure
19. Concurrency Patterns
20. RabbitMQ Worker Pattern
21. Standards Compliance Output Format
22. Standards Compliance (2x)
23. Checklist

### typescript.md (14 seções)
1. Version
2. Strict Configuration (MANDATORY)
3. Frameworks & Libraries
4. Type Safety Rules
5. Zod Validation Patterns
6. Dependency Injection
7. AsyncLocalStorage for Context
8. Testing Patterns
9. Error Handling
10. Function Design (MANDATORY)
11. Naming Conventions
12. Directory Structure (Backend)
13. RabbitMQ Worker Pattern
14. Checklist

### frontend.md (14 seções)
1. Framework
2. Libraries & Tools
3. State Management Patterns
4. Form Patterns
5. Styling Standards
6. Typography Standards
7. Animation Standards
8. Component Patterns
9. Accessibility (a11y)
10. Performance
11. Directory Structure
12. FORBIDDEN Patterns
13. Standards Compliance Categories
14. Checklist

### devops.md (8 seções)
1. Cloud Provider
2. Infrastructure as Code
3. Containers
4. Helm
5. Observability
6. Security
7. Makefile Standards
8. Checklist

### sre.md (8 seções)
1. Observability Stack
2. Logging Standards
3. Tracing Standards
4. OpenTelemetry with lib-commons (MANDATORY for Go)
5. Structured Logging with lib-common-js (MANDATORY for TypeScript)
6. Health Checks
7. Checklist

---

## Mapeamento: Agent → Standards Sections

### backend-engineer-golang.md → golang.md

| Agent Section (Inline) | Standards Section | Anchor |
|------------------------|-------------------|--------|
| FORBIDDEN Patterns | Logging Standards | #logging-standards |
| Bootstrap Pattern | Bootstrap Pattern (MANDATORY) | #bootstrap-pattern-mandatory |
| Application Type | (CRIAR) Application Types | #application-types |
| Code Instrumentation | Telemetry & Observability (MANDATORY) | #telemetry-observability-mandatory |
| Architecture Patterns | Architecture Patterns | #architecture-patterns |
| Directory Structure | Directory Structure | #directory-structure |

### backend-engineer-typescript.md → typescript.md

| Agent Section (Inline) | Standards Section | Anchor |
|------------------------|-------------------|--------|
| FORBIDDEN Patterns | Type Safety Rules | #type-safety-rules |
| Bootstrap Pattern | (CRIAR) Bootstrap Pattern | #bootstrap-pattern |
| Application Type | (CRIAR) Application Types | #application-types |
| Architecture Patterns | (CRIAR) Architecture Patterns | #architecture-patterns |

### frontend-bff-engineer-typescript.md → typescript.md

| Agent Section (Inline) | Standards Section | Anchor |
|------------------------|-------------------|--------|
| FORBIDDEN Patterns | Type Safety Rules | #type-safety-rules |
| Architecture Patterns | (CRIAR) Architecture Patterns | #architecture-patterns |
| Naming Conventions | Naming Conventions | #naming-conventions |

### frontend-engineer.md → frontend.md

| Agent Section (Inline) | Standards Section | Anchor |
|------------------------|-------------------|--------|
| FORBIDDEN Patterns | FORBIDDEN Patterns | #forbidden-patterns |
| Next.js App Router | (CRIAR) Next.js App Router | #nextjs-app-router |
| React 18+ | (CRIAR) React 18+ Features | #react-18-features |
| Accessibility | Accessibility (a11y) | #accessibility-a11y |
| Performance | Performance | #performance |
| Testing Patterns | (CRIAR) Testing Patterns | #testing-patterns |
| Architecture | (CRIAR) Architecture Patterns | #architecture-patterns |

### frontend-designer.md → frontend.md

| Agent Section (Inline) | Standards Section | Anchor |
|------------------------|-------------------|--------|
| FORBIDDEN Patterns | FORBIDDEN Patterns | #forbidden-patterns |
| UX Research | (CRIAR) UX Research | #ux-research |
| Accessibility | Accessibility (a11y) | #accessibility-a11y |
| Dark Mode | (CRIAR) Dark Mode Framework | #dark-mode-framework |

### devops-engineer.md → devops.md

| Agent Section (Inline) | Standards Section | Anchor |
|------------------------|-------------------|--------|
| FORBIDDEN Patterns | (CRIAR) FORBIDDEN Patterns | #forbidden-patterns |
| Security Checklist | Security | #security |

### sre.md → sre.md (standards)

| Agent Section (Inline) | Standards Section | Anchor |
|------------------------|-------------------|--------|
| FORBIDDEN Logging Patterns | Logging Standards | #logging-standards |

### qa-analyst.md → golang.md/typescript.md + shared-patterns

| Agent Section (Inline) | Standards Section | Anchor |
|------------------------|-------------------|--------|
| FORBIDDEN Test Patterns | Testing Patterns | #{lang}#testing-patterns |
| Test Quality Gate | (CRIAR) shared-patterns/test-quality-gate.md | - |
| Coverage Rules | (CRIAR) shared-patterns/coverage-rules.md | - |

---

## Progresso

| Step | Status | Notas |
|------|--------|-------|
| Auditoria | ✅ Completo | 8 agents auditados |
| Criar plano | ✅ Completo | Este arquivo |
| Step 1: Standards | ⏳ Em progresso | golang.md já tem seções necessárias |
| Step 2: Coverage table | ⏳ Pendente | |
| Step 3: Refatorar agents | ✅ EXEMPLO: backend-engineer-golang.md | |
| Step 4: Verificar | ⏳ Pendente | |

---

## Exemplo Refatorado: backend-engineer-golang.md

### ANTES (Inline hardcoded):

```markdown
## FORBIDDEN Patterns Acknowledged

I have loaded golang.md standards. FORBIDDEN logging patterns:
- fmt.Println() ❌
- fmt.Printf() ❌
- log.Println() ❌
...hardcoded list continues...
```

### DEPOIS (Referência dinâmica):

```markdown
## FORBIDDEN Patterns Check (MANDATORY - BEFORE ANY CODE)

**Standards Reference (MANDATORY WebFetch):**

| Standards File | Sections to Load | Anchor |
|----------------|------------------|--------|
| golang.md | Logging Standards | #logging-standards |
| golang.md | Telemetry & Observability | #telemetry-observability-mandatory |

**Process:**
1. WebFetch `golang.md`
2. Find "Logging Standards" section → Extract FORBIDDEN patterns table
3. Find "Telemetry & Observability" section → Extract Anti-Patterns table
4. **LIST ALL patterns you found** (proves you read the standards)

**Required Output Format:**

## FORBIDDEN Patterns Acknowledged

I have loaded golang.md standards via WebFetch.

### From "Logging Standards" section:
[LIST all FORBIDDEN logging patterns found in the standards file]

### From "Telemetry & Observability" section:
[LIST all Anti-Patterns found in the standards file]

**⛔ CRITICAL: Do NOT hardcode patterns. Extract them from WebFetch result.**
```

---

## Padrão de Referência Aplicado

Todas as seções que referenciam standards agora seguem este padrão:

```markdown
## {Section Name} (MANDATORY)

**Standards Reference (MANDATORY WebFetch):**

| Standards File | Section to Load | Anchor |
|----------------|-----------------|--------|
| {file}.md | {Section Name} | #{anchor} |

**Process:**
1. WebFetch standards file
2. Find referenced section
3. Extract patterns/rules from that section
4. LIST what you found (proves you read)

**⛔ CRITICAL: Do NOT hardcode. Extract from WebFetch result.**
```

---

## Seções Refatoradas em backend-engineer-golang.md

| Seção | Antes | Depois |
|-------|-------|--------|
| FORBIDDEN Patterns | ~25 linhas de padrões hardcoded | Ref: golang.md#logging-standards + #telemetry-observability |
| Bootstrap Pattern | ~30 linhas de estrutura hardcoded | Ref: golang.md#bootstrap-pattern + #directory-structure |
| Application Type | Tabela inline | Ref: golang.md#rabbitmq-worker-pattern |
| Architecture Patterns | Descrição inline | Ref: golang.md#architecture-patterns + #directory-structure |

**Linhas removidas:** ~80 linhas de conteúdo duplicado
**Substituído por:** ~15 linhas de referências + instruções de WebFetch

---

## Resultado Esperado

**Antes:**
```markdown
## FORBIDDEN Patterns Acknowledged

I have loaded golang.md standards. FORBIDDEN logging patterns:
- fmt.Println() ❌
- fmt.Printf() ❌
- log.Println() ❌
...inline list continues...
```

**Depois:**
```markdown
## FORBIDDEN Patterns (MANDATORY - WebFetch REQUIRED)

**Standards Reference:** golang.md#forbidden-logging-patterns

**MANDATORY:** WebFetch standards and list ALL forbidden patterns found.
If cannot list → STOP, WebFetch failed.

See [standards-workflow.md](../skills/shared-patterns/standards-workflow.md) for loading process.
```

O agent então faz WebFetch e lista os padrões **dinamicamente** do standards file, não de uma lista hardcoded.
