---
name: priscila-design-system-ux
description: Diretrizes de design, UX/UI, tokens semânticos, acessibilidade e auditoria visual da Priscila para plataformas Apple, Android e Web.
---

# Skill: priscila-design-system-ux

Esta skill guia a **Priscila** na definição de jornadas, fidelidade de protótipos e auditoria visual.

## 1. Princípios de Experiência
- **Protagonismo do Dado:** O número medido, o mapa ou o status são a estrela. Zero ornamentos vazios, zero "card soup" ou sobreposição de caixas desnecessárias.
- **Ergonomia por Plataforma:**
  - **iPhone / Mobile:** Área de alcance do polegar, navegação limpa, sem elementos minúsculos.
  - **iPad:** Aproveitamento real da largura de tela e multitarefa, sem apenas esticar a tela do celular.
  - **Mac:** Janela nativa redimensionável, menus, sidebar, barra de ferramentas e atalhos de teclado.
  - **Web:** Responsividade fluida, carregamento instantâneo e densidade visual equilibrada.

## 2. Design System & Tokens
- **Cores & Camadas Tonais:** Hierarquia visual construída por elevação de superfícies (base, raised, overlay) e não por bordas pesadas.
- **Tipografia:** Uso das fontes nativas do sistema (SF Pro / Roboto / Inter) com escala proporcional e `.monospacedDigit()` em números de telemetria.
- **Dark Mode First-Class:** Contraste impecável em temas escuros e claros sem perder a identidade da marca.

## 3. Acessibilidade (A11y) Inegociável
- **Conformidade WCAG AA:** Relação mínima de contraste de 4.5:1 para textos normais.
- **Dynamic Type:** Todos os textos escalam com as preferências do sistema.
- **Independência de Cor:** Nenhuma informação depende exclusivamente de cor; use ícones (SF Symbols) e rótulos textuais claros.
- **Alvos de Toque:** Mínimo de 44 × 44 pt para todos os botões e nós interativos.

## 4. Auditoria Visual
- Compare a tela real aberta com o protótipo canônico.
- Audite todos os estados: vazio (empty state), carregando (loading), resultado bem-sucedido, erro e modais.
- Se o Camillo encontrar um caso de borda não previsto, a especificação volta para alinhamento antes do código.

## 5. Windows (protótipo interno, Decisões 114 a 116)
- A referência visual é `design-system/prototypes/windows-premium/` (HTML) e `docs/09-design-system-windows.md`; o código é Compose Desktop em `android/desktop/`. Tokens idênticos aos do Android; fonte Google Sans Flex embarcada; métricas em mono.
- **Sem pill arredondada:** estado e veredito usam marcador com barra lateral colorida e texto mono em caixa alta. **Sem card por bloco, sem vidro:** seções separadas por linha fina; sombra só no botão principal e no toast.
- Tiles de jogo usam apenas as artes editoriais já aprovadas (Decisão 44), com degradê de leitura e o nome do jogo como identificação primária. O mapa só anima pacotes durante medição real; "Reduzir movimento" remove pacotes, pulsos e transições.
- Capturas de revisão: `./gradlew :desktop:shots` (a partir de `android/`); confira Início, Jogos, Check, Resultado, Histórico, Ajustes e a galeria `--ds` em 1120×740 e 900×600.
