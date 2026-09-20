# LagCheck — checklist de lançamento na App Store

**Estado:** preparação; não autoriza upload, submissão nem publicação
**Atualizado em:** 19 de setembro de 2026
**Escopo:** primeira versão pública do LagCheck para iPhone (iOS 17+)
**Fontes de verdade:** `docs/05-governanca-e-fluxo-de-trabalho.md`, `docs/06-fluxo-de-release.md`, decisões 18, 23, 33 e regras vigentes em `AGENTS.md`.

## Como usar

Este documento é um gate, não uma lista de intenções. Cada item só recebe **feito** com um link, versão/build, captura ou registro objetivo. Os estados possíveis são:

- **bloqueado:** há uma pendência conhecida que impede avançar;
- **a validar:** ainda não há evidência no ambiente correto;
- **feito:** a evidência foi registrada;
- **não se aplica:** decisão registrada com justificativa.

O release não avança de fase com qualquer item obrigatório bloqueado ou a validar. Submissão para App Review e publicação manual exigem a autorização explícita do dono do produto, Luiz.

## Fotografia inicial do repositório

Esta é uma leitura local, não uma afirmação sobre App Store Connect, TestFlight ou iPhone físico.

| Item | Estado | Evidência ou pendência |
| --- | --- | --- |
| Escopo de dispositivo | feito local; a validar na loja | Rian confirmou no target distribuível `Nolaggy`, em Debug e Release: iPhone (`TARGETED_DEVICE_FAMILY = 1`), iOS 17.0 e `SUPPORTED_PLATFORMS = iphoneos iphonesimulator`. O simulador não habilita iPad/Mac. Ainda falta conferir a mesma compatibilidade no registro do App Store Connect e no archive candidato. |
| Marca no app e material público | feito local; bloqueado externamente | O Release declara `CFBundleDisplayName = LagCheck`, AppIcon Coral Solar e Wordmark corretos. Por decisão do dono do produto, o bundle foi migrado para `com.lagcheck.app`; namespaces internos Nolaggy permanecem apenas internos. As páginas públicas isoladas do LagCheck foram criadas no projeto Firebase do Linka sob `/lagcheck/suporte` e `/lagcheck/privacidade`, mas ainda não foram publicadas. Antes do archive, registrar `com.lagcheck.app` na Apple e confirmar o bundle, SKU e nome da ficha no App Store Connect. |
| Versão candidata | bloqueado por distribuição e regressão | `1.0.0 (1)` é tecnicamente disponível: `com.lagcheck.app` não existe na Apple e não tem uploads associados. O dono do produto confirmou a validação física de Wi-Fi, celular, troca de rede, Deep Check e inconclusivo. A decisão 43/46 está integrada localmente: build, teste focado de recusa celular e teste de aplicação passaram; a suíte completa de UI ainda é pendência de regressão. Gemini foi aceito condicionalmente pela decisão 45. O catálogo remoto/cache/fallback foi comprovado no build Release sem assinatura e em 9 testes focados; ainda falta exercício no iPhone com o binário Release offline/cache corrompido. O recorte público remove editorial sem fonte auditada e diagnóstico NAT/STUN/CGNAT; o teste UI de ausência passou. Restam cortar um commit limpo, executar regressão completa e passar pelo primeiro TestFlight interno. Não configurar versão/build final até fechar esse recorte. |
| Links dentro do app | feito local; a validar publicado | O target Release aponta para `https://linka-speedtest.web.app/lagcheck/suporte` e `https://linka-speedtest.web.app/lagcheck/privacidade`. Falta publicar e abrir ambas no iPhone e no domínio público antes do archive. |
| Suporte e privacidade públicos | feito local; bloqueado publicação | As páginas autocontidas foram criadas em `linka/ios/aplicacao-web/public/lagcheck/`, com rewrites explícitas no Firebase antes do catch-all do SPA Linka. Lint, build e geração em `dist/` passaram; não há deploy nem verificação pública ainda. |
| Gemini no Deep Check | risco aceito condicionalmente | A decisão 45 autoriza o cliente direto apenas no candidato público `1.0.0` e no seu TestFlight interno. A chave é extraível do IPA e o contexto técnico do Deep Check é transmitido ao Gemini; privacidade, App Review Notes e plano de contenção precisam refletir isso. Proxy continua obrigatório antes de TestFlight externo ou qualquer release posterior. |
| Identidade visual do catálogo | feito por decisão do produto | O dono do produto confirmou que as imagens `Game*.imageset` são artes próprias geradas por IA e aprovou seu uso no catálogo e em screenshots. A decisão 44 registra que associação editorial, personagem, cenário, HUD ou texto presentes nas artes atuais não bloqueiam o release. Continua proibido importar ou copiar ativos oficiais de terceiros. |
| Internacionalização global | a validar | PT-BR, inglês e espanhol existem no projeto, mas a decisão 33 ainda está “em implementação”. Validar paridade, mercado resolvido e metadados/suporte nas localidades escolhidas. |
| Trabalho em andamento | bloqueado | Há alterações locais não integradas em jornadas, catálogo, UI, testes e decisões 22/43. Definir o corte do release, integrar somente o que passou por revisão e gerar o candidato a partir de um commit identificável. |

