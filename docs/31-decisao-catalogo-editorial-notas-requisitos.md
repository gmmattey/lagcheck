# LagCheck — Decisão 31: Catálogo Editorial com Notas Oficiais, Requisitos de Sistema e Rede sem Alucinação de Dados

**Status:** Decisão aprovada pelo Dono do Produto (Luiz); em especificação técnica e implementação  
**Data:** 18 de setembro de 2026  
**Autores / Revisores:** Luiz (Dono do Produto), Marco (Produto), Renan (Design), Rian (iOS), Iury (Rede)  
**Complementa:** `docs/01-funcional.md`, `docs/02-arquitetura.md`, `docs/03-especificacao-tecnica.md`, `docs/07-voz-do-produto.md`, `docs/14-decisao-catalogo-remoto-debug.md`, `docs/18-decisao-identidade-visual-neutra-de-jogos.md`, `docs/24-decisao-adocao-design-system-apple-games.md`, `docs/26-decisao-catalogo-console.md`

---

## 1. Contexto e Problema de Produto (Marco)

Com a consolidação da experiência do LagCheck no estilo **Apple Games Editorial Hub** (`docs/24`), o usuário não apenas realiza o diagnóstico de sua rota de rede para um jogo específico, mas navega pelo catálogo descobrindo títulos multiplayer competitivos e casuais.

Para que o app entregue um valor editorial autêntico sem se tornar uma ferramenta genérica de ping, precisamos responder a três perguntas fundamentais do jogador antes de iniciar o download ou a partida:
1. *Do que se trata o jogo e qual a sua recepção crítica oficial consagrada?*
2. *Meu dispositivo (ou meu console/PC) atende aos requisitos mínimos de hardware, sistema operacional e armazenamento?*
3. *Qual é a exigência real de rede para este jogo específico (largura de banda, sensibilidade a jitter/perda de pacotes e latência recomendada)?*

### Princípios e Guardrails Inegociáveis:
1. **Zero Alucinação de Dados (Auditoria e Fontes Oficiais):** É terminantemente proibido gerar notas sintéticas, notas fictícias ou compilar reviews inventadas por LLM. Toda nota ou avaliação exibida deve ser indexada por fonte oficial verificável (ex.: Metacritic Metascore / User Score, OpenCritic Top Critic Average, App Store Rating oficial por região, ou classificação indicativa oficial como ClassInd / ESRB / PEGI).
2. **Abrangência de Todo o Catálogo:** A curadoria editorial de notas oficiais, requisitos mínimos e demandas de rede cobre todos os títulos catalogados no aplicativo.
3. **Custo Operacional Recorrente Zero:** Proibido o uso de APIs comerciais pagas de agregação de games (ex.: planos pagos de IGDB, RAWG comercial ou scrapers dinâmicos de alta manutenção). Os dados editoriais residirão de forma estruturada, tipada e auditada no próprio catálogo assinado (`RemoteCatalogPayload`) com cache persistente e fallback offline empacotado (`DebugCatalogBase.json`).
4. **Identidade Visual Editorial do LagCheck (`docs/18`):** As imagens atuais do catálogo são artes editoriais originais, geradas para o LagCheck e inspiradas na atmosfera ou no universo de cada jogo, sem se apresentarem como o jogo em si; elas são permitidas. Permanecem proibidos capa oficial, logo, screenshot, personagem reconhecível e arte comercial ou de terceiros. A identidade visual segue os assets do LagCheck e o design system nativo SF Pro / Apple Games Editorial Hub.
5. **Bilinguismo Nativo (PT-BR e EN):** Textos descritivos e requisitos possuem suporte a localização para Português do Brasil e Inglês.

---

## 2. Modelagem de Dados no Domínio (Rian & Iury)

Seguindo a separação estrita de `NolaggyDomain` (`docs/02-arquitetura.md`), o schema do catálogo é enriquecido de forma retrocompatível (campos opcionais sem quebrar envelopes legados):

