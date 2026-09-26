# 54 — Decisão: Pílula de Telemetria Local ao Vivo na Home e Resolução de Jogos Não Listados

**Status:** decidido pelo Dono do Produto (Luiz); implementado  
**Data:** 25 de setembro de 2026  
**Responsáveis:** Luiz (Dono do produto), Marco (Produto), Renan (Design), Rian (Engenharia iOS), Iury (Qualidade de Rede)  
**Alinhamento Estratégico:** Decisões 49 (Medição Geral), 50 (Ready for Ranked), 51 (Dark Competitive UI), 52 (Dual-Node Vector) e 53 (Tipografia de Performance)

---

## 1. Problemas e Oportunidades Identificados

### 1.1 Métricas ao Vivo na Home (Inspiração NoPing)
No benchmark competitivo (NoPing), o usuário visualiza o status e a saúde da sua rota imediatamente antes de engajar na medição ou na partida. No entanto, no ambiente móvel do iOS:
- O LagCheck possui a **restrição inegociável de custo zero** e **preservação estrita da franquia de dados móveis e bateria do usuário** (Decisões 01, 36 e 50).
- Não é aceitável manter sondagem UDP contínua em segundo plano contra servidores de borda, pois isso aqueceria o aparelho, consumiria bateria e gastaria a franquia móvel sem consentimento explícito.
- **Solução aprovada por Marco e Iury:** Criação da **Pílula de Telemetria de Rede Local ao Vivo (`LiveNetworkSignalCapsule`)**, posicionada logo abaixo da headline da Home. Ela executa uma checagem passiva instantânea da interface ativa (`NWPathMonitor`) e, se em Wi-Fi, dispara uma única sonda assíncrona local (DNS query leve contra o Default Gateway com timeout de 300ms via `BSDWiFiLocalGatewayProber`). Exibe:
  - Tipo de interface e banda física: `Wi-Fi 5 GHz`, `Wi-Fi 2.4 GHz`, ou `Rede Móvel (5G/4G)`.
  - Latência real do primeiro salto: `Gateway 2 ms` (apenas quando respondido por probe local real, sem qualquer número inventado).
  - Status operacional da rota regional: `São Paulo Operacional` (com dot semântico verde com pulso sutil).

### 1.2 Jogos Não Listados no Catálogo
Quando o usuário deseja verificar sua rota para um jogo não presente no catálogo editorial (como Valorant, CS2, EA Sports FC, Rocket League ou League of Legends):
- A Decisão 49 estabeleceu o conceito canônico de **"Conexão Geral para Jogos"** (`generic-gaming`).
- O app mede a rota até o datacenter de referência regional para jogos (AWS GameLift em São Paulo para o mercado BR), sem prometer nem inventar ping específico do jogo não suportado.
- Na aba Jogos, a busca que não encontra resultados exibe assistência editorial vazia com CTA direto: *“Medir Conexão Geral”*, além de permitir o acesso direto pela ficha neutra permanente.

### 1.3 Correção do Botão Duplo de Voltar no Histórico
Na tela de Histórico (`HistoryFeatureView`), ao ser apresentada dentro da `NavigationStack` principal a partir de um botão com `showsBackHeader`, o SwiftUI exibia concomitantemente a seta nativa `< Início` no topo esquerdo e o botão customizado `< Voltar` do header de navegação da tela.
- **Ajuste:** Adicionado `.navigationBarBackButtonHidden(showsBackHeader)` para ocultar a seta duplicada do sistema, preservando a navegação limpa e o controle visual aprovado.

---

## 2. Especificação Técnica e de Design

### 2.1 Componente `LiveNetworkSignalCapsule`
- Localização: `Sources/NolaggyDesign/Components/LiveNetworkSignalCapsule.swift`.
- Dimensões: Altura fixa de 32pt, cantos em formato Capsule (`Capsule()`), fundo `NLColor.surface` (`#15181E`), borda fina contínua de 1px `NLColor.borderHairline` (`white.opacity(0.08)`).
- Tipografia: `NLTypography.captionStrong` para a interface e `NLTypography.caption` para a rota regional.
- Indicador visual: Círculo de 7pt com preenchimento semântico (`NLColor.scoreExcellent` para Wi-Fi 5 GHz / Móvel operacional, `NLColor.scoreUnstable` para Wi-Fi 2.4 GHz, e `NLColor.coralSolarRed` para offline) e sombra suave (`opacity(0.6)` e raio 3).
- Acessibilidade: Agrupado em elemento único com rótulo semântico descritivo e identificador `live-network-signal-capsule`.

### 2.2 Integridade Diagnóstica do Primeiro Salto (Iury)
- Conforme a Decisão 50, é terminantemente proibido acusar instabilidade ou exibir latência sem evidência técnica comprovada.
- Se o roteador Wi-Fi local não responder à consulta DNS na porta 53 no timeout estrito de 300ms, o tempo de gateway é omitido na pílula (exibindo apenas `Wi-Fi 5 GHz · Rota SP Operacional`), sem nunca gerar números falsos.

---

## 3. Critérios de Aceite Verificados

1. A tela de Histórico apresenta um único botão de retorno quando acionada via fluxo de navegação interna.
2. A Home exibe a pílula compacta de sinal local logo abaixo da headline, sem sobrecarregar a interface ou quebrar o ritmo editorial da Dark Competitive UI.
3. A pílula reflete a interface ativa do dispositivo e a latência de gateway do Wi-Fi de forma não bloqueante.
4. Nenhuma requisição contínua ou tráfego excessivo é gerado no background da Home.
5. Todos os 62 testes unitários de infraestrutura e domínio passam sem regressões.
