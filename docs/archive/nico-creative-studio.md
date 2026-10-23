# Nico — operação de criativos de loja

Nico recebe uma captura real ou fornecida, constrói uma composição PNG opaca,
valida o perfil técnico e monta uma galeria estática para aprovação. Os scripts
ficam em `.agents/skills/store-creative-studio/scripts/`; nada usa API de loja,
credencial ou serviço pago.

## Fluxo

1. Descubra plataformas, design system e ferramentas de captura.
2. Capture uma tela controlada do app ou receba uma imagem manual.
3. Crie um manifesto por loja, locale, perfil e variante.
4. Renderize e valide os PNGs.
5. Inspecione a galeria visualmente antes de aprovar internamente.

```bash
python3 .agents/skills/store-creative-studio/scripts/discover_capture_tools.py
zsh .agents/skills/store-creative-studio/scripts/capture-ios.sh <udid> <bundle-id> source/tela.png -ui-fixture-valid-result
zsh .agents/skills/store-creative-studio/scripts/capture-android.sh <package/activity> source/tela-android.png [adb-serial]
zsh .agents/skills/store-creative-studio/scripts/capture-macos.sh source/tela-mac.png <window-id>
python3 .agents/skills/store-creative-studio/scripts/nico_creative.py render --manifest manifest.json
python3 .agents/skills/store-creative-studio/scripts/nico_creative.py validate-manifest --manifest manifest.json
python3 .agents/skills/store-creative-studio/scripts/nico_creative.py gallery --manifest manifest.json --output previews/index.html
```

Cada registro de tela traz narrativa, hipótese, fonte e evidência da captura.
`manual_input` mantém a peça válida como composição, mas exige confirmar que a
tela corresponde ao build candidato antes do envio. `simulator_capture` e
`emulator_capture` documentam o cenário controlado, não uma medição real nem
prova de aprovação na loja.

## Separação por plataforma

Uma peça de App Store exige `source_platform: "ios"`; uma peça de Google Play
exige `source_platform: "android"`. O validador rejeita a mistura, inclusive
quando a captura parece visualmente parecida. No LagCheck isso é essencial:
o Android tem navegação e composição próprias (quatro abas e Home específica),
portanto uma captura iOS só pode existir no pacote iOS. Sem emulador/dispositivo
Android disponível, não se cria pacote de Google Play: aguarda-se a captura
Android ou uma imagem manual identificada como Android e revisada contra o build.

As especificações de Apple e Google mudam; o mapa local em
[`store-asset-specs.md`](../.agents/skills/store-creative-studio/references/store-asset-specs.md)
é um guardrail baseado em fontes oficiais, não autorização para upload.
