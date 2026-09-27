# Decisão 62 — Reconciliação Documental e Gate de TestFlight

- **Data:** 26 de setembro de 2026
- **Status:** registro de corte; candidato ainda não liberado para upload
- **Escopo:** iPhone, iOS 17+, versão `1.0.0`, build `1` local
- **Revisa:** `docs/01`, `03`, `06`, `36`, `45`, `50`, `55`, `56`, `57`, `60`, checklist de lançamento e política de privacidade

## Fonte de verdade deste corte

O binário não inclui o Atalho composto de contexto de rede da decisão 59. A decisão 60 é a regra vigente para esse assunto. Os App Intents nativos que apenas iniciam uma medição, abrem Dados da Rede ou devolvem a telemetria que o próprio app observa continuam registrados; eles não importam dados externos nem confirmam frequência Wi-Fi.

O Cockpit só pode mostrar frequência Wi-Fi como **não confirmada** enquanto o iOS não fornecer a evidência por API pública. SSID, nome da rede, RTT, jitter, perda e ausência de dado não são evidência de 2,4 GHz, 5 GHz ou 6 GHz.

## Privacidade e declaração de loja

O binário atual envia ao Worker autorizado `POST /v1/telemetry` um UUID aleatório persistente por instalação e eventos mínimos (`app_open`, `check_started`, `verdict_viewed`, `retest_started`), com jogo, plataforma e veredito quando aplicável. Não envia IP, SSID, BSSID, métricas brutas, endereço de gateway, conta, IDFA ou localização.

O UUID permite medir retorno da mesma instalação e é indexado pelo serviço de analytics do Worker; portanto a política pública e a resposta de App Privacy no App Store Connect não podem afirmar “sem telemetria própria” ou “nenhum dado transmitido”. A resposta de App Privacy deve ser preenchida contra o archive final e as práticas efetivas do Worker, incluindo a transmissão opcional ao Gemini prevista na decisão 45 quando a ação de dicas estiver habilitada.

## Evidência local obtida neste corte

| Evidência | Resultado |
| --- | --- |
| Testes unitários no simulador iPhone 17 Pro | 63 testes aprovados |
| Build Release genérico iOS, sem assinatura | aprovado |
| Extração de metadados dos App Intents no Release | aprovada; não contém importação de contexto por Atalho |
| iPhone físico, TestFlight e App Store Connect | não executados neste corte |

## Bloqueios antes de upload ao TestFlight

1. Revisão de Iury da regra de frequência e remoção das referências legadas que tratam SSID como prova de banda.
2. Validação em iPhone físico dos cenários de rede, cancelamento/background, consentimento móvel, VoiceOver e Dynamic Type descritos em `docs/06` e no checklist.
3. Publicação e verificação externa das URLs de suporte e privacidade antes de incluí-las em metadados ou archive candidato.
4. Preenchimento revisado de App Privacy, App Review Notes, classificação etária e export compliance no App Store Connect pelo titular autorizado.
5. **Resolvido neste corte:** o dono do produto reconfirmou a inclusão de `/v1/waitlist`, KV e Analytics Engine exclusivamente para a captura de convites. A publicação do Worker continua dependente da validação de Iury; o endpoint não amplia telemetria do app nem autoriza outras coletas.
6. Confirmar o archive depois da correção de identidade: a inspeção inicial do Release encontrou `CFBundleDisplayName = LagCheck`, mas `CFBundleName = Nolaggy` e versão `1.0` por valores explícitos no `Info.plist`. O arquivo foi alinhado a `LagCheck` e `MARKETING_VERSION`; o Release precisa ser reconstruído antes de qualquer archive.

Enquanto qualquer item acima estiver aberto, o estado correto é **pronto para continuação de validação local**, não “pronto para TestFlight” nem “enviado”.
