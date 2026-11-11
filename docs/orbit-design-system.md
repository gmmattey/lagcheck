# LagCheck ORBIT — Design System e Especificação Visual

> **Diretrizes de Design da Interface Desktop ORBIT**  
> **Fontes de Verdade:** `design-system/DESIGN.md`, `design-system/tokens/`, protótipo `design-system/prototypes/windows-premium/` e tokens do site em `sites/lagcheck/src/styles/global.css`.

---

## 1. Princípios de Experiência

A interface ORBIT combina a precisão técnica do LagCheck com a atmosfera cinematográfica dos consoles e launchers de PC modernos (NVIDIA, Xbox, PlayStation):
- **Cockpit Técnico e Calmo:** Fundo quase-preto com vinhetas discretas e superfícies grafite. Sem "card soup", sem excesso de bordas brancas e sem estética corporativa genérica.
- **Destaque Visual Verde-Lima (`#A3E635`):** Utilizado estrategicamente no botão primário de ação "JOGAR" e em indicadores de destaque do ORBIT, trazendo energia esportiva de alto contraste sobre o fundo escuro.
- **Roxo Gamer (`#7C3AED`):** Identidade assinatura do LagCheck para ações de diagnóstico de rede, foco e seleção.
- **Regra do Discord:** Toda informação deve ser traduzível para uma frase curta dita entre amigos no lobby da chamada de voz.
- **Honestidade Diagnóstica:** Sem medições inventadas. Jogos offline deixam explícito que são locais.

---

## 2. Tokens de Design (Alinhados 1:1 com OpenDesign e Web)

### 2.1 Cores (`LcColor`)

| Token | Valor Hex / CSS | Uso |
| :--- | :--- | :--- |
| `Background` | `#0B0D10` | Fundo quase-preto padrão da aplicação e da janela desktop. |
| `Surface` | `#15181E` | Superfície grafite primária (barra lateral, topo e cartões ativos). |
| `Panel` | `#1E232B` | Superfície elevada para painéis, cartões de jogos e containers. |
| `BorderHairline` | `rgba(255, 255, 255, 0.08)` | Bordas discretas de 1 px e divisórias entre seções. |
| `BorderSubtle` | `rgba(255, 255, 255, 0.10)` | Bordas de separação de cartões. |
| `BorderStrong` | `rgba(255, 255, 255, 0.16)` | Contornos de botões secundários e controles em repouso. |
| `BorderHover` | `rgba(124, 58, 237, 0.45)` | Destaque de hover em elementos interativos. |
| `OrbitLime` | `#A3E635` | Destaque esportivo ORBIT para o botão primário "JOGAR". |
| `OrbitLimeHover` | `#BEF264` | Estado hover do botão "JOGAR". |
| `OrbitLimePressed` | `#84CC16` | Estado pressionado do botão "JOGAR". |
| `OrbitLimeDark` | `#365314` | Contorno e bases de alto contraste para o verde-lima. |
| `Accent` (Roxo Gamer) | `#7C3AED` | Ação de diagnóstico "TESTAR CONEXÃO", anéis de foco e progresso. |
| `AccentLight` | `#A78BFA` | Texto e ícones secundários em roxo claro legível. |
| `AccentSubtle` | `rgba(124, 58, 237, 0.15)` | Preenchimento de seleção e pílulas ativas. |
| `TextPrimary` | `#F4F5F7` | Títulos, nomes de jogos e valores com alto contraste. |
| `TextSecondary` | `#8A93A0` | Subtítulos, descrições e metadados de leitura. |
| `TextTertiary` | `#606873` | Rótulos de seção, chevrons e metadados de apoio (Decisão 117). |
| `Good` (Verde) | `#22C55E` | Veredito favorável ("Pronto para Ranked") e jogos instalados. |
| `Caution` (Âmbar) | `#F59E0B` | Veredito de oscilação ("Condições Instáveis") e picos de latência. |
| `Coral` (Coral Solar) | `#FF5A36` | Veredito crítico ("Eu evitaria Ranked agora") e erros. |
| `Inconclusive` | `#8A93A0` | Veredito inconclusivo por ausência de dados UDP suficientes. |

---

### 2.2 Raios de Curvatura (`LcRadius`)

Herança canônica de `design-system/DESIGN.md`:
* `r8 = 8.dp`: Miniaturas de jogos, badges de plataforma e métricas compactas.
* `r13 = 13.dp`: Cartões de jogos, campos de busca e painéis de controle.
* `r17 = 17.dp`: Painel Hero de destaque cinematográfico e botões primários largos.
* `r26 = 26.dp`: Painéis amplos e modais.
* `pill = 999.dp`: Pílulas de filtro e badges de conectividade de rede.

---

### 2.3 Tipografia (`LcType`)

* **Google Sans Flex (Embarcada):**
  * `VerdictHero`: 40 sp / Line height 44 sp / Peso Black — títulos cinematográficos de jogos.
  * `PageTitle`: 28 sp / Line height 34 sp / Peso Bold — títulos de páginas.
  * `Section`: 11 sp / Line height 14 sp / Peso SemiBold / Tracking +1.4 sp — rótulos em caixa alta.
  * `Body`: 14 sp / Line height 20 sp / Peso Regular — leitura e descrições.
  * `BodyStrong`: 14 sp / Line height 20 sp / Peso SemiBold — nomes de cartões e botões.
  * `Button`: 13 sp / Line height 16 sp / Peso Bold / Tracking +1.0 sp — textos de ação.
* **Monoespaçado do Sistema (Cascadia Mono / Consolas):**
  * `DataHero`: 56 sp / Peso Bold — números principais de ping e latência.
  * `DataLarge`: 24 sp / Peso Bold — estatísticas e métricas de diagnóstico.
  * `DataSmall`: 13 sp / Peso Medium — tempo jogado e taxas percentuais de perda.

---

### 2.4 Movimento e Acessibilidade

* **Curva de Animação:** `CubicBezierEasing(0.2f, 0f, 0f, 1f)` em todas as microinterações (150–250 ms).
* **Reduzir Movimento:** Quando a chave "Reduzir movimento" estiver ativada em Ajustes:
  * O mapa de rotas desativa a animação de pacotes em voo.
  * O anel circular desativa o pulso em repouso.
  * As transições entre telas tornam-se instantâneas (`durationMillis = 0`).
* **Navegação por Teclado:** Todo componente interativo possui foco visível com anel de 2 dp em `LcColor.BorderHover` / `AccentLight`, acionável por Tab, Enter e Barra de Espaço.
