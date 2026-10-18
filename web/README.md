# Lagcheck — Webpage Comercial Oficial & Hub de Jogos (App Store Live)

Este diretório contém a webpage estática oficial e de alta performance do **Lagcheck** ([lagcheck.signallq.com](https://lagcheck.signallq.com)), desenvolvida sob a direção estética **Dark Competitive UI** (Decisões 51, 64 e 66), integrada ao ecossistema **SignallQ** e focada em conversão para o aplicativo nativo de iPhone publicado na Apple App Store.

---

## 1. Estrutura e Arquitetura

O site é gerado determinística e estaticamente pelo script `scripts/build_web.mjs`, garantindo consistência em SEO, metadados JSON-LD, rotas e acessibilidade:

```
web/
├── index.html                    # Homepage comercial de alta conversão
├── jogos/
│   ├── index.html                # Hub com busca interativa e filtros por categoria
│   ├── fortnite/index.html       # Guia e rota específica para Fortnite
│   ├── valorant/index.html       # Guia e rota específica para Valorant
│   ├── counter-strike-2/...      # Guia específico com infraestrutura Valve SDR
│   └── [demais 17 jogos]/        # Páginas com perfis de rede específicos
├── support/
│   └── index.html                # Central de suporte técnico (App Store Guidelines)
├── support.html                  # Fallback para servidores sem trailing slash
├── privacy/
│   └── index.html                # Política de privacidade transparente (SwiftData local, zero PII)
├── privacy.html                  # Fallback para servidores sem trailing slash
├── assets/
│   ├── brand/                    # Vetores e wordmark oficial
│   ├── games/                    # Artes dos 20 jogos (JPG original + WebP hero + WebP thumbnail)
│   ├── app-home.webp             # Screenshot da Home do app
│   ├── app-games.webp            # Screenshot da tela de Jogos
│   ├── app-result.webp           # Screenshot do Veredito
│   ├── linka-icon.png            # Ícone do app irmão Linka Speedtest
│   └── lagcheck-wordmark-light.svg # Wordmark oficial em minúsculas
├── robots.txt                    # Diretrizes para indexação
├── sitemap.xml                   # Mapa de URLs com 24 rotas indexáveis
├── vercel.json                   # Rewrites para Cloudflare Worker (/v1/*) e cabeçalhos de cache
└── validate.js                   # Suite de validação automatizada de SEO, rotas e HTTP 200
```

---

## 2. Jornada Comercial & CRO

1. **Hero & Download:**
   - Proposta de valor clara: *"Sua conexão está pronta para o ranked?"*
   - Subtítulo focado no benefício: interpretação de latência, jitter e perda de pacotes.
   - Botão oficial de download na App Store com badge Apple.
   - Micro-provas de confiança: Gratuito, para iPhone (iOS 17+), sem cadastro, diagnóstico em segundos.
2. **Demonstração do Resultado Real:**
   - Hierarquia em 5 níveis: Veredito semântico → Significado claro → Indicador de atenção → Orientação prática → Detalhes técnicos da rota.
   - CTA contextual: *"Fazer meu primeiro check"*.
3. **Como Funciona:**
   - 3 passos claros: Escolha o jogo → Envio de pacotes UDP reais (repouso + sob carga de bufferbloat) → Veredito direto.
4. **Catálogo Curado na Home & Hub `/jogos/`:**
   - 8 jogos populares destacados na Home e catálogo completo com 20 títulos em `/jogos/`.
   - Busca em tempo real e filtros por categoria (Battle Royale, FPS/Tático, MOBA, Outros).
5. **Speedtest Tradicional vs Lagcheck:**
   - Demonstração de por que velocidade em Mbps não resolve o lag em jogos.
6. **Transparência Técnica:**
   - Explicação factual sobre a rota UDP de referência até beacons AWS GameLift (sa-east-1) em São Paulo.
   - Callout específico para jogadores de PC e Console: o teste no iPhone diagnostica a rede doméstica e o enlace da operadora.
7. **Ecossistema SignallQ:**
   - Rodapé integrado com links para o ecossistema SignallQ, Linka Speedtest e SignallQ Android.

---

## 3. Performance & Otimizações de Mídia

- **Redução de Peso nas Artes:** As 20 imagens originais (~19 MB) receberam derivados WebP com redimensionamento responsivo:
  - Thumbnails (`*-thumb.webp`): 480×480 px (~35 KB por imagem, redução de **94.8%**).
  - Heroes (`*.webp`): Max 1280 px (~90 KB por imagem, redução de **84.2%**).
  - JPGs originais preservados para retrocompatibilidade.
- **Zero CLS:** Tags `<img>` com atributos `width` e `height` explícitos.
- **LCP Otimizado:** Imagens da primeira dobra com `fetchpriority="high"` e `loading="eager"`. Imagens abaixo da dobra com `loading="lazy"` e `decoding="async"`.
- **Animações Eficientes:** Remoção de polling de DOM (`setInterval`), adoção de `IntersectionObserver` pontual e suporte completo a `prefers-reduced-motion: reduce`.

---

## 4. Telemetria e Conversão

- **Visitas Anônimas:** `POST /v1/visit` ao carregar a página (zero PII, sem cookies).
- **Cliques da App Store:** `POST /v1/click` registra a intenção de instalação (`appstore_click`) com parâmetros UTM e página de origem.
- **Sem Falsos Leads:** Eliminado qualquer envio de e-mail fictício para a rota de waitlist. Cliques de download são contabilizados separadamente como intenção de conversão.

---

## 5. Como Gerar e Validar

### Gerar os arquivos estáticos:
```bash
node scripts/build_web.mjs
```

### Otimizar imagens dos jogos (se novos títulos forem adicionados):
```bash
python scripts/optimize_game_images.py
```

### Executar a suíte de testes de validação:
```bash
node web/validate.js
```

---

## 6. Conformidade e App Store Guidelines

- **Suporte:** Página `/support/` com canal direto `suporte@signallq.com` e esclarecimentos técnicos.
- **Privacidade:** Página `/privacy/` declara armazenamento local via SwiftData, telemetria própria mínima e banners AdMob/UMP nos placements autorizados, com dados de publicidade descritos sem confundir com a telemetria do LagCheck.
