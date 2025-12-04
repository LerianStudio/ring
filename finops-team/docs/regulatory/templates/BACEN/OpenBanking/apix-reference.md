# APIX - API Accelerator for Brazil Open Banking
## Reference Implementation Guide

---

## SUMARIO EXECUTIVO

### Visao Geral
O Apigee Open Banking APIx (APIX) e uma solucao de referencia do Google Cloud para implementacao de APIs em conformidade com o Open Finance Brasil.

### Caracteristicas Principais
- **Provedor**: Google Cloud (Apigee)
- **Proposito**: Aceleracao de conformidade com Open Banking Brasil
- **Formato**: API Proxies pre-configurados
- **Compliance**: Especificacoes BACEN e Open Finance Brasil

---

## 1. VISAO GERAL DA SOLUCAO

### 1.1 O que e o APIX

O APIX fornece:
- **API Proxies Pre-configurados**: Templates prontos para especificacoes BACEN
- **Framework de Seguranca OAuth 2.0**: Integracao FAPI-compliant
- **Portal do Desenvolvedor**: Documentacao e sandbox de APIs
- **Ambiente de Testes**: Casos de teste pre-definidos

### 1.2 Arquitetura de Referencia

```
┌─────────────────────────────────────────────────────────────┐
│                     ARQUITETURA APIX                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  [Cliente]  →  [Apigee Gateway]  →  [Backend APIs]          │
│      │              │                     │                  │
│      │         ┌────┴────┐               │                  │
│      │         │ APIX    │               │                  │
│      │         │ Proxies │               │                  │
│      │         └────┬────┘               │                  │
│      │              │                     │                  │
│      ↓              ↓                     ↓                  │
│  [OAuth 2.0]   [Policies]           [Midaz/Core]            │
│  [FAPI]        [Rate Limit]         [CRM]                   │
│  [mTLS]        [Logging]            [Reporter]              │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. COMPONENTES PRINCIPAIS

### 2.1 API Proxies Disponiveis

| Proxy | Descricao | Fase Open Finance |
|-------|-----------|-------------------|
| `accounts-proxy` | Contas e saldos | Fase 2 |
| `credit-cards-proxy` | Cartoes de credito | Fase 2 |
| `loans-proxy` | Emprestimos e financiamentos | Fase 2 |
| `payments-proxy` | Iniciacao de pagamentos | Fase 3 |
| `consents-proxy` | Gestao de consentimentos | Fase 2+ |
| `resources-proxy` | Dados abertos | Fase 1 |

### 2.2 Politicas de Seguranca

| Politica | Funcao |
|----------|--------|
| `OAuth-v20-Verify` | Validacao de tokens de acesso |
| `FAPI-Security-Check` | Conformidade FAPI 1.0 Advanced |
| `mTLS-Verification` | Verificacao de certificado cliente |
| `JWT-Signature-Verify` | Validacao de assinatura PS256 |
| `Consent-Validation` | Verificacao de escopo de consentimento |

### 2.3 Portal do Desenvolvedor

Recursos disponiveis:
- Documentacao de APIs (OpenAPI 3.0)
- Sandbox com dados simulados
- Geracao de credenciais de teste
- Monitoramento de chamadas

---

## 3. SUPORTE A CONFORMIDADE

### 3.1 Requisitos BACEN Atendidos

| Requisito | Implementacao APIX |
|-----------|-------------------|
| Autenticacao OAuth 2.0 | Politica `OAuth-v20` |
| Mutual TLS | Politica `mTLS-Verification` |
| FAPI Profile | Politica `FAPI-Security-Check` |
| Logging de Auditoria | Politica `Message-Logging` |
| Rate Limiting | Politica `Spike-Arrest` |
| Versionamento | Path-based versioning |

### 3.2 Estrutura de Governanca

O APIX facilita conformidade com:
- Especificacoes tecnicas do Open Finance Brasil
- Requisitos de seguranca FAPI 1.0 Advanced
- Politicas de privacidade LGPD
- SLAs de disponibilidade (99.5%)

### 3.3 Certificacoes

| Certificacao | Status |
|--------------|--------|
| Conformidade Open Finance Brasil | Sim |
| FAPI 1.0 Advanced Profile | Sim |
| ISO 27001 (Google Cloud) | Sim |
| SOC 2 Type II | Sim |

---

## 4. CASOS DE USO

### 4.1 Exposicao de APIs por Instituicao Financeira

**Cenario**: Banco tradicional precisa expor APIs Open Finance

```
Fluxo:
1. Implanta APIX no Apigee
2. Configura backend (Midaz, CRM)
3. Registra no Diretorio Open Finance
4. Publica APIs no Portal
5. Monitora metricas e SLA
```

### 4.2 Integracao de Provedores Terceiros (TPP)

**Cenario**: Fintech quer consumir APIs de multiplos bancos

```
Fluxo:
1. Registra como participante
2. Obtem certificado ICP-Brasil
3. Conecta via APIX Gateway
4. Implementa fluxo de consentimento
5. Consome APIs padronizadas
```

### 4.3 Iniciacao de Pagamentos (PISP)

**Cenario**: App de pagamento inicia PIX em nome do cliente

```
Fluxo:
1. Cliente autoriza no app
2. App solicita consentimento
3. Cliente autentica no banco
4. APIX roteia para backend
5. Pagamento executado via PIX
```

---

## 5. IMPLEMENTACAO TECNICA

### 5.1 Deployment no Google Cloud

```bash
# Exemplo de deployment via gcloud
gcloud apigee apis create open-banking-accounts \
  --bundle-directory=./proxies/accounts-proxy

