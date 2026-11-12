# Protótipo iOS de referência — LagCheck

Este diretório preserva o protótipo oficial da V1 para iPhone. Ele é a referência canônica de paridade visual e de comportamento para a implementação SwiftUI.

## Conteúdo

| Arquivo | Finalidade |
| --- | --- |
| `Nolaggy-iOS-Prototype-source.zip` | Pacote original recebido, preservado sem alteração |
| `source/Nolaggy iOS Prototype.dc.html` | Protótipo navegável/visual principal |
| `source/ios-frame.jsx` | Moldura de iPhone usada pelo protótipo |
| `source/support.js` | Suporte do protótipo |
| `source/assets/` | Assets complementares; marca legada removida. O HTML usa os assets oficiais em `design-system/assets/brand/` |
| `source/uploads/` | Imagens auxiliares incluídas no pacote original |

**Integridade do ZIP original (SHA-256):** `aa624b799282a021a43c2c5c9320e425311f2316137756f43d0c49f0ee2ee44f`

## Cobertura de telas

1. Home e menu lateral
2. Seleção de jogo e contexto
3. Quick Check em execução
4. Resultado do Quick Check, saudável e com risco
5. Detalhes da conexão
6. Deep Check: introdução, execução e resultado
7. Histórico
8. Configurações

## Regra de paridade 1:1

A implementação deve reproduzir fielmente o protótipo em iPhone, incluindo hierarquia, composição, espaçamentos percebidos, tipografia, cores, estados, ações, transições e prioridade de informação. O protótipo não é referência meramente estética.

**Ordem de referência:** `source/Nolaggy iOS Prototype.dc.html` é a fonte 1:1 para layout e estados. As PNGs em `source/assets/reference/` e `source/uploads/` são referências complementares de direção visual; se divergirem do HTML, o HTML prevalece. O board PNG legado com Home divergente e EA SPORTS FC 24 foi removido das referências extraídas para não ser usado na implementação.

Antes de declarar uma tela concluída, compare o app renderizado com a tela/estado correspondente deste pacote no mesmo viewport de iPhone. A validação deve cobrir aparência e interação, não apenas screenshot estático.

Há apenas três exceções possíveis: uma regra funcional posterior mais específica, uma exigência de precisão/segurança de rede ou uma exigência de acessibilidade do iOS. Qualquer divergência por uma dessas razões precisa ser aprovada por Marco e pelo responsável da frente, descrita no documento de decisão pertinente e refletida no protótipo/referência antes de virar padrão.

## Estados ainda sem referência 1:1

O pacote não desenha catálogo carregando/vazio/falhou, busca sem resultado, histórico vazio, consentimento UMP, indisponibilidade de Wi-Fi para Deep Check, cancelamento/falha de medição ou resultado inconclusivo. Esses estados continuam obrigatórios pela documentação funcional. Antes de implementá-los, Renan define sua composição; Rian e Iury revisam os estados que dependem de comportamento ou precisão de rede.

## Uso no desenvolvimento

- Renan verifica composição, tokens, componentes, estados e acessibilidade.
- Rian implementa em SwiftUI sem substituir a composição aprovada por layouts genéricos de plataforma.
- Iury confere que textos, métricas e estados de rede representados no protótipo permanecem tecnicamente verdadeiros.
- Marco decide qualquer conflito entre protótipo e documentação de produto.

Não edite os arquivos ativos em `source/` sem uma evolução deliberada do protótipo. O ZIP permanece como registro imutável do pacote recebido; o board PNG legado foi propositalmente excluído da cópia extraída, pois não representa o catálogo inicial aprovado. Evoluções do protótipo devem entrar em uma nova pasta versionada, mantendo esta referência intacta.

## Limpeza de marca (2026-10-03)

Referências visuais Nolaggy e cópias antigas de wordmark/ícone foram removidas da árvore extraída. O HTML aponta para a wordmark, o ícone e o símbolo roxos existentes e aprovados na Decisão 66. O ZIP original permanece apenas como arquivo histórico; seus assets não são fonte de marca atual.
