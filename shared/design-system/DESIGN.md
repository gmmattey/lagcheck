# LagCheck Design System

## Contexto do produto

LagCheck é um diagnóstico competitivo para quem quer saber se a conexão está pronta para jogar. O sistema prioriza uma decisão rápida e honesta: o veredito vem antes dos detalhes; a evidência vem quando a pessoa precisa entender ou agir.

## Fundamentos visuais

O visual é escuro, calmo e técnico, sem cair numa caricatura gamer. A área de decisão respira; listas, rotas e métricas usam linhas finas, monoespaçado e densidade controlada. A identidade usa o wordmark oficial claro em superfícies escuras.

## Color / Cor

Os tokens canônicos em hex valem para iOS, Android, Windows e Web (ver [`tokens/platforms.json`](tokens/platforms.json)): fundo `--bg` (`#0B0D10`), superfície (`#15181E`), painel elevado (`#1E232B`), texto primário (`#F4F5F7`), texto secundário (`#8A93A0`), texto terciário (`#606873`), Roxo Gamer (`#7C3AED`), Coral Solar (`#FF5A36`), Âmbar (`#F59E0B`) e Verde (`#22C55E`). A separação entre blocos vem de contraste tonal entre superfícies e elevação sutil, evitando linhas de contorno/bordas em cards, pílulas, campos de busca e anúncios (Decisão 128). Não converter automaticamente de `oklch` antigos: `oklch(0.585 0.214 299)` resulta em `#9052e6`, não em `#7C3AED`. Roxo Gamer é reservado para ação principal, seleção ativa, foco e progresso; Coral Solar serve a erro, risco ou ação destrutiva; Verde comunica resultado favorável e nunca substitui uma explicação textual.

## Typography / Tipografia

A tipografia é unificada entre iOS, Android, Windows e Web (Decisão 125):

| Papel | Família | Peso recomendado | Uso |
| --- | --- | --- | --- |
| Títulos e vereditos | **Barlow Semi Condensed** | 700–800 | Vereditos, nomes de tela, chamadas e destaques |
| Corpo e controles | **Barlow** | 400–600 | Parágrafos, listas, formulários, botões e navegação |
| Métricas e dados | **Chakra Petch** | 600 | Valores e rótulos de ping, jitter, perda de pacotes, rotas e tags técnicas (algarismos tabulares) |
| Fallback | Pilha sans-serif/mono do sistema | conforme componente | Leitura quando a fonte web não carregar |

As fontes empacotadas e suas licenças OFL ficam em `apps/android/core/designsystem/src/main/res/font/`, `apps/ios/Sources/NolaggyDesign/Resources/Fonts/`, `apps/windows/LagCheck.WinUI/Assets/Fonts/` e `apps/android/desktop/src/main/resources/fonts/`. Títulos trabalham com tracking negativo; rótulos técnicos são pequenos, em caixa alta e com tracking positivo. No mobile, **títulos principais e secundários das telas ficam sempre em CAIXA ALTA** (`JOGOS`, `HISTÓRICO`, `AJUSTES` / `CONFIGURAÇÕES`, `DETALHES`, `DETALHES TÉCNICOS`, `DADOS DA REDE`), mantendo a capitalização normal nos rótulos da barra inferior (`Início`, `Jogos`, `Histórico`, `Ajustes` / `Configurações`). Não usar fonte de métrica para parágrafos nem Barlow Semi Condensed em leitura contínua.

