# 25 — Decisão de marca: LagCheck e identidade Coral Solar

Data: 18 de setembro de 2026  
Status: **decidido e implementado**  
Participantes: Luiz (Dono do produto), Marco (Produto), Renan (Design), Rian (Engenharia iOS)

---

## 1. Contexto e Motivação

O produto foi iniciado sob o codinome/marca temporária *Nolaggy*. Conforme alinhamento estratégico de produto e posicionamento no mercado de games mobile:
1. O nome **LagCheck** comunica de forma imediata, assertiva e compreensível o valor central do aplicativo: checar a estabilidade da conexão e risco de lag antes de entrar em uma partida.
2. A nova direção visual editorial inspirada na Apple Games Hub demandava um app icon e wordmark com peso icônico, dinamismo e sofisticação, abandonando designs genéricos de velocímetro ou símbolos passivos.

---

## 2. Decisões Tomadas

### 2.1 Novo Nome Oficial do Produto
- O produto passa a se chamar oficialmente **LagCheck** (com wordmark estilizada em minúsculas: `lagcheck`).
- O nome de exibição no iOS (`CFBundleDisplayName`) passa a ser **LagCheck**.
- Textos voltados ao usuário, acessibilidade, telas de resultado ("LagCheck Score"), histórico e páginas de suporte/política foram atualizados para refletir **LagCheck**.
- Para fins de governança de código e estabilidade de compilação/testes, os namespaces internos de módulo Swift (`NolaggyApp`, `NolaggyDomain`, etc.) e identificador de bundle são mantidos sem quebra de referências de projeto.

### 2.2 Identidade Visual: Pulse Gauge (Opção 2)
Dentre as propostas criadas para a nova fase do app, foi aprovada a **Opção 2: Pulse Gauge**:
- **Conceito**: Arcos de gauge concêntricos em alta precisão que convergem para uma onda de pulso ultrarrápida (ping), simbolizando a leitura contínua e a precisão técnica da medição de rota.
- **Paleta Aprovada**: **Coral Solar**
  - Vermelho solar / Coral vivo: `#FF3823`
  - Laranja solar intermediário: `#FF6B35`
  - Âmbar / Amarelo solar de destaque: `#FFAB2E`
  - Fundo: Grafite escuro com profundidade sutil (`#15171B` / `#0C0E11`)

### 2.3 Ativos Canônicos Atualizados
- `design-system/assets/brand/app-icon-source.svg`: Master vetorial 1024x1024 no esquema Coral Solar.
- `design-system/assets/brand/wordmark-primary.svg`: Wordmark `lagcheck` com acento Coral Solar no medidor.
- `design-system/assets/brand/symbol-compact.svg`: Símbolo compacto do Pulse Gauge Coral Solar.
- `Sources/NolaggyApp/Assets.xcassets/AppIcon.appiconset/`: Conjunto completo de ícones de 20pt a 1024pt gerado a partir do master Coral Solar.
- `Sources/NolaggyApp/Assets.xcassets/WordmarkPrimary.imageset/`: Ativo de imagem da Wordmark atualizado no app.

---

## 3. Impacto e Validação

- **Compilação e Testes**: Alvo testado no simulador e device com 100% de sucesso.
- **Acessibilidade**: Contrastes validados com labels de acessibilidade `LagCheck` e `LagCheck Score`.
- **Instalação no iPhone**: App instalado e validado via Wi-Fi no dispositivo físico de teste.
