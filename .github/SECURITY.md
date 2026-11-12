# Segurança

## Como reportar

Use o **relato privado de vulnerabilidade** do GitHub: aba **Security** do repositório, depois **Report a vulnerability**. Não abra issue pública para falhas de segurança.

Inclua o que você encontrou, como reproduzir e o impacto que enxerga.

## O que esperar

Respondemos o mais rápido possível e avisamos quando houver correção. Não há programa de recompensa.

## Escopo

- Apps iOS, Android e Windows (prévia)
- Cloudflare Worker `nolaggy-deep-check` (`/v1/load` e `/v1/telemetry`)

Os arquivos `GoogleService-Info.plist` e `google-services.json` contêm identificadores públicos de cliente do Firebase, que ficam em todo app publicado. Não são segredos.
