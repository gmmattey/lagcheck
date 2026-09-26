import os
import subprocess

PROJECT_ROOT = "/Users/giammattey/Projetos/buildea/lagcheck"

# 1. Definir SVG do App Icon Source (1024x1024)
app_icon_svg = '''<svg viewBox="0 0 1024 1024" xmlns="http://www.w3.org/2000/svg" role="img" aria-labelledby="icon-title icon-desc">
  <title id="icon-title">LagCheck App Icon — Dual-Node Vector</title>
  <desc id="icon-desc">Ícone do aplicativo LagCheck: lâminas poligonais aerodinâmicas em Coral Solar representando envio e recepção de pacotes em rota competitiva sobre fundo quase preto.</desc>
  <defs>
    <!-- Fundo Quase Preto OLED (#0B0D10) com Gradiente Radial Profundo -->
    <radialGradient id="bg-grad" cx="50%" cy="40%" r="70%">
      <stop offset="0%" stop-color="#181B22" />
      <stop offset="50%" stop-color="#0E1015" />
      <stop offset="100%" stop-color="#07080A" />
    </radialGradient>

    <!-- Gradientes Faceta Externa / Iluminada (Âmbar Solar para Coral Vivo) -->
    <linearGradient id="facet-ext" x1="20%" y1="0%" x2="80%" y2="100%">
      <stop offset="0%" stop-color="#FFAB2E" />
      <stop offset="45%" stop-color="#FF6B35" />
      <stop offset="100%" stop-color="#FF3823" />
    </linearGradient>

    <!-- Gradientes Faceta Interna / Chiseled (Coral Solar Intenso para Carmim de Alta Densidade) -->
    <linearGradient id="facet-int" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#FF5A36" />
      <stop offset="60%" stop-color="#D93018" />
      <stop offset="100%" stop-color="#9E1808" />
    </linearGradient>

    <!-- Brilho Térmico / Halo Competitivo em Coral Solar -->
    <filter id="esports-glow" x="-25%" y="-25%" width="150%" height="150%">
      <feDropShadow dx="0" dy="24" stdDeviation="38" flood-color="#FF5A36" flood-opacity="0.4" />
      <feDropShadow dx="0" dy="8" stdDeviation="16" flood-color="#FFAB2E" flood-opacity="0.25" />
    </filter>

    <!-- Borda Hairline 1px com Brilho Sutil -->
    <linearGradient id="border-hairline" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="rgba(255, 255, 255, 0.16)" />
      <stop offset="50%" stop-color="rgba(255, 255, 255, 0.05)" />
      <stop offset="100%" stop-color="rgba(255, 255, 255, 0.02)" />
    </linearGradient>
  </defs>

  <!-- Fundo do Ícone (1024x1024) com Raio Apple 224pt -->
  <rect width="1024" height="1024" rx="224" fill="url(#bg-grad)" />
  <rect width="1024" height="1024" rx="224" fill="none" stroke="url(#border-hairline)" stroke-width="3" />

  <!-- Símbolo Central Dual-Node Vector -->
  <g transform="translate(512, 512)" filter="url(#esports-glow)">
    
    <!-- ==================== LÂMINA 1 (SUPERIOR) ==================== -->
    <g id="blade-upper">
      <!-- Faceta Externa / Crista Esquerda (Iluminada) -->
      <path d="M 0 -240
               L -200 130
               L -145 140
               L -125 100
               L 0 -130
               Z"
            fill="url(#facet-ext)" />

      <!-- Faceta Interna / Crista Direita (Chiseled Sombra) -->
      <path d="M 0 -240
               L 0 -130
               L 105 -25
               L 105 -85
               Z"
            fill="url(#facet-int)" />

      <!-- Ponta da Cauda Bipartida / Split Speed Tip -->
      <path d="M -200 130
               L -235 200
               L -180 145
               L -145 140
               Z"
            fill="url(#facet-ext)" />
      <path d="M -180 145
               L -155 220
               L -125 100
               Z"
            fill="url(#facet-int)" />
    </g>

    <!-- ==================== LÂMINA 2 (INFERIOR - ROTACIONADA 180°) ==================== -->
    <g id="blade-lower" transform="rotate(180)">
      <!-- Faceta Externa / Crista Esquerda (Iluminada) -->
      <path d="M 0 -240
               L -200 130
               L -145 140
               L -125 100
               L 0 -130
               Z"
            fill="url(#facet-ext)" />

      <!-- Faceta Interna / Crista Direita (Chiseled Sombra) -->
      <path d="M 0 -240
               L 0 -130
               L 105 -25
               L 105 -85
               Z"
            fill="url(#facet-int)" />

      <!-- Ponta da Cauda Bipartida / Split Speed Tip -->
      <path d="M -200 130
               L -235 200
               L -180 145
               L -145 140
               Z"
            fill="url(#facet-ext)" />
      <path d="M -180 145
               L -155 220
               L -125 100
               Z"
            fill="url(#facet-int)" />
    </g>

  </g>
</svg>
'''