gcloud apigee apis deploy open-banking-accounts \
  --environment=prod \
  --revision=1
```

### 5.2 Configuracao de Seguranca

```xml
<!-- Exemplo de politica OAuth 2.0 -->
<OAuthV2 name="OAuth-v20-Verify">
  <Operation>VerifyAccessToken</Operation>
  <Scope>accounts consent:urn:example:123</Scope>
  <GenerateResponse enabled="true"/>
</OAuthV2>
```

### 5.3 Exemplo de Proxy Configuration

```xml
<!-- accounts-proxy.xml -->
<ProxyEndpoint name="default">
  <PreFlow>
    <Request>
      <Step><Name>mTLS-Verification</Name></Step>
      <Step><Name>OAuth-v20-Verify</Name></Step>
      <Step><Name>FAPI-Security-Check</Name></Step>
      <Step><Name>Consent-Validation</Name></Step>
    </Request>
  </PreFlow>

  <Flows>
    <Flow name="GetAccounts">
      <Condition>(proxy.pathsuffix MatchesPath "/accounts") and (request.verb = "GET")</Condition>
      <Request>
        <Step><Name>Rate-Limit-Accounts</Name></Step>
      </Request>
    </Flow>
  </Flows>

  <RouteRule name="default">
    <TargetEndpoint>backend-midaz</TargetEndpoint>
  </RouteRule>
</ProxyEndpoint>
```

---

## 6. INTEGRACAO COM MIDAZ

### 6.1 Target Endpoint para Midaz

```xml
<!-- target-midaz.xml -->
<TargetEndpoint name="backend-midaz">
  <HTTPTargetConnection>
    <URL>https://api.midaz.internal/v1</URL>
    <SSLInfo>
      <Enabled>true</Enabled>
      <ClientAuthEnabled>true</ClientAuthEnabled>
    </SSLInfo>
  </HTTPTargetConnection>
</TargetEndpoint>
```

### 6.2 Mapeamento de Recursos

| Endpoint APIX | Recurso Midaz |
|---------------|---------------|
| `/accounts` | `/accounts` |
| `/accounts/{id}/balances` | `/accounts/{id}/balances` |
| `/accounts/{id}/transactions` | `/transactions?account_id={id}` |
| `/payments/pix` | `/transactions` (type=PIX) |

### 6.3 Transformacao de Dados

```xml
<!-- Transformacao Open Finance → Midaz -->
<AssignMessage name="Transform-Request">
  <Set>
    <Payload contentType="application/json">
      {
        "account_id": "{openbanking.accountId}",
        "amount": {openbanking.payment.amount},
        "currency": "{openbanking.payment.currency}",
        "type": "PIX"
      }
    </Payload>
  </Set>
</AssignMessage>
```

---

## 7. MONITORAMENTO E OBSERVABILIDADE

### 7.1 Metricas Disponiveis

| Metrica | Descricao |
|---------|-----------|
| `apigee.proxy.request.count` | Total de requisicoes |
| `apigee.proxy.response.time` | Latencia (P50, P95, P99) |
| `apigee.proxy.error.count` | Total de erros |
| `apigee.target.response.time` | Latencia do backend |

### 7.2 Integracao com Cloud Monitoring

```yaml
# Exemplo de alerta SLA
alertPolicy:
  displayName: "Open Banking SLA Alert"
  conditions:
    - displayName: "Availability < 99.5%"
      conditionThreshold:
        filter: 'metric.type="apigee.proxy.response.count"'
        comparison: COMPARISON_LT
        thresholdValue: 0.995
        duration: 300s
```

---

## 8. MELHORES PRATICAS

### 8.1 Seguranca

- **Sempre** validar certificados mTLS
- **Nunca** armazenar tokens em logs
- **Rotacionar** credenciais periodicamente
- **Monitorar** tentativas de acesso suspeitas

### 8.2 Performance

- Implementar caching para dados abertos (Fase 1)
- Usar connection pooling para backends
- Configurar timeouts adequados (< 1s para FAPI)
- Escalar horizontalmente em picos

### 8.3 Operacoes

- Manter versionamento de proxies
- Documentar todas as alteracoes
- Testar em ambiente de staging
- Monitorar SLAs continuamente

---

## 9. REFERENCIAS

### 9.1 Links Oficiais

| Recurso | URL |
|---------|-----|
| Google Cloud Open Banking | https://cloud.google.com/solutions/open-banking-apix |
| Apigee Documentation | https://cloud.google.com/apigee/docs |
| Open Finance Brasil APIs | https://github.com/OpenBanking-Brasil/areadesenvolvedor |
| FAPI Specification | https://openid.net/specs/openid-financial-api-part-2-1_0.html |

### 9.2 Repositorios de Codigo

- Apigee Open Banking: https://github.com/apigee/openbank
- Open Finance Brasil Specs: https://github.com/OpenBanking-Brasil

---

## 10. SUPORTE

### 10.1 Google Cloud Support

- **Premium Support**: SLA 24/7 para producao
- **Standard Support**: Horario comercial
- **Community**: Stack Overflow, GitHub Issues

### 10.2 Contatos Open Finance Brasil

- Portal: https://openfinancebrasil.org.br/
- Service Desk: Atraves do Diretorio de Participantes

---

*Este documento e uma referencia tecnica para implementacao do APIX.*
*Versao: 1.0.0 | Data: Dezembro/2025*
