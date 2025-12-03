# Development Cycle Design

**Data**: 2024-12-03
**Status**: Aprovado
**Plugin**: ring-dev-team

## Resumo

Sistema de ciclo de desenvolvimento completo que orquestra a execução de tasks através de 8 gates especializados, utilizando os agents do dev-team e coletando métricas para feedback loop contínuo.

## Objetivos

1. Importar tasks de arquivo Markdown com requisitos funcionais e técnicos
2. Executar cada task individualmente através de gates especializados
3. Utilizar agents do dev-team conforme especialização necessária
4. Coletar métricas de assertividade por task
5. Gerar feedback para melhoria contínua de agents/skills

## Arquitetura

### Abordagem: Modular com Orquestrador

```
dev-team/
├── skills/
│   ├── development-cycle/SKILL.md      # Orquestrador principal
│   ├── dev-import-tasks/SKILL.md       # Gate 0: Import
│   ├── dev-analysis/SKILL.md           # Gate 1: Análise
│   ├── dev-design/SKILL.md             # Gate 2: Design
│   ├── dev-implementation/SKILL.md     # Gate 3: Código
│   ├── dev-devops-setup/SKILL.md       # Gate 4: DevOps
│   ├── dev-testing/SKILL.md            # Gate 5: Testes
│   ├── dev-review/SKILL.md             # Gate 6: Review
│   ├── dev-validation/SKILL.md         # Gate 7: Validação
│   └── dev-feedback-loop/SKILL.md      # Sistema de Métricas
├── commands/
│   ├── dev-cycle.md                    # /ring-dev-team:dev-cycle
│   ├── dev-status.md                   # /ring-dev-team:dev-status
│   ├── dev-cancel.md                   # /ring-dev-team:dev-cancel
│   └── dev-report.md                   # /ring-dev-team:dev-report
├── templates/
│   ├── task-input.md                   # Formato de tasks
│   └── STANDARDS.md                    # Padrões do projeto
└── state/
    └── .gitignore                      # Ignora arquivos de estado
```

### Fluxo de Execução

```
┌─────────────────────────────────────────────────────────────────────┐
│                    DEVELOPMENT-CYCLE (Orquestrador)                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  📥 Gate 0: IMPORT ──→ Tasks parseadas                              │
│       │                                                              │
│       ▼                                                              │
│  🔍 Gate 1: ANALYSIS ──→ Contexto + Agent recomendado               │
│       │                    (codebase-explorer)                       │
│       ▼                                                              │
│  📐 Gate 2: DESIGN ──→ Plano técnico                                │
│       │                 (write-plan) + lê PRD/TRD                    │
│       ▼                                                              │
│  💻 Gate 3: IMPLEMENTATION ──→ Código                               │
│       │                         (backend-*/frontend-*)               │
│       ▼                                                              │
│  🐳 Gate 4: DEVOPS SETUP ──→ Docker, compose                        │
│       │                       (devops-engineer)                      │
│       ▼                                                              │
│  🧪 Gate 5: TESTING ──→ Testes + Cobertura                          │
│       │                  (qa-analyst)                                │
│       ▼                                                              │
│  👁️ Gate 6: REVIEW ──→ VERDICT                                      │
│       │                 (3 reviewers paralelos)                      │
│       │                                                              │
│       ├── FAIL ──→ Volta para Gate 3 com findings                   │
│       │                                                              │
│       ▼ PASS                                                         │
│  ✅ Gate 7: VALIDATION ──→ Aprovação manual                         │
│       │                                                              │
│       ├── REJECTED ──→ Documenta motivo                             │
│       │                                                              │
│       ▼ APPROVED                                                     │
│  📊 FEEDBACK LOOP ──→ Métricas + Relatório                          │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Especificação das Skills

### Gate 0: dev-import-tasks

**Responsabilidades:**
- Ler arquivo markdown com tasks
- Parsear estrutura padronizada
- Extrair requisitos funcionais e técnicos
- Validar informações mínimas
- Gerar lista estruturada para processamento

**Input:** Path para arquivo markdown ou conteúdo inline

**Output:** Lista de tasks parseadas com ID, título, requisitos, critérios de aceitação

**Validação:**
- ERRO: Task sem título ou critérios de aceitação
- WARNING: Task sem requisitos técnicos (será inferido)

---

### Gate 1: dev-analysis

**Responsabilidades:**
- Analisar codebase para entender contexto
- Identificar arquivos afetados
- Carregar configuração do projeto (docs/STANDARDS.md)
- Detectar padrões existentes
- Recomendar agent apropriado
- Documentar riscos

**Input:** Task parseada (Gate 0)

**Output:** Relatório com arquivos afetados, agent recomendado, project config, complexidade

**Agents utilizados:** `ring-default:codebase-explorer`

---

### Gate 2: dev-design

**Responsabilidades:**
- Criar plano técnico detalhado
- Ler PRD/TRD se existirem
- Definir arquitetura da solução
- Especificar interfaces e tipos
- Criar checklist de implementação

**Input:** Task (Gate 0), Análise (Gate 1), PRD/TRD (se existirem)

**Output:** Documento de design técnico

**Agents utilizados:** `ring-default:write-plan`

---

### Gate 3: dev-implementation

**Responsabilidades:**
- Executar implementação do código
- Seguir design técnico
- Usar agent especializado
- Documentar decisões

**Input:** Task, Análise, Design

**Output:** Código implementado, lista de arquivos

**Agents utilizados (seleção automática):**
- `ring-dev-team:backend-engineer-golang`
- `ring-dev-team:backend-engineer-typescript`
- `ring-dev-team:backend-engineer-python`
- `ring-dev-team:backend-engineer`
- `ring-dev-team:frontend-engineer-typescript`
- `ring-dev-team:frontend-engineer`
- `ring-dev-team:frontend-designer`

---

### Gate 4: dev-devops-setup

**Responsabilidades:**
- Criar/atualizar Dockerfile
- Criar/atualizar docker-compose.yml
- Configurar variáveis de ambiente
- Documentar setup local

**Input:** Task, Código implementado

**Output:** Dockerfile, docker-compose.yml, .env.example

**Agents utilizados:** `ring-dev-team:devops-engineer`

---

### Gate 5: dev-testing

**Responsabilidades:**
- Garantir cobertura de testes
- Criar testes unitários, integração, E2E
- Executar suite completa
- Seguir TDD

**Input:** Task com critérios, Código, Design

**Output:** Testes, relatório de cobertura, resultado

**Agents utilizados:** `ring-dev-team:qa-analyst`

**Skills relacionadas:** `ring-default:test-driven-development`

---

### Gate 6: dev-review

**Responsabilidades:**
- Executar code review com 3 reviewers paralelos
- Coletar findings
- Determinar VERDICT

**Input:** Código, Testes, Task

**Output:** Relatório consolidado com VERDICT (PASS/FAIL/NEEDS_DISCUSSION)

**Agents utilizados (PARALELO):**
- `ring-default:code-reviewer`
- `ring-default:business-logic-reviewer`
- `ring-default:security-reviewer`

---

### Gate 7: dev-validation

**Responsabilidades:**
- Validar critérios de aceitação
- Checklist manual com usuário
- Coletar aprovação final

**Input:** Task, Código final, Testes, Review

**Output:** Checklist preenchido, aprovação (APPROVED/REJECTED)

---

### dev-feedback-loop

**Responsabilidades:**
- Calcular assertividade por task
- Agregar métricas do ciclo
- Documentar falhas
- Identificar padrões
- Sugerir melhorias

**Cálculo de Assertividade:**
```
base_score = 100
- Penalidade por iterações extras: max 30 pontos
- Penalidade por review FAIL: 20 pontos
- Penalidade por NEEDS_DISCUSSION: 10 pontos
- Penalidade por critérios não atendidos: proporcional (max 40)
- Validação rejeitada = 0%

