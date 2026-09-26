# Decisão 57 — Hero Gauge Pulsante, Meus Jogos Favoritos, Exportação PDF Customizada e Otimização Única de Maior Impacto

- **Data:** 26 de setembro de 2026
- **Status:** Decidido e implementado
- **Papéis:** Marco (Produto e Integração), Renan (Design System Dark Competitive UI), Rian (Arquitetura iOS/SwiftUI), Iury (Qualidade de Rede e Integridade Diagnóstica), Dono do Produto (Diretrizes Estratégicas)

---

## 1. Contexto e Problema Identificado

Durante auditoria de usabilidade e integridade da experiência na Home e no Cockpit de Rede, foram identificados pontos essenciais de alinhamento com a proposta de valor do LagCheck:
1. **Divergência de Leitura Local (18 ms na Home vs 14 ms no Cockpit):** A existência de sondagens locais separadas com janelas ou instâncias de probes desconectadas criava a impressão de falta de sincronismo e perda de autoridade de medição. A rede do usuário precisava de uma **única fonte da verdade ao vivo**.
2. **Hero com Atrito e Informações Excedentes:** A Home apresentava dados técnicos locais e atalhos de histórico que dispersavam o foco do jogador. A ação primordial de entrada deve ser imediata, visceral e esportiva.
3. **Seleção de Jogos na Home:** O jogador deseja protagonismo para os seus jogos favoritos (até 4 títulos no formato padrão), sem poluição com jogo genérico nesta vitrine principal.
4. **Exportação Profissional:** Necessidade de comprovação técnica para compartilhar com suporte da operadora, amigos ou técnicos de rede via relatórios PDF customizados de alta fidelidade visual com a identidade oficial LagCheck (um de diagnóstico de rede e outro do veredito da medição).
5. **Fadiga de Recomendações:** A apresentação de múltiplos cards simultâneos de otimização no resultado dispersava a atenção. O jogador quer saber a **única oportunidade de maior impacto** para destravar sua jogabilidade agora.
6. **Casos de Uso Gamer no Cockpit:** O jogador precisa traduzir métricas técnicas (RTT, NAT, CGNAT) em respostas claras para Cloud Gaming, Chat de Voz, FPS Competitivo e Live Streaming.

---

## 2. Decisões Tomadas

### 2.1 Fonte Única da Verdade para Rede Local (`SharedNetworkTelemetryService`)
- Criado o serviço centralizado `SharedNetworkTelemetryService` em `NolaggyInfrastructure`.
- Centraliza as medições de gateway RTT (3 amostras determinísticas), identificação de banda Wi-Fi (5 GHz vs 2.4 GHz) e topologia STUN (NAT Tipo 1/2/3, CGNAT RFC 6598, Duplo NAT).
- Tanto o Cockpit de Rede quanto qualquer leitura do app consultam o mesmo estado compartilhado `@MainActor`. No Cockpit, há indicação pulsante ao vivo com atualização manual e automática sob demanda.

### 2.2 Novo Hero da Home: Gauge Circular Dinâmico com Ondas Pulsantes
- Criado o componente `HomeCircularPulseGaugeHero`.
- Design esportivo com anel em gradiente Coral Solar / Solar Flame, glow dinâmico e 3 ondas concêntricas circulares pulsando continuamente no ritmo do gauge.
- No centro: texto em destaque **"TESTAR AGORA"** acompanhado do jogo ativo e região de referência.
- O toque no gauge dispara imediatamente a medição (`isMeasuring`).

### 2.3 Meus Jogos / Favoritos na Home (Teto de 4 Jogos)
- Criado o componente `HomeFavoriteGamesRail` e a tela modal `FavoriteGamesSelectionSheet`.
- A Home exibe até 4 jogos favoritos selecionados pelo próprio jogador.
- O jogo genérico ("generic-gaming") foi terminantemente removido desta vitrine.
- Gerenciado por `FavoriteGamesStore` com persistência em `UserDefaults` e inicialização inteligente com os 4 jogos competitivos mais populares do catálogo na primeira abertura.

### 2.4 Limpeza de Superfície da Home Principal
- Removida a pílula de dados técnicos de rede da tela Home.
- Removido o botão/atalho de histórico da Home.
- O histórico permanece completo, auditável e seguro exclusivamente através do menu de configurações (`NolaggyAppHeader` → Configurações → Histórico).

### 2.5 Exportação de Relatórios PDF Customizados com a Identidade LagCheck
- Criado o módulo `LagCheckPDFExporter` com renderização vetorial gráfica profissional (`UIGraphicsPDFRenderer`) no padrão Dark Competitive UI (fundo `#0B0D10`, cards `#15181E`, wordmark `lagcheck`, tipografia limpa e selos de conformidade RFC 5389):
  1. **PDF 1 (Cockpit de Rede):** Relatório Técnico com Primeiro Salto, Banda Wi-Fi, Borda WAN, NAT Tipo 1/2/3, CGNAT, Duplo NAT e Prontidão para Casos de Uso.
  2. **PDF 2 (Resultado da Medição):** Atestado de Prontidão para Jogos com Veredito Semântico em destaque, Score LagCheck, Grid de Telemetria (Ping, Jitter, Perda, Bufferbloat) e a Oportunidade de Maior Impacto.
