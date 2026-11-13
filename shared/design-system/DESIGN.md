# LagCheck Design System

## Contexto do produto

LagCheck é um diagnóstico competitivo para quem quer saber se a conexão está pronta para jogar. O sistema prioriza uma decisão rápida e honesta: o veredito vem antes dos detalhes; a evidência vem quando a pessoa precisa entender ou agir.

## Fundamentos visuais

O visual é escuro, calmo e técnico, sem cair numa caricatura gamer. A área de decisão respira; listas, rotas e métricas usam linhas finas, monoespaçado e densidade controlada. A identidade usa o wordmark oficial claro em superfícies escuras.

## Color / Cor

Os tokens canônicos em hex valem para iOS, Android, Windows e Web (ver [`tokens/platforms.json`](tokens/platforms.json)): fundo `--bg` (`#0B0D10`), superfície (`#15181E`), painel elevado (`#1E232B`), texto primário (`#F4F5F7`), texto secundário (`#8A93A0`), texto terciário (`#606873`), borda (`white` 8–16%), Roxo Gamer (`#7C3AED`), Coral Solar (`#FF5A36`), Âmbar (`#F59E0B`) e Verde (`#22C55E`). Não converter automaticamente de `oklch` antigos: `oklch(0.585 0.214 299)` resulta em `#9052e6`, não em `#7C3AED`. Roxo Gamer é reservado para ação, seleção, foco e progresso; Coral Solar serve a erro, risco ou ação destrutiva; Verde comunica resultado favorável e nunca substitui uma explicação textual.

## Typography / Tipografia

- Display: `--lc-font-display`, arredondada e compacta, para vereditos, nomes de jogo e títulos.
- Corpo: `--lc-font-body`, nativa Apple, para leitura e controles.
- Técnica: `--lc-font-mono`, para rota, métricas, tempo e contexto de rede.

As pilhas abaixo valem para o iOS e para os protótipos HTML. Android usa Google Sans Flex; Windows empacota Barlow, Barlow Semi Condensed e Chakra Petch, conforme o site (veja Plataformas e `tokens/typography.json`). As fontes Windows e suas licenças OFL ficam em `android/desktop/src/main/resources/fonts/`. As pilhas são observadas diretamente nos protótipos: `ui-rounded, 'Arial Rounded MT Bold', system-ui, sans-serif`; `-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif`; e `ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace`. Títulos de produto trabalham com tracking negativo; rótulos técnicos são pequenos, em caixa alta e com tracking positivo. Não usar mono para parágrafos.


### Tipografia do site (Web)

Esta diretriz é **exclusiva do site público** `lagcheck.signallq.com`, implementado em `gmmattey/landings/pages/lagcheck/`. Ela não substitui as escolhas nativas de iOS e Android, nem altera as cores ou o wordmark. Para o Windows, esta combinação foi aprovada como nova referência visual; a migração do app está pendente de empacotamento e testes.

| Papel | Família | Peso recomendado | Uso |
| --- | --- | --- | --- |
| Corpo | **Barlow** | 400–500 | Parágrafos, artigos, tutoriais, formulários e textos de orientação |
| Títulos | **Barlow Semi Condensed** | 700–800 | H1–H3, chamadas, destaques e títulos editoriais |
| Métricas | **Chakra Petch** | 600 | Valores e rótulos de ping, jitter, perda de pacotes e diagnósticos, onde houver dados medidos |
| Fallback | Pilha sans-serif do sistema | conforme componente | Leitura quando a fonte web não carregar |

**Regras de implementação web:**
- Centralizar as famílias em *custom properties* CSS, sem repetir configurações em páginas individuais. Aplicar as regras por papéis semânticos para que toda a home, páginas de jogos, ferramentas e páginas institucionais compartilhem a mesma tipografia.
- Usar Barlow em leitura longa; evitar Chakra Petch em parágrafos e evitar Barlow Semi Condensed em textos de leitura contínua.
- Preservar hierarquia, legibilidade e contraste no mobile (inclusive a 320 px); manter altura de linha adequada e controlar quebras de título e largura dos botões.
- Carregar apenas pesos e subconjuntos necessários em WOFF2, com `font-display: swap`, alternativas compatíveis e verificação de CLS/LCP. Não introduzir dependência de CDN obrigatória se o self-hosting for viável.
- Métricas devem continuar diferenciando valor observado, indisponível e inconclusivo. A fonte não é um sinal de estado; as cores semânticas e mensagens textuais continuam sendo a referência.
- Paleta oficial preservada: fundo `#0B0D10`, Roxo Gamer `#7C3AED` e variações aprovadas. Sem substituir a paleta por cores inspiradas em concorrentes.

