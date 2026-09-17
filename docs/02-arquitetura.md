# Nolaggy — arquitetura do MVP

**Status:** rascunho inicial para V1  
**Plataforma inicial:** iPhone (iOS 17 ou superior)  
**Documento relacionado:** [Documentação funcional](./01-funcional.md)

> **Decisões fechadas:** a distribuição iOS usa o Apple Developer Program já existente. Fora dessa conta, o MVP tem meta de custo operacional recorrente zero. O catálogo remoto será publicado por um Cloudflare Worker no plano gratuito, sem banco de dados.
> A App Store pode distribuir o app globalmente, mas o catálogo com suporte oficial do MVP começa em Brasil e Estados Unidos.
> AdMob, UMP e banners não entram no MVP1. A monetização por anúncios é recorte de MVP1.1 e só poderá introduzir biblioteca, IDs, consentimento e gates próprios nessa etapa.

## 1. Objetivo arquitetural

O Nolaggy deve entregar uma avaliação confiável da experiência de jogo no iPhone com o mínimo de infraestrutura própria. A arquitetura privilegia medição no dispositivo, resultado determinístico, privacidade por padrão e evolução do catálogo sem publicação de uma nova versão.

O princípio central é simples: **o app mede; o catálogo orienta; o motor interpreta; o backend não participa de cada teste**.

```mermaid
flowchart LR
    U[Jogador] --> A[Nolaggy no iPhone]
    A --> C[Catálogo remoto]
    A --> P[Destinos de probe gamer]
    A --> H[Histórico local]

    subgraph A[Nolaggy no iPhone]
        UI[Experiência e jornadas]
        ORQ[Orquestrador de medição]
        ENG[Motor de qualidade de jogo]
        RES[Interpretador de resultado]
        UI --> ORQ --> ENG --> RES --> UI
    end
```

## 2. Visão do sistema

| Bloco | Responsabilidade | Não é responsabilidade |
| --- | --- | --- |
| App Nolaggy | Experiência, coleta, cálculo, explicação e histórico. | Depender de backend para calcular score ou armazenar cada teste. |
| Catálogo remoto | Cloudflare Worker gratuito que publica jogos, perfis, regiões, limites e flags versionados. | Receber telemetria de probes ou decidir o score de uma sessão. |
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

Contém as superfícies de Home, descoberta de jogos, seleção de plataforma, Quick Check, Deep Check, resultado, detalhes, histórico e estados de erro.

Essa camada só apresenta estado pronto para uso. Ela não calcula métricas, escolhe endpoints, interpreta UDP nem aplica regras de classificação.

### 3.2 Aplicação e orquestração

Coordena os casos de uso: carregar catálogo, selecionar contexto de jogo, iniciar/cancelar uma sessão e persistir resultado.

O **Measurement Session Coordinator** é o dono do ciclo de uma medição. Ele garante que só exista uma sessão ativa por vez, reage à mudança de caminho de rede e mantém o resultado parcial separado do resultado final.

### 3.3 Domínio de qualidade de jogo

É o núcleo determinístico, independente de tela, transporte ou fornecedor de endpoint. Inclui:

- resolução do contexto de teste a partir de jogo, mercado, plataforma e catálogo;
- agregação de amostras e validação de sessão;
- cálculo de P50, P95, P99, jitter, perda, spikes, consistência e comportamento sob carga;
- aplicação dos pesos, limites e guardrails do perfil;
- geração do Nolaggy Score, classificação, causa principal, recomendação e confiança;
- comparação de regiões quando esse modo for habilitado pelo catálogo.

O domínio recebe dados de entrada tipados e devolve um resultado completo. Não acessa UI, armazenamento, HTTP, UDP nem estado global do iOS.

### 3.4 Infraestrutura do dispositivo e integrações

Implementa adaptadores para capacidades externas:

- transporte UDP para probes;
- carga HTTP controlada do Deep Check;
- observação de caminho de rede e mudança entre Wi-Fi/celular;
- obtenção de idioma e localidade do sistema somente para apresentação e ordenação inicial de mercados publicados; nunca para localizar a pessoa;
- acesso a armazenamento local;
- cliente de catálogo remoto e cache;
- relógio, agendamento e cancelamento de operações.

