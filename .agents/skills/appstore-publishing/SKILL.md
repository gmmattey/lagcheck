---
name: appstore-publishing
description: Prepara e audita publicação, metadados, revisão e experimentos da Apple App Store, sem submeter ou alterar App Store Connect sem autorização explícita.
---

# Publicação Apple

Use para App Store Connect, TestFlight, App Review, App Privacy, Product Page
Optimization, Custom Product Pages ou rejeições. Antes de propor campos,
confira a documentação Apple atual e o binário/documentos reais.

## Checagem local

- Rode o validador com `platform: "ios"`; ele valida limites conhecidos e
  reporta revisão humana pendente — não certifica aprovação da Apple.
- Compare cada claim, screenshot e declaração de privacidade com o build e
  integrações reais. Para o LagCheck, a telemetria anônima existente ainda
  exige declaração baseada no comportamento verificado, não uma inferência de
  “nenhum dado”.
- A submissão requer metadados obrigatórios e o build selecionado. O clique
  de submissão, resposta à revisão e publicação continuam bloqueados até ordem
  explícita do dono do produto.

## Checklist por operação

| Situação | Verificar antes de preparar |
| --- | --- |
| Primeira versão ou update | versão/build correto, categoria, idade, disponibilidade, direitos, URLs de suporte e privacidade, export compliance, App Review Notes e screenshots reais |
| Privacidade e ATT | binário, SDKs, tráfego e finalidade; não deduza o formulário por nome de endpoint ou documento antigo |
| TestFlight | grupo, pergunta de beta, build processado, risco aceito e feedback; instalação local não é beta |
| IAP/assinatura | produto real no app, preço, direitos entregues, restore, telas de compra e primeira submissão; não crie o item no console sem ordem |
| Rejeição | mensagem literal da Apple, item afetado, claim/asset/build envolvido e menor correção verificável; prepare a resposta, não a envie |

Não prometa que “metadados aprovados localmente” serão aceitos. Para operações
elegíveis, confirme o papel necessário no console, a documentação Apple atual
e o estado do item antes de recomendar o próximo clique.

## Experimentos

Product Page Optimization só é proposta para app elegível e publicado. Defina
uma hipótese, uma mudança de asset por vez, métrica principal, guarda,
segmento e decisão. A Apple permite até três tratamentos; só reporte vencedor
quando o console mostrar o resultado com confiança suficiente.

Consulte `docs/listing-app-store.md`, `docs/checklist-lancamento-app-store.md`
e `gate-testflight` no LagCheck.
