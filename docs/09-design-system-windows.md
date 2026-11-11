# LagCheck — Design System e Especificação Desktop do Windows

> **Status:** Protótipo interno de referência (Decisões 114, 115 e 116 de `docs/DECISOES.md`). Não é alvo oficial de distribuição ampla; cada publicação exige autorização explícita do Luiz.
> **Fonte visual obrigatória e canônica:** `DESIGN.md` e `index.html` de `/Users/giammattey/Open Design/lagcheck-web-ds-82b1/`, em paridade com as marcas oficiais em `sites/lagcheck/src/assets/brand/`.
> **Protótipo visual de referência:** `design-system/prototypes/windows-premium/index.html`.
> **Implementação nativa Compose Desktop:** `android/desktop/` (reaproveitando o `core` de medição UDP do Android).

> **Atualização (Decisão 118):** a Home do Windows passou a ser a biblioteca de jogos instalados, e o diagnóstico é contextual ao jogo e não bloqueante. Onde este documento descreve a Home como painel de leitura de partida, vale a Decisão 118 até a Etapa 6 reescrever esta especificação.

---

## 1. Princípios e Direção Visual

O Lagcheck para Windows adota o mesmo sistema visual escuro, sóbrio e técnico do produto web e mobile nativo. A interface foi desenhada para o jogador de PC no lobby entre partidas, mantendo a **Regra do Discord**: toda informação na tela deve ser traduzível para uma frase curta falada entre amigos na call.

1. **Fundo escuro, técnico e sóbrio:** Foco na informação de rota e estabilidade. Sem estética de cassino gamer, sem HUD ornamental, sem anéis orbitais, sem neon, sem vidro espelhado (glassmorphism) e sem halos ou auroras de fundo.
2. **Hierarquia inegociável:**
   - **1. Leitura da partida (Veredito):** o que a medição significa para o jogo agora, em até 2 linhas;
   - **2. Métricas reais:** Repouso, Jitter, Sob carga (Load Delta) e Perda UDP em faixa contínua;
   - **3. Evidência de rota:** Região de referência, cidade de partida aproximada e limites do teste;
   - **4. Recomendação prática:** Próximo passo proporcional sem promessa milagrosa.
3. **Métrica é medição, não troféu:** Algarismos monoespaçados tabulares (Chakra Petch). Travessão (`—`) explícito quando não houver dado coletado; nunca preencher com `0 ms` ou "Estável" falso.
4. **Sem cardização excessiva (Card Soup):** Agrupamento contínuo com divisores de 1px hairline (`rgba(244, 245, 247, 0.10)`). Um card só existe para seletores isolados, evidência inseparável ou cards de jogos na biblioteca.
5. **Uma única ação primária por etapa:** CTA de 56px de altura, roxo plano (`#7C3AED`), raio de 12px e rótulo com verbo direto no infinitivo (ex: "Iniciar diagnóstico", "Testar novamente"), sem ícones de play ou setas (`→`).

---

## 2. Tokens de Cor e Função

Todos os valores em hexadecimal são canônicos e idênticos aos de `DESIGN.md`:

| Token | Hex | Função na Interface Desktop | Onde usar | Onde NÃO usar |
| :--- | :--- | :--- | :--- | :--- |
| `--stage` | `#060709` | Fundo externo e barra de título | Moldura externa da janela e titlebar nativa | Cards, textos ou áreas de leitura |
| `--deep` | `#0B0D10` | Fundo principal de leitura | Palco central (`main`), tela de medição e mapa | Gradientes decorativos ou texturas |
| `--surface` | `#15181E` | Superfície funcional e seletor | Barra lateral ativa, cards de jogos, seletor de contexto | Fundo de títulos ou métricas individuais |
| `--panel` | `#1E232B` | Camada ativa e microcontroles | Controle selecionado, hover forte, caixas de status | Fundo geral da aplicação |
| `--line` | `rgba(244, 245, 247, 0.10)` | Hairline de divisão | Separadores sutis de seções e linhas de tabela | Bordas grossas ou ornamentais |
| `--line-strong`| `rgba(244, 245, 247, 0.16)` | Contorno de controle | Bordas de botões secundários, switches e inputs | Divisores normais de conteúdo |
| `--text-primary` | `#F4F5F7` | Decisões e números | Títulos, vereditos, numerais em Chakra Petch e CTA | Textos longos de apoio ou notas de rodapé |
| `--text-secondary`| `#8A93A0` | Contexto e explicações | Explicação de veredito, rota técnica, notas de métricas | Valores de destaque ou títulos |
| `--text-tertiary` | `#606873` | Metadados técnicos | Eyebrow técnico, timestamps, hash de build e rótulos | Textos essenciais de acessibilidade |
| `--purple` | `#7C3AED` | Ação primária e foco | Botão principal (CTA), foco de teclado, fase ativa | Gradientes decorativos ou cor de vitória |
| `--purple-light`| `#A78BFA` | Contorno de foco e acento | Anel de foco acessível (3px) e acento textual suave | Fundo de botões primários |
| `--ready` | `#22C55E` | Leitura favorável comprovada | Ponto de status, numeral e veredito positivo | Sinal isolado sem palavra explicativa |
| `--caution` | `#F59E0B` | Atenção contextual | Jitter alto, aumento sob carga, aviso para usar cabo | Decoração ou badge chamativo |
| `--coral` | `#FF5A36` | Erro, descarte ou risco | Falha de socket, gateway inacessível, erro crítico | Promoção, marketing ou alertas falsos |

