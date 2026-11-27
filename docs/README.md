# LagCheck — documentação do projeto

Atualizado em 2026-11-15. Marca oficial: **LagCheck**; wordmark: `Lagcheck` (`wordmark-primary.svg`, Decisão 124).

O app ajuda a decidir se a conexão observada está adequada para jogar agora. Mede a rota do celular ou PC até infraestrutura de referência; não promete ping real do jogo nem desempenho futuro. Sem respostas UDP válidas suficientes, o resultado é inconclusivo.

## Fontes de verdade

| Assunto | Documento |
| --- | --- |
| Design system compartilhado | [DESIGN.md](../shared/design-system/DESIGN.md), [Componentes](../shared/design-system/components.md) e [Tokens](../shared/design-system/tokens/) |
| Adaptação desktop Windows (WinUI 3) | [apps/windows/DESIGN.md](../apps/windows/DESIGN.md) |
| Escopo, jornada e regras de produto | [Funcional](01-funcional.md) |
| Roadmap oficial, backlog e estado atual | [Roadmap e Estado Atual](ROADMAP.md) |
| Módulos e responsabilidades | [Arquitetura](02-arquitetura.md) e [Contrato KMP](../apps/android/core/domain/ENGINE_CONTRACT.md) |
| Contratos e algoritmos | [Especificação técnica](03-especificacao-tecnica.md) |
| Design system iOS/Android detalhado | [Design system](04-design-system.md) |
| Composição de interface histórica | [Protótipo canônico iOS](../shared/design-system/prototypes/ios-reference/README.md) |
| Papéis e gates | [Governança](05-governanca-e-fluxo-de-trabalho.md) e [workflow](../.agents/WORKFLOW.md) |
| Distribuição iOS | [Release](06-fluxo-de-release.md) |
| Copy e localização | [Voz do produto](07-voz-do-produto.md) |
| Arquitetura Android e motor KMP | [Arquitetura Android](08-arquitetura-android.md) |
| Protótipo Windows (Compose Desktop histórico) | [Design system Windows (histórico)](09-design-system-windows.md), [empacotamento](../apps/android/desktop/PACKAGING.md) e [protótipo visual](../shared/design-system/prototypes/windows-premium/README.md) |
| Aprovações e histórico | [Documento único de decisões](DECISOES.md) |
| Fichas das lojas, ASO e checklist de lançamento | [`lojas/`](lojas/) |
| Monitoramento e operação | [`operacao/`](operacao/) |
| Funil, DebugView e exclusão do aparelho interno | [Firebase Analytics iOS](analytics/firebase-analytics-ios.md) |
| Funil Android, DebugView e exclusão local | [Firebase Analytics Android](analytics/firebase-analytics-android.md) |

Decisões de ID maior refinam ou substituem as anteriores. Documentos em `archive/` preservam histórico. Uma divergência sem decisão posterior exige alinhamento antes de implementação.

## Escopo vigente

- iPhone com iOS 17+ (`apps/ios/`) e Android nativo Kotlin/Compose com API 26+ (`apps/android/`) como alvos oficiais; Windows WinUI 3 (`apps/windows/`) permanece protótipo interno não publicável sem autorização explícita.
- Motor único Kotlin Multiplatform (`apps/android/core/domain`, Decisões 134–136 e 143) servindo iOS, Android, Windows e site.
- Jornada `Home → Jogo → Check → Veredito`, 4 destinos no mobile (`Início`, `Jogos`, `Histórico`, `Ajustes`/`Configurações`) com títulos das telas em caixa alta, busca padronizada (`#15181E`, `12 px`), `Populares` 2×3 e `Jogos` em 3 colunas (Decisões 144 e 145).
- Dark Competitive UI (`shared/design-system/DESIGN.md`): profundidade sem contornos em cards/busca/anúncios, tríade tipográfica Barlow Semi Condensed + Barlow + Chakra Petch, Roxo Gamer (`#7C3AED`) exclusivo do CTA principal e Coral Solar (`#FF5A36`) para atenção/risco/ações destrutivas.
- Catálogo local embarcado de 54 jogos sem assinatura (Decisão 106), refresh opcional validado via `catalog-v3.json`, e AdMob Native Advanced em faixa horizontal compacta (`Início`, `Jogos`, `Histórico`, `Resultado` válido) com consentimento UMP (Decisões 96, 97 e 144).
- Custo recorrente zero: único Cloudflare Worker (`nolaggy-deep-check`) com `GET /v1/load` e `POST /v1/telemetry`.

## Estado e evidências

A [auditoria Android de 2026-10-03](auditorias/android-ios-code-parity-2026-10-03.md) registra a base inicial do port. Validações locais recentes de build/testes unitários e simulador/emulador não substituem teste UDP em hardware físico, troca real de rede e aprovação explícita antes de distribuição em TestFlight/lojas.

## Organização do repositório (Decisão 120)

| Diretório | Conteúdo |
| --- | --- |
| `apps/ios/` | Implementação SwiftUI, `NolaggyDesign`, `NolaggyDomain`, infraestrutura iOS e testes |
| `apps/android/` | App Compose, motor KMP `:core:domain`, `:core:catalog`, `:core:network`, `:core:session`, `:core:telemetry-radio`, `:core:designsystem`, `:engine-host` e `:desktop` |
| `apps/windows/` | Protótipo Windows WinUI 3 (`LagCheck.WinUI`, `DESIGN.md`) |
| `apps/worker/` | Cloudflare Worker `nolaggy-deep-check` (`/v1/load` e `/v1/telemetry`) |
| `shared/design-system/` | `DESIGN.md`, `components.md`, tokens, fontes, assets oficiais e protótipos |
| `shared/distribution/` | `store/` (App Store/Google Play), `marketing/` e `release/` |
| `shared/scripts/` | Automações de validação, ícones e release |
| `docs/` | Documentação técnica, funcional, governança e `DECISOES.md` |
| `.agents/`, `.codex/` | Workflow da squad, skills canônicas e definição dos 4 agentes titulares |
