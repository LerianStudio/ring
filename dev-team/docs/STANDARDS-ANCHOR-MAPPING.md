# Standards Anchor Mapping - Padronização

> **STATUS:** ✅ APPLIED - All standards files and agents updated to use standardized anchors.

## Objetivo

Padronizar os nomes das seções (anchors) nos standards files para que conceitos universais tenham o mesmo nome, independente da linguagem ou implementação.

---

## Mapeamento Atual → Proposto

### 1. Observability / Telemetry

| File | Anchor Atual | Anchor Proposto |
|------|--------------|-----------------|
| golang.md | `#telemetry--observability-mandatory` | `#observability` |
| sre.md | `#observability-stack` | `#observability` |
| devops.md | `#observability` | `#observability` ✓ |
| typescript.md | ❌ (não tem) | `#observability` (criar) |
| frontend.md | ❌ (não tem) | `#observability` (criar) |

### 2. Logging

| File | Anchor Atual | Anchor Proposto |
|------|--------------|-----------------|
| golang.md | `#logging-standards` | `#logging` |
| sre.md | `#logging-standards` | `#logging` |
| typescript.md | ❌ (não tem) | `#logging` (criar) |
| sre.md | `#structured-logging-with-lib-common-js-mandatory-for-typescript` | `#logging` (merge) |

### 3. Tracing

| File | Anchor Atual | Anchor Proposto |
|------|--------------|-----------------|
| sre.md | `#tracing-standards` | `#tracing` |
| golang.md | (dentro de telemetry) | `#tracing` (extrair) |
| typescript.md | ❌ (não tem) | `#tracing` (criar) |

### 4. Error Handling

| File | Anchor Atual | Anchor Proposto |
|------|--------------|-----------------|
| golang.md | `#error-handling` | `#error-handling` ✓ |
| typescript.md | `#error-handling` | `#error-handling` ✓ |

### 5. Testing

| File | Anchor Atual | Anchor Proposto |
|------|--------------|-----------------|
| golang.md | `#testing-patterns` | `#testing` |
| typescript.md | `#testing-patterns` | `#testing` |

### 6. Security

| File | Anchor Atual | Anchor Proposto |
|------|--------------|-----------------|
| devops.md | `#security` | `#security` ✓ |
| (outros) | ❌ | `#security` (criar onde aplicável) |

### 7. Accessibility

| File | Anchor Atual | Anchor Proposto |
|------|--------------|-----------------|
| frontend.md | `#accessibility-a11y` | `#accessibility` |

### 8. Performance

| File | Anchor Atual | Anchor Proposto |
|------|--------------|-----------------|
| frontend.md | `#performance` | `#performance` ✓ |

### 9. Directory Structure

| File | Anchor Atual | Anchor Proposto |
|------|--------------|-----------------|
| golang.md | `#directory-structure` | `#directory-structure` ✓ |
| typescript.md | `#directory-structure-backend` | `#directory-structure` |
| frontend.md | `#directory-structure` | `#directory-structure` ✓ |

### 10. Configuration

| File | Anchor Atual | Anchor Proposto |
|------|--------------|-----------------|
| golang.md | `#configuration-loading-mandatory` | `#configuration` |
| typescript.md | (dentro de Zod) | `#configuration` (extrair) |

### 11. Dependency Injection

| File | Anchor Atual | Anchor Proposto |
|------|--------------|-----------------|
| typescript.md | `#dependency-injection` | `#dependency-injection` ✓ |
| golang.md | (dentro de bootstrap) | `#dependency-injection` (extrair ou ref) |

### 12. Bootstrap / Initialization

| File | Anchor Atual | Anchor Proposto |
|------|--------------|-----------------|
| golang.md | `#bootstrap-pattern-mandatory` | `#bootstrap` |
| typescript.md | ❌ (não tem seção dedicada) | `#bootstrap` (criar) |

### 13. Type Safety

