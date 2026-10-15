---
name: store-creative-studio
description: Produz e valida screenshots e criativos reais para Apple App Store e Google Play a partir de capturas do app, com composição PNG, manifesto e galeria local para aprovação.
---

# Nico — Store Creative Studio

Use esta skill para preparar artes de loja, melhorar criativos existentes ou
criar variantes de conversão. Ela complementa `renan-design`,
`aso-store-listing` e `store-conversion`; não redesenha a marca, não inventa
telas e não envia nada às lojas.

## Primeiro: prova visual, não ilustração de feature

1. Descubra o app e ferramentas: `python3 tools/nico_validate.py discover --root .`
   e `python3 .agents/skills/store-creative-studio/scripts/discover_capture_tools.py`.
2. Leia os tokens, ativos aprovados e a funcionalidade real. Para LagCheck,
   carregue `renan-design`; a arte não pode prometer ping de jogo, cura de lag
   ou diagnóstico causal sem evidência.
3. Prefira captura controlada: use `zsh capture-ios.sh` ou `zsh capture-android.sh`.
   Para macOS, `zsh capture-macos.sh` aceita a janela selecionada; escolha um
   perfil aprovado no App Store Connect antes de exportar para loja.
   Se ela não estiver disponível, use uma imagem fornecida com
   `source_evidence: manual_input`; isso mantém a pipeline funcional, mas o
   manifesto marcará revisão de fidelidade pendente.
   **Nunca reutilize uma captura de iOS/macOS para Google Play, nem uma de Android
   para App Store.** Todo item declara `source_platform`, e o validador bloqueia
   a combinação incompatível antes de renderizar.
4. Escreva uma narrativa curta: benefício → capacidade real → diferencial.
   Cada peça tem objetivo, mensagem, fonte, composição e hipótese de conversão.

## Produzir

Parta de `templates/manifest-appstore-iphone.json` ou
`templates/manifest-google-play.json`, adapte campos e execute:

```bash
python3 .agents/skills/store-creative-studio/scripts/nico_creative.py render --manifest caminho/manifest.json
python3 .agents/skills/store-creative-studio/scripts/nico_creative.py validate-manifest --manifest caminho/manifest.json
python3 .agents/skills/store-creative-studio/scripts/nico_creative.py gallery --manifest caminho/manifest.json --output caminho/preview/index.html
```

O compositor gera PNG RGB opaco, preserva proporção da captura e cria um
manifesto auditável. As dimensões de cada perfil estão em
`references/store-asset-specs.md`; confirme sempre o requisito atual no
console/documentação oficial antes do upload.

Exemplo de captura Android:

```bash
zsh .agents/skills/store-creative-studio/scripts/capture-android.sh \
  com.exemplo.app/.MainActivity source/tela-android.png emulator-5554
```

## Aprovação

Abra a galeria local e faça revisão visual: texto legível, composição sem corte
da interface, identidade aprovada, sem dados pessoais, sem UI inventada e sem
marcas/arte de terceiros não licenciadas. A saída é `ready_for_review`, nunca
`approved_by_store`. Publicar, subir assets, mudar metadados publicados ou
identidade aprovada requer ordem explícita do Luiz.
