# lagcheck para Windows: protótipo visual (referência)

Protótipo navegável em HTML único. **É especificação visual e de comportamento, não código de produto.** O app Windows de verdade é o protótipo interno em Compose Desktop, `android/desktop/` (Decisões 114, 115 e 116 de `docs/DECISOES.md`; spec em `docs/09-design-system-windows.md`). Windows não é alvo oficial.

```bash
cd design-system/prototypes/windows-premium
python -m http.server 5200
# abrir http://127.0.0.1:5200/index.html
```

Telas: Início, Check (detecção de região e ping animado no mapa), Resultado (abre ao fim do check), Histórico e Ajustes. Os controles "Local" e "Cenário" no canto do mapa existem só no protótipo (simulam usuário em outra cidade e check estável, instável ou com perda). Os valores são simulados.

## Identidade

- Tokens do Android (`android/core/designsystem/src/main/kotlin/com/lagcheck/core/designsystem/theme/Color.kt`): fundo `#0B0D10`, Roxo Gamer `#7C3AED`, Coral, Âmbar, Verde, Cinza inconclusivo. Única derivação: `--accent-text #A78BFA`, tint do roxo para texto pequeno sobre fundo escuro.
- Fonte Google Sans Flex (corpo e títulos), mono do sistema (Cascadia Mono) para métricas. Arquivos em `assets/` (SIL OFL).
- Sem vidro, sem aurora, sem card por bloco: seções separadas por linha fina. Sem pills arredondadas: o estado é um marcador com barra lateral colorida. Sombra só no botão principal e no toast.
- Vereditos com os rótulos oficiais (`● Pronto para Ranked`, `▲ Condições instáveis`, `▲ Eu evitaria Ranked agora`, `— Inconclusivo`). A regra de veredito do protótipo é só ilustrativa; o app usa o `core`.
- Inspiração: tiles de módulo do Razer Synapse e a faixa de telemetria do app NVIDIA, sempre dentro da paleta e das formas do Android.

## Mapa de detecção e ping animado

Motor em JavaScript (`initCheck` em `index.html`), portado para Compose em `android/desktop/.../ui/map/`. Mapa de pontos gerado do Natural Earth 110m (domínio público) por `build-map.mjs`; sem biblioteca em tempo de execução, offline, cerca de 23 KB. Arco quadrático, pacote com rastro, ondas que acendem os pontos e câmera que enquadra a rota. **Pacotes só existem para sondas reais**; em repouso o mapa mostra só os pinos e o arco parado. "Reduzir movimento" remove pacotes e pulsos.

Os dois CodePens avaliados (puki10 e mushigh) foram descartados: o primeiro é Vue 2 com um SVG sem projeção conhecida e licença não declarada; o segundo depende do Highcharts (pago para uso comercial) e de CDN. Aproveitamos só as ideias: zoom na região e modelo de latitude/longitude com linha e ponto.

## Limites conhecidos

- O protótipo usa projeção equiretangular e arco simples; no app, rotas que cruzam o Pacífico atravessam o mapa inteiro.
- Os milissegundos mostrados são os medidos; a duração da animação é expandida e o texto no mapa avisa isso.
- Localização do usuário: cidade aproximada pelo IP, só em memória e em cache local de 24 h, nunca GPS, nunca enviada (Decisão 116).
- WinUI 3 foi avaliado e **descartado**: contradiz a Decisão 114 (reuso do `core` do Android em Kotlin sem duplicar regra).