---

## 3. Tipografia Oficial

Três famílias tipográficas com papéis estritamente separados:

| Papel | Família | Pesos | Tamanhos e Entrelinhas | Uso Exclusivo |
| :--- | :--- | :--- | :--- | :--- |
| **Corpo / UI** | **Barlow** | 400 (Regular), 500 (Medium), 600 (SemiBold) | 13–16 px / 1.5 | Parágrafos de apoio, labels de controles, botões e recomendações |
| **Títulos / Veredito** | **Barlow Semi Condensed** | 700 (Bold), 800 (ExtraBold) | H1: 32–38 px / 1.08; H2: 24–28 px; Veredito: 36–42 px (tracking `-0.015em`) | Veredito principal da partida, títulos de tela e nomes de jogo em cards |
| **Telemetria** | **Chakra Petch** | 600 (SemiBold) | 24–40 px / 1.0 (tabular-nums) | Valores de latência, jitter, variação sob carga, upload e perda UDP |
| **Técnica** | **Cascadia Mono** / `ui-monospace` | 600 (Bold) | 10–12 px / 1.2 (tracking `0.08em` a `0.1em`, caixa alta) | Eyebrow técnico, códigos de região (ex: `sa-east-1`), timestamps e status |

*Regra:* Chakra Petch nunca é usada em parágrafo. Barlow Semi Condensed nunca é usada em texto corrido de suporte. Texto técnico nunca é sublinhado nem leva gradiente.

---

## 4. Uso Correto da Marca Oficial no Windows

A marca oficial é rigorosamente protegida e não pode ser redesenhada, recriada em código ou contornada com fontes genéricas:

- **Wordmark oficial (`wordmark-primary.svg`):**
  - **Localização canônica:** `sites/lagcheck/src/assets/brand/wordmark-primary.svg`.
  - **Posicionamento:** Deve aparecer no topo esquerdo da janela, na barra de título nativa ou no cabeçalho superior.
  - **Dimensão recomendada:** Altura fixa entre 17 px e 20 px, preservando a proporção original (~4.9:1).
  - **Restrição:** Nunca aplicar gradiente, sombra ou contorno adicional por CSS/código. Os nós luminosos e o gradiente roxo já fazem parte do SVG original.
- **Símbolo oficial (`lagcheck-mark.svg`):**
  - **Localização canônica:** `sites/lagcheck/src/assets/brand/lagcheck-mark.svg`.
  - **Posicionamento:** Usado isolado exclusivamente como:
    1. Ícone da janela do Windows na barra de título (20×13 px ou 22×14 px);
    2. Ícone de barra de tarefas e instalador (.ico/.exe);
    3. Identificação compacta quando a janela for redimensionada para largura mínima.
  - **Restrição:** Proibido alterar suas cores, girar ou desmembrar as três faixas e a marca de verificação.

---

## 5. Arquitetura da Janela e Layout Desktop

- **Dimensões recomendadas:**
  - Janela padrão: **1120 × 740 px** (centralizada no monitor);
  - Janela mínima suportada: **960 × 600 px**;
  - Comportamento responsivo:
    - Acima de 1180 px: Barra lateral completa (224 px) + Palco central de leitura com margens confortáveis;
    - Entre 960 px e 1180 px: Barra lateral pode colapsar para modo compacto de 64 px (apenas ícones nativos) ou manter o cockpit em coluna única de 920 px.
- **Barra de Título (Native Titlebar):**
  - 42 px de altura, integrada ao shell (`--stage`), com área de arrasto nativa e botões padrão do Windows (Minimizar, Maximizar/Restaurar, Fechar);
  - Pílula central de contexto discreto: `ESTE PC · CONEXÃO GERAL` ou `NOME DO JOGO · REGIÃO`.
