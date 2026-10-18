# Referência versionada — Resultado e Detalhes iOS com hierarquia Android

**Versão:** v1 · 17 de outubro de 2026
**Status:** handoff visual versionado para implementação. Não é runtime, screenshot de simulador ou evidência de aparelho físico.

## Objetivo

Esta referência fecha Resultado e Detalhes da jornada iOS atual: Deep Check,
`CheckCompletoResultView` e `TechnicalDetailsView`. Usa `VerdictScreen` e
`TechnicalDetailsScreen` Android como referência de hierarquia e acabamento:
decisão primeiro, telemetria compacta e evidência observada antes de qualquer
interpretação. O mock também preserva Resultado para o `QuickCheck` legado se
ele for reativado; hoje ele existe para fixture, mas não é a jornada normal.

O iOS mantém Safe Area, voltar/fechar, apresentação modal, foco VoiceOver,
gesto de dispensar e share sheet nativos. Esta é uma referência de handoff
visual, não runtime, screenshot de simulador ou evidência de aparelho físico.

Não altera score, veredito, UDP, catálogo, persistência ou Worker.

## Resultado — composição fechada

1. Barra superior: voltar com alvo de 44 pt e contexto em monoespaçado.
2. Kicker, `VerdictIndicatorBadge` e manchete sem score nem glifo Unicode.
3. Uma frase curta e, somente no resultado conclusivo, a prévia do card local.
4. Telemetria inline, seguida de um único painel `O QUE MAIS PESOU`.
5. CTA Roxo Gamer `Testar novamente`, seguido de `Ver detalhes`.
6. Estados `ready`, `caution`, `notReady` e `inconclusive`.

### Ordem e proporção

| Faixa | Conteúdo | Regra visual |
| --- | --- | --- |
| Topo | Voltar 44 pt; `JOGO · PLATAFORMA · REGIÃO` | Contexto mono de 10–12 pt, alinhado à direita e truncado no meio apenas se necessário. |
| Decisão | `RESULTADO DO CHECK`, badge e manchete | Kicker mono 11 pt; badge próprio de 24 pt; headline rounded 34–38 pt. O score não entra aqui. |
| Leitura rápida | Uma frase e card local | Corpo 16 pt. No estado conclusivo, o card 1200×630 entra logo após a frase e antes da telemetria. |
| Telemetria | `P50 · jitter · perda` | Dados em mono 11–13 pt, todos derivados da mesma sessão UDP. |
| Evidência | `O QUE MAIS PESOU` | Um painel `surface`, borda de 1 px e uma causa observada. Sem lista de cartões. |
| Ações | Retestar, detalhes, utilitários | Primário roxo 56–62 pt; detalhes secundário; compartilhar/PDF só quando conclusivo. |

`ready` usa verde semântico; `caution` usa âmbar; `notReady` usa Coral Solar;
`inconclusive` usa neutro. Roxo fica reservado à ação, seleção e foco.

## Detalhes — composição fechada

Detalhes é a ampliação da mesma sessão, não uma segunda tela de veredito. O
score numérico pode aparecer aqui porque está subordinado à manchete que ficou
na tela anterior. A ordem replica o Android sem inventar dados que o iPhone
não mede.

| Ordem | Seção | Dados e comportamento iOS |
| --- | --- | --- |
| 1 | Cabeçalho | `Detalhes técnicos` e `Fechar`, ambos na barra segura com alvo de 44 pt. No iPhone, abrir em sheet de tela inteira/large detent com `NavigationStack`; `Fechar` dispensa. Não usar navegação Android ou botão de sistema Android. |
| 2 | Resumo | Badge, rótulo do veredito, `JOGO · REGIÃO · DATA/HORA` em um painel compacto. Não repetir headline gigante. |
| 3 | Score e métricas | `SCORE` 0–100 e grade 2×2: `P50`, `JITTER`, `PERDA`, `P99`. Valores mono; `—` para fato ausente. Nunca transformar zero de dados em `0`. |
| 4 | `LATÊNCIA DURANTE O CHECK` | Gráfico temporal com repouso à esquerda e sob carga à direita somente quando houver amostras temporais reais para cada fase. Grade de 1 px, linha verde para traçado e ponto Coral somente para pico realmente observado. Legenda mono. Percentis agregados não geram uma curva. Sem série suficiente: mensagem curta `Sem amostras suficientes para o gráfico`, sem curva inventada. |
| 5 | `ORIGEM DA EVIDÊNCIA` | Dois registros: `Enlace local` e `Rota externa`. A rota mostra somente destino regional de referência e efeito medido. Enlace local usa `Não observável` sem probe isolado; com `GatewayProbeOutcome` real, pode mostrar estado e RTT/perda. |
| 6 | `O QUE ENCONTRAMOS` | Linhas separadas no mesmo painel: estabilidade, comportamento sob carga e destino medido. Dot segue severidade; detalhe curto, factual e localizável. |
| 7 | Nota técnica | Confiança e versão de regra em mono. É o fim da leitura técnica; recomendações só entram se tiverem evidência do domínio e couberem em uma frase curta. |

