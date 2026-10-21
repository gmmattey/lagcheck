# Cartão de Missão — Catálogo completo em Jogos

## Enquadramento

- **Problema da pessoa:** a aba Jogos esconde 31 títulos que já estão no catálogo válido só porque não possuem contexto iPhone. Isso faz o catálogo parecer incompleto para quem já entende que a leitura parte do telefone.
- **Resultado esperado observável:** Jogos exibe todo título com contexto válido no mercado atual. Um toque abre o Check usando apenas um contexto publicado pelo catálogo: iPhone quando houver; caso contrário, a plataforma externa válida. O resultado deixa visível a plataforma e, fora do iPhone, a leitura é apresentada como estimativa feita pelo iPhone na rede atual.
- **Fora de escopo:** JSON/schema do catálogo, rotas/Worker, motor UDP, score/veredito, persistência, histórico, widget, deep links, consentimento, anúncios fora de Jogos e publicação.
- **Lane:** Full flow comum.
- **Por que esta lane:** muda descoberta e composição nos dois clientes, mas reutiliza os resolvedores e contratos de catálogo já existentes. Não há alteração de API, persistência, regras de medição ou segurança.
- **Decisão/fonte de verdade:** Decisões 18, 41, 50, 51, 64, 105, 106 e 107; `docs/01-funcional.md` §§3, 10.2–10.4; `docs/04-design-system.md`; `docs/07-voz-do-produto.md`.

## Donos e fronteiras

- **Responsável pela entrega:** Rian — composição iOS/SwiftUI e Android/Compose.
- **Responsável pelo aceite operacional:** Giam.
- **Estratégia e orquestração:** Marco.
- **Revisores:** Renan (hierarquia, acessibilidade e honestidade visual) e Breno (testes/regressão).
- **Gate de Camillo:** não aplicável neste recorte. Reabrir como fluxo sistêmico se surgir alteração em schema, resolvedor, rota, persistência, Worker, telemetria ou regra de medição.

## Handoff de UI

- **Descoberta:** mantém Recentes reais, Favoritos reais, Todos os jogos em A–Z, busca e anúncio após conteúdo essencial. Card continua com arte editorial autorizada, nome e alvo inteiro; plataforma não vira filtro, etiqueta ou uma etapa extra.
- **Ação:** o toque não pergunta onde a pessoa joga. Escolhe apenas contexto que o catálogo já resolve; iPhone tem prioridade quando existir. Sem iPhone, o contexto externo continua explícito no Check/resultado.
- **Honestidade:** plataforma externa recebe a nota curta de estimativa já localizada. Não presume que console/PC está no mesmo Wi-Fi, não presume cabo e não chama a medição de ping oficial do jogo.
- **Acessibilidade/localização:** busca, cards, favoritos e resultados preservam identificadores e alvos de 44 pt/dp; PT-BR e inglês não adicionam texto explicativo longo nem dependem somente de cor.

## Aceite e evidência

| Critério observável | Dono da prova | Evidência exigida | Estado |
| --- | --- | --- | --- |
| Vitrine mostra os 54 jogos válidos sem recorte mobile | Rian / Breno | inspeção do catálogo e teste de UI iOS / emulador Android | pendente |
| Busca encontra um título somente PC e seu toque abre Check | Rian / Breno | teste UI iOS e teste manual Android | pendente |
| iPhone continua prioritário quando o jogo o suporta | Rian / Breno | teste de resolução e regressão de UI | pendente |
| Contexto externo mostra plataforma e nota de estimativa | Renan / Breno | inspeção e teste UI | pendente |
| Busca, favoritos, anúncio, PT-BR/inglês e alvos não regressam | Renan / Breno | build/testes e revisão visual | pendente |

## Handoff e encerramento

- **Arquivos/módulos previstos:** `HomeFeatureView`, `QuickCheckFeatureView`, `CheckCompletoResultView`, `MainActivity`, `MainViewModel`, testes de UI e `docs/DECISOES.md`.
- **Risco aceito:** a leitura externa continua uma estimativa de rota no telefone; a confirmação de rede/local do console ou PC permanece fora deste fluxo de um toque.
- **Evidência a registrar:** inspeção estática, build/teste iOS, build/teste Android, simulador/emulador e aparelho físico são estados separados.
