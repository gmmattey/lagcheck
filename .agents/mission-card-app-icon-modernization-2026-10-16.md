# Cartão de Missão — LagCheck

## Modernização do ícone do app (iOS e Android)

### Enquadramento

- **Problema da pessoa:** o ícone atual (glifo roxo de uma cor sobre preto liso) parece chapado e datado ao lado dos ícones atuais da Home e da loja. Quem procura um app de jogo não vê profundidade, material nem identidade de "cockpit esportivo" antes de abrir.
- **Resultado esperado observável:** iOS e Android com ícone moderno, com profundidade e luz, que lê bem em 60 px, e que segue os formatos recomendados de cada plataforma. Luiz confirmou que a modernização é necessária.
- **Fora de escopo:** mudar wordmark, paleta de tokens, mascotes da Decisão 83, nome do app, ficha de loja e qualquer publicação. Nenhum upload ao App Store Connect ou Play Console.
- **Lane:** Exploração (rotas de conceito) → Full flow comum (implementação após decisão do Luiz).
- **Por que esta lane:** é só ativo visual e configuração de recursos dos dois clientes. Não mexe em domínio, persistência, Worker nem motor UDP.
- **Decisão/fonte de verdade:** Decisão 83; `docs/04-design-system.md` (status dos ativos de marca); `design-system/assets/app-icon/`; `design-system/assets/brand/`.

### Donos e fronteiras

- **Responsável pela entrega:** Renan (conceito e assets). Rian (integração em Xcode e Android).
- **Aceite operacional de produto:** Giam.
- **Estratégia, prioridade e escalonamento ao Luiz:** Marco.
- **Revisores obrigatórios:** Breno (QA em simulador, emulador e aparelhos).
- **Decisão pendente do Luiz:**
  1. Conceito: refinar o glifo atual com profundidade, ou trocar por joystick/controle. Escolher após a exploração.
  2. Aprovação do ativo final, que vira nova decisão em `docs/DECISOES.md` e atualiza `docs/04` e `AGENTS.md`.
- **Mudança sistêmica / Architecture Plan:** não.

### Rota escolhida (Luiz, 16/10/2026)

- **R1, glifo modernizado**, para iOS **e** Android. O joystick (R3) e as demais rotas ficam descartadas por ora. Prancha da exploração fica no scratchpad da sessão, fora do repositório.
- **Refino pedido:** traço mais grosso e curvas simplificadas para sobreviver em 29 px; contraste no iOS Tinted; monocromático do Android como silhueta limpa na zona segura de 66 dp; luz e brilho roxo na base do fundo mantidos.
- **Teste A/B adiado:** 314 impressões no período inspecionado não bastam para Product Page Optimization nem Store Listing Experiments. A escolha é por critério de design e leitura em miniatura. Reavaliar quando houver tráfego.

### Exploração (Renan, sem alterar ativos oficiais)

Rotas a apresentar, 3 a 4, cada uma avaliada em 1024, 60 px e 29 px:

1. **Glifo atual modernizado:** mesmo elo, com camadas, gradiente interno, luz de borda e brilho sutil.
2. **Elo + controle fundidos:** direcional ou stick com leitura de conexão.
3. **Joystick arcade** (alavanca com bola): silhueta própria, longe de console conhecido.
4. **Gamepad minimalista:** só como contraponto.

Critérios de escolha: legibilidade em 60 px, distinção frente a ícones genéricos de controle, comunicar jogo e conexão, coerência com Dark Competitive UI (`#0B0D10`, Roxo Gamer `#7C3AED`, Coral reservado), sem silhueta que remeta a console de terceiros.

### Conformidade técnica (vale para qualquer rota)

- **iOS:** master 1024 sem transparência e sem cantos arredondados embutidos (o sistema aplica a máscara). Variantes Dark e Tinted. Avaliar formato em camadas (Icon Composer) para iOS 26. O alvo mínimo continua iOS 17, então o ícone convencional precisa existir.
- **Android:** adaptativo com primeiro plano 108 dp e conteúdo na zona segura de 66 dp, ícone monocromático para Material You, preservando o seletor de ícones da Decisão 83.
- **Lojas:** ícone 1024 (App Store) e 512 (Play) derivados do mesmo master.

### Aceite e evidência

| Critério observável | Dono da prova | Evidência exigida | Estado |
| --- | --- | --- | --- |
| Luiz escolhe o conceito entre as rotas | Giam / Luiz | painel comparativo em 1024, 60 e 29 px | pendente |
| Ícone lê bem em 60 e 29 px e em fundo claro e escuro do launcher | Renan | captura em simulador e emulador | não validado |
| iOS: sem alpha, Dark e Tinted corretos | Rian / Breno | build e captura no simulador | não validado |
| Android: zona segura, monocromático e themed corretos, seletor da Decisão 83 intacto | Rian / Breno | emulador e launchers reais (Pixel, Samsung One UI) | não validado |
| Ativos antigos preservados até a aprovação | Giam | `git diff` sem alterar `design-system/assets/` oficial antes da decisão | pendente |

### Handoff e encerramento

- **Próximo passo e dona/o:** Renan entrega o painel comparativo das rotas. Luiz escolhe. Depois Giam registra a decisão, e Rian e Breno implementam e validam.