**Regras de implementação web (`gmmattey/landings/pages/lagcheck/src/styles/global.css`):**
- Centralizar as famílias em *custom properties* CSS, sem repetir configurações em páginas individuais. Aplicar as regras por papéis semânticos para que toda a home, páginas de jogos, ferramentas e páginas institucionais compartilhem a mesma tipografia.
- Usar Barlow em leitura longa; evitar Chakra Petch em parágrafos e evitar Barlow Semi Condensed em textos de leitura contínua.
- Preservar hierarquia, legibilidade e contraste no mobile (inclusive a 320 px); manter altura de linha adequada e controlar quebras de título e largura dos botões.
- Carregar apenas pesos e subconjuntos necessários em WOFF2, com `font-display: swap`, alternativas compatíveis e verificação de CLS/LCP. Não introduzir dependência de CDN obrigatória se o self-hosting for viável.
- Métricas devem continuar diferenciando valor observado, indisponível e inconclusivo. A fonte não é um sinal de estado; as cores semânticas e mensagens textuais continuam sendo a referência.
- Paleta oficial preservada: fundo `#0B0D10`, Roxo Gamer `#7C3AED` e variações aprovadas. Sem substituir a paleta por cores inspiradas em concorrentes.
- A alteração desta documentação **não publica o site**.

## Mapa de medição

O mapa de medição mostra de onde o check sai e até qual região ele foi medido, espelhando a implementação web (`pages/lagcheck/src/lib/map/`):

- **Base e projeção:** grade de pontos Natural Earth 110m (1,5° por célula) em projeção equiretangular, fundo `--bg` (`#0B0D10`), pontos de terra em `--text-secondary` a 34% de opacidade. Plano, sem gradiente, brilho, halo ou onda expansiva.
- **Câmera e enquadramento:** `WORLD_CAMERA` (`lon = 0`, `lat = 12`, `zoom = 1`) durante a varredura e `fitCamera` com teto de `zoom <= 3.4` quando a rota é fechada (acima disso a grade de 1,5° perde o contorno dos continentes), garantindo que pinos e rótulos caibam sem corte.
- **Arcos e sondas reais:** arco quadrático de Bézier (`computeArc` / `bezierPoint`) em `--purple` (`#7C3AED`). Tudo que se move vem de medição real: saída fixa em `420 ms` (`620 ms` na varredura inicial com `45 ms` de escalonamento entre regiões) e volta proporcional ao RTT observado (`clamp(rttMs * 8, 300, 700)` ms) com easing cúbico simétrico.
- **Rótulos sem sobreposição:** apenas “Você” e a região escolhida (ou mais rápida na varredura) recebem rótulo, com detecção de colisão de caixas para nunca sobrepor nem sair da área útil.
- **"Você":** localização aproximada pelo IP no endpoint do site (`/v1/approx-location`, 0,5°), com rótulo "Você · Cidade"; a varredura espera por ela, como o `trySweep()` do site. Se falhar, os apps usam o país do aparelho; sem país, a nota "Localização aproximada indisponível".
- **Implementação nativa:** `RouteMapController` + `RouteMeasurementMapView` (`apps/ios/Sources/NolaggyDesign/Components/RouteMap/`) e `RouteMapController` + `RouteMeasurementMap` (`apps/android/core/designsystem/src/main/kotlin/com/lagcheck/core/designsystem/components/map/`), porta direta de `route-map.ts` (Decisão 123). Contêiner com raio 12 e proporção 4:3 na medição e 16:10 no resultado.

## Espaçamento, forma e elevação

Base de 4 px. Conteúdo de tela usa 22 px nas laterais; controles interativos usam no mínimo 44 pt (iOS) / 44–48 dp (Android) e CTA principal de tela cheia 56–58 px (46 px no botão compacto `TESTAR AGORA` do Hero na Home). Raios (Decisão 126): 8 px para mídia e métricas (`sm`), 12 px para campos de busca, cartões compactos e CTAs (`md`/`lg`), 26 px para bottom sheet (`xl`) e pill (999 px) para pílulas concisas de status e tab bar flutuante. Sem bordas/contornos marcados em cards, busca, pílulas ou anúncios; elevação e contraste de superfície definem a hierarquia (Decisão 128).

## Layout

No mobile (iOS e Android), a navegação tem **4 destinos** (`Início`, `Jogos`, `Histórico`, `Ajustes`/`Configurações` — Decisões 80 e 98). Os títulos das telas são sempre em caixa alta:

