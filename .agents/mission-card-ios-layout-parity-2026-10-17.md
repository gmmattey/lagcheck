# Cartão de Missão — Recuperação iOS pelo padrão Android e quatro destinos nativos

## Enquadramento

- **Problema da pessoa:** no iPhone, Ajustes, Histórico e Resultado perderam a hierarquia que funciona no Android: contornos tomam o lugar de profundidade, a prévia Link foge da ordem da decisão e a navegação esconde Histórico/Ajustes. A arte usada é a mesma, mas o enquadramento e a composição do card compartilhável não são.
- **Resultado esperado observável:** iOS preserva a promessa e os dados do Check, mas passa a ter (1) tab bar Apple nativa com Início, Jogos, Histórico e Ajustes; (2) grupos de Ajustes e Histórico com profundidade, sem contornos decorativos; (3) Resultado com veredito e prévia Link antes da telemetria, na mesma ordem Android; e (4) arquivo Link 1200x630 com arte em sangria e composição estrutural Android, usando somente arte autorizada/local e a folha nativa do iOS.
- **Fora de escopo:** qualquer edição Android, score/veredito/thresholds, motor de medição, catálogo/schema, Worker, persistência, endpoints, vídeo/Stories iOS, publicação e assets de terceiros.
- **Lane:** Full flow comum.
- **Por que esta lane:** a mudança é confinada à apresentação iOS e ao exportador local, mas cobre duas telas críticas e requer paridade de promessa/arquivo com Android e revisão visual.
- **Fontes de verdade:** `docs/04-design-system.md`; Decisões 64, 66, 80, 81 e 95; implementação Android de `SettingsScreen`, `HistoryScreen`, `VerdictScreen` e `ShareMediaRenderer`.

## Contrato compartilhado e diferenças nativas

| Item | Obrigatório nos dois clientes | iOS nesta missão |
| --- | --- | --- |
| Dados | Mesmo veredito, jogo, região e P50/jitter/perda observados; inconclusivo não gera arquivo | Não reinterpreta nenhum dado de domínio |
| Card 1200x630 | Arte editorial autorizada, gradiente legível, wordmark, headline, três métricas e CTA; sem ping de jogo inventado | Renderização UIKit/SwiftUI local; QR/loja só quando houver URL iOS segura, caso contrário omitir o bloco em vez de fingir um destino |
| Resultado | Veredito é a primeira decisão; compartilhamento não compete com ele | Preparo é assíncrono e não bloqueia; prévia Link vem após a manchete e antes da telemetria, como no Android |
| Ajustes | Seções escaneáveis, valores e ações claros | `List`/grupos nativos ou composição SwiftUI equivalente, alvos de 44 pt, Dynamic Type e VoiceOver; não copia navegação Android |
| Histórico | Registros e resumo são escaneáveis sem transformar cada observação em dashboard ou promessa preditiva | Mantém comparabilidade, inconclusivos e retenção; usa agrupamento e hierarquia nativos do iPhone |
| Navegação | Início, Jogos, Histórico e Ajustes são destinos de primeira classe | `TabView`, SF Symbols e tab bar do sistema; não copia barra Material nem troca de ícone Android |

## Donos e aceite

- **Responsável pela entrega:** Rian (iOS).
- **Revisão de composição e visual:** Renan.
- **QA independente:** Breno.
- **Aceite operacional:** Giam.
- **Integridade de dados:** Iury revisa somente se o arquivo puder divergir do snapshot; nenhuma regra de medição entra no escopo.

## Critérios de aceite e evidência

1. Android não tem arquivo ou comportamento modificado (`git diff` restrito a iOS/testes/documentação da missão).
2. Em iPhone, a tab bar nativa expõe Início, Jogos, Histórico e Ajustes; Histórico/Ajustes como raízes não mostram volta artificial e os atalhos internos levam ao destino correto.
3. Em Resultado, a primeira dobra apresenta manchete de veredito e a prévia Link antes da telemetria; resultado inconclusivo não cria arquivo, prévia ou ação de share.
4. O JPEG iOS é 1200x630 e contém somente snapshot válido: arte autorizada/fallback neutro em sangria, wordmark oficial, jogo, região efetivamente medida, headline e P50/jitter/perda quando observados. Não contém arte de terceiro, ping de jogo, causa inventada, URL Android ou QR sem destino iOS seguro.
5. Ajustes e Histórico usam superfícies contínuas e profundidade, sem contorno que feche grupos; divisórias existem somente entre linhas adjacentes. Ajustes preserva idioma, região, lembrete, privacidade, suporte e exclusão; Histórico preserva comparabilidade e entradas inconclusivas.
6. PT-BR e inglês; Dynamic Type AX3+; VoiceOver em ordem lógica; controles com alvo mínimo de 44 pt.
7. Testes focados do exportador e UI/build iOS passam. Revisão em simulador no viewport equivalente e dispositivo físico continuam estados separados e explicitamente registrados.

## Entrega local e evidência

- **Estado anterior descartado pela auditoria:** uma tentativa local colocou bordas e família tipográfica misturada no iOS, deixou a prévia Link fora da ordem Android e manteve a tab bar com apenas dois destinos. Ela não atende a esta missão e será corrigida nesta mesma frente.
- **Preservado:** Android não será editado nesta missão. O repositório já continha alterações pendentes no Android antes do início e elas continuam preservadas, sem reversão ou ampliação.
- **Evidência executada:** `xcodebuild build` passou para `iPhone 17 Pro`; quatro UI tests focados passaram (Resultado PT-BR/EN/inconclusivo e as quatro abas nativas); inspeção visual no simulador iPhone 17 Pro confirmou as quatro abas, Ajustes/Histórico sem contorno ornamental e a prévia Link antes da telemetria.
- **Ainda pendente para aceite final:** revisão independente de Renan/Breno, Dynamic Type AX3+/VoiceOver e iPhone físico. Esses ambientes não foram alegados como validados.
