# LagCheck — Decisão 47: Progressão Visual Imersiva com Pulse Gauge Coral Solar durante a Medição

**Status:** Decisão aprovada pelo Dono do Produto (Luiz); em especificação e implementação  
**Data:** 25 de setembro de 2026  
**Autores / Revisores:** Luiz (Dono do Produto), Marco (Produto), Renan (Design), Iury (Rede), Rian (iOS)  
**Revisa e complementa:** `docs/01-funcional.md`, `docs/04-design-system.md`, `docs/07-voz-do-produto.md`, `docs/archive/decisoes/34-decisao-trilha-viva-medicao-e-estresse.md`, `docs/archive/decisoes/36-decisao-check-completo-wifi-e-rede-movel.md`, `docs/archive/decisoes/43-decisao-jornada-unica-deep-check.md`, `docs/archive/decisoes/46-reconciliacao-jornada-deep-check.md`

---

## 1. Contexto e Motivação de Produto (Luiz e Marco)

A decisão 36 estabeleceu a trilha de 5 nós verticais durante a medição ativa (`MeasurementLiveTrail`). Embora essa estrutura tenha eliminado ruídos de telemetria desnecessários (números pulando, gráficos oscilantes e scores antecipados), ela introduziu um efeito colateral indesejado na experiência do usuário:
1. **Percepção técnica excessiva:** Rótulos como "Ping", "Perda" e "Sob carga" dispostos em lista vertical remetem a painéis de diagnóstico de redes e telecomunicações (sysadmin/TI), distanciando o app da linguagem e mentalidade do jogador.
2. **Sensação de congelamento / pouca dinamicidade:** Durante os 30 segundos de medição (15s repouso + 15s carga), badges estáticos como "Medindo" e "Monitorando" passam a falsa impressão de que a tela travou, aumentando a ansiedade da espera.
3. **Subutilização da marca:** O LagCheck tem como elemento de assinatura visual o **Pulse Gauge Coral Solar**, mas durante o momento mais crítico da experiência (a execução do teste) exibia uma lista árida de verificação.

O Dono do Produto aprovou a transição para a **Opção 1: Experiência Centralizada com Pulse Gauge Coral Solar**, priorizando imersão visual, dinamismo orgânico e tradução humanizada do progresso do teste.

---

## 2. Direção de Design e Comportamento Visual (Renan)

A nova interface de medição ativa substitui a lista de verificação técnica por uma composição editorial e dinâmica no padrão Apple Games HIG:

### 2.1 Hero Central: Pulse Gauge Coral Solar Dinâmico
- **Núcleo Pulsante:** Um gauge central com anéis concêntricos suaves em Coral Solar (`NLColor.accentPrimary` / `#FF6B35`), que pulsam de forma orgânica e contínua.
- **Transpiração de Conexão:** As ondas se expandem suavemente em direção às bordas, transmitindo a sensação de que o sinal está ativamente transitando entre o iPhone e a nuvem.
- **Adaptação à Fase sob Carga:** Na fase sob pressão (carga HTTP de 10 MB), o núcleo ganha densidade visual e um pulso mais enérgico, comunicando visualmente a sobrecarga da rede sem precisar de textos alarmistas.
- **Acessibilidade (`accessibilityReduceMotion`):** Se a pessoa tiver redução de movimento ativada no iOS, o pulso contínuo é substituído por anéis fixos com gradiente suave e respiração lenta de opacidade.

### 2.2 Indicador de Etapas da Partida (Progresso em 2 Fases)
Uma barra de progresso horizontal e elegante divide a jornada em dois momentos claros do jogo:
1. **Etapa 1: Conexão Base** *(Repouso — 0% a 50%)*
2. **Etapa 2: Conexão sob Pressão** *(Sob Carga — 50% a 100%)*

O preenchimento acompanha o volume de amostras recebidas de forma fluida (`.smooth(duration: 0.35)`).

### 2.3 Microcopy Humanizado e Contextual
Em vez de expor jargões de telecomunicações ("Ping", "Perda de pacotes", "Sob carga"), a tela apresenta mensagens calmas e focadas na experiência da partida:

| Momento da Execução | Fase Técnica | Copy Apresentado ao Jogador |
| :--- | :--- | :--- |
| Início do Repouso | Probes UDP 1–10 | *"Conectando à rota de [Região]..."* |
| Meio do Repouso | Probes UDP 11–30 | *"Avaliando a rapidez dos comandos..."* |
| Início da Carga | Início da Carga HTTP + UDP | *"Simulando partida com tráfego intenso..."* |
| Meio/Fim da Carga | Carga HTTP ativa + UDP | *"Testando estabilidade sob pressão..."* |

### 2.4 Contexto Sutil da Rota (Rodapé Editorial)
No rodapé da tela, uma indicação minimalista e tipada em uma única linha substitui a antiga lista de 5 nós:
- Ícone do meio de conexão (`wifi` ou `antenna.radiowaves.left.and.right`) + `"Wi-Fi"` / `"Rede móvel"`
- Indicador de direção sutil (`arrow.right`)
- Ícone de destino (`mappin.and.ellipse`) + Nome amigável da região (ex.: `"São Paulo"`).

---

## 3. Diretrizes de Engenharia e Integridade de Medição (Iury e Rian)

1. **Zero Falsificação:** Toda animação do Pulse Gauge é governada por eventos reais do ciclo da sessão (`samples.count`, fase atual e recebimento de probes). Não há animações falsas desconectadas da pilha de rede.
2. **Silêncio Técnico Preservado:** Permanece estritamente proibido exibir números de milissegundos pulando, contadores numéricos de perda de pacotes, gráficos oscilantes ou notas antecipadas durante o teste. O score e as métricas consolidadas só aparecem na tela de resultado.
3. **Cancelamento Imediato:** Qualquer troca de rede (Wi-Fi ➔ Celular ou Celular ➔ Wi-Fi), background ou cancelamento pelo usuário aborta imediatamente a medição, descarta amostras parciais e reseta a interface.
4. **Consentimento Móvel Intacto:** A exigência de consentimento prévio com teto de 10 MB em redes celulares permanece inalterada antes do disparo de qualquer probe ou carga.
5. **Arquitetura Modular:** A evolução do componente visual ocorre no módulo `NolaggyDesign` sob a assinatura evoluída de `MeasurementLiveTrail` / `MeasurementPulseGauge`, integrando-se nativamente a `DeepCheckFeatureView` e `MeasurementProgressView`.

---

## 4. Critérios de Aceite

1. **Visual:** A tela exibe o Pulse Gauge Coral Solar central, a barra de progresso em 2 etapas e mensagens contextuais de jogo. A tabela/checklist de 5 nós técnicos foi removida da tela de medição ativa.
2. **Acessibilidade:** Suporte completo a Dynamic Type, VoiceOver e redução de movimento (`Reduce Motion`).
3. **Estabilidade:** Execução suave a 60/120 fps sem congelamento de UI ou sobrecarga na thread de medição UDP.
