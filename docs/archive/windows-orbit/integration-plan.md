> **Histórico (Decisão 118).** Registro da primeira versão da biblioteca do Windows, quando ela ainda tinha um nome interno que foi abandonado. O que vale hoje está em `docs/09-design-system-windows.md` e na Decisão 118 de `docs/DECISOES.md`. Este arquivo não é mais atualizado.

# LagCheck ORBIT — Plano de Integração e Auditoria Técnica

> **Documento de Auditoria e Integração (Fases 1 e 2)**  
> **Status:** Proposta técnica submetida para avaliação e aprovação da Squad e do Dono do Produto (Luiz).  
> **Branch de trabalho:** `feature/orbit-playnite-integration`  
> **Data:** 11 de novembro de 2026.

---

## 1. Fase 1 — Auditoria do Repositório Atual

### 1.1 Estrutura de Diretórios, Tecnologias e Dependências

O LagCheck possui uma arquitetura unificada multi-alvo:
- **iOS:** Código nativo em Swift / SwiftUI (`Sources/`, `Nolaggy.xcodeproj`).
- **Android:** Código nativo em Kotlin / Jetpack Compose (`android/app/`).
- **Core Compartilhado:** Bibliotecas Kotlin puras (`android/core/`) que concentram todo o domínio de diagnóstico determinístico de rede, regras de negócio e catálogo.
- **Windows Desktop:** Implementado no subprojeto `android/desktop/` (originado nas Decisões 114, 115 e 116), estruturado sobre o mesmo repositório e integrado aos módulos `core`.

```text
android/
├── core/
│   ├── domain/           # Regras de avaliação, modelos, cálculo de veredito e recomendações
│   ├── catalog/          # Verificador e resolvedor do catálogo de jogos e regiões
│   ├── network/          # Sondas UDP, codecs (STUN, Steam A2S, PlayFab QoS), tráfego de carga HTTP
│   ├── session/          # Orquestrador de medições (repouso + carga), cálculo de RTT/jitter/perda
│   ├── telemetry-radio/  # Snapshots de rádio (mobile)
│   └── designsystem/     # Tokens e componentes Jetpack Compose Android
├── desktop/              # Aplicação desktop Windows (Compose Desktop sobre core)
│   ├── src/main/kotlin/  # AppState, Measurement, UI (Shell, Screens, Map), Update, Analytics
│   ├── src/main/resources/ # Fontes Google Sans Flex, ícone .ico, grade do mapa (Natural Earth)
│   ├── src/test/kotlin/  # Testes unitários desktop (Update, Location, Analytics, Map)
│   ├── build.gradle.kts  # Configuração Gradle, JVM 17, empacotador Compose Desktop
│   └── PACKAGING.md      # Instruções de build, empacotamento MSI/EXE e release
└── settings.gradle.kts
```

#### Dependências e Stack Técnico
- **Linguagem / Runtime:** Kotlin 2.0+ direcionado para JVM 17 (`jvmTarget = JVM_17`).
- **Interface Gráfica:** Jetpack Compose Multiplatform for Desktop (`org.jetbrains.compose.desktop`), renderizado com aceleração por hardware via Skia Graphics Engine.
- **Concorrência:** `kotlinx.coroutines.core` para processamento assíncrono não-bloqueante.
- **Networking da UI:** Módulo padrão `java.net.http` (HttpClient da JDK 11+) para consultas de atualização no GitHub Releases, telemetria GA4 e geolocalização aproximada por IP.
- **Networking de Diagnóstico:** Java NIO DatagramChannel nativo no `core:network` para sondagem UDP de micro-latência com precisão de nanossegundos.

---

### 1.2 Funcionalidades Existentes do LagCheck Windows

1. **Diagnóstico Determinístico de Conexão:**
   - **Check Geral de Conexão:** Medição contra a região de referência mais próxima (`Platform.PC`), sem exigir escolha de jogo.
   - **Check Específico por Jogo:** Medição contra servidores de catálogo autorizados (atualmente 40 jogos autorizados para PC no catálogo oficial).