Esses adaptadores obedecem contratos definidos pelo domínio e pela aplicação. Trocar um destino de probe não pode alterar a regra de score.

### 3.5 Dados locais e catálogo

Há duas famílias de dados:

| Família | Origem | Uso | Regra de retenção inicial |
| --- | --- | --- | --- |
| Configuração de catálogo | Base embarcada no app, atualizada remotamente e com cache local. | Jogos, regiões, perfis, limites, textos parametrizados e flags. | Atualizar no máximo a cada 24 h; usar última versão válida por até 30 dias; depois, voltar à base embarcada. |
| Dados do jogador | Criados no dispositivo em SwiftData. | Preferências, recentes/favoritos e histórico de resultados. | Permanecem locais por até 90 dias, com máximo de 100 medições por jogo e exclusão manual nas configurações. |

O histórico armazena o resultado contextualizado e a versão das regras usadas: jogo, plataforma, tipo de rede declarado, região, estratégia de medição, confiança, métricas agregadas, score, classificação, causa e versão de catálogo/perfil. Amostras brutas só devem ser persistidas se forem necessárias para detalhes e diagnóstico local; elas não são requisito para sincronização remota no MVP.

## 4. Componentes e fronteiras

```mermaid
flowchart LR
    UI[UI] --> USE[Casos de uso]
    USE --> CTX[Resolvedor de contexto]
    USE --> SESS[Coordenador de sessão]
    SESS --> PATH[Observador de rede]
    SESS --> PROBE[Adaptador de probe UDP]
    SESS --> LOAD[Adaptador de carga HTTP]
    SESS --> NGQE[NGQE]
    CTX --> CAT[Repositório do catálogo]
    NGQE --> INT[Interpretador]
    INT --> HIST[Repositório de histórico]
```

| Componente | Dono | Entrada | Saída |
| --- | --- | --- | --- |
| Repositório do catálogo | Dados | Configuração remota/cache | Catálogo válido e versionado ou indisponibilidade explícita. |
| Resolvedor de contexto | Domínio | Jogo, mercado, plataforma e catálogo | Perfil, regiões, alvo, confiança e regras aplicáveis. |
| Coordenador de sessão | Aplicação | Contexto resolvido e intenção de Quick/Deep Check | Estado de sessão, cancelamento ou amostras finalizadas. |
| Observador de rede | Infraestrutura | Estado do caminho de rede | Evento de mudança que invalida a sessão. |
| Adaptador de probe UDP | Infraestrutura | Alvo e plano de amostragem | Amostras válidas, timeouts ou falha de transporte. |
| Adaptador de carga HTTP | Infraestrutura | Cenário de carga | Sinal de carga e métricas auxiliares da fase Deep Check. |
| NGQE | Domínio | Amostras, perfil e regras | Métricas calculadas, score e guardrails aplicados. |
| Interpretador | Domínio | Resultado do NGQE e confiança | Conclusão, causa e recomendação localizáveis. |
| Repositório de histórico | Dados | Resultado final | Histórico local por jogo. |

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

### 5.2 Deep Check

O Deep Check reutiliza a resolução de contexto do Quick Check, porém só é habilitado em Wi-Fi na V1 para não consumir dados móveis. Ele divide a sessão em duas distribuições independentes:

1. fase de repouso, com probes UDP;
2. fase sob carga controlada, com probes UDP simultâneos a uma transferência HTTP controlada de até 10 MB.

Cada fase dura 15 segundos, totalizando aproximadamente 30 segundos, e executa até dois probes UDP por segundo.

O NGQE recebe ambas as séries separadas e calcula a degradação. Na fase de repouso, o Deep Check também compara a região primária com uma alternativa quando o catálogo a disponibilizar; a fase sob carga continua na região primária. O score principal representa somente a fase de repouso; a fase de carga produz um indicador separado de impacto sob carga. Uma falha de carga não invalida automaticamente as amostras de repouso, mas impede uma conclusão sobre comportamento sob carga e precisa aparecer como limitação do resultado.