# 2. Definir Símbolo Compacto (240x240)
symbol_compact_svg = '''<svg viewBox="0 0 240 240" xmlns="http://www.w3.org/2000/svg" role="img" aria-labelledby="sym-title sym-desc">
  <title id="sym-title">Símbolo LagCheck — Dual-Node Vector</title>
  <desc id="sym-desc">Símbolo compacto oficial do LagCheck: lâminas poligonais em Coral Solar representando envio e recepção de rota em alta velocidade.</desc>
  <defs>
    <linearGradient id="sym-facet-ext" x1="20%" y1="0%" x2="80%" y2="100%">
      <stop offset="0%" stop-color="#FFAB2E" />
      <stop offset="45%" stop-color="#FF6B35" />
      <stop offset="100%" stop-color="#FF3823" />
    </linearGradient>
    <linearGradient id="sym-facet-int" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#FF5A36" />
      <stop offset="60%" stop-color="#D93018" />
      <stop offset="100%" stop-color="#9E1808" />
    </linearGradient>
    <filter id="sym-glow" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="6" stdDeviation="10" flood-color="#FF5A36" flood-opacity="0.35" />
    </filter>
  </defs>

  <g transform="translate(120, 120) scale(0.42)" filter="url(#sym-glow)">
    <g id="blade-upper">
      <path d="M 0 -240 L -200 130 L -145 140 L -125 100 L 0 -130 Z" fill="url(#sym-facet-ext)" />
      <path d="M 0 -240 L 0 -130 L 105 -25 L 105 -85 Z" fill="url(#sym-facet-int)" />
      <path d="M -200 130 L -235 200 L -180 145 L -145 140 Z" fill="url(#sym-facet-ext)" />
      <path d="M -180 145 L -155 220 L -125 100 Z" fill="url(#sym-facet-int)" />
    </g>
    <g id="blade-lower" transform="rotate(180)">
      <path d="M 0 -240 L -200 130 L -145 140 L -125 100 L 0 -130 Z" fill="url(#sym-facet-ext)" />
      <path d="M 0 -240 L 0 -130 L 105 -25 L 105 -85 Z" fill="url(#sym-facet-int)" />
      <path d="M -200 130 L -235 200 L -180 145 L -145 140 Z" fill="url(#sym-facet-ext)" />
      <path d="M -180 145 L -155 220 L -125 100 Z" fill="url(#sym-facet-int)" />
    </g>
  </g>
</svg>
'''

