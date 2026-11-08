# LagCheck Design System

## Contexto do produto

LagCheck é um diagnóstico competitivo para quem quer saber se a conexão está pronta para jogar. O sistema prioriza uma decisão rápida e honesta: o veredito vem antes dos detalhes; a evidência vem quando a pessoa precisa entender ou agir.

## Fundamentos visuais

O visual é escuro, calmo e técnico, sem cair numa caricatura gamer. A área de decisão respira; listas, rotas e métricas usam linhas finas, monoespaçado e densidade controlada. A identidade usa o wordmark oficial claro em superfícies escuras.

## Color / Cor

Os tokens vivem em [colors_and_type.css](colors_and_type.css). A origem declara `--bg: oklch(0.158 0.011 260)`, `--surface: oklch(0.205 0.012 260)`, `--fg: oklch(0.955 0.006 260)`, `--muted: oklch(0.675 0.014 260)`, `--border: oklch(0.302 0.014 260)` e `--accent: oklch(0.585 0.214 299)` no `brand-spec.md`. Roxo Gamer é reservado para ação, seleção, foco e progresso. Coral Solar (`oklch(0.684 0.196 35)`) serve a atenção ou destruição. O Verde (`oklch(0.76 0.15 150)`) comunica resultado favorável; não substitui uma explicação textual.

## Typography / Tipografia

- Display: `--lc-font-display`, arredondada e compacta, para vereditos, nomes de jogo e títulos.
- Corpo: `--lc-font-body`, nativa Apple, para leitura e controles.
- Técnica: `--lc-font-mono`, para rota, métricas, tempo e contexto de rede.

As pilhas abaixo valem para o iOS e para os protótipos HTML. Android e Windows usam Google Sans Flex (veja a tabela em Plataformas e `tokens/typography.json`). As pilhas são observadas diretamente nos protótipos: `ui-rounded, 'Arial Rounded MT Bold', system-ui, sans-serif`; `-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif`; e `ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace`. Títulos de produto trabalham com tracking negativo; rótulos técnicos são pequenos, em caixa alta e com tracking positivo. Não usar mono para parágrafos.

## Espaçamento, forma e elevação

Base de 4 px. Conteúdo de tela usa 22 px nas laterais, controles usam no mínimo 44 px e CTA principal 56–62 px. Raios: 8 px para mídia e métricas, 13 px para campos/cartões compactos, 17 px para CTA, 26 px para bottom sheet e pill para estado conciso. Elevação só aparece em menu, toast, CTA e sheet.

## Layout

O shell é mobile-first: status, barra superior, conteúdo de decisão e indicador do sistema. Não há uma navegação persistente de destino para escolher jogo; a seleção é uma etapa transitória. A Home usa uma só ação primária. Em detalhes, o veredito continua presente e os dados entram por seções: score, métricas, série temporal, rota e recomendações.

## Componentes

- **Wordmark:** `wordmark-primary.svg`, a peça oficial preservada com símbolo e “Check” em Roxo Gamer, enquanto “Lag” segue branco; usar em superfícies escuras. `assets/lagcheck-wordmark-light.svg` é o adaptador compatível para as telas preservadas.
- **Ícone do app:** `app-icon-source.svg`, o símbolo oficial refinado para a família roxa.
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
| Fonte | SF arredondada, SF e SF mono | Google Sans Flex em tudo, números tabulares (Decisão 80) | Google Sans Flex e Consolas |
| Alvo mínimo | 44 pt | 48 dp na maioria, 44 dp em alguns | 40 dp mouse, 44 dp toque |
| Navegação | 4 abas: Início, Jogos, Histórico, Configurações | 4 abas: Início, Jogos, Histórico, Configurações | Barra lateral: Início, Jogos, Histórico, Ajustes |

Em conflito, a ordem é: decisão registrada em `docs/DECISOES.md`, depois `tokens/*.json`, depois o código. O Windows tem documento próprio: [`docs/09-design-system-windows.md`](../docs/09-design-system-windows.md).

**Texto terciário** é `#606873` nas três plataformas (aprovado em 7/nov/2026). Contraste de 3,45:1 sobre o fundo, abaixo do mínimo de 4,5:1 para texto pequeno; usar só em metadados e rótulos de apoio, nunca para informação essencial.

**Cores de terceiros** (WhatsApp, Discord, Telegram, Instagram, X, TikTok) e o violeta do ícone do app são exceções e ficam só em `LagCheckBrandColors` (Android) e `NLBrandColor` (iOS). Não use cor solta em telas. Todas as divergências da Decisão 117 estão resolvidas.

## Anti-patterns / Anti-padrões

- Não usar roxo como fundo amplo, nem Coral Solar como CTA comum.
- Não transformar cada bloco em card nem aplicar glassmorphism.
- Não usar arte oficial de jogos; as capas preservadas são editoriais/neutras.
- Não fazer resultado inconclusivo parecer bom ou preencher métricas ausentes.
- Não inferir banda/canal Wi-Fi a partir de SSID, BSSID, RSSI ou ausência de dados.
- Não repetir CTA primário no mesmo viewport, nem esconder ações destrutivas sem confirmação.