2. **Avaliação Semântica e Métricas Oficiais:**
   - Classificação inequívoca: `● PRONTO PARA RANKED`, `▲ EU EVITARIA RANKED AGORA`, `▲ CONDIÇÕES INSTÁVEIS` ou `— INCONCLUSIVO`.
   - Métricas calculadas: Latência (mediana de RTT em ms), Jitter (RFC 3550 / variação de latência em ms) e Perda de Pacotes (% exata).
   - Detecção de degradação sob carga (bufferbloat) contrastando as fases de Repouso e Carga.
3. **Cockpit e Visualização de Rota (Mapa Integrado):**
   - Projeção geográfica matricial desenhada em Canvas Compose (grade Natural Earth 110m).
   - Resolução de localização aproximada por IP via endpoint leve `GET /v1/approx-location` do `lagcheck-site` (coordenadas truncadas a 0,5° e cidade/país, sem log e com cache local de 24h).
   - Animação de arco de rota e pacotes sincronizados estritamente com as sondas UDP reais comunicadas pelo `core:session`.
4. **Navegação e Janela Desktop:**
   - Janela redimensionável normal (1120×740 padrão, mínimo 900×600) com controles de minimizar, restaurar e fechar.
   - Barra lateral compacta de navegação: Início, Jogos, Histórico, Ajustes (e galeria `--ds` para validação interna de componentes).
5. **Histórico da Sessão:**
   - Armazenamento em memória das medições realizadas na sessão atual com métricas, veredito e rota.
6. **Atualizador de Versão Integrado:**
   - Verificação em segundo plano contra o GitHub Releases oficial (`gmmattey/lagcheck`, tags `windows-vX.Y.Z`).
   - Download seguro com verificação rigorosa de integridade criptográfica via hash SHA-256 antes da execução do instalador.
7. **Telemetria de Produto com Proteção de Privacidade:**
   - Envio de eventos anônimos de funil de medição ao Google Analytics 4 via Measurement Protocol.
   - Respeito integral à privacidade: sem envio de IP, endereços MAC, dados de usuário ou amostras brutas de rede.
   - Opção explícita de desativação (opt-out) nas configurações.
8. **Controle de Acessibilidade e Movimento:**
   - Chave "Reduzir Movimento" que desativa animações de mapa, pulsos do anel circular e transições de tela.
   - Suporte completo a navegação por teclado (Tab, Enter, Espaço) e foco visualmente destacado.
9. **Modos de Linha de Comando e Automação:**
   - `--cli`: Execução de diagnóstico via terminal sem abrir janela gráfica (usado para testes contínuos e scripts).
   - `--shots`: Geração automatizada de capturas de tela (screenshots) das telas para validação visual contínua.

---

### 1.3 Mecanismo de Diagnóstico de Rede

O diagnóstico de rede não utiliza `ping` ICMP de sistema operacional nem requisições HTTP triviais:
- **Motor UDP:** Localizado em `com.lagcheck.network.transport.UdpProbeTransport`.
- **Codecs Suportados:**
  - *STUN (RFC 5389/8489):* Para servidores de infraestrutura geral e gateways.
  - *Steam Query A2S:* Protocolo oficial de sondagem de servidores Source/Steam (`A2S_INFO` e `A2S_PING`).
  - *PlayFab QoS:* Protocolo de sondagem da nuvem de servidores de jogos Microsoft/Azure PlayFab.
- **Protocolo de Medição:**
  - *Fase 1 (Repouso):* 30 sondas UDP disparadas com cadência controlada (intervalos de 50 a 100 ms).
  - *Fase 2 (Carga):* 30 sondas UDP adicionais disparadas simultaneamente à geração de carga downstream via `HttpLoadTransport` consumindo o endpoint leve `/v1/load` do worker Cloudflare.
- **Cálculo Determinístico:**
  - O `ProbeLedger` registra timestamps em nanossegundos no momento exato do envio e da recepção do datagrama.
  - O `GameReadinessEvaluator` (em `core:domain`) calcula RTT mediano, percentual de perda e jitter diferencial.
  - Se a rota não responder com o número mínimo exigido de pacotes válidos, o resultado é **obrigatoriamente Inconclusivo**. Nunca há interpolação fictícia ou estimativa inventada.