- **Barra Lateral de Navegação (Sidebar):**
  - Quatro destinos fixos: `Início`, `Jogos`, `Histórico`, `Ajustes`;
  - Indicador de item ativo com fundo `--surface`, borda fina `--line-strong` e ícone com tom acentuado `--purple-light`;
  - Rodapé da sidebar exibe estado local da placa de rede (`Ethernet` ou `Wi-Fi`) e versão do build.
  - **Regra inegociável de medição:** Durante o Check, a barra lateral fica **travada e desabilitada**. O usuário só pode clicar em "Cancelar análise", garantindo que nenhuma requisição concorrente ou troca de tela contamine as sondas UDP.

---

## 6. Especificação dos 6 Estados Obrigatórios

### Estado 1: Pronto (Lobby antes do check)
- **Objetivo:** O jogador acabou de abrir o app ou voltou ao lobby e quer saber se a conexão aguenta jogar.
- **Composição visual:**
  - Header com eyebrow "Diagnóstico em Tempo Real", título "Sua conexão aguenta a partida?" e subtítulo curto;
  - CTA primário em destaque: `Iniciar diagnóstico` (56 px, `--purple`, com foco roxo);
  - Seletor de contexto de jogo: Grade compacta com os 6 jogos mais jogados no PC (Valorant, CS2, Fortnite, LoL, etc.) em cards de `--surface` com 12 px de raio;
  - Telemetria do último check (se existente na sessão): Faixa contínua com Repouso, Jitter, Sob carga e Perda UDP em Chakra Petch;
  - Nota de transparência: "O teste mede a rota do seu PC até a infraestrutura de referência AWS mais próxima. Sem respostas suficientes, o resultado é inconclusivo."

### Estado 2: Medindo (Check em execução)
- **Objetivo:** Medição determinística ativa. Zero distrações, zero publicidade, foco na rota.
- **Composição visual:**
  - Trilha horizontal de etapas em 4 fases: `1. Conexão` → `2. Latência` → `3. Sob carga` → `4. Análise`;
  - Mapa de medição de rota plano: Projeção de pontos do globo (sem neons decorativos), destacando o pino "Você" e o pino da região AWS selecionada, com arco sutil (`#7C3AED`);
  - Overlay de fase: nome da fase ativa em Barlow Semi Condensed e contagem de sondas (ex: "Sonda UDP 6 de 12");
  - Telemetria ao vivo: Latência instantânea em destaque no canto do mapa (Chakra Petch grande) e faixa contínua abaixo com valores atualizando em tempo real;
  - Barra lateral travada: navegação desabilitada;
  - Ação única: Botão secundário `Cancelar análise` que aborta os sockets e descarta medições parciais.

### Estado 3: Resultado Bom (Conexão Boa / Pronto para Ranked)
- **Objetivo:** Informar com clareza matemática que a rede está sólida para o modo competitivo.
- **Composição visual:**
  - Veredito de impacto: Ponto verde + `● PRONTO PARA RANKED` em Barlow Semi Condensed 800 (verde `--ready`);
  - Subtítulo direto: "Sua conexão está estável. Latência base baixa e sem degradação perceptível sob tráfego concorrente."
  - Faixa contínua de métricas (4 colunas com divisores finos):
    - Repouso: `18 ms` (verde)
    - Jitter: `2 ms` (verde)
    - Sob carga: `+4 ms` (verde)
    - Perda UDP: `0%` (verde)
  - Painel de evidência lateral: Rota técnica `PC local → AWS sa-east-1 (São Paulo)` e achado dominante ("Estabilidade Preservada");
  - Acordeão recolhido com o ping real de todos os servidores candidatos da AWS;
  - Recomendação prática: "Sinal verde para partidas ranqueadas. Teste novamente se outra pessoa começar downloads pesados."
  - Ações: CTA primário `Testar novamente` (56 px) e link de texto utilitário `Copiar para o Discord`.

### Estado 4: Resultado Instável (Condições Instáveis / Atenção)
- **Objetivo:** Alertar sobre oscilação prejudicial antes que o jogador perca pontos na ranqueada.
- **Composição visual:**
  - Veredito de impacto: Marcador quadrado âmbar + `▲ CONDIÇÕES INSTÁVEIS` (âmbar `--caution`);
  - Subtítulo: "A rota apresentou variação sob carga. A resposta pode engasgar durante trocas de tiros intensas."
  - Faixa de métricas:
    - Repouso: `42 ms` (âmbar)
    - Jitter: `14 ms` (âmbar, variação alta)
    - Sob carga: `+38 ms` (âmbar, spike de fila / bufferbloat)
    - Perda UDP: `1.8%` (âmbar, descarte leve)
  - Achado dominante: "Fila e Saturação de Rádio: aumento expressivo de latência sob tráfego concorrente."
  - Recomendação prática: "Evite fila ranqueada agora. Conecte o cabo Ethernet e pause downloads em segundo plano (Steam/Epic) antes de jogar."
  - Ações: CTA primário `Repetir análise`.

