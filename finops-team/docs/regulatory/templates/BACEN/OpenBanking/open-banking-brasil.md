# Open Banking Brasil (Sistema Financeiro Aberto)
## Open Finance Brasil - Regulatory Reference Guide

---

## SUMARIO EXECUTIVO

### Visao Geral
O Open Finance Brasil (anteriormente Open Banking Brasil) consiste no compartilhamento de dados, produtos e servicos entre entidades reguladas por meio de iniciativa do cliente.

### Caracteristicas Principais
- **Autoridade Reguladora**: Banco Central do Brasil (BCB)
- **Marco Regulatorio**: Resolucao Conjunta CMN-BCB No. 1/2020
- **Formato de APIs**: REST/JSON com especificacao OpenAPI 3.0
- **Seguranca**: FAPI-1-Advanced Profile (Financial-grade API)
- **Compliance**: LGPD (Lei No. 13.709/2018)

---

## 1. MARCO REGULATORIO

### 1.1 Base Normativa Principal

| Norma | Descricao | Data |
|-------|-----------|------|
| **Resolucao Conjunta CMN-BCB No. 1/2020** | Disposicoes sobre o Open Banking | 04/05/2020 |
| **Circular BCB No. 4.015/2020** | Procedimentos para adesao | 04/05/2020 |
| **Resolucao BCB No. 32/2020** | Escopo de dados e servicos | 29/10/2020 |
| **Instrucao Normativa No. 97/2021** | Especificacoes tecnicas | 01/02/2021 |
| **LGPD - Lei No. 13.709/2018** | Protecao de Dados Pessoais | 14/08/2018 |

### 1.2 Governanca

A estrutura de governanca e composta por:
- **Conselho Deliberativo**: Decisoes estrategicas
- **Secretariado**: Gestao operacional (atualmente Open Finance Brasil)
- **Grupos Tecnicos (GTs)**: Especificacoes tecnicas por area

---

## 2. FASES DE IMPLEMENTACAO

### Fase 1 - Dados Abertos (Fev/2021)
**Objetivo**: Dados publicos sobre instituicoes participantes

| Categoria | Dados Compartilhados |
|-----------|---------------------|
| Canais de Atendimento | Agencias, terminais, correspondentes |
| Produtos e Servicos | Contas, cartoes, emprestimos, financiamentos |
| Tarifas | Tabelas de tarifas vigentes |

### Fase 2 - Dados de Clientes (Ago/2021)
**Objetivo**: Dados cadastrais e transacionais mediante consentimento

| Categoria | Dados Compartilhados |
|-----------|---------------------|
| Dados Cadastrais | CPF/CNPJ, nome, endereco, contatos |
| Contas | Saldos, extratos, limites |
| Cartao de Credito | Fatura, transacoes, limites |
| Operacoes de Credito | Contratos, parcelas, garantias |

### Fase 3 - Servicos (Out/2021)
**Objetivo**: Iniciacao de pagamentos e propostas de credito

| Servico | Descricao |
|---------|-----------|
| Iniciacao de Pagamento | PIX, TED, TEF, boletos |
| Encaminhamento de Proposta | Credito, financiamento |
| Pagamento de Contas | Concessionarias, tributos |

### Fase 4 - Dados Adicionais (Dez/2022+)
**Objetivo**: Expansao para novos segmentos

| Segmento | Dados |
|----------|-------|
| Cambio | Operacoes, cotacoes |
| Investimentos | Fundos, renda fixa, renda variavel |
| Seguros | Apolices, sinistros |
| Previdencia | Planos, contribuicoes |
| Capitalizacao | Titulos, sorteios |

---

## 3. REQUISITOS DE SEGURANCA DE APIS

### 3.1 Perfil de Seguranca FAPI

O Open Finance Brasil adota o Financial-grade API (FAPI) Security Profile:

```
Especificacao: FAPI 1.0 Advanced Profile
Baseado em: OpenID Connect + OAuth 2.0
```

### 3.2 Autenticacao e Autorizacao

#### OAuth 2.0 Flows Permitidos
| Flow | Uso | Requisito |
|------|-----|-----------|
| **Authorization Code + PKCE** | Consentimento de usuario | Obrigatorio |
| **Client Credentials** | APIs abertas (Fase 1) | Permitido |
| **Refresh Token** | Renovacao de acesso | Obrigatorio |

#### Mutual TLS (mTLS)
- **Obrigatorio** para todas as chamadas de API
- Certificado emitido por ICP-Brasil
- Validacao bidirecional (cliente e servidor)