---

### 1.4 Sistema de Navegação, Design System e Componentes Reutilizáveis

O design system desktop herda as premissas da **Dark Competitive UI** do LagCheck (`docs/04-design-system.md` e `docs/09-design-system-windows.md`):
- **Tokens Canônicos (`com.lagcheck.desktop.ds.Tokens.kt`):**
  - Fundo quase preto: `#0B0D10` (`LcColor.Background`).
  - Superfícies grafite: `#15181E` (`LcColor.Panel`) e `#1E232B` (`LcColor.PanelElevated`).
  - Bordas discretas: 1 px em `#262B34` (`LcColor.Border`) e `#1E232B` (`LcColor.BorderHairline`).
  - Tipografia: Google Sans Flex embarcada em pesos Regular, Medium, SemiBold e Bold; algarismos monoespaçados tabulares.
  - Destaques semânticos: Verde `#22C55E` (Excelente / Pronto), Âmbar `#F59E0B` (Atenção / Picos), Coral Solar `#FF5A36` (Erro / Instável).
- **Componentes de UI Reutilizáveis (`Components.kt`):**
  - `Interactive`: Envoltório para elementos clicáveis com estados de hover, foco visível (anel de 2 dp) e suporte a teclado.
  - `PrimaryButton` e `SecondaryButton`.
  - `Panel`: Superfície escura com borda fina de 1 px.
  - `CircularGauge`: Anel central com animação de pulso em repouso e indicação de progresso.
  - `LatencyChart`: Gráfico de linha em tempo real exibindo a série temporal de pings e marcador da fase de carga.
  - `VerdictHeadline` e `StatusMarker`: Identificadores com barra colorida vertical.
  - `SidebarItem`, `PageHeader`, `SectionLabel`, `MetricTile`, `EmptyState`, `SearchField`, `GameArtwork`.
- **Arquitetura de Navegação (`ui/Shell.kt`):**
  - Janela dividida em: Barra Lateral (navegação compacta) + Barra Superior (migalhas de pão e contexto) + Área de Trabalho Central.
  - Transições suaves controladas por `Crossfade` com easing `cubic-bezier(.2, 0, 0, 1)`.

---

### 1.5 Pipeline de Build, Empacotamento e Distribuição

- **Gradle Plugin:** `org.jetbrains.compose` (Compose Multiplatform).
- **Target Formats:** MSI e EXE para Windows x64.
- **Empacotamento Interno:** Executado via `jpackage` com `jlink` para criação de uma imagem modular enxuta da JVM (incluindo o módulo obrigatório `java.net.http`).
- **Comandos Principais:**
  - `./gradlew :desktop:createDistributable`: Gera diretório com binários descompactados (`LagCheck.exe` + runtime embutido).
  - `./gradlew :desktop:packageExe`: Gera o instalador executável Windows.
  - `./gradlew :desktop:packageMsi`: Gera o instalador MSI corporativo.
  - `./gradlew :desktop:shots`: Bateria de capturas de tela automatizadas.
- **Parametrização:** Versão padronizada via `-Plagcheck.version=X.Y.Z` (obrigatório formato `MAJOR.MINOR.PATCH`).
- **Assinatura de Código:** Não configurada na base atual (executáveis não assinados requerem aprovação no SmartScreen).

---

### 1.6 Testes Automatizados e Limitações Conhecidas

- **Testes Unitários:**
  - `android/desktop/src/test/kotlin/`: Cobertura de telemetria GA4, cliente de geolocalização IP, comparador de versões e projeção do mapa de rotas.
  - `android/core/*/src/test/kotlin/`: Mais de 100 testes unitários cobrindo todos os algoritmos de rede, codecs de pacotes e regras de avaliação de veredito.
- **Limitações Identificadas do Protótipo Windows:**
  1. *Sem persistência em disco:* O histórico é mantido somente em memória durante a sessão (`AppState.history`).
  2. *Catálogo estático mobile:* Exibe apenas a lista pré-definida de 40 jogos do catálogo do app, sem detectar os jogos reais instalados no computador.
  3. *Sem integração com launchers:* Não consegue descobrir jogos da Steam, Epic Games ou Xbox Game Pass instalados no PC.
  4. *Sem execução de jogos:* Não possui mecanismo para iniciar executáveis ou disparar URIs de inicialização de jogos.
  5. *Sem acompanhamento de processos:* Não detecta se um jogo está rodando nem contabiliza tempo de jogo.

