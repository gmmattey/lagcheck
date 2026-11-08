# LagCheck — documentação do projeto

Atualizado em 2026-10-03. Marca oficial: **LagCheck**; wordmark: `lagcheck`.

O app ajuda a decidir se a conexão observada está adequada para jogar agora. Mede a rota do celular até infraestrutura de referência; não promete ping real do jogo nem desempenho futuro. Sem respostas UDP válidas suficientes, o resultado é inconclusivo.

## Fontes de verdade

| Assunto | Documento |
| --- | --- |
| Escopo, jornada e regras de produto | [Funcional](01-funcional.md) |
| Módulos e responsabilidades iOS | [Arquitetura](02-arquitetura.md) |
| Contratos e algoritmos iOS | [Especificação técnica](03-especificacao-tecnica.md) |
| Tokens, marca e acessibilidade | [Design system](04-design-system.md) e [tokens](../design-system/tokens/) |
| Composição de interface | [Protótipo canônico iOS](../design-system/prototypes/ios-reference/README.md) |
| Papéis e gates | [Governança](05-governanca-e-fluxo-de-trabalho.md) e [workflow](../.agents/WORKFLOW.md) |
| Distribuição iOS | [Release](06-fluxo-de-release.md) |
| Copy e localização | [Voz do produto](07-voz-do-produto.md) |
| Port, rádio e limites Android | [Arquitetura Android](08-arquitetura-android.md) |
| Protótipo Windows (Compose Desktop; Decisões 114 a 116) | [Design system e telemetria Windows](09-design-system-windows.md), [empacotamento](../android/desktop/PACKAGING.md) e [protótipo visual](../design-system/prototypes/windows-premium/README.md) |
| Aprovações e histórico | [Documento único de decisões](DECISOES.md) |
| Fichas das lojas, ASO e checklist de lançamento | [`lojas/`](lojas/) |
| Monitoramento e operação | [`operacao/`](operacao/) |
| Funil, DebugView e exclusão do aparelho interno | [Firebase Analytics iOS](analytics/firebase-analytics-ios.md) |
| Funil Android, DebugView e exclusão local | [Firebase Analytics Android](analytics/firebase-analytics-android.md) |

Decisões de ID maior refinam ou substituem as anteriores. Documentos em `archive/` preservam histórico. Uma divergência sem decisão posterior exige alinhamento antes de implementação.

## Escopo vigente

- iPhone com iOS 17+ e Android nativo Kotlin/Compose com API 26+ (Decisões 67–69).
- Jornada `Home → Jogo → Check → Veredito`, duas abas e Check único com repouso e carga. Score numérico subordinado aos detalhes.
- Dark Competitive UI: Roxo Gamer para ações primárias; Coral Solar para atenção, erro e ações destrutivas (Decisão 66). Assets oficiais preservados.
- Regras determinísticas e catálogo assinado. No Android, influência do gateway no veredito é uma divergência autorizada, com validação física pendente (Decisão 69).
- Custo recorrente zero, sem anúncios no MVP1. Nenhum endpoint novo autorizado além dos três contratos existentes do Worker.

## Estado e evidências

A [auditoria Android de 2026-10-03](auditorias/android-ios-code-parity-2026-10-03.md) registra testes JVM, testes unitários do app, build Debug e capturas no emulador. A comparação renderizada com iPhone, medição UDP em aparelho físico, troca de rede, gateway/NAT e PDF físico continuam pendentes nos cenários indicados na auditoria. Fixtures de histórico comprovam leitura e apresentação, não coleta real.

Os estados antigos nas Decisões 68–69 descrevem a evidência disponível quando foram registradas; o acompanhamento posterior está na auditoria. Essa evidência não comprova distribuição Android, TestFlight ou publicação em loja. O [fluxo de release](06-fluxo-de-release.md) trata Xcode, TestFlight e App Store; não constitui autorização nem procedimento de publicação Android.

## Organização do repositório

| Diretório | Conteúdo |
| --- | --- |
| `Sources/`, `Tests/`, `Nolaggy.xcodeproj`, `project.yml` | Implementação, testes e configuração iOS; nomes internos legados (`Nolaggy`) preservados |
| `android/` | App Compose, módulos de domínio, catálogo, rede, sessão, rádio e a prévia desktop (Windows) |
| `worker/` | Worker de carga, catálogo e telemetria |
| `store/` | Criativos e metadados enviados às lojas (privacidade e suporte ficam no site oficial) |
| `design-system/` | Tokens, assets e protótipos |
| `marketing/` | Campanhas, vídeos e plano de crescimento |
| `docs/` | Documentação técnica e de produto. Subpastas: `lojas/`, `analytics/`, `operacao/`, `auditorias/`, `pesquisa/`, `archive/` |
| `scripts/` | Automações de build e release |
| `.agents/`, `.codex/` | Workflow, skills e agentes da squad |
