# LagCheck Windows — Adaptação Desktop (WinUI 3)

Este documento define **o que muda no Windows** em relação ao núcleo compartilhado em [shared/design-system/DESIGN.md](../../shared/design-system/DESIGN.md). Tudo o que é identidade de marca, paleta Dark Competitive, tríade tipográfica, mapa de medição, voz do produto e anti-padrões vale igual aqui e não é repetido neste arquivo.

- **Fonte viva dos tokens e fontes no WinUI 3:** [`Styles/Theme.xaml`](LagCheck.WinUI/Styles/Theme.xaml) e [`Controls/Typography.cs`](LagCheck.WinUI/Controls/Typography.cs) (em conflito, prevalece `docs/DECISOES.md`, depois `shared/design-system/`).
- **Motor compartilhado:** medições reais em UDP via `DiagnosticEngineClient` e `ILibraryBridge` (Decisão 119). Nunca simular leitura ou biblioteca.

---

## 1. O que é característico do Windows (sem descaracterizar o LagCheck)

No PC, o LagCheck atua como **launcher gamer com cockpit de telemetria integrado**. As adaptações abaixo existem para respeitar janela larga, mouse e teclado, mantendo o veredito na frente dos detalhes e a Regra do Discord:

- **Sem catálogo próprio:** exibe somente os títulos instalados no PC (Steam, Epic Games, Xbox / PC Game Pass e executáveis locais), além do contexto **Este PC** para Check Geral.
- **Artes puxadas da CDN das lojas:** capas, banners e logos dos jogos instalados são obtidos em tempo de execução direto da CDN das lojas (Steam, Epic, Xbox) para cache local do usuário — seguindo a mesma linha de iOS e Android, que recebem as artes das lojas via API do LagCheck — nunca entrando no repositório ou no instalador. O escurecimento fica restrito à base e ao canto inferior esquerdo onde há texto, sem lavar a imagem.
- **Botão de jogar sempre acessível:** nenhuma medição bloqueia o início de um jogo instalado.
- **Evitar cardlização:** conteúdo, listas, métricas e detalhes vivem direto sobre o fundo ou separados por espaço e hierarquia tipográfica, sem encaixotar cada bloco em um card.
- **Profundidade no lugar de contorno:** cards, widgets e pílulas não usam linhas de contorno para se separar; a separação vem de contraste de superfície e profundidade/elevação (`Theme.xaml`).
- **Somente o CTA principal leva a cor da marca:** o Roxo Gamer (`#7C3AED`) fica reservado ao CTA principal da tela (`JOGAR AGORA` / `Testar agora`). Ações secundárias, filtros e controles auxiliares usam superfícies neutras.
- **Cantos sem exagero no arredondamento:** usar raios contidos e consistentes com o sistema (`8` a `16 px`), evitando cantos exagerados ou formas excessivamente arredondadas em cards e botões.
- **Movimento único:** transições (`Fluid` / `Motion`) respeitam a preferência de movimento reduzido do app e do Windows.

---

## 2. Navegação e Arquitetura de Telas

A navegação é **sem barra lateral**: o conteúdo ocupa toda a janela. No topo esquerdo fica a marca (que volta para a Início) ou o botão de voltar; no topo direito da Início ficam os atalhos para **Biblioteca**, **Histórico**, **Galeria**, **Buscar** (`Ctrl+F`) e **Ajustes**. `Esc`, `Alt+Seta` e o botão voltar do mouse retornam.

| Tela | Papel no fluxo do Windows |
| --- | --- |
| **Início** (`HomePage`) | Abre no último jogo selecionado (ou `Este PC`). Trilho de instalados no topo, Hero no canto inferior esquerdo (plataforma, título/logo, último veredito + ping, `JOGAR AGORA`, `Testar conexão`, detalhes e favorito) e grade personalizável de widgets à direita. |
| **Biblioteca** (`LibraryPage`) | Coleção local completa com busca (`Ctrl+F`), ordenação, filtros por launcher/estado, tag de veredito e início rápido (`▶`). |
| **Detalhes do Jogo** (`GameDetailsPage`) | Capa imersiva no topo com ações imediatas; abaixo em duas colunas: descrição, capturas e atualizações da loja à esquerda; ficha técnica, resumo de estabilidade da rede (com medidores em anel) e histórico do jogo à direita. |
| **Galeria** (`GalleryPage`) | Exibe somente capturas locais reais encontradas no PC. |
| **Conexão** (`DiagnosticPage`) | Cockpit de telemetria em três estados: Repouso (mapa de datacenters), Medição (numeral ao vivo e fases reais) e Resultado (veredito, métricas, evidência de rota, Voz/Streaming/NAT, servidores, copiar resultado e `JOGAR AGORA` quando contextual). |
| **Histórico** (`HistoryPage`) | Filtro por escopo (geral ou por jogo), card de estabilidade da rede com gráfico e medidores em anel, busca e tabela de sessões. |
| **Ajustes** (`SettingsPage`) | Layout em duas colunas (categorias à esquerda, opções à direita): Tela e janela (`F11`), Aparência e idioma (`Sistema`, `PT-BR`, `EN`, `ES`), Jogos e imagens, Privacidade e rede, Atualizações e Sobre. |

---

## 3. Regra de manutenção deste arquivo

Para este documento não envelhecer a cada ajuste visual:
- **Entram aqui:** mudança de navegação, tela nova/removida, regra específica de desktop ou exceção em relação ao `shared/design-system/DESIGN.md`.
- **Não entram aqui:** códigos hex repetidos, número de versão estático, tamanhos em pixels ou inventário de botões — isso mora no próprio XAML e em `Theme.xaml`.
