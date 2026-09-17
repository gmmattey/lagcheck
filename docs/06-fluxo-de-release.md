# Nolaggy — fluxo de release

**Status:** regra operacional da V1  
**Idioma:** PT-BR  
**Escopo:** iPhone, iOS 17 ou superior  
**Documentos relacionados:** [Governança e fluxo de trabalho](./05-governanca-e-fluxo-de-trabalho.md) · [Arquitetura](./02-arquitetura.md) · [Especificação técnica](./03-especificacao-tecnica.md)

## 1. Objetivo

Este fluxo define como o Nolaggy sai da máquina de desenvolvimento, passa por TestFlight e chega à App Store sem confundir estados diferentes de entrega.

Uma instalação local não é beta. Um build enviado ao App Store Connect não é distribuído. Um build distribuído pelo TestFlight não é produção. Um build aprovado pela Apple não está publicado até que a opção de release escolhida seja executada.

## 2. Os três canais

| Canal | Para quem | Como instala | Pode usar dados/serviços de produção? | Objetivo |
| --- | --- | --- | --- | --- |
| Debug | Time de desenvolvimento | Direto pelo Xcode em iPhone físico | Não por padrão | Construir e depurar rapidamente |
| TestFlight | Time interno e beta testers autorizados | App TestFlight | Sim, com proteções e dados reais mínimos | Validar o release candidato em condições reais |
| Produção | Público da App Store | App Store | Sim | Entregar uma versão aprovada e monitorada |

O simulador ajuda a validar interface e lógica isolada, mas não substitui instalação Debug em iPhone para medir rede, permissões, ciclo de vida ou comportamento real do sistema.

## 3. Regra de versionamento

O Nolaggy usa dois identificadores obrigatórios.

| Identificador | Formato | Onde aparece | Regra |
| --- | --- | --- | --- |
| Versão de produto | `MAJOR.MINOR.PATCH` | App Store, TestFlight e Ajustes do app | É a versão percebida pelo usuário |
| Número de build | inteiro positivo, por exemplo `42` | Xcode, App Store Connect e diagnósticos | Nunca é reutilizado para um upload; sempre cresce |

No Xcode, a versão de produto corresponde a `MARKETING_VERSION` / `CFBundleShortVersionString`. O número de build corresponde a `CURRENT_PROJECT_VERSION` / `CFBundleVersion`.

### 3.1 Como escolher a versão de produto

| Alteração | Próxima versão | Exemplo |
| --- | --- | --- |
| Primeiro beta funcional | `0.1.0` | primeira jornada utilizável |
| Nova capacidade compatível ou mudança relevante de experiência | aumenta `MINOR` | `0.1.0` → `0.2.0` |
| Correção, texto, acessibilidade ou ajuste sem nova capacidade | aumenta `PATCH` | `0.2.0` → `0.2.1` |
| Mudança incompatível de contrato, dados ou promessa de produto | aumenta `MAJOR` | `0.9.0` → `1.0.0` |

Enquanto o app estiver em pré-lançamento, `0.x.y` comunica evolução. A primeira versão pública deve ser `1.0.0` somente quando a promessa do MVP estiver estável, não porque o primeiro binário foi enviado ao TestFlight.

### 3.2 Como escolher o build

- Todo arquivo enviado ao App Store Connect recebe um build maior que o último enviado. Exemplo: `0.1.0 (42)`, `0.1.0 (43)`, `0.1.1 (44)`.
- O build é globalmente crescente para simplificar rastreio, mesmo que a Apple só exija incremento dentro de uma mesma versão de produto.
- Um build cancelado, rejeitado ou expirado não é reaproveitado.
- Debug local pode usar builds de desenvolvimento, mas não deve reutilizar um número que já tenha sido enviado à Apple. Antes de arquivar para TestFlight, o número de build é definido explicitamente.
- Toda observação de teste, bug crítico e nota de release identifica versão e build: `0.2.0 (57)`; nunca apenas “a versão mais recente”.

## 4. Debug — instalação local e direta

Debug serve para descobrir e corrigir problemas enquanto o trabalho está acontecendo. É um ambiente de desenvolvimento, não uma distribuição informal para usuários.

### 4.1 Regras

