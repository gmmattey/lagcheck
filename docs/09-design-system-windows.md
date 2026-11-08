# LagCheck — Design System e Navegação do Windows (protótipo)

> **Status:** protótipo interno (Decisão 114). Não é alvo oficial. Código em `android/desktop/`.
> Herda a **Dark Competitive UI** (`docs/04-design-system.md`). Aqui só entra o que muda no desktop.

## 1. O que não muda
Tokens de cor (`#0B0D10`, `#15181E`, `#1E232B`, Roxo `#7C3AED`, Coral `#FF5A36`, verde/âmbar/cinza semânticos), dark mode exclusivo, borda de 1 px, números monoespaçados, veredito com símbolo + texto + cor, regra do Discord (uma frase curta por informação), sem "card soup". Fonte da verdade no código: `ds/Tokens.kt`.

## 2. O que muda no desktop
| Tema | Mobile | Windows |
| --- | --- | --- |
| Navegação | Tab bar de 4 destinos (Início, Jogos, Histórico, Ajustes) | Barra lateral de 232 dp: Início, Jogos, Histórico, Ajustes. Histórico sobe para a barra porque há espaço. |
| Largura | 1 coluna | Conteúdo até 920 dp, centralizado; Início mantém um cockpit em coluna única para o Check continuar sendo o protagonista. |
| Entrada | Toque | Mouse + teclado: hover em todo item clicável, foco visível (anel 2 dp roxo claro), Tab/Enter/Espaço. |
| Alvo mínimo | 44 pt | 40 dp com mouse, botões 44 dp. |
| Marca, arte e ícones | Wordmark, artes editoriais e ícones nativos do app | Reutiliza os ativos locais aprovados do Android: wordmark oficial, artes editoriais autorais e a mesma linguagem de ícones. Sem download ou criação de arte. |
| Tipografia | Google Sans Flex | Google Sans Flex embarcada para corpo e títulos; Consolas do sistema para dados. |
| Janela | Tela cheia | 1120×740, mínimo 900×600. |
| Durante o Check | Sem anúncio | Barra lateral travada (uma sessão por vez); só "Cancelar" sai, descarta tudo. |

## 3. Componentes (`ds/Components.kt`)
`Interactive` (base: hover, foco, desabilitado), `PrimaryButton` (roxo), `SecondaryButton` (contorno), `Panel`, `SectionLabel`, `PageHeader`, `MetricTile`, `VerdictHeadline`, `StatusMarker`, `SidebarItem`, `ListRow`, `EmptyState`, `CircularGauge` (anel; pulsa em repouso, parado com "Reduzir movimento"), `LatencyChart` (linha, picos ≥ 80 ms em âmbar, marcador de início da carga), `SearchField` e `GameArtwork` (somente arte editorial local aprovada, com fallback neutro).
Galeria viva: `./gradlew :desktop:run --args="--ds"`. Ela é interna e só aparece nesse modo, nunca na navegação normal. Capturas sem janela: `./gradlew :desktop:shots` (gera `android/desktop/build/shots/`). As capturas usam Reduzir movimento, aguardam uma composição completa antes de gravar e já dispensam o aviso; `notice.png` é a única exceção, feita para revisar a faixa de primeira abertura no fluxo da tela. `check.png` mostra o mapa só da região, sem localização pessoal. As três capturas do Check mostram a curva de latência, não o skeleton do gráfico. Para revisão e material da página de download, `check-map.png` e `check-map-reduced.png` usam somente na captura a localização de exemplo Salvador, BR e a região do catálogo São Paulo; o primeiro mantém sondas em voo e o segundo usa Reduzir movimento.

## 4. Telas e fluxo
`Início → (Jogo) → Check → Resultado → Histórico`. A Início abre com a pílula honesta `ESTE PC · CONEXÃO GERAL`, seguida do anel "TESTAR" (Conexão geral), último Check em uma linha sem card e uma faixa de até quatro jogos com `VER TODOS`; a arte editorial local cria o contexto de jogo sem disputar a ação principal. Não afirma Wi-Fi, banda ou adaptador que o protótipo não observa. Jogos lista só o que o catálogo assinado libera para PC (hoje 40), com sua miniatura editorial local quando disponível. Resultado: veredito, Ping/Jitter/Perda, gráfico e ações. Histórico vive só na sessão e mostra miniatura apenas para jogo com ativo local compatível.