---

## 2. Fase 2 — Avaliação e Incorporação do Playnite

### 2.1 Análise de Licença e Conformidade Legal

- **Repositório de Origem:** `https://github.com/JosefNemec/Playnite`
- **Licença do Playnite:** **MIT License** (Copyright (c) 2017 Josef Nemec).
  - Permite uso comercial, modificação, distribuição, sublicenciamento e uso privado.
  - Requisito legal: Manter o aviso de copyright e o texto da licença original em todos os arquivos ou porções substanciais do software incorporado.
- **Repositório de Extensões Oficiais:** `https://github.com/JosefNemec/PlayniteExtensions`
  - Também licenciado sob MIT License. Contém as implementações dos plugins de biblioteca Steam, Epic, GOG, Xbox, etc.
- **Dependências de Terceiros do Playnite:**
  - *LiteDB:* Licença MIT (banco de dados NoSQL embarcado em arquivo único).
  - *Newtonsoft.Json:* Licença MIT.
  - *CefSharp / WebView2:* Licença BSD-style / Microsoft SDK (utilizados no Playnite para fluxos de autenticação web de launchers).
  - *Prism / MvvmLight:* Licença MIT.

---

### 2.2 Versão de Referência e Arquitetura do Playnite

A versão estável de referência é o **Playnite 10.x**, escrito em **C# / .NET** (com suporte a .NET Framework 4.6.2 e runtime moderno) utilizando **WPF (Windows Presentation Foundation)** para apresentação desktop.

#### Módulos Estruturais do Playnite:
1. **`Playnite` (Core Library):**
   - Gerencia a base de dados central (`GameDatabase`) em LiteDB.
   - Controla o ciclo de vida dos jogos: instalação, inicialização (`GameController`), acompanhamento de processos (`ProcessMonitor`) e tempo de jogo.
2. **`Playnite.SDK`:**
   - Interface pública que expõe contratos para plugins (`LibraryPlugin`, `GenericPlugin`, `MetadataPlugin`).
3. **`Playnite.DesktopApp` / `Playnite.FullscreenApp`:**
   - UIs completas em WPF/XAML orientadas a MVVM (Desktop com visão de grade/detalhes e Fullscreen para TV/joystick).
4. **Plugins de Biblioteca (`PlayniteExtensions`):**
   - Módulos independentes responsáveis pela comunicação com clientes de jogos e plataformas (Steam, Epic, Xbox).

---

### 2.3 Mecanismos de Biblioteca e Gerenciamento de Jogos

Como o Playnite detecta, importa e executa jogos em cada plataforma no Windows:

#### A. Steam
- **Detecção do Cliente:** Localiza o executável e a pasta da Steam através do Registro do Windows:
  - `HKEY_CURRENT_USER\Software\Valve\Steam` (valor `SteamPath` e `SteamExe`).
- **Descoberta de Bibliotecas:** Lê o arquivo de configuração de texto VDF `steamapps/libraryfolders.vdf`. Este arquivo mapeia todos os diretórios de instalação de jogos (unidades de disco secundárias).
- **Detecção de Jogos Instalados:** Em cada pasta `steamapps/`, o Playnite faz o parsing dos arquivos `appmanifest_<appId>.acf` (formato Valve KeyValue). O arquivo informa:
  - `appid`: ID numérico do jogo.
  - `name`: Nome do jogo.
  - `installdir`: Pasta do executável.
  - `StateFlags`: Flag inteira indicando se o jogo está instalado e atualizado (ex: 4 = totalmente instalado).
- **Execução:** O Playnite não executa o `.exe` diretamente (o que quebraria o DRM e o overlay Steam); ele dispara a URL de protocolo registrada no Windows:
  ```text
  steam://rungameid/<appId>
  ```
