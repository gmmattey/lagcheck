# LagCheck 🎮⚡

**LagCheck** é uma ferramenta multiplataforma de diagnóstico preditivo e medição determinística de rotas de rede para gamers competitivos. O app responde à pergunta essencial:
> *"Minha conexão está boa para jogar agora?"*

Desenvolvido para **iOS** (SwiftUI) e **Android** (Kotlin/Jetpack Compose), com suporte de infraestrutura em edge na **Cloudflare Workers** (`worker/nolaggy-deep-check`).

O site institucional e biblioteca de jogos pública estão centralizados em `~/Projetos/web/landings` (`sites/lagcheck/`).

---

## 🎯 Pilares do Produto

1. **Veredito Semântico Direto:** Manchete clara e proporcional (`● PRONTO PARA RANKED`, `▲ EU EVITARIA RANKED AGORA`, `▲ CONDIÇÕES INSTÁVEIS`).
2. **Catálogo de 20+ Jogos Competitivos:** Diagnóstico calibrado por título (Valorant, CS2, League of Legends, Fortnite, Apex Legends, Warzone, etc.).
3. **Medição Determinística:** Probe ativo de latência em repouso e sob carga, jitter e perda de pacotes via UDP/STUN e HTTP.
4. **Dark Competitive UI:** Design System escuro de alta fidelidade visual (fundos `#0B0D10`, superfícies `#15181E`, Roxo Gamer `#7C3AED` e Coral Solar `#FF5A36`).

---

## 🏗️ Arquitetura do Repositório

```
rede/lagcheck/
├── Sources/                 # Código nativo iOS (SwiftUI, Core Engine UDP/STUN)
├── Tests/                   # Suíte de testes automatizados iOS
├── Nolaggy.xcodeproj        # Projeto Xcode iOS / iPadOS
├── android/                 # Projeto nativo Android (Kotlin, Jetpack Compose)
│   ├── app/                 # Módulo do app Android
│   └── build.gradle.kts     # Configuração de build e assinatura do Android
├── worker/                  # Cloudflare Worker (nolaggy-deep-check)
├── release/                 # Chaves de assinatura locais e saídas de build (ignorado no git)
│   └── keys/                # Keystore e propriedades de assinatura Play Console
├── scripts/                 # Scripts operacionais (android-release.sh, etc.)
├── docs/                    # Decisões de arquitetura (ADRs) e voz do produto
├── design-system/           # Tokens visuais e ativos oficiais da marca
└── AGENTS.md                # Diretrizes operacionais e governança da Squad Lean
```

---

## 🚀 Como Executar e Validar

### 🍏 iOS (SwiftUI)
1. Abra o projeto no Xcode:
   ```sh
   open Nolaggy.xcodeproj
   ```
2. Selecione o target `Nolaggy` e execute no simulador ou em aparelho físico (iPhone).
3. Testes unitários de motor e catálogo:
   Execute `Cmd + U` no Xcode.

### 🤖 Android (Jetpack Compose)
1. Compilação de depuração:
   ```sh
   cd android
   ./gradlew assembleDebug
   ```
2. Gerar pacote de release assinado para o Google Play Console:
   ```sh
   ./scripts/android-release.sh 1.0.3 9
   ```
   *O artefato `.aab` e o arquivo de desofuscação `mapping.txt` serão gerados em `release/android/`.*

### ☁️ Cloudflare Worker (`nolaggy-deep-check`)
```sh
cd worker/nolaggy-deep-check
npm install
npm run test
```

---

## 👥 Governança da Squad

O desenvolvimento segue a **Squad Lean de 4 Agentes** (detalhada em [`AGENTS.md`](AGENTS.md)):
- **Marcelo** (`marcelo`): Líder de Produto & Orquestrador
- **Priscila** (`priscila`): Diretora de Experiência, UX/UI & Design System
- **Camillo** (`camillo`): Engenheiro Principal Full-Stack & Arquitetura
- **Renan** (`renan`): Qualidade, QA, Testes Automatizados & Prova de Fogo

Operando sob o **Ciclo Ágil de 3 Passos** com WIP = 1 e auto-teste obrigatório.
