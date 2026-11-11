# LagCheck ORBIT — Matriz de Testes e Validação

> **Guia de Testes e Procedimentos de Garantia de Qualidade (QA)**  
> **Status:** Testes de unidade e bateria visual automatizada 100% aprovados.

---

## 1. Testes Automatizados Executáveis

Os testes do LagCheck ORBIT rodam de forma autônoma sem requerer ambiente com display gráfico nem elevação de privilégios.

### 1.1 Suíte de Testes Unitários

Executar a partir da pasta `android/`:
```bash
./gradlew :desktop:test
```

**Cobertura de Testes de Unidade:**
* `LibraryCoreTest.testReferenceGamesIntegrity`: Valida a configuração estrita dos 3 jogos de referência (*Cities: Skylines II*, *Fall Guys*, *Call of Duty: Warzone*) e seus respectivos perfis de rede (Offline, Conexão Geral, Homologado).
* `LibraryCoreTest.testSteamManifestParsing`: Valida o parser de manifestos ACF da Steam com extração de AppID, flags de instalação e resolução automática do catálogo LagCheck.
* `LibraryCoreTest.testSteamLibraryFoldersParsing`: Valida a leitura de diretórios de bibliotecas adicionais em arquivos `libraryfolders.vdf`.
* `LibraryCoreTest.testEpicManifestParsing`: Valida o parser de arquivos JSON `.item` da Epic Games com extração de AppName, executável e URI de protocolo.
* `LibraryCoreTest.testLibraryRepositoryFilteringAndSearch`: Valida a reatividade do repositório (filtros por plataforma, busca textual em tempo real e alternância de favoritos).
* `Ga4ClientTest`: Valida a telemetria estritamente anônima do GA4 Measurement Protocol.
* `IpLocationClientTest`: Valida o parsing e cache da geolocalização IP aproximada.
* `UpdateSupportTest`: Valida a verificação de hash SHA-256 e comparação de versões de release.
* `RouteMapTest`: Valida as projeções de coordenadas e grade geográfica Natural Earth.

---

### 1.2 Bateria de Capturas Automatizadas (`:desktop:shots`)

Para validar visualmente todas as telas do aplicativo em modo headless (sem abrir janela):
```bash
./gradlew :desktop:shots
```
As imagens PNG geradas são salvas em:
`android/desktop/build/shots/`

**Telas validadas pela bateria:**
* `home.png` e `home-compact.png`: Renderização da interface ORBIT com o Hero cinematográfico, pílulas de filtro e grade de jogos.
* `check.png` e `check-map.png`: Diagnóstico UDP em tempo real com o mapa de rotas.
* `result.png`: Apresentação do veredito oficial com métricas de ping, jitter e perda.
* `games.png`: Catálogo completo de rotas homologadas.
* `history.png`: Histórico de diagnósticos da sessão.
* `settings.png`: Painel de ajustes e controle de telemetria/acessibilidade.
* `components.png`: Galeria de componentes do design system.

---

### 1.3 Diagnóstico de Rede sem Janela (`:desktop:runCli`)

Executa o diagnóstico UDP de 60 sondas reais (repouso + carga HTTP) diretamente pelo terminal:
```bash
./gradlew :desktop:runCli
```
Exemplo de saída esperada:
```text
100%
verdict=READY ping=21 jitter=3.2 loss=0.0 abort=null loadMeasured=true games=40
```

---

## 2. Matriz de Validação em Aparelho / Windows Físico

| Cenário | O que foi validado no ambiente Mac | O que requer validação em máquina Windows real |
| :--- | :--- | :--- |
| **Parsing Steam (VDF / ACF)** | ✓ Validado com amostras reais e sintéticas de manifestos Valve | Testar com biblioteca real da Steam instalada em múltiplos drives (ex: `D:\SteamLibrary`). |
| **Parsing Epic Games (.item)** | ✓ Validado com JSONs reais de manifestos Epic Games | Testar com instalação real da Epic Games Store em `%ProgramData%`. |
| **Execução via Protocolo (`GameRunner`)** | ✓ Validado dispatch de comando via sistema operacional | Testar se o client da Steam e Epic Games sobem e iniciam o jogo em primeiro plano no Windows. |
| **Interface ORBIT (Compose Desktop)** | ✓ Compilação, layout, DPI e renderização Skia validados via `:desktop:shots` | Inspecionar a suavidade visual em monitores de alta taxa de atualização (120 Hz / 240 Hz). |
| **Redimensionamento da Janela** | ✓ Layout adaptativo (compacto < 950 dp e padrão 1120 dp) testado | Testar arrasto de borda e atalhos Windows Snap (Win + Seta). |
| **Diagnóstico Determinístico UDP** | ✓ 100% validado pelo `core:session` e `core:network` | Validar comportamento sob Windows Defender Firewall e VPNs. |
