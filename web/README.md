# Lagcheck — Site Oficial e Landing Page de Alta Performance

Este diretório contém o site oficial do **Lagcheck**, concebido sob a direção estética **Dark Competitive UI** (Decisões 51, 52 e 53) e estruturado com base no benchmark de mercado do **NoPing**:
1. **Landing Page de Alta Conversão (`/`):** Hero gamer de alto impacto, simulador interativo de rota e prontidão, comparativo técnico, catálogo de jogos e SEO avançado.
2. **Página de Suporte (`/support`):** Central de ajuda e resolução de problemas conforme requisitos da Apple App Store.
3. **Política de Privacidade (`/privacy`):** Termos de privacidade transparentes em total conformidade com o app (SwiftData local, sem contas, sem telemetria intrusiva).

---

## Estrutura de Arquivos

```
web/
├── assets/
│   ├── brand/                    # Cópias 1:1 dos ativos oficiais em design-system/assets/brand/
│   │   ├── app-icon-source.svg
│   │   ├── lockup-thumbnail.svg
│   │   ├── symbol-compact.svg
│   │   ├── wordmark-mono-dark.svg
│   │   ├── wordmark-mono-light.svg
│   │   └── wordmark-primary.svg
│   └── games/                    # Artes dos títulos competitivos em assets/games/
├── css/
│   └── style.css                 # Dark Competitive UI, animações de pulso e tokens oficiais
├── js/
│   └── main.js                   # Controle bilíngue (PT/EN) e simulador interativo de rota
├── index.html                    # Site oficial gamer inspirado no NoPing com SEO completo
├── support.html                  # Central de suporte e resolução de problemas
├── support/
│   └── index.html                # Rota direta /support/ para servidores estáticos
├── privacy.html                  # Política de privacidade completa em conformidade com o app
├── privacy/
│   └── index.html                # Rota direta /privacy/ para servidores estáticos
├── robots.txt                    # Diretrizes para indexação de motores de busca
├── sitemap.xml                   # Mapa do site com hreflang para SEO internacional
├── validate.js                   # Suite de testes com 81 validações automatizadas
└── README.md                     # Este guia de execução e contexto
```

---

## Como Rodar Localmente

O site é 100% estático e não requer build complexo ou dependências de terceiros (HTML, CSS e JavaScript puros).

### Opção 1: Usando Python 3 (Nativo no macOS)

A partir da raiz do repositório:
```bash
python3 -m http.server 8080 --directory web
```
Em seguida, abra seu navegador em:
- Home: [http://localhost:8080/](http://localhost:8080/)
- Suporte: [http://localhost:8080/support.html](http://localhost:8080/support.html) ou [http://localhost:8080/support/](http://localhost:8080/support/)
- Privacidade: [http://localhost:8080/privacy.html](http://localhost:8080/privacy.html) ou [http://localhost:8080/privacy/](http://localhost:8080/privacy/)

### Opção 2: Usando Node.js (Servidor Local ou npx)

Executar com `npx serve`:
```bash
npx serve web
```
Ou com servidor de validação nativo integrado:
```bash
node web/validate.js
```

---

## Como Executar a Validação Automatizada

Para verificar a integridade dos arquivos, paridade dos ativos SVG com `design-system/assets/brand/`, conferência de tokens de design system, requisitos de negócio e resposta HTTP 200 em todas as rotas:

```bash
node web/validate.js
```

O script testará:
1. Existência e integridade de todos os arquivos obrigatórios (incluindo `robots.txt` e `sitemap.xml`).
2. Comparação byte-a-byte dos ativos vetoriais da marca.
3. Uso estrito dos tokens de cor e layout de `design-system/tokens/`.
4. Paridade de blocos bilíngues (PT-BR e EN).
5. Conformidade com todas as regras de privacidade (SwiftData, 90 dias, 100 registros, ausência de AdMob/UMP nesta entrega, compromisso de revisão futura).
6. Conformidade com regras de suporte (contato provisório visível, produto iPhone iOS 17+, explicação de rota vs ping de servidor de jogo).
7. Subida de servidor HTTP local temporário e teste de 200 OK em todas as rotas (incluindo SEO).

---

## Diretrizes de Marca e Design

- **Marca:** Lagcheck.
- **Wordmark:** `lagcheck` em minúsculas (Dual-Node Vector + Kinetic Speed Slant).
- **Estética:** Dark Competitive UI (fundo `#0B0D10`, superfícies grafite `#15181E`/`#1E232B`, bordas finas de 1px e Coral Solar `#FF5A36` de ação).
- **Acessibilidade:**
  - Contraste WCAG AAA/AA em todas as superfícies.
  - Alvos de toque com área mínima de 44x44 pt.
  - Foco visível (`:focus-visible`) com anel Coral Solar.
  - Skip link acessível no topo de cada página.
  - Respeito à preferência de sistema `prefers-reduced-motion`.

---

## Suposições e Decisões Tomadas

1. **Contato de Suporte:** O canal de suporte oficial definido é `suporte@signallq.com`, com alertas de canal de atendimento direto para conformidade com a App Store.
2. **Rotas e Compatibilidade Estática:** Para máxima compatibilidade com qualquer servidor estático (GitHub Pages, Cloudflare Pages, Nginx ou `file://`), as páginas estão disponíveis tanto como `support.html` / `privacy.html` quanto em subpastas com `index.html` (`support/index.html` e `privacy/index.html`).
3. **Isolamento Absoluto:** Todo o código do site está restrito ao diretório `web/`. O código do app iOS (`Sources/`, `Tests/`, `Lagcheck.xcodeproj`), o Worker (`worker/`) e as documentações existentes (`docs/`) foram preservados intactos.
