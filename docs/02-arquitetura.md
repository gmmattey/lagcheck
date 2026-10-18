# LagCheck — arquitetura do MVP

**Status:** rascunho inicial para V1  
**Plataforma inicial:** iPhone (iOS 17 ou superior)  
**Documento relacionado:** [Documentação funcional](./01-funcional.md)

> **Decisões fechadas:** a distribuição iOS usa o Apple Developer Program já existente. Fora dessa conta, o MVP tem meta de custo operacional recorrente zero. O catálogo assinado acompanha cada build; a telemetria mínima anônima de retenção usa o Cloudflare Worker no plano gratuito, sem banco de dados complexo ou SDKs pagos.
> A App Store pode distribuir o app globalmente, mas o catálogo com suporte oficial do MVP começa em Brasil e Estados Unidos.
> O plano original do MVP1 não incluía publicidade. As Decisões 82, 96 e 97 autorizam AdMob/UMP e unidades Native Advanced em Home, Histórico, Jogos e Resultado nos dois clientes, mantendo medição e domínio isolados.
> **Atualização Decisões 50 e 55:** O modelo de domínio incorpora o `GameReadinessEvaluator` produzindo `GameReadinessVerdict`, além de motores dedicados de integridade diagnóstica: `SampleQualityEvaluator`, `LoadImpactEvaluator` multidimensional (`deep-load-impact-v2`), `EvidenceRecommendationEngine` e probe isolado de gateway local (`en0`) para estrita separação entre instabilidade doméstica e rota externa. A telemetria remota mínima para validação de retenção é suportada via Worker (`POST /v1/telemetry`), sem PII nem armazenamento de IP.

## 1. Objetivo arquitetural

O LagCheck deve entregar uma avaliação confiável da experiência de jogo no iPhone com o mínimo de infraestrutura própria. A arquitetura privilegia medição no dispositivo, resultado determinístico, privacidade por padrão e catálogo explícito na versão instalada.

O princípio central é simples: **o app mede; o catálogo orienta; o motor interpreta a prontidão da partida; o backend não arbitra cada teste**.

```mermaid
flowchart LR
    U[Jogador] --> A[LagCheck no iPhone]
    A --> C[Catálogo local assinado]
    A --> P[Destinos de probe gamer]
    A --> H[Histórico local]
    A -.-> T[Telemetria anônima Worker]

    subgraph A[LagCheck no iPhone]
        UI[Experiência e jornadas]
        ORQ[Orquestrador de medição]
        ENG[Motor de qualidade NGQE]
        INT[Interpretador de sintomas]
        RDY[Game Readiness Evaluator]
        UI --> ORQ --> ENG --> INT --> RDY --> UI
    end
```

## 2. Visão do sistema

| Bloco | Responsabilidade | Não é responsabilidade |
| --- | --- | --- |
| App LagCheck | Experiência, coleta UDP, cálculo NGQE, diagnóstico e veredito de prontidão. | Depender de backend para calcular score ou arbitrar o veredito. |
| Catálogo local & Telemetria | Envelope Ed25519 no build; Cloudflare Worker gratuito somente para carga em `/v1/load` e telemetria anônima em `/v1/telemetry`. | Processar dados brutos de rede, PII, IPs ou decidir o resultado de uma sessão. |
| Destinos de probe | Responder às medições de rede permitidas para uma região. | Conhecer usuário, jogo selecionado ou persistir resultado. |

Não há conta obrigatória, servidor de speed test próprio, VPN, túnel de tráfego, banco remoto de histórico ou LLM no caminho crítico do MVP.

## 3. Camadas do aplicativo

```mermaid
flowchart TB
    UX[Apresentação e experiência]
    APP[Aplicação e orquestração]
    DOMAIN[Domínio de qualidade de jogo]
    INFRA[Infraestrutura do dispositivo e integrações]
    DATA[Dados locais e catálogo]

    UX --> APP --> DOMAIN --> INFRA
    APP --> DATA
    DOMAIN --> DATA
```

### 3.1 Apresentação e experiência