- **Acompanhamento (Process Monitor):** Monitora processos filhos disparados ou consulta o status do ID via API Steam.

#### B. Epic Games Store
- **Detecção do Cliente:** Registro do Windows em `HKLM\SOFTWARE\Epic Games\EpicGamesLauncher` ou `%ProgramData%\Epic\EpicGamesLauncher\`.
- **Descoberta de Jogos Instalados:** A Epic salva arquivos de manifesto individuais em formato JSON em:
  ```text
  %ProgramData%\Epic\EpicGamesLauncher\Data\Manifests\*.item
  ```
- **Parsing do Manifesto:** Cada `.item` é um JSON contendo:
  - `DisplayName`: Nome do jogo.
  - `AppName`: Identificador único na Epic (ex: `Sugar` para Fall Guys).
  - `InstallLocation`: Caminho completo dos arquivos.
  - `LaunchExecutable`: Binário principal do jogo.
- **Execução:** Inicializado via protocolo oficial registrado no Windows:
  ```text
  com.epicgames.launcher://apps/<AppName>?action=launch
  ```

#### C. Xbox / Microsoft Store / PC Game Pass
- **Detecção de Jogos Instalados:** Utiliza as APIs WinRT de gerenciamento de pacotes do Windows (`Windows.Management.Deployment.PackageManager`) ou consulta as chaves de registro do AppX em `HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\Repository\Packages`.
- **Filtragem:** Identifica aplicativos que possuem capacidades de jogos ou declaram `xbox.live` em seu `AppxManifest.xml`.
- **Execução:** Inicialização através do protocolo de ativação de URI do aplicativo UWP (`AUMID - Application User Model ID`) ou protocolo `ms-windows-store://`.

#### D. Jogos Manuais e Executáveis Avulsos
- O Playnite permite apontar qualquer arquivo `.exe`, `.bat` ou `.lnk` (atalho do Windows).
- O lançamento ocorre via `Process.Start` nativo do Windows com acompanhamento de término do processo (`Process.WaitForExit` / eventos de saída).

#### E. Persistência de Dados e Metadados
- O Playnite utiliza **LiteDB** (banco NoSQL leve de arquivo único).
- Cada jogo é salvo com: ID único, nome, plataforma, caminhos de capa (`CoverImage`) e imagem de fundo (`BackgroundImage`), estatísticas de jogo (tempo jogado, data do último lançamento), estado de favorito e coleções.
- Metadados e capas podem ser baixados via APIs públicas (Steam Store API pública, IGDB) ou inseridos manualmente pelo usuário.

---

### 2.4 Comparação Rigorosa das Três Estratégias

| Critério | Estratégia A: Extensão Playnite | Estratégia B: Reutilização Modular (Transposição da Lógica) | Estratégia C: Fork Completo do Playnite |
| :--- | :--- | :--- | :--- |
| **Descrição** | Criar um plugin C# do LagCheck para ser instalado dentro do Playnite oficial. | Portar a lógica e algoritmos de integração (Steam, Epic, Xbox, Launcher) diretamente para a arquitetura desktop do LagCheck. | Clonar o repositório C#/WPF do Playnite, remover a interface antiga e reconstruir a ORBIT UI em WPF com o motor UDP acoplado. |
| **Identidade do Produto** | **Péssima.** O usuário precisa instalar e abrir o Playnite. O LagCheck é mero acessório de terceiros. | **Excelente.** Aplicativo independente, 100% LagCheck ORBIT, com visual premium customizado e marca íntegra. | **Boa.** Aplicativo independente, mas preso ao legado visual e arquitetural do ecossistema WPF do Playnite. |
| **Preservação do LagCheck Core** | Baixa. Exigiria expor o LagCheck como serviço externo/CLI para ser consumido pelo plugin. | **Perfeita (100%).** Mantém os módulos `:core:session`, `:core:network`, `:core:catalog` e `:core:domain` intactos. | **Péssima.** Exigiria portar todo o motor de rede determinístico UDP e regras de score para C# ou criar pontes complexas via JNI/C-Interop. |
| **Interface ORBIT** | **Inviável.** Limitada às grades e temas permitidos pelo engine WPF padrão do Playnite. | **Perfeita.** Liberdade total no Compose Desktop com aceleração Skia, 120 FPS, sombras finas e animações fluidas. | Viável em WPF/XAML, porém com alto custo de estilização para fugir da estrutura base do Playnite. |
| **Complexidade de Build** | Baixa para o plugin, mas não entrega a plataforma solicitada. | **Baixa/Média.** Build 100% unificado no Gradle existente (`./gradlew :desktop:packageExe`). Zero runtimes extras. | **Extrema.** Manter compilação mista (Visual Studio / MSBuild + Gradle), dependências legadas e dezenas de pacotes NuGet. |
| **Custo de Manutenção / "Fork Drift"** | Inexistente para o Playnite, mas inútil para o objetivo do produto. | **Baixíssimo.** O código de leitura de manifestos (Steam VDF, Epic JSON, Xbox) é estável há anos e não sofre quebras. | **Crítico.** O Playnite possui centenas de milhares de linhas; manter um fork sincronizado é um pesadelo técnico contínuo. |
| **Segurança e Privacidade** | Dependente do código de dezenas de extensões do Playnite. | **Total controle.** Sem telemetria oculta, sem scripts invasivos, aderente às regras de privacidade do LagCheck. | Complexa auditoria de todo o código legado do Playnite. |

