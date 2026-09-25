# LagCheck — Contrato da Validation Release (Entrega 1)

Documento normativo de produto e engenharia para a **Validation Release** do **LagCheck**.

---

## 1. Objetivo da Fase

O LagCheck entrou oficialmente na fase de **validação comercial e aquisição de usuários**. 

Nesta fase, a prioridade máxima do produto é testar e validar sua proposta de valor com tráfego real. A pergunta central do usuário à qual o produto responde de forma inequívoca é:

> **“Minha conexão está boa para jogar isso agora?”**

A proposta de valor é entregar uma conclusão rápida, honesta e fundamentada em medição real da rota do iPhone até a infraestrutura do jogo escolhido, permitindo ao jogador decidir com segurança antes de entrar em uma partida ranqueada ou competitiva.

---

## 2. Regra Fundamental de Governança

> **“Durante a fase de validação comercial, nenhuma nova funcionalidade deve ser implementada sem evidência de que ela corrige um problema observado no funil, na retenção ou em feedback real de usuários.”**

Qualquer expansão de escopo técnico, inclusão de novas modalidades de teste, adição de novos protocolos ou alteração do fluxo canônico está congelada até a conclusão da validação de tração e conversão.

---

## 3. Jornada Única Oficial do Usuário

O aplicativo opera sob uma **jornada única, linear e focada**:

$$\text{Escolher jogo} \longrightarrow \text{Escolher contexto/plataforma} \longrightarrow \text{Iniciar LagCheck} \longrightarrow \text{Receber conclusão} \longrightarrow \text{Entender o motivo} \longrightarrow \text{Testar novamente}$$

### Eliminação do "Quick Check"
- O conceito de "Quick Check" como modo visível, opção de medição, botão ou filtro de catálogo está **completamente eliminado** da experiência do usuário e da comunicação visual.
- A ação primária de medição é única: **"Testar conexão"** (ou **"Iniciar LagCheck"**).
- A medição executada pelo app executa a metodologia completa de duas fases (repouso + estresse sob carga controlada) com apresentação de veredito imediato no padrão Apple Games HIG.

---

## 4. Escopo Congelado (Frozen Scope)

O escopo do binário de validação está estritamente delimitado a:

1. **Catálogo Editorial e Descoberta:**
   - Vitrine de jogos populares e curados com suporte multiplataforma (iPhone, PlayStation, Xbox, Nintendo Switch, PC).
   - Identidade visual neutra e padronizada (sem capas ou logotipos licenciados de terceiros, conforme Decisão 18).
2. **Contexto de Jogo e Equipamento:**
   - Seleção explícita de plataforma e vínculo externo de rede (cabo Ethernet vs Wi-Fi) para consoles/PC, contextualizando o atestado da rota.
3. **Medição Determinística de Rede:**
   - Coleta de pacotes UDP reais para servidores de referência globais (AWS GameLift, Azure PlayFab, Valve A2S).
   - Duas fases integradas: leitura de repouso (latência P50, jitter, perda de pacotes) e impacto sob carga controlada (via Worker Cloudflare gratuito `nolaggy-deep-check` em `/v1/load`).
   - Avaliação e recomendação determinística de frequência Wi-Fi (2.4 GHz vs 5 GHz).
4. **Tela de Resultado (Apple Games HIG):**
   - Veredito claro e direto em destaque superior (Hero Editorial: *Segura bem*, *Oscilou bastante*, *Sofreu sob carga*, *Perda de pacotes*, *Leitura inconclusiva*).
   - Trilha visual da rota em 5 nós óticos HIG (`Local`, `Provedor`, `Caminho`, `Carga`, `Servidor`).
   - Ações assertivas: reteste primário imediato, detalhes técnicos de rede em sheet secundário, e dicas de otimização locais.
5. **Histórico Local e Retenção:**
   - Persistência exclusiva no iPhone via SwiftData.
   - Retenção máxima de 90 dias ou até 100 registros recentes por jogo.
   - Reteste direto de entradas anteriores com re-resolução dinâmica de rota regional.

---

## 5. Contrato de Eventos de Analytics do Funil

Para medir a eficácia da proposta de valor, a taxa de conclusão e os pontos de abandono durante a validação comercial, o LagCheck adota um contrato de telemetria mínimo, estruturado e com privacidade estrita por design.