Contém a Home focada em prontidão ("Vai jogar? Faça um Check"), tela de preparação ágil de jogo (`GameDetailView`), fluxo de medição com feedback limpo (`MeasurementProgressView`), tela de resultado orientada a veredito (`GameReadinessResultView` exibindo veredito semântico em 1º lugar, bloco honesto "O que encontramos" e métricas discretas), detalhes técnicos sob demanda (`TechnicalDetailsView` com P50/P95, spikes, dados sob carga e score 0–100), histórico de partidas e menu de configurações acessível por `…`.

Essa camada só apresenta estado pronto para uso. Ela não calcula métricas, escolhe endpoints, interpreta UDP nem aplica regras de classificação.

### 3.2 Aplicação e orquestração

Coordena os casos de uso: carregar catálogo, selecionar contexto de jogo, iniciar/cancelar uma sessão e persistir resultado.

O **Measurement Session Coordinator** é o dono do ciclo de uma medição. Ele:
- Garante que só exista uma sessão ativa por vez;
- Dispara o probe isolado de gateway local em Wi-Fi e os probes de rota remota;
- Monitora a qualidade da amostra via `SampleQualityEvaluator`, abortando precocemente em conexões degradadas;
- Reage instantaneamente a eventos do `NetworkPathObserver` (troca Wi-Fi ⇄ Celular), cancelando os sockets e descartando dados parciais da memória;
- Mantém o resultado parcial em repouso estritamente separado da fase sob carga.

### 3.3 Domínio de qualidade de jogo

É o núcleo determinístico, independente de tela, transporte ou fornecedor de endpoint. Inclui:

- Resolução do contexto de teste a partir de jogo, mercado, plataforma e catálogo;
- Agregação de amostras e watchdog de qualidade (`SampleQualityEvaluator`);
- Cálculo de P50, P95, P99, jitter, perda, spikes e latência de cauda ($P95/P50$);
- Classificação de spikes: isolados vs. recorrentes;
- Avaliação multidimensional sob carga (`LoadImpactEvaluator` com regra `deep-load-impact-v2`);
- Aplicação de pesos, limites e guardrails do perfil no motor NGQE;
- Hierarquia e coocorrência de causas pelo `ResultInterpreter` (causa primária e sintomas secundários);
- Motor de recomendações determinísticas (`EvidenceRecommendationEngine`, gerando de 1 a 3 ações práticas);
- Avaliação semântica de prontidão pelo `GameReadinessEvaluator` (`readiness-v2.0`), considerando confiança de rota;
- Geração do LagCheck Score (0–100) determinístico mantido para detalhes, histórico e telemetria.

O domínio recebe dados de entrada tipados e devolve um resultado completo. Não acessa UI, armazenamento, HTTP, UDP nem estado global do iOS.

### 3.4 Infraestrutura do dispositivo e integrações

Implementa adaptadores para capacidades externas:

- Descoberta dinâmica de gateway local via rotas do sistema operacional (`sysctl`/`getifaddrs` na `en0`), sem assumir IP `.1`;
- Transporte UDP para probes no gateway local (5 probes, 200 ms timeout) e detecção de estado observável/não-observável;
- Transporte UDP para probes remotos em destinos AWS GameLift, Azure PlayFab ou Valve;
- Carga HTTP controlada do Check (Worker `/v1/load`, teto de 10 MB);
- Diagnóstico de banda Wi-Fi com níveis de confiança (`WiFiBandDetector`: `.high`, `.medium`, `.low`, `.unknown`);
- Cliente leve de STUN RFC 5389 para detecção de topologia de NAT;
- Observação contínua de caminho de rede via `NWPathMonitor` para descarte imediato em transição de interface;
- Telemetria de produto anônima enviada ao Worker (`/v1/telemetry`) para validação de retenção sem PII/IP;
- Acesso a armazenamento local (SwiftData);
- Leitor do catálogo local e validação de assinatura Ed25519.

Esses adaptadores obedecem contratos definidos pelo domínio e pela aplicação. Trocar um destino de probe não pode alterar a regra de score ou prontidão.