### 3.3 Especificacoes Criptograficas

#### Assinatura JWT
| Parametro | Valor | Descricao |
|-----------|-------|-----------|
| Algoritmo | PS256 | RSASSA-PSS com SHA-256 |
| Tamanho Chave | 2048 bits | Minimo requerido |
| Header `typ` | JWT | Tipo do token |
| Header `alg` | PS256 | Algoritmo de assinatura |

#### Criptografia JWE
| Parametro | Valor | Descricao |
|-----------|-------|-----------|
| Key Encryption | RSA-OAEP | Encriptacao da chave |
| Content Encryption | A256GCM | Encriptacao do conteudo |

### 3.4 Exemplo de Request Autenticado

```http
POST /open-banking/payments/v1/pix/payments HTTP/1.1
Host: api.banco.com.br
Authorization: Bearer eyJhbGciOiJQUzI1NiIsInR5cCI6IkpXVCJ9...
x-fapi-interaction-id: c7c05ab1-3c54-4f08-8e93-9d8e4d2a5c17
x-fapi-auth-date: Mon, 04 Dec 2025 12:00:00 GMT
x-fapi-customer-ip-address: 201.220.100.50
Content-Type: application/json

{
  "data": {
    "localInstrument": "DICT",
    "payment": {
      "amount": "100.00",
      "currency": "BRL"
    },
    "creditorAccount": {
      "ispb": "12345678",
      "number": "1234567890",
      "accountType": "CACC"
    }
  }
}
```

---

## 4. GESTAO DE CONSENTIMENTO

### 4.1 Principios LGPD

O consentimento no Open Finance deve seguir:
- **Livre**: Sem coercao ou pressao
- **Informado**: Cliente ciente do uso dos dados
- **Inequivoco**: Manifestacao clara de vontade
- **Especifico**: Para finalidades determinadas

### 4.2 Ciclo de Vida do Consentimento

```
┌─────────────────────────────────────────────────────────────┐
│                    CICLO DE CONSENTIMENTO                    │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  [CRIACAO]  →  [AUTORIZACAO]  →  [ATIVO]  →  [REVOGACAO]    │
│      │              │              │             │           │
│      ↓              ↓              ↓             ↓           │
│  Cliente        Validacao      Uso dos      Encerramento    │
│  solicita       biometrica     dados                        │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 4.3 Requisitos de Consentimento

| Requisito | Descricao |
|-----------|-----------|
| **Prazo Maximo** | 12 meses (renovavel) |
| **Revogacao** | A qualquer momento pelo cliente |
| **Interface** | Canal eletronico dedicado |
| **Confirmacao** | Dupla autenticacao obrigatoria |
| **Registro** | Auditavel por 5 anos |

### 4.4 Estrutura de Consentimento

```json
{
  "data": {
    "consentId": "urn:bancoex:C1DD33123",
    "creationDateTime": "2025-12-04T12:00:00Z",
    "status": "AUTHORISED",
    "statusUpdateDateTime": "2025-12-04T12:05:00Z",
    "permissions": [
      "ACCOUNTS_READ",
      "ACCOUNTS_BALANCES_READ",
      "ACCOUNTS_TRANSACTIONS_READ"
    ],
    "expirationDateTime": "2026-12-04T12:00:00Z"
  }
}
```

---

## 5. TIPOS DE PARTICIPANTES

### 5.1 Papeis no Ecossistema

| Papel | Sigla | Descricao | Exemplo |
|-------|-------|-----------|---------|
| **Transmissor de Dados** | DADOS | Detentor dos dados do cliente | Banco tradicional |
| **Receptor de Dados** | DADOS | Recebe dados mediante consentimento | Fintech, agregador |
| **Detentora de Conta** | AS | Mantem conta de pagamento | Instituicao de pagamento |
| **Iniciador de Pagamento** | PISP | Inicia transacoes em nome do cliente | App de pagamento |

### 5.2 Obrigacoes por Tipo

```
┌────────────────────────────────────────────────────────────┐
│             MATRIZ DE OBRIGACOES                            │
├────────────────────────────────────────────────────────────┤
│ Participante          │ Transmitir │ Receber │ Pagamento  │
├───────────────────────┼────────────┼─────────┼────────────┤
│ Banco Multiplo (S1)   │    SIM     │   SIM   │    SIM     │
│ Banco Comercial (S2)  │    SIM     │   OPC   │    SIM     │
│ Instituicao Pag.      │    SIM     │   OPC   │    SIM     │
│ Fintech (ITP)         │    NAO     │   SIM   │    OPC     │
│ Agregador             │    NAO     │   SIM   │    NAO     │
└────────────────────────────────────────────────────────────┘