Meta: ≥85% média
```

## Coleta de Métricas

### Divisão de Responsabilidades

| Métrica | Quem Mede | Como |
|---------|-----------|------|
| Duration | Orquestrador | Timestamp antes/depois |
| Iterations | Skill | Conta loops internos |
| Result | Skill | Determina PASS/FAIL |
| Details | Skill | Dados específicos |
| Aggregation | Orquestrador | Soma/média ao final |
| Assertiveness | Feedback Loop | Fórmula |

### Contrato de Output das Skills

```markdown
## Execution Report

| Metric | Value |
|--------|-------|
| Duration | Xm Ys |
| Iterations | N |
| Result | PASS/FAIL/PARTIAL |

### Details
- key: value

### Issues Encountered
- Lista ou "Nenhum"

### Handoff to Next Gate
- Informações para próximo gate
```

## Templates

### task-input.md (formato de entrada)

```markdown
## Task: ID - Título

### Requisitos Funcionais
- Requisito 1
- Requisito 2

### Requisitos Técnicos
- Especificação técnica 1
- Especificação técnica 2

### Critérios de Aceitação
- [ ] Critério 1
- [ ] Critério 2

### Referências
- PRD: path/to/prd.md
- TRD: path/to/trd.md

### Prioridade
Alta/Média/Baixa

### Estimativa
S/M/L/XL
```

### docs/STANDARDS.md (padrões do projeto)

Define: Stack, Architecture, Required Libraries, Code Conventions, Forbidden Practices, Directory Structure.

## Slash Commands

| Comando | Descrição |
|---------|-----------|
| `/ring-dev-team:dev-cycle [file]` | Executar ciclo de desenvolvimento |
| `/ring-dev-team:dev-status` | Ver status do ciclo atual |
| `/ring-dev-team:dev-cancel` | Cancelar ciclo em execução |
| `/ring-dev-team:dev-report` | Ver relatório de feedback |

## Integração com PM-Team

O Gate 2 (dev-design) lê PRD/TRD se existirem:

```
PM-Team Workflow           Dev-Team Workflow
─────────────────          ─────────────────
/pre-dev-feature
    │
    ▼
PRD.md ───────────────────────┐
    │                          │
    ▼                          │
TRD.md ───────────────────────┼──→ Gate 2: DESIGN
    │                          │
    ▼                          │
tasks.md ─────────────────────┴──→ Gate 0: IMPORT
```

## Próximos Passos

1. [x] Design documentado
2. [ ] Criar estrutura de diretórios
3. [ ] Implementar skills
4. [ ] Criar templates
5. [ ] Criar slash commands
6. [ ] Testar ciclo completo