### 3.5 Dados locais e catálogo

Há duas famílias de dados:

| Família | Origem | Uso | Regra de retenção inicial |
| --- | --- | --- | --- |
| Configuração de catálogo | Envelope assinado embarcado no app. | Jogos, regiões, perfis, limites, textos parametrizados e flags. | Validar no lançamento; nova versão exige novo build. |
| Dados do jogador | Criados no dispositivo em SwiftData. | Preferências, último jogo/plataforma e histórico de vereditos. | Permanecem locais por até 90 dias, com máximo de 100 medições por jogo e exclusão manual nas configurações. |

O histórico armazena o resultado contextualizado e a versão das regras usadas: jogo, plataforma, tipo de rede (`.wifi` ou `.cellular`), gateway probe result (`.stable`, `.degraded`, `.unobservable`), região, estratégia de medição, confiança, métricas agregadas, veredito de prontidão, score, causa primária, causas secundárias, recomendações geradas e versão das regras (`readiness-v2.0`, `deep-load-impact-v2`).

### 3.6 Snapshot do widget por plataforma (Decisão 88)

O widget não lê SwiftData/JSON de histórico diretamente nem busca imagem pela rede. Depois de um Check válido, a aplicação materializa um snapshot substituível com o contexto necessário para repetir a medição (jogo, plataforma, vínculo externo, região, métricas e veredito) e uma miniatura editorial derivada da fonte oficial daquele cliente.

- **iOS:** o app resolve o contexto no catálogo assinado local do iOS e grava snapshot e miniatura no App Group do iOS; a extensão WidgetKit só lê esse material local.
- **Android:** o app resolve o contexto no catálogo assinado local do Android e grava snapshot com o nome do resource editorial local no armazenamento privado; o `AppWidgetProvider` só lê esse material local e o resource da própria build.
- A revisão de catálogo ou de arte invalida a representação anterior de modo gracioso: mantém CTA contextual sem métrica antiga quando o jogo ainda for reconhecido, ou cai na identidade neutra. Não há cache compartilhado entre plataformas, upload, telemetria nova, endpoint ou nova regra de veredito.
- O deep link contém apenas o identificador local do jogo e o app revalida o contexto antes de iniciar o Check. Jogo ausente, catálogo inválido, contexto incompatível ou sessão já ativa não iniciam medição; o app mostra o estado recuperável correspondente.

## 4. Componentes e fronteiras

```mermaid
flowchart LR
    UI[UI] --> USE[Casos de uso]
    USE --> CTX[Resolvedor de contexto]
    USE --> SESS[Coordenador de sessão]
    SESS --> PATH[Observador de rede]
    SESS --> GW[Probe Gateway Local]
    SESS --> PROBE[Adaptador de probe UDP]
    SESS --> LOAD[Adaptador de carga HTTP]
    SESS --> QUAL[Sample Quality Watchdog]
    SESS --> NGQE[NGQE]
    CTX --> CAT[Repositório do catálogo]
    NGQE --> LOADIMP[Avaliador de Carga Multidimensional]
    LOADIMP --> INT[Interpretador de Causas e Coocorrência]
    INT --> REC[Motor de Recomendações]
    REC --> RDY[Game Readiness Evaluator]
    RDY --> HIST[Repositório de histórico]
    RDY --> TEL[Telemetria anônima Worker]
```

