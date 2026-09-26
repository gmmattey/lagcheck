# 52 — Decisão de marca: Dual-Node Vector e Wordmark Kinetic Speed Slant

**Status:** decidido pelo Dono do Produto (Luiz); em implementação  
**Data:** 25 de setembro de 2026  
**Responsáveis:** Luiz (Dono do produto), Marco (Produto), Renan (Design), Rian (Engenharia iOS)  
**Substitui:** Decisão 25 (Pulse Gauge) no símbolo, app icon e wordmark  
**Alinhamento Estratégico:** Decisões 50 (Ready for Ranked) e 51 (Dark Competitive UI)

---

## 1. Contexto e Motivação

Com a aprovação das Decisões 50 e 51 — que reposicionaram o LagCheck para a jornada competitiva *Ready for Ranked* e estabeleceram a estética **Dark Competitive UI** inspirada no benchmark do NoPing —, a identidade visual preliminar definida na Decisão 25 (*Pulse Gauge*) tornou-se anacrônica com o produto real:

1. **Eliminação da Herança do Velocímetro:** O anel circular de 270 graus do Pulse Gauge remetia a velocímetros de banda larga residencial (Speedtest, Fast.com). Como a UI interna eliminou medidores de NOC para priorizar o veredito semântico e telemetria viva, o ícone circular estava desalinhado da tela do app.
2. **Superação do Checkmark Passivo:** O checkmark tradicional lembrava apps de produtividade e listas de tarefas, em vez de um selo de prontidão de alta performance gamer.
3. **Tipografia sem Pegada Esports:** A wordmark anterior em SF Pro Display limpo carecia de agressividade, tracking tenso e personalidade de software competitivo.

---

## 2. Decisões Tomadas

### 2.1 Novo Símbolo Oficial: Dual-Node Vector
Dentre as opções exploradas com base no benchmark de alta performance (NoPing), o Dono do Produto (Luiz) aprovou a proposta **Dual-Node Vector**:
- **Conceito Técnico de Produto:** O LagCheck mede a integridade do caminho entre dois nós essenciais — o iPhone do jogador e o datacenter do jogo. O símbolo é formado por **duas lâminas poligonais geométricas e dinâmicas** com chanfros em 45°:
  - A **lâmina superior** representa o feixe de transmissão (origem / dispositivo do jogador).
  - A **lâmina inferior** representa a rota de resposta confirmada (destino / servidor de partida).
  - A interação espacial entre as lâminas projeta um vetor ascendente de confirmação supersônica (*check* em alta velocidade).
- **Sem Círculos ou Gauges:** O símbolo é puramente poligonal, veloz e de alto impacto, comunicando corte de atraso, baixa latência e prontidão competitiva.

### 2.2 Nova Wordmark: Kinetic Speed Slant
Aprovada a direção tipográfica **Kinetic Speed Slant**:
- **Grafia:** Mantida estritamente em minúsculas: **`lagcheck`** (conforme regra do `AGENTS.md`).
- **Inclinação e Dinâmica:** Ângulo frontal de velocidade (*speed slant* a 14°), transmitindo aceleração e resposta instantânea.
- **Cortes Angulares a 45°:** Todas as terminações de hastes (`l`, `g`, `h`, `k`) e aberturas (`c`, `e`) possuem chanfros técnicos esportivos, inspirados na tipografia industrial de produtos como NoPing e equipamentos de esports.
- **Cores Oficiais no Lockup:**
  - `lag`: Titânio branco puro (`#F4F5F7`), peso *Heavy*, sólido.
  - `check`: **Coral Solar vibrante** (`#FF5A36` com gradiente sutil a `#FFAB2E`), peso *Heavy*, destacando o veredito/ação.
  - Símbolo Dual-Node Vector posicionado à esquerda no lockup horizontal oficial.

### 2.3 App Icon Oficial
- **Master 1024x1024:** Fundo quase preto profundo (`#0B0D10`), microborda hairline em `rgba(255, 255, 255, 0.08)`.
- **Glifo Central:** O **Dual-Node Vector** em Coral Solar com facetas chanfradas tridimensionais sutis, halo térmico escuro contido e alto contraste visual em qualquer tamanho de tela (de 20pt na busca Spotlight a 1024pt na App Store).

---

## 3. Ativos e Arquivos Atualizados

1. **Vetores Canônicos de Marca (`design-system/assets/brand/` e `web/assets/brand/`):**
   - `app-icon-source.svg`: Master vetorial 1024x1024 com o Dual-Node Vector.
   - `symbol-compact.svg`: Símbolo compacto das lâminas em Coral Solar.
   - `wordmark-primary.svg`: Lockup horizontal oficial `[Dual-Node Vector] lagcheck` (Kinetic Speed Slant).
   - `wordmark-mono-dark.svg`: Versão monocromática escura para superfícies claras.
   - `wordmark-mono-light.svg`: Versão monocromática clara para fundos pretos.

2. **Conjuntos de Imagens no Xcode (`Sources/NolaggyApp/Assets.xcassets/`):**
   - `AppIcon.appiconset/`: Renders em alta definição em todas as escalas (20@2x/3x, 29@2x/3x, 40@2x/3x, 60@2x/3x, 1024x1024).
   - `WordmarkPrimary.imageset/`: Render PNG transparente de alta resolução da nova wordmark para o header da Home e onboarding.

---

## 4. Impacto e Governança

- **Marca & Identidade:** A marca continua sendo **LagCheck** (wordmark `lagcheck`). A mudança é puramente de símbolo, tipografia e atitude visual.
- **Tokens de Cor:** Preservada a paleta Coral Solar (`#FF5A36`, `#FF3823`, `#FFAB2E`).
- **Validação:** Assets renderizados e testados nos targets de compilação sem warnings ou quebras.
