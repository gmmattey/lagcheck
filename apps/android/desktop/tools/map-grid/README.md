# Ferramenta de Grade do Mapa (Map Grid) — LagCheck Desktop

Esta pasta contém o gerador e a documentação da grade de pontos do mapa-múndi (*dot-matrix*) utilizada pelo componente `RouteMap` no Compose Desktop (`com.lagcheck.desktop.ui.map`).

## Especificação Técnica da Grade

- **Projeção:** Cilíndrica Equiretangular recortada (*Plate Carrée* recortada).
- **Limites Geográficos:**
  - Longitude: `-180.0°` a `+180.0°`
  - Latitude superior (`latTop`): `+84.0°`
  - Latitude inferior (`latBottom`): `-58.0°`
  - Passo angular (`step`): `1.5°`
- **Dimensões da Matriz:**
  - Colunas: `360 / 1.5 = 240`
  - Linhas: `(84 - (-58)) / 1.5 = 94.67 → 95`
  - Total de células: `240 × 95 = 22.800`
- **Pontos de Terra Ativos (`1`):** `6.858` pontos.
- **Fonte Canônica dos Dados:** *Natural Earth 110m* (via `world-atlas / land-110m.json`, domínio público).

## Arquivos e Destino

- **Script gerador:** `generate-grid.mjs`
- **Recurso empacotado no app:** `android/desktop/src/main/resources/map/map-grid.json`

## Como Regenerar / Atualizar

Sem necessidade de dependências de rede externas (utilizando o extrator offline do protótipo canônico):

```bash
node android/desktop/tools/map-grid/generate-grid.mjs
```

Se for regenerar a partir do shapefile bruto Natural Earth (requer Node com `d3-geo` e `topojson-client`):
Consulte o script de referência em `design-system/prototypes/windows-premium/build-map.mjs`.