| Componente | Dono | Entrada | Saída |
| --- | --- | --- | --- |
| Repositório do catálogo | Dados | Envelope local assinado | Catálogo válido e versionado ou indisponibilidade explícita. |
| Resolvedor de contexto | Domínio | Jogo, mercado, plataforma e catálogo | Perfil, regiões, alvo, confiança e regras aplicáveis. |
| Coordenador de sessão | Aplicação | Contexto resolvido e intenção de Check | Estado de sessão, cancelamento ou amostras finalizadas. |
| Observador de rede | Infraestrutura | Estado do caminho de rede | Evento de mudança de interface que descarta a sessão. |
| Probe Gateway Local | Infraestrutura | Gateway dinâmico resolvido | RTT/loss local ou marcação de `.unobservable`. |
| Adaptador de probe UDP | Infraestrutura | Alvo e plano de amostragem | Amostras válidas, timeouts ou falha de transporte. |
| Adaptador de carga HTTP | Infraestrutura | Cenário de carga | Sinal de carga e métricas de transferência. |
| Watchdog de qualidade | Domínio | Amostras iniciais de UDP | Confirmação de qualidade ou abort precoce. |
| NGQE | Domínio | Amostras, perfil e regras | Métricas calculadas, score 0–100 e guardrails aplicados. |
| Avaliador de carga | Domínio | Amostras de repouso e carga | Classificação de materialidade (`deep-load-impact-v2`). |
| Interpretador de causas | Domínio | Métricas, delta de carga e probe local | Causa primária e sintomas secundários objetivos. |
| Motor de recomendações | Domínio | Causa primária e sintomas confirmados | 1 a 3 ações práticas ordenadas por impacto. |
| Game Readiness Evaluator | Domínio | Métricas, sintomas, perfil e confiança | `GameReadinessVerdict` (`.ready`, `.caution`, `.notReady`, `.inconclusive`). |
| Repositório de histórico | Dados | Veredito, regras e métricas | Histórico local por jogo no SwiftData. |
| Telemetria de retenção | Infraestrutura | Eventos de ciclo (start, verdict, retest) | Evento anônimo enviado a `/v1/telemetry`. |

## 5. Fluxos arquiteturais críticos

### 5.1 Quick Check

```mermaid
sequenceDiagram
    participant UI as Interface
    participant CAT as Catálogo
    participant S as Coordenador
    participant N as Caminho de rede
    participant P as Probe UDP
    participant Q as NGQE
    participant H as Histórico local

    UI->>CAT: carrega catálogo válido
    UI->>S: inicia Quick Check
    S->>N: fixa caminho observado
    loop aproximadamente 15 segundos
        S->>P: envia probe
        P-->>S: amostra ou timeout
        N-->>S: mudança de caminho, se houver
    end
    alt caminho mudou ou dados insuficientes
        S-->>UI: cancelado ou inconclusivo
    else sessão válida
        S->>Q: calcula métricas e score
        Q-->>S: resultado determinístico
        S->>H: persiste resultado final
        S-->>UI: resultado
    end
```

O estado parcial alimenta somente a tela durante o teste. Score, classificação, causa e recomendação são calculados uma única vez no término de uma sessão válida.

### 5.2 Deep Check (Wi-Fi e Rede Móvel)

O Deep Check reutiliza a resolução de contexto do Quick Check e opera tanto em **Wi-Fi** quanto em **rede móvel** (Decisão 36). Em rede móvel, o início da fase de carga exige consentimento explícito do usuário, informando o limite máximo de dados (até 10 MB). Ele divide a sessão em duas distribuições independentes:

1. fase de repouso, com probes UDP;
2. fase sob carga controlada, com probes UDP simultâneos a uma transferência HTTP controlada de até 10 MB.

Cada fase dura 15 segundos, totalizando aproximadamente 30 segundos, e executa até dois probes UDP por segundo.

O NGQE recebe ambas as séries separadas e calcula a degradação. Na fase de repouso, o Deep Check também compara a região primária com uma alternativa quando o catálogo a disponibilizar; a fase sob carga continua na região primária. O score principal representa somente a fase de repouso; a fase de carga produz um indicador separado de impacto sob carga. Uma falha de carga não invalida automaticamente as amostras de repouso, mas impede uma conclusão sobre comportamento sob carga e precisa aparecer como limitação do resultado.

Qualquer transição de caminho de rede durante a sessão (Wi-Fi ➔ celular ou celular ➔ Wi-Fi) aciona cancelamento imediato pelo `NetworkPathObserver` e descarte total de dados parciais. O histórico registra o tipo de conexão utilizado (`.wifi` ou `.cellular`), sem comparação automatizada entre elas.

