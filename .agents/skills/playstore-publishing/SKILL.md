---
name: playstore-publishing
description: Prepara e audita distribuição Android no Google Play, incluindo AAB, trilhas, Data safety, vitals e listagem, sem publicar ou alterar Play Console sem autorização explícita.
---

# Publicação Google Play

Use para Play Console, AAB, internal/closed/open/production, Data safety,
target API, Android Vitals, listing ou suspensão. Reconfirme requisitos do
Google Play antes de tratar uma regra como atual.

## Checagem local

- Rode o validador com `platform: "android"`; ele confere limites de texto e
  reporta políticas que ainda precisam de revisão humana.
- Inspecione `android/app/build.gradle.kts`, manifesto, permissões e AAB
  fornecido. Um build local não prova aceite do Play nem o estado de uma trilha.
- Compare Data safety e política de privacidade com o comportamento efetivo
  do app e parceiros. Nunca preencha ou altere esses formulários sem
  autorização explícita.

## Lançamento

Registre trilha, versão/versionCode, público, objetivo, métrica de qualidade,
limiar de pausa e plano de rollback. Mudança de trilha, rollout, managed
publishing ou resposta à suspensão é ação externa e exige autorização.

Para o LagCheck, use `docs/listing-google-play.md` e confirme o target API
vigente no Google antes do upload.

## Checklist por operação

| Situação | Verificar antes de preparar |
| --- | --- |
| App/trilha | package name, AAB, versionCode crescente, público correto, testes exigidos e notas de versão |
| Conformidade | target API vigente, permissões sensíveis, Data safety, política de privacidade, IARC e declarações de conteúdo reais |
| Qualidade | crashes, ANRs, Android Vitals, dispositivos incompatíveis e fluxo crítico no aparelho; build instalado não prova aceite do Play |
| Listagem | título/descrições, screenshots reais, feature graphic, localizações e coerência com o app |
| Staged rollout/rejeição | percentual, métrica de pausa, plano de reversão e mensagem literal do Play; rascunhe a resposta sem enviá-la |

Não presuma que uma regra histórica de testes ou target API continua válida. O
Play Console e a documentação oficial do dia são a fonte final.