### 5.1 Princípios de Privacidade (Privacy-First)
- **Zero PII (Personally Identifiable Information):** Nenhum nome, e-mail, Apple ID ou identificador persistente de dispositivo é coletado.
- **Zero Dados Sensíveis de Rede:** É expressamente proibido registrar endereço IP, SSID, BSSID, MAC Address, modelo de roteador ou amostras brutas de pacotes de rede.
- **Custo Operacional Zero:** Nenhum serviço ou SDK pago de analytics (Mixpanel, Amplitude, AppsFlyer) é adicionado ao projeto.
- **Zero Anúncios:** Nenhum SDK de publicidade (Google AdMob, Unity Ads) está integrado ou ativo nesta versão.
- **Transparência Técnica:** Eventos são emitidos localmente via subsistema unificado de logging da Apple (`os.Logger`, subsystem `com.lagcheck.app`, category `analytics`).

### 5.2 Catálogo Canônico de Eventos

| Evento | Momento de Emissão | Parâmetros Obrigatórios |
| :--- | :--- | :--- |
| `app_open` | Inicialização do aplicativo na Home | *Nenhum* |
| `game_selected` | Toque em um jogo na vitrine, busca ou catálogo | `game_id` |
| `platform_selected` | Seleção ou alteração da plataforma de jogo (iPhone, PlayStation, Xbox, Switch, PC) | `platform` |
| `lagcheck_started` | Início efetivo da coleta de pacotes de medição | `game_id`, `platform`, `network_type`, `region_id` |
| `lagcheck_completed` | Conclusão bem-sucedida com resultado válido | `game_id`, `platform`, `network_type`, `region_id`, `result_class`, `duration_seconds` |
| `lagcheck_inconclusive` | Conclusão sem amostras UDP válidas suficientes (< 10 amostras) | `game_id`, `platform`, `network_type`, `region_id`, `inconclusive_reason` |
| `lagcheck_cancelled` | Cancelamento por ação do usuário, transição para background ou troca de rede | `game_id`, `platform`, `network_type`, `region_id`, `cancellation_reason` |
| `result_viewed` | Apresentação da tela de resultado / veredito ao usuário | `game_id`, `platform`, `result_class` |
| `retest_started` | Toque no botão de reteste na tela de resultado ou no Histórico | `game_id`, `platform` |

---

## 6. Critérios de Prontidão para Release (Readiness Criteria)

A versão está apta para publicação e aquisição de tráfego somente quando satisfizer 100% dos seguintes critérios:

1. **Consistência Semântica e Visual de Marca:**
   - Marca oficial **LagCheck**, com wordmark grafada estritamente em minúsculas (`lagcheck`).
   - Ícone e identidade visual oficial **Pulse Gauge Coral Solar** em todos os assets (app, web, favicons).
   - Eliminação total de menções residuais visíveis à marca provisória anterior (`Nolaggy`) em telas, cópias, descrições de acessibilidade, site institucional, páginas de suporte e política de privacidade.
2. **Integridade das Regras de Medição de Rede:**
   - **Consentimento em Dados Móveis:** O usuário é consultado explicitamente antes do primeiro teste em 4G/5G; recusa aborta a sessão imediatamente sem transmissão de pacotes.
   - **Descarte em Mudança de Conexão:** Qualquer alteração no caminho de rede (`.networkPathChanged`) ou ida para background descarta imediatamente a medição parcial.
   - **Proibição de Fallback Alucinado:** Respostas UDP insuficientes resultam obrigatoriamente em veredito inconclusivo. Resultados inconclusivos **nunca** geram score fictício e **nunca** são persistidos no SwiftData.
3. **Portões de Qualidade Automatizados:**
   - Script de localização (`scripts/verify-localization.mjs`): 100% de paridade entre as 440 chaves em `pt-BR`, `en` e `es`.
   - Script de validação do site (`web/validate.js`): 77/77 testes aprovados (100% sucesso).
   - Testes unitários do Core (`NolaggyUnitTests`): 229/229 testes aprovados (120 de domínio, 50 de aplicação, 59 de infraestrutura).
   - Compilação limpa do binário principal sem erros (`xcodebuild build -scheme Nolaggy`).

---

## 7. Não-Escopo Explícito

Estão formalmente fora de escopo para esta release:
- Novas telas ou abas de navegação.
- Novos testes ou diagnósticos de rede (ex: testes de VPN, DNS benchmarking, novos tipos de NAT).
- Redesign ou novas linguagens visuais.
- SDKs pagos de atribuição ou telemetria externa.
- Publicidade, banners ou paywalls.
- Suporte a sistemas Android ou web app de medição.
