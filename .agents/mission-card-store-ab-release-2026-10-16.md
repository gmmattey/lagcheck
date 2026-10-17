# Cartão de Missão — LagCheck

## Páginas de loja para experimento pós-versão

### Enquadramento

- **Problema da pessoa:** quem encontra o LagCheck na loja precisa entender em poucos segundos que ele entrega uma leitura honesta da rota antes da partida, sem confundir isso com ping real do jogo ou promessa de eliminar lag.
- **Resultado esperado observável:** ficam prontas, localmente, duas variações de primeira captura para a App Store e duas para o Google Play. Em cada loja, a única variável é a narrativa da primeira captura; ícone, metadados, demais criativos, funcionalidade e promessa permanecem como controle.
- **Fora de escopo:** criar, editar ou publicar qualquer item no App Store Connect ou Play Console; enviar binário; alterar preço, privacidade, Data safety, anúncios, metadados aprovados, ícone, score, medição, Worker ou catálogo; declarar uma variante vencedora.
- **Lane:** Fast lane.
- **Por que esta lane:** prepara ativos locais e um plano de conversão; não altera o produto, seus contratos nem qualquer estado externo.
- **Fonte de verdade:** `docs/01-funcional.md`, `docs/04-design-system.md`, `docs/06-fluxo-de-release.md`, `docs/07-voz-do-produto.md`, `docs/listing-app-store.md`, `docs/listing-google-play.md`, Decisões 74, 83 e 91.

### Donos e fronteiras

- **Responsável pela preparação:** Nico.
- **Aceite operacional:** Giam.
- **Estratégia/prioridade:** Marco.
- **Revisores obrigatórios antes de console:** Renan (fidelidade e copy), Breno (correspondência com o build candidato) e Giam.
- **Decisão pendente do Luiz:** autorização separada para criar/rodar cada experimento e para aplicar qualquer tratamento vencedor. Preparar arquivos não constitui essa autorização.
- **Gate arquitetural:** não aplicável.

### Hipótese e desenho do teste

| Loja | Controle | Tratamento A | Tratamento B | Variável única |
| --- | --- | --- | --- | --- |
| App Store | Página publicada na data do teste | `ANTES DA FILA, VEJA A ROTA.` | `SUA CONEXÃO, UM RESULTADO CLARO.` | Headline e apoio da primeira screenshot |
| Google Play | Listing publicada na data do teste | `ANTES DA FILA, VEJA A ROTA.` | `SUA CONEXÃO, UM RESULTADO CLARO.` | Headline e apoio da primeira screenshot |

- **Hipótese:** uma promessa curta centrada na decisão antes da fila ou na clareza do resultado pode elevar a conversão da página em relação ao controle atual; não se presume qual delas vence.
- **Métrica principal:** instalação por visitante, usando a métrica equivalente escolhida pelo console para a loja e estado do app.
- **Métrica de proteção:** não aplicar variante que contradiga o build candidato, que reduza compreensão da limitação de rota de referência, ou cujo resultado do console seja inconclusivo.
- **Segmento:** somente `pt-BR` inicialmente. Não misturar localizações ou canais de aquisição sem registrar a segmentação no console.
- **Condição de partida:** a versão nova precisa estar distribuída no estado que o console exige; a página/listing de controle deve estar totalmente publicada; cada screenshot deve ser revisada contra o build final. Na Apple, não iniciar/alterar o experimento durante a publicação da versão se os próprios ativos estiverem mudando.
- **Condição de decisão:** usar apenas a recomendação/confiança exibida pelo console; `More data needed`, empate, ou resultado inconclusivo mantém o controle. A decisão 91 registra que o volume observado antes desta missão não sustentava experimento; não há limiar inventado localmente.

### Aceite e evidência

| Critério observável | Dona/o da prova | Evidência exigida | Estado |
| --- | --- | --- | --- |
| Duas variantes por loja têm captura da plataforma correta e PNG sem alpha | Nico | manifesto, relatório do renderizador e validação local | pendente |
| A variável é só a narrativa da primeira captura; ícone não participa | Nico / Renan | inspeção das galerias e do plano | pendente |
| A copy não chama a rota de ping do jogo nem promete melhora/causa | Marco / Renan | revisão humana de copy | pendente |
| Captura representa a versão candidata, sem arte de jogo de terceiros | Renan / Breno | confronto com build candidato | pendente |
| Só inicia após estado e estimativa de duração/volume do console | Giam / Luiz | evidência de console autorizada | não iniciado |
| Tratamento só é aplicado após autorização de Luiz e resultado conclusivo no console | Luiz / Giam | registro do console e decisão | não iniciado |

### Handoff

- **Pacote local:** `store/experiments/2026-10-release/` e os manifestos em cada loja.
- **Próximo passo:** quando o candidato de versão estiver de pé, Renan/Breno confrontam as telas com o binário; Giam reabre este cartão com o volume/estimativa do console; Luiz decide se autoriza a execução externa.
- **Estado externo:** nenhum. Não há experimento criado, asset enviado, ficha alterada, build associado ou página publicada por esta missão.