- Instalação é feita pelo Xcode diretamente em um iPhone autorizado para desenvolvimento.
- O esquema Debug usa assinatura de desenvolvimento e, se necessário, um bundle identifier próprio de desenvolvimento para coexistir com a versão TestFlight/produção. Essa separação será definida quando o projeto Xcode for criado.
- Endpoints de teste, dados simulados e chaves de desenvolvimento ficam isolados da configuração de release. O MVP1 não contém SDK, ID ou configuração de anúncio.
- Em iPhone físico, Debug, TestFlight e Produção usam o mesmo transporte real de medição aprovado para o catálogo vigente. `Noop` e fixtures existem somente no simulador ou em testes Debug explicitamente acionados; um binário Release nunca pode substituir UDP, observação de caminho ou carga do Deep por uma leitura sintética.
- Debug pode usar catálogo-base e fixtures para reprodução. Quando usar o catálogo remoto, a tela deve indicar claramente o ambiente e não pode alterar catálogo de produção.
- Não há distribuição de IPA, link público ou instalação em aparelho de cliente por esse canal.
- Cada teste relevante registra iPhone, versão de iOS, conexão usada, versão/build e resultado observado.

### 4.2 Gate para considerar um item pronto para TestFlight

Antes de gerar o primeiro archive de um item, Rian confirma:

1. build Debug compila sem falha;
2. testes unitários e de contrato aplicáveis passaram;
3. o fluxo foi exercitado em iPhone físico quando depende de rede, ciclo de vida ou permissões;
4. estados de erro, cancelamento e inconclusivo estão acessíveis e compreensíveis;
5. nenhum segredo, endpoint interno ou mock será empacotado como release; AdMob, UMP e IDs de anúncio não fazem parte do binário MVP1.

## 5. TestFlight — beta controlada

TestFlight é o canal de validação do binário de distribuição. O build enviado é assinado para distribuição e deve ser tratado como um candidato real à produção, mesmo quando ainda tiver funcionalidade incompleta.

Apple processa o build antes que ele apareça no App Store Connect. Builds do TestFlight têm validade máxima de 90 dias; testers internos e externos são grupos diferentes, e testes externos podem exigir Beta App Review. [Visão geral do TestFlight](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/)

### 5.1 Sequência

```text
Archive Release
  → validação local do archive
  → upload ao App Store Connect
  → processamento da Apple
  → TestFlight interno
  → correção ou aceite
  → TestFlight externo, se necessário
  → release candidate aprovado
```

### 5.2 Regras de upload

- Somente Rian prepara o archive; Marco autoriza o envio quando o gate de beta estiver atendido.
- O build é enviado com versão, build, notas de teste e foco de validação claros.
- Primeiro passa por grupo interno. Grupo externo só recebe build que já teve o fluxo principal validado internamente.
- Teste externo é uma decisão de produto: público, objetivo, idiomas, instruções e canal de feedback precisam ser definidos antes do convite.
- Quando houver TestFlight externo, as informações de teste e qualquer revisão beta exigida pela Apple devem estar completas. Não se promete uma data de disponibilidade antes da aprovação/processamento efetivo.
- Feedback que revela erro de resultado de rede, privacidade, bloqueio do fluxo ou incompatibilidade em iPhone vira prioridade de correção. Sugestão de melhoria entra no próximo recorte, salvo decisão explícita de escopo.

### 5.3 Gate de TestFlight

Para um build ser aceito como release candidate, a evidência deve cobrir:

- Quick Check em iPhone físico, pelo menos em Wi-Fi e rede celular;
- cancelamento correto por troca de rede, ida a background e ação da pessoa;
- Deep Check em Wi-Fi, incluindo carga concluída, carga interrompida e resultado sem dados suficientes;
- catálogo assinado, cache e catálogo-base funcionando em cenários de falha;
- persistência e exclusão de histórico conforme a regra da V1;
- PT-BR e inglês, Dynamic Type e VoiceOver nos fluxos alterados;
- validação explícita de que as limitações são comunicadas como estimativa quando a medição não é do dispositivo/jogo real.

Rian registra a evidência técnica, Iury aprova qualquer alteração que afete a leitura de rede, Renan aprova experiência e acessibilidade afetadas, e Marco decide se o build segue ou volta para correção.

## 6. Produção — App Store

Produção é uma publicação deliberada. O build selecionado deve ser o release candidate aprovado no TestFlight, sem recompilação surpresa. Se qualquer código ou configuração mudar, nasce um novo build e ele volta pelo fluxo de TestFlight.

### 6.1 Preparação

Antes de submeter para App Review, Marco confirma:

1. versão e build finais registrados;
2. build correto selecionado no App Store Connect;
3. metadados, descrição, suporte, política de privacidade, classificação etária, países e screenshots revisados;
4. informações de privacidade coerentes com o binário, sem declarar publicidade inexistente no MVP1;
5. credenciais, instruções e contato de App Review disponíveis se forem necessários;
6. plano de suporte e resposta a problema crítico definido;
7. autorização explícita do dono do produto para a submissão.

No App Store Connect, a versão precisa estar completa, com o build correto associado, antes de ser adicionada e submetida para revisão. [Como submeter uma versão](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app)