### 5.3 Catálogo offline ou inválido

O mesmo catálogo assinado acompanha cada build iOS e Android. Não há atualização HTTP nem cache persistente: somente esse envelope local, depois de validar esquema, assinatura e regras de negócio, pode fornecer jogo, contexto, região ou destino de probe. Sem um catálogo válido aplicável ao jogo/contexto, o teste não começa; a UI explica que a configuração do jogo não está disponível no momento.

O catálogo local é tratado como entrada não confiável até passar por validação de esquema, versão, regras de negócio e assinatura criptográfica Ed25519. A chave privada de publicação nunca vai para o aplicativo. Um envelope malformado, corrompido ou com assinatura inválida falha fechado e não inicia medição.

### 5.3 Seleção de mercado, região e assets de catálogo

O app usa localidade/região do sistema apenas para ordenar candidatos de mercado publicados no catálogo. Dentro de uma sessão, o coordenador cria snapshot imutável do catálogo validado e faz pré-leitura UDP somente contra regiões candidatas declaradas nele. Mercado e região efetivos são resolvidos por essa pré-leitura ou por override manual explícito; viagem, VPN ou configuração regional do aparelho não autorizam fixar contexto por localidade. Não há GPS, geocodificação, IP geolocation nem destino obtido fora do catálogo. Sem candidato confirmado, não há medição nem score. A regra canônica está em [Decisão de seleção regional automática](./DECISOES.md#decisão-16).

> **Atualizado pela Decisão 71:** catálogo e artes originais remotos são autorizados nos dois apps. Não importar artes licenciadas ou oficiais de terceiros.

O catálogo assinado declara a base HTTPS e o caminho da arte. Infraestrutura valida caminho, HTTPS, MIME, bytes e dimensões; por autorização de Luiz, não confere hash do conteúdo recebido. O SHA-256 no schema permanece metadado compatível. Download/cache fica fora do domínio e é oportunista; UI recebe catálogo validado e imagem decodificada, sem interpretar JSON. Android deriva apresentação e plataformas do catálogo, usando registro local apenas para fallback.

O cache de imagens é separado do catálogo: falha de imagem não invalida contexto de medição. Imagens são chaveadas por URL/revisão, revalidadas após 24 h e limitadas a 50 MiB. A Home abre com o catálogo local válido e arte local/neutra imediata. Transferências de imagem são canceladas durante preparação/medição e background.

O Worker publica duas rotas públicas: `/v1/load` e `/v1/telemetry`. A carga entrega até 10 MB sem cache e só é usada pelo Deep Check. Não há API autenticada, banco de dados ou endpoint individual por jogo no MVP. O catálogo não passa pelo Worker.

### 5.4 Publicidade no MVP1.1

**Estado vigente:** a Decisão 96 substitui o banner Android da Decisão 82 por anúncios nativos em Home, Histórico, Jogos e Resultado; a Decisão 97 estende essas quatro superfícies ao iOS. O SDK fica na camada de app, condicionado a UMP e à política de posicionamento; domínio, medição e telemetria não recebem dados de anúncio.

O plano inicial do cliente iOS não continha publicidade. A entrada agora autorizada pela Decisão 97 exige contrato de privacidade, revisão de design e gates de release próprios; jamais poderá interferir em medição, score, veredito ou histórico.

## 6. Contratos arquiteturais

Os contratos detalhados serão formalizados na especificação técnica. Nesta camada, valem estas garantias:

| Contrato | Garantia |
| --- | --- |
| `GameCatalogRepository` | Entrega somente catálogo validado, assinado, versionado e aplicável ou erro explícito. |
| `MeasurementTransport` | Entrega amostras, timeouts e erros de transporte sem calcular métricas. |
| `NetworkPathObserver` | Informa mudança relevante de caminho durante uma sessão; não mistura estados. |
| `QualityEvaluator` | Produz sempre o mesmo resultado para o mesmo conjunto de amostras e perfil. |
| `ResultInterpreter` | Traduz resultado técnico em sintomas honestos observados. |
| `GameReadinessEvaluator` | Arbitra a decisão semântica de prontidão de partida (`GameReadinessVerdict`) a partir dos sintomas e perfil do jogo. |
| `HistoryRepository` | Persiste somente resultados finais, veredito e contexto necessário para interpretá-los depois. |

O MVP não possui fallback HTTP ou ICMP para um destino UDP bloqueado. Quando o transporte não gera as 10 respostas válidas mínimas, a sessão termina como inconclusiva e mantém a semântica de medição gamer intacta.

## 7. Privacidade e segurança por desenho

- Resultados e histórico são locais por padrão.
- O teste não exige login, identificador pessoal nem envio de cada amostra para um servidor próprio.
- O catálogo não inclui dados pessoais nem permite texto livre que altere a interpretação técnica.
- O envelope local é autenticado por assinatura Ed25519; serviços auxiliares usam canais seguros e não alteram o catálogo.
- O aplicativo não tenta descobrir, escanear ou atacar servidores de jogos. Só usa destinos permitidos e configurados no catálogo.
- A telemetria mínima de produto para validação de retenção (Decisão 50) envia apenas um ID de instalação aleatório e eventos de funil a `/v1/telemetry`, sem endereço IP, amostras de rede brutas ou dados de conta.

## 8. Evolução sem reescrita

### 8.1 Novos destinos de probe

O domínio trabalha com uma abstração de alvo de medição. Um destino oficial, infraestrutura de jogo, proxy regional gamer ou destino genérico são variações configuráveis de estratégia. É possível adicionar novos provedores de probe sem mudar fórmula, telas ou histórico.

### 8.2 Android oficial (Decisões 67–69)

O port Android em `android/` preserva os contratos de catálogo e as regras determinísticas do iOS, com adaptadores próprios de transporte, rádio, persistência e apresentação. Estrutura, versões das regras e a divergência autorizada do gateway estão em [Arquitetura Android](./08-arquitetura-android.md). A validação local e seus limites estão na [auditoria de paridade](../audits/android-ios-code-parity-2026-10-03.md).

Não há premissa de código compartilhado no MVP iPhone. A portabilidade vem dos contratos, catálogo versionado e comportamento determinístico, não de uma escolha prematura de framework multiplataforma.

### 8.3 Operação em Wi-Fi e celular
 
Com a Decisão 36, o Check Completo opera tanto em Wi-Fi quanto em rede celular (com consentimento prévio para a carga HTTP de até 10 MB). Na V1, uma mudança de caminho durante a sessão cancela imediatamente a medição sem persistência parcial; o app não inicia comparação automatizada entre redes diferentes e nunca trata resultado de Wi-Fi e rede móvel como equivalentes.

### 8.4 Monetização futura

Qualquer monetização, inclusive publicidade prevista para MVP1.1, é uma camada de aplicação. Ela não deve alterar o domínio de medição ou score e não integra o MVP1.

## 9. Requisitos arquiteturais de qualidade

| Qualidade | Diretriz |
| --- | --- |
| Confiabilidade e Integridade | Sessões são canceladas ou inconclusivas quando os dados não permitem conclusão honesta. Diagnósticos causais exigem medição isolada real; o app nunca acusa o Wi-Fi ou a operadora sem evidência comprovada (Decisão 50). |
| Desempenho | Cálculo local e incremental; o resultado não espera um backend. |
| Resiliência | Cache de catálogo válido e recuperação clara de erro de rede. |
| Testabilidade | NGQE, resolvedor, interpretador e `GameReadinessEvaluator` são puros/independentes de UI e transportes. |
| Observabilidade | Telemetria anônima, enxuta e sem PII/IP via Cloudflare Worker existente (`POST /v1/telemetry`) para mensurar retenção e reteste real entre sessões (Decisão 50). |
| Evolução | Perfis e catálogo versionados; adaptadores substituíveis. |
| Acessibilidade e idioma | Toda conclusão e estado relevante funciona em PT-BR e inglês; localização não modifica regras de score. |

## 10. Decisões em aberto antes da especificação técnica