### Estado 5: Inconclusivo / Indisponível (Sem dados suficientes)
- **Objetivo:** Honestidade radical de produto. Sem dados UDP válidos suficientes, nunca inventar score.
- **Composição visual:**
  - Veredito neutro: Círculo vazado cinza + `— LEITURA INCONCLUSIVA` (cinza `--text-secondary`);
  - Subtítulo: "Poucas sondas UDP retornaram eco válido. O Lagcheck não inventa pontuação quando a medição real é incompleta."
  - Faixa de métricas: Repouso `—`, Jitter `—`, Sob carga `—`, Perda UDP `> 60%`;
  - Diagnóstico: "As portas UDP de medição podem estar bloqueadas pelo firewall local ou a rota está sofrendo descarte em massa na operadora."
  - Recomendação prática: "Verifique se a sua conexão está ativa e tente novamente. Se o problema persistir, confira as regras do firewall do Windows."
  - Ações: CTA primário `Tentar novamente`.

### Estado 6: Erro de Rede (Falha de socket / Conectividade)
- **Objetivo:** Comunicar falha imediata de conectividade ou gateway inacessível sem quebrar o app.
- **Composição visual:**
  - Veredito em coral: Losango coral rotacionado + `▲ FALHA NA MEDIÇÃO` (coral `--coral`);
  - Subtítulo: "O adaptador de rede não conseguiu alcançar a infraestrutura de medição de referência."
  - Faixa de métricas técnicas: Status `SEM RESPOSTA`, Gateway `Inalcançável`, DNS `Não resolvido`, Tentativas `3x`;
  - Motivo técnico: `Socket Timeout (ErrCode: NET_ROUTE_UNREACHABLE)`;
  - Recomendação prática: "Reinicie o adaptador de rede ou aguarde a estabilização da conexão da operadora antes de tentar novamente."
  - Ações: CTA primário `Tentar novamente`.

---

## 7. Componentes Reutilizáveis Desktop

1. **`TitlebarShell`:** Componente de topo com ícone vetorial (`lagcheck-mark.svg`), logotipo oficial (`wordmark-primary.svg`), chip de contexto e botões nativos de minimizar/maximizar/fechar.
2. **`NavigationSidebar`:** Trilho de destinos acessível com suporte a foco, bloqueio durante o teste e identificação da conexão de rede local no rodapé.
3. **`PrimaryButton`:** Altura de 56 px, raio de 12 px, roxo plano (`#7C3AED`), hover escurecido (`#8B5CF6`), sombra `0 6px 20px rgba(124, 58, 237, 0.35)`.
4. **`SecondaryButton`:** Altura de 44 px, contorno de 1 px (`--line-strong`), sem preenchimento, raio de 12 px.
5. **`MetricStrip`:** Grade contínua com hairlines de 1 px, Chakra Petch tabular para numerais e notas de 12 px logo abaixo.
6. **`RouteMapCanvas`:** Renderizador de mapa 2D em canvas com malha discreta de pontos, arcos quadráticos e sondas reais sem efeitos de neon.
7. **`SwitchControl`:** Trilho retangular de 44×24 px com indicador deslizante de 18×18 px, raio de 6 px, atendendo às diretrizes de controle do Windows 11.
8. **`HistoryRow`:** Linha tabular contínua para histórico com hover sutil e colunas monoespaçadas.

---

## 8. Acessibilidade e Interação por Teclado

- **Contraste:** Todas as cores de texto essencial respeitam a razão mínima WCAG AA de 4.5:1 sobre `--deep` e `--surface`.
- **Foco visível:** Controles focados recebem contorno duplo visível com `outline: 3px solid #A78BFA` e `outline-offset: 3px`.
- **Navegação por Teclado:**
  - `Ctrl + 1`: Início
  - `Ctrl + 2`: Jogos
  - `Ctrl + 3`: Histórico
  - `Ctrl + 4`: Ajustes
  - `Espaço` ou `Enter`: Aciona qualquer botão focado ou o CTA primário;
  - `Esc`: Cancela a medição em andamento se estiver na tela de medição.
- **Reduzir Movimento:** Quando ativado pelo sistema (`prefers-reduced-motion: reduce`) ou pela chave em Ajustes, remove imediatamente pulsos de sondas no mapa, animações de transição de tela e contadores progressivos, mantendo os estados estáticos legíveis.
