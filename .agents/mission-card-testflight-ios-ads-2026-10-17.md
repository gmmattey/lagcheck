# Cartão de Missão — candidato TestFlight iOS com AdMob/UMP

## Enquadramento

- **Problema da pessoa:** o LagCheck precisa testar em iPhone real a monetização por banners sem sacrificar a decisão principal: saber se vale jogar agora.
- **Resultado esperado observável:** um candidato `1.0.2 (4)` chega ao App Store Connect para processamento no TestFlight com UMP antes de qualquer request, banners adaptativos e identificados só em Início, Histórico, Jogos e Resultado concluído válido; Check, inconclusivo, detalhes e ações essenciais ficam livres de anúncio.
- **Fora de escopo:** App Review, publicação na App Store, ATT, formatos fullscreen/rewarded, mudanças em score, motor UDP, Worker, catálogo ou telemetria própria.
- **Lane:** full flow sistêmica / release candidate.
- **Fonte de verdade:** Decisões 82, 97, 98 e 99; `.agents/architecture-plan-ios-ads-2026-10-17.md`; `docs/01-funcional.md` §11; `docs/06-fluxo-de-release.md`.

## Donos, risco e aceite

- **Autorização de monetização e upload:** Luiz — concedida em 17/10/2026.
- **Aceite operacional:** Giam; **arquitetura/privacidade:** Camillo; **implementação iOS:** Rian; **visual:** Renan; **QA:** Breno.
- **Risco principal:** o SDK de publicidade coleta/processa dados próprios e a ausência de anúncio não pode deslocar nem bloquear a jornada.
- **Rollback:** `LAGCHECK_ADS_ENABLED=NO` elimina UMP, inicialização e slots sem tocar na medição.

| Critério | Evidência mínima | Estado inicial |
| --- | --- | --- |
| UMP antes de request; opção de privacidade quando exigida | iPhone real com cenário de consentimento | pendente |
| Banners elegíveis só nos quatro destinos; Check, inconclusivo e detalhes sem slot | iPhone real, VoiceOver e fonte ampliada | pendente |
| Falha/ausência de banner não bloqueia CTA, score, resultado ou share | iPhone real com falha controlada | pendente |
| SDK fora de domínio, motor, catálogo, Worker e telemetria própria | inspeção e testes/build | validado por inspeção e build local |
| Política pública e rascunho de App Privacy refletem o SDK | inspeção de fonte e matriz de disclosure | política publicada em `lagcheck.vercel.app`; Console pendente |
| Archive assinado `1.0.2 (4)` é aceito pelo App Store Connect | archive, upload e estado de processamento | enviado pelo Organizer do Xcode; App Store Connect recebeu o build |

## Limite de evidência

Testes e build locais não provam consentimento UMP, preenchimento de anúncio, acessibilidade, dados de SDK ou processamento da Apple. O iPhone conectado estava offline na abertura desta missão; a prova física continua obrigatória antes do aceite interno.

## Registro de execução — 17/10/2026

- `xcodebuild test` (`NolaggyCoreTests`) e o build Release sem assinatura passaram; a validação estática do site passou em 148/148.
- O site foi publicado no Vercel e a política pública passou a descrever AdMob/UMP. O app agora aponta para `https://lagcheck.vercel.app/privacy/` e `/support/`.
- O archive e o IPA `1.0.2 (4)` foram gerados e o IPA passou em `codesign --strict` com `Apple Distribution`; ele inclui Google Mobile Ads e UMP.
- O Organizer do Xcode enviou o archive ao App Store Connect em 17/10/2026 às 16:25; o status exibido é **Uploaded**, build `4`. A Apple ainda precisa processá-lo antes de ele aparecer como instalável no TestFlight.
- O Xcode concluiu com dois avisos não bloqueantes de upload de dSYM dos frameworks pré-compilados `GoogleMobileAds` e `UserMessagingPlatform`. O archive e o upload foram aceitos; investigar símbolos antes da próxima distribuição para melhorar a simbolicação de crashes desses SDKs.
- O iPhone físico permanece offline; UMP, preenchimento/ausência de banner, acessibilidade e jornada real de ads continuam pendentes de prova em aparelho.