| File | Anchor Atual | Anchor Proposto |
|------|--------------|-----------------|
| typescript.md | `#type-safety-rules` | `#type-safety` |
| golang.md | (implícito na linguagem) | N/A |

### 14. Containers

| File | Anchor Atual | Anchor Proposto |
|------|--------------|-----------------|
| devops.md | `#containers` | `#containers` ✓ |

### 15. Health Checks

| File | Anchor Atual | Anchor Proposto |
|------|--------------|-----------------|
| sre.md | `#health-checks` | `#health-checks` ✓ |
| devops.md | (dentro de containers) | `#health-checks` (extrair) |

---

## Anchors Universais Padronizados (APPLIED ✅)

| # | Anchor | Conceito | Aplica a | Status |
|---|--------|----------|----------|--------|
| 1 | `#observability` | Telemetria, métricas, traces | golang, sre, devops | ✅ Applied |
| 2 | `#logging` | Structured logging, log levels | golang, sre | ✅ Applied |
| 3 | `#tracing` | Distributed tracing, spans | sre | ✅ Applied |
| 4 | `#error-handling` | Error types, handling patterns | golang, typescript | ✅ Already correct |
| 5 | `#testing` | Unit tests, integration tests | golang, typescript | ✅ Applied |
| 6 | `#security` | Auth, secrets, vulnerabilities | devops | ✅ Already correct |
| 7 | `#accessibility` | a11y, ARIA, keyboard nav | frontend | ✅ Applied |
| 8 | `#performance` | Optimization, lazy loading | frontend | ✅ Already correct |
| 9 | `#directory-structure` | Folder organization | golang, typescript, frontend | ✅ Applied |
| 10 | `#configuration` | Config loading, env vars | golang | ✅ Applied |
| 11 | `#dependency-injection` | DI patterns, IoC | typescript | ✅ Already correct |
| 12 | `#bootstrap` | App initialization order | golang | ✅ Applied |
| 13 | `#type-safety` | Type rules, strict mode | typescript | ✅ Applied |
| 14 | `#containers` | Docker, images | devops | ✅ Already correct |
| 15 | `#health-checks` | Liveness, readiness probes | sre | ✅ Already correct |
| 16 | `#forbidden-patterns` | Anti-patterns proibidos | frontend | ✅ Applied |

---

## Ações Necessárias

### Fase 1: Renomear seções existentes
- [ ] golang.md: `Telemetry & Observability` → `Observability`
- [ ] golang.md: `Logging Standards` → `Logging`
- [ ] golang.md: `Testing Patterns` → `Testing`
- [ ] golang.md: `Bootstrap Pattern` → `Bootstrap`
- [ ] golang.md: `Configuration Loading` → `Configuration`
- [ ] typescript.md: `Testing Patterns` → `Testing`
- [ ] typescript.md: `Type Safety Rules` → `Type Safety`
- [ ] typescript.md: `Directory Structure (Backend)` → `Directory Structure`
- [ ] sre.md: `Logging Standards` → `Logging`
- [ ] sre.md: `Tracing Standards` → `Tracing`
- [ ] frontend.md: `Accessibility (a11y)` → `Accessibility`

### Fase 2: Criar seções faltantes
- [ ] typescript.md: Criar `#observability` (referenciando sre.md para lib-common-js)
- [ ] typescript.md: Criar `#logging` (referenciando sre.md)
- [ ] typescript.md: Criar `#bootstrap` (ordem de inicialização)
- [ ] frontend.md: Criar `#observability` (métricas de performance, RUM)

### Fase 3: Atualizar agents
- [ ] Atualizar todas as referências nos agents para usar anchors padronizados
- [ ] Atualizar standards-coverage-table.md

---

## Benefícios

1. **Consistência**: Agent sabe que `#observability` existe em qualquer standards file
2. **Descoberta**: Fácil encontrar o que precisa, mesmo sem conhecer a linguagem
3. **Manutenção**: Adicionar nova linguagem = criar mesmas seções padronizadas
4. **Validação**: Pode automatizar verificação de que todas seções existem