# 3. Definir Wordmark Primary (Transparente, com lag branco e check Coral Solar)
wordmark_primary_svg = '''<svg viewBox="0 0 780 150" xmlns="http://www.w3.org/2000/svg" role="img" aria-labelledby="wm-title wm-desc">
  <title id="wm-title">LagCheck Wordmark — Dual-Node Vector &amp; Kinetic Speed Slant</title>
  <desc id="wm-desc">Wordmark horizontal oficial do LagCheck: símbolo Dual-Node Vector em Coral Solar e tipografia lagcheck com inclinação de velocidade e cortes chanfrados estilo NoPing.</desc>
  <defs>
    <linearGradient id="coral-wordmark-grad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#FFAB2E" />
      <stop offset="45%" stop-color="#FF5A36" />
      <stop offset="100%" stop-color="#FF3823" />
    </linearGradient>
    <linearGradient id="coral-wm-dark" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#FF5A36" />
      <stop offset="60%" stop-color="#D93018" />
      <stop offset="100%" stop-color="#9E1808" />
    </linearGradient>
    <filter id="wm-glow" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="4" stdDeviation="10" flood-color="#FF5A36" flood-opacity="0.35" />
    </filter>
  </defs>

  <!-- Símbolo Dual-Node Compacto à Esquerda -->
  <g transform="translate(85, 75) scale(0.25)" filter="url(#wm-glow)">
    <g>
      <path d="M 0 -240 L -200 130 L -145 140 L -125 100 L 0 -130 Z" fill="url(#coral-wordmark-grad)" />
      <path d="M 0 -240 L 0 -130 L 105 -25 L 105 -85 Z" fill="url(#coral-wm-dark)" />
      <path d="M -200 130 L -235 200 L -180 145 L -145 140 Z" fill="url(#coral-wordmark-grad)" />
      <path d="M -180 145 L -155 220 L -125 100 Z" fill="url(#coral-wm-dark)" />
    </g>
    <g transform="rotate(180)">
      <path d="M 0 -240 L -200 130 L -145 140 L -125 100 L 0 -130 Z" fill="url(#coral-wordmark-grad)" />
      <path d="M 0 -240 L 0 -130 L 105 -25 L 105 -85 Z" fill="url(#coral-wm-dark)" />
      <path d="M -200 130 L -235 200 L -180 145 L -145 140 Z" fill="url(#coral-wordmark-grad)" />
      <path d="M -180 145 L -155 220 L -125 100 Z" fill="url(#coral-wm-dark)" />
    </g>
  </g>

  <!-- Tipografia Kinetic Speed Slant com Skew -14deg -->
  <g transform="translate(180, 100) skewX(-14)">
    <!-- Parte 1: 'lag' em Branco Titânio -->
    <g fill="#F4F5F7" fill-rule="evenodd">
      <path d="M 0 0 L 0 -50 L 12 -62 L 22 -62 L 22 0 Z" />
      <g transform="translate(30, 0)">
        <path d="M 12 -46 L 40 -46 L 52 -34 L 52 0 L 34 0 L 34 -8 
                 L 12 -8 L 0 -20 L 0 -34 Z
                 M 18 -22 L 34 -22 L 34 -32 L 18 -32 Z" />
      </g>
      <g transform="translate(90, 0)">
        <path d="M 12 -46 L 40 -46 L 52 -34 L 52 10 L 40 22 L 8 22 L 8 10 L 34 10 L 34 0 
                 L 12 0 L 0 -12 L 0 -34 Z
                 M 18 -14 L 34 -14 L 34 -32 L 18 -32 Z" />
      </g>
    </g>

    <!-- Parte 2: 'check' em Coral Solar -->
    <g fill="url(#coral-wordmark-grad)" filter="url(#wm-glow)" fill-rule="evenodd">
      <g transform="translate(152, 0)">
        <path d="M 48 -34 L 36 -46 L 12 -46 L 0 -34 
                 L 0 -12 L 12 0 L 36 0 L 48 -12 
                 L 32 -12 L 26 -6 L 22 -6 L 16 -12 
                 L 16 -34 L 22 -40 L 26 -40 L 32 -34 Z" />
      </g>
      <g transform="translate(208, 0)">
        <path d="M 0 0 L 0 -50 L 12 -62 L 22 -62 L 22 -32 
                 L 32 -46 L 42 -46 L 52 -36 
                 L 52 0 L 32 0 L 32 -28 
                 L 26 -34 L 22 -34 L 22 0 Z" />
      </g>
      <g transform="translate(268, 0)">
        <path d="M 0 -34 L 12 -46 L 38 -46 L 50 -34 
                 L 50 -20 L 18 -20 L 18 -12 L 24 -6 L 36 -6 L 46 -14 L 46 0 
                 L 38 0 L 12 0 L 0 -12 Z
                 M 18 -32 L 32 -32 L 32 -26 L 18 -26 Z" />
      </g>
      <g transform="translate(326, 0)">
        <path d="M 48 -34 L 36 -46 L 12 -46 L 0 -34 
                 L 0 -12 L 12 0 L 36 0 L 48 -12 
                 L 32 -12 L 26 -6 L 22 -6 L 16 -12 
                 L 16 -34 L 22 -40 L 26 -40 L 32 -34 Z" />
      </g>
      <g transform="translate(382, 0)">
        <path d="M 0 0 L 0 -50 L 12 -62 L 22 -62 L 22 -24 
                 L 36 -46 L 58 -46 L 30 -18 
                 L 60 0 L 36 0 L 18 -16 L 22 0 Z" />
      </g>
    </g>
  </g>
</svg>
'''