Legenda: SIM=Obrigatorio, NAO=Nao aplicavel, OPC=Opcional
```

---

## 6. ESPECIFICACOES TECNICAS DE API

### 6.1 Padroes de Nomenclatura

| Elemento | Padrao | Exemplo |
|----------|--------|---------|
| Endpoints | kebab-case | `/open-banking/accounts/v1/accounts` |
| Campos JSON | camelCase | `accountNumber`, `transactionId` |
| Enums | SCREAMING_SNAKE_CASE | `CONTA_CORRENTE`, `PIX_PAYMENT` |
| Data/Hora | ISO 8601 | `2025-12-04T12:00:00Z` |

### 6.2 Versionamento de APIs

```
Formato: /open-banking/{area}/v{major}/...

Exemplo:
  /open-banking/accounts/v1/accounts
  /open-banking/accounts/v2/accounts  (versao major nova)
```

### 6.3 Headers Obrigatorios

| Header | Descricao | Obrigatorio |
|--------|-----------|-------------|
| `x-fapi-interaction-id` | UUID de rastreamento | Sim |
| `x-fapi-auth-date` | Data/hora da autenticacao | Condicional |
| `x-fapi-customer-ip-address` | IP do cliente | Condicional |
| `x-customer-user-agent` | User-Agent do cliente | Recomendado |

### 6.4 Codigos de Resposta HTTP

| Codigo | Uso |
|--------|-----|
| 200 OK | Sucesso em GET |
| 201 Created | Sucesso em POST |
| 204 No Content | Sucesso em DELETE |
| 400 Bad Request | Erro de validacao |
| 401 Unauthorized | Token invalido/expirado |
| 403 Forbidden | Sem permissao |
| 404 Not Found | Recurso inexistente |
| 422 Unprocessable | Erro de negocio |
| 429 Too Many Requests | Rate limit excedido |

---

## 7. REQUISITOS DE DISPONIBILIDADE

### 7.1 SLA Minimo

| Metrica | Requisito |
|---------|-----------|
| Disponibilidade | 99.5% mensal |
| Tempo de Resposta (P95) | < 1000ms |
| Taxa de Erro | < 0.5% |

### 7.2 Monitoramento

- Reporte mensal ao BCB via sistema proprio
- Dashboard publico de status das APIs
- Notificacao de indisponibilidades > 5 minutos

---

## 8. REFERENCIAS

### 8.1 Links Oficiais

| Recurso | URL |
|---------|-----|
| Portal BCB | https://www.bcb.gov.br/en/financialstability/open_finance |
| Open Finance Brasil | https://openfinancebrasil.org.br/ |
| Portal do Desenvolvedor | https://openfinancebrasil.atlassian.net/wiki/spaces/OF/ |
| Especificacoes de API | https://github.com/OpenBanking-Brasil/areadesenvolvedor |
| Diretorio de Participantes | https://data.directory.openbankingbrasil.org.br/ |

### 8.2 Documentos Tecnicos

- Security Profile: FAPI 1.0 Advanced
- API Specifications: OpenAPI 3.0.0
- Certificate Profile: ICP-Brasil
- Consent API Specification: v2.0+

---

## 9. INTEGRACAO COM MIDAZ

### 9.1 Mapeamento de Campos

| Campo Open Finance | Campo Midaz | Transformacao |
|-------------------|-------------|---------------|
| `accountId` | `account.id` | UUID direto |
| `amount.amount` | `transaction.amount` | floatformat:4 |
| `amount.currency` | `transaction.currency` | ISO 4217 |
| `transactionDateTime` | `transaction.created_at` | ISO 8601 |
| `creditorAccount.ispb` | `organization.code` | 8 digitos |

### 9.2 Consideracoes de Implementacao

1. **Precisao Decimal**: Open Finance requer 4 casas decimais
2. **Timezone**: Sempre UTC (sufixo Z)
3. **IDs**: Formato UUID v4
4. **Paginacao**: Cursor-based com links HATEOAS

---

*Este documento e uma referencia tecnica baseada nas especificacoes oficiais do Open Finance Brasil.*
*Versao: 1.0.0 | Data: Dezembro/2025*
