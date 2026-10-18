# Cartão de Missão — Experiência EUA

## Enquadramento

- **Problema da pessoa:** 8 dos 16 primeiros downloads (App Store Connect, 17 de out. de 2026) são dos EUA. Quem joga lá precisa de um app em inglês natural, com a rota certa e sem sinais de produto feito só para o Brasil. Amostra pequena: serve de direção, não de prova.
- **Resultado observável:** jogador americano abre o app em inglês, escolhe o jogo, recebe o veredito medido contra a baliza mais próxima e vê só região, data e hora no formato dele.
- **Fora de escopo:** novo endpoint, mudança de score/veredito/thresholds, mercado novo no catálogo assinado, SDK ou custo.
- **Lane:** Full flow comum para copy e formatos. Qualquer mudança em catálogo, seleção regional ou mercado vira **Full flow sistêmica** com Gate do Camillo e revisão do Iury.
- **Fonte de verdade:** Decisões 16, 28, 29, 90, 99 e 105; `docs/07-voz-do-produto.md`.

## Apurado (inspeção do código; nada medido em aparelho nos EUA)

| Hipótese | Resultado |
| --- | --- |
| A rota fica presa a São Paulo por o catálogo só ter mercado `BR` | **Não.** Na rota assinada v3 (Decisão 90) todas as regiões assinadas são pré-lidas e a regra escolhe pelo RTT real; os EUA têm `us-east-1`, `us-east-2`, `us-west-1`, `us-west-2` e `ca-central-1`. `market: "BR"` é só a chave do catálogo (121 contextos, todos `BR`). Falta provar em aparelho nos EUA. |
| `"BR"` fixo no App Clip e nos fallbacks é defeito | **Não por si só.** É a chave que existe no catálogo; trocar exigiria mercado novo assinado. |
| Textos fixos de "São Paulo" | **Defeito corrigido no iOS:** os detalhes da medição mostravam sempre "São Paulo · reference region". Agora mostram a região medida. Android já usa o destino real. |
| Hora e data com padrão brasileiro | **Defeito corrigido no Android:** hora `HH:mm`, `dd MMM` e `dd/MM/yyyy` fixos. Agora seguem o idioma do app (EUA: 3:45 PM, mês primeiro). No iOS não achei formato fixo. |
| Catálogo relevante nos EUA | **Lacuna a decidir:** 17 jogos ativos no iPhone; faltam títulos mobile populares nos EUA. |

## Pendências

1. **Prova em aparelho nos EUA (Breno/Iury):** iPhone em rede americana (ou VPN com ressalva) confirmando que a baliza escolhida é a americana e o veredito é coerente. Sem isso, não afirmar.
2. **Catálogo (decisão do Luiz + Iury + Camillo):** quais jogos mobile populares nos EUA entram, com arte editorial autoral; exige envelope assinado novo.
3. **Revisão do inglês (Renan, `docs/07`):** ler os fluxos Home → Jogos → Check → Resultado → Histórico em inglês nos dois clientes, procurando tradução literal e termos do Brasil.
4. **Ficha da App Store em inglês (Nico):** título, subtítulo, palavras-chave e capturas para os EUA. Sem publicar nada sem o Luiz.
5. **Estado `gamesCatalogTitle`:** a string `games.catalog_title` ("Mais jogados no Brasil") não é usada no Swift; remover na limpeza.

## Evidência até agora

- iOS: `xcodebuild build` do esquema `Nolaggy` com sucesso.
- Android: `./gradlew :app:compileDebugKotlin :core:domain:test` com sucesso.
- Não validado: simulador/emulador, aparelho físico, rede nos EUA, VoiceOver/TalkBack.

## Atualização (18 de outubro de 2026) — Decisão 106

- **Feito localmente:** catálogo embutido sem assinatura nem validade; 54 jogos com seis novos para os EUA; 15 artes originais (6 novas e 9 substituições); data/hora por idioma no Android; região medida nos detalhes do iOS.
- **Evidência:** testes do Worker (59), Android (domínio, catálogo e sessão) e build iOS verdes; testes unitários iOS com 7 falhas já existentes no código original.
- **Pendente:** reimplantar o Worker (serve artes antigas até lá); medição em aparelho em rede dos EUA (Breno/Iury); ficha da App Store em inglês (Nico); limpeza de `verifyAndDecode` e telas mortas de resultado. O site agora vive em outro repositório, então `web/` deste não é mais usado.