# 4. Wordmark Monocromático Escuro (para fundos claros)
wordmark_mono_dark_svg = '''<svg viewBox="0 0 780 150" xmlns="http://www.w3.org/2000/svg" role="img" aria-labelledby="wm-dark-title wm-dark-desc">
  <title id="wm-dark-title">LagCheck Wordmark Monocromático Escuro</title>
  <desc id="wm-dark-desc">Wordmark LagCheck para superfícies claras em tinta escura sólida.</desc>
  <g transform="translate(85, 75) scale(0.25)" fill="#15181E">
    <path d="M 0 -240 L -200 130 L -145 140 L -125 100 L 0 -130 Z" />
    <path d="M 0 -240 L 0 -130 L 105 -25 L 105 -85 Z" />
    <path d="M -200 130 L -235 200 L -180 145 L -145 140 Z" />
    <path d="M -180 145 L -155 220 L -125 100 Z" />
    <g transform="rotate(180)">
      <path d="M 0 -240 L -200 130 L -145 140 L -125 100 L 0 -130 Z" />
      <path d="M 0 -240 L 0 -130 L 105 -25 L 105 -85 Z" />
      <path d="M -200 130 L -235 200 L -180 145 L -145 140 Z" />
      <path d="M -180 145 L -155 220 L -125 100 Z" />
    </g>
  </g>
  <g transform="translate(180, 100) skewX(-14)" fill="#15181E" fill-rule="evenodd">
    <path d="M 0 0 L 0 -50 L 12 -62 L 22 -62 L 22 0 Z" />
    <g transform="translate(30, 0)">
      <path d="M 12 -46 L 40 -46 L 52 -34 L 52 0 L 34 0 L 34 -8 L 12 -8 L 0 -20 L 0 -34 Z M 18 -22 L 34 -22 L 34 -32 L 18 -32 Z" />
    </g>
    <g transform="translate(90, 0)">
      <path d="M 12 -46 L 40 -46 L 52 -34 L 52 10 L 40 22 L 8 22 L 8 10 L 34 10 L 34 0 L 12 0 L 0 -12 L 0 -34 Z M 18 -14 L 34 -14 L 34 -32 L 18 -32 Z" />
    </g>
    <g transform="translate(152, 0)">
      <path d="M 48 -34 L 36 -46 L 12 -46 L 0 -34 L 0 -12 L 12 0 L 36 0 L 48 -12 L 32 -12 L 26 -6 L 22 -6 L 16 -12 L 16 -34 L 22 -40 L 26 -40 L 32 -34 Z" />
    </g>
    <g transform="translate(208, 0)">
      <path d="M 0 0 L 0 -50 L 12 -62 L 22 -62 L 22 -32 L 32 -46 L 42 -46 L 52 -36 L 52 0 L 32 0 L 32 -28 L 26 -34 L 22 -34 L 22 0 Z" />
    </g>
    <g transform="translate(268, 0)">
      <path d="M 0 -34 L 12 -46 L 38 -46 L 50 -34 L 50 -20 L 18 -20 L 18 -12 L 24 -6 L 36 -6 L 46 -14 L 46 0 L 38 0 L 12 0 L 0 -12 Z M 18 -32 L 32 -32 L 32 -26 L 18 -26 Z" />
    </g>
    <g transform="translate(326, 0)">
      <path d="M 48 -34 L 36 -46 L 12 -46 L 0 -34 L 0 -12 L 12 0 L 36 0 L 48 -12 L 32 -12 L 26 -6 L 22 -6 L 16 -12 L 16 -34 L 22 -40 L 26 -40 L 32 -34 Z" />
    </g>
    <g transform="translate(382, 0)">
      <path d="M 0 0 L 0 -50 L 12 -62 L 22 -62 L 22 -24 L 36 -46 L 58 -46 L 30 -18 L 60 0 L 36 0 L 18 -16 L 22 0 Z" />
    </g>
  </g>
</svg>
'''