---

### 2.5 Estratégia Recomendada: Estratégia B (Reutilização Modular Arquitetural)

A **Estratégia B (Reutilização Modular / Transposição da Lógica de Integração)** é a solução tecnicamente superior, mais sustentável e que atende a 100% dos requisitos do produto pelos seguintes motivos:

1. **A mecânica dos launchers no Windows é simples e baseada em arquivos/protocolos:**
   - Para integrar com a Steam, basta ler arquivos de texto (`libraryfolders.vdf` e `appmanifest_*.acf`) e invocar `steam://run/<id>`.
   - Para integrar com a Epic Games, basta ler arquivos JSON (`Manifests/*.item`) e invocar `com.epicgames.launcher://apps/<id>?action=launch`.
   - Para jogos instalados avulsos, basta manipular atalhos e processos do Windows.
   - Não há necessidade de importar as 400.000 linhas de código C# do Playnite para realizar essas tarefas. A lógica de negócio dos plugins de integração do Playnite pode ser aproveitada, estruturada e executada diretamente em Kotlin JVM no ecossistema atual do LagCheck.
2. **Preservação Total do Motor de Rede do LagCheck:**
   - O motor UDP determinístico, os codecs de rede (STUN, Steam Query A2S, PlayFab QoS) e o orquestrador de repouso/carga continuam operando nativamente em Kotlin, sem nenhuma ponte arriscada ou reimplementação desnecessária.
3. **Pipeline de Distribuição Unificado:**
   - O projeto continua compilando com um único comando (`./gradlew :desktop:createDistributable` ou `packageExe`), gerando executáveis enxutos com runtime JVM embutido via jlink, sem forçar o usuário a instalar runtimes adicionais do .NET Framework ou do .NET Core.

---