### 5.3 Catálogo offline ou inválido

O app tenta atualizar o catálogo antes de começar um teste, sem impedir a abertura da Home, e no máximo uma vez a cada 24 horas. Se não houver conexão, pode usar o último catálogo local válido por até 30 dias. Depois desse prazo, retorna ao catálogo-base embarcado no app. Sem um catálogo válido aplicável ao jogo/contexto, o teste não começa; a UI explica que a configuração do jogo não está disponível no momento.

O catálogo é tratado como entrada não confiável até passar por validação de esquema, versão, regras de negócio e assinatura criptográfica Ed25519. O app só aceita um `catalog.json` cuja assinatura corresponda à chave pública embarcada; a chave privada de publicação nunca vai para o aplicativo. Um catálogo malformado, corrompido ou com assinatura inválida não pode sobrescrever a última versão válida nem derrubar o app.

### 5.3 Seleção de mercado, região e assets de catálogo

O app usa localidade/região do sistema apenas para ordenar candidatos de mercado publicados no catálogo. Dentro de uma sessão, o coordenador cria snapshot imutável do catálogo validado e faz pré-leitura UDP somente contra regiões candidatas declaradas nele. Mercado e região efetivos são resolvidos por essa pré-leitura ou por override manual explícito; viagem, VPN ou configuração regional do aparelho não autorizam fixar contexto por localidade. Não há GPS, geocodificação, IP geolocation nem destino obtido fora do catálogo. Sem candidato confirmado, não há medição nem score. A regra canônica está em [Decisão de seleção regional automática](./16-decisao-selecao-regional-automatica.md).

> **Substituído para a V1:** os três parágrafos abaixo descrevem o pipeline de assets remotos assinados como estava previsto originalmente. A [Decisão de identidade visual neutra dos jogos](./18-decisao-identidade-visual-neutra-de-jogos.md) substitui esse pipeline para a V1: não há asset remoto, URL, hash ou cache de imagem por jogo no catálogo assinado atual. A miniatura é um componente neutro do design system, sem mapeamento por jogo. O texto abaixo permanece como referência para uma eventual reintrodução de arte licenciada, mediante nova decisão.

O catálogo assinado pode referenciar assets remotos de jogos por URL HTTPS, hash de conteúdo, tipo MIME e limite de tamanho. A assinatura autoriza a referência; o app ainda valida esquema, host permitido, HTTPS, hash e limites antes de disponibilizar a imagem para a UI. Nenhuma tela interpreta URL ou JSON remoto diretamente.

O cache de imagens é separado do cache do catálogo: apagar, expirar ou falhar uma imagem não invalida um contexto de medição já válido. O cache do catálogo continua válido por até 30 dias; imagens podem ser descartadas antes por pressão de armazenamento, expiração HTTP ou troca de hash. A Home abre com o último catálogo válido e placeholders neutros para imagens ausentes, iniciando atualização de catálogo e assets em segundo plano sem bloquear a navegação ou uma medição válida.

O Worker publica duas rotas públicas: `/v1/catalog.json` e `/v1/load`. O catálogo contém metadados de versão e validade, jogos, perfis de score e regiões/destinos de probe. A rota de carga entrega até 10 MB sem cache e só é usada pelo Deep Check em Wi-Fi. Não há API autenticada, banco de dados ou endpoint individual por jogo no MVP.

Enquanto não houver domínio próprio, o Worker usa uma URL `workers.dev` gratuita como endpoint temporário do catálogo. Ela não é exposta na interface; o catálogo-base embarcado e a validação de assinatura preservam o funcionamento se esse endpoint falhar. Quando existir domínio próprio, a URL é substituída sem mudar o contrato ou o aplicativo.

### 5.4 Publicidade no MVP1.1

O MVP1 não contém publicidade: não há AdMob, UMP, banner, consentimento de anúncios, IDs de unidade ou espaço reservado na interface. A eventual entrada no MVP1.1 será uma decisão separada, com contrato de privacidade, revisão de design e gates de release próprios; jamais poderá interferir em medição, score, resultado ou histórico.

## 6. Contratos arquiteturais

