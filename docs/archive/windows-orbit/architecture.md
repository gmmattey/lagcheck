> **Histórico (Decisão 118).** Registro da primeira versão da biblioteca do Windows, quando ela ainda tinha um nome interno que foi abandonado. O que vale hoje está em `docs/09-design-system-windows.md` e na Decisão 118 de `docs/DECISOES.md`. Este arquivo não é mais atualizado.

# LagCheck ORBIT — Arquitetura Técnica

> **Documento de Arquitetura da Plataforma Desktop**  
> **Status:** Implementado na branch `feature/orbit-playnite-integration`.  
> **Alvo:** Windows 10/11 x64 (JVM 17+ / Compose Desktop).

---

## 1. Visão Geral

O **LagCheck ORBIT** evolui o protótipo de desktop para uma plataforma gamer que unifica a biblioteca de jogos de PC, a interface cinematográfica ORBIT (inspirada nos ecossistemas da NVIDIA, Xbox e PlayStation) e o motor de diagnósticos determinísticos de rota do LagCheck.

A arquitetura adota separação estrita de responsabilidades entre três camadas principais:

```text
┌────────────────────────────────────────────────────────────────────────┐
│                               ORBIT UI                                 │
│      (Compose Desktop / Skia GPU — Janela Desktop Redimensionável)     │
│                                                                        │
│   • OrbitShell (Janela, Barra Superior, Lateral Compacta)              │
│   • OrbitHero (Destaque Cinematográfico, Badges, Botão JOGAR e TESTAR) │
│   • OrbitLibraryView (Filtros, Busca, Grade de Cartões Virtuais)       │
│   • OrbitGameCard (Miniatura, Plataforma, Estado, Favorito)            │
│   • RouteMap (Canvas Matricial Geográfico com Sondas Reais)            │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
           ┌────────────────────────┴────────────────────────┐
           ▼                                                 ▼
┌─────────────────────────────────────┐   ┌──────────────────────────────┐
│          GAME LIBRARY CORE          │   │        LAGCHECK CORE         │
│     (com.lagcheck.desktop.library)  │   │  (:core:session, :core:net)  │
├─────────────────────────────────────┤   ├──────────────────────────────┤
│ • Modelos Unificados (PcGame)       │   │ • CheckOrchestrator          │
│ • Scanners de Launchers:            │   │ • UdpProbeTransport (NIO)    │
│   - SteamScanner (VDF/ACF Parser)   │   │ • Codecs (STUN, A2S, QoS)    │
│   - EpicScanner (JSON Manifests)    │   │ • HttpLoadTransport          │
│ • GameRunner (Launcher Protocol URIs│   │ • GameReadinessEvaluator     │
│   e Execução de Processos)          │   │ • Catálogo Assinado de Rotas │
│ • LibraryRepository (Persistência,  │   │ • Localização por IP         │
│   Favoritos, Busca e Filtros)       │   │ • Telemetria GA4 Protegida   │
└─────────────────────────────────────┘   └──────────────────────────────┘
```

---

## 2. Camadas do Sistema

### 2.1 LagCheck Core (Existente e Preservado)
Mantém 100% de paridade e fidelidade aos contratos dos módulos do repositório:
- **`:core:network`:**
  - `UdpProbeTransport`: Sondas UDP em canal não-bloqueante (`DatagramChannel`) com carimbo de tempo em nanossegundos.
  - Codecs de pacote suportados:
    - **STUN (RFC 5389/8489):** Sondas em gateways e servidores neutros.
    - **Steam Query A2S (`A2S_INFO` / `A2S_PING`):** Sondas diretas em servidores Valve/Source.
    - **PlayFab QoS (`PingBeacon`):** Sondas em instâncias do Microsoft Azure PlayFab.
  - `HttpLoadTransport`: Geração de carga downstream simultânea via worker Cloudflare para teste de saturação (bufferbloat).
- **`:core:session`:**
  - `CheckOrchestrator`: Coordena as duas fases do diagnóstico (30 sondas em Repouso + 30 sondas sob Carga).
  - Cálculo de métricas: RTT mediano, Jitter diferencial (RFC 3550) e Perda de Pacotes exata.
- **`:core:domain`:**
  - `GameReadinessEvaluator`: Avaliação determinística baseada na matriz de qualidade.
  - Vereditos: `● PRONTO PARA RANKED`, `▲ EU EVITARIA RANKED AGORA`, `▲ CONDIÇÕES INSTÁVEIS` ou `— INCONCLUSIVO`.
  - **Integridade:** Sem respostas suficientes, o resultado é estritamente inconclusivo. Nunca há fallback HTTP, ICMP ou nota inventada.

---

