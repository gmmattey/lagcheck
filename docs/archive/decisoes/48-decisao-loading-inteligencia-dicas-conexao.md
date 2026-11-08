# LagCheck — Decisão 48: Experiência Visual de Carregamento com IA (Dicas de Otimização)

**Status:** Decisão aprovada pelo Dono do Produto (Luiz); em especificação e implementação  
**Data:** 25 de setembro de 2026  
**Autores / Revisores:** Luiz (Dono do Produto), Marco (Produto), Renan (Design), Rian (iOS)  
**Revisa e complementa:** `docs/04-design-system.md`, `docs/07-voz-do-produto.md`, `docs/archive/decisoes/23-decisao-dicas-conexao-gemini-deep-check.md`, `docs/archive/decisoes/45-excecao-temporaria-gemini-release-1.0.0.md`

---

## 1. Contexto e Motivação de Produto (Luiz e Marco)

Ao solicitar **"Dicas de Otimização"** (`ConnectionBoosterSheet`) na tela de resultado do Deep Check, o app realiza uma consulta ao Gemini para cruzar as métricas aferidas da rede (RTT, jitter, perda, impacto sob carga) com o jogo e a plataforma do jogador.

O componente anterior (`BoosterSkeletonView`) apresentava 3 blocos cinzas estáticos sem qualquer feedback visual ou narrativo. Esse padrão causava uma percepção de tela travada ou espera fria, falhando em comunicar o valor da inteligência contextual do LagCheck.

O Dono do Produto aprovou a **Opção A: Orbe Editorial de Inteligência com Pulso Coral e Shimmer**, integrando animação orgânica, status rotativo contextual e esqueletos translúcidos com ondas de luz Coral Solar.

---

## 2. Direção de Design e Comportamento Visual (Renan)

### 2.1 Orbe Central de Inteligência
- Um orbe compacto (72pt) com gradiente radial em Coral Solar (`NLColor.accentPrimary`) que pulsa suavemente no centro da tela.
- Anéis concêntricos suaves expandindo ao redor com fade gradual de opacidade.
- Ícone inteligente central (`sparkles`) iluminado em tom de destaque.
- Quando `accessibilityReduceMotion` estiver ativo: os anéis animados são substituídos por um gradiente estático calmo sem movimentação contínua.

### 2.2 Micro-narrativa Sequencial (Status Rotativo)
Enquanto a API processa a consulta (tipicamente de 2 a 4 segundos), a interface transita suavemente entre três mensagens que traduzem o processamento em linguagem acessível e elegante:
1. **Passo 1 (0 a 1.5s):** *"Lendo a telemetria da sua rede…"*  
   *(Detalhe: "Avaliando estabilidade, jitter e impacto sob carga")*
2. **Passo 2 (1.5 a 3.0s):** *"Cruzando requisitos de [Jogo]…"*  
   *(Detalhe: "Verificando limites de latência e tolerância da partida")*
3. **Passo 3 (3.0s em diante):** *"Preparando ações práticas para [Plataforma]…"*  
   *(Detalhe: "Formatando ajustes no roteador, console e conexão")*

### 2.3 Cards Skeleton com Shimmer Coral Solar
Abaixo do orbe e da micro-narrativa, três cartões com layout pré-formatado exibem um efeito de shimmer suave:
- Fundo elevado (`NLColor.backgroundRaised`) com borda sutil (`NLColor.borderSubtle`).
- Um gradiente linear translúcido deslizando horizontalmente, antecipando o formato dos cards de recomendação.

---

## 3. Diretrizes de Engenharia e Localização (Rian)

1. **Localização Completa:** Textos disponíveis em **PT-BR**, **Inglês** e **Espanhol**.
2. **Tempo Real (Zero Falso Atraso):** O carregamento acompanha estritamente o tempo real da resposta da API do Gemini. No momento em que o JSON estruturado é decodificado e validado, a visualização transita imediatamente (`.spring()`) para a lista de recomendações.
3. **Acessibilidade:** Suporte completo a Dynamic Type, rótulos dedicados para VoiceOver e respeito a `accessibilityReduceMotion`.
