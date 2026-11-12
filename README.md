<p align="center">
  <img src="shared/design-system/assets/brand/wordmark-primary.svg" alt="lagcheck" height="56">
</p>

<p align="center">
  <b>Sua conexão está boa para jogar agora?</b><br>
  O LagCheck mede a rota do seu celular até a infraestrutura do jogo e responde em uma frase.
</p>

<p align="center">
  <a href="https://apps.apple.com/app/id6818706960">App Store</a> ·
  <a href="https://groups.google.com/g/lagcheck">Testar no Android</a> ·
  <a href="https://lagcheck.signallq.com">Site</a> ·
  <a href="#english">English</a>
</p>

<p align="center">
  <img src="shared/distribution/store/google-play/pt-BR/pre-registration/final/03-veredito-direto.png" alt="Veredito do LagCheck" width="190">
  <img src="shared/distribution/store/google-play/pt-BR/pre-registration/final/01-leitura-em-repouso.png" alt="Leitura em repouso" width="190">
  <img src="shared/distribution/store/google-play/pt-BR/pre-registration/final/02-leitura-sob-carga.png" alt="Leitura sob carga" width="190">
  <img src="shared/distribution/store/google-play/pt-BR/pre-registration/final/04-detalhes-da-rota.png" alt="Detalhes da rota" width="190">
</p>

> ⚠️ **Código visível, uso restrito.** Este repositório é público para transparência, mas **não tem licença de uso**. Todos os direitos reservados. Não copie, redistribua nem use o código, a marca ou os ativos sem avisar e receber autorização. Veja o [aviso de uso](docs/NOTICE.md).

## O que é

Um app para jogador competitivo que quer saber, antes da partida, se a rede aguenta. Você escolhe o jogo, o LagCheck mede e entrega um veredito direto:

| Veredito | Significa |
| --- | --- |
| `● PRONTO PARA RANKED` | A conexão está estável para jogar. |
| `▲ CONDIÇÕES INSTÁVEIS` | Dá para jogar, mas pode oscilar. |
| `▲ EU EVITARIA RANKED AGORA` | A medição mostra problema. |
| `— INCONCLUSIVO` | Não deu para medir com confiança, então não inventamos nota. |

## Como funciona

- **Medição real, sem nota inventada.** Latência, jitter e perda de pacotes por UDP, em repouso e sob carga. Sem respostas válidas suficientes, o resultado é inconclusivo.
- **Score determinístico e versionado.** A mesma medição sempre dá o mesmo resultado, com vetores de teste.
- **Honesto sobre o limite.** Mede a rota do aparelho até uma infraestrutura de referência. Não promete o ping exato de um jogo, e para console ou PC o resultado é uma estimativa.
- **Custo zero e privacidade.** Catálogo de jogos local no app, sem assinatura. Telemetria anônima e mínima, sem dados pessoais nem IP.
- **Sem acusação sem prova.** O app só aponta roteador ou operadora quando há evidência.

## Plataformas

| Plataforma | Tecnologia | Pasta | Estado |
| --- | --- | --- | --- |
| iPhone (iOS 17+) | Swift, SwiftUI | [`apps/ios/`](apps/ios) | Na App Store |
| Android (API 26+) | Kotlin, Jetpack Compose | [`apps/android/app/`](apps/android/app) | Em teste (alpha e beta) |
| Windows (WinUI 3) | C#, WinUI 3 | [`apps/windows/`](apps/windows) | Protótipo |
| Windows (Desktop) | Kotlin, Compose Desktop | [`apps/android/desktop/`](apps/android/desktop) | Prévia, [`windows-v0.1.0`](https://github.com/gmmattey/lagcheck/releases/tag/windows-v0.1.0) |
| Backend | Cloudflare Worker | [`apps/worker/`](apps/worker) | Em produção |

**Quer testar o Android?** Entre no [grupo de testadores](https://groups.google.com/g/lagcheck) para receber acesso ao teste alpha e beta.

O app Windows ainda não é um alvo oficial. É uma prévia.

## Rodando localmente

**iOS** (Xcode 16+)
```sh
cd apps/ios
open Nolaggy.xcodeproj
```
Escolha o target `Nolaggy` e rode no simulador. Testes: `Cmd + U`.

**Android** (JDK 21)
```sh
cd apps/android
./gradlew assembleDebug
./gradlew test
```

**Windows (LagCheck — Desktop Compose)**
```sh
cd apps/android
# 1. Executar a interface desktop interativa
./gradlew :desktop:run

# 2. Executar suíte de testes automatizados
./gradlew :desktop:test

# 3. Rodar diagnóstico UDP via terminal (sem janela)
./gradlew :desktop:runCli

# 4. Gerar capturas visuais automatizadas
./gradlew :desktop:shots

# 5. Gerar instalador Windows (.exe / .msi)
./gradlew :desktop:packageExe
```

**Worker**
```sh
cd apps/worker
npm install
npm test
```

> O nome `Nolaggy` em pastas e no projeto Xcode vem da marca anterior. A marca oficial é **LagCheck**.

## Estrutura (Decisão 120)

```text
apps/
  ios/          app iOS (SwiftUI) e motor de medição
  android/      app Android e prévia desktop (Compose Desktop)
  windows/      app Windows (WinUI 3)
  worker/       Cloudflare Worker (carga do Deep Check e telemetria)
shared/
  design-system/ tokens, ativos de marca e protótipos
  distribution/  textos de loja, campanhas e chaves/bundles de release
  scripts/       automações de build e validação
docs/           especificação, arquitetura e decisões
```

## Documentação

- [Funcional](docs/01-funcional.md): problema, jornada e regras de negócio
- [Arquitetura](docs/02-arquitetura.md) e [especificação técnica](docs/03-especificacao-tecnica.md)
- [Design system](docs/04-design-system.md): Dark Competitive UI
- [Voz do produto](docs/07-voz-do-produto.md)
- [Decisões](docs/DECISOES.md): registro único de todas as decisões do produto

## Contribuir e reportar problemas

Bugs e ideias entram como [issue](https://github.com/gmmattey/lagcheck/issues/new/choose). Antes de enviar código, leia o [CONTRIBUTING](.github/CONTRIBUTING.md). Falhas de segurança seguem o [SECURITY](.github/SECURITY.md).

## Sobre o fluxo de trabalho

O projeto é tocado por uma equipe pequena de agentes de IA com direção humana (Luiz). Os papéis e o ciclo estão em [`AGENTS.md`](AGENTS.md).

---

## English

**LagCheck** tells competitive mobile gamers whether their connection is good enough to play right now. It measures the route from the phone to a reference infrastructure using real UDP probes (latency, jitter, packet loss, at rest and under load) and returns a plain verdict. If there is not enough valid data, the result is *inconclusive*, never an invented score.

- iOS (SwiftUI) · Android (Kotlin/Compose) · Windows preview (Compose Desktop) · Cloudflare Worker backend
- Deterministic, versioned score. Console and PC results are labeled as estimates.
- Anonymous, minimal telemetry. No personal data, no IP.

**Source-available, all rights reserved.** There is no open-source license. Do not copy, redistribute or use the code, brand or assets without permission. See [NOTICE.md](NOTICE.md).