### 6.2 Publicação

Para a primeira versão pública e para alterações de risco, o padrão é **release manual após aprovação**. Assim, um build aprovado fica em `Pending Developer Release` até Marco e o dono do produto confirmarem a publicação.

Apple permite release automático, agendado ou manual; a escolha manual mantém a decisão final com o time. Após acionar a publicação, a disponibilidade pode levar algum tempo para se propagar na App Store. [Opções de release da versão](https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/select-an-app-store-version-release-option)

Depois de publicado, Marco registra a hora, versão/build, países, link da loja e estado observado. “Aprovado” não é reportado como “publicado” antes de a versão estar efetivamente disponível.

### 6.3 Monitoramento inicial

Nas primeiras 48 horas, o time acompanha:

- crashes e feedback de usuários no App Store Connect;
- falhas de medição e resultados inconclusivos reportados;
- comportamento do catálogo remoto e fallback;
- avaliações que indiquem problema recorrente de promessa ou compreensão.

O Nolaggy não coleta telemetria própria no MVP1. A observação usa dados agregados do App Store Connect e feedback voluntário, respeitando a documentação funcional.

## 7. Correção urgente e rollback

Uma correção urgente é aberta quando existe resultado de rede enganoso, risco de privacidade, bloqueio do fluxo principal ou crash relevante. Itens de monetização só entram nesse critério quando o MVP1.1 estiver formalmente em escopo.

| Estado do problema | Ação |
| --- | --- |
| Build ainda em Debug/TestFlight | interromper distribuição se necessário, corrigir, gerar novo build e repetir o gate aplicável |
| Versão em App Review | retirar/cancelar a submissão quando possível, corrigir e submeter novo build |
| Versão aprovada mas ainda em release manual | não publicar; corrigir antes de liberar |
| Versão já pública | conter com catálogo/configuração remota somente se isso for seguro e já previsto; preparar hotfix e passá-lo por TestFlight e App Review |

Não existe “desfazer o binário” publicado como se fosse um deploy web. Reverter código no repositório ajuda a preparar o hotfix, mas não retira a versão instalada dos aparelhos. Por isso, a contenção por catálogo só pode reduzir dano dentro das regras já aprovadas e nunca alterar silenciosamente o significado de um resultado histórico.

Hotfix aumenta `PATCH` e recebe novo build. Exemplo: `1.0.0 (120)` público com defeito → `1.0.1 (121)` para TestFlight e App Review. A urgência não elimina teste de regressão para o problema corrigido.

## 8. Preparação para GitHub no futuro — sem integração agora

Nenhum repositório, branch, Action, segredo, webhook ou automação será criado nesta etapa. O projeto só deixa o desenho preparado para integrar GitHub depois, sem mudar o fluxo acima.

Quando houver autorização, a integração deve adotar:

| Elemento futuro | Regra prevista |
| --- | --- |
| Branch principal | `main` representa o estado integrado e liberável; não recebe alteração direta sem revisão |
| Trabalho isolado | cada frente usa branch curta com escopo claro; merge só após revisão e validação correspondente |
| Pull request | descreve comportamento, documentos afetados, validações executadas e riscos; não afirma publicação sem prova externa |
| Tags | `vX.Y.Z` marca exatamente o commit da versão de produto liberada; o build correspondente fica registrado na release note |
| CI | em pull request: build, testes e lint; em tag de release: archive reproduzível e validações adicionais. Upload para Apple só existe com autorização explícita |
| Segredos | certificados, chaves do App Store Connect e assinatura de catálogo ficam em cofre de segredos; nunca em código, arquivo de configuração versionado ou log |
| Proteção | aprovação obrigatória, checks verdes e histórico auditável para `main` e tags de release |
| Releases | notas humanas, versão/build, link de TestFlight ou App Store quando existir e evidência real do estado de distribuição |

Automação futura acelera passos repetitivos; ela não substitui os gates de produto, a aprovação de submissão nem a confirmação de publicação.

## 9. Registro mínimo de cada release

Cada ida para TestFlight ou Produção deve registrar:

```text
Versão/build:       0.2.0 (57)
Canal:              TestFlight interno | TestFlight externo | Produção
Objetivo:           o que este build valida ou entrega
Escopo:             principais mudanças
Validações:         testes e aparelhos/rede usados
Pendências/riscos:  o que permanece conhecido
Decisão:            enviado | aceito | rejeitado | publicado
Responsáveis:       Marco / Renan / Rian / Iury, conforme o caso
```

Esse registro é a fonte de verdade sobre o release. Não se presume que uma versão está em produção porque um archive foi criado, um upload começou ou uma automação terminou.