## 1. Fechar o escopo do release candidate

- [ ] **Marco:** registrar objetivo, escopo e não-escopo da versão pública.
- [ ] **Rian:** informar commit/PRs que compõem o candidato e confirmar árvore limpa no momento do archive.
- [ ] **Marco + Luiz:** decidir mercados de lançamento. A decisão 33 orienta prontidão global, mas os países só entram após confirmação no App Store Connect e capacidade de suporte.
- [ ] **Marco + Renan + Iury + Rian:** registrar qualquer exceção ao protótipo, à promessa de medição ou à direção visual.
- [ ] **Marco:** escolher `MAJOR.MINOR.PATCH`; **Rian:** definir build inédito e maior que todo upload anterior.
- [ ] **Rian:** confirmar que o archive Release não contém fixtures, mocks, chaves, endpoints internos ou configuração de anúncio.
- [ ] **Rian + Marco:** aplicar a decisão 45 ao candidato `1.0.0`: registrar o risco aceito, confirmar comportamento de falha sem dica inventada e preparar contenção de credencial. Não ampliar o Worker atual. Proxy permanece obrigatório antes de TestFlight externo ou do próximo release público.
- [ ] **Renan + Rian:** auditar todos os assets embarcados. A loja, screenshots e binário usam apenas a marca LagCheck e arte própria/neutra aprovada.

## 2. Validar o produto antes do TestFlight

- [ ] **Rian:** build Release e testes unitários, de contrato e UI aplicáveis passaram; anexar comandos, data e resultado.
- [ ] **Iury:** aprovar versão da regra de score, thresholds e vetores de teste do candidato.
- [ ] **Rian + Iury:** exercitar Deep Check único em iPhone físico, em Wi-Fi e celular, com consentimento aceito/recusado, respostas UDP suficientes e caminho inconclusivo.
- [ ] **Rian + Iury:** exercitar Deep Check: repouso, carga concluída, carga interrompida, dados insuficientes, cancelamento, troca de rede e ida ao background. Confirmar que resultado parcial é descartado.
- [ ] **Rian:** no iPhone com o binário Release, validar indisponibilidade e retorno dos serviços remotos (catálogo, carga, status de plataforma e, se permanecer no escopo, dicas), incluindo catálogo offline e cache corrompido; sem inventar score ou recomendação. O fallback já foi comprovado no build Release sem assinatura e em 9 testes focados.
- [ ] **Rian:** conferir permissões e avisos em aparelho real, incluindo rede local e dados móveis quando o fluxo os solicita; textos de uso e consentimento precisam ser claros.
- [ ] **Renan:** comparar os fluxos alterados com o protótipo canônico e aprovar contraste, alvos de 44 pt, Dynamic Type, VoiceOver e estados fora do protótipo.
- [ ] **Marco + Renan:** revisar PT-BR, inglês e espanhol no iPhone; a comunicação deixa claro que a medição é até infraestrutura de referência e é estimativa fora do jogo/dispositivo real.
- [ ] **Rian:** validar histórico, exclusão, cache e fallback do catálogo no aparelho, sem reter dados além do documentado.

## 3. TestFlight controlado

- [ ] **Marco:** definir pergunta de validação, grupo interno, instruções e canal de feedback para `versão (build)`.
- [ ] **Rian:** gerar archive Release, validar assinatura e fazer upload; registrar o resultado de processamento da Apple.
- [ ] **Marco:** liberar primeiro para TestFlight interno; “upload concluído” não conta como distribuição.
- [ ] **Time:** registrar evidência de cada cenário do bloco 2 com modelo de iPhone, iOS, tipo de rede e resultado.
- [ ] **Marco:** consolidar bugs em corrigir, aceitar com risco ou adiar; não há release candidate aprovado sem aceite de Iury para impacto de medição e de Renan para experiência/acessibilidade.
- [ ] **Marco + Luiz:** decidir se haverá TestFlight externo. Para `1.0.0`, ele permanece proibido pela decisão 45; só poderá existir após proxy aprovado, informações de beta completas e fluxo principal validado internamente.

## 4. Preparar App Store Connect e a página da loja