- Integração nativa com `UIActivityViewController` (`ShareSheet`) permitindo salvar em Arquivos, imprimir ou compartilhar no WhatsApp/Discord.

### 2.6 Otimização Única de Maior Impacto no Resultado
- Criado o `HighImpactOptimizationEvaluator`.
- Substitui a lista de 3 níveis por **1 único card destacado** ("OPORTUNIDADE DE MAIOR IMPACTO"):
  1. Cabo Ethernet Cat6 se console/PC em Wi-Fi (eliminação de até 80% do jitter).
  2. Wi-Fi 5 GHz se contenção local ou 2.4 GHz detectado.
  3. SQM (Smart Queue Management) / pausa de downloads se saturação de bufferbloat sob carga.
  4. Suporte técnico para atenuação de fibra se perda de pacotes na rota WAN.
  5. Liberação de portas UPnP / IP público se NAT estrito ou CGNAT.
  6. Manutenção e setup proativo se a rede estiver perfeita (`.ready`).

### 2.7 Casos de Uso no Cockpit de Rede com Motivadores Diagnósticos Reais
- Seção "PRONTIDÃO PARA PERFIS DE USO GAMER" no `NetworkCockpitView`:
  - **Não exibe meras descrições conceituais dos apps** (ex: "Discord, Party Chat...").
  - **Exibe o motivador causal exato observado**:
    - **Streaming de Jogos (Cloud Gaming):** aponta latência do roteador (ms) ou Wi-Fi 2.4 GHz detectado com risco de congelamento de vídeo.
    - **Áudio Multiplayer (Chat de Voz):** aponta latência de gateway (ms) e clareza versus voz robótica/cortes.
    - **Multiplayer Competitivo (FPS/MOBA):** aponta bloqueio por NAT Tipo 3 (Estrito), duplicidade de roteador (Duplo NAT) ou latência de registro de disparos.
    - **Transmissão ao Vivo (Live Stream):** aponta estabilidade em 5 GHz versus interferência de 2.4 GHz derrubando o bitrate da live.

### 2.8 Seleção e Desmarcação Dinâmica de Jogos na Home
- Toque no mesmo jogo da barra de favoritos desmarca a seleção (`selectedGameID = nil`).
- Quando desmarcado, o Hero Gauge circular assume o modo **"CONEXÃO GERAL"** (rota de referência neutra).
- Tocar em "TESTAR AGORA" sem jogo selecionado dispara automaticamente o teste da rota geral.

### 2.9 Integração com Atalhos do iOS e Deep Links (`lagcheck://`)
- Registrado o scheme `lagcheck` no `project.yml` e gerado no `Info.plist`.
- `QuickCheckFeatureView` trata chamadas externas via `.onOpenURL`:
  - `lagcheck://quicktest` / `lagcheck://test`: dispara o teste diretamente em 1 toque na Home (compatível com atalhos do iOS e `EcosystemTriggerEngine` do WiFi Casa).
  - `lagcheck://network` / `lagcheck://wifi`: abre diretamente a aba/tela de Dados da Rede (Cockpit).
  - `lagcheck://games`: navega para a aba de Jogos.
  - `lagcheck://home`: navega para a Home.

---

## 3. Arquivos Criados e Alterados

- `Sources/NolaggyInfrastructure/SharedNetworkTelemetryService.swift` (novo: fonte única de verdade da telemetria)
- `Sources/NolaggyDesign/Components/HomeCircularPulseGaugeHero.swift` (novo: estética do MeasurementPulse com ondas dinâmicas e ação direta)
- `Sources/NolaggyApplication/FavoriteGamesStore.swift` (novo: persistência de até 4 jogos favoritos)
- `Sources/NolaggyApp/Features/Home/HomeFavoriteGamesRail.swift` (novo: trilho horizontal de favoritos com desmarcação toggle)
- `Sources/NolaggyDomain/HighImpactOptimization.swift` (novo: avaliação determinística da oportunidade de maior impacto)
- `Sources/NolaggyApp/LagCheckPDFExporter.swift` (novo: geração de PDFs customizados Dark Competitive)
- `Sources/NolaggyApp/Features/Diagnostics/NetworkCockpitView.swift` (refatorado: motivadores diagnósticos reais, exportação de PDF e cópia)
- `Sources/NolaggyApp/Features/Home/HomeFeatureView.swift` (refatorado: hero gauge, favoritos, remoção de dados técnicos da home)
- `Sources/NolaggyApp/Features/Result/CheckCompletoResultView.swift` (refatorado: card de otimização única e exportação de PDF)
- `Sources/NolaggyApp/QuickCheckFeatureView.swift` (atualizado: suporte a deep links `.onOpenURL` e `lagcheck://`)
- `Sources/NolaggyApp/Info.plist` e `project.yml` (atualizado: registro de `CFBundleURLTypes`)
- `Sources/NolaggyApp/Resources/{pt-BR,en,es}.lproj/Localizable.strings` (novas chaves localizadas)
- `Tests/NolaggyDomainTests/HighImpactOptimizationTests.swift` (novo: 100% aprovado)
- `Tests/NolaggyApplicationTests/FavoriteGamesStoreTests.swift` (novo: 100% aprovado)
- `Tests/NolaggyUITests/QuickCheckPilotUITests.swift` (atualizado: 100% aprovado)