### Estados de Detalhes

| Estado de resultado | Detalhes permitidos |
| --- | --- |
| `ready`, `caution`, `notReady` | Mostra as sete seções quando os fatos correspondentes existirem. Carga, gráfico e achados se adaptam à sessão, nunca a um valor padrão. |
| `inconclusive` | Cabeçalho, contexto e motivo curto. Não mostra score, causa, gráfico, recomendação, compartilhamento ou PDF. Métricas disponíveis ficam `—`; o CTA volta ao Resultado para retestar. |
| Cancelado / rede mudou | Não abre Detalhes para a sessão descartada. Mostrar motivo terminal fora do Resultado e `Testar novamente`. |
| Falta de permissão/fato opcional | Não bloqueia o veredito. O registro específico diz `Não observável`; os demais fatos continuam. |
| Preparando/falha de card | Pertence ao Resultado, jamais bloqueia Detalhes. |

## Dados Android que ficam fora do iOS

O layout de `ORIGEM DA EVIDÊNCIA` é compartilhado; a telemetria não é. iOS não
exibe nem infere banda 2.4/5/6 GHz, RSSI em dBm, velocidade PHY Tx/Rx, padrão
Wi-Fi, contadores RF ou o rótulo `Sinal bom`/`Sinal fraco` se ele depender
desses dados. Também não replica nav rail/back do Android, formatos visuais de
share Android ou sua navegação de sistema.

O iPhone pode exibir UDP observado: veredito/score válidos, P50/P95/P99,
jitter, perda, séries de repouso/carga, impacto de carga, região, data/hora,
confiança, versão de regra e achados da rota. Sem probe local isolado, a única
copy correta para enlace local é `Não observável`. A frase atribuída a
instabilidade local depende de `GatewayProbeOutcome` real e revisão do Iury;
a referência nunca transforma uma captura ou RSSI Android em fato iOS.

## Card compartilhável

O JPEG mede **1200×630**. A composição é arte editorial autorizada ou
miniatura neutra à esquerda, sob gradiente escuro; à direita entram wordmark
oficial, domínio, `CHECK · JOGO`, manchete, P50, jitter, perda e a declaração
`Medido com pacotes UDP reais.`

O arquivo só usa o snapshot válido que o originou. Não é criado para resultado
inconclusivo, cancelado ou troca de rede. Quando uma métrica não existe, usa
`—`; ausência de P50 ou jitter impede a geração.

## Estados complementares de implementação

| Estado | Regra visual e interação |
| --- | --- |
| Preparando card | Reserva a razão 1200:630 com superfície e borda; não usa spinner, shimmer ou pulso. |
| Card pronto | Miniatura abre o share sheet iOS com o mesmo arquivo já preparado. |
| Falha do card | Resultado permanece; exibe `Falha ao preparar o card` e alvo separado `Preparar card novamente`. |
| Cancelado / rede mudou | É estado terminal fora desta tela de veredito: motivo curto + retestar; descarta leitura parcial. |
| Permissão sem fato opcional | Não bloqueia Check; omite somente o fato não observado. |

## Acessibilidade e validação pendente

- Ordem VoiceOver Resultado: contexto, veredito, frase, telemetria, achado,
  ações, share. Em Detalhes: título, resumo, score, cada métrica, resumo do
  gráfico, origem, achados e nota técnica.
- Todo controle tem mínimo 44×44 pt; após cancelar o share sheet, o foco volta à
  miniatura ou ícone que o abriu.
- AX1–AX5 pode quebrar contexto e telemetria em linhas; manchete e CTAs não
  truncam nem usam `minimumScaleFactor`. A grade pode virar uma coluna sem
  perder a ordem de leitura.
- O gráfico tem alternativa VoiceOver: `Repouso P50 …; carga P95 …; pico …`.
  A cor não é o único sinal de veredito ou pico.
- Reduzir Movimento não altera a leitura do estado e gráficos não dependem de
  animação para comunicar dados.
- Validar PT-BR e inglês, iPhone pequeno e grande, Dynamic Type, VoiceOver,
  contraste, sheet, share sheet, card real e estados de gráfico antes de
  aprovar QA visual.

## Fontes

- `docs/DECISOES.md`, Decisões 94 e 95.
- `docs/01-funcional.md`, seção 7.4.
- `android/app/src/main/kotlin/com/lagcheck/android/ui/verdict/VerdictScreen.kt`.
- `android/app/src/main/kotlin/com/lagcheck/android/ui/details/TechnicalDetailsScreen.kt`.
- `Sources/NolaggyApp/Features/Details/TechnicalDetailsView.swift`.
- `android/app/src/main/kotlin/com/lagcheck/android/share/ShareMediaRenderer.kt`.
- `design-system/tokens/colors.json`, `spacing.json` e `typography.json`.

`result-handoff.html` é um mock autocontido para revisão estática. Ele não
substitui `ios-reference/source/`, que permanece intacto como registro legado.
