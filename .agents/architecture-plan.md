# Architecture Plan — LagCheck

> Documento mantido por **Camillo** (Principal Engineer / System Architect) quando acionado pelo gate arquitetural obrigatório (`AGENTS.md` §6 e `.agents/WORKFLOW.md` §2.3).
> Tarefas simples (Fast lane ou Full flow comum sem impacto sistêmico) **não** exigem o preenchimento deste artefato.

---

## 1. Contexto e Problema
- **Problema a resolver:** [Descrever de forma objetiva o problema sistêmico ou necessidade arquitetural]
- **Comportamento esperado:** [O que o sistema deve fazer após a mudança]
- **Frente solicitante / Autor do aceite:** Marco (Product Lead)

---

## 2. Escopo Arquitetural
- **Módulos afetados:**
  - [ ] `NolaggyDomain` (Domínio puro, sem dependências de framework de UI/rede)
  - [ ] `NolaggyApplication` (Casos de uso, orquestração de medição)
  - [ ] `NolaggyInfrastructure` (Networking UDP, probes, sockets, persistência SwiftData, cliente Cloudflare)
  - [ ] `NolaggyDesign` (Componentes, tokens Dark Competitive UI, assets)
  - [ ] `LagCheck` (Composição principal, app target, injeção de dependências)
  - [ ] Cloudflare Worker (`nolaggy-deep-check` em `/v1/catalog.json`, `/v1/load`, `/v1/telemetry`)
- **Não-objetivos (Out of Scope):** [O que explicitamente NÃO será alterado]

---

## 3. Decisão Técnica & Desenho da Solução
- **Decisão proposta:** [Descrição detalhada da arquitetura escolhida]
- **Alternativas consideradas e rejeitadas:** [Por que outras opções foram descartadas]
- **Fluxo de dados & Diagrama de sequência (se aplicável):**
- **Contratos de API / Schemas JSON / Protocolos:** [Definição dos payloads ou interfaces]

---

## 4. Persistência e Migrações
- **Impacto no SwiftData:** [Modelos alterados, estratégia de versionamento de schema, migração leve/personalizada]
- **Compatibilidade retroativa com histórico local:** [Garantia de leitura de sessões antigas]

---

## 5. Falhas, Timeout e Resiliência
- **Tratamento de timeouts e cancelamento:** [Uso de `Task.isCancelled`, encerramento gracioso de sockets UDP]
- **Comportamento sob condições adversas:** [Dados insuficientes resultam estritamente em `.inconclusive`]
- **Descarte de dados inválidos:** [Sem fallback para ping HTTP/ICMP]

---

## 6. Segurança, Privacidade e Custos
- **Custo operacional recorrente:** **Zero** (Restrição inegociável do produto).
- **Privacidade & Telemetria:** Nenhuma coleta de PII, IP completo ou dados sensíveis.
- **Validação criptográfica:** [Ed25519 para catálogo remoto]

---

## 7. Estratégia de Testes e Validação
- **Testes unitários necessários (Rian / Iury):** [Módulos de domínio e infraestrutura]
- **Testes de contrato:** [Worker / payloads]
- **Critérios de validação independente (Breno):** [Checklist de testes, build, regressão]
- **Validação em iPhone físico (iOS 17+):** [Cenários obrigatórios em device real]

---

## 8. Status do Gate Arquitetural
- [ ] Investigação concluída por Camillo
- [ ] Plano aprovado por Camillo e alinhado com Marco
- [ ] Implementação concluída por Rian / Iury
- [ ] Validação técnica e de confiabilidade aprovada por Breno
- [ ] Revisão final de aderência arquitetural aprovada por Camillo
- [ ] Aceite de produto formalizado por Marco