- [ ] **Luiz / titular da conta:** confirmar acordos, dados bancários/fiscais e acesso de conta necessários. Não preencher declaração legal sem o responsável autorizado.
- [ ] **Marco:** criar/confirmar o registro do app com bundle identifier definitivo, SKU, categoria e disponibilidade compatíveis com o lançamento.
- [ ] **Marco + Renan:** preparar nome `LagCheck`, subtítulo, descrição, palavras-chave, copyright e notas da versão por localidade. Não usar nomes de outros apps/empresas como keywords.
- [ ] **Renan:** capturar screenshots reais do binário candidato, sem mock que prometa resultado não observado. Preparar de 1 a 10 por tamanho/localidade exigido; app preview é opcional.
- [ ] **Marco + Renan:** revisar screenshots, copy e metadados para não sugerirem “ping do jogo”, “zero lag”, resultado garantido ou suporte a plataforma que o app não mede diretamente.
- [ ] **Marco:** preencher classificação etária com base no conteúdo real e declarar corretamente conteúdo de jogos, links externos, recursos online e qualquer interação aplicável.
- [ ] **Marco + Rian:** preencher direitos de conteúdo e confirmar que nomes, marcas, referências editoriais e qualquer conteúdo de terceiros têm base de uso em todos os países selecionados.
- [ ] **Rian + Marco:** responder a privacidade a partir do binário e dos parceiros reais — AWS/GameLift, Cloudflare, serviços de status e Gemini, se aplicável. A declaração não pode dizer “não coletamos dados” sem verificar o que cada integração transmite/retém.
- [ ] **Marco:** informar URL HTTPS pública de política de privacidade no App Store Connect; a página precisa corresponder ao binário candidato e explicar contato/solicitações de privacidade.
- [ ] **Marco:** informar URL HTTPS pública de suporte com contato real e testado. Configurar as mesmas URLs no app e confirmar que abrem no iPhone.
- [ ] **Rian:** responder a export compliance para o archive enviado, considerando TLS e qualquer criptografia usada; anexar documentação se a Apple indicar que ela é necessária.
- [ ] **Rian + Marco:** preparar App Review Notes: como executar Deep Check, permissões, dependências de rede, comportamento inconclusivo e contato responsivo. Fornecer credenciais apenas se o app realmente exigir login.
- [ ] **Rian:** revisar assinatura, capabilities, permissões, uso de APIs e manifestos de privacidade exigidos pelo Xcode/SDKs efetivamente incluídos.
- [ ] **Marco:** definir preço, países e imposto/categoria fiscal; confirmar que não há compra, assinatura ou publicidade fora do escopo do MVP1.

## 5. Submeter e publicar

- [ ] **Marco + Rian:** conferir que o build selecionado na versão é exatamente o release candidate aprovado no TestFlight; qualquer mudança gera novo build e retorna ao TestFlight.
- [ ] **Marco:** conferir todos os campos obrigatórios e o estado `Ready for Review` no App Store Connect.
- [ ] **Luiz:** dar autorização explícita e registrada para `Submit for Review`. Preparar não é autorização para esse clique.
- [ ] **Marco:** escolher **release manual após aprovação** para a primeira versão pública.
- [ ] **Marco:** acompanhar mensagens/rejeições da App Review; se houver mudança de código ou configuração, retirar/corrigir e refazer os gates necessários.
- [ ] **Marco + Luiz:** após `Pending Developer Release`, confirmar versão/build, países e plano de suporte antes do clique de publicação manual.
- [ ] **Marco:** confirmar a versão visível na App Store e registrar hora, países e link. “Approved” não é “Published”.

## 6. Primeiras 48 horas e contingência

- [ ] **Marco:** acompanhar crashes, feedback voluntário, avaliações e dados agregados disponíveis no App Store Connect.
- [ ] **Iury + Rian:** acompanhar relatos de medição inconclusiva, rota enganosa, falha do catálogo/carga e regressões por rede/região.
- [ ] **Marco:** manter um canal de resposta de suporte com responsável e SLA de triagem definidos.
- [ ] **Time:** se houver risco de privacidade, crash relevante, bloqueio do fluxo ou resultado de rede enganoso, interromper a liberação manual quando possível e abrir hotfix `PATCH` com build novo. Não existe rollback instantâneo de binário já instalado.

## Registro do release

Preencher somente com evidência observada:

```text
Versão/build:
Commit do archive:
Canal:                    TestFlight interno | TestFlight externo | Produção
Objetivo:
Escopo:
Validações:               testes, aparelhos, iOS e redes usados
Pendências/riscos aceitos:
Decisão e data:           enviado | aceito | rejeitado | aprovado | publicado
Responsáveis e aceite:    Marco | Renan | Rian | Iury | Luiz
Links de evidência:
```

## Referências externas consultadas

- Apple exige metadados completos e o build correto antes da submissão: <https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app>
- Política de privacidade e declaração de dados são obrigatórias para apps iOS distribuídos na App Store: <https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy>
- A classificação etária é obrigatória; um app sem classificação não pode ser publicado: <https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating>
- A Apple exige de uma a dez screenshots por tamanho/localidade aplicável: <https://developer.apple.com/help/app-store-connect/manage-app-information/upload-app-previews-and-screenshots>
- A aprovação pode anteceder a disponibilidade pública; a Apple documenta release manual, automático ou em fases: <https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/overview-of-publishing-your-app-on-the-app-store>
