# Decisão 56 — Jornada 1-Toque, Cockpit de Rede, Plataforma no Resultado e Refinamentos de UX

- **Data:** 26/09/2026
- **Status:** Decidido e aprovado pelo Dono do Produto (Luiz)
- **Frentes envolvidas:** Marco (Produto), Renan (Design/UI), Rian (iOS/SwiftUI), Iury (Qualidade de Rede/Diagnóstico)

---

## 1. Contexto e Motivação

A jornada anterior ainda apresentava fricção prévia à medição: após selecionar um jogo ou tocar no botão de ação da Home, o app abria um modal intermediário de detalhes para seleção de plataforma e tipo de conexão (cabo ou Wi-Fi), antes de finalmente iniciar o teste. 

Como o teste é executado a partir do hardware do iPhone, o app não tem acesso à placa de rede de um console externo (PlayStation, Xbox) ou PC, nem consegue medir fisicamente uma conexão cabeada se o iPhone está no Wi-Fi. Solicitar esses dados antes da medição gerava atrito desnecessário e expectativas irreais.

Adicionalmente:
1. Durante a medição, a transição entre a fase de repouso e a fase de carga provocava instabilidade visual ("samba" de layout) devido à variação de altura dos textos contextuais e das barras de progresso.
2. O veredito semântico utilizava marcadores genéricos de texto (`●`, `▲`), em vez de ícones semânticos nativos do ecossistema Apple (SF Symbols).
3. O jogador não possuía uma área consolidada para consultar parâmetros técnicos da sua rede (IP local, gateway, tipo de NAT, CGNAT, IPv6, DNS), úteis para configuração de partidas e resolução de problemas.

---

## 2. Decisões Tomadas

### 2.1 Jornada 1-Toque (Zero Fricção)
- **Home → Jogo → Medição Direta:** Ao tocar no botão de ação principal da Home com um jogo ativo (ou selecionado no trilho rápido), o app navega **diretamente para a tela de medição em andamento**, sem modal intermediário.
- **Teste Geral Instantâneo:** Disponibilização de link/botão "Realizar Teste Geral" na Home e como primeira opção quando uma busca não encontra o jogo digitado. O acionamento dispara imediatamente a medição da rota neutra regional de referência.
- **Desacoplamento do Catálogo Editorial:** Informações editoriais de requisitos e plataformas continuam acessíveis sob demanda (via botão secundário de informações ou tela de resultado), sem bloquear o início do teste.

### 2.2 Redefinição do Papel da Plataforma (Console / PC / Mobile)
- **Configuração Global:** A preferência de plataforma do jogador passa a residir em Configurações (`SettingsView`), sob "Minha Plataforma Principal" (PlayStation, Xbox, PC, Mobile ou Genérica/Não definida).
- **Consultoria no Resultado (Pós-Medição):** A plataforma selecionada ganha protagonismo no **Resultado**. As métricas observadas alimentam um guia acionável em três níveis:
  - *Nível 1 (Você mesmo):* Ações no setup local (DMZ, UPnP, fixar IP estático no console, cabo Ethernet Cat6).
  - *Nível 2 (Operadora):* Roteiro de contato com o suporte para liberação de portas, saída de CGNAT (RFC 6598) ou habilitação de IPv6 nativo.
  - *Nível 3 (Hardware):* Diagnóstico de limitações do roteador padrão e recomendação de equipamentos com SQM (CAKE) contra bufferbloat.

### 2.3 Cockpit de Rede ("Dados da Rede do Jogador" no Menu Principal)
- O Cockpit de Rede é promovido a **aba primária no menu de navegação principal** (`Home > Jogos > Rede` via `AppTab.network`), além de ser acessível com um toque na **Pílula de Telemetria ao Vivo** (`LiveNetworkSignalCapsule`) da Home e também nas Configurações.
- Reúne dados consolidados:
  - Salto Local: Interface (Wi-Fi ou celular), IP local, IP do Gateway e latência do Gateway observada. A frequência Wi-Fi só aparece se uma fonte pública válida do sistema a confirmar; no candidato atual ela permanece não confirmada.
  - Borda WAN: Tipo de NAT (Aberto, Moderado, Estrito, Duplo NAT), status de CGNAT, suporte a IPv6, IP Público completo (com botão de revelação/cópia) e DNS ativo.
  - Ferramenta de Suporte: Botão "Copiar Relatório de Rede" formatado para compartilhamento com suporte técnico ou Discord.

### 2.4 Estabilização Visual da Tela de Medição
- Fixação de dimensões mínimas e reservas de layout nos componentes de `MeasurementLiveTrail`:
  - `contextualStatusSection`: frame com altura mínima travada, garantindo que variações de texto entre repouso e carga não empurrem os `Spacer()` nem desloquem o radar Coral Solar.
  - `stepBar`: altura da linha e reserva de espaço para o checkmark de conclusão com animação de opacidade pura, eliminando pulo na entrada do ícone.
- Transições de estado puramente alfa/suaves entre fases de medição.

### 2.5 Ícones Semânticos de Veredito (HIG Apple)
- Substituição dos caracteres em texto cru (`●`, `▲`, `—`) por SF Symbols alinhados com as Human Interface Guidelines:
  - `.ready` (Pronto para Ranked) → `checkmark.circle.fill` (Verde Esmeralda).
  - `.caution` (Condições Instáveis) → `exclamationmark.triangle.fill` (Amarelo Âmbar).
  - `.notReady` (Eu Evitaria Ranked) → `xmark.octagon.fill` (Coral Solar / Vermelho).
  - `.inconclusive` (Inconclusivo / Dados Insuficientes) → `minus.circle.fill` (Cinza Neutro).
- As strings em `Localizable.strings` (pt-BR, en, es) passam a conter apenas a headline textual, sendo o ícone renderizado por `Image(systemName:)` nativo em `HStack`.

---

## 3. Impacto Arquitetural e Governança

- **Domínio (`NolaggyDomain`):** `GameReadinessVerdict` expõe os novos `symbolName` oficiais. As regras de score e thresholds permanecem estritamente determinísticas.
- **Design System (`NolaggyDesign`):** `MeasurementLiveTrail` recebe estabilização de layout e suporte a toque para abertura do cockpit em `LiveNetworkSignalCapsule`.
- **Aplicação e UI (`NolaggyApp`):** `HomeFeatureView` remove o passo intermediário de `selectedGameForDetails` no CTA principal; `CheckCompletoResultView` incorpora o card de otimização de plataforma e o novo cabeçalho com SF Symbols; `SettingsView` ganha o seletor de plataforma padrão.
- **Custo Operacional:** Zero. Todo o diagnóstico utiliza os probes locais (gateway, interfaces) e infraestrutura já autorizada (STUN RFC 5389 e Cloudflare Worker `/v1/load`).
