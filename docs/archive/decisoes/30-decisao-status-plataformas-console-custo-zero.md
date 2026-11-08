# LagCheck — Decisão 30: Status Operacional de Plataformas de Console a Custo Zero (PSN e Xbox Live)

**Status:** Decisão aprovada pelo Dono do Produto (Luiz); em especificação técnica e implementação  
**Data:** 18 de setembro de 2026  
**Autores / Revisores:** Luiz (Dono do Produto), Marco (Produto), Iury (Rede), Renan (Design), Rian (iOS)  
**Complementa:** `docs/01-funcional.md`, `docs/02-arquitetura.md`, `docs/03-especificacao-tecnica.md`, `docs/07-voz-do-produto.md`, `docs/archive/decisoes/24-decisao-adocao-design-system-apple-games.md`, `docs/archive/decisoes/26-decisao-catalogo-console.md`

---

## 1. Contexto e Problema de Produto (Marco)

Com a liberação de plataformas de console no catálogo (Decisão 26 para Fortnite, Roblox e Minecraft), o jogador pode selecionar PlayStation ou Xbox para checar sua conexão antes de ligar o console.

Porém, um cenário frequente de frustração ocorre quando a conexão e a rota do jogador estão perfeitas (ex.: ping 18 ms, jitter 1 ms, perda 0%), mas a rede da plataforma (PlayStation Network ou Xbox Live) está fora do ar ou com problemas de autenticação/matchmaking. Sem essa informação, o usuário tenta jogar, falha e conclui erroneamente que o diagnóstico do LagCheck estava incorreto.

### Diretrizes de Produto:
1. **Valor para o jogador:** Responder com clareza: *"A minha conexão está boa para jogar agora, e a plataforma do jogo está operando normalmente?"*
2. **Separação estrita:** O score de rota do LagCheck continua sendo estritamente determinístico e baseado na medição UDP real. O status da plataforma é uma **camada contextual e não-bloqueante**, que enriquece a recomendação da partida sem adulterar o score.
3. **Custo Operacional Zero Inegociável:** Nenhuma criação de novos workers na Cloudflare, nenhum servidor intermediário, nenhum proxy e nenhum serviço pago de terceiros (como Downdetector comercial).

---

## 2. Engenharia de Rede e Endpoints Públicos (Iury)

Investigamos a infraestrutura pública mantida pelas próprias fabricantes de consoles para seus portais de status e dashboards de console. Ambas disponibilizam endpoints públicos em CDNs globais abertos para consulta HTTP/HTTPS sem necessidade de chave de API, autenticação ou custo:

### A. PlayStation Network (Sony Interactive Entertainment)
* **Endpoint público (Akamai CDN):**  
  `https://status.playstation.com/data/statuses/region/SCEA.json` (Américas — BR, US, CA, MX, etc.)  
  `https://status.playstation.com/data/statuses/region/SCEE.json` (Europa, Oceania)
* **Estrutura de Dados:**
  * Objeto raiz com lista `countries` indexada por `countryCode` (ex.: `"BR"` ou `"US"`).
  * Cada país contém um array de incidentes gerais `status` e a lista de serviços essenciais `services` (`Account_Management`, `Gaming_And_Social`, `PlayStation_Store`).
  * Quando não há incidentes, os arrays `status` retornam vazios (`[]`).
  * Em caso de degradação ou queda, o objeto descreve o serviço impactado e a mensagem oficial da Sony.

### B. Xbox Network / Xbox Live (Microsoft Corporation)
* **Endpoint público (Azure Front Door):**  
  `https://xnotify.xboxlive.com/servicestatusv6/{Market}/{Locale}`  
  (ex.: `https://xnotify.xboxlive.com/servicestatusv6/BR/pt-BR` ou `US/en-US`)
* **Header obrigatório:** `Accept: application/json`
* **Estrutura de Dados:**
  * Objeto `Status.Overall.State`: `"None"` (operacional), `"Minor"` (parcialmente degradado) ou `"Major"` (interrupção grave).
  * Lista discriminada de `CoreServices` e `Scenarios` (ex.: `"Conta e perfil"`, `"Jogos multijogador"`, `"Entrar"`).

### Políticas de Tráfego e Resiliência do Cliente:
1. **Cache em Memória:** TTL de 10 minutos para evitar chamadas de rede repetitivas e economizar bateria.
2. **Timeout Agressivo:** Máximo de 3.000 ms por consulta.
3. **Fallback Seguro (Fail-Open):** Se houver falha de rede ou timeout na consulta de status da plataforma, o resultado é classificado como `.unknown` e a medição UDP prossegue normalmente sem exibir alarmes falsos.

---

## 3. Arquitetura de Software e Módulos (Rian)

Seguindo rigorosamente `docs/02-arquitetura.md`:

```
┌────────────────────────────────────────────────────────┐
│                   NolaggyDomain                        │
│  - enum PlatformHealthStatus: operational, degraded,   │
│    majorOutage, unknown                                │
│  - struct PlatformHealth                               │
│  - protocol PlatformHealthProvider                     │
└───────────────────────────▲────────────────────────────┘
                            │ implementa
┌───────────────────────────┴────────────────────────────┐
│                NolaggyInfrastructure                  │
│  - actor DirectPlatformHealthClient:                   │
│    PlatformHealthProvider                              │
│    (URLSession nativa, parsers JSON SCEA e xnotify,   │
│     cache com TTL de 10 min, zero dependência cloud)   │
└────────────────────────────────────────────────────────┘
```

1. **`NolaggyDomain`:**
   * Contratos puros sem importação de `Foundation` com rede ou `UIKit`/`SwiftUI`.
2. **`NolaggyInfrastructure`:**
   * `DirectPlatformHealthClient` utiliza `URLSession.shared` com parsing seguro via `Decodable`.
3. **`NolaggyApplication` e `NolaggyApp`:**
   * Consulta disparada assincronamente quando a plataforma selecionada for de console (`playstation` ou `xbox`).
   * Não atrasa nem bloqueia o ciclo do `QuickCheckService`.

---

## 4. Design, UX e Voz do Produto (Renan & Marco)

1. **Visual Alinhado com Apple Games Editorial Hub (`docs/24`):**
   * **Estado Operacional:** Nenhum aviso visual invasivo. A interface foca no score limpo da conexão.
   * **Estado Degradado ou Fora do Ar:** Um card de aviso sutil com borda e fundo semântico, utilizando o SF Symbol `exclamationmark.triangle.fill`.
2. **Tom de Voz (`docs/07-voz-do-produto.md`):**
   * *Degradado:* "Sua conexão está pronta para jogar, mas a PlayStation Network apresenta instabilidade no momento."
   * *Fora do Ar:* "Atenção: A Xbox Network está enfrentando interrupções no login e partidas multiplayer."
3. **Acessibilidade:**
   * Alvo de toque adequado, rótulo acessível completo para VoiceOver e contraste total segundo WCAG AA.