- **Início (Decisões 132 e 144):** Hero full-bleed ocupando toda a largura e subindo até o topo atrás da barra de status, com gradiente direto para `#0B0D10` (carrossel com até 3 jogos testados recentemente ou `home_hero_default`) e botão sólido `TESTAR AGORA` (`#7C3AED`, altura 46, raio 12). Logo abaixo do Hero fica a barra de busca padronizada; em seguida `SEUS FAVORITOS` e `POPULARES` em grade fixa **2 linhas × 3 colunas** (`3:4`, até 6 jogos) com a frase `"Toque no jogo para iniciar o teste"` abaixo do título.
- **Jogos (Decisão 145):** título `JOGOS` em caixa alta, mesma barra de busca padronizada da Home e catálogo em **grade de 3 colunas** (`3:4`).
- **Histórico (Decisão 143):** título `HISTÓRICO` em caixa alta, filtros sem `#7C3AED` e bloco único de estabilidade da conexão (curva de ping traçada apenas com `>= 3` checks válidos por segmento de rede/região + 4 anéis `Ping méd`, `Jitter`, `Perda` e `Sob carga` + contagem separada de inconclusivos) acima da lista de sessões.
- **Resultado e Detalhes:** o veredito é o protagonista imediato; em detalhes (`DETALHES` / `DETALHES TÉCNICOS`), entram score, métricas, série temporal, rota e recomendações.
- **Anúncio nativo (`NativeAdSlot`, Decisão 144):** apenas em `Início`, `Jogos`, `Histórico` e `Resultado` concluído válido, sempre como faixa horizontal compacta (~88–96 px), sem `MediaView` grande e sem contorno.

## Componentes

- **Wordmark:** `wordmark-primary.svg` (Decisão 124), "Lagcheck" com o símbolo L + check: "Lag" branco e "check" em degradê roxo; usar em superfícies escuras. As variantes `wordmark-mono-*` e `lagcheck-wordmark-light.svg` ainda são da marca anterior.
- **Símbolo:** `lagcheck-mark.svg`, "L" roxo com faixas de velocidade, check branco e órbita com dois nós.
- **Ícone do app:** `app-icon-source.svg`, o símbolo oficial sobre o fundo grafite com brilho roxo embaixo, gerado por `shared/scripts/generate-brand-icons.py`.
- **Botão primário:** Roxo Gamer (`#7C3AED`), cantos `12 px`, alto contraste e sombra de ação, sem halo ou anel externo duplo (Decisões 126 e 144). Um por viewport para a mesma ação.
- **Botão secundário/atalho:** superfície neutra sem contorno marcado; nunca compete com o primário.
- **Barra de busca:** idêntica em `Início`, `Jogos` e seleção de favoritos — superfície `#15181E`, cantos `12 px`, altura mínima `46`, sem linha de contorno e sem sombra.
- **Pill de telemetria:** estado curto com ponto de status e texto mono.
- **Linha de catálogo/histórico:** divisória ou contraste de superfície, capa neutra `3:4` e contexto técnico; sem cards redundantes.
- **Bottom sheet:** confirmação, plataforma e escolha contextual; alça, raio superior amplo e scrim.
- **Veredito:** display grande + texto interpretativo + métricas apenas quando observadas.
- **Métricas e evidência:** superfícies discretas, valores mono e rótulo claro. Ausência de leitura fica explícita.

## Motion / Movimento e interação

Os protótipos usam `cubic-bezier(.2, 0, 0, 1)`. Pressão dá escala de até `.98`; menus e toasts entram entre 150–200 ms; sheets sobem em 250 ms. Progresso e pacotes só expressam uma medição realmente em andamento. Respeitar `prefers-reduced-motion`: reduzir transições e remover pacotes animados. Todo foco visível usa anel claro de 3 px com deslocamento de 3 px.

## Voice / Voz

