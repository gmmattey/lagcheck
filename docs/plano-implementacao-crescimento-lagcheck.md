# Plano de Implementação Geral — Viralidade, Aquisição e Diferenciação LagCheck

> **Orquestração:** Marco (Product Lead)  
> **Especialistas:** Renan (Design), Rian (iOS), Iury (Network), Camillo (Arquiteto Sistêmico), Breno (QA)  
> **Status:** Proposta da Squad para Validação do Dono do Produto (Luiz)

---

## 1. Visão Geral e Princípios Inegociáveis

Todas as 9 iniciativas seguem estritamente os pilares fundamentais do LagCheck:
1. **Custo Operacional Recorrente Zero:** Nenhuma dependência de APIs pagas, servidores adicionais ou SDKs terceiros invasivos. Toda a inteligência e renderização rodam on-device ou sobre o Worker gratuito existente (`nolaggy-deep-check`).
2. **Diretriz "Gamer Não Lê" (Decisão 64):** Nenhuma tela sobrecarregada ou didática em excesso. Cockpit esportivo de alto contraste, tipografia monoespaçada tática e a *Regra do Discord*: tudo deve ser traduzível para uma frase curta falada no meio da call.
3. **Integridade Diagnóstica (Decisões 50 e 72):** O veredito do app é determinístico e soberano. Não inventamos notas, não usamos fallbacks inseguros (HTTP/ICMP) e não acusamos operadora ou roteador sem probe isolado comprovado.

---

## 2. Faseamento Estratégico

```mermaid
flowchart LR
    subgraph Fase 1 [Fase 1: Onda P0 — Aquisição e Viralidade Imediata]
        A[Item 2: ASO Tático de Busca]
        B[Item 1: Card Viral Squad Pass]
        C[Item 3: Bufferbloat Score Tático]
    end

    subgraph Fase 2 [Fase 2: Onda P1 — Diferenciação e Retenção]
        D[Item 4: Ping Real por Datacenter]
        E[Item 5: Isolador de Causa Raiz]
        F[Item 6: Widgets Interativos iOS 17]
    end

    subgraph Fase 3 [Fase 3: Onda P2 — Ecossistema e Fricção Zero]
        G[Item 7: In-App Events Sazonais]
        H[Item 8: Siri Shortcuts & Spotlight]
        I[Item 9: App Clip Instantâneo]
    end

    Fase 1 --> Fase 2 --> Fase 3
```

---

## 3. Fase 1: Onda P0 — Lançamento e Aquisição Imediata

### Item 2: ASO Tático de Dor Gamer & Metadados da App Store
- **Objetivo:** Capturar o tráfego de busca de jogadores frustrados com lag sem gastar com anúncios pagos.
- **Responsáveis:** Marco (Estratégia/Copy) e Renan (Screenshots táticos da loja).
- **Módulos Afetados:** Metadados no App Store Connect e Assets de Marketing.
- **Passos de Execução:**
  1. **Nome do App & Subtítulo:**
     - *Nome:* `LagCheck — Teste de Ping & Lag`
     - *Subtítulo (30 caracteres):* `Ping Real para Jogos e Ranked`
  2. **Campo de Palavras-Chave (100 caracteres otimizados):**
     - `ping,lag,valorant,fortnite,cs2,bufferbloat,jitter,perda de pacote,wifi gamer,speed test,packet loss`
  3. **Screenshots da App Store (Dark Competitive UI):**
     - Tela 1: *"Pronto pra Ranked?"* (Hero com o badge verde neon e 14ms).
     - Tela 2: *"Ping Real nos Servidores do Jogo"* (AWS GameLift, Riot, Valve).
     - Tela 3: *"Detector de Bufferbloat"* (Mostra quando a conexão engasga sob carga).
     - Tela 4: *"Zero VPN, Zero Assinatura"* (Destaque de privacidade e gratuidade).
- **Critérios de Aceite:** Metadados validados contra guidelines da Apple (sem infração de copyright de terceiros) e aprovados por Marco e Luiz.

---

### Item 1: Card Viral "Squad Pass / Ready Check" (Discord / WhatsApp / Stories)
- **Objetivo:** O jogador que mede a conexão compartilha o resultado visualmente com 1 toque no grupo do Discord ou WhatsApp para provar se pode ou não puxar fila.
- **Responsáveis:** Renan (Design do Card) e Rian (Implementação SwiftUI `ImageRenderer`).
- **Módulos Afetados:** `NolaggyDesign` (Componente visual), `NolaggyApplication` (Presenter) e `App` (Share Sheet / Clipboard).
- **Desenho Técnico & Arquitetura:**
  - Uso nativo de `ImageRenderer` (iOS 16+), gerando uma imagem PNG compacta em memória (sem gravar arquivo desnecessário no disco).
  - O botão de ação rápida oferece duas ações diretas: **"Copiar Imagem pro Discord"** (copia PNG diretamente para o Pasteboard do iOS) e **"Compartilhar"** (`ShareLink`).
