# LagCheck — decisão: jornada de lista nativa e Deep Check por jogo

**Status:** decisão aprovada pelo dono do produto (Luiz); em fase de implementação pelo time.
**Data:** 17 de setembro de 2026; revisada em 19 de setembro de 2026.
**Substitui:** a jornada anterior de seleção prévia de jogo e início manual de Quick Check na Home (`docs/01` §7.1, `docs/10` e protótipo canônico legado com vitrine horizontal/card soup).
**Complementa:** `docs/archive/decisoes/21-decisao-direcao-visual-simplicidade.md` (simplicidade, sem firulas, sistema visual nativo e limpo).

---

## 1. O Problema e a Nova Proposta de Valor

Na jornada anterior, o usuário precisava abrir o app, encontrar e escolher um jogo, escolher plataforma/contexto e iniciar uma leitura genérica antes de ter informação útil para a partida.

**Nova proposta de valor:**
O LagCheck abre pela pergunta que a pessoa quer responder: qual jogo e qual plataforma ela vai usar. A partir dessa escolha, inicia o Deep Check específico daquele contexto. Não existe mais uma etapa, CTA, tela ou resultado de Quick Check.

---

## 2. Princípios da Nova Jornada

1. **Escolha explícita de contexto**: A pessoa escolhe o jogo e, quando aplicável, a plataforma e o vínculo declarado do equipamento antes de medir.
2. **Interface Nativa de 1 Coluna (iOS Standard)**: Uma `List` limpa do SwiftUI / NavigationStack, substituindo carrosséis horizontais, filtros e cards redundantes.
3. **Estado de medição honesto**: Durante a leitura, o app mostra progresso discreto. Sem respostas UDP válidas suficientes, o resultado é inconclusivo e não exibe score nem recomendação para jogar.
4. **Cálculo Determinístico por Jogo**: Ao terminar o Deep Check, as métricas de repouso são avaliadas pelas regras do título e do contexto selecionados. O impacto sob carga é complementar e não recalcula o score principal.
5. **Atualização Sob Demanda**: A pessoa inicia uma nova medição pela ação principal do estado da Home ou pelo detalhe do jogo; não há atualização automática em background.
6. **Detalhes do Jogo**: Tocar em um jogo abre a tela de detalhes para escolher plataforma/contexto e iniciar o **Deep Check específico**.
7. **Deep Check Específico**: Tenta usar o beacon oficial do jogo se disponível (`gameOfficial`/`gameInfrastructure`); se não houver, utiliza a infraestrutura regional correspondente (`regionGameProxy`/`genericRegion`) com total transparência de confiança.

---

## 3. Comportamento e Estados de Tela

### 3.1 Home (Lista de Jogos)

- **Topo**:
  - Título do app (`lagcheck` em minúsculas na wordmark).
  - Indicador sutil de estado/progresso quando houver uma medição ativa.
  - Ação principal única: escolher um jogo no primeiro uso ou testar novamente uma observação existente.
- **Linha do Jogo (`GameRowView`)**:
  - Esquerda: ícone neutro do LagCheck + nome localizado + badge de categoria/plataforma.
  - Direita: a última observação válida daquele contexto, quando existir; sem score inventado quando não existir evidência.
- **Falha / Mudança de Conexão**: banner discreto com ação *"Tentar novamente"*.

### 3.2 Detalhes do Jogo (`GameDetailView`)

- Header com nome do jogo e observação válida disponível, sem glow/halo neon (conforme `docs/21`).
- Contexto de plataforma e vínculo declarado quando aplicável.
- Ação principal: botão destacado *"Fazer Deep Check deste jogo"*.

### 3.3 Deep Check do Jogo

- Roda as etapas de repouso (15s) e carga HTTP (15s via Cloudflare Worker).
- Mira no beacon específico do jogo quando documentado no catálogo.

---

## 4. Responsabilidades do Time

- **Marco (Produto)**: Alinhamento de escopo, priorização dos 8 jogos e validação da experiência geral.
- **Renan (Design)**: Especificação dos componentes nativos (`GameRowView`, tela de detalhes sem firulas) e tokens simplificados (`docs/21`).
- **Rian (iOS)**: Implementação no `NolaggyApp` e `NolaggyDesign`: escolha de contexto, orquestração do Deep Check e navegação em `NavigationStack`.
- **Iury (Rede/Score)**: Validação do Deep Check por contexto e dos critérios determinísticos de resultado.
