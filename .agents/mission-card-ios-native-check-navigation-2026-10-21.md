# Cartão de Missão — Transições nativas no Check iOS

## Enquadramento

- **Problema da pessoa:** a medição, o resultado e os estados finais do Check trocam de conteúdo sem a transição esperada no iPhone, deixando a jornada seca e sem orientação espacial.
- **Resultado esperado observável:** ao avançar da medição para resultado, inconclusivo ou cancelado, o iOS usa a transição de `NavigationStack`; o retorno por gesto e pela ação de sair preserva o cancelamento seguro e fecha a jornada, sem ressuscitar uma medição parada.
- **Fora de escopo:** animações decorativas, mudanças em score/veredito, regras de medição, abas principais, Android, Worker, persistência e copy.
- **Lane:** Full flow comum.
- **Por que esta lane:** altera a jornada visível de um fluxo existente no iOS, mas permanece no módulo SwiftUI e não cria ou muda contrato, persistência ou motor de rede.
- **Fonte de verdade:** `docs/04-design-system.md` §§7 e 11 (movimento só quando comunica mudança real e pilhas de navegação reais); Decisões 98, 103 e 104 em `docs/DECISOES.md`.

## Aceite e evidência

- **Aceite:** Check entra pela cobertura nativa existente; a tela terminal aparece por navegação nativa; voltar por gesto/ação cancela com segurança e fecha a cobertura; Reduzir Movimento continua sem animações extras do produto.
- **Validação planejada:** build do alvo iOS, UI tests da tela de resultado e inspeção no simulador. Gesto interativo em iPhone físico permanece uma prova separada.
