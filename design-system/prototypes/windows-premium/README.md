# Lagcheck para Windows: Protótipo Visual de Referência (Desktop UI)

Protótipo navegável em HTML único autocontido. **É especificação visual e de comportamento 1:1, adaptado ao sistema visual oficial do Lagcheck Web DS (`DESIGN.md`).** O app Windows nativo é o protótipo interno em Compose Desktop em `android/desktop/` (Decisões 114, 115 e 116 de `docs/DECISOES.md`; especificação em `docs/09-design-system-windows.md`).

## Como Executar Localmente para Revisão Visual

```bash
cd design-system/prototypes/windows-premium
python3 -m http.server 5200
# Abrir no navegador: http://127.0.0.1:5200/index.html
```

## O que Há Nesta Atualização

1. **Identidade Oficial Atualizada:**
   - Wordmark canônica oficial em `assets/wordmark-primary.svg` (SVG canônico 1420×290, 19 KB, sem alterações);
   - Símbolo oficial em `assets/lagcheck-mark.svg` (440×280, 2.9 KB) usado na barra de título nativa e como ícone do app;
   - Fontes auto-hospedadas WOFF2: **Barlow** (400, 500) para corpo, **Barlow Semi Condensed** (700, 800) para títulos/vereditos, **Chakra Petch** (600, tabular-nums) para telemetria numérica, e Cascadia Mono para dados técnicos.

2. **Tokens Canônicos (DESIGN.md):**
   - Fundos: `--stage` (`#060709`), `--deep` (`#0B0D10`), `--surface` (`#15181E`), `--panel` (`#1E232B`);
   - Linhas e hairlines: `--line` (`rgba(244, 245, 247, 0.10)`), `--line-strong` (`rgba(244, 245, 247, 0.16)`);
   - Textos: `--text-primary` (`#F4F5F7`), `--text-secondary` (`#8A93A0`), `--text-tertiary` (`#606873`);
   - Cores semânticas: `--purple` (`#7C3AED`, hover `#8B5CF6`, foco `#A78BFA`), `--ready` (`#22C55E`), `--caution` (`#F59E0B`), `--coral` (`#FF5A36`).

3. **Os 6 Estados Obrigatórios Prontos para Inspeção:**
   - Na barra de topo da página de teste há botões diretos para alternar entre:
     - **1. Pronto (Lobby):** Seletor de jogos do PC, estado do último check em faixa contínua, CTA primário de 56 px;
     - **2. Medindo:** Trilha de etapas (Conexão → Latência → Sob carga → Análise), mapa plano sem glow com sondas reais, telemetria ao vivo, barra lateral travada e botão "Cancelar";
     - **3. Resultado Bom:** `● Pronto para Ranked` (verde), métricas de repouso, jitter, sob carga e perda UDP, rota técnica até AWS sa-east-1, achado e recomendação prática;
     - **4. Resultado Instável:** `▲ Condições instáveis` (âmbar), destaque de oscilação sob carga e jitter alto, recomendação para usar cabo de rede;
     - **5. Inconclusivo / Indisponível:** `— Leitura inconclusiva` (cinza neutro), explicando com honestidade que faltaram respostas sem inventar notas;
     - **6. Erro de Rede:** `▲ Falha na medição` (coral), timeout de rede, diagnóstico e retry claro.

4. **Diretrizes de Acessibilidade e Desktop:**
   - Contraste WCAG AA;
   - Anel de foco visível (`3px solid #A78BFA` com offset de 3px);
   - Atalhos de teclado nativos: `Ctrl+1` (Início), `Ctrl+2` (Jogos), `Ctrl+3` (Histórico), `Ctrl+4` (Ajustes), `Esc` (Cancelar teste);
   - Suporte completo a "Reduzir movimento" (`prefers-reduced-motion` e switch em Ajustes).