**Fonte de implementação web:** `gmmattey/landings/pages/lagcheck/src/styles/global.css` e estilos compartilhados. Antes de publicar, verificar componentes com `font-family` explícita, conferir a renderização desktop/mobile e executar a suíte existente do site. A alteração desta documentação **não publica o site**.

## Mapa de medição

O mapa de medição mostra de onde o check sai e até qual região ele foi medido, espelhando a implementação web (`pages/lagcheck/src/lib/map/`):

- **Base e projeção:** grade de pontos Natural Earth 110m (1,5° por célula) em projeção equiretangular, fundo `--bg` (`#0B0D10`), pontos de terra em `--text-secondary` a 34% de opacidade. Plano, sem gradiente, brilho, halo ou onda expansiva.
- **Câmera e enquadramento:** `WORLD_CAMERA` (`lon = 0`, `lat = 12`, `zoom = 1`) durante a varredura e `fitCamera` com teto de `zoom <= 3.4` quando a rota é fechada (acima disso a grade de 1,5° perde o contorno dos continentes), garantindo que pinos e rótulos caibam sem corte.
- **Arcos e sondas reais:** arco quadrático de Bézier (`computeArc` / `bezierPoint`) em `--purple` (`#7C3AED`). Tudo que se move vem de medição real: saída fixa em `420 ms` (`620 ms` na varredura inicial com `45 ms` de escalonamento entre regiões) e volta proporcional ao RTT observado (`clamp(rttMs * 8, 300, 700)` ms) com easing cúbico simétrico.
- **Rótulos sem sobreposição:** apenas “Você” e a região escolhida (ou mais rápida na varredura) recebem rótulo, com detecção de colisão de caixas para nunca sobrepor nem sair da área útil.
- **"Você":** localização aproximada pelo IP no endpoint do site (`/v1/approx-location`, 0,5°), com rótulo "Você · Cidade"; a varredura espera por ela, como o `trySweep()` do site. Se falhar, os apps usam o país do aparelho; sem país, a nota "Localização aproximada indisponível".
- **Implementação nativa:** `RouteMapController` + `RouteMeasurementMapView` (`NolaggyDesign/Components/RouteMap/` no iOS) e `RouteMapController` + `RouteMeasurementMap` (`core/designsystem/components/map/` no Android), porta direta de `route-map.ts` (Decisão 123). Contêiner com raio 13, borda de 1 px, proporção 4:3 na medição e 16:10 no resultado.

## Espaçamento, forma e elevação

Base de 4 px. Conteúdo de tela usa 22 px nas laterais, controles usam no mínimo 44 px e CTA principal 56–62 px. Raios: 8 px para mídia e métricas, 13 px para campos/cartões compactos, 17 px para CTA, 26 px para bottom sheet e pill para estado conciso. Elevação só aparece em menu, toast, CTA e sheet.

## Layout

O shell é mobile-first: status, barra superior, conteúdo de decisão e indicador do sistema. Não há uma navegação persistente de destino para escolher jogo; a seleção é uma etapa transitória. A Home usa uma só ação primária. Em detalhes, o veredito continua presente e os dados entram por seções: score, métricas, série temporal, rota e recomendações.

## Componentes

- **Wordmark:** `wordmark-primary.svg` (Decisão 124), "Lagcheck" com o símbolo L + check: "Lag" branco e "check" em degradê roxo; usar em superfícies escuras. As variantes `wordmark-mono-*` e `lagcheck-wordmark-light.svg` ainda são da marca anterior.
- **Símbolo:** `lagcheck-mark.svg`, "L" roxo com faixas de velocidade, check branco e órbita com dois nós.
- **Ícone do app:** `app-icon-source.svg`, o símbolo oficial sobre o fundo grafite com brilho roxo embaixo, gerado por `shared/scripts/generate-brand-icons.py`.
- **Botão primário:** largura cheia na tela, roxo, alto contraste e sombra de ação. Um por viewport para a mesma ação.
- **Botão secundário/atalho:** transparente ou bordado; nunca compete com o primário.
- **Pill de telemetria:** estado curto com ponto de status e texto mono.
- **Linha de catálogo/histórico:** divisória, capa neutra e contexto técnico; sem cards redundantes.
- **Bottom sheet:** confirmação, plataforma e escolha contextual; alça, raio superior amplo e scrim.
- **Veredito:** display grande + texto interpretativo + métricas apenas quando observadas.
- **Métricas e evidência:** superfícies discretas, valores mono e rótulo claro. Ausência de leitura fica explícita.