## 3. Fase 3 — Arquitetura Alvo Integrada

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                            LAGCHECK ORBIT WINDOWS                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                              ORBIT UI                               │   │
│   │     (Compose Desktop / Skia GPU - Janela Desktop Redimensionável)   │   │
│   │                                                                     │   │
│   │  ┌──────────────┐ ┌───────────────┐ ┌──────────────┐ ┌───────────┐  │   │
│   │  │ Barra Topo   │ │ Lateral Ícones│ │ Destaque     │ │ Grade     │  │   │
│   │  │ Janela/Busca │ │ Início/Jogos  │ │ Cinematográ- │ │ Cartões   │  │   │
│   │  │ /Config      │ │ /Histórico    │ │ fico Jogo    │ │ Visual    │  │   │
│   │  └──────────────┘ └───────────────┘ └──────────────┘ └───────────┘  │   │
│   │                                                                     │   │
│   │  ┌───────────────────────────────────────────────────────────────┐  │   │
│   │  │ Painel de Diagnóstico Integrado (Latência/Jitter/Perda/Score) │  │   │
│   │  └───────────────────────────────────────────────────────────────┘  │   │
│   └──────────────────────────────────┬──────────────────────────────────┘   │
│                                      │                                      │
│                  ┌───────────────────┴───────────────────┐                  │
│                  ▼                                       ▼                  │
│   ┌───────────────────────────────┐       ┌─────────────────────────────┐   │
│   │       GAME LIBRARY CORE       │       │        LAGCHECK CORE        │   │
│   │   (Inspirado no Playnite)     │       │   (Existente e Preservado)  │   │
│   ├───────────────────────────────┤       ├─────────────────────────────┤   │
│   │ • Scanners de Launchers:      │       │ • CheckOrchestrator         │   │
│   │   - Steam (VDF/ACF parser)    │       │ • UdpProbeTransport (NIO)   │   │
│   │   - Epic Games (JSON items)   │       │ • Codecs (STUN, A2S, QoS)   │   │
│   │   - Xbox/UWP (Registry/WinRT) │       │ • HttpLoadTransport         │   │
│   │ • Execução de Jogos:          │       │ • GameReadinessEvaluator    │   │
│   │   - Launcher Protocol URIs    │       │ • Catálogo e Regiões        │   │
│   │   - Process Launcher / Monitor│       │ • Mapa de Rotas Geográfico  │   │
│   │ • Persistência Local:         │       │ • Telemetria GA4 Protegida  │   │
│   │   - SQLite / Local JSON DB    │       │ • Atualizador SHA-256       │   │
│   │ • Metadados e Capas Locais    │       │                             │   │
│   └───────────────────────────────┘       └─────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 3.1 Camadas da Arquitetura

1. **ORBIT UI:**
   - Janela moderna em Compose Desktop com tema escuro (fundo `#0B0D10`, superfícies `#15181E`, detalhes em verde-lima `#A3E635` / roxo `#7C3AED`).
   - Visão cinematográfica no topo com botão principal **Jogar** e secundário **Testar Conexão**.
   - Biblioteca de jogos em grade com filtros (Instalados, Plataforma, Favoritos) e busca rápida.
2. **Game Library Core:**
   - Camada responsável pela ingestão de jogos do ecossistema PC:
     - `SteamLibraryScanner`: Localiza pastas da Steam e analisa arquivos ACF.
     - `EpicLibraryScanner`: Lê manifestos `.item` na pasta ProgramData.
     - `GameLauncher`: Dispara jogos via protocolo de launcher (`steam://run/...`, `com.epicgames.launcher://...`) ou inicialização direta com monitoramento assíncrono de processo.
     - `GameLibraryRepository`: Armazenamento local da biblioteca, favoritos, tempo de jogo e metadados.
3. **LagCheck Core:**
   - Totalmente preservado. Fornece diagnósticos pontuais ou correlacionados aos jogos da biblioteca quando estes possuírem servidores de rede homologados no catálogo.

---

## 4. Riscos Técnicos e Estratégias de Mitigação

| Risco | Impacto | Mitigação |
| :--- | :--- | :--- |
| **Launchers instalados em diretórios não-padrão** | Médio | Consultar o Registro do Windows (`HKCU` e `HKLM`) e permitir inclusão/configuração manual de diretórios de bibliotecas nas Configurações. |
| **Jogos sem servidores de rede aplicáveis** | Alto | Seguir estritamente a regra do LagCheck: Jogos sem infraestrutura de rede conhecida (ex: Cities: Skylines II) **não exibem testes falsos de latência**. A UI mostra "Jogo Offline / Sem servidores dedicados" e disponibiliza apenas o botão "Testar Conexão Geral". |
| **Launcher bloqueado ou não iniciado** | Baixo | Tratar erros de protocolo e exibir notificação limpa caso o client da Steam ou Epic não responda à URI de inicialização. |
| **Performance ao renderizar centenas de jogos** | Médio | Utilizar `LazyVerticalGrid` virtualizada do Compose Desktop com carregamento assíncrono de imagens e cache em memória. |
| **Conflito de privilégios no Windows** | Baixo | Nunca exigir elevação administrativa (UAC). Toda leitura de manifestos ocorre em pastas de leitura livre do usuário (`AppData`, `ProgramData`, `SteamApps`). |