Os contratos detalhados serão formalizados na especificação técnica. Nesta camada, valem estas garantias:

| Contrato | Garantia |
| --- | --- |
| `GameCatalogRepository` | Entrega somente catálogo validado, assinado, versionado e aplicável ou erro explícito. |
| `MeasurementTransport` | Entrega amostras, timeouts e erros de transporte sem calcular métricas. |
| `NetworkPathObserver` | Informa mudança relevante de caminho durante uma sessão; não mistura estados. |
| `QualityEvaluator` | Produz sempre o mesmo resultado para o mesmo conjunto de amostras e perfil. |
| `ResultInterpreter` | Traduz resultado técnico em causa/recomendação sem alterar score ou confiança. |
| `HistoryRepository` | Persiste somente resultados finais e contexto necessário para interpretá-los depois. |

O MVP não possui fallback HTTP ou ICMP para um destino UDP bloqueado. Quando o transporte não gera as 10 respostas válidas mínimas, a sessão termina como inconclusiva e mantém a semântica de medição gamer intacta.

## 7. Privacidade e segurança por desenho

- Resultados e histórico são locais por padrão.
- O teste não exige login, identificador pessoal nem envio de cada amostra para um servidor próprio.
- O catálogo não inclui dados pessoais nem permite texto livre que altere a interpretação técnica.
- A comunicação com catálogo e serviços auxiliares usa canais seguros; a implementação define autenticação de conteúdo, cache e estratégia de atualização.
- O aplicativo não tenta descobrir, escanear ou atacar servidores de jogos. Só usa destinos permitidos e configurados no catálogo.

## 8. Evolução sem reescrita

### 8.1 Novos destinos de probe

O domínio trabalha com uma abstração de alvo de medição. Um destino oficial, infraestrutura de jogo, proxy regional gamer ou destino genérico são variações configuráveis de estratégia. É possível adicionar novos provedores de probe sem mudar fórmula, telas ou histórico.

### 8.2 Android futuro

A versão Android futura deverá preservar os contratos de catálogo, métricas, NGQE, resultado e histórico. Os adaptadores de transporte, observação de rede, persistência e apresentação serão específicos da plataforma.

Não há premissa de código compartilhado no MVP iPhone. A portabilidade vem dos contratos, catálogo versionado e comportamento determinístico, não de uma escolha prematura de framework multiplataforma.

### 8.3 Comparação Wi-Fi e celular

A comparação explícita entre Wi-Fi e rede celular fica fora do MVP e é candidata à V1.1. Na V1, uma mudança de caminho durante a sessão cancela a medição; o app não inicia comparação automatizada e não habilita Deep Check em rede celular sem uma evolução específica desse fluxo.

### 8.4 Monetização futura

Qualquer monetização, inclusive publicidade prevista para MVP1.1, é uma camada de aplicação. Ela não deve alterar o domínio de medição ou score e não integra o MVP1.

## 9. Requisitos arquiteturais de qualidade

| Qualidade | Diretriz |
| --- | --- |
| Confiabilidade | Sessões são canceladas ou inconclusivas quando os dados não permitem conclusão honesta. |
| Desempenho | Cálculo local e incremental; o resultado não espera um backend. |
| Resiliência | Cache de catálogo válido e recuperação clara de erro de rede. |
| Testabilidade | NGQE, resolvedor e interpretador são puros/independentes de UI e transportes. |
| Observabilidade | O MVP não coleta telemetria própria. Produto usa somente dados agregados disponibilizados por App Store Connect e feedback voluntário; qualquer telemetria futura será agregada e sem amostras brutas ou identificadores pessoais por padrão. Esses mesmos dados agregados (sessões, retenção, avaliações) são o critério de saída do MVP1 antes de comprometer escopo do MVP1.1 — ver [Funcional §13.1](./01-funcional.md#131-critério-de-saída-do-mvp1). |
| Evolução | Perfis e catálogo versionados; adaptadores substituíveis. |
| Acessibilidade e idioma | Toda conclusão e estado relevante funciona em PT-BR e inglês; localização não modifica regras de score. |

## 10. Decisões em aberto antes da especificação técnica
