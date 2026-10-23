# Nico

Nico é a frente local de crescimento, operações de loja e direção criativa. Ele ajuda a
descobrir onde a jornada de um app quebra — descoberta, página, instalação,
ativação, retenção ou receita — sem transformar hipótese em dado ou rascunho em
publicação.

## Uso

```text
Nico, auditar aplicativo
Nico, preparar artes deste aplicativo para a App Store
Nico, gerar screenshots para o Google Play
Nico, criar três variantes para testar conversão
Nico, analisar por que este aplicativo não está crescendo
```

O ponto de entrada é `.agents/agents/nico.md`. Ele carrega a skill
necessária em vez de despejar todas as regras de lojas no contexto. A estrutura
é versionada no próprio repositório e usa Markdown/JSON/Python padrão, então
também pode ser lida por Claude Code ou Antigravity; a descoberta específica de
skills depende do host.

## Fluxo seguro

```bash
python3 tools/nico_validate.py discover --root .
python3 tools/nico_validate.py validate --input Tests/nico/fixtures/ios-valid.json
python3 tools/nico_validate.py guard-operation --operation publish
python3 -m unittest discover -s Tests/nico -p 'test_*.py'
```

O validador é local: não lê segredos, não chama Apple/Google e não publica.
Ele confere limites de metadados e impede que um fluxo automatizado trate uma
operação externa sensível como autorizada. Política, direitos, App Privacy,
Data safety, fidelidade dos screenshots e estado do console sempre exigem
revisão de evidência real.

## Mapa de capacidades

| Capacidade | Implementada localmente | Depende de autorização / conexão |
| --- | --- | --- |
| Descobrir plataformas e evidência no repositório | Sim | — |
| Auditar funil e produzir plano priorizado | Sim, com dados disponíveis | Métricas privadas ampliam a conclusão |
| Validar limites básicos iOS/Android | Sim | Conferência final no console e política atual |
| Preparar ASO, criativos e experimento | Sim | Criar/aplicar experimento na loja |
| Analisar página pública e concorrentes | Sim, por pesquisa | Rankings/receita privados não disponíveis publicamente |
| Consultar App Store Connect / Play Developer API | Não configurado | Credencial, escopo e autorização explícitos |
| Publicar, alterar preço, privacidade ou responder review | Não | Ordem explícita do Luiz e acesso apropriado |
| Agendar acompanhamento | Não automático | Workflow/agendamento existente ou nova autorização |

Os escopos mínimos, limites, alternativas e estado de cada integração estão em
[`docs/nico-integrations.md`](nico-integrations.md).

## Fonte de regras mutáveis

Os limites codificados são guardrails, verificados em 14 de outubro de 2026:
Apple define nome e subtítulo de até 30 caracteres, keywords de até 100 bytes,
texto promocional de 170 e descrição de 4.000; Google Play deve ser conferido
no Console/políticas antes de uma alteração final. A fonte oficial prevalece
quando ela mudar. Veja [App information da Apple](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/), [platform version information](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/), [Product Page Optimization](https://developer.apple.com/help/app-store-connect/create-product-page-optimization-tests/overview-of-product-page-optimization/), [experimentos do Google Play](https://support.google.com/googleplay/android-developer/answer/12053285) e [Target API policy](https://support.google.com/googleplay/android-developer/answer/16561298).

## Contratos

O relatório usa `.agents/skills/store-audit/references/report-contract.md`:
evidência classificada, dois maiores gargalos, funil, oportunidades priorizadas
e validação. Todo experimento inclui hipótese, controle, variável única,
métrica principal, métrica de proteção, segmento, critério de decisão e parada.

Para o LagCheck, prevalecem as promessas honestas do `AGENTS.md`: a medição é
do dispositivo até infraestrutura de referência; resultado para console/PC é
estimativa; sem UDP suficiente o resultado é inconclusivo. Nico não
autoriza claims que ultrapassem isso.

## Estúdio criativo

`store-creative-studio` produz PNGs reais e uma galeria HTML local a partir de
capturas do app. Use os manifestos editáveis e scripts documentados na própria
skill. O [pacote demonstrativo](../store/app-store/pt-BR/nico-demo/README.md)
mostra o caminho completo com uma captura de simulador controlada; ele não é
arte enviada à Apple.