# 5. Wordmark Monocromático Claro (para fundos pretos)
wordmark_mono_light_svg = '''<svg viewBox="0 0 780 150" xmlns="http://www.w3.org/2000/svg" role="img" aria-labelledby="wm-light-title wm-light-desc">
  <title id="wm-light-title">LagCheck Wordmark Monocromático Claro</title>
  <desc id="wm-light-desc">Wordmark LagCheck para superfícies escuras em tinta branca sólida.</desc>
  <g transform="translate(85, 75) scale(0.25)" fill="#F4F5F7">
    <path d="M 0 -240 L -200 130 L -145 140 L -125 100 L 0 -130 Z" />
    <path d="M 0 -240 L 0 -130 L 105 -25 L 105 -85 Z" />
    <path d="M -200 130 L -235 200 L -180 145 L -145 140 Z" />
    <path d="M -180 145 L -155 220 L -125 100 Z" />
    <g transform="rotate(180)">
      <path d="M 0 -240 L -200 130 L -145 140 L -125 100 L 0 -130 Z" />
      <path d="M 0 -240 L 0 -130 L 105 -25 L 105 -85 Z" />
      <path d="M -200 130 L -235 200 L -180 145 L -145 140 Z" />
      <path d="M -180 145 L -155 220 L -125 100 Z" />
    </g>
  </g>
  <g transform="translate(180, 100) skewX(-14)" fill="#F4F5F7" fill-rule="evenodd">
    <path d="M 0 0 L 0 -50 L 12 -62 L 22 -62 L 22 0 Z" />
    <g transform="translate(30, 0)">
      <path d="M 12 -46 L 40 -46 L 52 -34 L 52 0 L 34 0 L 34 -8 L 12 -8 L 0 -20 L 0 -34 Z M 18 -22 L 34 -22 L 34 -32 L 18 -32 Z" />
    </g>
    <g transform="translate(90, 0)">
      <path d="M 12 -46 L 40 -46 L 52 -34 L 52 10 L 40 22 L 8 22 L 8 10 L 34 10 L 34 0 L 12 0 L 0 -12 L 0 -34 Z M 18 -14 L 34 -14 L 34 -32 L 18 -32 Z" />
    </g>
    <g transform="translate(152, 0)">
      <path d="M 48 -34 L 36 -46 L 12 -46 L 0 -34 L 0 -12 L 12 0 L 36 0 L 48 -12 L 32 -12 L 26 -6 L 22 -6 L 16 -12 L 16 -34 L 22 -40 L 26 -40 L 32 -34 Z" />
    </g>
    <g transform="translate(208, 0)">
      <path d="M 0 0 L 0 -50 L 12 -62 L 22 -62 L 22 -32 L 32 -46 L 42 -46 L 52 -36 L 52 0 L 32 0 L 32 -28 L 26 -34 L 22 -34 L 22 0 Z" />
    </g>
    <g transform="translate(268, 0)">
      <path d="M 0 -34 L 12 -46 L 38 -46 L 50 -34 L 50 -20 L 18 -20 L 18 -12 L 24 -6 L 36 -6 L 46 -14 L 46 0 L 38 0 L 12 0 L 0 -12 Z M 18 -32 L 32 -32 L 32 -26 L 18 -26 Z" />
    </g>
    <g transform="translate(326, 0)">
      <path d="M 48 -34 L 36 -46 L 12 -46 L 0 -34 L 0 -12 L 12 0 L 36 0 L 48 -12 L 32 -12 L 26 -6 L 22 -6 L 16 -12 L 16 -34 L 22 -40 L 26 -40 L 32 -34 Z" />
    </g>
    <g transform="translate(382, 0)">
      <path d="M 0 0 L 0 -50 L 12 -62 L 22 -62 L 22 -24 L 36 -46 L 58 -46 L 30 -18 L 60 0 L 36 0 L 18 -16 L 22 0 Z" />
    </g>
  </g>
</svg>
'''

# Escrever os SVGs em design-system/assets/brand/ e web/assets/brand/
brand_dirs = [
    os.path.join(PROJECT_ROOT, "design-system/assets/brand"),
    os.path.join(PROJECT_ROOT, "web/assets/brand")
]