Português brasileiro, direto e sem prometer além da leitura: “Pronto para Ranked”, “Eu evitaria Ranked agora”, “Condições instáveis”, “Inconclusivo”. Chamar o teste de **check** e dar motivo quando interrompido. Não inventar banda, rota, perda ou conclusão saudável se a medição não existe.

## Plataformas

O sistema vale para iOS, Android e Windows (prévia). Os valores de referência estão em `tokens/*.json`; como cada plataforma os implementa e onde diverge está em [`tokens/platforms.json`](tokens/platforms.json).

| | iOS | Android | Windows (WinUI 3) |
| --- | --- | --- | --- |
| Código dos tokens | `apps/ios/Sources/NolaggyDesign/Tokens/` | `apps/android/core/designsystem/src/main/kotlin/com/lagcheck/core/designsystem/theme/` | `apps/windows/LagCheck.WinUI/Styles/Theme.xaml` |
| Cores, espaçamento, raio | Tokens completos (`NLColor`, `NLSpacing`, `NLRadius`) | `LagCheckColors`, `LagCheckSpacing`, `LagCheckRadius` | Tokens próprios em `Theme.xaml` (cantos e profundidade alinhados ao Android) |
| Fonte | Barlow Semi Condensed (títulos), Barlow (corpo), Chakra Petch (métricas) | Barlow Semi Condensed (títulos), Barlow (corpo), Chakra Petch (métricas) | Barlow Semi Condensed (títulos), Barlow (corpo), Chakra Petch (métricas) |
| Alvo mínimo | 44 pt | 48 dp na maioria, 44 dp em alguns | 40–44 px no mouse, 44 px no toque |
| Navegação | 4 abas: Início, Jogos, Histórico, Configurações | 4 abas: Início, Jogos, Histórico, Configurações | Sem barra lateral: atalhos no topo da Início (Biblioteca, Histórico, Galeria, Busca, Ajustes) e seta de voltar |

Em conflito, a ordem é: decisão registrada em `docs/DECISOES.md`, depois `tokens/*.json`, depois o código. O Windows WinUI 3 tem documento próprio em [`apps/windows/DESIGN.md`](../../apps/windows/DESIGN.md) (a prévia anterior em Compose Desktop segue em [`docs/09-design-system-windows.md`](../../docs/09-design-system-windows.md)).

**Texto terciário** é `#606873` nas três plataformas (aprovado em 7/nov/2026). Contraste de 3,45:1 sobre o fundo, abaixo do mínimo de 4,5:1 para texto pequeno; usar só em metadados e rótulos de apoio, nunca para informação essencial.

**Cores de terceiros** (WhatsApp, Discord, Telegram, Instagram, X, TikTok) e o violeta do ícone do app são exceções e ficam só em `LagCheckBrandColors` (Android) e `NLBrandColor` (iOS). Não use cor solta em telas. Todas as divergências da Decisão 117 estão resolvidas.

## Anti-patterns / Anti-padrões

- Não usar a cor da marca (`#7C3AED`) fora do CTA principal da tela (proibido em fundo amplo, ações secundárias ou decoração); não usar Coral Solar como CTA comum.
- Evitar cardlização: não transformar cada bloco em card nem aplicar glassmorphism.
- Não usar linhas de contorno em cards e pílulas: preferir profundidade e contraste de superfície no lugar de bordas marcadas.
- Não exagerar no arredondamento dos cantos: manter raios contidos e proporcionais ao componente.
- Usar artes dos jogos obtidas da CDN das lojas (via API do LagCheck no iOS/Android e direto das lojas no Windows), nunca versionadas no repositório; não usar arte de jogo como fundo da tela de medição em andamento.
- Não fazer resultado inconclusivo parecer bom ou preencher métricas ausentes.
- Não inferir banda/canal Wi-Fi a partir de SSID, BSSID, RSSI ou ausência de dados.
- Não repetir CTA primário no mesmo viewport, nem esconder ações destrutivas sem confirmação.
