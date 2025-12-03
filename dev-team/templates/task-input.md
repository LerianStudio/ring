# Task Input Template

Este template define o formato padrão para arquivos de tasks que serão processados pelo ciclo de desenvolvimento (`/ring-dev-team:dev-cycle`).

---

## Formato do Arquivo

```markdown
---
source: manual | jira | imported
sprint: Sprint 2024-01
imported_at: 2024-01-15
---

## Task: PROJ-123 - Título da Task

### Requisitos Funcionais
- Requisito funcional 1
- Requisito funcional 2
- Requisito funcional 3

### Requisitos Técnicos
- Especificação técnica 1
- Especificação técnica 2

### Critérios de Aceitação
- [ ] Critério de aceitação 1
- [ ] Critério de aceitação 2
- [ ] Critério de aceitação 3

### Referências
- PRD: docs/pre-dev/feature/prd.md
- TRD: docs/pre-dev/feature/trd.md

### Prioridade
Alta | Média | Baixa

### Estimativa
S | M | L | XL

---

## Task: PROJ-124 - Segunda Task

...
```

---

## Campos

### Obrigatórios

| Campo | Descrição | Exemplo |
|-------|-----------|---------|
| `## Task: ID - Título` | Identificador único e nome descritivo | `## Task: PROJ-123 - Implementar autenticação OAuth2` |
| `### Requisitos Funcionais` | O que o usuário/sistema precisa fazer | Lista de requisitos de negócio |
| `### Critérios de Aceitação` | Como validar que a task está completa | Lista de checklist items |

### Opcionais (mas recomendados)

| Campo | Descrição | Comportamento se ausente |
|-------|-----------|-------------------------|
| `### Requisitos Técnicos` | Especificações técnicas | Inferido do contexto e STANDARDS.md |
| `### Referências` | Links para PRD/TRD | Skill dev-design gera mini-TRD |
| `### Prioridade` | Ordem de execução | Processado na ordem do arquivo |
| `### Estimativa` | Tamanho da task | Estimado no Gate 1 (analysis) |

---

## Exemplo Completo

```markdown
---
source: manual
sprint: Sprint 2024-Q1-W2
---

## Task: AUTH-001 - Implementar login com Google OAuth2

### Requisitos Funcionais
- Usuário deve poder iniciar login clicando em "Entrar com Google"
- Sistema deve redirecionar para tela de consentimento do Google
- Após autorização, usuário deve ser redirecionado de volta e logado
- Sessão deve ser criada com token JWT
- Usuário deve ver seu nome e foto do Google na navbar

### Requisitos Técnicos
- Usar biblioteca: golang.org/x/oauth2
- Tokens armazenados em Redis (cache) + PostgreSQL (persistência)
- JWT com expiração de 24h
- Refresh token rotation habilitado
- Scopes necessários: email, profile, openid

### Critérios de Aceitação
- [ ] Botão "Entrar com Google" visível na página de login
- [ ] Clique redireciona para Google OAuth consent screen
- [ ] Após autorização, usuário é redirecionado e logado automaticamente
- [ ] Token JWT é gerado e armazenado em cookie httpOnly
- [ ] Nome e foto do usuário aparecem na navbar
- [ ] Logout limpa sessão e tokens
- [ ] Rate limiting de 10 tentativas/minuto por IP funciona

### Referências
- PRD: docs/pre-dev/auth/prd.md
- TRD: docs/pre-dev/auth/trd.md
- Google OAuth Docs: https://developers.google.com/identity/protocols/oauth2

### Prioridade
Alta

### Estimativa
M

---

## Task: AUTH-002 - Implementar login com GitHub OAuth2

### Requisitos Funcionais
- Usuário deve poder iniciar login clicando em "Entrar com GitHub"
- Fluxo similar ao Google OAuth
- Deve importar username do GitHub como identificador alternativo

### Requisitos Técnicos
- Reutilizar infraestrutura OAuth criada em AUTH-001
- GitHub OAuth App configurado no projeto
- Scopes: read:user, user:email

### Critérios de Aceitação
- [ ] Botão "Entrar com GitHub" visível na página de login
- [ ] Fluxo OAuth completo funciona
- [ ] Username do GitHub é salvo no perfil
- [ ] Usuário pode ter múltiplos providers vinculados

### Referências
- PRD: docs/pre-dev/auth/prd.md
- TRD: docs/pre-dev/auth/trd.md

### Prioridade
Alta

### Estimativa
S

---

## Task: DASH-001 - Dashboard de métricas do usuário

### Requisitos Funcionais
- Exibir total de logins nos últimos 30 dias
- Gráfico de linha com logins por dia
- Filtro por período (7d, 30d, 90d)
- Card com último login e localização

### Requisitos Técnicos
- Frontend: React com Recharts para gráficos
- API: GET /api/v1/users/{id}/metrics
- Cache de 5 minutos no Redis
- Agregação feita no backend (não no frontend)

### Critérios de Aceitação
- [ ] Dashboard renderiza sem erros
- [ ] Gráfico mostra dados corretos para cada período
- [ ] Filtros funcionam e atualizam gráfico
- [ ] Loading state enquanto carrega dados
- [ ] Empty state se não houver dados
- [ ] Responsivo em mobile

### Prioridade
Média

### Estimativa
M
```

---

## Validação

O Gate 0 (`dev-import-tasks`) valida o arquivo:

### Erros (bloqueiam processamento)
- Task sem título (`## Task: ...`)
- Task sem critérios de aceitação
- Critérios de aceitação vazios

### Warnings (processamento continua)
- Task sem requisitos técnicos → "Será inferido do contexto"
- Task sem referência a PRD/TRD → "Recomendado executar /pre-dev-feature primeiro"
- Estimativa XL ou maior → "Considere quebrar em tasks menores"

---

## Dicas

1. **Um arquivo por sprint/ciclo**: Agrupe tasks relacionadas
2. **Critérios específicos**: Evite "funciona corretamente", prefira "retorna status 200 com body JSON"
3. **Referências a PRD/TRD**: Se existirem, o design será mais preciso
4. **Estimativas realistas**: S (1-2d), M (3-5d), L (1-2w), XL (>2w - considere quebrar)