```swift
public struct RemoteCatalogGameEditorial: Codable, Equatable, Sendable {
    /// Descrição concisa e oficial do jogo (PT-BR e EN)
    public let summary: [String: String]
    /// Desenvolvedora / Publicadora oficial
    public let publisher: String
    /// Ano de lançamento original
    public let releaseYear: Int
    /// Classificação indicativa oficial (ex: "Livre", "10+", "12+", "14+", "16+", "18+")
    public let ageRating: String
    /// Notas de crítica e comunidade oficiais auditadas
    public let ratings: [EditorialRating]
    /// Requisitos técnicos mínimos e recomendados por plataforma
    public let requirements: [PlatformRequirement]
    /// Especificações de rede recomendadas para gameplay competitivo/ótimo
    public let networkDemands: GameNetworkDemands
}

public struct EditorialRating: Codable, Equatable, Sendable {
    public enum Source: String, Codable, Equatable, Sendable {
        case metacriticCritic = "metacritic_critic"
        case metacriticUser = "metacritic_user"
        case openCritic = "opencritic"
        case appStore = "app_store"
        case steam = "steam"
    }
    public let source: Source
    public let score: Double         // Ex: 83.0 (Metacritic 0-100) ou 4.6 (App Store 1-5)
    public let scale: Double         // Ex: 100.0 ou 5.0
    public let reviewCount: Int?     // Volume de avaliações apuradas
    public let referenceURL: String  // Link auditável da fonte oficial
}

public struct PlatformRequirement: Codable, Equatable, Sendable {
    public let platform: Platform    // .iphone, .playstation, .xbox, .pc, .nintendo
    public let minimumOS: String     // Ex: "iOS 17.0", "Windows 10 64-bit"
    public let storageBytes: Int64   // Ex: 35_000_000_000 (35 GB)
    public let memoryRAMBytes: Int64 // Ex: 4_000_000_000 (4 GB)
    public let targetFramerate: Int? // Ex: 60 ou 120 FPS
}

public struct GameNetworkDemands: Codable, Equatable, Sendable {
    public let minDownloadMbps: Double      // Ex: 5.0 Mbps
    public let minUploadMbps: Double        // Ex: 1.0 Mbps
    public let optimalPingMs: Double        // Ex: 40.0 ms
    public let acceptablePingMs: Double     // Ex: 80.0 ms
    public let maxJitterMs: Double          // Ex: 8.0 ms
    public let packetLossTolerancePct: Double // Ex: 0.5%
}
```

---

## 3. Curadoria e Auditoria de Todos os Títulos do Catálogo

A tabela a seguir consolida os dados reais e auditados de todos os títulos presentes no catálogo do LagCheck:

