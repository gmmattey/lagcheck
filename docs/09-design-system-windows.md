# LagCheck — Design System e Navegação do Windows (protótipo)

> **Status:** protótipo interno (Decisão 114). Não é alvo oficial. Código em `android/desktop/`.
> Herda a **Dark Competitive UI** (`docs/04-design-system.md`). Aqui só entra o que muda no desktop.

## 1. O que não muda
Tokens de cor (`#0B0D10`, `#15181E`, `#1E232B`, Roxo `#7C3AED`, Coral `#FF5A36`, verde/âmbar/cinza semânticos), dark mode exclusivo, borda de 1 px, números monoespaçados, veredito com símbolo + texto + cor, regra do Discord (uma frase curta por informação), sem "card soup". Fonte da verdade no código: `ds/Tokens.kt`.

## 2. O que muda no desktop
| Tema | Mobile | Windows |
| --- | --- | --- |
| Navegação | Tab bar `Início | Jogos` | Barra lateral de 232 dp: Início, Jogos, Histórico, Ajustes. Histórico sobe para a barra porque há espaço. |
| Largura | 1 coluna | Conteúdo até 920 dp, centralizado; Início mantém um cockpit em coluna única para o Check continuar sendo o protagonista. |
| Entrada | Toque | Mouse + teclado: hover em todo item clicável, foco visível (anel 2 dp roxo claro), Tab/Enter/Espaço. |
| Alvo mínimo | 44 pt | 40 dp com mouse, botões 44 dp. |
| Marca, arte e ícones | Wordmark, artes editoriais e ícones nativos do app | Reutiliza os ativos locais aprovados do Android: wordmark oficial, artes editoriais autorais e a mesma linguagem de ícones. Sem download ou criação de arte. |
| Tipografia | Google Sans Flex | Segoe UI (sistema) e Consolas para dados. Sem fonte embarcada no protótipo. |
| Janela | Tela cheia | 1120×740, mínimo 900×600. |
| Durante o Check | Sem anúncio | Barra lateral travada (uma sessão por vez); só "Cancelar" sai, descarta tudo. |

## 3. Componentes (`ds/Components.kt`)
`Interactive` (base: hover, foco, desabilitado), `PrimaryButton` (roxo), `SecondaryButton` (contorno), `Panel`, `SectionLabel`, `PageHeader`, `MetricTile`, `VerdictHeadline`, `StatusChip`, `SidebarItem`, `ListRow`, `EmptyState`, `CircularGauge` (anel; pulsa em repouso, parado com "Reduzir movimento"), `LatencyChart` (linha, picos ≥ 80 ms em âmbar, marcador de início da carga), `SearchField` e `GameArtwork` (somente arte editorial local aprovada, com fallback neutro).
Galeria viva: `./gradlew :desktop:run --args="--ds"`. Ela é interna e só aparece nesse modo, nunca na navegação normal. Capturas sem janela: `./gradlew :desktop:shots` (gera `android/desktop/build/shots/`).

## 4. Telas e fluxo
`Início → (Jogo) → Check → Resultado → Histórico`. A Início abre com a pílula honesta `ESTE PC · CONEXÃO GERAL`, seguida do anel "TESTAR" (Conexão geral), último Check em uma linha sem card e uma faixa de até quatro jogos com `VER TODOS`; a arte editorial local cria o contexto de jogo sem disputar a ação principal. Não afirma Wi-Fi, banda ou adaptador que o protótipo não observa. Jogos lista só o que o catálogo assinado libera para PC (hoje 40), com sua miniatura editorial local quando disponível. Resultado: veredito, Ping/Jitter/Perda, gráfico e ações. Histórico vive só na sessão e mostra miniatura apenas para jogo com ativo local compatível.

## 5. Fora do protótipo (pendente)
Português/inglês (hoje só PT-BR), persistência do histórico, anúncio e consentimento, leitura do adaptador/Wi-Fi, acessibilidade validada com Narrator, DPI/escala do Windows, ícone do app e instalador assinado. Regra de score específica para PC exige decisão própria (Decisão 114, pendências).
