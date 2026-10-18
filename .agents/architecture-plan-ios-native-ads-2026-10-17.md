# Architecture Plan — anúncios nativos no iOS (Decisão 95)

**Gate de Camillo: `can proceed with listed constraints`.** A Decisão 95 e o [Cartão de Missão](mission-card-ios-native-ads-2026-10-17.md) autorizam a implementação local. Este gate não autoriza distribuição; o aceite depende de build no Mac e prova em iPhone físico.

## Contrato e limites

- O app iOS completo (`Nolaggy`, iOS 17+) pode carregar um anúncio Native Advanced em cada uma das superfícies Home, Histórico, Jogos e Resultado. Widget, App Clip, Check, Detalhes e Configurações não recebem SDK, loader, solicitação ou slot. Configurações oferece somente a entrada de opções de privacidade quando o UMP exigir.
- O anúncio aparece como módulo separado no fluxo de rolagem, identificado como `Anúncio`/`Ad`, com assets, CTA e AdChoices sob controle do SDK. Jamais se confunde com conteúdo editorial, recomendação, score ou veredito. No Resultado, fica depois do veredito, métricas, explicação e ações essenciais. Um anúncio ausente não deixa lacuna e sua chegada não pode deslocar o foco ou esconder a ação principal.
- O SDK e o consentimento ficam na camada do app iOS. `NolaggyDomain`, `NolaggyApplication`, `NolaggyInfrastructure`, motor UDP, histórico, catálogo e Worker não importam tipos de anúncios nem recebem impressões, identificadores ou status de consentimento. Não há novo endpoint, mediação ou custo recorrente contratado.
- A flag de build de anúncios tem comportamento de falha segura: desligada, impede UMP, inicialização, loaders, requisições e espaço visual. Uma ausência de configuração válida também desliga solicitações; em Release deve **falhar o build** para impedir distribuir uma configuração incompleta.

## Configuração de build e dependências

- Vincular Google Mobile Ads e UMP exclusivamente ao target `Nolaggy` em `project.yml` e ao projeto gerado. Não incluir os pacotes nos targets `LagCheckWidget` e `LagCheckClip`. Fixar versões compatíveis e registrar a versão resolvida no projeto/lockfile. A geração do projeto e a resolução SPM precisam ser comprovadas no Mac.
- Debug usa o App ID de demonstração iOS do Google (`ca-app-pub-3940256099942544~1458002511`) e a unidade nativa de demonstração (`ca-app-pub-3940256099942544/3986624511`). Preview, UI test e desenvolvimento nunca fazem requisição às unidades reais. Dispositivos físicos de QA devem continuar configurados como dispositivos de teste quando forem usadas unidades próprias em qualquer teste posterior.
- Release usa o App ID iOS confirmado no AdMob em 17/10/2026, `ca-app-pub-5542349230926522~8215990145`, com unidades `ca-app-pub-5542349230926522/4055030074` (Home), `/4883886853` (Histórico), `/2936380361` (Jogos) e `/7813302529` (Resultado). Esses são identificadores de configuração, não segredos. Validar em build que Release não contenha App ID/unidade de demonstração, valores vazios nem mistura de apps; Debug não pode conter unidades reais. A leitura do AdMob também mostrou verificação do app não confirmada e aprovação que requer revisão: IDs existentes não comprovam entrega de anúncios.
- O `GADApplicationIdentifier` pertence ao `Info.plist` do app principal conforme configuração Debug/Release. Conferir `SKAdNetworkItems` pela documentação vigente do SDK e o produto real. Não acrescentar `NSUserTrackingUsageDescription` ou solicitar ATT por padrão sem decisão de rastreamento e revisão de privacidade; UMP e ATT têm finalidades distintas.

## Sequência e ciclo de vida

1. Em toda abertura do app, o coordenador de anúncios solicita atualização do estado UMP e apresenta o formulário se necessário. Se o SDK disser que opções de privacidade são obrigatórias, expõe a ação localizada em Configurações. Não inferir consentimento de cache próprio.
2. Inicialização e carga dependem de `canRequestAds` atualizado e da flag ligada. Centralizar o gate para evitar dupla inicialização ou pedidos duplicados quando os callbacks do UMP convergirem. Um erro de UMP não autoriza requisição por conta própria; obedecer o valor do SDK.
3. Cada superfície elegível solicita no máximo o que consegue apresentar, sem pré-carregar durante Check. Carregar fora do caminho crítico de navegação e de medição. Ao sair da tela, iniciar Check, ir ao background, revogar permissão ou desligar a flag, cancelar/descartar loader e anúncio e remover a view. No retorno ao foreground, rever o gate antes de nova carga.
4. Renderizar com `NativeAdView` hospedada por `UIViewRepresentable`, registrando views de headline, media, ícone, corpo, CTA e AdChoices antes de associar o anúncio. O SDK mantém o toque e a atribuição; a UI não sobrepõe gestos próprios ao CTA/AdChoices. Cada anúncio pertence a um único container visível.

## Privacidade, segurança e distribuição

- Revisar `PrivacyInfo.xcprivacy`, política pública de privacidade, App Store App Privacy, mensagens UMP e requisitos regionais contra o comportamento efetivo e o manifesto do SDK. Separar claramente telemetria mínima do Worker dos dados tratados pelo AdMob. Não afirmar que a política pública ou o listing já estão atualizados por editar apenas o repositório.
- A integração fica fora do App Clip e Widget. Nenhuma amostra de rede, jogo, região, veredito, histórico ou identificador de telemetria é enviada ao SDK como segmentação. Não usar dados do Check para personalização.
- A existência dos IDs de produção em Release configura o binário local; não autoriza upload, TestFlight, App Store, publicação web, alteração de campanhas ou teste que gere impressões reais.

## Compatibilidade, rollback e evidência

- Não há migração de dados ou contrato de servidor. A flag permite rollback funcional sem requisitar anúncios; para rollback de privacidade no binário, remover SDK e configuração e gerar nova versão. O histórico local e o motor de medição ficam intactos.
- Testes de configuração: matriz Debug/Release × flag ligada/desligada × IDs válidos/ausentes, assegurando falha do build Release inválido. Testes de política com seams/fakes: UMP pendente, negado, permitido, erro, opções exigidas, carga bem sucedida/falha, navegação, background, entrada em Check e retorno. Sem mudar vetores de score/veredito.
- No Mac: gerar projeto, resolver dependências, compilar Debug e Release e executar testes iOS. Em simulador: quatro superfícies, ausência nas excluídas, rótulo/AdChoices/CTA, PT-BR/inglês e Dynamic Type. Em iPhone físico: UMP por região e mudança de escolha, carga/falha, AdChoices, CTA, VoiceOver, foco, rolagem, navegação, Check e retorno do background. Breno registra aparelho, iOS, build e ambiente. Renan revisa hierarquia visual e acessibilidade. Camillo verifica aderência a este plano antes do aceite de Giam.
- Até essas provas e a revisão de privacidade/loja, o status é **implementação local**, não validado para distribuição.

## Referências externas verificadas

- [Configuração do Google Mobile Ads para iOS](https://developers.google.com/admob/ios/quick-start): App ID, `Info.plist` e SKAdNetwork.
- [Consentimento UMP no iOS](https://developers.google.com/admob/ios/privacy): atualizar em toda abertura e usar `canRequestAds`.
- [Anúncios nativos no iOS](https://developers.google.com/admob/ios/native) e [renderização nativa](https://developers.google.com/admob/ios/native/advanced): IDs de teste no desenvolvimento, loader, assets e views do SDK.
