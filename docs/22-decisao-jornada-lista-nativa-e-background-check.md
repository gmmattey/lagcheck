# Nolaggy — decisão: jornada de lista nativa e Quick Check automático em background

**Status:** decisão aprovada pelo dono do produto (Luiz); em fase de especificação e implementação pelo time.  
**Data:** 17 de setembro de 2026  
**Substitui:** a jornada anterior de seleção prévia de jogo e início manual de medição na Home (`docs/01` §7.1, `docs/10` e protótipo canônico legado com vitrine horizontal/card soup).  
**Complementa:** `docs/21-decisao-direcao-visual-simplicidade.md` (simplicidade, sem firulas, sistema visual nativo e limpo).

---

## 1. O Problema e a Nova Proposta de Valor

Na jornada anterior, o usuário precisava abrir o app, encontrar e escolher um jogo, escolher plataforma/contexto e clicar em iniciar o Quick Check, aguardando 15 segundos antes de ter qualquer informação.

**Nova proposta de valor:**
Ao abrir o app, o Nolaggy começa a avaliar a qualidade da rede em background imediatamente. Em ~15 segundos, o usuário se depara com a lista completa de jogos populares já pontuada especificamente para os requisitos de cada jogo (thresholds individuais de latência, jitter e estabilidade).

---

## 2. Princípios da Nova Jornada

1. **Auto-check no Launch**: Inicia imediatamente uma medição Quick Check em background contra o beacon regional de referência (AWS GameLift `sa-east-1` no Brasil).
2. **Interface Nativa de 1 Coluna (iOS Standard)**: Uma `List` limpa do SwiftUI / NavigationStack, substituindo carrosséis horizontais, filtros e cards redundantes.
3. **Skeletons durante a Medição**: Durante os ~15s de medição, a lista apresenta os jogos com placeholders elegantes no lugar das notas e um status discreto no topo indicando *"Avaliando sua rede..."*.
4. **Cálculo Determinístico por Jogo**: Ao terminar o Quick Check, o app aplica as métricas brutas (RTT P50/P95, jitter, perda) contra as regras de cada título do catálogo, gerando um Nolaggy Score individual por jogo.
5. **Atualização Sob Demanda**: Suporte total a gesto de **Pull-to-refresh** e botão nativo de recarregar (`arrow.clockwise`) na Navigation Bar.
6. **Aprofundamento sob Demanda (Detalhes do Jogo)**: Tocar em um jogo abre a tela de detalhes com o veredito e métricas daquele jogo, oferecendo a opção de rodar o **Deep Check específico**.
7. **Deep Check Específico**: Tenta usar o beacon oficial do jogo se disponível (`gameOfficial`/`gameInfrastructure`); se não houver, utiliza a infraestrutura regional correspondente (`regionGameProxy`/`genericRegion`) com total transparência de confiança.

---

## 3. Comportamento e Estados de Tela

### 3.1 Home (Lista de Jogos)

- **Topo**:
  - Título do app (`nolaggy` em minúsculas).
  - Indicador sutil de status/progresso: *"Avaliando sua rede..."* com barra ou spinner discreto.
  - Ação no canto superior direito: botão nativo de refresh (`arrow.clockwise`).
- **Linha do Jogo (`GameRowView`)**:
  - Esquerda: Ícone neutro Nolaggy do jogo (`GameNeutralMark`) + Nome localizado + Badge de categoria/plataforma.
  - Direita: Score circular ou badge numérico no padrão do Design System (verde/âmbar/coral/cinza), ou shimmer/skeleton durante a análise.
- **Falha / Mudança de Conexão**:
  - Banner discreto no topo: *"Conexão alterada ou insuficiente para medição"*, com botão *"Tentar novamente"*.

### 3.2 Detalhes do Jogo (`GameDetailView`)

- Header com Nome do Jogo e Score grande (sem glow/halo neon, conforme `docs/21`).
- Veredito claro e amigável (conforme `docs/07-voz-do-produto.md`).
- Cartão de Métricas observadas: Latência estimada, Jitter e Perda de Pacotes.
- Ação Principal: Botão destacado *"Fazer Deep Check deste jogo"*.

### 3.3 Deep Check do Jogo

- Roda as etapas de repouso (15s) e carga HTTP (15s via Cloudflare Worker).
- Mira no beacon específico do jogo quando documentado no catálogo.

---

## 4. Responsabilidades do Time

- **Marco (Produto)**: Alinhamento de escopo, priorização dos 8 jogos e validação da experiência geral.
- **Renan (Design)**: Especificação dos componentes nativos (`GameRowView`, skeletons, tela de detalhes sem firulas) e tokens simplificados (`docs/21`).
- **Rian (iOS)**: Implementação no `NolaggyApp` e `NolaggyDesign`: orquestração do Quick Check no launch, view models reativos e navegação em NavigationStack.
- **Iury (Rede/Score)**: Validação da normalização do Quick Check multi-jogo (mesma amostra de RTT aplicada aos diferentes perfis/thresholds de jogos do catálogo).
