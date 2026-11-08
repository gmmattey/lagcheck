# LagCheck — Decisão 34: Trilha Viva de Medição e Diagnóstico Visual de Estresse (Quick Check e Deep Check)

**Status:** Decisão aprovada pelo Dono do Produto (Luiz); em especificação técnica e implementação  
**Data:** 18 de setembro de 2026  
**Autores / Revisores:** Luiz (Dono do Produto), Marco (Produto), Renan (Design), Iury (Rede), Rian (iOS)  
**Complementa:** `docs/01-funcional.md`, `docs/02-arquitetura.md`, `docs/03-especificacao-tecnica.md`, `docs/04-design-system.md`, `docs/07-voz-do-produto.md`, `docs/archive/decisoes/10-decisao-experiencia-piloto.md`, `docs/archive/decisoes/12-decisao-deep-check-piloto.md`, `docs/archive/decisoes/24-decisao-adocao-design-system-apple-games.md`, `docs/archive/decisoes/25-decisao-marca-lagcheck-coral-solar.md`, `docs/archive/decisoes/27-decisao-diagnostico-frequencia-wifi.md`

---

## 1. Contexto e Motivação de Produto (Marco)

Durante as sessões ativas de medição (Quick Check e fases de repouso/carga do Deep Check), o usuário era exposto a um anel de progresso circular (`MeasurementPulse`) com um número de RTT isolado e um gráfico linear de série temporal (`LatencyGraph`).

Apesar de tecnicamente acurado, esse padrão apresenta duas limitações de produto:
1. **Abstração excessiva:** O usuário leigo não entende intuitivamente o significado de um número em milissegundos pulando na tela nem uma linha oscilando.
2. **Falta de clareza sobre a origem do gargalo:** Quando a conexão oscila ou engasga sob carga, o gráfico mostra que a latência subiu, mas não explica *onde* ocorreu o problema (se foi no Wi-Fi dentro da casa ou na rota externa da internet).

### Diretrizes Inegociáveis de Honestidade Técnica:
* **Fidelidade à telemetria real:** O app só pode desenhar nós e trechos que são efetivamente aferidos pela camada de rede. O iOS não permite `traceroute` nem RAW sockets; portanto, **é proibido criar nós fictícios** (ex.: "armário da operadora" com latência inventada).
* **Os 3 Nós Canônicos Verificáveis:**
  1. `[ iPhone ]`: Origem do tráfego e dispositivo de medição.
  2. `[ Wi-Fi / Roteador ]`: Primeiro salto local medido via micro-rajadas UDP no gateway (`en0`) (conforme Decisão 27). Em redes móveis, adapta-se para `[ Rede Móvel ]`.
  3. `[ Região Gamer ]`: Destino de referência de infraestrutura do jogo (AWS GameLift, Azure PlayFab ou Valve A2S).
* **Preservação da Decisão:** A **Trilha Viva** substitui o medidor circular e o gráfico linear durante o estado ativo de medição. Na tela final de resultado, o **LagCheck Score** e o veredito verbal de partida permanecem intactos, complementados pela síntese de integridade dos trechos da rota.

---

## 2. Engenharia de Rede e Dinâmica de Telemetria (Iury)

A Trilha Viva é alimentada em tempo real pelas amostras de `ProbeSample` e pelas métricas agregadas locais:

### A. Fluxo de Pacotes (Ida e Volta)
* **Cadência de Emissão:** Cada emissão de probe UDP (2 probes por segundo) dispara visualmente um pacote saindo do iPhone em direção ao nó intermediário e daí para o destino.
* **Velocidade de Trânsito:** A animação de ida e volta do pulso é proporcional ao RTT mediano recente ($P50$).
* **Perda de Pacote (*Packet Loss*):** Quando um probe atinge timeout ou é descartado, o pacote luminoso se desfaz/evapora no trecho correspondente antes de retornar.
* **Jitter (Instabilidade):** Oscilação rítmica na velocidade dos pacotes sucessivos (uns desaceleram, outros avançam rapidamente).

### B. Diagnóstico Visual de Estresse (Fase de Carga do Deep Check)
No Deep Check, ao acionar a carga controlada de até 10 MB via HTTP (`/v1/load`), a telemetria discrimina a origem do estresse:
1. **Gargalo no Enlace Sem Fio (Bufferbloat Local / Saturação 2.4 GHz):**
   * *Evidência:* Jitter do salto local $> 15\text{ ms}$, $\Delta P50 \ge 35\text{ ms}$ ou perda local.
   * *Comportamento Visual:* O segmento `iPhone ➔ Roteador` aquece para tons Coral/Vermelho (`NLColor.coralSolarRed`), com partículas acumulando e vibrando na interface com o roteador.
2. **Gargalo na Rota WAN / Provedor (Bufferbloat Externo):**
   * *Evidência:* Gateway local responsivo ($< 2{,}5\text{ ms}$), mas $\Delta P50$ sob carga $\ge 20\text{ ms}$ no destino final.
   * *Comportamento Visual:* O trecho `iPhone ➔ Roteador` permanece estável e iluminado em verde/ciano neutro, enquanto o trecho `Roteador ➔ Região Gamer` expande, muda para Coral Solar e os pacotes atrasam no retorno externo.

---

## 3. Direção de Design e Tokens (Renan)

O novo componente **`MeasurementLiveTrail`** integra o design system `NolaggyDesign`:

1. **Tokens de Cor (Paleta Coral Solar — Decisão 25):**
   * Nó ativo / Em trânsito regular: `NLColor.accentPrimary` (Coral Solar `#FF6B35`).
   * Trecho saudável / Estável: Verde/Menta de sistema ou tom ciano sutil de contraste.
   * Trecho sob estresse / Gargalo: `NLColor.coralSolarRed` (`#FF3823`) com halo pulsante de alerta.
   * Fundo dos nós: `NLColor.backgroundRaised` com borda `NLColor.borderSubtle`.
2. **Tipografia e Badges:**
   * Ícones SF Symbols canônicos:
     * Dispositivo: `iphone`
     * Salto local: `wifi` (ou `antenna.radiowaves.left.and.right` em rede celular) / `router`
     * Destino: `server.rack` ou `mappin.and.ellipse`
   * Labels concisos: "Seu iPhone", "Wi-Fi local", "São Paulo (AWS)".
3. **Acessibilidade:**
   * Respeito rigoroso a `accessibilityReduceMotion`: partículas em movimento contínuo são substituídas por barras de progresso lineares segmentadas com indicação textual de estado.
   * Labels de acessibilidade VoiceOver discriminando o estado de cada segmento em tempo real.

---

## 4. Arquitetura de Software no iOS (Rian)

* **Localização do Componente:** `Sources/NolaggyDesign/Components/MeasurementLiveTrail.swift`.
* **Renderização:** SwiftUI nativo com `TimelineView(.animation)` e `Canvas` para alto desempenho (60/120 fps ProMotion) sem alocação contínua de memória e zero overhead no motor de medição UDP.
* **Integração nas Features:**
  * `QuickCheckFeatureView.measurementView`: substitui `MeasurementPulse` e `LatencyGraph` por `MeasurementLiveTrail`.
  * `DeepCheckFeatureView.measuring(phase)`: adota `MeasurementLiveTrail` em ambas as fases (repouso e carga), ativando o modo de estresse visual durante a fase de carga.
