# LagCheck — decisão 27: diagnóstico e recomendação de frequência Wi-Fi (2.4 GHz vs 5 GHz)

**Status:** decisão aprovada para especificação e implementação em branch dedicada (`feature/wifi-band-diagnostics`)  
**Data:** 18 de setembro de 2026  
**Autores / Revisores:** Marco (Produto), Rian (iOS), Iury (Rede), Renan (Design), Luiz (Dono do Produto)  
**Validação Externa:** Claude Code CLI (Auditoria técnica de conformidade App Store e rede)  
**Complementa:** `docs/01-funcional.md`, `docs/02-arquitetura.md`, `docs/03-especificacao-tecnica.md`, `docs/07-voz-do-produto.md`, `docs/archive/decisoes/23-decisao-dicas-conexao-gemini-deep-check.md`, `docs/archive/decisoes/24-decisao-adocao-design-system-apple-games.md`, `docs/archive/decisoes/25-decisao-marca-lagcheck-coral-solar.md`

---

## 1. Contexto e Problema do Jogador

A frequência de 2.4 GHz em redes Wi-Fi é uma das principais causas de variações bruscas de latência (jitter) e perda de pacotes para jogos móveis e consoles, devido à disputa de meio (apenas 3 canais de 20 MHz sem sobreposição) e interferência de eletrodomésticos e Bluetooth. Em contraste, redes de 5 GHz ou 6 GHz (Wi-Fi 6E/7) fornecem canais amplos e meio desimpedido, mantendo a cadência estável dos datagramas UDP.

Para melhorar a experiência do usuário sem fazer falsas promessas, o LagCheck deve ser capaz de avaliar a conexão sem fio local e recomendar a alternância para a frequência mais favorável quando forem observadas condições degradadas.

---

## 2. Limitações de Plataforma no iOS 17+ (Apple App Store)

Conforme parecer de engenharia (Rian) e auditoria técnica do Claude Code CLI:
1. **Inexistência de API Pública de Frequência:** O iOS não expõe canal de rádio, frequência (MHz) ou modulação física (PHY rate) em nenhuma API pública. `CoreWLAN` é exclusivo do macOS. `MobileWiFi.framework` é API privada e acarreta rejeição sumária na App Store (Guideline 2.5.1).
2. **Restrições de SSID e Privacidade:** `NEHotspotNetwork.fetchCurrent` fornece apenas o SSID/BSSID e exige o entitlement `com.apple.developer.networking.wifi-info` associado à permissão de GPS/Localização (`CoreLocation`). Exigir localização exclusivamente para teste de ping causa atrito e suspeita no usuário. Além disso, roteadores modernos utilizam **Band Steering**, unificando o mesmo nome de rede para 2.4 GHz e 5 GHz.
3. **Ausência de Eco UDP no Gateway:** Roteadores domésticos e ONTs de operadoras brasileiras (Claro, Vivo, Intelbras, TP-Link) não possuem serviço de eco UDP ativo e frequentemente silenciam ou aplicam rate-limit em portas locais. Se um roteador não responder, o resultado do salto local deve ser estritamente **Inconclusivo**, nunca uma suposição inventada.

---

## 3. Arquitetura da Solução: Diagnóstico Híbrido

A solução opera em três camadas coordenadas:

### A. Camada de Telemetria de Salto Local (Core Engine)
- Resolução do endereço IP do gateway padrão da interface Wi-Fi (`en0`) via tabela de rotas do sistema BSD.
- Envio de micro-rajada de datagramas UDP monotônicos locais para amostragem de RTT e jitter do enlace sem fio.
- **Assinatura de Contenção 2.4 GHz / Interferência:** Jitter local elevado ($> 15\text{ ms}$), razão de cauda $P95 / P50 \ge 1{,}45$ com picos frequentes de contenção, ou colapso de tempo de ar sob carga no Deep Check ($\Delta P50 \ge 35\text{ ms}$).
- **Assinatura 5 GHz / 6 GHz:** RTT mediano sub-2 ms ($< 2{,}5\text{ ms}$) com jitter inter-pacote estável ($< 1{,}2\text{ ms}$).
- **Tratamento Inconclusivo:** Sem respostas válidas do gateway, a estimativa do salto local é classificada como `.inconclusive`.

