# Firebase Analytics no Android

O Firebase mede o funil agregado do LagCheck Android. Ele não participa do Check e não recebe IP, SSID, BSSID, MAC, localização, endereço do destino, identificador de hardware ou amostras de rede.

## Eventos

| Evento | Parâmetros |
| --- | --- |
| `game_selected` | `game_id` |
| `lagcheck_started` | `game_id`, `game_platform`, `network_type`, `region_id` |
| `lagcheck_completed` | os quatro acima, `result_class`, `duration_seconds` |
| `lagcheck_inconclusive` | os quatro acima, `inconclusive_reason` |
| `lagcheck_cancelled` | os quatro acima, `cancellation_reason` |
| `result_viewed` | `game_id`, `game_platform`, `result_class` |
| `retest_started` | `game_id`, `game_platform` |

`first_open`, `session_start` e outros eventos automáticos pertencem ao SDK. O app não os reproduz. O Check só emite `lagcheck_started` quando a medição UDP vai começar e só emite um desfecho: concluído, inconclusivo ou cancelado.

## Variants e configuração

O arquivo versionado em `android/app/src/release/google-services.json` pertence ao projeto `lagcheck-analytics` e ao pacote `com.lagcheck.app`.

O Debug mantém `com.lagcheck.app.debug`, compila sem cadastro Firebase e fica com coleta desligada. O Gradle pula `processDebugGoogleServices`; não copie o JSON de produção para o Debug nem remova o sufixo `.debug`.

Para validar o DebugView sem segundo cadastro, instale o **Release** distribuído no teste interno e, num aparelho de teste que não esteja excluído da coleta, rode:

```sh
adb shell setprop debug.firebase.analytics.app com.lagcheck.app
adb shell am force-stop com.lagcheck.app
```

Abra o app, execute o caminho desejado e confira o Firebase Console → Analytics → DebugView. Antes, ative no GA4 o filtro de tráfego de desenvolvedor. Ao terminar, desligue o modo:

```sh
adb shell setprop debug.firebase.analytics.app .none.
adb shell am force-stop com.lagcheck.app
```

O DebugView não é prova de produção, e este repositório ainda não tem evidência dele em aparelho físico.

## Excluir a instalação do proprietário

Em Ajustes, desligue **Compartilhar dados de uso**. A escolha fica só naquele aparelho, persiste após reiniciar e bloqueia os eventos automáticos e os eventos de produto antes que o app libere a coleta na próxima abertura. Para voltar a participar, ligue a chave manualmente no mesmo lugar.

Não há deep link, parâmetro externo ou login capaz de reativar a coleta. Essa escolha não controla AdMob: anúncios e UMP continuam com o próprio consentimento. A primeira instalação ainda pode registrar dados somente se a pessoa mantiver a chave ligada; desligar depois não apaga eventos já aceitos pelo Firebase.

## Console, privacidade e distribuição

No GA4, registre como dimensões personalizadas `game_id`, `game_platform`, `network_type`, `region_id`, `result_class`, `inconclusive_reason` e `cancellation_reason`. Registre `duration_seconds` como métrica. A partir disso, os relatórios do GA4 mostram ativação, repetição e retenção D1/D7/D30 sem dashboard próprio.

Antes de publicar outro AAB, confira o binário real contra a Segurança de Dados da Play, a política em `~/Projetos/web/landings/sites/lagcheck/` e a declaração do AdMob. Firebase Analytics não habilita personalização de anúncios nesta integração: a coleta de Advertising ID e o sinal padrão de personalização estão desligados. A obrigação de consentimento por região precisa ser revisada com a política publicada e a configuração final do GA4/AdMob; o UMP existente segue sendo o gate dos anúncios, não do Firebase.

## Checklist do teste interno

1. Gere o AAB Release sem assinatura quando não houver chave local: `./gradlew :app:bundleRelease`.
2. Instale ou envie somente após revisar o package `com.lagcheck.app` e a declaração de dados.
3. Em aparelho físico, valide seleção, início real, conclusão, inconclusivo, interrupção por segundo plano/troca de rede, cancelamento e reteste.
4. Confirme no DebugView cada evento e os parâmetros, com o filtro de desenvolvedor ativo.
5. Desligue a coleta em uma instalação do proprietário, encerre e abra o app; confirme que não surgem novos eventos desse aparelho.
