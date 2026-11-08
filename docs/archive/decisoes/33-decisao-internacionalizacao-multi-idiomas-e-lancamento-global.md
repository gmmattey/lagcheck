# LagCheck — decisão 33: internacionalização (i18n), multi-idiomas e prontidão para lançamento global

**Status:** decisão aprovada pelo Dono do Produto (Luiz); em implementação  
**Data:** 18 de setembro de 2026  
**Autores / Revisores:** Luiz (Dono do Produto), Marco (Produto), Renan (Design), Rian (iOS), Iury (Rede)  
**Complementa:** `docs/01-funcional.md`, `docs/02-arquitetura.md`, `docs/03-especificacao-tecnica.md`, `docs/04-design-system.md`, `docs/07-voz-do-produto.md`, `docs/archive/decisoes/16-decisao-selecao-regional-automatica.md`, `docs/archive/decisoes/28-decisao-servidores-testes-globais.md`

---

## 1. Contexto e Decisão do Produto

O Dono do Produto (Luiz) determinou a garantia de prontidão do **LagCheck** para distribuição global imediata, removendo qualquer amarra estrutural ou textual que restrinja a operação do aplicativo unicamente ao território brasileiro ou impeça sua expansão multilíngue.

Ficam estabelecidas quatro diretrizes mandatórias:
1. **Desvinculação Regional de Conteúdo:** O aplicativo não pode ter hardcoded de mercado (`market: "BR"`) em fluxos de carregamento de jogos ou status de serviços. A prateleira editorial e as seções devem ser globais (ex.: *"Mais populares"* / *"Most Popular"* / *"Más jugados"* em vez de referenciar exclusivamente o Brasil).
2. **Resolução Dinâmica de Mercado com Fallback Seguro:** A consulta de jogos do catálogo deve inspecionar o código de região do sistema do usuário (`Locale.current.region`). Se o mercado específico não constar no catálogo assinado, o sistema deve realizar um fallback elegante para um mercado ativo do catálogo, impedindo telas vazias para jogadores de outros países.
3. **Multi-idiomas com Paridade Estrita:**
   - Idiomas oficiais na V1 internacional: **Português (`pt-BR`)**, **Inglês (`en`)** e **Espanhol (`es`)**.
   - Paridade de 100% nas chaves entre todos os arquivos `.lproj`.
   - Nenhuma string voltada ao usuário pode permanecer como texto literal chumbado em código Swift.
4. **Integração com Ajustes de Idioma do Sistema Operacional:** Em Configurações, a linha de Idioma deve oferecer acesso direto às preferências do aplicativo no iOS (`UIApplication.openSettingsURLString`), permitindo que o usuário escolha seu idioma preferido através do recurso *Per-App Language Settings* da Apple.
5. **Idioma efetivo único:** O idioma do sistema é o padrão; uma escolha explícita da pessoa no LagCheck o substitui enquanto estiver ativa. Toda copy apresentada — texto de tela, VoiceOver, erro, estado vazio, formato textual e conteúdo editorial dinâmico — deve usar esse mesmo idioma efetivo. Não é aceitável uma tela parcialmente traduzida.
6. **IA no idioma efetivo:** As dicas pós-Deep Check devem receber o locale efetivo no contrato e retornar exclusivamente em `pt-BR`, `en` ou `es` correspondente. O pedido inteiro enviado ao modelo deve estar coerente com o idioma alvo; conteúdo em idioma inesperado, vazio ou fora do contrato é falha recuperável, nunca uma tradução ou recomendação inventada no cliente.

---

## 2. Parecer de Design e Voz do Produto (Renan & Marco)

1. **Voz do Produto em Três Idiomas (`docs/07`):**
   - **Inglês (`en`):** Tom conciso, seguro e gamer sem ser exagerado (*"Ready to play"*, *"Lag risk"*, *"Most Popular"*).
   - **Português (`pt-BR`):** Tom calmo, direto e natural (*"Pronto para jogar"*, *"Risco de lag"*, *"Mais populares"*).
   - **Espanhol (`es`):** Tom claro, formal sem rigidez excessiva e alinhado com o vocabulário gamer pan-hispânico (*"Listo para jugar"*, *"Riesgo de lag"*, *"Más jugados"*, *"Detalles"*).
2. **Expansão de Texto e Resiliência de Layout:**
   - O espanhol e o português tendem a ser entre 15% e 25% mais longos que o inglês.
   - Os componentes de vitrine (Hero, Shelf, GameRow), badges e cartões de diagnósticos devem manter o uso de `lineLimit` adequado, `fixedSize(horizontal: false, vertical: true)` onde necessário e tamanhos de botões com área de toque mínima de 44 pt.

---

## 3. Parecer de Arquitetura e Engenharia iOS (Rian)

1. **Catálogo & Resolução (`CatalogMeasurementJourney`):**
   - Adição do método estático `resolvedMarket(in:preferred:)` que avalia as regiões disponíveis no payload assinado contra a região local do dispositivo.
2. **Plataformas de Console (`DirectPlatformHealthClient`):**
   - Resolução dinâmica da região do jogador para consultas de status de serviços da PlayStation Network (SCEA vs. SCEE) e Xbox Network, passando o mercado detectado.
3. **XcodeGen (`project.yml`):**
   - Configuração de `developmentLanguage: en` e registro formal de `knownRegions: [Base, en, pt-BR, es]`.
4. **Remoção de Strings Literais:**
   - Componentes de detalhes editoriais e fichas técnicas (`GameDetailEditorialComponents.swift`, `NATTopologyModels.swift`) passam a consumir chaves formais de localização.
5. **Propagação do locale:** A escolha efetiva deve ser injetada nos adaptadores que montam textos e formatos. `NSLocalizedString`, `Locale.current` ou `String(format:)` não podem contornar essa escolha quando ela divergir do idioma do sistema.

---

## 4. Parecer de Qualidade de Rede e Servidores Globais (Iury)

1. **Preservação de Custo Zero e Protocolo UDP:**
   - A expansão de idiomas não altera o protocolo UDP dos 21 servidores AWS GameLift já homologados na Decisão 28.
2. **Nomes de Localidades Amigáveis em Espanhol:**
   - A enumeração canônica `GlobalProbeRegistry` passa a mapear os nomes das cidades/regiões no padrão hispânico (ex.: *"Virginia del Norte"*, *"Tokio"*, *"Seúl"*, *"Singapur"*, *"Ciudad del Cabo"*).