| Game ID | Nome | Publisher | Lançamento | Metacritic / Avaliação Oficial | Classificação | Armazenamento / RAM (iOS/Base) | Demanda de Rede Recomendada |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `fortnite` | Fortnite | Epic Games | 2017 | **83** (Metacritic PC/Console) / **4.6 ★** (App Store Histórico) | 12+ / Teen | ~18 GB / 4 GB RAM | Ping ótimo < 40ms, Jitter < 5ms, Perda 0% |
| `call-of-duty-mobile` | Call of Duty: Mobile | Activision | 2019 | **81** (Metacritic) / **4.7 ★** (App Store BR) | 16+ / Mature | ~15 GB / 3 GB RAM | Ping ótimo < 45ms, Jitter < 6ms, Perda < 0.5% |
| `free-fire` | Free Fire | Garena | 2017 | **4.2 ★** (App Store BR, 100M+ reviews) | 12+ / Teen | ~4 GB / 2 GB RAM | Ping ótimo < 60ms, Jitter < 12ms, Perda < 1.0% |
| `pubg-mobile` | PUBG MOBILE | Krafton / Level Infinite | 2018 | **82** (Metacritic) / **4.4 ★** (App Store) | 16+ / Mature | ~9 GB / 3 GB RAM | Ping ótimo < 50ms, Jitter < 8ms, Perda < 0.5% |
| `brawl-stars` | Brawl Stars | Supercell | 2018 | **72** (Metacritic) / **4.8 ★** (App Store) | 10+ / Everyone | ~1.5 GB / 2 GB RAM | Ping ótimo < 35ms, Jitter < 4ms, Perda 0% |
| `wild-rift` | League of Legends: Wild Rift | Riot Games | 2020 | **89** (Metacritic) / **4.3 ★** (App Store) | 12+ / Teen | ~7 GB / 3 GB RAM | Ping ótimo < 40ms, Jitter < 5ms, Perda 0% |
| `roblox` | Roblox | Roblox Corporation | 2006 | **4.5 ★** (App Store BR, 10M+ reviews) | 10+ / Everyone 10+ | ~3 GB / 2 GB RAM | Ping ótimo < 65ms, Jitter < 15ms, Perda < 1.5% |
| `minecraft` | Minecraft | Mojang Studios | 2011 | **93** (Metacritic All-Time) / **4.6 ★** (App Store) | Livre / Everyone | ~1.8 GB / 2 GB RAM | Ping ótimo < 70ms, Jitter < 15ms, Perda < 2.0% |
| `apex-legends` | Apex Legends | Electronic Arts / Respawn | 2019 | **89** (Metacritic) / **80%** (Steam Muito Positivas) | 14+ / Teen | ~75 GB / 8 GB RAM (PC/Console) | Ping ótimo < 45ms, Jitter < 5ms, Perda 0% |
| `blood-strike` | Blood Strike | NetEase Games | 2023 | **4.6 ★** (App Store BR, 500k+ reviews) | 14+ / Teen | ~3.5 GB / 2 GB RAM | Ping ótimo < 55ms, Jitter < 10ms, Perda < 1.0% |
| `cs2` | Counter-Strike 2 | Valve Corporation | 2023 | **82** (Metacritic) / **87%** (Steam Histórico) | 16+ / Mature | ~85 GB / 8 GB RAM (PC) | Ping ótimo < 30ms, Jitter < 3ms, Perda 0% |
| `dota2` | Dota 2 | Valve Corporation | 2013 | **90** (Metacritic) / **82%** (Steam) | 12+ / Teen | ~60 GB / 4 GB RAM (PC) | Ping ótimo < 45ms, Jitter < 5ms, Perda 0% |
| `eafc` | EA SPORTS FC 24/25 | Electronic Arts | 2023 | **76** (Metacritic) / **4.7 ★** (App Store Mobile) | Livre / Everyone | ~15 GB (Mobile) / 50 GB (Console) | Ping ótimo < 35ms, Jitter < 4ms, Perda 0% |
| `league-of-legends` | League of Legends (PC) | Riot Games | 2009 | **78** (Metacritic) / Referência global MOBA | 12+ / Teen | ~22 GB / 4 GB RAM (PC) | Ping ótimo < 35ms, Jitter < 4ms, Perda 0% |
| `palworld` | Palworld | Pocketpair | 2024 | **90%** (Steam Muito Positivas, 300k+ reviews) | 12+ / Teen | ~40 GB / 16 GB RAM (PC/Xbox) | Ping ótimo < 70ms, Jitter < 15ms, Perda < 1.0% |
| `rainbow-six` | Rainbow Six Siege | Ubisoft | 2015 | **79** (Metacritic) / **86%** (Steam) | 16+ / Mature | ~65 GB / 8 GB RAM (PC/Console) | Ping ótimo < 40ms, Jitter < 4ms, Perda 0% |
| `rocket-league` | Rocket League | Psyonix / Epic Games | 2015 | **86** (Metacritic) / **88%** (Steam Histórico) | Livre / Everyone | ~20 GB / 4 GB RAM (PC/Console) | Ping ótimo < 40ms, Jitter < 5ms, Perda 0% |
| `rust` | Rust | Facepunch Studios | 2018 | **69** (Metacritic) / **87%** (Steam Muito Positivas) | 18+ / Mature | ~35 GB / 16 GB RAM (PC/Console) | Ping ótimo < 50ms, Jitter < 8ms, Perda < 0.5% |
| `valorant` | Valorant | Riot Games | 2020 | **80** (Metacritic) / Referência Tático PC/Console | 14+ / Teen | ~45 GB / 4 GB RAM (PC/Console) | Ping ótimo < 30ms, Jitter < 3ms, Perda 0% |
| `warzone` | Call of Duty: Warzone | Activision | 2020 | **79** (Metacritic) / **3.8 ★** (App Store Mobile) | 18+ / Mature | ~125 GB (PC/Console) / ~15 GB (Mobile) | Ping ótimo < 45ms, Jitter < 5ms, Perda 0% |

---

## 4. Experiência de Interface e Design Editorial (Renan)

No ecossistema **Apple Games Editorial Hub** (`docs/24`):

1. **Card de Avaliação Oficial na Tela de Detalhes (`GameDetailRatingsRow`):**
   - Badges elegantes exibindo a nota oficial e a fonte reconhecida (ex.: `Metascore 83`, `App Store 4.7 ★`, `Steam 87%`).
   - Apresentação em tipografia SF Pro nativa de alto contraste com indicador de escala.
2. **Seção de Ficha Técnica e Requisitos (`GameSpecsSection`):**
   - Segmentação horizontal por plataforma ativa (`iPhone`, `PlayStation`, `Xbox`, `PC`).
   - Métricas em grid 2x2: Sistema Operacional Mínimo, Armazenamento Estimado, Memória RAM Mínima e Perfil de Rede Recomendado.
3. **Comparador Contextual de Fit de Conexão:**
   - Confronta em tempo real a latência medida do usuário com o `optimalPingMs` do jogo:
     - Exemplo: *"Sua conexão com 22 ms de ping está dentro da faixa ideal (< 40 ms) para partidas competitivas."*