### 2.2 Game Library Core (`com.lagcheck.desktop.library`)
Responsável pela descoberta, catálogo e inicialização de jogos de PC:

1. **Modelo Unificado de Jogo (`PcGame`):**
   - Identificador único (`id`), título (`title`), plataforma (`GamePlatform`), diretório de instalação (`installDirectory`), URI de lançamento (`launchUri`), executável (`executablePath`), status de instalação (`isInstalled`), favoritos (`isFavorite`), tempo jogado (`playTimeMinutes`) e suporte de rede (`GameNetworkSupport`).
2. **Suporte de Rede Tipado (`GameNetworkSupport`):**
   - `LagcheckSupported(catalogId, regionLabel)`: Jogos multijogador com servidores homologados no catálogo (ex: *Call of Duty: Warzone*, *Counter-Strike 2*, *Apex Legends*). Habilita diagnóstico completo.
   - `GeneralConnectionOnly(note)`: Jogos online casuais ou com servidores dinâmicos/P2P (ex: *Fall Guys*). Executa o diagnóstico da rota geral do PC.
   - `OfflineSingleplayer(note)`: Jogos estritamente solo/locais (ex: *Cities: Skylines II*). **Não exibe testes fictícios de latência**, informando com transparência que se trata de uma experiência offline.
3. **Scanners de Launchers:**
   - **`SteamScanner`:** Localiza a instalação da Steam no Registro do Windows (`HKCU\Software\Valve\Steam`), analisa `libraryfolders.vdf` para encontrar todas as unidades de armazenamento secundárias e realiza o parsing dos manifestos `appmanifest_<appId>.acf`. Mapeia o lançamento para `steam://rungameid/<appId>`.
   - **`EpicScanner`:** Lê manifestos JSON individuais em `%ProgramData%\Epic\EpicGamesLauncher\Data\Manifests\*.item` e extrai `DisplayName`, `AppName`, `InstallLocation` e `LaunchExecutable`. Mapeia o lançamento para `com.epicgames.launcher://apps/<AppName>?action=launch`.
4. **Executor de Jogos (`GameRunner`):**
   - Dispara jogos através de protocolos de launcher ou executáveis diretos com segurança, capturando códigos de retorno e exceções sem bloquear a interface.
5. **Repositório e Persistência (`LibraryRepository`):**
   - Agrega jogos de referência (*Cities: Skylines II*, *Fall Guys*, *Call of Duty*) e jogos detectados no disco.
   - Persiste preferências do usuário (favoritos) em arquivo local de configuração (`~/.lagcheck/orbit_prefs.properties`).
   - Fornece filtragem reativa por plataforma (Todos, Instalados, Favoritos, Steam, Epic) e busca textual em tempo real.

---

### 2.3 ORBIT UI (Interface do Usuário)
Construída com Jetpack Compose for Desktop, utilizando aceleração de hardware Skia:
- **Janela Desktop:** Janela padrão de 1120×740 dp, redimensionável (tamanho mínimo de 900×600 dp), com suporte a maximizar, minimizar e restaurar.
- **Topologia de Telas:**
  - **Barra Superior (`WorkspaceTopbar`):** Identificação oficial Lagcheck ORBIT, contexto da página e status.
  - **Barra Lateral (`Sidebar`):** Navegação compacta por ícones e títulos com indicador de seleção animado.
  - **Destaque Cinematográfico (`OrbitHero`):** Jogo ativo em primeiro plano com arte editorial, badges de plataforma/rede, botão primário **JOGAR** (em verde-lima esportivo) e botão secundário **TESTAR CONEXÃO**.
  - **Grade de Biblioteca (`OrbitLibraryView` e `OrbitGameCard`):** Grade responsiva com colunas dinâmicas (2 a 4 colunas conforme a largura da janela) e cartões visuais com feedback tátil de hover.
  - **Cockpit Geral Preservado:** Abaixo da biblioteca, o anel circular "TESTAR" permanece disponível para medição instantânea da conexão geral sem depender de um jogo específico.

---

## 3. Gestão de Estado e Concorrência

- O estado do aplicativo é centralizado na classe `AppState`, que expõe:
  - `library`: Instância única do `LibraryRepository`.
  - `route`: Rota atual (`Route.Home`, `Route.Games`, `Route.History`, `Route.Settings`, `Route.Check`, `Route.Result`, `Route.Components`).
  - `history`: Histórico de diagnósticos realizados na sessão.
  - `routeMap`: Estado do mapa de rotas animado.
- Todas as operações de I/O de disco (leitura de manifestos ACF e JSON) e rede (sondas UDP, download de atualização e localização IP) rodam em dispatchers de background (`Dispatchers.IO`), mantendo a thread de renderização da UI livre de bloqueios a 60–120 FPS.