- **Layout do Card (Cockpit Esportivo 1080x1350 ou 1200x630):**
  - Fundo grafite profundo (`#0B0D10`), bordas finas de 1px com glow sutil na cor do veredito.
  - Header: Logo `lagcheck` + Jogo selecionado (ex: *Valorant · São Paulo*).
  - Centro: Veredito em fonte bold esportiva (`● PRONTO PARA RANKED` ou `▲ EVITARIA RANKED AGORA`).
  - Métricas táticas em cockpit monoespaçado: Latência P50, Jitter, Perda de Pacotes e Nota de Bufferbloat.
  - Rodapé: Badge discreto *"Medição UDP real · lagcheck.app"*.
- **Critérios de Aceite:** Cópia instantânea para a área de transferência (< 200ms); colagem impecável no Discord/WhatsApp; renderização sem travamento de UI (`@MainActor`).

---

### Item 3: Bufferbloat Score Tático (Ping sob Carga / Grade A a F)
- **Objetivo:** Transformar a métrica da Fase 3 de estresse (`/v1/load`) em uma nota instantânea e compreensível que explica por que a conexão fica instável quando outros usam a rede.
- **Responsáveis:** Iury (Fórmula & Guardrails no Domínio), Renan (Visual da Nota) e Rian (Integração).
- **Módulos Afetados:** `NolaggyDomain` (`QualityMetrics`, `GameReadinessVerdict`), `NolaggyDesign`.
- **Regra de Negócio (Domínio Puro):**
  - Mede a diferença de latência: $\Delta RTT = RTT_{carga} - RTT_{repouso}$.
  - **Classificação Bufferbloat:**
    - **Grade A+ / A:** $\Delta RTT \le +5\text{ ms}$ (Roteador gerencia fila com perfeição - SQM/FQ-CoDel).
    - **Grade B:** $+6\text{ ms} \le \Delta RTT \le +15\text{ ms}$ (Variação leve, jogável sem teletransporte).
    - **Grade C:** $+16\text{ ms} \le \Delta RTT \le +35\text{ ms}$ (Degradação perceptível ao atirar/esquivar).
    - **Grade D / F:** $\Delta RTT > +35\text{ ms}$ (Bufferbloat severo; spike brutal sob uso simultâneo).
- **Exibição na UI:**
  - Pílula monoespaçada na tela de resultado: `BUFFERBLOAT: GRADE A (+3ms)`.
- **Critérios de Aceite:** Testes unitários puros no `NolaggyDomain` cobrindo todos os limites de $\Delta RTT$; cálculo 100% determinístico sem oscilação artificial.

---

## 4. Fase 2: Onda P1 — Diferenciação e Retenção

### Item 4: Ping Real por Datacenter de Jogo (GameLift, Riot, PlayFab, Valve)
- **Objetivo:** Consolidar a medição UDP real contra os endereços oficiais dos jogos mais jogados no Brasil/Mundo.
- **Responsáveis:** Iury (Calibração de Beacons & Codecs UDP) e Camillo (Governança de Contratos).
- **Módulos Afetados:** `NolaggyInfrastructure` (`UdpProbeTransport`, codecs de rede) e `worker/catalog/`.
- **Passos de Execução:**
  1. Revisão e atualização do catálogo remoto assinado (v3) com clusters ativos no Brasil (`sa-east-1` AWS, servidores Riot Direct em SP, Azure PlayFab SP, Valve CS2 SP).
  2. Fallback determinístico de rota: se o endpoint primário falhar, o motor utiliza o beacon regional AWS neutro com sinalização de confiança `.medium` (Decisão 55).
- **Critérios de Aceite:** 30 probes enviados em rajada controlada; conformidade estrita de RFC sem vazar descritores de sockets; rejeição de endpoints inacessíveis sem travar a interface.

---

### Item 5: Isolador de Causa Raiz ("De Quem é a Culpa?")
- **Objetivo:** Resolver a dúvida se o problema é o Wi-Fi do quarto, a rota da operadora ou o servidor do jogo que caiu.
- **Responsáveis:** Iury (Rede/Gateway) e Camillo (Gate Arquitetural).
- **Módulos Afetados:** `NolaggyInfrastructure` (Gateway probe local), `NolaggyDomain` (Interpretação).
- **Lógica Diagnóstica (Sem Acusar Sem Prova):**
  - **Probe 1 (Local):** Mede latência até o gateway da rede local (Roteador/AP).
    - Se $RTT_{gateway} > 15\text{ ms}$ ou jitter alto $\rightarrow$ **"Gargalo no seu Wi-Fi/Sinal Local"**.
  - **Probe 2 (Operadora/Rota):** Mede até o primeiro salto da WAN / Cloudflare Anycast.
    - Se Gateway está limpo ($< 2\text{ ms}$) mas Rota varia brutalmente $\rightarrow$ **"Instabilidade na Rota da Operadora"**.
  - **Probe 3 (Status do Jogo):** Consulta rápida e gratuita do status de plataformas oficiais (PSN, Xbox Live, Riot Status).
    - Se servidores estão sob manutenção $\rightarrow$ **"Servidores do Jogo em Alerta"**.