---

## 5. Mapeamento de Arquivos a Modificar / Criar

### Novos Arquivos a Criar
1. **Modelos e Contratos da Biblioteca (`android/desktop/src/main/kotlin/com/lagcheck/desktop/library/`):**
   - `model/PcGame.kt`: Modelo unificado de jogo de PC (ID, título, plataforma, caminho de instalação, URI de lançamento, executável, capa, tempo jogado, favorito).
   - `scanner/LibraryScanner.kt`: Interface para scanners de launchers.
   - `scanner/SteamScanner.kt`: Scanner da biblioteca Steam (leitura de VDF e manifestos ACF).
   - `scanner/EpicScanner.kt`: Scanner da biblioteca Epic Games (leitura de manifestos JSON `.item`).
   - `launcher/GameRunner.kt`: Mecanismo de execução de jogos e monitoramento de processos.
   - `repository/LibraryRepository.kt`: Repositório local de persistência da biblioteca e preferências.
2. **Telas e Componentes da Interface ORBIT (`android/desktop/src/main/kotlin/com/lagcheck/desktop/ui/orbit/`):**
   - `OrbitShell.kt`: Casca principal da interface ORBIT.
   - `OrbitHero.kt`: Destaque cinematográfico do jogo selecionado com botão "Jogar" e "Testar Conexão".
   - `OrbitGameCard.kt`: Cartão visual de jogo com miniatura, badges de plataforma e status de instalação.
   - `OrbitDiagnosticPanel.kt`: Painel integrado de diagnóstico LagCheck.
3. **Documentação Exigida:**
   - `docs/orbit-integration-plan.md` (este documento).
   - `docs/playnite-licenses.md`: Atribuições, licença MIT do Playnite e direitos autorais.
   - `docs/orbit-architecture.md`: Especificação detalhada da arquitetura técnica.
   - `docs/orbit-design-system.md`: Especificação visual da interface ORBIT.
   - `docs/orbit-testing.md`: Guia e matriz de testes da integração.

### Arquivos Existentes a Ajustar
- `android/desktop/src/main/kotlin/com/lagcheck/desktop/AppState.kt`: Adição do estado da biblioteca de jogos (`LibraryState`) e controle de jogo ativo no Hero.
- `android/desktop/src/main/kotlin/com/lagcheck/desktop/ds/Tokens.kt`: Introdução dos tokens de destaque verde-lima da interface ORBIT (`#A3E635` / `#84CC16`).
- `android/desktop/src/main/kotlin/com/lagcheck/desktop/Main.kt`: Inicialização do repositório da biblioteca e injeção na casca principal.
- `README.md`: Atualização das instruções de compilação da plataforma desktop ORBIT.

---

## 6. Estimativa de Complexidade e Primeiro Incremento Funcional

- **Complexidade Geral:** Moderada (graças à modularidade do Kotlin e à independência dos manifestos dos launchers).
- **Esforço Estimado:**
  - *Fase 3 & 4 (Arquitetura e Interface ORBIT):* Baixo/Médio (Compose Desktop já possui toda a base e tokens prontos).
  - *Fase 5 & 6 (Game Library Core e Scanners):* Médio (parsing dos formatos VDF e JSON; execução de protocolos).
  - *Fase 7 (Validação e QA):* Médio (testes em ambiente Mac simulado e validação final em Windows real).

### Primeiro Incremento Funcional Proposto (Passo Imediato após Aprovação)
1. Criar o módulo `com.lagcheck.desktop.library` com os modelos base de jogos e a implementação do scanner da Steam (`SteamScanner`), capaz de ler bibliotecas e arquivos `.acf` locais ou mockados para testes.
2. Criar a tela principal ORBIT (`OrbitShell`), integrando o destaque cinematográfico dos três jogos de referência (*Cities: Skylines II*, *Fall Guys*, *Call of Duty*), alternando entre exibição de diagnóstico para jogos com suporte a rede e indicação clara para jogos offline/locais.
3. Garantir compilação contínua e 100% dos testes unitários verdes via `./gradlew :desktop:test`.