## Motion / Movimento e interação

Os protótipos usam `cubic-bezier(.2, 0, 0, 1)`. Pressão dá escala de até `.98`; menus e toasts entram entre 150–200 ms; sheets sobem em 250 ms. Progresso e pacotes só expressam uma medição realmente em andamento. Respeitar `prefers-reduced-motion`: reduzir transições e remover pacotes animados. Todo foco visível usa anel claro de 3 px com deslocamento de 3 px.

## Voice / Voz

Português brasileiro, direto e sem prometer além da leitura: “Pronto para Ranked”, “Condições instáveis”, “Não foi possível avaliar com segurança desta vez”. Chamar o teste de **check** e dar motivo quando interrompido. Não inventar banda, rota, perda ou conclusão saudável se a medição não existe.

## Plataformas

O sistema vale para iOS, Android e Windows (prévia). Os valores de referência estão em `tokens/*.json`; como cada plataforma os implementa e onde diverge está em [`tokens/platforms.json`](tokens/platforms.json).

| | iOS | Android | Windows (prévia) |
| --- | --- | --- | --- |
| Código dos tokens | `Sources/NolaggyDesign/Tokens/` | `android/core/designsystem/src/main/kotlin/com/lagcheck/core/designsystem/theme/` | `android/desktop/src/main/kotlin/com/lagcheck/desktop/ds/Tokens.kt` |
| Cores, espaçamento, raio | Tokens completos (`NLColor`, `NLSpacing`, `NLRadius`) | `LagCheckColors`, `LagCheckSpacing`, `LagCheckRadius` | Tokens próprios |
| Fonte | SF arredondada, SF e SF mono | Google Sans Flex em tudo, números tabulares (Decisão 80) | Barlow Semi Condensed (títulos), Barlow (corpo), Chakra Petch (métricas), com fontes empacotadas |
| Alvo mínimo | 44 pt | 48 dp na maioria, 44 dp em alguns | 40 dp mouse, 44 dp toque |
| Navegação | 4 abas: Início, Jogos, Histórico, Configurações | 4 abas: Início, Jogos, Histórico, Configurações | Barra lateral: Início, Jogos, Histórico, Ajustes |

Em conflito, a ordem é: decisão registrada em `docs/DECISOES.md`, depois `tokens/*.json`, depois o código. O Windows tem documento próprio: [`docs/09-design-system-windows.md`](../docs/09-design-system-windows.md).

**Texto terciário** é `#606873` nas três plataformas (aprovado em 7/nov/2026). Contraste de 3,45:1 sobre o fundo, abaixo do mínimo de 4,5:1 para texto pequeno; usar só em metadados e rótulos de apoio, nunca para informação essencial.

**Cores de terceiros** (WhatsApp, Discord, Telegram, Instagram, X, TikTok) e o violeta do ícone do app são exceções e ficam só em `LagCheckBrandColors` (Android) e `NLBrandColor` (iOS). Não use cor solta em telas. Todas as divergências da Decisão 117 estão resolvidas.

## Anti-patterns / Anti-padrões

- Não usar roxo como fundo amplo, nem Coral Solar como CTA comum.
- Não transformar cada bloco em card nem aplicar glassmorphism.
- Usar apenas as capas editoriais oficiais do catálogo verificável; não usar arte de jogo como fundo da tela de medição em andamento.
- Não fazer resultado inconclusivo parecer bom ou preencher métricas ausentes.
- Não inferir banda/canal Wi-Fi a partir de SSID, BSSID, RSSI ou ausência de dados.
- Não repetir CTA primário no mesmo viewport, nem esconder ações destrutivas sem confirmação.