for d in brand_dirs:
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, "app-icon-source.svg"), "w") as f:
        f.write(app_icon_svg)
    with open(os.path.join(d, "symbol-compact.svg"), "w") as f:
        f.write(symbol_compact_svg)
    with open(os.path.join(d, "wordmark-primary.svg"), "w") as f:
        f.write(wordmark_primary_svg)
    with open(os.path.join(d, "wordmark-mono-dark.svg"), "w") as f:
        f.write(wordmark_mono_dark_svg)
    with open(os.path.join(d, "wordmark-mono-light.svg"), "w") as f:
        f.write(wordmark_mono_light_svg)
    print(f"SVGs salvos em: {d}")

# Renderizar Ícones PNG para o Xcode AppIcon.appiconset
appicon_dir = os.path.join(PROJECT_ROOT, "Sources/NolaggyApp/Assets.xcassets/AppIcon.appiconset")
os.makedirs(appicon_dir, exist_ok=True)

icon_source = os.path.join(PROJECT_ROOT, "design-system/assets/brand/app-icon-source.svg")

icon_sizes = [
    ("icon-1024.png", 1024, 1024),
    ("appicon-1024-master.png", 1024, 1024),
    ("icon-60@3x.png", 180, 180),
    ("icon-60@2x.png", 120, 120),
    ("icon-40@3x.png", 120, 120),
    ("icon-40@2x.png", 80, 80),
    ("icon-29@3x.png", 87, 87),
    ("icon-29@2x.png", 58, 58),
    ("icon-20@3x.png", 60, 60),
    ("icon-20@2x.png", 40, 40),
    ("icon-thumbnail-256.png", 256, 256)
]

for filename, w, h in icon_sizes:
    target_path = os.path.join(appicon_dir, filename)
    subprocess.run(["/opt/homebrew/bin/rsvg-convert", "-w", str(w), "-h", str(h), icon_source, "-o", target_path], check=True)
    print(f"Rendered {filename} ({w}x{h})")

# Também atualizar o master em design-system/assets/app-icon/appicon-1024-master.png
app_icon_asset_master = os.path.join(PROJECT_ROOT, "design-system/assets/app-icon/appicon-1024-master.png")
subprocess.run(["/opt/homebrew/bin/rsvg-convert", "-w", "1024", "-h", "1024", icon_source, "-o", app_icon_asset_master], check=True)
print("Updated design-system/assets/app-icon/appicon-1024-master.png")

# Renderizar WordmarkPrimary para Sources/NolaggyApp/Assets.xcassets/WordmarkPrimary.imageset/
wm_dir = os.path.join(PROJECT_ROOT, "Sources/NolaggyApp/Assets.xcassets/WordmarkPrimary.imageset")
os.makedirs(wm_dir, exist_ok=True)
wm_source = os.path.join(PROJECT_ROOT, "design-system/assets/brand/wordmark-primary.svg")

# Dimensões da Wordmark no app (ex: 260x50 em 1x, 520x100 em 2x, 780x150 em 3x)
subprocess.run(["/opt/homebrew/bin/rsvg-convert", "-w", "260", "-h", "50", wm_source, "-o", os.path.join(wm_dir, "wordmark-primary.png")], check=True)
subprocess.run(["/opt/homebrew/bin/rsvg-convert", "-w", "520", "-h", "100", wm_source, "-o", os.path.join(wm_dir, "wordmark-primary@2x.png")], check=True)
subprocess.run(["/opt/homebrew/bin/rsvg-convert", "-w", "780", "-h", "150", wm_source, "-o", os.path.join(wm_dir, "wordmark-primary@3x.png")], check=True)
print("Rendered WordmarkPrimary.imageset PNGs")

# Atualizar Contents.json da WordmarkPrimary para incluir @2x e @3x
wm_contents_json = '''{
  "images" : [
    {
      "filename" : "wordmark-primary.png",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "filename" : "wordmark-primary@2x.png",
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "filename" : "wordmark-primary@3x.png",
      "idiom" : "universal",
      "scale" : "3x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
'''
with open(os.path.join(wm_dir, "Contents.json"), "w") as f:
    f.write(wm_contents_json)

print("All brand assets successfully updated!")