## 5. Mapa, localização e atualização

No Check, o mapa ocupa 280 dp no quadro normal e 240 dp no conteúdo da janela mínima de 900 dp; o anel e o gráfico ficam abaixo, sem sobreposição. Ele só anima sondas que o `core:session` comunicou de fato. A região é a selecionada pelo catálogo; o pino “Você” só aparece quando a localização aproximada por IP estiver disponível. A consulta vai ao endpoint `GET /v1/approx-location` do `lagcheck-site` (`lagcheck.signallq.com`; o Worker `nolaggy-deep-check` não participa; Decisão 116), usa cidade/país e coordenadas arredondadas, tem cache local de 24 h e a tela espera no máximo cerca de 3 s. Nesse intervalo, o skeleton preserva a mesma altura do mapa. Depois, em falha, 404 ou ajuste desligado, com região medida, o mapa entra no modo só-a-região: mostra pontos de terra, pino regional e a legenda “Localização aproximada indisponível”, sem “Você”, arco ou pacotes. Sem região medida, não há mapa. Não há reserva pelo fuso, GPS nem reenvio da posição. A atualização continua opcional e inerte sem fonte configurada. A localização usada em `check-map.png` e `check-map-reduced.png` é declaradamente dado de demonstração do gerador de capturas; não entra no fluxo do app.

Quando houver uma atualização, o instalador baixa em stream para arquivo temporário: HTTPS e hosts permitidos continuam valendo em cada redirecionamento, o SHA-256 é calculado durante a cópia e falha ou cancelamento apagam o arquivo. Só um arquivo conferido pode abrir; `.msi` usa `msiexec /i` e `.exe` abre direto, sem elevação silenciosa.

O catálogo assinado informa o `regionID` e o rótulo da região medida, mas não guarda coordenadas. O desktop mantém uma tabela local de coordenadas das cidades-sede, limitada aos mesmos IDs homologados pelo Android e iOS; ela só posiciona o pino regional e nunca escolhe, troca ou acrescenta rota. Se faltar coordenada para um ID do catálogo, a tela conserva o rótulo da região e não desenha rota.

## 6. Telemetria e privacidade

No build empacotado, o LagCheck pode enviar ao GA4 só jogo, plataforma PC, região, tipo de rede, classe do resultado, duração e motivo final do Check. Nunca envia IP, SSID, BSSID, MAC, localização, destino, amostras brutas, nome do PC ou da pessoa. Na primeira abertura, uma faixa no fluxo da tela explica isso e “OK” grava localmente que ela foi vista; não é popup. A pessoa pode desligar “Enviar dados de uso anônimos” em Ajustes; a escolha fica local e vale já. Também pode gerar um novo ID aleatório local. `run`, `shots`, CLI e testes não coletam, mesmo se as credenciais estiverem presentes.

## 7. Ajustes e movimento

Ajustes é uma lista de seções separadas por linha fina: nenhum bloco vira card. Chaves usam trilho retangular de raio 6 dp, foco roxo visível e funcionamento por Tab, Espaço e Enter. A chave “Reduzir movimento” interrompe as animações de rota, gráficos, métricas, transições e indicador da barra lateral. Datas e horas usam PT-BR e fuso local, por exemplo `07/11/2026 16:23`; ISO cru não aparece na tela. Quando há movimento, microinterações usam 150–250 ms e `cubic-bezier(.2,0,0,1)`.

## 8. Fora do protótipo (pendente)
Português/inglês (hoje só PT-BR), persistência do histórico, anúncio e consentimento, leitura do adaptador/Wi-Fi, acessibilidade validada com Narrator, DPI/escala do Windows, ícone do app e instalador assinado. Regra de score específica para PC exige decisão própria (Decisão 114, pendências).
