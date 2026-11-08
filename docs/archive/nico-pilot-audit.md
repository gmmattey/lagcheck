# Nico — Auditoria piloto do LagCheck

**Escopo:** evidência local disponível em 14 de outubro de 2026. Não houve
consulta autenticada a App Store Connect, Play Console, analytics ou página
pública confirmada.

## Estado de evidência

| Item | Estado | Fonte / período | Limite |
| --- | --- | --- | --- |
| Produto iOS e Android | confirmado | `Nolaggy.xcodeproj`, `android/app/build.gradle.kts` | não prova distribuição |
| Metadados preparados para Apple/Google | confirmado | `docs/lojas/listing-app-store.md`, `docs/lojas/listing-google-play.md` | não prova que foram inseridos nas lojas |
| Assets de ficha | confirmado localmente | `store/app-store/pt-BR/` | estão não rastreados nesta cópia; não são prova de upload |
| Ficha pública, aprovação, installs, conversão, retenção, receita | não disponível | nenhum console ou URL público verificado | não há diagnóstico quantitativo possível |

## Dois maiores gargalos

1. **Não há baseline de distribuição nem funil observável.** Sem impressões,
   visitas, downloads, primeira abertura e retenção por período, não dá para
   dizer se o problema é descoberta, conversão ou valor pós-instalação.
2. **As fontes locais de metadados estão divergentes e parte da copy precisa de
   revisão de promessa.** `docs/lojas/ASO_METADATA.md` propõe outro nome/subtítulo
   dos documentos de listing. A ficha extensa usa expressões como “Ping Real
   nos Servidores do Jogo”, “certified” e “prove … se a culpa … é do servidor”,
   que podem exceder a promessa comprovada no `AGENTS.md`.

## Oportunidades priorizadas

| Ação | Hipótese | Impacto | Confiança | Esforço | Custo | Dependência | Métrica / critério |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Consolidar uma única ficha por loja e locale | reduz risco de promessa divergente e retrabalho | Alto | Alta | Baixo | Zero | Marco, Renan, Luiz | aprovação editorial; campos passam no validador e revisão de claim |
| Registrar baseline da loja e ativação | separa falha de descoberta de conversão/retenção | Alto | Alta | Médio | Zero se console já existir | acesso autorizado ao console | impressões → page views → downloads → primeira medição por semana |
| Testar primeira captura contra mensagem de veredito honesto | melhora compreensão da proposta antes de instalar | Médio | Média | Médio | Zero | ficha publicada e tráfego suficiente | decisão exibida pelo experimento da plataforma, não opinião |

## Próxima ação

**Ação:** escolher o documento canônico de metadata e reconciliar as duas
fichas com a promessa diagnóstica do LagCheck antes de qualquer preenchimento
de console. **Impacto esperado:** reduzir risco de rejeição/expectativa errada
e deixar um experimento de conversão válido. **Validação:** revisão Marco +
Renan e validação local; a aprovação/publicação ainda depende do Luiz e da
loja.
