# LagCheck — Modo Pronto

O sistema parte do quase-preto do produto, usa Roxo Gamer para ação e foco, e reserva Coral Solar para atenção e exclusão.

```css
:root {
  --bg: oklch(0.158 0.011 260); /* #0B0D10 */
  --surface: oklch(0.205 0.012 260);
  --fg: oklch(0.955 0.006 260);
  --muted: oklch(0.675 0.014 260);
  --border: oklch(0.302 0.014 260);
  --accent: oklch(0.585 0.214 299); /* #7C3AED · Roxo Gamer */
  --attention: oklch(0.684 0.196 35); /* #FF5A36 · Coral Solar */
}
```

- Display: `ui-rounded, 'Arial Rounded MT Bold', system-ui, sans-serif`
- Corpo: `-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif`
- Mono: `ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace`

Regras observadas: fundo sólido e profundo; nenhuma superfície grande em formato de card; Roxo Gamer em CTAs, seleção, foco e progresso; Coral Solar apenas para atenção e ações destrutivas; verde reservado a resultado bom; ritmo amplo na área de decisão.