### B. Camada Sintática de SSID (Secundária / Opcional)
- Reconhecimento de sufixos inequívocos de rede:
  - Sufixos 5 GHz / 6 GHz: `5G`, `5GHz`, `5.0GHz`, `6G`, `6GHz`, `6E`, `WiFi6`, `WiFi7`.
  - Sufixos 2.4 GHz: `2.4G`, `2.4GHz`, `2G`, `2_4GHz`.
- Quando um sufixo inequívoco é detectado, a confiança do diagnóstico é elevada para `.confirmed`.

### C. Camada Editorial de Recomendação (Apple Games Editorial Hub)
- Apresentação visual limpa respeitando os tokens de `NolaggyDesign` e a voz do produto (`docs/07`).
- Textos honestos diferenciando certeza de nome vs sintomas observados na telemetria.

---

## 4. Pontos de Contato e Experiência do Usuário (UI/UX)

1. **Card de Status na Home (`HomeNetworkStatusCard`):**
   - No trilho visual `iPhone` ➔ `Wi-Fi` ➔ `Internet` ➔ `Jogo`, o nó sem fio exibe identificador sutil de frequência (`2.4G`, `5G` ou `Oscilação`).
2. **Página de Detalhes do Jogo (`GameDetailView`):**
   - Card nativo `NetworkBandAdviceBanner` posicionado abaixo do veredito de score e acima do botão de Deep Check, contextualizando o impacto no jogo selecionado.
3. **Resultado do Deep Check (`DeepCheckResultView`):**
   - Indicação se o gargalo sob carga concentra-se no enlace local sem fio (ar saturado) ou na infraestrutura externa do provedor.
4. **Gemini Connection Booster Sheet (`ConnectionBoosterSheet` — `docs/23`):**
   - Card prioritário no topo do checklist de ações práticas recomendando a migração para a frequência de 5 GHz.

---

## 5. Matriz de Copywriting (PT-BR e EN)

### Banda Confirmada (2.4 GHz)
- **PT-BR:**
  - *Título:* Conectado em Wi-Fi 2.4 GHz
  - *Mensagem:* Esta frequência tem maior alcance, mas sofre mais interferência durante as partidas. Se o seu roteador tiver rede 5 GHz ou Wi-Fi 6, conecte-se a ela para reduzir oscilações.
  - *Ação:* Ver ajustes de Wi-Fi
- **EN:**
  - *Title:* Connected to 2.4 GHz Wi-Fi
  - *Message:* This band offers wider range, but is prone to interference during matches. If your router has a 5 GHz or Wi-Fi 6 network, switch to it for lower jitter.
  - *Action:* Open Wi-Fi Settings

### Sintomas Observados (SSID Unificado / Instabilidade de Sinal)
- **PT-BR:**
  - *Título:* Instabilidade detectada no sinal Wi-Fi
  - *Mensagem:* Esta medição encontrou variações típicas de frequências de 2.4 GHz ou interferência de sinal. Se o seu roteador for dual-band, tente alternar para a rede 5 GHz ou aproximar-se do roteador.
  - *Ação:* Fazer Deep Check
- **EN:**
  - *Title:* Wi-Fi signal instability detected
  - *Message:* This check showed variations typical of 2.4 GHz networks or signal interference. If your router is dual-band, try switching to 5 GHz or moving closer to the router.
  - *Action:* Run Deep Check

### 5 GHz / 6 GHz Saudável
- **PT-BR:**
  - *Status:* Wi-Fi 5 GHz · Conexão local estável
  - *Mensagem:* Sua conexão local está em uma frequência rápida e com pouca interferência.
- **EN:**
  - *Status:* 5 GHz Wi-Fi · Stable local link
  - *Message:* Your local connection is using a fast frequency band with low interference.

---

## 6. Governança e Próximos Gates

- **Rian:** Implementação modular dos adaptadores em `NolaggyInfrastructure` e integração no app.
- **Iury:** Calibração dos vetores de teste de domínio em `NolaggyDomainTests`.
- **Renan:** Implementação do componente visual `NetworkBandAdviceBanner` em `NolaggyDesign`.
- **Marco / Luiz:** Revisão final de branch e abertura de Pull Request para integração na `main`.
