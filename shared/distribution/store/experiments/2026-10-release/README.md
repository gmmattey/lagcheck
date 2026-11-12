# LagCheck — experimento de página de loja pós-versão

Este diretório prepara, para revisão local, tratamentos de criativos para a
próxima versão. Ele não cria um experimento, não envia arquivos, não altera
fichas, não muda metadados e não determina vencedor.

## Pergunta que o teste responde

Qual mensagem na primeira captura ajuda mais uma pessoa em `pt-BR` a entender
a proposta real do LagCheck?

- **A — decisão antes da fila:** `ANTES DA FILA, VEJA A ROTA.`
- **B — clareza do resultado:** `SUA CONEXÃO, UM RESULTADO CLARO.`

Ambas usam uma tela real de Check em cenário controlado e descrevem a leitura
da rota para infraestrutura de referência. Nenhuma a chama de ping do jogo,
promete que a conexão vai melhorar, ou atribui uma causa a Wi-Fi/operadora.

## Desenho

| Elemento | App Store | Google Play |
| --- | --- | --- |
| Controle | Página publicada no momento da criação | Listing publicada no momento da criação |
| Tratamentos prontos | A e B | A e B |
| Ativo modificado | Só a primeira screenshot | Só a primeira screenshot |
| Ícone | Controle; fora do teste | Controle; fora do teste |
| Localização | pt-BR | pt-BR |
| Métrica primária | Conversão/instalação indicada pelo App Analytics | `Unique user install clicks`, salvo decisão documentada no console |
| Proteção | Fidedignidade ao build e resultado conclusivo | Fidedignidade ao build e resultado conclusivo |

## Arquivos

```text
store/app-store/pt-BR/experiments/2026-10-release/
  treatment-a-decisao/manifest.json
  treatment-b-clareza/manifest.json
store/google-play/pt-BR/experiments/2026-10-release/
  treatment-a-decisao/manifest.json
  treatment-b-clareza/manifest.json
```

Cada manifesto aponta para uma captura controlada já presente no repositório e
o renderizador gera `final/`, `reports/` e `previews/` ao lado dele. O relatório
`ready_for_review` só confirma o arquivo local; não é aceite da loja nem prova
de fidelidade ao release candidate.

## Travas para usar depois

1. Revalidar os ativos com o build candidato, a privacidade e a ficha vigentes.
2. Conferir a elegibilidade e a estimativa de duração/volume no console no dia.
3. Não testar o ícone: a Decisão 91 mantém isso adiado por volume insuficiente.
4. Testar somente esta variável. Não trocar descrição, feature graphic, ícone,
   preço, onboarding ou outra screenshot na mesma rodada.
5. Giam registra o desenho exibido pelo console; Luiz autoriza a criação.
6. Só aplicar tratamento se o console indicar resultado conclusivo e Luiz der
   a ordem. Empate, `More data needed` e resultado inconclusivo preservam o
   controle.

## Limites por plataforma, conferidos em 16/10/2026

- **Apple Product Page Optimization:** app em `Ready for Distribution` e live;
  até três tratamentos; uma nova versão durante o teste pode afetar o resultado.
- **Google Play Store Listing Experiments:** a listing precisa estar pronta para
  experimentos; até duas variantes contra o controle; a métrica deve ser
  escolhida no console, que estima o volume/duração.

As regras do console e a documentação oficial no momento da ativação prevalecem
sobre esta preparação local.
