# LagCheck.WinUI

Shell WinUI 3 do protótipo interno do LagCheck para Windows. Esta camada só desenha estados e despacha intenções; não calcula score, veredito, compatibilidade de jogo, nem acessa rede de diagnóstico.

## Limites da integração

- `LagCheck.WinUI.Library.ILibraryBridge` é a fronteira da Biblioteca. A composição deve configurar `LibraryPageServices.Configure(bridge)` com um adaptador do **mesmo** host local usado pelo diagnóstico. Sem ponte, a tela informa explicitamente que a biblioteca não está conectada.
- `LagCheck.WinUI.Diagnostic.DiagnosticEngineClient` é a fronteira NDJSON local do motor Kotlin. O protocolo tem versão `lagcheck-engine-v1`; o host deve rejeitar versões incompatíveis e manter uma única sessão ativa.
- O Shell encontra `LibraryPage` e `DiagnosticPage` em tempo de execução para permitir que essas frentes evoluam sem duplicar motor. Não existe diagnóstico automático no shell: selecionar um jogo não inicia medição.
- Catálogo e Histórico não exibem conteúdo enquanto suas fontes reais não estiverem conectadas. Isso é intencional: nenhum endpoint, jogo, métrica, score ou telemetria é simulado.

## Recursos que precisam entrar no pacote

As fontes oficiais (Barlow, Barlow Semi Condensed e Chakra Petch) e a wordmark/ícone aprovados precisam ser fornecidos pelo empacotamento Windows. O código usa as famílias por nome e não recria a marca em vetor ou tipografia.

## Verificação local

O projeto fixa `Microsoft.WindowsAppSDK` em `1.7.250606001` e segmenta `net10.0-windows10.0.19041.0`. A restauração/build deve ocorrer somente no ambiente Windows autorizado, junto com o host Kotlin e seus testes.

## Paridade com o protótipo v2

A interface segue `LagCheck Windows v2.dc.html` (tokens em `Styles/Theme.xaml`, ícones SVG em `Controls/Glyphs.cs`, mapa em `Controls/RouteMapView.cs`). Pontos que **não** são desenhados porque o motor não os entrega, em respeito à regra "sem mock": upload e streaming, NAT, ranking de servidores e recomendações da tela de resultado; a faixa de métricas ao vivo mostra Resposta, Jitter e Sob carga, e o resultado soma Perda. O mapa só marca a origem quando a localização aproximada está autorizada nos Ajustes.

Armadilhas do build: `FlowLayout` em XAML derruba o `MarkupCompilePass1` sem mensagem (use `Controls/WrapPanel`), e um `Geometry` não pode ser compartilhado entre dois `Path`.