- **Critérios de Aceite:** Proibido disparar falso positivo; isolamento estrito em threads secundárias com timeout de 800ms.

---

### Item 6: Widgets Interativos & Lock Screen (iOS 17+)
- **Objetivo:** Criar um ritual diário pré-game: o jogador vê o status da conexão na tela de bloqueio antes mesmo de sentar na cadeira.
- **Responsáveis:** Renan (Design do Widget) e Rian (WidgetKit & App Intents).
- **Módulos Afetados:** Novo target `NolaggyWidgetExtension` e App Group para leitura do último snapshot SwiftData.
- **Especificação dos Widgets:**
  - **Lock Screen Circular / Retangular:** Badge mínimo `SP: 16ms ● OK`.
  - **Home Screen Small:** Card grafite com nome do jogo favorito, RTT P50 e botão interativo (App Intent) com ícone de *Refresh* para rodar re-check em background.
  - **StandBy Mode:** Modo noturno/mesa com relógio e telemetria de rede de alto contraste.
- **Critérios de Aceite:** Widget atualiza de forma eficiente via `WidgetCenter.shared.reloadTimelines()` sem drenar bateria; dados lidos de forma segura e imutável via App Group.

---

## 5. Fase 3: Onda P2 — Ecossistema e Fricção Zero

### Item 7: In-App Events Sazonais na App Store
- **Objetivo:** Ganhar tração editorial orgânica e aparecer na aba *Hoje* da App Store durante grandes eventos de games.
- **Responsáveis:** Marco (Calendário Editorial) e Renan (Assets Apple HIG).
- **Módulos Afetados:** App Store Connect (sem código no cliente).
- **Execução:**
  - Cadastrar eventos no App Store Connect sincronizados com calendários públicos:
    - Exemplo: *"Início de Nova Season de Ranked"* (Março/Julho/Novembro).
    - Chamada: *"Sua conexão aguenta a subida de elo? Cheque sua rota antes da primeira partida da season."*
- **Critérios de Aceite:** Submissão de banners de acordo com as especificações rígidas da Apple (sem logotipos protegidos de terceiros, usando estética autoral LagCheck).

---

### Item 8: Spotlight Search & Siri Shortcuts
- **Objetivo:** Permitir que o jogador pesquise no iPhone ou pergunte à assistente sem navegar por menus.
- **Responsáveis:** Rian (App Intents & CoreSpotlight).
- **Módulos Afetados:** `NolaggyApplication` (Intents).
- **Funcionalidades:**
  - Registro de App Shortcuts: *"E aí Siri, verificar conexão no LagCheck"*.
  - Indexação no Spotlight: Ao digitar "ping", "valorant", "lag" ou "ranked" na busca do iOS, o LagCheck aparece como atalho de ação rápida.
- **Critérios de Aceite:** Execução de medição disparada por intent concluída com sucesso em background ou abrindo diretamente a tela de veredito.

---

### Item 9: App Clip Instantâneo (Fricção Zero no Discord/Lobby)
- **Objetivo:** Um amigo manda no Discord: `lagcheck.app/check?game=valorant`. O outro clica no iPhone e abre instantaneamente o App Clip em 2 segundos para testar o ping na call, sem precisar baixar o app completo na App Store.
- **Responsáveis:** Camillo (Gate Arquitetural & Tamanho de Binário), Rian (Target App Clip) e Breno (QA de Empacotamento).
- **Módulos Afetados:** Novo target `LagCheckClip` (< 15 MB descompactado) e `web/.well-known/apple-app-site-association`.
- **Restrições Arquiteturais:**
  - Compartilha estritamente `NolaggyDomain`, `NolaggyInfrastructure` e `NolaggyDesign`.
  - Exclui persistência local pesada (SwiftData completo) e histórico longo.
  - Tela única: Executa o check direto e exibe o veredito + banner nativo *"Baixe o app completo para histórico e widgets"*.
- **Critérios de Aceite:** Binário final abaixo do limite de 15 MB da Apple; Universal Links funcionando diretamente a partir de cliques no Discord e Safari.

---

## 6. Governança, QA e Próximos Passos (Camillo & Breno)

| Frente | Ação Imediata | Responsável |
| :--- | :--- | :--- |
| **QA (Breno)** | Montar plano de testes automatizados para `ImageRenderer` (Item 1) e vetores de Bufferbloat (Item 3). | Breno |
| **Arquitetura (Camillo)** | Validar que o `ImageRenderer` e o cálculo de Bufferbloat não tocam no ciclo de vida de rede nem adicionam custos. | Camillo |
| **Design (Renan)** | Entregar o layout do Card Viral esportivo em 2 proporções (1:1 e 9:16 para Stories). | Renan |
| **iOS (Rian)** | Preparar o branch da Fase 1 conectando os metadados de ASO e a UI do Card Viral. | Rian |
| **Produto (Marco)** | Submeter o plano ao Luiz para fechamento de prioridades. | Marco |
