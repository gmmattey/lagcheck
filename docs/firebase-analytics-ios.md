# Firebase Analytics no iOS

O Firebase registra o funil agregado do LagCheck. Ele não participa da medição, não recebe rota, IP, SSID, BSSID, amostras UDP, endereço de servidor, conta, IDFA ou identificador de hardware.

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

`first_open`, `session_start` e os demais eventos automáticos são do SDK. O app não duplica esses eventos. Cada sessão de diagnóstico já protege o desfecho com uma trava: concluído, inconclusivo ou cancelado sai uma única vez.

## Debug e testes

No Debug, a coleta começa desligada. Para validar um aparelho no DebugView, inclua estes argumentos no esquema **Nolaggy**:

```
-lagcheck-firebase-debug
-FIRDebugEnabled
```

Abra **Firebase Console → Analytics → DebugView** e execute seleção de jogo, início, conclusão, inconclusivo, cancelamento, resultado e reteste. Ao terminar, remova `-lagcheck-firebase-debug` e inicie uma vez com `-FIRDebugDisabled`.

No GA4, crie e ative o filtro de dados de tráfego de desenvolvedor antes de validar. DebugView mostra o dispositivo quase em tempo real, mas o filtro é o que impede o tráfego de desenvolvimento de aparecer nos relatórios e nas exportações. Testes unitários e de interface também ficam fora: a coleta é bloqueada por argumento de fixture ou ambiente XCTest.

## Excluir a instalação do proprietário

No aparelho publicado, abra uma vez:

```
lagcheck://internal/analytics?collection=off
```

A preferência fica somente no `UserDefaults` desse aparelho e bloqueia Firebase e Worker, inclusive após reiniciar. Para reativar a mesma instalação, abra:

```
lagcheck://internal/analytics?collection=on
```

O Firebase é configurado com coleta inicialmente desligada e recebe a preferência imediatamente na inicialização. Ainda assim, se a exclusão for acionada pela primeira vez depois de o app já ter sido aberto, nenhum SDK consegue desfazer qualquer evento que tenha saído antes dessa ação. Para uma prova local sem essa janela, inicie pelo Xcode com `-lagcheck-analytics-disabled` já configurado.

## Configuração manual no Firebase e na loja

No Firebase/GA4, registre como dimensões personalizadas os parâmetros `game_id`, `game_platform`, `network_type`, `region_id`, `result_class`, `inconclusive_reason` e `cancellation_reason`; registre `duration_seconds` como métrica. Isso permite montar aquisição, ativação, conclusão, desfechos e repetição sem dashboard próprio. D1, D7 e D30 vêm dos relatórios de retenção do GA4 quando houver volume.

Antes de enviar um archive, confronte o binário com a App Privacy no App Store Connect e com a política em `~/Projetos/web/landings/sites/lagcheck/`: Firebase Analytics adiciona coleta de dados de uso e identificadores conforme o SDK efetivamente distribuído. Mantenha o campo de rastreamento como não usado se não houver rastreamento entre apps/sites, e não declare ATT por causa do Analytics sozinho. UMP continua sendo o gate de consentimento dos anúncios; esta integração não altera AdMob, UMP ou os seus pedidos de anúncio.
